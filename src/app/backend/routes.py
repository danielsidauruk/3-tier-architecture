from flask import jsonify, request, Blueprint
from services import DataService
from database import db
from config import Config
from pymongo.errors import ConnectionFailure

api_blueprint = Blueprint('api', __name__)

def get_data_service():
    """Factory function to get a DataService instance."""
    return DataService(db, Config())

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
