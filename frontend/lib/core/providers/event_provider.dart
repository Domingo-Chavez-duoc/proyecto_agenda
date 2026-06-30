import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<AppEvent> _events = [];
  bool _loading = false;
  String? _error;

  List<AppEvent> get events => _events;
  bool get loading => _loading;
  String? get error => _error;

  /// Eventos agrupados por fecha (para el calendario)
  Map<DateTime, List<AppEvent>> get eventsByDay {
    final Map<DateTime, List<AppEvent>> map = {};
    for (final e in _events) {
      final day = DateTime(
        e.startDatetime.year,
        e.startDatetime.month,
        e.startDatetime.day,
      );
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  List<AppEvent> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventsByDay[key] ?? [];
  }

  List<AppEvent> eventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _events
        .where((e) =>
            e.startDatetime.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.startDatetime.isBefore(weekEnd))
        .toList()
      ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadEvents() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await apiClient.get('/events/');
      final list = res.data as List<dynamic>;
      _events = list
          .map((e) => AppEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<bool> createEvent({
    required String title,
    String? description,
    required DateTime start,
    required DateTime end,
    String color = '#4F46E5',
    bool allDay = false,
    String? location,
  }) async {
    try {
      final res = await apiClient.post('/events/', data: {
        'title': title,
        'description': description,
        'start_datetime': start.toIso8601String(),
        'end_datetime': end.toIso8601String(),
        'color': color,
        'all_day': allDay,
        'location': location,
      });
      final newEvent = AppEvent.fromJson(res.data as Map<String, dynamic>);
      _events
        ..add(newEvent)
        ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  Future<bool> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.put('/events/$id', data: data);
      final updated = AppEvent.fromJson(res.data as Map<String, dynamic>);
      final idx = _events.indexWhere((e) => e.id == id);
      if (idx != -1) _events[idx] = updated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteEvent(int id) async {
    try {
      await apiClient.delete('/events/$id');
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
