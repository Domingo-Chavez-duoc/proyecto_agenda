from datetime import datetime
from flask import request
from flask_restx import Namespace, Resource, fields
from flask_jwt_extended import jwt_required, get_jwt_identity
from .. import db
from ..models.event import Event

ns = Namespace("events", description="Event CRUD operations")

# --- Swagger models ---
event_input = ns.model(
    "EventInput",
    {
        "title": fields.String(required=True, example="Team standup"),
        "description": fields.String(example="Daily sync"),
        "color": fields.String(example="#4F46E5"),
        "start_datetime": fields.String(required=True, example="2024-06-15T09:00:00"),
        "end_datetime": fields.String(required=True, example="2024-06-15T09:30:00"),
        "all_day": fields.Boolean(example=False),
        "location": fields.String(example="Meeting Room A"),
    },
)

event_output = ns.model(
    "Event",
    {
        "id": fields.Integer(),
        "user_id": fields.Integer(),
        "title": fields.String(),
        "description": fields.String(),
        "color": fields.String(),
        "start_datetime": fields.String(),
        "end_datetime": fields.String(),
        "all_day": fields.Boolean(),
        "location": fields.String(),
        "created_at": fields.String(),
        "updated_at": fields.String(),
    },
)


def _parse_dt(val: str) -> datetime:
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%d"):
        try:
            return datetime.strptime(val, fmt)
        except ValueError:
            continue
    raise ValueError(f"Cannot parse datetime: {val}")


@ns.route("/")
class EventList(Resource):
    @jwt_required()
    @ns.response(200, "List of events", [event_output])
    def get(self):
        """Get all events for the authenticated user (optional: ?start=&end= filters)"""
        user_id = int(get_jwt_identity())
        query = Event.query.filter_by(user_id=user_id)

        start = request.args.get("start")
        end = request.args.get("end")
        if start:
            query = query.filter(Event.start_datetime >= _parse_dt(start))
        if end:
            query = query.filter(Event.end_datetime <= _parse_dt(end))

        events = query.order_by(Event.start_datetime).all()
        return [e.to_dict() for e in events], 200

    @jwt_required()
    @ns.expect(event_input, validate=True)
    @ns.response(201, "Event created", event_output)
    @ns.response(400, "Validation error")
    def post(self):
        """Create a new event"""
        user_id = int(get_jwt_identity())
        data = request.get_json()

        try:
            start = _parse_dt(data["start_datetime"])
            end = _parse_dt(data["end_datetime"])
        except (KeyError, ValueError) as e:
            ns.abort(400, str(e))

        if end <= start:
            ns.abort(400, "end_datetime must be after start_datetime")

        event = Event(
            user_id=user_id,
            title=data["title"].strip(),
            description=data.get("description"),
            color=data.get("color", "#4F46E5"),
            start_datetime=start,
            end_datetime=end,
            all_day=data.get("all_day", False),
            location=data.get("location"),
        )
        db.session.add(event)
        db.session.commit()
        return event.to_dict(), 201


@ns.route("/<int:event_id>")
@ns.param("event_id", "The event identifier")
class EventDetail(Resource):
    @jwt_required()
    @ns.response(200, "Event detail", event_output)
    @ns.response(404, "Event not found")
    def get(self, event_id: int):
        """Get a single event"""
        user_id = int(get_jwt_identity())
        event = Event.query.filter_by(id=event_id, user_id=user_id).first_or_404()
        return event.to_dict(), 200

    @jwt_required()
    @ns.expect(event_input)
    @ns.response(200, "Event updated", event_output)
    @ns.response(404, "Event not found")
    def put(self, event_id: int):
        """Update an event"""
        user_id = int(get_jwt_identity())
        event = Event.query.filter_by(id=event_id, user_id=user_id).first_or_404()
        data = request.get_json()

        if "title" in data:
            event.title = data["title"].strip()
        if "description" in data:
            event.description = data.get("description")
        if "color" in data:
            event.color = data["color"]
        if "start_datetime" in data:
            event.start_datetime = _parse_dt(data["start_datetime"])
        if "end_datetime" in data:
            event.end_datetime = _parse_dt(data["end_datetime"])
        if "all_day" in data:
            event.all_day = data["all_day"]
        if "location" in data:
            event.location = data.get("location")

        db.session.commit()
        return event.to_dict(), 200

    @jwt_required()
    @ns.response(204, "Event deleted")
    @ns.response(404, "Event not found")
    def delete(self, event_id: int):
        """Delete an event"""
        user_id = int(get_jwt_identity())
        event = Event.query.filter_by(id=event_id, user_id=user_id).first_or_404()
        db.session.delete(event)
        db.session.commit()
        return "", 204
