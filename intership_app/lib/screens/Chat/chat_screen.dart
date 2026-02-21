import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId; // ID único de la sala de chat
  final String otherUserId; // ID de la otra persona
  final String otherUserName; // Nombre de la otra persona para el Appbar

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

  // --- FUNCIÓN PARA ENVIAR MENSAJE ---
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear(); // Limpiamos la caja de texto rápido

    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Guardar el mensaje en la subcolección 'messages'
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // 2. Actualizar el último mensaje en el documento principal del chat (útil si luego haces una lista de chats)
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'users': [currentUserId, widget.otherUserId],
      'lastMessage': text,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              radius: 18,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
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
          // --- ÁREA DE MENSAJES ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // reverse: true requiere ordenar descendente
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay mensajes aún.\n¡Escribe algo para empezar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Para que el scroll empiece desde abajo
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == currentUserId;
                    
                    // Formatear la hora
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

          // --- ÁREA PARA ESCRIBIR EL MENSAJE ---
          Container(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25, top: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BURBUJA DE MENSAJE ---
  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.orangeAccent : const Color(0xFF2E3B52),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}