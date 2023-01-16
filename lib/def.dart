import 'package:flutter/material.dart';

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
