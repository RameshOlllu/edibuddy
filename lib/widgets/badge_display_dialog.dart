import 'package:flutter/material.dart';

class BadgeDisplayDialog extends StatelessWidget {
  final List<bool> completedSteps;

  const BadgeDisplayDialog({Key? key, required this.completedSteps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildBadge(context, Icons.person, 'Personal\nInfo', completedSteps[0]),
                _buildBadge(context, Icons.location_on, 'Location', completedSteps[1]),
                _buildBadge(context, Icons.school, 'Education', completedSteps[2]),
                _buildBadge(context, Icons.work, 'Experience', completedSteps[3]),
                _buildBadge(context, Icons.language, 'Language', completedSteps[4]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label, bool isCompleted) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isCompleted ? colorScheme.primary : colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

