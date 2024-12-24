import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flow_manager.dart';

class StepProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final flowManager = Provider.of<FlowManager>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        flowManager.totalSteps,
        (index) {
          final isCompleted = flowManager.isStepCompleted(index);
          final isActive = flowManager.currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isCompleted
                          ? Colors.green
                          : isActive
                              ? Colors.orange
                              : Colors.grey,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (index != flowManager.totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted || flowManager.currentStep > index
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
