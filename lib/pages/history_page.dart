import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final String? studentId; // Optional: If provided, shows history for this student
  final String? studentName; // Optional: For display purposes

  const HistoryPage({Key? key, this.studentId, this.studentName}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _studentId;
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    // If studentId is passed from Admin, use it directly
    if (widget.studentId != null) {
      if (mounted) {
        setState(() {
          _studentId = widget.studentId;
          _isLoadingId = false;
        });
      }
      return;
    }

    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingId = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _studentId = doc.data()?['studentId'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching student ID: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingId = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName != null 
            ? '${widget.studentName}\'s History' 
            : 'Collection History'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingId
          ? const Center(child: CircularProgressIndicator())
          : _studentId == null
              ? const Center(child: Text('Could not retrieve user history.'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parcels')
                      .where('studentId', isEqualTo: _studentId)
                      .where('status', isEqualTo: 'Collected')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No collected parcels found.',
                                style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      );
                    }

                    final parcels = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: parcels.length,
                      itemBuilder: (context, index) {
                        final parcelDoc = parcels[index];
                        final parcel =
                            parcelDoc.data() as Map<String, dynamic>;
                        final trackingNumber =
                            parcel['trackingNumber'] as String? ?? 'N/A';
                        final collectedAt =
                            parcel['collectedAt'] as Timestamp?;
                        final type = parcel['type'] as String? ?? 'Parcel';
                        final overdueCharge = (parcel['overdueCharge'] as num?)?.toDouble() ?? 0.0;

                        String collectedDateFormatted = 'Unknown time';
                        if (collectedAt != null) {
                          collectedDateFormatted = DateFormat('d MMM yyyy, h:mm a')
                              .format(collectedAt.toDate());
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: const Icon(Icons.check_circle_outline,
                                  color: Colors.purple),
                            ),
                            title: Text(trackingNumber),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Collected: $collectedDateFormatted'),
                                Text('Type: $type'),
                                Text('Paid Overdue: RM ${overdueCharge.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}