import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flow_manager.dart';

class StepProgressBar extends StatelessWidget {
  final Function(int) onStepTap;

  const StepProgressBar({Key? key, required this.onStepTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final flowManager = Provider.of<FlowManager>(context);

    final stepSpacing = (MediaQuery.of(context).size.width -
            flowManager.totalSteps * 36) / // Width for step circles
        (flowManager.totalSteps - 1); // Space between steps

    return Center( // Center the entire progress bar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Only use required space
        children: List.generate(
          flowManager.totalSteps,
          (index) {
            final isCompleted = flowManager.isStepCompleted(index);
            final isActive = flowManager.currentStep == index;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => onStepTap(index),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 36 : 24,
                        height: isActive ? 36 : 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : (isActive ? Colors.orange : Colors.grey.shade300),
                          border: Border.all(
                            color: isActive ? Colors.orange : Colors.grey.shade400,
                            width: isActive ? 3 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.black,
                                    fontSize: isActive ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != flowManager.totalSteps - 1)
                  SizedBox(
                    width: stepSpacing,
                    child: Container(
                      height: 2,
                      color: isCompleted || flowManager.currentStep > index
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
