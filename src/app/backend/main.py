import os
import uuid
from flask import Flask, jsonify, request
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
import redis
from redis.exceptions import ConnectionError as RedisConnectionError
import json
from dotenv import load_dotenv # For local development
from flask_cors import CORS # Import CORS

# Load environment variables from .env file for local development
load_dotenv()

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# --- Configuration ---
# MongoDB Connection
# In production on EC2, these would be actual private IPs or DNS names of your MongoDB instances
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
MONGO_COLLECTION_NAME = os.getenv("MONGO_COLLECTION_NAME", "mycollection")

# Redis Connection
# In production on EC2, this would be the private IP or DNS name of your Redis instance
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))
REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", 300)) # Time-to-live for cache in seconds (5 minutes)

# --- Database & Cache Clients ---
# These are global variables. They are set once on app startup.
# If a connection fails, they will remain None until the app is restarted
# or a specific re-initialization mechanism is implemented.
mongo_client = None
mongo_db = None
redis_client = None

def init_db_clients():
    global mongo_client, mongo_db, redis_client
    
    # Attempt to connect to MongoDB
    try:
        # Added serverSelectionTimeoutMS to prevent long hangs on connection attempt
        mongo_client_temp = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        mongo_client_temp.admin.command('ping') # Test connection
        mongo_client = mongo_client_temp
        mongo_db = mongo_client[MONGO_DB_NAME]
        app.logger.info(f"Connected to MongoDB at {MONGO_URI}, database {MONGO_DB_NAME}")
    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"Failed to connect to MongoDB: {e}")
        mongo_client = None
        mongo_db = None
    except Exception as e:
        app.logger.error(f"An unexpected error occurred during MongoDB client initialization: {e}")
        mongo_client = None
        mongo_db = None

    # Attempt to connect to Redis
    try:
        # Added socket_connect_timeout to prevent long hangs on connection attempt
        redis_client_temp = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB, decode_responses=True, socket_connect_timeout=5)
        redis_client_temp.ping() # Test connection
        redis_client = redis_client_temp
        app.logger.info(f"Connected to Redis at {REDIS_HOST}:{REDIS_PORT}")
    except RedisConnectionError as e:
        app.logger.error(f"Failed to connect to Redis: {e}")
        redis_client = None
    except Exception as e:
        app.logger.error(f"An unexpected error occurred during Redis client initialization: {e}")
        redis_client = None

# Initialize clients when the app starts
# This will attempt connections upon Flask app context creation
with app.app_context():
    init_db_clients()

# --- API Endpoints ---

@app.route('/get_data/<string:key>', methods=['GET'])
def get_data(key):
    # Check if both DB and cache are unavailable globally
    if redis_client is None and mongo_db is None:
        return jsonify({"error": "Database and cache are unavailable"}), 503

    data = None
    source = "Unknown"
    redis_available_for_this_request = False # Track Redis status for this specific request

    # 1. Try to fetch from Redis (Cache)
    if redis_client is not None: # Check if the global redis_client was initialized
        try:
            cached_data = redis_client.get(key)
            if cached_data:
                data = json.loads(cached_data)
                source = "Redis"
                app.logger.info(f"Cache hit for key: {key}")
                redis_available_for_this_request = True # Redis successfully responded
            else:
                app.logger.info(f"Cache miss for key: {key}")
                redis_available_for_this_request = True # Redis is responsive but no cache
        except RedisConnectionError as e:
            app.logger.warning(f"Redis connection error during GET for key '{key}': {e}. Falling back to MongoDB.")
            # Do NOT reassign global redis_client here. Just mark it unavailable for this request.
            redis_available_for_this_request = False
        except Exception as e: # Catch other potential errors with Redis client (e.g., parsing)
            app.logger.error(f"Unexpected error with Redis during GET for key '{key}': {e}. Falling back to MongoDB.")
            redis_available_for_this_request = False

    # 2. If data not found in Redis (cache miss or Redis unavailable), fetch from MongoDB
    if data is None:
        if mongo_db is not None: # Check if the global mongo_db was initialized
            try:
                mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
                mongo_data = mongo_collection.find_one({"_id": key})

                if mongo_data:
                    # MongoDB's _id is an ObjectId by default, convert to string for JSON serialization
                    if '_id' in mongo_data and not isinstance(mongo_data['_id'], str):
                        mongo_data['_id'] = str(mongo_data['_id'])
                    data = mongo_data
                    source = "MongoDB"
                    app.logger.info(f"Data found in MongoDB for key: {key}")

                    # Store in Redis for future requests ONLY if Redis was available and responsive
                    if redis_available_for_this_request:
                        try:
                            redis_client.setex(key, REDIS_CACHE_TTL, json.dumps(data))
                            app.logger.info(f"Data cached in Redis for key: {key} with TTL {REDIS_CACHE_TTL}s")
                        except RedisConnectionError as e:
                            app.logger.warning(f"Redis connection error during SETEX for key '{key}': {e}. Data not cached.")
                            # Still don't reassign global redis_client here.
                        except Exception as e:
                            app.logger.error(f"Unexpected error caching to Redis for key '{key}': {e}. Data not cached.")
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
            return jsonify({"error": "MongoDB is unavailable"}), 503 # MongoDB was never initialized

    # Final check if data was found (should not be None if logic is correct)
    if data is None:
        return jsonify({"error": "An unexpected issue occurred: Data is None after all attempts."}), 500

    return jsonify({"data": data, "source": source})


@app.route('/list_all_data', methods=['GET'])
def list_all_data():
    if mongo_db is None: # Check if the global mongo_db was initialized
        return jsonify({"error": "MongoDB is unavailable"}), 503

    data_list = []
    source = "Unknown"

    # 1. Try to fetch from Redis (Cache)
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
            app.logger.warning(f"Redis connection error during GET for all_data_list: {e}. Falling back to MongoDB.")
        except Exception as e:
            app.logger.error(f"Unexpected error with Redis during GET for all_data_list: {e}. Falling back to MongoDB.")

    # 2. If not in cache or Redis unavailable, fetch from MongoDB
    if mongo_db is None:
        return jsonify({"error": "MongoDB is unavailable"}), 503

    try:
        mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
        for doc in mongo_collection.find({}):
            if '_id' in doc and not isinstance(doc['_id'], str):
                doc['_id'] = str(doc['_id'])
            data_list.append(doc)
        source = "MongoDB"
        app.logger.info("Fetched all data from MongoDB.")

        # Store in Redis for future requests if Redis is available
        if redis_client is not None:
            try:
                redis_client.setex("all_data_list", REDIS_CACHE_TTL, json.dumps(data_list))
                app.logger.info(f"All data list cached in Redis with TTL {REDIS_CACHE_TTL}s")
            except RedisConnectionError as e:
                app.logger.warning(f"Redis connection error during SETEX for all_data_list: {e}. Data not cached.")
            except Exception as e:
                app.logger.error(f"Unexpected error caching all_data_list to Redis: {e}. Data not cached.")

    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"MongoDB error listing all data: {e}")
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        app.logger.error(f"Error listing all data: {e}")
        return jsonify({"error": f"Internal server error: {e}"}), 500

    return jsonify({"data": data_list, "source": source})


@app.route('/set_data', methods=['POST'])
def set_data():
    if mongo_db is None: # Check if the global mongo_db was initialized
        return jsonify({"error": "MongoDB is unavailable"}), 503

    request_data = request.get_json()
    
    # Generate a new UUID for the _id
    new_id = str(uuid.uuid4())[:8]
    request_data['_id'] = new_id

    try:
        mongo_collection = mongo_db[MONGO_COLLECTION_NAME]
        
        # Insert the new document
        mongo_collection.insert_one(request_data)
        
        # Invalidate Redis cache for this key and the all_data_list if Redis is available
        if redis_client is not None: # Check if the global redis_client was initialized
            try:
                redis_client.delete(new_id)
                redis_client.delete("all_data_list") # Invalidate the list cache
                app.logger.info(f"Cache invalidated for key: {new_id} and all_data_list")
            except RedisConnectionError as e:
                app.logger.warning(f"Redis error during cache invalidation for key '{new_id}' or all_data_list: {e}. Data pushed to MongoDB.")
            except Exception as e:
                app.logger.error(f"Unexpected error during Redis cache invalidation for key '{new_id}' or all_data_list: {e}. Data pushed to MongoDB.")
        else:
            app.logger.warning(f"Redis client not available for cache invalidation for key '{new_id}'. Data pushed to MongoDB.")

        message = f"Data inserted successfully with new ID: {new_id}"
        app.logger.info(message)
        return jsonify({"message": message, "data": request_data}), 200

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
                    redis_client.delete("all_data_list") # Invalidate the list cache
                    app.logger.info(f"Cache invalidated for key: {key} and all_data_list")
                except RedisConnectionError as e:
                    app.logger.warning(f"Redis error during cache invalidation for key '{key}' or all_data_list: {e}.")
                except Exception as e:
                    app.logger.error(f"Unexpected error during Redis cache invalidation for key '{key}' or all_data_list: {e}.")
            message = f"Data for key '{key}' deleted successfully."
            app.logger.info(message)
            return jsonify({"message": message, "key": key}), 200
        else:
            message = f"Data for key '{key}' not found."
            app.logger.warning(message)
            return jsonify({"error": message}), 404

    except (ConnectionFailure, OperationFailure) as e:
        app.logger.error(f"MongoDB error deleting data for key '{key}': {e}")
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        app.logger.error(f"Error deleting data for key '{key}': {e}")
        return jsonify({"error": f"Internal server error: {e}"}), 500


# --- Health Check Endpoint (Optional but Recommended for Load Balancers) ---
@app.route('/health', methods=['GET'])
def health_check():
    mongo_status = "disconnected"
    redis_status = "disconnected"
    status_code = 503 # Default to service unavailable
    messages = []

    try:
        if mongo_client is not None:
            mongo_client.admin.command('ping')
            mongo_status = "connected"
        else:
            messages.append("MongoDB client not initialized.")
    except Exception as e:
        messages.append(f"MongoDB: {e}")

    try:
        if redis_client is not None:
            redis_client.ping()
            redis_status = "connected"
        else:
            messages.append("Redis client not initialized.")
    except Exception as e:
        messages.append(f"Redis: {e}")

    if mongo_status == "connected" and redis_status == "connected":
        status_code = 200
        messages.append("All services connected.")
    elif mongo_status == "connected" or redis_status == "connected":
        status_code = 200 # Partial connectivity might still be OK for some apps
        messages.append("Partial service connectivity.")
    else:
        status_code = 503 # No services connected
        messages.append("No services connected.")

    return jsonify({
        "status": "ok" if status_code == 200 else "error",
        "db": mongo_status,
        "cache": redis_status,
        "messages": messages
    }), status_code

# --- Run the Flask App ---
if __name__ == '__main__':
    # For local development, you can create a .env file with:
    # MONGO_URI="mongodb://localhost:27017/"
    # REDIS_HOST="localhost"
    # REDIS_PORT=6379
    #
    # Or, if running MongoDB/Redis in Docker:
    # MONGO_URI="mongodb://host.docker.internal:27017/"
    # REDIS_HOST="host.docker.internal"
    #
    # In a production EC2 environment, these environment variables
    # would be set directly on the EC2 instances.
    app.run(host='0.0.0.0', port=5000, debug=True) # debug=True for local developemnt