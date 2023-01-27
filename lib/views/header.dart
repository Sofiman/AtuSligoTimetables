import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarHeader extends ConsumerWidget {

  final DateTime weekStart;
  final Function(DateTime) changeDate;

  const CalendarHeader({super.key, required this.weekStart, required this.changeDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => changeDate(weekStart.subtract(const Duration(days: 7))),
            icon: const Icon(Icons.undo),
            tooltip: "Previous week",
            splashRadius: 24,
          ),
          GestureDetector(
            onTap: () {
              // TODO
            },
            child: Row(
              children: [Text("Sg_Kgadv_B07/F/Y2/1/(A)"), Icon(Icons.arrow_drop_down)],
            ),
          ),
          IconButton(
            onPressed: () => changeDate(weekStart.add(const Duration(days: 7))),
            icon: const Icon(Icons.redo),
            tooltip: "Next week",
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

}