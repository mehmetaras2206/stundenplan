import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/schedule_provider.dart';

class ActivityStatsScreen extends StatefulWidget {
  const ActivityStatsScreen({super.key});

  @override
  State<ActivityStatsScreen> createState() => _ActivityStatsScreenState();
}

class _ActivityStatsScreenState extends State<ActivityStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _todayStart;
  late DateTime _todayEnd;
  late DateTime _weekStart;
  late DateTime _weekEnd;
  late DateTime _monthStart;
  late DateTime _monthEnd;

  // For custom week/month selection
  DateTime? _selectedWeek;
  DateTime? _customWeekStart;
  DateTime? _customWeekEnd;
  DateTime? _selectedMonth;
  DateTime? _customMonthStart;
  DateTime? _customMonthEnd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _calculateDates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateDates() {
    final now = DateTime.now();

    // Today
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Current calendar week (Monday to Sunday)
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    _weekStart = DateTime(now.year, now.month, now.day - (weekday - 1));
    _weekEnd = DateTime(_weekStart.year, _weekStart.month, _weekStart.day + 6, 23, 59, 59);

    // Current calendar month (1st to last day)
    _monthStart = DateTime(now.year, now.month, 1);
    _monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Initialize selected week to current week
    _selectedWeek = _weekStart;
    _updateCustomWeek(_selectedWeek!);

    // Initialize selected month to current month
    _selectedMonth = DateTime(now.year, now.month);
    _updateCustomMonth(_selectedMonth!);
  }

  void _updateCustomWeek(DateTime weekStart) {
    _customWeekStart = weekStart;
    _customWeekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6, 23, 59, 59);
  }

  void _updateCustomMonth(DateTime month) {
    _customMonthStart = DateTime(month.year, month.month, 1);
    _customMonthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitäts-Statistiken'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Heute'),
            Tab(text: 'Aktuelle KW'),
            Tab(text: 'Aktueller Monat'),
            Tab(text: 'KW auswählen'),
            Tab(text: 'Monat auswählen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsView(_todayStart, _todayEnd, 'Tag'),
          _buildStatsView(_weekStart, _weekEnd, 'Kalenderwoche'),
          _buildStatsView(_monthStart, _monthEnd, 'Kalendermonat'),
          _buildCustomWeekView(),
          _buildCustomMonthView(),
        ],
      ),
    );
  }

  Widget _buildStatsView(DateTime startDate, DateTime endDate, String period) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, _) {
        return FutureBuilder<Map<String, Duration>>(
          future: activityProvider.getStatsByActivity(
            startDate: startDate,
            endDate: endDate,
          ),
          builder: (context, activitySnapshot) {
            if (!activitySnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<Map<String, Duration>>(
              future: activityProvider.getStatsByCategory(
                startDate: startDate,
                endDate: endDate,
              ),
              builder: (context, categorySnapshot) {
                if (!categorySnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activityStats = activitySnapshot.data!;
                final categoryStats = categorySnapshot.data!;

                final totalDuration = activityStats.values.fold<Duration>(
                  Duration.zero,
                  (prev, duration) => prev + duration,
                );

                if (activityStats.isEmpty) {
                  String emptyMessage;
                  if (period == 'Tag') {
                    emptyMessage = 'Keine Aktivitäten heute';
                  } else if (period == 'Kalenderwoche') {
                    emptyMessage = 'Keine Aktivitäten in dieser Kalenderwoche';
                  } else if (period == 'Kalendermonat') {
                    emptyMessage = 'Keine Aktivitäten in diesem Kalendermonat';
                  } else {
                    emptyMessage = 'Keine Aktivitäten im $period';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total Time Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Gesamt-Zeit',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(totalDuration),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getDaysInPeriod(startDate, endDate)} Tage',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats by Activity
                    Text(
                      'Nach Aktivität',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...activityStats.entries.map((entry) {
                      final percentage = totalDuration.inSeconds > 0
                          ? (entry.value.inSeconds / totalDuration.inSeconds)
                          : 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(entry.value),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Stats by Category
                    if (categoryStats.isNotEmpty) ...[
                      Text(
                        'Nach Kategorie',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Consumer<ScheduleProvider>(
                        builder: (context, scheduleProvider, _) {
                          // Create a map of category name -> category object
                          final categoryMap = {
                            for (var cat in scheduleProvider.categories)
                              cat.name: cat
                          };

                          return Column(
                            children: categoryStats.entries.map((entry) {
                              final percentage = totalDuration.inSeconds > 0
                                  ? (entry.value.inSeconds / totalDuration.inSeconds)
                                  : 0.0;

                              // Find category object to check for weekly goal
                              final category = categoryMap[entry.key];
                              final hasWeeklyGoal = category?.weeklyGoalHours != null;
                              final trackedHours = entry.value.inMinutes / 60.0;
                              final goalHours = category?.weeklyGoalHours ?? 0;
                              final remainingHours = goalHours - trackedHours;
                              final goalProgress = hasWeeklyGoal && goalHours > 0
                                  ? (trackedHours / goalHours).clamp(0.0, 1.0)
                                  : percentage;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(entry.value),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (hasWeeklyGoal) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ziel: ${goalHours.toStringAsFixed(1)}h${period == 'Kalenderwoche' ? ' / Woche' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: hasWeeklyGoal ? goalProgress : percentage,
                                          minHeight: 8,
                                          backgroundColor: Colors.grey[300],
                                          color: hasWeeklyGoal
                                              ? (trackedHours >= goalHours
                                                  ? Colors.green
                                                  : Theme.of(context).primaryColor)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hasWeeklyGoal
                                            ? (remainingHours > 0
                                                ? 'Noch ${remainingHours.toStringAsFixed(1)}h übrig'
                                                : 'Ziel erreicht! (+${(-remainingHours).toStringAsFixed(1)}h)')
                                            : '${(percentage * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasWeeklyGoal && trackedHours >= goalHours
                                              ? Colors.green[700]
                                              : Colors.grey[600],
                                          fontWeight: hasWeeklyGoal && trackedHours >= goalHours
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  int _getDaysInPeriod(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  Widget _buildCustomMonthView() {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime>(
                  decoration: const InputDecoration(
                    labelText: 'Monat auswählen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  hint: Text(_selectedMonth != null
                      ? '${_getMonthName(_selectedMonth!.month)} ${_selectedMonth!.year}'
                      : 'Monat wählen'),
                  items: _generateMonthDropdownItems(),
                  onChanged: (DateTime? newMonth) {
                    if (newMonth != null) {
                      setState(() {
                        _selectedMonth = newMonth;
                        _updateCustomMonth(newMonth);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Stats view
        Expanded(
          child: _buildStatsView(
            _customMonthStart!,
            _customMonthEnd!,
            'ausgewählten Monat',
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<DateTime>> _generateMonthDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    final now = DateTime.now();

    // Generate last 24 months
    for (int i = 0; i < 24; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(month.month);
      final label = '$monthName ${month.year}';

      items.add(
        DropdownMenuItem<DateTime>(
          value: month,
          child: Text(label),
        ),
      );
    }

    return items;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return monthNames[month - 1];
  }

  Widget _buildCustomWeekView() {
    return Column(
      children: [
        // Week selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime>(
                  decoration: const InputDecoration(
                    labelText: 'Kalenderwoche auswählen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  hint: Text(_selectedWeek != null
                      ? _formatWeekLabel(_selectedWeek!)
                      : 'Woche wählen'),
                  items: _generateWeekDropdownItems(),
                  onChanged: (DateTime? newWeek) {
                    if (newWeek != null) {
                      setState(() {
                        _selectedWeek = newWeek;
                        _updateCustomWeek(newWeek);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Stats view
        Expanded(
          child: _buildStatsView(
            _customWeekStart!,
            _customWeekEnd!,
            'ausgewählte Woche',
          ),
        ),
      ],
    );
  }

  String _formatWeekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return 'KW ${_getWeekNumber(weekStart)}: ${weekStart.day}.${weekStart.month}. - ${weekEnd.day}.${weekEnd.month}.${weekEnd.year}';
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  List<DropdownMenuItem<DateTime>> _generateWeekDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    final now = DateTime.now();

    // Generate last 12 weeks
    for (int i = 0; i < 12; i++) {
      final weekDate = now.subtract(Duration(days: i * 7));
      final weekday = weekDate.weekday;
      final weekStart = weekDate.subtract(Duration(days: weekday - 1));
      final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final label = _formatWeekLabel(monday);

      items.add(
        DropdownMenuItem<DateTime>(
          value: monday,
          child: Text(label),
        ),
      );
    }

    return items;
  }
}
