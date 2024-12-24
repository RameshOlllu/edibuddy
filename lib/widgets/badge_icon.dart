import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final Map<String, dynamic> badges;

  const BadgeIcon({required this.badges});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Badges'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: badges.entries.map((entry) {
              final earned = entry.value['earned'] ?? false;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: earned ? Colors.green : Colors.grey,
                  child: Icon(
                    earned ? Icons.check : Icons.close,
                    color: Colors.white,
                  ),
                ),
                title: Text(entry.key),
                subtitle: earned
                    ? Text('Earned at: ${entry.value['earnedAt']}')
                    : const Text('Not Earned Yet'),
              );
            }).toList(),
          ),
        ),
      ),
      child: const Icon(Icons.badge),
    );
  }
}
