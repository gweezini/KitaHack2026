import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // ... existing methods ...

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentId = authProvider.studentId;

    if (studentId != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('studentId', isEqualTo: studentId)
            .where('isRead', isEqualTo: false)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
           final batch = FirebaseFirestore.instance.batch();
           for (final doc in querySnapshot.docs) {
             batch.update(doc.reference, {'isRead': true});
           }
           await batch.commit();
        }
      } catch (e) {
        print("Error marking notifications as read: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentId = authProvider.studentId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: studentId == null
          ? const Center(child: Text('Error: Student ID is NULL. Try relogin.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('studentId', isEqualTo: studentId)
                  // Removed orderBy to avoid index requirement
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No notifications yet.'),
                      ],
                    ),
                  );
                }

                // Client-side sort
                final notifications = snapshot.data!.docs;
                notifications.sort((a, b) {
                   final tA = (a.data() as Map)['timestamp'] as Timestamp?;
                   final tB = (b.data() as Map)['timestamp'] as Timestamp?;
                   if (tA == null || tB == null) return 0;
                   return tB.compareTo(tA);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final notification = notifications[index].data() as Map<String, dynamic>;
                    final timestamp = notification['timestamp'] as Timestamp?;
                    final date = timestamp?.toDate();
                    final formattedDate = date != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                        : 'Unknown Date';
                    final isRead = notification['isRead'] ?? true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.grey.shade200 : Colors.deepOrange.shade100,
                        child: Icon(
                          Icons.notifications, 
                          color: isRead ? Colors.grey : Colors.deepOrange
                        ),
                      ),
                      title: Text(
                        notification['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification['message'] ?? ''),
                          const SizedBox(height: 4),
                          Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
    );
  }
}
