import 'dart:math';

import 'package:atu_sligo_timetables/views/course.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:simple_timetable/simple_timetable.dart';

import '../def.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final Logger logger = Logger();
  final DateFormat _dayFormat = DateFormat.E();
  final format = DateFormat.jm();
  DateTime _currentDate = DateTime.now();
  late DateTime _selectedWeek;
  late Future<List<Event<Course>>> future;

  @override
  void initState() {
    super.initState();
    _selectedWeek = getWeekStart(DateTime(_currentDate.year));
    future = getCoursesByWeek(_selectedWeek);
  }

  DateTime getWeekStart(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: dt.weekday - 1));
  }

  TimeOfDay parseTimeOfDay(String time) {
    List<String> timeSplit = time.split(":");
    int hour = int.parse(timeSplit.first);
    int minute = int.parse(timeSplit.last);
    return TimeOfDay(hour: hour, minute: minute);
  }

  int weeksBetween(DateTime from, DateTime to) {
    from = DateTime.utc(from.year, from.month, from.day);
    to = DateTime.utc(to.year, to.month, to.day);
    return (to.difference(from).inDays / 7).ceil();
  }

  Future<List<Event<Course>>> getCoursesByWeek(DateTime weekStart) async {
    var weekNum = weeksBetween(semesterStart, weekStart) + 1;
    logger.d("Fetching data for week $weekNum");
    var url = Uri.parse(
        'http://timetables.itsligo.ie:81/reporting/textspreadsheet;student+set;id;SG_KGADV_B07%2FF%2FY2%2F1%2F%28A%29%0D%0A?days=1-7&=21&periods=3-20&=22&weeks=$weekNum&template=student+set+textspreadsheet');
    var response = await http.get(url);

    if (response.statusCode != 200) {
      return Future.error("Expected status code 200 got ${response.statusCode}");
    }
    var document = parse(response.body);

    List<Event<Course>> courses = [];
    for (int i = 0; i < 7; i++) {
      var table = document.body!.children[i * 2 + 2];
      var els = table.querySelector("tbody");
      if (els == null) continue;
      for (var raw in els.children.skip(1)) {
        try {
          var startTime = parseTimeOfDay(raw.children[3].text);
          var endTime = parseTimeOfDay(raw.children[4].text);
          var duration = parseTimeOfDay(raw.children[5].text);
          var startDate =
              weekStart.add(Duration(days: i, hours: startTime.hour, minutes: startTime.minute));
          var endDate = weekStart
              .add(Duration(days: i, hours: endTime.hour, minutes: endTime.minute - 1));
          var course = Course(
              raw.children[0].text,
              raw.children[1].text,
              CourseTypeDe.fromString(raw.children[2].text),
              startDate,
              endDate,
              duration,
              raw.children[7].text,
              raw.children[8].text,
              raw.children[9].text);
          courses.add(Event(
              id: "${course.name} / ${course.module}",
              start: startDate,
              end: endDate,
              date: startDate,
              payload: course));
        } catch (e) {
          logger.w("Could not parse course", e);
        }
      }
    }
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<Event<Course>>? agenda = snapshot.data;
              if (agenda != null) {
                return RefreshIndicator(
                  onRefresh: () async {
                    future = getCoursesByWeek(_selectedWeek);
                    await future;
                  },
                  child: SimpleTimetable<Course>(
                    onChange: (current, _) {
                      DateTime newWeekStart = getWeekStart(current.first);
                      if (_selectedWeek != newWeekStart) {
                        setState(() {
                          _selectedWeek = newWeekStart;
                          future = getCoursesByWeek(_selectedWeek);
                        });
                      }
                      _currentDate = current.first;
                    },
                    initialDate: _currentDate,
                    dayStart: 8,
                    dayEnd: 20,
                    visibleRange: width < 600 ? 1 : min((width / 240).floor(), 7),
                    events: agenda,
                    cellHeight: 60 + width/80,
                    buildHeader: (date, isToday) {
                      final dark = Theme.of(context).brightness == Brightness.dark;
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday ? (dark ? Colors.white : Colors.black) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          child: DefaultTextStyle(
                            style: TextStyle(color: isToday == dark ? Colors.black : Colors.white),
                            child: Column(
                              children: [
                                Text(_dayFormat.format(date), style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(date.day.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    buildCard: (event, isPast) {
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
                            border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white),
                            borderRadius: BorderRadius.circular(4),
                            color: event.payload != null
                                ? event.payload!.type.color()
                                : (isPast ? Colors.grey[400] : Colors.blue[200]?.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              Flexible(
                                child: AutoSizeText(
                                  '${event.payload?.name}',
                                  minFontSize: 10,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    },
                  ),
                );
              } else {
                return Text(snapshot.error.toString());
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
          future: future,
        ),
      ),
    );
  }
}
