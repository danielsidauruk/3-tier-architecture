import logging
import json
import uuid
import boto3
from ec2_metadata import ec2_metadata
from database import Database
from config import Config
from pymongo.errors import ConnectionFailure, OperationFailure
from redis.exceptions import ConnectionError as RedisConnectionError

class DataService:
    """Encapsulates business logic for data operations."""
    def __init__(self, database: Database, config: Config):
        self.db = database
        self.config = config
        self.mongo_collection = self.db.mongo_db[self.config.MONGO_COLLECTION_NAME] if self.db.mongo_db is not None else None
        self.rds_client = boto3.client('rds', region_name=self.config.PRIMARY_REGION)
        self.elasticache_client = boto3.client('elasticache', region_name=self.config.PRIMARY_REGION)

    def get_system_status(self):
        """Gets the system status."""
        # Backend Metadata
        backend_metadata = {
            "instance_id": ec2_metadata.instance_id,
            "availability_zone": ec2_metadata.availability_zone
        }

        # DocumentDB Metadata
        docdb_metadata = {}
        try:
            hello_response = self.db.mongo_client.admin.command('hello')
            connected_instance_endpoint = hello_response['me']
            
            response = self.rds_client.describe_db_clusters(DBClusterIdentifier=self.config.MONGODB_CLUSTER_IDENTIFIER)
            for member in response['DBClusters'][0]['DBClusterMembers']:
                db_instance_response = self.rds_client.describe_db_instances(DBInstanceIdentifier=member['DBInstanceIdentifier'])
                db_instance = db_instance_response['DBInstances'][0]
                if db_instance['Endpoint']['Address'] in connected_instance_endpoint:
                    docdb_metadata = {
                        "instance_id": db_instance['DBInstanceIdentifier'],
                        "availability_zone": db_instance['AvailabilityZone'],
                    }
                    break
        except Exception as e:
            logging.error(f"Could not retrieve DocumentDB metadata: {e}")
            docdb_metadata = {"error": str(e)}

        # ElastiCache Metadata
        elasticache_metadata = {}
        try:
            cluster_nodes = self.db.redis_client.cluster_nodes()
            # In redis-py-cluster, the first node in the list is the one we are connected to.
            connected_node_id = list(cluster_nodes.values())[0]['node_id']

            response = self.elasticache_client.describe_cache_clusters(CacheClusterId=self.config.REDIS_REPLICATION_GROUP_ID, ShowCacheNodeInfo=True)
            for node in response['CacheClusters'][0]['CacheNodes']:
                if connected_node_id in node['CacheNodeId']:
                    elasticache_metadata = {
                        "instance_id": node['CacheNodeId'],
                        "availability_zone": node['CustomerAvailabilityZone'],
                    }
                    break
        except Exception as e:
            logging.error(f"Could not retrieve ElastiCache metadata: {e}")
            elasticache_metadata = {"error": str(e)}

        return {
            "backend_metadata": backend_metadata,
            "database_metadata": docdb_metadata,
            "elasticache_metadata": elasticache_metadata
        }

    def get_data(self, key: str):
        """Gets data from cache or database."""
        if self.db.redis_client is not None:
            try:
                # This GET command will be routed to a replica by redis-py-cluster
                cached_data = self.db.redis_client.get(key)
                if cached_data:
                    logging.info(f"Cache hit for key: {key}")
                    return json.loads(cached_data), "Redis (Valkey Engine)"
            except RedisConnectionError as e:
                logging.warning(f"Redis (Valkey Engine) connection error during GET for key '{key}': {e}")

        if self.mongo_collection is not None:
            try:
                mongo_data = self.mongo_collection.find_one({"_id": key})
                if mongo_data:
                    mongo_data['_id'] = str(mongo_data['_id'])
                    if self.db.redis_client is not None:
                        try:
                            # This SETEX command will be routed to the primary
                            self.db.redis_client.setex(key, self.config.REDIS_CACHE_TTL, json.dumps(mongo_data))
                            logging.info(f"Data for key {key} cached in Redis (Valkey Engine).")
                        except RedisConnectionError as e:
                            logging.warning(f"Redis (Valkey Engine) error during SETEX for key '{key}': {e}")
                    return mongo_data, "MongoDB"
            except (ConnectionFailure, OperationFailure) as e:
                logging.error(f"MongoDB error fetching data for key '{key}': {e}")
                raise

        return None, None

    def list_all_data(self):
        """Lists all data from cache or database."""
        backend_metadata = {
            "instance_id": ec2_metadata.instance_id,
            "availability_zone": ec2_metadata.availability_zone
        }
        if self.db.redis_client is not None:
            try:
                cached_list = self.db.redis_client.get("all_data_list")
                if cached_list:
                    logging.info("Cache hit for all_data_list")
                    return json.loads(cached_list), "Redis (Valkey Engine)", backend_metadata
            except RedisConnectionError as e:
                logging.warning(f"Redis (Valkey Engine) connection error during GET for all_data_list: {e}")

        if self.mongo_collection is not None:
            try:
                data_list = list(self.mongo_collection.find({}))
                for doc in data_list:
                    doc['_id'] = str(doc['_id'])
                if self.db.redis_client is not None:
                    try:
                        self.db.redis_client.setex("all_data_list", self.config.REDIS_CACHE_TTL, json.dumps(data_list))
                        logging.info(f"All data list cached in Redis (Valkey Engine)")
                    except RedisConnectionError as e:
                        logging.warning(f"Redis (Valkey Engine) error during SETEX for all_data_list: {e}")
                return data_list, "MongoDB", backend_metadata
            except (ConnectionFailure, OperationFailure) as e:
                logging.error(f"MongoDB error listing all data: {e}")
                raise
        return [], None, backend_metadata


    def set_data(self, data: dict):
        """Inserts new data."""
        if self.mongo_collection is None:
            raise ConnectionFailure("MongoDB is unavailable")
        
        new_id = str(uuid.uuid4())[:8]
        data['_id'] = new_id
        
        try:
            self.mongo_collection.insert_one(data)
            if self.db.redis_client is not None:
                try:
                    # These DELETE commands will be routed to the primary
                    self.db.redis_client.delete(new_id)
                    self.db.redis_client.delete("all_data_list")
                    logging.info(f"Cache invalidated for key: {new_id} and all_data_list")
                except RedisConnectionError as e:
                    logging.warning(f"Redis (Valkey Engine) error during cache invalidation for key '{new_id}': {e}")
            return data
        except (ConnectionFailure, OperationFailure) as e:
            logging.error(f"MongoDB error setting data: {e}")
            raise

    def delete_data(self, key: str):
        """Deletes data."""
        if self.mongo_collection is None:
            raise ConnectionFailure("MongoDB is unavailable")

        try:
            result = self.mongo_collection.delete_one({'_id': key})
            if result.deleted_count > 0:
                if self.db.redis_client is not None:
                    try:
                        # These DELETE commands will be routed to the primary
                        self.db.redis_client.delete(key)
                        self.db.redis_client.delete("all_data_list")
                        logging.info(f"Cache invalidated for key: {key} and all_data_list")
                    except RedisConnectionError as e:
                        logging.warning(f"Redis (Valkey Engine) error during cache invalidation for key '{key}': {e}")
                return True
            return False
        except (ConnectionFailure, OperationFailure) as e:
            logging.error(f"MongoDB error deleting data for key '{key}': {e}")
            raise