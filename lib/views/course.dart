import 'package:atu_sligo_timetables/def.dart';
import 'package:flutter/material.dart';

class CourseView extends StatelessWidget {
  final Course course;

  const CourseView({super.key, required this.course});

  List<String> getStaffMembers() {
    return course.staff.split(",").map((e) => e.trim()).toList();
  }

  List<String> getGroups() {
    return course.studentGroups.split(";").map((e) => e.trim()).toList();
  }

  String renderDuration(){
    final TimeOfDay d = course.duration;
    return "${d.hour}h${d.minute > 0 ? d.minute.toString().padLeft(2, '0') : ""}";
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = ChipTheme.of(context).brightness ?? theme.brightness;
    final ChipThemeData chipDefaults = ChipThemeData.fromDefaults(
      brightness: brightness,
      secondaryColor: brightness == Brightness.dark ? Colors.tealAccent[200]! : theme.primaryColor,
      labelStyle: theme.textTheme.bodyText1!,
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.module, style: theme.textTheme.caption),
                        Text(course.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    )),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 24)
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 6),
                Text("Duration", style: theme.textTheme.labelLarge),
                Container(
                  color: chipDefaults.backgroundColor,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Text(renderDuration(), style: theme.chipTheme.labelStyle),
                ),
                Text("Type", style: theme.textTheme.labelLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                        height: 32,
                        width: 32,
                        color: course.type.color(),
                        margin: const EdgeInsets.only(left: 4)),
                    Container(
                      color: chipDefaults.backgroundColor,
                      height: 32,
                      padding: const EdgeInsets.all(8),
                      child: Text(course.type.toString(), style: theme.chipTheme.labelStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Room", style: theme.textTheme.labelLarge),
                Container(
                  color: chipDefaults.backgroundColor,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Text(course.room, style: theme.chipTheme.labelStyle),
                ),
                Text("Staff", style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Flex(
                  direction: Axis.horizontal,
                  children: [
                    for (var staff in getStaffMembers())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Chip(
                          avatar: const CircleAvatar(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.school, size: 16),
                          ),
                          label: Text(staff),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Groups", style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  direction: Axis.horizontal,
                  children: [
                    for (var group in getGroups())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Chip(
                          avatar: const CircleAvatar(
                              backgroundColor: Colors.deepPurpleAccent,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.groups, size: 16)),
                          label: Text(group),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
