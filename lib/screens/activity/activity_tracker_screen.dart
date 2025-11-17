import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/activity_track.dart';
import 'activity_stats_screen.dart';

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  String _activitySource = 'predefined'; // 'predefined' or 'schedule'
  String? _selectedScheduleItemId;
  String? _selectedPredefinedActivityId;
  String? _selectedCategoryId; // For filtering schedule items by category

  Future<void> _showStartActivityDialog() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final activityProvider = context.read<ActivityProvider>();

    // Reset selections
    setState(() {
      _activitySource = activityProvider.predefinedActivities.isNotEmpty ? 'predefined' : 'schedule';
      _selectedScheduleItemId = null;
      _selectedPredefinedActivityId = null;
      _selectedCategoryId = null;
    });

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aktivität starten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Source Toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'predefined',
                      label: Text('Aktivität'),
                      icon: Icon(Icons.fitness_center),
                    ),
                    ButtonSegment<String>(
                      value: 'schedule',
                      label: Text('Veranstaltung'),
                      icon: Icon(Icons.school),
                    ),
                  ],
                  selected: {_activitySource},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      _activitySource = newSelection.first;
                      _selectedScheduleItemId = null;
                      _selectedPredefinedActivityId = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Selection based on source
                if (_activitySource == 'predefined') ...[
                  if (activityProvider.predefinedActivities.isEmpty) ...[
                    const Text(
                      'Keine Aktivitäten vorhanden',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erstelle Aktivitäten in den Einstellungen.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Aktivität auswählen',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      hint: const Text('Aktivität wählen'),
                      initialValue: _selectedPredefinedActivityId,
                      items: activityProvider.predefinedActivities.map((activity) {
                        return DropdownMenuItem<String>(
                          value: activity.id,
                          child: Row(
                            children: [
                              if (activity.color != null)
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: activity.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (activity.color != null) const SizedBox(width: 8),
                              if (activity.icon != null)
                                Icon(activity.icon, size: 18),
                              if (activity.icon != null) const SizedBox(width: 8),
                              Expanded(child: Text(activity.name)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedPredefinedActivityId = value);
                      },
                    ),
                  ],
                ] else ...[
                  if (scheduleProvider.scheduleItems.isEmpty) ...[
                    const Text(
                      'Keine Veranstaltungen vorhanden',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erstelle Veranstaltungen im Stundenplan.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ] else ...[
                    // Category filter first
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Kategorie auswählen',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('Kategorie wählen'),
                      initialValue: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle Kategorien'),
                        ),
                        ...scheduleProvider.categories.map((category) {
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
                                Expanded(child: Text(category.name)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategoryId = value;
                          _selectedScheduleItemId = null; // Reset schedule item selection
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Schedule item selection (filtered by category)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Veranstaltung auswählen',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      hint: const Text('Veranstaltung wählen'),
                      initialValue: _selectedScheduleItemId,
                      items: scheduleProvider.scheduleItems
                          .where((item) =>
                              _selectedCategoryId == null ||
                              item.categoryId == _selectedCategoryId)
                          .map((item) {
                        final category = item.categoryId != null
                            ? scheduleProvider.getCategoryById(item.categoryId)
                            : null;
                        return DropdownMenuItem<String>(
                          value: item.id,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: category?.color ?? item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    if (item.eventType != null)
                                      Text(
                                        item.eventType!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedScheduleItemId = value);
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () async {
                // Validation
                if (_activitySource == 'predefined' && _selectedPredefinedActivityId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Aktivität auswählen')),
                  );
                  return;
                }
                if (_activitySource == 'schedule' && _selectedScheduleItemId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Veranstaltung auswählen')),
                  );
                  return;
                }

                // Determine name and metadata
                String activityName;
                String? categoryId;
                Color? color;

                if (_activitySource == 'predefined') {
                  final predefinedActivity = activityProvider.predefinedActivities
                      .firstWhere((a) => a.id == _selectedPredefinedActivityId);
                  activityName = predefinedActivity.name;
                  color = predefinedActivity.color;
                } else {
                  final scheduleItem = scheduleProvider.scheduleItems
                      .firstWhere((i) => i.id == _selectedScheduleItemId);
                  activityName = scheduleItem.title;
                  categoryId = scheduleItem.categoryId;
                  final category = categoryId != null
                      ? scheduleProvider.getCategoryById(categoryId)
                      : null;
                  color = category?.color ?? scheduleItem.color;
                }

                // Start activity
                await activityProvider.startActivity(
                  activityName: activityName,
                  scheduleItemId: _activitySource == 'schedule' ? _selectedScheduleItemId : null,
                  categoryId: categoryId,
                  predefinedActivityId: _activitySource == 'predefined' ? _selectedPredefinedActivityId : null,
                  color: color,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Starten'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitäts-Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivityStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, _) {
          if (activityProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Running Activity Card
              if (activityProvider.hasRunningTrack)
                _buildRunningTrackCard(activityProvider.runningTrack!),

              // Activity List
              Expanded(
                child: activityProvider.activityTracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Aktivitäten',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Starte deine erste Aktivität!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activityProvider.activityTracks.length,
                        itemBuilder: (context, index) {
                          final track = activityProvider.activityTracks[index];
                          if (track.isRunning) return const SizedBox.shrink();
                          return _buildTrackCard(track, activityProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStartActivityDialog,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Aktivität starten'),
      ),
    );
  }

  Widget _buildRunningTrackCard(ActivityTrack track) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      track.isPaused ? Icons.pause : Icons.fiber_manual_record,
                      color: track.isPaused ? Colors.orange : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      track.isPaused ? 'PAUSIERT' : 'LÄUFT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: track.isPaused ? Colors.orange : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  track.activityName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.formattedDuration,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (track.isPaused)
                      FilledButton.icon(
                        onPressed: () => provider.resumeActivity(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Fortsetzen'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => provider.pauseActivity(),
                        icon: const Icon(Icons.pause),
                        label: const Text('Pausieren'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: () => provider.stopActivity(),
                      icon: const Icon(Icons.stop),
                      label: const Text('Beenden'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackCard(ActivityTrack track, ActivityProvider provider) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final category = track.categoryId != null
        ? scheduleProvider.getCategoryById(track.categoryId)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: track.color ??
                category?.color ??
                Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          track.activityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatTimeRange(track.startTime, track.endTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (category != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              track.formattedDuration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(track);
                } else if (value == 'delete') {
                  provider.deleteTrack(track.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Bearbeiten'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Löschen'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}. ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(DateTime start, DateTime? end) {
    // Check if same day
    if (end != null &&
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      // Same day: show date once, then time range
      return '${start.day}.${start.month}.${start.year} | ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } else if (end != null) {
      // Different days: show full date and time for both
      return '${start.day}.${start.month}. ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.day}.${end.month}. ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } else {
      // Still running
      return '${start.day}.${start.month}.${start.year} | ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - läuft';
    }
  }

  Future<void> _showEditDialog(ActivityTrack track) async {
    final nameController = TextEditingController(text: track.activityName);
    DateTime selectedStartTime = track.startTime;
    DateTime? selectedEndTime = track.endTime;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivität bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Aktivitätsname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Startzeit'),
                  subtitle: Text(_formatDateTime(selectedStartTime)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedStartTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null && dialogContext.mounted) {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selectedStartTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedStartTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                if (selectedEndTime != null)
                  ListTile(
                    title: const Text('Endzeit'),
                    subtitle: Text(_formatDateTime(selectedEndTime!)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedEndTime!,
                        firstDate: selectedStartTime,
                        lastDate: DateTime.now(),
                      );
                      if (date != null && dialogContext.mounted) {
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(selectedEndTime!),
                        );
                        if (time != null) {
                          setState(() {
                            selectedEndTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
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

                if (selectedEndTime != null &&
                    selectedEndTime!.isBefore(selectedStartTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Endzeit muss nach Startzeit liegen')),
                  );
                  return;
                }

                final updated = track.copyWith(
                  activityName: nameController.text.trim(),
                  startTime: selectedStartTime,
                  endTime: selectedEndTime,
                );

                await context.read<ActivityProvider>().updateTrack(updated);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
