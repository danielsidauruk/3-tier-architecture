import logging
from flask import Flask
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
from redis import Redis
from redis.exceptions import ConnectionError as RedisConnectionError
from config import Config

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
            self._init_valkey()

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

    def _init_valkey(self):
        """Initializes a Valkey/Redis client."""
        try:
            client = Redis(
                host=self.config.REDIS_PRIMARY_ENDPOINT,
                port=self.config.REDIS_PORT,
                decode_responses=True,
                socket_connect_timeout=5
            )
            client.ping()
            self.redis_client = client
            logging.info(f"Connected to Valkey at {self.config.REDIS_PRIMARY_ENDPOINT}")
        except RedisConnectionError as e:
            logging.error(f"Failed to connect to Valkey: {e}")
        except Exception as e:
            logging.error(f"Unexpected error during Valkey initialization: {e}")

db = Database(Config())
