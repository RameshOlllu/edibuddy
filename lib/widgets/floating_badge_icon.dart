import 'package:flutter/material.dart';
import 'badge_display_dialog.dart';

class FloatingBadgeIcon extends StatelessWidget {
  final List<bool> completedSteps;

  const FloatingBadgeIcon({Key? key, required this.completedSteps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return BadgeDisplayDialog(completedSteps: completedSteps);
          },
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text('Rames'),
    );
  }
}

