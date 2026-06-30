import 'package:flutter/material.dart';

class AppEvent {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String color;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final bool allDay;
  final String? location;
  final DateTime createdAt;

  const AppEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.color,
    required this.startDatetime,
    required this.endDatetime,
    required this.allDay,
    this.location,
    required this.createdAt,
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) => AppEvent(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        color: json['color'] as String? ?? '#4F46E5',
        startDatetime: DateTime.parse(json['start_datetime'] as String),
        endDatetime: DateTime.parse(json['end_datetime'] as String),
        allDay: json['all_day'] as bool? ?? false,
        location: json['location'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'color': color,
        'start_datetime': startDatetime.toIso8601String(),
        'end_datetime': endDatetime.toIso8601String(),
        'all_day': allDay,
        'location': location,
      };

  Color get flutterColor {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
