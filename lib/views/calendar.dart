import 'dart:math';

import 'package:atu_sligo_timetables/views/course.dart';
import 'package:atu_sligo_timetables/views/header.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:simple_timetable/simple_timetable.dart';

import '../timetable.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  final Logger logger = Logger();
  final DateFormat _dayFormat = DateFormat.E();
  final format = DateFormat.jm();
  DateTime _currentDate = DateTime.now();
  late DateTime _selectedWeek;
  late Future<List<Event<Course>>> future;

  @override
  void initState() {
    super.initState();
    _selectedWeek = getWeekStart(_currentDate);
  }

  Widget _buildHeader(DateTime date, bool isToday) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? (dark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: DefaultTextStyle(
          style:
              TextStyle(color: isToday == dark ? Colors.black : Colors.white),
          child: Column(
            children: [
              Text(_dayFormat.format(date),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(date.day.toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Event<Course> event, bool isPast) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        if (event.payload != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CourseView(course: event.payload!)));
        } else {
          logger.e("No course data => event.payload is null");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white),
          borderRadius: BorderRadius.circular(4),
          color: event.payload != null
              ? event.payload!.type.color()
              : (isPast
                  ? Colors.grey[400]
                  : Colors.blue[200]?.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Flexible(
              child: AutoSizeText(
                '${event.payload?.name}',
                minFontSize: 10,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: AutoSizeText(
                '${event.payload?.room}',
                minFontSize: 8,
                style: const TextStyle(fontSize: 12),
                maxFontSize: 12,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    AsyncValue<List<Event<Course>>> courses =
        ref.watch(coursesByWeekProvider(_selectedWeek));
    return Scaffold(
      body: SafeArea(
        child: courses.when(
          data: (agenda) {
            return Column(
              children: [
                CalendarHeader(
                  weekStart: _selectedWeek,
                  changeDate: (newDate) {
                    DateTime newWeekStart = getWeekStart(newDate);
                    if (_selectedWeek != newWeekStart) {
                      _selectedWeek = newWeekStart;
                    }
                    setState(() {
                      _currentDate = newDate;
                    });
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      return await ref
                          .refresh(coursesByWeekProvider(_selectedWeek));
                    },
                    child: SimpleTimetable<Course>(
                      onChange: (current, _) {
                        DateTime newWeekStart = getWeekStart(current.first);
                        if (_selectedWeek != newWeekStart) {
                          _selectedWeek = newWeekStart;
                        }
                        setState(() {
                          _currentDate = current.first;
                        });
                      },
                      initialDate: _currentDate,
                      dayStart: 8,
                      dayEnd: 20,
                      visibleRange:
                          width < 450 ? 1 : min((width / 200).floor(), 7),
                      events: agenda,
                      cellHeight: 60 + width / 80,
                      buildHeader: _buildHeader,
                      buildCard: _buildCard,
                    ),
                  ),
                ),
              ],
            );
          },
          error: (e, _) => GestureDetector(
            child: Center(child: Text("$e (Tap to retry)")),
            onTap: () => ref.refresh(coursesByWeekProvider(_selectedWeek)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
