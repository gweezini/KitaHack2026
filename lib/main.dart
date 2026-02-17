import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/admin/ocr_scan_page.dart';
import 'pages/admin/users_list_page.dart';
import 'pages/overdue_charges_page.dart';
import 'pages/admin/pending_parcels_page.dart';
import 'pages/track_parcel_page.dart';
import 'pages/notification_page.dart';
import 'pages/history_page.dart';
import 'services/notification_service.dart';
import 'package:kita_hack_2026/pages/admin/verify_collection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use platform-specific initialization
  if (kIsWeb) {
    // For Web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAEK6pS8wEnnB7PoVgqwejbX3_8CQwlVVI",
        appId: "1:391327390609:web:702aa5c27150566e57d830",
        messagingSenderId: "391327390609",
        projectId: "parcelkita-b53af",
        authDomain: "parcelkita-b53af.firebaseapp.com",
        storageBucket: "parcelkita-b53af.firebasestorage.app",
      ),
    );
  } else {
    // For Android/iOS (uses google-services.json)
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'KitaHack University Parcels',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange, // this one i changed to deep orange 
            brightness: Brightness.light, // set as light mode
          ),

          useMaterial3: true,
        //set button pattern
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white, // its text is white
            ),
          ),
        ),

        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Navigate based on authentication status
            if (authProvider.isAuthenticated) {
              return authProvider.isAdmin ? const AdminDashboard() : const HomePage();
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentId = authProvider.studentId;

    return Scaffold(
      backgroundColor: Colors.white, // Match Login Page background
      appBar: AppBar(
        title: const Text('ParcelKita', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification Map
          StreamBuilder<QuerySnapshot>(
            stream: studentId != null
                ? FirebaseFirestore.instance
                    .collection('notifications')
                    .where('studentId', isEqualTo: studentId)
                    // Removed orderBy from query to avoid index requirement
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              List<DocumentSnapshot> notifications = [];

              if (snapshot.hasData) {
                // Client-side sorting to show latest first without Firestore index
                notifications = snapshot.data!.docs;
                notifications.sort((a, b) {
                   final tA = (a.data() as Map)['timestamp'] as Timestamp?;
                   final tB = (b.data() as Map)['timestamp'] as Timestamp?;
                   if (tA == null || tB == null) return 0;
                   return tB.compareTo(tA);
                });
                
                // Count unread (across all fetched docs)
                unreadCount = notifications.where((doc) => (doc.data() as Map)['isRead'] == false).length;

                // Take top 5 for the dropdown
                if (notifications.length > 5) {
                   notifications = notifications.sublist(0, 5);
                }
              }

              return PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: Colors.white, // White background for the menu
                constraints: const BoxConstraints.tightFor(width: 350), // Wider menu
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications, size: 28),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onSelected: (value) {
                  if (value == 'view_all') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationPage()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  List<PopupMenuEntry<String>> items = [];

                  // Header
                  items.add(
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Text('Recent Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                    ),
                  );

                  // Notification Items
                  if (notifications.isEmpty) {
                    items.add(
                      const PopupMenuItem<String>(
                        enabled: false,
                        child: Text('No notifications'),
                      ),
                    );
                  } else {
                    for (var doc in notifications) {
                      final data = doc.data() as Map<String, dynamic>;
                      final bool isRead = data['isRead'] ?? true;
                      
                      items.add(
                        PopupMenuItem<String>(
                          value: doc.id,
                          onTap: () {
                             // Mark as read on tap
                             if (!isRead) {
                               doc.reference.update({'isRead': true});
                             }
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 4), // Add spacing between items
                            padding: const EdgeInsets.all(12), // More padding inside
                            decoration: BoxDecoration(
                              color: Colors.white, // All notifications are white now
                              borderRadius: BorderRadius.circular(12),
                              // Distinct styling for unread: Orange border + Shadow
                              border: isRead 
                                  ? Border.all(color: Colors.grey.shade200) 
                                  : Border.all(color: Colors.deepOrange.shade200, width: 2), 
                              boxShadow: [
                                if (!isRead)
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!isRead) 
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.deepOrange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        data['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['message'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // Footer: View All
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'view_all',
                      child: Center(
                        child: Text(
                          'View All Notifications',
                          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );

                  return items;
                },
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replaced generic welcome with branded icon and text
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_shipping,
                  size: 40, color: Colors.deepOrange),
            ),
            const SizedBox(height: 20),
            const Text(
              'ParcelKita',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange),
            ),
            const SizedBox(height: 8),
            Text('Track your parcels with ease',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 48),
            
            // Replaced Notifications Button with StreamBuilder above
            
            _StudentButton(
              title: 'Track Parcel',
              icon: Icons.local_shipping,
              color: Colors.blue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackParcelPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _StudentButton(
              title: 'Overdue Charges',
              icon: Icons.receipt,
              color: Colors.orange,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OverdueChargesPage(), 
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _StudentButton(
              title: 'History',
              icon: Icons.history,
              color: Colors.purple,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final int badgeCount;

  const _StudentButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Only wrap in Stack if there is a badge to show
    Widget iconWidget = Icon(
      icon,
      size: 32,
      color: Colors.white,
    );

    if (badgeCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4, // Adjust position to be partially outside checking clip
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.shade200, // Light Orange Badge
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard [TEST MODE]'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UsersListPage()),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('Users Registered'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PendingParcelsPage()),
                  );
                },
                icon: const Icon(Icons.pending_actions),
                label: const Text('Pending Parcels'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VerifyCollectionPage()),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Verify Collection'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final service = NotificationService();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for overdue parcels...')));
                  
                  try {
                    int count = await service.checkAndSendOverdueReminders(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sent $count reminders.'),
                          backgroundColor: count > 0 ? Colors.green : Colors.blue,
                        ),
                      );
                    }
                  } catch (e) {
                     if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Send Due Date Reminders'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OCRScanPage()),
          );
        },
        label: const Text('Scan Parcel'),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}