import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UpdateApplicantStatusPage extends StatefulWidget {
  final Map<String, dynamic> application;
  final Map<String, dynamic> userData;
  final String employerId;
  final String jobId;
  final String employeeId;

  const UpdateApplicantStatusPage({
    Key? key,
    required this.application,
    required this.userData,
    required this.employerId,
    required this.jobId,
    required this.employeeId,
  }) : super(key: key);

  @override
  _UpdateApplicantStatusPageState createState() => _UpdateApplicantStatusPageState();
}

class _UpdateApplicantStatusPageState extends State<UpdateApplicantStatusPage> {
  late String _selectedStatus;
  final List<String> statusOptions = ['Applied', 'Shortlisted', 'Interview', 'Rejected', 'Hired'];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.application['status'] ?? 'Applied';
    _messageController.text = widget.application['communicationMessage'] ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

Future<void> _updateStatus() async {
  try {
    // Update status only in job_applications
    await FirebaseFirestore.instance
        .collection('job_applications')
        .doc(widget.application['id'])
        .update({'status': _selectedStatus});
    
    // If a message is provided, create a new communication message
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      final messageData = {
        'applicationId': widget.application['id'],
        'jobId': widget.jobId,
        'employeeId': widget.employeeId,
        'employerId': widget.employerId,
        'senderId': widget.employerId, // Employer is sending the message
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'readByEmployer': true,
        'readByEmployee': false,
      };
      await FirebaseFirestore.instance.collection('communications').add(messageData);
    }
    
    // Ensure the widget is still mounted before using context
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $_selectedStatus')),
    );
    Navigator.pop(context, true); // Return true to indicate an update
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating status: $e')),
    );
  }
}


  Widget _buildRichTextEditor() {
    // A simulated rich text editor using a multiline TextField with a simple formatting toolbar.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Communication Message",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            style: const TextStyle(fontSize: 16, height: 1.5),
            decoration: const InputDecoration.collapsed(
                hintText: "Enter your message here..."),
          ),
        ),
        const SizedBox(height: 8),
        // Simple formatting toolbar (visual only)
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.format_bold, color: Colors.grey.shade600),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.format_italic, color: Colors.grey.shade600),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.format_underline, color: Colors.grey.shade600),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final basicDetails = widget.userData['basicDetails'] ?? {};
    final photoUrl = widget.userData['photoURL'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Status & Message"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        basicDetails['fullName'] ?? 'Unknown',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(basicDetails['email'] ?? 'No Email'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Card containing status dropdown and rich text editor
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: statusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Update Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRichTextEditor(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Extra spacing to allow scrolling.
          ],
        ),
      ),
      // Fixed bottom button for updating status.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _updateStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Update & Return',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
