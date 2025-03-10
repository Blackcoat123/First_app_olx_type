import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/chat_messages.dart'; // Import your ChatMessages page

class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found'));
          }

          // Get the list of user documents
          final users = snapshot.data!.docs;

          // Filter out the current user
          final filteredUsers = users.where((user) => user.id != currentUser?.uid).toList();

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index].data() as Map<String, dynamic>;
              final userId = filteredUsers[index].id;

              return ListTile(
                title: Text(user['firstName'] ?? 'Unknown User'),
                subtitle: Text(user['email'] ?? 'No email'),
                onTap: () {
                  // Navigate to the chat page wi
                  // th the selected user's ID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessages(otherUserId: userId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}