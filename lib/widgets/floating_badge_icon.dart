import 'package:flutter/material.dart';
import 'badge_display_dialog.dart';

class FloatingBadgeIcon extends StatelessWidget {
  final Map<String, dynamic> badges;

  const FloatingBadgeIcon({Key? key, required this.badges}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure only `earned` is used here
    final completedSteps = badges.values.map((badge) {
      return badge['earned'] as bool;
    }).toList();

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
      child: Icon(
        Icons.badge,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 28,
      ),
    );
  }
}
