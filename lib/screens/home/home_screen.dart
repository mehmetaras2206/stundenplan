import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/theme_provider.dart';
import '../schedule/add_edit_schedule_screen.dart';
import '../categories/categories_screen.dart';
import '../schedule/week_view_screen.dart';
import '../schedule/search_screen.dart';
import '../stats/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../activity/activity_tracker_screen.dart';
import '../../widgets/schedule_item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  int _currentIndex = 0; // 0 = Schedule, 1 = Activity Tracker

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadData();
    });
  }

  Widget _buildScheduleView() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        if (scheduleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedDayItems = scheduleProvider.getItemsForDate(_selectedDay!);

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.week: 'Woche',
                  CalendarFormat.twoWeeks: '2 Wochen',
                  CalendarFormat.month: 'Monat',
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!mounted) return;
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  return scheduleProvider.getItemsForDate(day);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                ),
                daysOfWeekHeight: 40,
                rowHeight: 48,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Veranstaltungen am ${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedDayItems.length} ${selectedDayItems.length == 1 ? "Veranstaltung" : "Veranstaltungen"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedDayItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Veranstaltungen an diesem Tag',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: selectedDayItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      cacheExtent: 500,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        final item = selectedDayItems[index];
                        return ScheduleItemCard(
                          key: ValueKey(item.id),
                          item: item,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditScheduleScreen(
                                  item: item,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Mein Stundenplan' : 'Aktivitäts-Tracker'),
        actions: [
          // Schedule-specific buttons (only shown in schedule mode)
          if (_currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.view_week),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeekViewScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
          // Theme toggle (always visible)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              IconData themeIcon;
              String themeText;

              if (themeProvider.isLightMode) {
                themeIcon = Icons.light_mode;
                themeText = 'Hell';
              } else if (themeProvider.isDarkMode) {
                themeIcon = Icons.dark_mode;
                themeText = 'Dunkel';
              } else {
                themeIcon = Icons.brightness_auto;
                themeText = 'System';
              }

              return IconButton(
                icon: Icon(themeIcon),
                tooltip: 'Theme: $themeText',
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildScheduleView() : const ActivityTrackerScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Stundenplan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Zeit-Tracker',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? (MediaQuery.of(context).size.width < 600
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditScheduleScreen(
                          selectedDate: _selectedDay,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditScheduleScreen(
                          selectedDate: _selectedDay,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Neue Veranstaltung'),
                ))
          : null,
    );
  }
}
