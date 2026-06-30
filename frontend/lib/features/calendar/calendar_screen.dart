import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/event.dart';
import '../../core/providers/event_provider.dart';
import '../../shared/widgets/event_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final selectedEvents = provider.eventsForDay(_selectedDay);
    final eventsByDay = provider.eventsByDay;

    return Scaffold(
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar widget
                TableCalendar<AppEvent>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  calendarFormat: _format,
                  eventLoader: (day) {
                    final key =
                        DateTime(day.year, day.month, day.day);
                    return eventsByDay[key] ?? [];
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onFormatChanged: (f) => setState(() => _format = f),
                  onPageChanged: (f) => setState(() => _focusedDay = f),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonShowsNext: false,
                    titleCentered: true,
                  ),
                ),

                const Divider(height: 1),

                // Day events list
                Expanded(
                  child: selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_available,
                                  size: 48, color: Colors.black26),
                              const SizedBox(height: 8),
                              Text(
                                'Sin eventos el ${DateFormat('d MMM').format(_selectedDay)}',
                                style:
                                    const TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: selectedEvents.length,
                          itemBuilder: (context, i) {
                            return _EventTile(
                              event: selectedEvents[i],
                              onEdit: () => EventDialog.show(
                                context,
                                editEvent: selectedEvents[i],
                              ),
                              onDelete: () async {
                                final confirmed = await _confirmDelete(
                                    context);
                                if (confirmed == true && context.mounted) {
                                  await context
                                      .read<EventProvider>()
                                      .deleteEvent(selectedEvents[i].id);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            EventDialog.show(context, initialDate: _selectedDay),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content:
            const Text('¿Estás seguro de que quieres eliminar este evento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AppEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 12,
          decoration: BoxDecoration(
            color: event.flutterColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!event.allDay)
              Text(
                '${timeFmt.format(event.startDatetime)} – ${timeFmt.format(event.endDatetime)}',
                style: const TextStyle(fontSize: 13),
              )
            else
              const Text('Todo el día', style: TextStyle(fontSize: 13)),
            if (event.location != null)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.black45),
                  const SizedBox(width: 2),
                  Text(event.location!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit', child: Text('Editar')),
            const PopupMenuItem(
                value: 'delete', child: Text('Eliminar')),
          ],
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
        ),
        isThreeLine: event.location != null,
      ),
    );
  }
}
