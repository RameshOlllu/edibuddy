import 'package:flutter/material.dart';

import 'add_new_award.dart';

class AwardsOverviewScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> awards;

  const AwardsOverviewScreen({
    Key? key,
    required this.userId,
    required this.awards,
  }) : super(key: key);

  @override
  State<AwardsOverviewScreen> createState() => _AwardsOverviewScreenState();
}

class _AwardsOverviewScreenState extends State<AwardsOverviewScreen> {
  late List<Map<String, dynamic>> awards;
  bool isUpdated = false;

  @override
  void initState() {
    super.initState();
    awards = List<Map<String, dynamic>>.from(widget.awards);
  }

  Future<void> _addAward() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AddAwardScreen(
          userId: widget.userId,
          onAwardAdded: (newAward) {
            setState(() {
              awards.add(newAward);
              isUpdated = true;
            });
          },
        );
      },
    );
  }

  Future<void> _deleteAward(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Award"),
        content: const Text("Are you sure you want to delete this award?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        awards.removeAt(index);
        isUpdated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awards & Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, isUpdated ? awards : null);
          },
        ),
      ),
      body: awards.isEmpty
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _addAward,
                icon: const Icon(Icons.add),
                label: const Text('Add Award'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: awards.length,
              itemBuilder: (context, index) {
                final award = awards[index];
                return Stack(
                  children: [
                    _buildAwardCard(award, context),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAward(index),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAward,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAwardCard(Map<String, dynamic> award, BuildContext context) {
    DateTime? receivedDate;
    if (award['receivedDate'] is String) {
      receivedDate = DateTime.tryParse(award['receivedDate']);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.emoji_events,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    award['title'] ?? 'Untitled',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    award['organization'] ?? 'Unknown Organization',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
