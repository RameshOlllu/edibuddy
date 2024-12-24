import 'package:flutter/material.dart';

class FlowManager extends ChangeNotifier {
  int _currentStep = 0;
  final List<bool> _completedSteps = [false, false, false, false, false, false, false];
  final int _totalSteps = 7;

  int get currentStep => _currentStep;
  List<bool> get completedSteps => _completedSteps;
  int get totalSteps => _totalSteps;

  void markStepCompleted(int step) {
    if (step < _totalSteps) {
      _completedSteps[step] = true;
      notifyListeners();
    }
  }

  void navigateToStep(int step) {
    if (step < _totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  bool isStepCompleted(int step) => _completedSteps[step];
}

