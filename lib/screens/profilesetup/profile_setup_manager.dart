import 'package:edibuddy/screens/profilesetup/award_details_screen.dart';
import 'package:edibuddy/screens/profilesetup/experience_details_screen.dart';
import 'package:edibuddy/screens/profilesetup/job_preferences_screen.dart';
import 'package:edibuddy/screens/profilesetup/language_details_screen.dart';
import 'package:edibuddy/screens/profilesetup/resume_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/flow_manager.dart';
import '../../widgets/step_progress_bar.dart';
import 'basic_details_screen.dart';
import 'education_details_screen.dart';
import 'location_details_screen.dart';


class ProfileSetupManager extends StatefulWidget {
  final String userId;

  const ProfileSetupManager({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileSetupManagerState createState() => _ProfileSetupManagerState();
}

class _ProfileSetupManagerState extends State<ProfileSetupManager> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _goToNextStep() {
    final flowManager = Provider.of<FlowManager>(context, listen: false);
    final nextStep = flowManager.currentStep + 1;

    if (nextStep < flowManager.totalSteps) {
      flowManager.markStepCompleted(flowManager.currentStep); // Mark current step as completed
      flowManager.navigateToStep(nextStep); // Move to the next step
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    final flowManager = Provider.of<FlowManager>(context, listen: false);
    final prevStep = flowManager.currentStep - 1;

    if (prevStep >= 0) {
      flowManager.navigateToStep(prevStep); // Move to the previous step
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Ramesh received user id is ${widget.userId}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 80,
            child: StepProgressBar(),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BasicDetailsScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                ),
                LocationDetailsScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                  onPrevious: _goToPreviousStep,
                ),
                EducationDetailsScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                  onPrevious: _goToPreviousStep,
                ),
                 ExperienceDetailsScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                  onPrevious: _goToPreviousStep,
                ),
                 
                 JobPreferencesScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                  onPrevious: _goToPreviousStep,
                ),AwardDetailsScreen(
                  userId: widget.userId,
                  onNext: _goToNextStep,
                  onPrevious: _goToPreviousStep,
                ),ResumeUploadScreen(
                  userId: widget.userId,
              
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
