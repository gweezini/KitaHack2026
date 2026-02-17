import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? _studentId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _studentId = doc.data()?['studentId'];
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching student ID: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    if (_studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send test: Student ID not loaded')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'studentId': _studentId,
        'title': 'Test Notification',
        'message': 'This is a test message to verify notifications work.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifs (${_studentId ?? "No ID"})'), // Debug ID
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentId == null
              ? const Center(child: Text('Student ID not found.'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('studentId', isEqualTo: _studentId)
                      // .orderBy('timestamp', descending: true) // REMOVED FOR DEBUGGING (Index Check)
                      .snapshots(),
                  builder: (context, snapshot) {
                     // Debug Print
                     if (snapshot.hasError) print("Stream Error: ${snapshot.error}");
                     if (snapshot.hasData) print("Docs found: ${snapshot.data!.docs.length}");
                     
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

                    final notifications = snapshot.data!.docs;

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

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepOrange.shade100,
                            child: const Icon(Icons.notifications, color: Colors.deepOrange),
                          ),
                          title: Text(
                            notification['title'] ?? 'Notification',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

      floatingActionButton: FloatingActionButton(
        onPressed: _sendTestNotification,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }
}
