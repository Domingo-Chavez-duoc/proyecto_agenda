import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_migrate import Migrate
from flask_restx import Api

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

authorizations = {
    "Bearer": {
        "type": "apiKey",
        "in": "header",
        "name": "Authorization",
        "description": "JWT token — format: **Bearer &lt;token&gt;**",
    }
}


def create_app(config_name: str = None):
    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "development")

    app = Flask(__name__)

    from .config import config
    app.config.from_object(config[config_name])

    # Extensions
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # API + Swagger
    api = Api(
        app,
        version="1.0",
        title="Calendar App API",
        description="REST API for Calendar/Agenda MVP — JWT protected",
        doc="/swagger",
        authorizations=authorizations,
        security="Bearer",
        prefix="/api",
    )

    # Namespaces
    from .routes.auth import ns as auth_ns
    from .routes.events import ns as events_ns
    from .routes.users import ns as users_ns

    api.add_namespace(auth_ns, path="/auth")
    api.add_namespace(events_ns, path="/events")
    api.add_namespace(users_ns, path="/users")

    # Create tables in dev if needed
    with app.app_context():
        db.create_all()

    return app
