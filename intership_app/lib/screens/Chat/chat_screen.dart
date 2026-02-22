import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- FUNCIÓN PARA OBTENER 2 INICIALES ---
  String _getTwoInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    String initials = parts[0][0];
    if (parts.length > 1) {
      initials += parts.last[0];
    }
    return initials.toUpperCase();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Guardar el mensaje en la colección de mensajes del chat
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // 2. Actualizar el último mensaje en la información general del chat
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'users': [currentUserId, widget.otherUserId],
      'lastMessage': text,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // --- NUEVO: OBTENER EL NOMBRE REAL DEL USUARIO QUE ENVÍA ---
    String myName = "Usuario"; 
    
    // Primero revisamos si el nombre está en Firebase Auth
    if (FirebaseAuth.instance.currentUser?.displayName != null && 
        FirebaseAuth.instance.currentUser!.displayName!.isNotEmpty) {
      myName = FirebaseAuth.instance.currentUser!.displayName!;
    } else {
      // Si no, lo buscamos en tu colección de usuarios en Firestore.
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          
          // --- AQUÍ ESTÁ EL CAMBIO CLAVE: BUSCAMOS firstName Y lastName ---
          final String firstName = data['firstName'] ?? '';
          final String lastName = data['lastName'] ?? '';
          
          final String fullName = '$firstName $lastName'.trim();
          
          if (fullName.isNotEmpty) {
            myName = fullName; // Se guardará como "Massimo Coordinador"
          }
        }
      } catch (e) {
        debugPrint("Error obteniendo nombre: $e");
      }
    }
    // -----------------------------------------------------------

    // 3. Crear la notificación con el ID del chat y el NOMBRE REAL
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': widget.otherUserId,
      'senderId': currentUserId,
      'chatId': widget.chatId, 
      'senderName': myName, // <-- AHORA USA TU NOMBRE COMPLETO
      'title': 'Nuevo mensaje de $myName', // <-- TÍTULO PERSONALIZADO
      'body': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'chat',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueAccent.shade400,
                    Colors.purpleAccent.shade400,
                  ],
                ),
              ),
              child: Text(
                _getTwoInitials(widget.otherUserName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay mensajes aún.\n¡Escribe algo para empezar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == currentUserId;
                    
                    String timeString = '';
                    if (msgData['timestamp'] != null) {
                      DateTime date = (msgData['timestamp'] as Timestamp).toDate();
                      timeString = DateFormat('hh:mm a').format(date);
                    }

                    return _buildMessageBubble(msgData['text'], isMe, timeString);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: 4,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe 
                ? LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500])
                : const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(
              time,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Escribe un mensaje...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}