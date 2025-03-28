import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationMessagesPage extends StatefulWidget {
  final String applicationId;
  final String jobId;
  final String employeeId;
  final String employerId;

  const CommunicationMessagesPage({
    Key? key,
    required this.applicationId,
    required this.jobId,
    required this.employeeId,
    required this.employerId,
  }) : super(key: key);

  @override
  _CommunicationMessagesPageState createState() =>
      _CommunicationMessagesPageState();
}

class _CommunicationMessagesPageState extends State<CommunicationMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _messages = [];
  List<int> _searchResults = [];
  int _currentSearchIndex = 0;
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Marks unread messages for this application as read.
  Future<void> _markMessagesAsRead() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('communications')
        .where('applicationId', isEqualTo: widget.applicationId)
        .where('readByEmployer', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({'readByEmployer': true});
    }
  }

  /// Sends a new message to Firestore.
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageData = {
      'applicationId': widget.applicationId,
      'jobId': widget.jobId,
      'employeeId': widget.employeeId,
      'employerId': widget.employerId,
      'senderId': FirebaseAuth
          .instance.currentUser!.uid, // Assuming employer sends message
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readByEmployer':
          widget.employerId == FirebaseAuth.instance.currentUser!.uid,
      'readByEmployee':
          widget.employeeId == FirebaseAuth.instance.currentUser!.uid,
    };

    await FirebaseFirestore.instance
        .collection('communications')
        .add(messageData);
    _messageController.clear();

    // Scroll to bottom (or top if reversed)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Returns a stream of messages for this application.
  Stream<QuerySnapshot> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('communications')
        .where('applicationId', isEqualTo: widget.applicationId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _onOpenLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildAppBarTitle() {
    return _isSearching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search messages...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          )
        : const Text("Conversation");
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _searchController.clear();
      _searchResults.clear();
      _currentSearchIndex = 0;
      _searchQuery = "";
    });
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyChatWidget();
        }

        _messages = snapshot.data!.docs;
        // Filter messages by search query if needed.
        List<DocumentSnapshot> displayMessages = _messages;
        if (_searchQuery.isNotEmpty) {
          displayMessages = _messages.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final msg = data['message'] as String? ?? "";
            return msg.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: displayMessages.length,
          itemBuilder: (context, index) {
            final data = displayMessages[index].data() as Map<String, dynamic>;
            final bool isSentByEmployer = data['senderId'] == widget.employerId;
            final Timestamp? ts = data['timestamp'] as Timestamp?;
            final timeString = ts != null
                ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
                : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Align(
                alignment: isSentByEmployer
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Card(
                    color: isSentByEmployer
                        ? Colors.deepPurple.shade100
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isSentByEmployer ? 16 : 0),
                        bottomRight: Radius.circular(isSentByEmployer ? 0 : 16),
                      ),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: isSentByEmployer
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Linkify(
                            onOpen: (link) => _onOpenLink(link.url),
                            text: data['message'] ?? "",
                            style: const TextStyle(fontSize: 16),
                            linkStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeString,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChatWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 20),
          Text(
            "No messages yet",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          Text(
            "Start the conversation now",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          SafeArea(child: _buildMessageInputArea()),
        ],
      ),
    );
  }
}
