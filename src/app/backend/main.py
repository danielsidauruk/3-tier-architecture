import os
import uuid
import json
import logging
from flask import Flask, jsonify, request, Blueprint
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
import redis
from redis.exceptions import ConnectionError as RedisConnectionError
from flask_cors import CORS
from urllib.parse import quote_plus
import boto3
from botocore.exceptions import ClientError

# ==============================================================================
# Configuration
# ==============================================================================

class Config:
    """Application configuration."""
    MONGODB_ENDPOINT = os.getenv("MONGODB_ENDPOINT", "localhost")
    MONGODB_PORT = int(os.getenv("MONGODB_PORT", 27017))
    MONGODB_USER = os.getenv("MONGODB_USER")
    PRIMARY_REGION = os.getenv("PRIMARY_REGION", "ap-southeast-1")
    SECRET_NAME = os.getenv("SECRET_NAME", "mongodb-secret")
    MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
    MONGO_COLLECTION_NAME = os.getenv("MONGO_COLLECTION_NAME", "mycollection")
    REDIS_ENDPOINT = os.getenv("REDIS_ENDPOINT", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    REDIS_DB = int(os.getenv("REDIS_DB", 0))
    REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", 300))
    TLS_CA_FILE = os.getenv("TLS_CA_FILE", "global-bundle.pem")

    @staticmethod
    def get_secret(secret_name: str, region_name: str) -> dict | str:
        """Retrieves a secret from AWS Secrets Manager."""
        session = boto3.session.Session()
        client = session.client(service_name='secretsmanager', region_name=region_name)
        try:
            get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        except ClientError as e:
            logging.error(f"Failed to retrieve secret '{secret_name}': {e}")
            raise e
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            try:
                return json.loads(secret)
            except json.JSONDecodeError:
                return secret
        else:
            raise ValueError("Binary secrets are not supported.")

    @classmethod
    def get_mongo_uri(cls):
        """Constructs the MongoDB URI."""
        password = cls.get_secret(cls.SECRET_NAME, cls.PRIMARY_REGION)
        if cls.MONGODB_USER and password:
            encoded_password = quote_plus(password)
            return f"mongodb://{cls.MONGODB_USER}:{encoded_password}@{cls.MONGODB_ENDPOINT}:{cls.MONGODB_PORT}/"
        return f"mongodb://{cls.MONGODB_ENDPOINT}:{cls.MONGODB_PORT}/"

# ==============================================================================
# Database and Cache Initialization
# ==============================================================================

class Database:
    """Handles database and cache connections."""
    def __init__(self, config: Config):
        self.config = config
        self.mongo_client = None
        self.mongo_db = None
        self.redis_client = None

    def init_app(self, app: Flask):
        """Initializes database and cache clients."""
        with app.app_context():
            self._init_mongodb()
            self._init_redis()

    def _init_mongodb(self):
        try:
            uri = self.config.get_mongo_uri()
            client = MongoClient(
                uri,
                tls=True,
                tlsCAFile=self.config.TLS_CA_FILE,
                replicaSet='rs0',
                retryWrites=False,
                serverSelectionTimeoutMS=5000
            )
            client.admin.command('ping')
            self.mongo_client = client
            self.mongo_db = self.mongo_client[self.config.MONGO_DB_NAME]
            logging.info(f"Connected to MongoDB at {self.config.MONGODB_ENDPOINT}")
        except (ConnectionFailure, OperationFailure) as e:
            logging.error(f"Failed to connect to MongoDB: {e}")
        except Exception as e:
            logging.error(f"Unexpected error during MongoDB initialization: {e}")

    def _init_redis(self):
        try:
            client = redis.Redis(
                host=self.config.REDIS_ENDPOINT,
                port=self.config.REDIS_PORT,
                db=self.config.REDIS_DB,
                decode_responses=True,
                socket_connect_timeout=5
            )
            client.ping()
            self.redis_client = client
            logging.info(f"Connected to Redis at {self.config.REDIS_ENDPOINT}")
        except RedisConnectionError as e:
            logging.error(f"Failed to connect to Redis: {e}")
        except Exception as e:
            logging.error(f"Unexpected error during Redis initialization: {e}")

db = Database(Config)

# ==============================================================================
# Services (Business Logic)
# ==============================================================================

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
                cached_data = self.db.redis_client.get(key)
                if cached_data:
                    logging.info(f"Cache hit for key: {key}")
                    return json.loads(cached_data), "Redis"
            except RedisConnectionError as e:
                logging.warning(f"Redis connection error during GET for key '{key}': {e}")

        if self.mongo_collection is not None:
            try:
                mongo_data = self.mongo_collection.find_one({"_id": key})
                if mongo_data:
                    mongo_data['_id'] = str(mongo_data['_id'])
                    if self.db.redis_client is not None:
                        try:
                            self.db.redis_client.setex(key, self.config.REDIS_CACHE_TTL, json.dumps(mongo_data))
                            logging.info(f"Data for key {key} cached in Redis.")
                        except RedisConnectionError as e:
                            logging.warning(f"Redis error during SETEX for key '{key}': {e}")
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
                    return json.loads(cached_list), "Redis"
            except RedisConnectionError as e:
                logging.warning(f"Redis connection error during GET for all_data_list: {e}")

        if self.mongo_collection is not None:
            try:
                data_list = list(self.mongo_collection.find({}))
                for doc in data_list:
                    doc['_id'] = str(doc['_id'])
                if self.db.redis_client is not None:
                    try:
                        self.db.redis_client.setex("all_data_list", self.config.REDIS_CACHE_TTL, json.dumps(data_list))
                        logging.info("All data list cached in Redis")
                    except RedisConnectionError as e:
                        logging.warning(f"Redis error during SETEX for all_data_list: {e}")
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
                    self.db.redis_client.delete(new_id)
                    self.db.redis_client.delete("all_data_list")
                    logging.info(f"Cache invalidated for key: {new_id} and all_data_list")
                except RedisConnectionError as e:
                    logging.warning(f"Redis error during cache invalidation for key '{new_id}': {e}")
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
                        self.db.redis_client.delete(key)
                        self.db.redis_client.delete("all_data_list")
                        logging.info(f"Cache invalidated for key: {key} and all_data_list")
                    except RedisConnectionError as e:
                        logging.warning(f"Redis error during cache invalidation for key '{key}': {e}")
                return True
            return False
        except (ConnectionFailure, OperationFailure) as e:
            logging.error(f"MongoDB error deleting data for key '{key}': {e}")
            raise

# ==============================================================================
# API Blueprint (Routes)
# ==============================================================================

api_blueprint = Blueprint('api', __name__)

def get_data_service():
    """Factory function to get a DataService instance."""
    return DataService(db, Config)

@api_blueprint.route('/get_data/<string:key>', methods=['GET'])
def get_data(key):
    service = get_data_service()
    try:
        data, source = service.get_data(key)
        if data:
            return jsonify({"data": data, "source": source})
        return jsonify({"error": f"Data for key '{key}' not found"}), 404
    except Exception as e:
        return jsonify({"error": f"Internal server error: {e}"}), 500

@api_blueprint.route('/list_all_data', methods=['GET'])
def list_all_data():
    service = get_data_service()
    try:
        data_list, source = service.list_all_data()
        return jsonify({"data": data_list, "source": source})
    except Exception as e:
        return jsonify({"error": f"Internal server error: {e}"})

@api_blueprint.route('/set_data', methods=['POST'])
def set_data():
    service = get_data_service()
    request_data = request.get_json()
    if not request_data:
        return jsonify({"error": "Invalid JSON"}), 400
    try:
        inserted_data = service.set_data(request_data)
        return jsonify({"message": f"Data inserted successfully with new ID: {inserted_data['_id']}", "data": inserted_data}), 201
    except ConnectionFailure as e:
        return jsonify({"error": f"Database unavailable: {e}"}), 503
    except Exception as e:
        return jsonify({"error": f"Internal server error: {e}"}), 500

@api_blueprint.route('/delete_data/<string:key>', methods=['DELETE'])
def delete_data(key):
    service = get_data_service()
    try:
        if service.delete_data(key):
            return jsonify({"message": f"Data for key '{key}' deleted successfully."}), 200
        return jsonify({"error": f"Data for key '{key}' not found."}), 404
    except ConnectionFailure as e:
        return jsonify({"error": f"Database unavailable: {e}"}), 503
    except Exception as e:
        return jsonify({"error": f"Internal server error: {e}"}), 500

@api_blueprint.route('/health', methods=['GET'])
def health_check():
    mongo_status = "disconnected"
    redis_status = "disconnected"
    
    if db.mongo_client is not None:
        try:
            db.mongo_client.admin.command('ping')
            mongo_status = "connected"
        except Exception:
            pass

    if db.redis_client is not None:
        try:
            db.redis_client.ping()
            redis_status = "connected"
        except Exception:
            pass

    status_code = 200 if mongo_status == "connected" or redis_status == "connected" else 503
    return jsonify({
        "db": mongo_status,
        "cache": redis_status,
    }), status_code

# ==============================================================================
# Application Factory
# ==============================================================================

def create_app():
    """Creates and configures the Flask application."""
    app = Flask(__name__)
    CORS(app)
    app.config.from_object(Config)
    
    logging.basicConfig(level=logging.INFO)

    db.init_app(app)
    
    app.register_blueprint(api_blueprint)

    return app

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
