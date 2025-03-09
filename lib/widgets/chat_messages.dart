import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_bubble.dart'; // Import your MessageBubble widget

class ChatMessages extends StatefulWidget {
  final String otherUserId;

  const ChatMessages({super.key, required this.otherUserId});

  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final TextEditingController _messageController = TextEditingController();
  String? _otherUserFullName; // Store the other user's full name
  String? _otherUserEmail; // Store the other user's email

  @override
  void initState() {
    super.initState();
    _fetchOtherUserDetails(); // Fetch the other user's details when the widget initializes
  }

  void _fetchOtherUserDetails() async {
    final otherUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();

    if (otherUserDoc.exists) {
      final data = otherUserDoc.data();
      setState(() {
        _otherUserFullName = '${data?['firstName']} ${data?['lastName']}'; // Combine firstName and lastName
        _otherUserEmail = data?['email']; // Get the email
      });
    }
  }

  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure consistent chat ID
    return ids.join('_');
  }

  void sendMessage(String chatId) async {
    final authenticatedUser = FirebaseAuth.instance.currentUser;

    if (authenticatedUser == null || _messageController.text.trim().isEmpty) {
      return;
    }

    // Save the message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': _messageController.text.trim(),
      'userId': authenticatedUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fetch the sender's details
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authenticatedUser.uid)
        .get();

    final senderName = senderDoc.exists
        ? '${senderDoc['firstName']} ${senderDoc['lastName']}'
        : 'Unknown';

    // Save a notification for the recipient
    final recipientId = widget.otherUserId;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(recipientId)
        .collection('userNotifications')
        .add({
      'title': 'New Message',
      'body': 'You have a new message from $senderName', // Include sender's name
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'otherUserId': authenticatedUser.uid, // Include sender's ID
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser;

    if (authenticatedUser == null) {
      return const Center(
        child: Text('User not authenticated.'),
      );
    }

    final String chatId = getChatId(authenticatedUser.uid, widget.otherUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserFullName ?? 'Loading...'), // Display the other user's full name
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Newest messages at the bottom
                  .snapshots(),
              builder: (ctx, chatSnapshots) {
                if (chatSnapshots.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (chatSnapshots.hasError) {
                  return const Center(
                    child: Text('Something went wrong.'),
                  );
                }

                if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages found.'),
                  );
                }

                final loadedMessages = chatSnapshots.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
                  reverse: true, // Display messages from the bottom
                  itemCount: loadedMessages.length,
                  itemBuilder: (ctx, index) {
                    final chatData = loadedMessages[index].data() as Map<String, dynamic>?;

                    if (chatData == null || !chatData.containsKey('text') || !chatData.containsKey('userId')) {
                      return const SizedBox(); // Skip invalid messages
                    }

                    final String messageText = chatData['text'] ?? 'No message';
                    final String userId = chatData['userId'] ?? 'Unknown';

                    final String? userImage = chatData['userImage'] as String?;
                    final String? email = chatData['email'] as String?; // Use email instead of username

                    // Handling next message for checking consecutive sender
                    final nextChatData = index + 1 < loadedMessages.length
                        ? loadedMessages[index + 1].data() as Map<String, dynamic>?
                        : null;

                    final String? nextUserId = nextChatData?['userId'] as String?;
                    final bool nextUserIsSame = nextUserId == userId;

                    if (nextUserIsSame) {
                      return MessageBubble.next(
                        message: messageText,
                        isMe: authenticatedUser.uid == userId,
                      );
                    } else {
                      return MessageBubble.first(
                        userImage: userImage ?? '',
                        username: email ?? 'Unknown', // Use email instead of username
                        message: messageText,
                        isMe: authenticatedUser.uid == userId,
                      );
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController, // Use the controller
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(chatId); // Send the message
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}