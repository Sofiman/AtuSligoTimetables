import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:simple_timetable/simple_timetable.dart';

final DateTime semesterStart = DateTime(2022, 8, 22);

enum CourseType {
  unknown,
  lecture,
  practical;

  @override
  String toString() {
    switch (this) {
      case CourseType.lecture:
        return "Lecture";
      case CourseType.practical:
        return "Practical";
      default:
        return "Unknown";
    }
  }
}

extension CourseTypeDe on CourseType {
  static CourseType fromString(String name) {
    switch (name) {
      case "Lecture":
        return CourseType.lecture;
      case "Practical":
        return CourseType.practical;
      default:
        return CourseType.unknown;
    }
  }
}

extension CourseTypeDisplay on CourseType {
  Color color() {
    switch (this) {
      case CourseType.lecture:
        return Colors.orange[200]!.withOpacity(0.5);
      case CourseType.practical:
        return Colors.blue[200]!.withOpacity(0.5);
      default:
        return Colors.grey[200]!;
    }
  }
}

class Course {
  final String name;
  final String module;
  final CourseType type;
  final DateTime start;
  final DateTime end;
  final TimeOfDay duration;
  final String room;
  final String staff;
  final String studentGroups;

  Course(this.name, this.module, this.type, this.start, this.end, this.duration, this.room,
      this.staff, this.studentGroups);
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

final coursesByWeekProvider = FutureProvider.autoDispose.family<List<Event<Course>>, DateTime>((ref, weekStart) async {
  final Logger logger = Logger();
  var weekNum = weeksBetween(semesterStart, weekStart) + 1;
  logger.d("Fetching data for week $weekNum");
  var url = Uri.parse(
      'http://timetables.itsligo.ie:81/reporting/textspreadsheet;student+set;id;SG_KGADV_B07%2FF%2FY2%2F1%2F%28A%29%0D%0A?days=1-7&periods=3-20&weeks=$weekNum&template=student+set+textspreadsheet');
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
            .add(Duration(days: i, hours: endTime.hour, minutes: endTime.minute));
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
            id: "${course.module}//${course.name}",
            start: startDate,
            end: endDate.subtract(const Duration(minutes: 1)),
            date: startDate,
            payload: course));
      } catch (e) {
        logger.w("Could not parse course", e);
      }
    }
  }
  return courses;
});
