from flask import request
from flask_restx import Namespace, Resource, fields
from flask_jwt_extended import jwt_required, get_jwt_identity
from .. import db
from ..models.user import User

ns = Namespace("users", description="User profile operations")

user_output = ns.model(
    "UserProfile",
    {
        "id": fields.Integer(),
        "name": fields.String(),
        "email": fields.String(),
        "avatar_url": fields.String(),
        "created_at": fields.String(),
    },
)

update_model = ns.model(
    "UpdateProfile",
    {
        "name": fields.String(example="Jane Doe"),
        "avatar_url": fields.String(example="https://example.com/avatar.png"),
    },
)

password_model = ns.model(
    "ChangePassword",
    {
        "current_password": fields.String(required=True),
        "new_password": fields.String(required=True),
    },
)


@ns.route("/me")
class UserMe(Resource):
    @jwt_required()
    @ns.response(200, "User profile", user_output)
    def get(self):
        """Get current user profile"""
        user_id = int(get_jwt_identity())
        user = db.session.get(User, user_id)
        if not user:
            ns.abort(404, "User not found")
        return user.to_dict(), 200

    @jwt_required()
    @ns.expect(update_model)
    @ns.response(200, "Profile updated", user_output)
    def put(self):
        """Update current user profile"""
        user_id = int(get_jwt_identity())
        user = db.session.get(User, user_id)
        if not user:
            ns.abort(404, "User not found")

        data = request.get_json()
        if "name" in data and data["name"].strip():
            user.name = data["name"].strip()
        if "avatar_url" in data:
            user.avatar_url = data.get("avatar_url")

        db.session.commit()
        return user.to_dict(), 200


@ns.route("/me/password")
class ChangePassword(Resource):
    @jwt_required()
    @ns.expect(password_model, validate=True)
    @ns.response(200, "Password changed")
    @ns.response(401, "Current password is incorrect")
    def put(self):
        """Change current user password"""
        user_id = int(get_jwt_identity())
        user = db.session.get(User, user_id)
        data = request.get_json()

        if not user.check_password(data["current_password"]):
            ns.abort(401, "Current password is incorrect")
        if len(data["new_password"]) < 6:
            ns.abort(400, "New password must be at least 6 characters")

        user.set_password(data["new_password"])
        db.session.commit()
        return {"message": "Password changed successfully"}, 200
