import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'Chat/chat_screen.dart'; // Mantén tu ruta correcta del chat aquí

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Función para marcar la notificación como leída
  void _markAsRead(String docId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'isRead': true,
    });
  }

  // --- NUEVA FUNCIÓN: VACIAR NOTIFICACIONES ---
  void _clearAllNotifications(BuildContext context, String userId) async {
    // Mostramos un pequeño diálogo de confirmación para evitar borrados por accidente
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Vaciar Notificaciones', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres eliminar todas tus notificaciones?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cierra el diálogo sin hacer nada
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              
              // Borrado masivo en Firebase
              final batch = FirebaseFirestore.instance.batch();
              final snapshots = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .get();
                  
              for (var doc in snapshots.docs) {
                batch.delete(doc.reference); // Agrega cada notificación a la lista de borrado
              }
              
              await batch.commit(); // Ejecuta el borrado
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificaciones eliminadas correctamente')),
                );
              }
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // --- NUEVO BOTÓN PARA VACIAR ---
          if (currentUserId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'Vaciar notificaciones',
              onPressed: () => _clearAllNotifications(context, currentUserId),
            ),
        ],
      ),
      body: currentUserId == null
          ? const Center(child: Text("Error de sesión", style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 15),
                        Text("No tienes notificaciones nuevas.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
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

                    // --- AJUSTE DEL NOMBRE INTELIGENTE ---
                    // Como el estudiante siempre habla con el coordinador, si el nombre viene 
                    // como "Usuario" o viene vacío desde la base de datos, lo forzamos a "Coordinador".
                    String displaySenderName = data['senderName'] ?? 'Coordinador';
                    if (displaySenderName.trim() == 'Usuario' || displaySenderName.trim().isEmpty) {
                      displaySenderName = 'Coordinador';
                    }

                    return Container(
                      color: isRead ? Colors.transparent : Colors.blueAccent.withOpacity(0.1),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(iconType, color: iconColor),
                        ),
                        title: Text(
                          data['title'] ?? 'Notificación',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['body'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                            const SizedBox(height: 4),
                            Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          ],
                        ),
                        onTap: () {
                          if (!isRead) _markAsRead(notif.id);
                          
                          if (data['type'] == 'chat' && data['chatId'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: data['chatId'],
                                  otherUserId: data['senderId'],
                                  otherUserName: displaySenderName, // <- Aquí pasamos el nombre arreglado
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