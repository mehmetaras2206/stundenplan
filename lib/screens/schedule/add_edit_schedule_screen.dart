import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/schedule_item.dart';
import '../../models/category.dart';
import '../../providers/schedule_provider.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final ScheduleItem? item;
  final DateTime? selectedDate;

  const AddEditScheduleScreen({
    super.key,
    this.item,
    this.selectedDate,
  });

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  Color _selectedColor = const Color(0xFF6366F1);
  String? _selectedCategoryId;
  String? _eventType; // Vorlesung, Übung, Hausaufgaben, etc.
  String? _recurrenceType; // null = einmalig, daily, weekly, biweekly, monthly, yearly

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title);
    _descriptionController = TextEditingController(text: widget.item?.description);
    _locationController = TextEditingController(text: widget.item?.location);
    _selectedCategoryId = widget.item?.categoryId;
    _eventType = widget.item?.eventType;

    if (widget.item != null) {
      _selectedDate = DateTime(
        widget.item!.startTime.year,
        widget.item!.startTime.month,
        widget.item!.startTime.day,
      );
      _startTime = TimeOfDay.fromDateTime(widget.item!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.item!.endTime);
      _selectedColor = widget.item!.color ?? const Color(0xFF6366F1);
      _recurrenceType = widget.item!.isRecurring ? widget.item!.recurrenceRule : null;
    } else {
      _selectedDate = widget.selectedDate ?? DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (time == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = time;
        // Ensure end time is after start time
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      } else {
        _endTime = time;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time range
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endzeit muss nach Startzeit liegen')),
      );
      return;
    }

    // Create DateTime from date and time
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final scheduleProvider = context.read<ScheduleProvider>();
    final item = ScheduleItem(
      id: widget.item?.id ?? const Uuid().v4(),
      userId: widget.item?.userId ?? '',
      title: _titleController.text.trim(),
      eventType: _eventType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      color: _selectedColor,
      categoryId: _selectedCategoryId,
      isRecurring: _recurrenceType != null,
      recurrenceRule: _recurrenceType,
      createdAt: widget.item?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.item == null) {
        await scheduleProvider.addScheduleItem(item);
      } else {
        await scheduleProvider.updateScheduleItem(item);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veranstaltung löschen'),
        content: const Text('Möchten Sie diese Veranstaltung wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<ScheduleProvider>().deleteScheduleItem(widget.item!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Neue Veranstaltung' : 'Veranstaltung bearbeiten'),
        actions: widget.item != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _delete,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Veranstaltungsname *',
                hintText: 'z.B. Mathematik I',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Namen eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'z.B. Vorlesung, Dozent, Themen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Raum/Ort',
                hintText: 'z.B. Hörsaal A, Raum 3.14',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
            ),
            const SizedBox(height: 24),
            Consumer<ScheduleProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('Kategorie wählen (optional)'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Keine Kategorie'),
                        ),
                        ...provider.categories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await _showCreateCategoryDialog(context, provider);
                        if (result != null && mounted) {
                          setState(() => _selectedCategoryId = result);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Neue Kategorie erstellen'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Veranstaltungstyp (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _eventType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_note),
                helperText: 'z.B. Vorlesung, Übung, Hausaufgaben',
              ),
              hint: const Text('Typ wählen (optional)'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Kein Typ')),
                DropdownMenuItem(value: 'Vorlesung', child: Text('Vorlesung')),
                DropdownMenuItem(value: 'Übung', child: Text('Übung')),
                DropdownMenuItem(value: 'Tutorium', child: Text('Tutorium')),
                DropdownMenuItem(value: 'Seminar', child: Text('Seminar')),
                DropdownMenuItem(value: 'Praktikum', child: Text('Praktikum')),
                DropdownMenuItem(value: 'Hausaufgaben', child: Text('Hausaufgaben')),
                DropdownMenuItem(value: 'Prüfung', child: Text('Prüfung')),
                DropdownMenuItem(value: 'Projekt', child: Text('Projekt')),
                DropdownMenuItem(value: 'Labor', child: Text('Labor')),
              ],
              onChanged: (value) {
                setState(() => _eventType = value);
              },
            ),
            const SizedBox(height: 24),
            const Text('Datum und Zeit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Datum'),
              subtitle: Text(
                '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Startuhrzeit'),
                    subtitle: Text(
                      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                    ),
                    leading: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Enduhrzeit'),
                    subtitle: Text(
                      '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                    ),
                    leading: const Icon(Icons.access_time_filled),
                    onTap: () => _selectTime(false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Wiederholung (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _recurrenceType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
                helperText: 'Leer lassen für einmalige Veranstaltung',
              ),
              hint: const Text('Keine Wiederholung (Einmalig)'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Keine Wiederholung (Einmalig)')),
                DropdownMenuItem(value: 'daily', child: Text('Täglich')),
                DropdownMenuItem(value: 'weekly', child: Text('Wöchentlich')),
                DropdownMenuItem(value: 'biweekly', child: Text('Zweiwöchentlich')),
                DropdownMenuItem(value: 'monthly', child: Text('Monatlich')),
                DropdownMenuItem(value: 'yearly', child: Text('Jährlich')),
              ],
              onChanged: (value) {
                setState(() => _recurrenceType = value);
              },
            ),
            const SizedBox(height: 24),
            const Text('Farbe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemSize = (constraints.maxWidth - 84) / 8; // 8 items with spacing
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Color(0xFF6366F1),
                    const Color(0xFFEF4444),
                    const Color(0xFF10B981),
                    const Color(0xFFF59E0B),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                    const Color(0xFF06B6D4),
                    const Color(0xFF84CC16),
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: itemSize.clamp(40, 50),
                        height: itemSize.clamp(40, 50),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Speichern'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCreateCategoryDialog(BuildContext context, ScheduleProvider provider) async {
    final nameController = TextEditingController();
    Color selectedColor = const Color(0xFF6366F1);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Neue Kategorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategoriename',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Farbe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Color(0xFF6366F1),
                    const Color(0xFFEF4444),
                    const Color(0xFF10B981),
                    const Color(0xFFF59E0B),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                    const Color(0xFF06B6D4),
                    const Color(0xFF84CC16),
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Namen eingeben')),
                  );
                  return;
                }

                final category = Category(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  color: selectedColor,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await provider.addCategory(category);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, category.id);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler: $e')),
                    );
                  }
                }
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}
