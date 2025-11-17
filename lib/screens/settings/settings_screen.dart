import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/export_import_service.dart';
import 'predefined_activities_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final success = await _exportImportService.shareExportedData();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daten erfolgreich exportiert!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export abgebrochen oder fehlgeschlagen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData({bool clearFirst = false}) async {
    if (clearFirst) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daten ersetzen?'),
          content: const Text(
            'Möchten Sie wirklich alle bestehenden Daten löschen und durch die importierten Daten ersetzen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ersetzen'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isImporting = true);

    try {
      if (clearFirst) {
        await _exportImportService.clearAllData();
      }

      final result = await _exportImportService.importData();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data
        await context.read<ScheduleProvider>().loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Import: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aktivitäts-Tracker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.purple),
              title: const Text('Aktivitäten verwalten'),
              subtitle: const Text(
                'Vordefinierte Aktivitäten für Zeit-Tracking erstellen',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PredefinedActivitiesScreen(),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
            child: Text(
              'Daten sichern & übertragen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: const Text('Stundenplan exportieren'),
                  subtitle: const Text(
                    'Speichern Sie alle Veranstaltungen und Kategorien als Datei',
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('Stundenplan importieren (Hinzufügen)'),
                  subtitle: const Text(
                    'Importieren Sie Daten aus einer Backup-Datei (bestehende Daten bleiben erhalten)',
                  ),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isImporting ? null : () => _importData(clearFirst: false),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_alt, color: Colors.orange),
                  title: const Text('Stundenplan importieren (Ersetzen)'),
                  subtitle: const Text(
                    'Löschen Sie alle Daten und importieren Sie aus einer Backup-Datei',
                  ),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isImporting ? null : () => _importData(clearFirst: true),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'So funktioniert\'s',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    icon: Icons.upload_file,
                    title: 'Exportieren',
                    description:
                        'Erstellt eine JSON-Datei mit allen Ihren Daten. Sie können diese Datei über Cloud-Dienste (WhatsApp, E-Mail, Google Drive, etc.) teilen.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.download,
                    title: 'Importieren (Hinzufügen)',
                    description:
                        'Fügt Daten aus einer Backup-Datei hinzu. Bestehende Daten bleiben erhalten.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.sync_alt,
                    title: 'Importieren (Ersetzen)',
                    description:
                        'Löscht ALLE bestehenden Daten und ersetzt sie durch die importierten Daten. Nutzen Sie diese Option beim Umzug auf ein neues Gerät.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
