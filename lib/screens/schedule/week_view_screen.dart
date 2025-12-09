import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_item.dart';
import 'add_edit_schedule_screen.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _selectedWeek;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedWeek = _getWeekStart(DateTime.now());
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getWeekTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedWeek = _getWeekStart(DateTime.now());
                _pageController.jumpToPage(1000);
              });
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final offset = index - 1000;
          setState(() {
            _selectedWeek = _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
          });
        },
        itemBuilder: (context, index) {
          final offset = index - 1000;
          final weekStart = _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
          return _buildWeekView(weekStart);
        },
      ),
    );
  }

  String _getWeekTitle() {
    final weekEnd = _selectedWeek.add(const Duration(days: 6));
    final monthNames = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${_selectedWeek.day}. ${monthNames[_selectedWeek.month - 1]} - ${weekEnd.day}. ${monthNames[weekEnd.month - 1]}';
  }

  Widget _buildWeekView(DateTime weekStart) {
    final weekDays = _getWeekDays(weekStart);

    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Header with day names
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: weekDays.map((day) {
                  final isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][day.weekday - 1],
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Schedule grid
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weekDays.map((day) {
                    final dayItems = provider.getItemsForDate(day);

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: dayItems.isEmpty
                            ? Container(
                                height: 100,
                                alignment: Alignment.center,
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 24,
                                  ),
                                ),
                              )
                            : Column(
                                children: dayItems.map((item) {
                                  return _buildEventCard(item);
                                }).toList(),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(ScheduleItem item) {
    final timeFormat = DateFormat('HH:mm');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditScheduleScreen(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (item.color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
          border: Border(
            left: BorderSide(
              color: item.color ?? Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeFormat.format(item.startTime),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: item.color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.location != null) ...[
              const SizedBox(height: 2),
              Text(
                item.location!,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
