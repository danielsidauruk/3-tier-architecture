import os
import json
import logging
import boto3
from botocore.exceptions import ClientError
from urllib.parse import quote_plus

class Config:
    """Application configuration."""
    MONGODB_ENDPOINT = os.getenv("MONGODB_ENDPOINT", "localhost")
    MONGODB_PORT = int(os.getenv("MONGODB_PORT", 27017))
    MONGODB_USER = os.getenv("MONGODB_USER")
    PRIMARY_REGION = os.getenv("PRIMARY_REGION", "ap-southeast-1")
    SECRET_NAME = os.getenv("SECRET_NAME", "mongodb-secret")
    MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
    MONGO_COLLECTION_NAME = os.getenv("MONGO_COLLECTION_NAME", "mycollection")
    REDIS_PRIMARY_ENDPOINT = os.getenv("REDIS_PRIMARY_ENDPOINT", "localhost")
    REDIS_READER_ENDPOINT = os.getenv("REDIS_READER_ENDPOINT", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", 300))
    TLS_CA_FILE = os.getenv("TLS_CA_FILE", "global-bundle.pem")
    MONGODB_CLUSTER_IDENTIFIER = os.getenv("MONGODB_CLUSTER_IDENTIFIER", "")
    REDIS_REPLICATION_GROUP_ID = os.getenv("REDIS_REPLICATION_GROUP_ID", "")

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
