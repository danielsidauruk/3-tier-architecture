import logging
from flask import Flask
from flask_cors import CORS

from config import Config
from database import db
from routes import api_blueprint

def create_app():
    """Creates and configures the Flask application."""
    app = Flask(__name__)
    CORS(app)
    app.config.from_object(Config)
    
    logging.basicConfig(level=logging.INFO)

    # Initialize database and cache connections
    db.init_app(app)
    
    # Register the API blueprint
    app.register_blueprint(api_blueprint)

    return app

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
