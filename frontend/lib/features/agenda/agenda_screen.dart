import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/event.dart';
import '../../core/providers/event_provider.dart';
import '../../shared/widgets/event_dialog.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  DateTime _getWeekStart(DateTime date) {
    // Lunes como inicio de semana
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  void _goToday() => setState(() => _weekStart = _getWeekStart(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final weekEvents = provider.eventsForWeek(_weekStart);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final today = DateTime.now();
    final dateFmt = DateFormat('d MMM');
    final monthFmt = DateFormat('MMMM yyyy');

    // Agrupar eventos por día
    final Map<int, List<AppEvent>> byDayIndex = {};
    for (int i = 0; i < 7; i++) {
      byDayIndex[i] = [];
    }
    for (final e in weekEvents) {
      final diff =
          e.startDatetime.difference(_weekStart).inDays.clamp(0, 6);
      byDayIndex[diff]!.add(e);
    }

    return Scaffold(
      body: Column(
        children: [
          // Week navigation header
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevWeek,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Semana anterior',
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        monthFmt.format(_weekStart),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${dateFmt.format(_weekStart)} – ${dateFmt.format(weekEnd)}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Semana siguiente',
                ),
                TextButton(
                  onPressed: _goToday,
                  child: const Text('Hoy'),
                ),
              ],
            ),
          ),

          // Day pills row
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Row(
              children: List.generate(7, (i) {
                final day = _weekStart.add(Duration(days: i));
                final isToday = isSameDay(day, today);
                final hasEvents = byDayIndex[i]!.isNotEmpty;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black54,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const Divider(height: 1),

          // Events list
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : weekEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.event_available,
                                size: 48, color: Colors.black26),
                            SizedBox(height: 8),
                            Text('Sin eventos esta semana',
                                style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 7,
                        itemBuilder: (context, i) {
                          final day =
                              _weekStart.add(Duration(days: i));
                          final events = byDayIndex[i]!;
                          if (events.isEmpty) return const SizedBox.shrink();
                          return _DaySection(
                            day: day,
                            events: events,
                            isToday: isSameDay(day, today),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => EventDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<AppEvent> events;
  final bool isToday;

  const _DaySection({
    required this.day,
    required this.events,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat('EEEE, d MMMM');
    final timeFmt = DateFormat('HH:mm');
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isToday
                      ? null
                      : Border.all(color: Colors.black12),
                ),
                child: Text(
                  dayFmt.format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isToday ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...events.map(
          (e) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: e.flutterColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                e.allDay
                    ? 'Todo el día'
                    : '${timeFmt.format(e.startDatetime)} – ${timeFmt.format(e.endDatetime)}'
                        '${e.location != null ? '  ·  ${e.location}' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Eliminar')),
                ],
                onSelected: (v) async {
                  if (v == 'edit') {
                    await EventDialog.show(context, editEvent: e);
                  } else if (v == 'delete') {
                    if (context.mounted) {
                      await context.read<EventProvider>().deleteEvent(e.id);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
