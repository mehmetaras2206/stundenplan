import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/predefined_activity.dart';
import '../../providers/activity_provider.dart';

class PredefinedActivitiesScreen extends StatefulWidget {
  const PredefinedActivitiesScreen({super.key});

  @override
  State<PredefinedActivitiesScreen> createState() =>
      _PredefinedActivitiesScreenState();
}

class _PredefinedActivitiesScreenState
    extends State<PredefinedActivitiesScreen> {
  Future<void> _showAddEditDialog({PredefinedActivity? activity}) async {
    final isEdit = activity != null;
    final nameController = TextEditingController(text: activity?.name ?? '');
    Color selectedColor = activity?.color ?? Colors.blue;
    IconData? selectedIcon = activity?.icon;

    // Common activity icons
    final availableIcons = [
      Icons.fitness_center,
      Icons.sports_soccer,
      Icons.sports_basketball,
      Icons.directions_run,
      Icons.self_improvement,
      Icons.school,
      Icons.menu_book,
      Icons.laptop,
      Icons.code,
      Icons.brush,
      Icons.music_note,
      Icons.videogame_asset,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.work,
      Icons.home,
      Icons.favorite,
      Icons.pets,
      Icons.shopping_cart,
      Icons.directions_car,
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Aktivität bearbeiten' : 'Neue Aktivität'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z.B. Sport, Lernen, Kochen',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEdit,
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text(
                  'Farbe',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    Color? pickedColor = await showDialog<Color>(
                      context: context,
                      builder: (BuildContext context) {
                        Color tempColor = selectedColor;
                        return AlertDialog(
                          title: const Text('Farbe wählen'),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: selectedColor,
                              onColorChanged: (color) {
                                tempColor = color;
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Abbrechen'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () =>
                                  Navigator.of(context).pop(tempColor),
                            ),
                          ],
                        );
                      },
                    );
                    if (pickedColor != null) {
                      setDialogState(() {
                        selectedColor = pickedColor;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text(
                        'Farbe wählen',
                        style: TextStyle(
                          color: selectedColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Icon picker
                const Text(
                  'Icon (optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: availableIcons.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "No icon" option
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedIcon == null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                width: selectedIcon == null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.block, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final icon = availableIcons[index - 1];
                      final isSelected = selectedIcon == icon;

                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

                final activityProvider = context.read<ActivityProvider>();
                final now = DateTime.now();

                if (isEdit) {
                  final updated = activity.copyWith(
                    name: nameController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                    updatedAt: now,
                  );
                  await activityProvider.updatePredefinedActivity(updated);
                } else {
                  final newActivity = PredefinedActivity(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                    createdAt: now,
                    updatedAt: now,
                  );
                  await activityProvider.addPredefinedActivity(newActivity);
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(isEdit ? 'Speichern' : 'Hinzufügen'),
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
        title: const Text('Aktivitäten verwalten'),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, _) {
          if (activityProvider.predefinedActivities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
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
                    'Erstelle deine erste Aktivität!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activityProvider.predefinedActivities.length,
            itemBuilder: (context, index) {
              final activity = activityProvider.predefinedActivities[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: activity.color,
                    child: activity.icon != null
                        ? Icon(
                            activity.icon,
                            color: (activity.color?.computeLuminance() ?? 0) > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : Text(
                            activity.name[0].toUpperCase(),
                            style: TextStyle(
                              color: (activity.color?.computeLuminance() ?? 0) > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    activity.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(activity: activity),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Aktivität löschen?'),
                              content: Text(
                                  'Möchtest du "${activity.name}" wirklich löschen?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Abbrechen'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Löschen'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await activityProvider
                                .deletePredefinedActivity(activity.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Neue Aktivität'),
      ),
    );
  }
}
