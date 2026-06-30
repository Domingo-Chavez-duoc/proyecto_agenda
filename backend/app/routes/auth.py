from flask import request
from flask_restx import Namespace, Resource, fields
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
)
from .. import db
from ..models.user import User

ns = Namespace("auth", description="Authentication operations")

# --- Swagger models ---
register_model = ns.model(
    "Register",
    {
        "name": fields.String(required=True, example="Jane Doe"),
        "email": fields.String(required=True, example="jane@example.com"),
        "password": fields.String(required=True, example="secret123"),
    },
)

login_model = ns.model(
    "Login",
    {
        "email": fields.String(required=True, example="jane@example.com"),
        "password": fields.String(required=True, example="secret123"),
    },
)

token_model = ns.model(
    "TokenResponse",
    {
        "access_token": fields.String(),
        "refresh_token": fields.String(),
        "user": fields.Raw(),
    },
)


# --- Routes ---
@ns.route("/register")
class Register(Resource):
    @ns.expect(register_model, validate=True)
    @ns.response(201, "User created", token_model)
    @ns.response(409, "Email already registered")
    @ns.response(400, "Validation error")
    def post(self):
        """Register a new user"""
        data = request.get_json()
        name = data.get("name", "").strip()
        email = data.get("email", "").lower().strip()
        password = data.get("password", "")

        if not name or not email or not password:
            ns.abort(400, "name, email and password are required")
        if len(password) < 6:
            ns.abort(400, "Password must be at least 6 characters")
        if User.query.filter_by(email=email).first():
            ns.abort(409, "Email already registered")

        user = User(name=name, email=email)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()

        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": user.to_dict(),
        }, 201


@ns.route("/login")
class Login(Resource):
    @ns.expect(login_model, validate=True)
    @ns.response(200, "Login successful", token_model)
    @ns.response(401, "Invalid credentials")
    def post(self):
        """Login and get JWT tokens"""
        data = request.get_json()
        email = data.get("email", "").lower().strip()
        password = data.get("password", "")

        user = User.query.filter_by(email=email).first()
        if not user or not user.check_password(password):
            ns.abort(401, "Invalid email or password")

        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": user.to_dict(),
        }, 200


@ns.route("/refresh")
class Refresh(Resource):
    @jwt_required(refresh=True)
    @ns.response(200, "Token refreshed")
    def post(self):
        """Get a new access token using refresh token"""
        identity = get_jwt_identity()
        access_token = create_access_token(identity=identity)
        return {"access_token": access_token}, 200
