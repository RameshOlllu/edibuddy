import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<bool> completedSteps;

  const StepProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.completedSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            totalSteps,
            (index) => Expanded(
              child: Column(
                children: [
                  _StepBadge(
                    isActive: index == currentStep,
                    isCompleted: completedSteps[index],
                    stepNumber: index + 1,
                  ),
                  if (index != totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: completedSteps[index]
                            ? Colors.green
                            : (currentStep > index ? Colors.orange : Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
         
          'Step ${currentStep + 1} of $totalSteps',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final int stepNumber;

  const _StepBadge({
    Key? key,
    required this.isActive,
    required this.isCompleted,
    required this.stepNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? colorScheme.primary
            : (isActive ? colorScheme.primaryContainer : colorScheme.surfaceVariant),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                size: 16,
                color: colorScheme.onPrimary,
              )
            : Text(
                '$stepNumber',
                style: TextStyle(
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
