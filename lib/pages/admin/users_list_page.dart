import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Users'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final fullName = user['fullName'] as String? ?? 'No Name';
              final userEmail = user['email'] as String? ?? 'No Email';
              // Check for 'role' from new registration page, and 'isAdmin' from old.
              final isAdmin = (user['role'] == 'admin') || (user['isAdmin'] as bool? ?? false);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isAdmin ? Colors.orange.shade700 : Colors.blue.shade300,
                    foregroundColor: Colors.white,
                    child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person),
                  ),
                  title: Text(fullName),
                  subtitle: Text(userEmail),
                  trailing: isAdmin ? const Text('Admin', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}