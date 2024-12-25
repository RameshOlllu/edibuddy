import 'package:flutter/material.dart';

class SkillSelectionScreen extends StatefulWidget {
  final List<String> selectedSkills;

  const SkillSelectionScreen({Key? key, required this.selectedSkills})
      : super(key: key);

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  List<String> suggestedSkills = [
    "Classroom management",
    "Teaching",
    "Student assessment",
    "Lesson planning",
    "Content delivery",
    "Lesson plans",
    "Grading",
    "Curriculum training",
    "Curriculum design",
    "Lesson evaluation",
  ];

  List<String> selectedSkills = [];
  TextEditingController skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedSkills = List.from(widget.selectedSkills);
  }

  void _addCustomSkill(String value) {
    if (value.isNotEmpty && !selectedSkills.contains(value)) {
      setState(() {
        selectedSkills.add(value);
        skillController.clear();
      });
    }
  }

  void _handleDone() {
    Navigator.pop(context, selectedSkills);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleDone();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Select Skills"),
          actions: [
            TextButton(
              onPressed: _handleDone,
              child: const Text(
                "Done",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Skill input field
              TextField(
                controller: skillController,
                decoration: InputDecoration(
                  labelText: "Enter or select skills",
                  hintText: "Type to add a skill",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addCustomSkill(skillController.text),
                  ),
                ),
                onSubmitted: _addCustomSkill,
              ),
              const SizedBox(height: 16),

              // Suggested skills
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Suggested Skills",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestedSkills.map((skill) {
                          final isSelected = selectedSkills.contains(skill);
                          return ChoiceChip(
                            label: Text(skill),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedSkills.add(skill);
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Selected skills
                      const Text(
                        "Selected Skills",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedSkills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            onDeleted: () {
                              setState(() {
                                selectedSkills.remove(skill);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _handleDone,
            child: const Text("Done"),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
