import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/event.dart';
import '../../core/providers/event_provider.dart';
import '../theme/app_theme.dart';

class EventDialog extends StatefulWidget {
  final DateTime? initialDate;
  final AppEvent? editEvent; // null = create, not null = edit

  const EventDialog({super.key, this.initialDate, this.editEvent});

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    AppEvent? editEvent,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          EventDialog(initialDate: initialDate, editEvent: editEvent),
    );
  }

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  String _color = '#4F46E5';
  bool _allDay = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    if (widget.editEvent != null) {
      final e = widget.editEvent!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description ?? '';
      _locationCtrl.text = e.location ?? '';
      _start = e.startDatetime;
      _end = e.endDatetime;
      _color = e.color;
      _allDay = e.allDay;
    } else {
      _start = DateTime(base.year, base.month, base.day, 9);
      _end = DateTime(base.year, base.month, base.day, 10);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
      );
      if (time == null || !mounted) return;
      final dt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      setState(() {
        if (isStart) {
          _start = dt;
          if (_end.isBefore(_start)) {
            _end = _start.add(const Duration(hours: 1));
          }
        } else {
          _end = dt;
        }
      });
    } else {
      setState(() {
        if (isStart) {
          _start = DateTime(date.year, date.month, date.day);
        } else {
          _end = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<EventProvider>();
    bool ok;

    if (widget.editEvent != null) {
      ok = await provider.updateEvent(widget.editEvent!.id, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'start_datetime': _start.toIso8601String(),
        'end_datetime': _end.toIso8601String(),
        'color': _color,
        'all_day': _allDay,
        'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      });
    } else {
      ok = await provider.createEvent(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        start: _start,
        end: _end,
        color: _color,
        allDay: _allDay,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el evento')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final isEdit = widget.editEvent != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar evento' : 'Nuevo evento'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // All day toggle
                SwitchListTile.adaptive(
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                  title: const Text('Todo el día'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                // Start date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Inicio'),
                  subtitle: Text(fmt.format(_start)),
                  onTap: () => _pickDateTime(true),
                ),

                // End date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Fin'),
                  subtitle: Text(fmt.format(_end)),
                  onTap: () => _pickDateTime(false),
                ),

                const SizedBox(height: 12),

                // Color picker
                const Text('Color del evento',
                    style:
                        TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppTheme.eventColorHex
                      .asMap()
                      .entries
                      .map((entry) {
                    final hex = entry.value;
                    final selected = _color == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.eventColors[entry.key],
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: Colors.black, width: 2)
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
