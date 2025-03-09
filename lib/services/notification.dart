import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/chat_messages.dart';
// Import your ChatMessages screen

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser;

    if (authenticatedUser == null) {
      return const Center(
        child: Text('User not authenticated.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(authenticatedUser.uid)
            .collection('userNotifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications found.'),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (ctx, index) {
              final notification = notifications[index].data();
              final title = notification['title'] ?? 'No Title';
              final body = notification['body'] ?? 'No Body';
              final timestamp = notification['timestamp']?.toDate() ?? DateTime.now();
              final isRead = notification['read'] ?? false;
              final otherUserId = notification['otherUserId']; // Extract sender's ID from notification

              return ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body), // Display the sender's name in the body
                    Text(
                      '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                tileColor: isRead ? Colors.white : Colors.grey[200],
                onTap: () async {
                  // Mark the notification as read
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(authenticatedUser.uid)
                      .collection('userNotifications')
                      .doc(notifications[index].id)
                      .update({'read': true});

                  // Optionally, delete the notification after it is read
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(authenticatedUser.uid)
                      .collection('userNotifications')
                      .doc(notifications[index].id)
                      .delete();

                  // Navigate to the ChatMessages screen with the sender's ID (otherUserId)
                  if (otherUserId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatMessages(
                          otherUserId: otherUserId, // Sender's ID
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat user ID not found.')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}