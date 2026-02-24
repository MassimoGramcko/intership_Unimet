import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'Chat/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // --- COLORES PRE-COMPUTADOS ---
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white20 = Color(0x33FFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white40 = Color(0x66FFFFFF);
  static const Color _white70 = Color(0xB3FFFFFF);

  // --- STREAM CACHEADO ---
  late final String? _currentUserId;
  late final Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
    } else {
      _notificationsStream = null;
    }
  }

  void _markAsRead(String docId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'isRead': true,
    });
  }

  void _clearAllNotifications(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        title: const Text(
          'Vaciar Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas tus notificaciones?',
          style: TextStyle(color: _white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final batch = FirebaseFirestore.instance.batch();
              final snapshots = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: _currentUserId)
                  .get();

              for (var doc in snapshots.docs) {
                batch.delete(doc.reference);
              }

              await batch.commit();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notificaciones eliminadas correctamente'),
                  ),
                );
              }
            },
            child: const Text(
              'Vaciar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _surfaceDark,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_currentUserId != null)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Vaciar notificaciones',
              onPressed: () => _clearAllNotifications(context),
            ),
        ],
      ),
      body: _currentUserId == null
          ? const Center(
              child: Text(
                "Error de sesión",
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: _white20,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No tienes notificaciones nuevas.",
                          style: TextStyle(color: _white50),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final data = notif.data() as Map<String, dynamic>;
                    final bool isRead = data['isRead'] ?? false;

                    String timeStr = '';
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      timeStr = DateFormat('dd MMM, hh:mm a').format(date);
                    }

                    IconData iconType = Icons.notifications;
                    Color iconColor = Colors.blueAccent;

                    if (data['type'] == 'chat') {
                      iconType = Icons.chat_bubble_rounded;
                      iconColor = Colors.greenAccent;
                    } else if (data['type'] == 'application') {
                      iconType = Icons.assignment_turned_in_rounded;
                      iconColor = Colors.orangeAccent;
                    }

                    String displaySenderName =
                        data['senderName'] ?? 'Coordinador';
                    if (displaySenderName.trim() == 'Usuario' ||
                        displaySenderName.trim().isEmpty) {
                      displaySenderName = 'Coordinador';
                    }

                    return Container(
                      color: isRead
                          ? Colors.transparent
                          : Colors.blueAccent.withValues(alpha: 0.1),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.2),
                          child: Icon(iconType, color: iconColor),
                        ),
                        title: Text(
                          data['title'] ?? 'Notificación',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['body'] ?? '',
                              style: const TextStyle(color: _white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: _white40,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!isRead) _markAsRead(notif.id);

                          if (data['type'] == 'chat' &&
                              data['chatId'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: data['chatId'],
                                  otherUserId: data['senderId'],
                                  otherUserName: displaySenderName,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
