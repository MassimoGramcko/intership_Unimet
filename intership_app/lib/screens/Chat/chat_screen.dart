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

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white40 = Color(0x66FFFFFF);
  static const Color _black10 = Color(0x1A000000);

  // --- STREAM CACHEADO ---
  late final Stream<QuerySnapshot> _messagesStream;

  // --- NOMBRE CACHEADO (se busca UNA sola vez) ---
  String _cachedMyName = "Usuario";

  @override
  void initState() {
    super.initState();

    // Cachear stream de mensajes con límite
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();

    // Cachear nombre del usuario UNA sola vez
    _loadMyName();
  }

  Future<void> _loadMyName() async {
    // Primero revisar displayName de Firebase Auth
    if (FirebaseAuth.instance.currentUser?.displayName != null &&
        FirebaseAuth.instance.currentUser!.displayName!.isNotEmpty) {
      _cachedMyName = FirebaseAuth.instance.currentUser!.displayName!;
      return;
    }

    // Si no, buscar en Firestore UNA sola vez
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String firstName = data['firstName'] ?? '';
        final String lastName = data['lastName'] ?? '';
        final String fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          _cachedMyName = fullName;
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo nombre: $e");
    }
  }

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

    // 1. Guardar el mensaje
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // 2. Actualizar el último mensaje
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'users': [currentUserId, widget.otherUserId],
        'lastMessage': text,
        'lastUpdate': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 3. Crear notificación con nombre CACHEADO (sin query extra)
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': widget.otherUserId,
      'senderId': currentUserId,
      'chatId': widget.chatId,
      'senderName': _cachedMyName,
      'title': 'Nuevo mensaje de $_cachedMyName',
      'body': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'chat',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _surfaceDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay mensajes aún.\n¡Escribe algo para empezar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _white40),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == currentUserId;

                    String timeString = '';
                    if (msgData['timestamp'] != null) {
                      DateTime date = (msgData['timestamp'] as Timestamp)
                          .toDate();
                      timeString = DateFormat('hh:mm a').format(date);
                    }

                    return _buildMessageBubble(
                      msgData['text'],
                      isMe,
                      timeString,
                    );
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
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
                  ? LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF334155), _surfaceDark],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: const [
                BoxShadow(color: _black10, blurRadius: 5, offset: Offset(0, 2)),
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
              style: const TextStyle(color: _white30, fontSize: 10),
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
        color: _surfaceDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgDark,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _white10),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Escribe un mensaje...",
                  hintStyle: TextStyle(color: _white30),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
