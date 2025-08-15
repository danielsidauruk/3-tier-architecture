import logging
import json
import uuid
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

    def get_data(self, key: str):
        """Gets data from cache or database."""
        if self.db.redis_client is not None:
            try:
                # This GET command will be routed to a replica by redis-py-cluster
                cached_data = self.db.redis_client.get(key)
                if cached_data:
                    logging.info(f"Cache hit for key: {key}")
                    return json.loads(cached_data), "Valkey"
            except RedisConnectionError as e:
                logging.warning(f"Valkey connection error during GET for key '{key}': {e}")

        if self.mongo_collection is not None:
            try:
                mongo_data = self.mongo_collection.find_one({"_id": key})
                if mongo_data:
                    mongo_data['_id'] = str(mongo_data['_id'])
                    if self.db.redis_client is not None:
                        try:
                            # This SETEX command will be routed to the primary
                            self.db.redis_client.setex(key, self.config.REDIS_CACHE_TTL, json.dumps(mongo_data))
                            logging.info(f"Data for key {key} cached in Valkey.")
                        except RedisConnectionError as e:
                            logging.warning(f"Valkey error during SETEX for key '{key}': {e}")
                    return mongo_data, "MongoDB"
            except (ConnectionFailure, OperationFailure) as e:
                logging.error(f"MongoDB error fetching data for key '{key}': {e}")
                raise

        return None, None

    def list_all_data(self):
        """Lists all data from cache or database."""
        if self.db.redis_client is not None:
            try:
                cached_list = self.db.redis_client.get("all_data_list")
                if cached_list:
                    logging.info("Cache hit for all_data_list")
                    return json.loads(cached_list), "Valkey"
            except RedisConnectionError as e:
                logging.warning(f"Valkey connection error during GET for all_data_list: {e}")

        if self.mongo_collection is not None:
            try:
                data_list = list(self.mongo_collection.find({}))
                for doc in data_list:
                    doc['_id'] = str(doc['_id'])
                if self.db.redis_client is not None:
                    try:
                        self.db.redis_client.setex("all_data_list", self.config.REDIS_CACHE_TTL, json.dumps(data_list))
                        logging.info("All data list cached in Valkey")
                    except RedisConnectionError as e:
                        logging.warning(f"Valkey error during SETEX for all_data_list: {e}")
                return data_list, "MongoDB"
            except (ConnectionFailure, OperationFailure) as e:
                logging.error(f"MongoDB error listing all data: {e}")
                raise
        return [], None


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
                    logging.warning(f"Valkey error during cache invalidation for key '{new_id}': {e}")
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
                        logging.warning(f"Valkey error during cache invalidation for key '{key}': {e}")
                return True
            return False
        except (ConnectionFailure, OperationFailure) as e:
            logging.error(f"MongoDB error deleting data for key '{key}': {e}")
            raise
