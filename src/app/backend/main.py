import os
import uuid
import json
from flask import Flask, jsonify, request
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
import redis
from redis.exceptions import ConnectionError as RedisConnectionError
from flask_cors import CORS
from urllib.parse import quote_plus

app = Flask(__name__)
CORS(app)

MONGODB_ENDPOINT = os.getenv("MONGODB_ENDPOINT", "localhost")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", 27017))
MONGODB_USER = os.getenv("MONGODB_USER")
MONGODB_PASSWORD = os.getenv("MONGODB_PASSWORD")

if MONGODB_USER and MONGODB_PASSWORD:
    ENCODED_MONGODB_PASSWORD = quote_plus(MONGODB_PASSWORD)
    MONGO_URI = f"mongodb://{MONGODB_USER}:{ENCODED_MONGODB_PASSWORD}@{MONGODB_ENDPOINT}:{MONGODB_PORT}/"
else:
    MONGO_URI = f"mongodb://{MONGODB_ENDPOINT}:{MONGODB_PORT}/"

MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
MONGO_COLLECTION_NAME = os.getenv("MONGO_COLLECTION_NAME", "mycollection")

REDIS_ENDPOINT = os.getenv("REDIS_ENDPOINT", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))
REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", 300))

mongo_client = None
mongo_db = None
redis_client = None

def init_db_clients():
    global mongo_client, mongo_db, redis_client
    try:
        mongo_client_temp = MongoClient(
            MONGO_URI,
            tls=True,
            tlsCAFile='global-bundle.pem',
            replicaSet='rs0',
            retryWrites=False,
            serverSelectionTimeoutMS=5000
        )
        mongo_client_temp.admin.command('ping')
        mongo_client = mongo_client_temp
        mongo_db = mongo_client[MONGO_DB_NAME]
        app.logger.info(f"Connected to MongoDB at {MONGO_URI}, database {MONGO_DB_NAME}")
    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"Failed to connect to MongoDB: {e}")
        mongo_client = None
        mongo_db = None
    except Exception as e:
        app.logger.error(f"Unexpected error during MongoDB client initialization: {e}")
        mongo_client = None
        mongo_db = None

    try:
        redis_client_temp = redis.Redis(
            host=REDIS_ENDPOINT,
            port=REDIS_PORT,
            db=REDIS_DB,
            decode_responses=True,
            socket_connect_timeout=5
        )
        redis_client_temp.ping()
        redis_client = redis_client_temp
        app.logger.info(f"Connected to Redis at {REDIS_ENDPOINT}:{REDIS_PORT}")
    except RedisConnectionError as e:
        app.logger.error(f"Failed to connect to Redis: {e}")
        redis_client = None
    except Exception as e:
        app.logger.error(f"Unexpected error during Redis client initialization: {e}")
        redis_client = None

with app.app_context():
    init_db_clients()

@app.route('/get_data/<string:key>', methods=['GET'])
def get_data(key):
    if redis_client is None and mongo_db is None:
        return jsonify({"error": "Database and cache are unavailable"}), 503

    data = None
    source = "Unknown"
    redis_available_for_this_request = False

    if redis_client is not None:
        try:
            cached_data = redis_client.get(key)
            if cached_data:
                data = json.loads(cached_data)
                source = "Redis"
                app.logger.info(f"Cache hit for key: {key}")
                redis_available_for_this_request = True
            else:
                app.logger.info(f"Cache miss for key: {key}")
                redis_available_for_this_request = True
        except RedisConnectionError as e:
            app.logger.warning(f"Redis connection error during GET for key '{key}': {e}")
        except Exception as e:
            app.logger.error(f"Unexpected error with Redis during GET for key '{key}': {e}")

    if data is None:
        if mongo_db is not None:
            try:
                mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
                mongo_data = mongo_collection.find_one({"_id": key})
                if mongo_data:
                    if '_id' in mongo_data and not isinstance(mongo_data['_id'], str):
                        mongo_data['_id'] = str(mongo_data['_id'])
                    data = mongo_data
                    source = "MongoDB"
                    app.logger.info(f"Data found in MongoDB for key: {key}")
                    if redis_available_for_this_request:
                        try:
                            redis_client.setex(key, REDIS_CACHE_TTL, json.dumps(data))
                            app.logger.info(f"Data cached in Redis for key: {key}")
                        except RedisConnectionError as e:
                            app.logger.warning(f"Redis error during SETEX for key '{key}': {e}")
                        except Exception as e:
                            app.logger.error(f"Unexpected error caching Redis key '{key}': {e}")
                else:
                    app.logger.warning(f"Data not found in MongoDB for key: {key}")
                    return jsonify({"error": f"Data for key '{key}' not found"}), 404
            except (ConnectionFailure, OperationFailure) as e:
                app.logger.error(f"MongoDB error fetching data for key '{key}': {e}")
                return jsonify({"error": f"Database error: {e}"}), 500
            except Exception as e:
                app.logger.error(f"Error fetching data from MongoDB for key '{key}': {e}")
                return jsonify({"error": f"Internal server error from DB: {e}"}), 500
        else:
            return jsonify({"error": "MongoDB is unavailable"}), 503

    if data is None:
        return jsonify({"error": "An unexpected issue occurred: Data is None after all attempts."}), 500

    return jsonify({"data": data, "source": source})

@app.route('/list_all_data', methods=['GET'])
def list_all_data():
    if mongo_db is None:
        return jsonify({"error": "MongoDB is unavailable"}), 503

    data_list = []
    source = "Unknown"

    if redis_client is not None:
        try:
            cached_list = redis_client.get("all_data_list")
            if cached_list:
                data_list = json.loads(cached_list)
                source = "Redis"
                app.logger.info("Cache hit for all_data_list")
                return jsonify({"data": data_list, "source": source})
            else:
                app.logger.info("Cache miss for all_data_list")
        except RedisConnectionError as e:
            app.logger.warning(f"Redis connection error during GET for all_data_list: {e}")
        except Exception as e:
            app.logger.error(f"Unexpected error with Redis during GET for all_data_list: {e}")

    try:
        mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
        for doc in mongo_collection.find({}):
            if '_id' in doc and not isinstance(doc['_id'], str):
                doc['_id'] = str(doc['_id'])
            data_list.append(doc)
        source = "MongoDB"
        app.logger.info("Fetched all data from MongoDB.")

        if redis_client is not None:
            try:
                redis_client.setex("all_data_list", REDIS_CACHE_TTL, json.dumps(data_list))
                app.logger.info("All data list cached in Redis")
            except RedisConnectionError as e:
                app.logger.warning(f"Redis error during SETEX for all_data_list: {e}")
            except Exception as e:
                app.logger.error(f"Unexpected error caching all_data_list to Redis: {e}")
    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"MongoDB error listing all data: {e}")
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        app.logger.error(f"Error listing all data: {e}")
        return jsonify({"error": f"Internal server error: {e}"}), 500

    return jsonify({"data": data_list, "source": source})

@app.route('/set_data', methods=['POST'])
def set_data():
    if mongo_db is None:
        return jsonify({"error": "MongoDB is unavailable"}), 503

    request_data = request.get_json()
    new_id = str(uuid.uuid4())[:8]
    request_data['_id'] = new_id

    try:
        mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
        mongo_collection.insert_one(request_data)
        if redis_client is not None:
            try:
                redis_client.delete(new_id)
                redis_client.delete("all_data_list")
                app.logger.info(f"Cache invalidated for key: {new_id} and all_data_list")
            except RedisConnectionError as e:
                app.logger.warning(f"Redis error during cache invalidation for key '{new_id}': {e}")
            except Exception as e:
                app.logger.error(f"Unexpected error during Redis cache invalidation for key '{new_id}': {e}")
        else:
            app.logger.warning(f"Redis client not available for cache invalidation for key '{new_id}'")
        app.logger.info(f"Data inserted successfully with new ID: {new_id}")
        return jsonify({"message": f"Data inserted successfully with new ID: {new_id}", "data": request_data}), 200
    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"MongoDB error setting data: {e}")
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        app.logger.error(f"Error setting data: {e}")
        return jsonify({"error": f"Internal server error: {e}"}), 500

@app.route('/delete_data/<string:key>', methods=['DELETE'])
def delete_data(key):
    if mongo_db is None:
        return jsonify({"error": "MongoDB is unavailable"}), 503

    try:
        mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
        result = mongo_collection.delete_one({'_id': key})

        if result.deleted_count > 0:
            if redis_client is not None:
                try:
                    redis_client.delete(key)
                    redis_client.delete("all_data_list")
                    app.logger.info(f"Cache invalidated for key: {key} and all_data_list")
                except RedisConnectionError as e:
                    app.logger.warning(f"Redis error during cache invalidation for key '{key}': {e}")
                except Exception as e:
                    app.logger.error(f"Unexpected error during Redis cache invalidation for key '{key}': {e}")
            app.logger.info(f"Data for key '{key}' deleted successfully.")
            return jsonify({"message": f"Data for key '{key}' deleted successfully.", "key": key}), 200
        else:
            app.logger.warning(f"Data for key '{key}' not found.")
            return jsonify({"error": f"Data for key '{key}' not found."}), 404
    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"MongoDB error deleting data for key '{key}': {e}")
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        app.logger.error(f"Error deleting data for key '{key}': {e}")
        return jsonify({"error": f"Internal server error: {e}"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    mongo_status = "disconnected"
    redis_status = "disconnected"
    status_code = 503
    messages = []

    try:
        if mongo_client is not None:
            mongo_client.admin.command('ping')
            mongo_status = "connected"
    except Exception as e:
        messages.append(f"MongoDB: {e}")

    try:
        if redis_client is not None:
            redis_client.ping()
            redis_status = "connected"
    except Exception as e:
        messages.append(f"Redis: {e}")

    if mongo_status == "connected" and redis_status == "connected":
        status_code = 200
        messages.append("All services connected.")
    elif mongo_status == "connected" or redis_status == "connected":
        status_code = 200
        messages.append("Partial service connectivity.")
    else:
        messages.append("No services connected.")

    return jsonify({
        "status": "ok" if status_code == 200 else "error",
        "db": mongo_status,
        "cache": redis_status,
        "messages": messages
    }), status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
