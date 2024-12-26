import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/flow_manager.dart';
import '../../widgets/badge_display_dialog.dart';
import '../../widgets/floating_badge_icon.dart';
import '../../widgets/step_progress_bar.dart';
import 'basic_details_screen.dart';
import 'education_details_screen.dart';
import 'location_details_screen.dart';
import 'experience_details_screen.dart';
import 'job_preferences_screen.dart';
import 'award_details_screen.dart';
import 'resume_upload_screen.dart';

class ProfileSetupManager extends StatefulWidget {
  final String userId;
  final VoidCallback onProfileComplete;

  const ProfileSetupManager({
    Key? key,
    required this.userId,
    required this.onProfileComplete,
  }) : super(key: key);

  @override
  _ProfileSetupManagerState createState() => _ProfileSetupManagerState();
}

class _ProfileSetupManagerState extends State<ProfileSetupManager> {
  late PageController _pageController;

  final Map<String, dynamic> _badges = {
    'basicdetails': {'earned': false},
    'locationdetails': {'earned': false},
    'education': {'earned': false},
    'experience': {'earned': false},
    'jobpreferences': {'earned': false},
    'awards': {'earned': false},
    'resume': {'earned': false},
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchAndSetBadges();
  }

  Future<void> _fetchAndSetBadges() async {
    try {
      // Fetch badges from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final fetchedBadges = userDoc.data()?['badges'] ?? {};

        setState(() {
          // Update _badges dynamically
          fetchedBadges.forEach((key, value) {
            if (_badges.containsKey(key) && value['earned'] == true) {
              _badges[key]['earned'] = true;
            }
          });
        });

        debugPrint('Updated badges: $_badges');
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load badges: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _goToNextStep([bool? isEarned]) {
  final flowManager = Provider.of<FlowManager>(context, listen: false);
  final nextStep = flowManager.currentStep + 1;

  if (isEarned != null) {
    // Update the badge's earned state based on the passed value
    final badgeKeys = _badges.keys.toList();
    if (flowManager.currentStep < badgeKeys.length) {
      setState(() {
        _badges[badgeKeys[flowManager.currentStep]]['earned'] = isEarned;
      });
    }
  }

  if (nextStep < flowManager.totalSteps) {
    flowManager.markStepCompleted(flowManager.currentStep);
    flowManager.navigateToStep(nextStep);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    _showBadgeProgress();
  } else if (nextStep == flowManager.totalSteps) {
    _completeProfileSetup();
  }
}



  void _completeProfileSetup() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found.");
      }

      final badges = userDoc.data()?['badges'] ?? {};
      const requiredBadgeKeys = [
        'basicdetails',
        'locationdetails',
        'education',
        'experience',
        'jobpreferences',
        'awards',
        'resume',
      ];

      final allBadgesEarned = requiredBadgeKeys.every((key) {
        final badge = badges[key];
        return badge != null && badge['earned'] == true;
      });

      if (allBadgesEarned) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'profileComplete': true});

        if (mounted) {
          widget.onProfileComplete();
        }
      } else {
        throw Exception("Not all required badges are earned.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete profile setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBadgeProgress() {
    showDialog(
      context: context,
      builder: (_) => BadgeDisplayDialog(
        completedSteps: _badges.values.map((badge) => badge['earned'] as bool).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: StepProgressBar(
                  onStepTap: (step) {
                    _pageController.jumpToPage(step);
                  },
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    BasicDetailsScreen(
                      userId: widget.userId,
                      onNext: (isEarned) => _goToNextStep(isEarned),
                    ),
                    LocationDetailsScreen(
                      userId: widget.userId,
                      onNext: _goToNextStep,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    EducationDetailsScreen(
                      userId: widget.userId,
                      onNext: _goToNextStep,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    ExperienceDetailsScreen(
                      userId: widget.userId,
                      onNext: _goToNextStep,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    JobPreferencesScreen(
                      userId: widget.userId,
                      onNext: _goToNextStep,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    AwardDetailsScreen(
                      userId: widget.userId,
                      onNext: _goToNextStep,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    ResumeUploadScreen(
                      userId: widget.userId,
                      onProfileComplete: widget.onProfileComplete,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingBadgeIcon(
              badges: _badges,
            ),
          ),
        ],
      ),
    );
  }
}

