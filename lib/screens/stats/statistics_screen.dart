import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_item.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'week'; // week, month, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = _calculateStats(provider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zeitraum',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'week',
                            label: Text('Woche'),
                            icon: Icon(Icons.view_week),
                          ),
                          ButtonSegment(
                            value: 'month',
                            label: Text('Monat'),
                            icon: Icon(Icons.calendar_month),
                          ),
                          ButtonSegment(
                            value: 'all',
                            label: Text('Gesamt'),
                            icon: Icon(Icons.all_inclusive),
                          ),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _selectedPeriod = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total events
              _buildStatCard(
                icon: Icons.event,
                title: 'Gesamt Veranstaltungen',
                value: stats['totalEvents'].toString(),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),

              // Total hours
              _buildStatCard(
                icon: Icons.access_time,
                title: 'Gesamt Stunden',
                value: '${stats['totalHours'].toStringAsFixed(1)} h',
                color: Colors.green,
              ),
              const SizedBox(height: 12),

              // Average duration
              _buildStatCard(
                icon: Icons.timelapse,
                title: 'Durchschnittliche Dauer',
                value: '${stats['avgDuration'].toStringAsFixed(1)} h',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),

              // Upcoming events
              _buildStatCard(
                icon: Icons.upcoming,
                title: 'Anstehende Veranstaltungen',
                value: stats['upcomingEvents'].toString(),
                color: Colors.purple,
              ),
              const SizedBox(height: 24),

              // Category breakdown
              if (provider.categories.isNotEmpty) ...[
                const Text(
                  'Veranstaltungen pro Kategorie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCategoryBreakdown(stats['categoryBreakdown'], provider),
                const SizedBox(height: 24),
              ],

              // Busiest day
              const Text(
                'Aktivste Tage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildBusiestDays(stats['busiestDays']),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateStats(ScheduleProvider provider) {
    final now = DateTime.now();
    List<ScheduleItem> items;

    // Filter items based on selected period
    switch (_selectedPeriod) {
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        items = provider.getItemsForDateRange(weekStart, weekEnd);
        break;
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        items = provider.getItemsForDateRange(monthStart, monthEnd);
        break;
      default:
        items = provider.scheduleItems;
    }

    // Calculate total hours
    double totalHours = 0;
    for (final item in items) {
      totalHours += item.duration.inMinutes / 60.0;
    }

    // Calculate average duration
    final avgDuration = items.isEmpty ? 0.0 : totalHours / items.length;

    // Count upcoming events
    final upcomingEvents = items.where((item) => item.startTime.isAfter(now)).length;

    // Category breakdown
    final categoryBreakdown = <String, int>{};
    for (final item in items) {
      if (item.categoryId != null) {
        final category = provider.getCategoryById(item.categoryId);
        if (category != null) {
          categoryBreakdown[category.name] = (categoryBreakdown[category.name] ?? 0) + 1;
        }
      } else {
        categoryBreakdown['Keine Kategorie'] = (categoryBreakdown['Keine Kategorie'] ?? 0) + 1;
      }
    }

    // Busiest days (day of week)
    final dayBreakdown = <String, int>{};
    final weekdayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    for (final item in items) {
      final dayName = weekdayNames[item.startTime.weekday - 1];
      dayBreakdown[dayName] = (dayBreakdown[dayName] ?? 0) + 1;
    }

    // Sort busiest days
    final sortedDays = dayBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalEvents': items.length,
      'totalHours': totalHours,
      'avgDuration': avgDuration,
      'upcomingEvents': upcomingEvents,
      'categoryBreakdown': categoryBreakdown,
      'busiestDays': sortedDays.take(3).toList(),
    };
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    Map<String, int> breakdown,
    ScheduleProvider provider,
  ) {
    if (breakdown.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Keine Daten verfügbar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final sortedCategories = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedCategories.map((entry) {
            final category = provider.categories
                .where((c) => c.name == entry.key)
                .firstOrNull;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  if (category != null)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (category == null)
                    Icon(Icons.circle_outlined, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBusiestDays(List<MapEntry<String, int>> days) {
    if (days.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Keine Daten verfügbar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;

            IconData medal;
            Color medalColor;

            switch (index) {
              case 0:
                medal = Icons.emoji_events;
                medalColor = Colors.amber;
                break;
              case 1:
                medal = Icons.emoji_events;
                medalColor = Colors.grey[400]!;
                break;
              default:
                medal = Icons.emoji_events;
                medalColor = Colors.brown[300]!;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(medal, color: medalColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      day.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${day.value} ${day.value == 1 ? "Veranstaltung" : "Veranstaltungen"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
