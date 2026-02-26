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
  String? _editingMessageId; // <-- NUEVO: Para saber qué mensaje estamos editando

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white40 = Color(0x66FFFFFF);
  static const Color _black10 = Color(0x1A000000);

  // --- STREAM CACHEADO ---
  late final Stream<QuerySnapshot> _messagesStream;

  // --- DATOS DEL USUARIO ACTUAL ---
  String _cachedMyName = "Usuario";
  String _myRole = "student"; // <-- NUEVO: Para saber si soy estudiante o coordinador

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
        final String role = data['role'] ?? 'student'; // Obtener el rol
        final String fullName = '$firstName $lastName'.trim();

        if (mounted) {
          setState(() {
            _myRole = role;
            if (fullName.isNotEmpty) _cachedMyName = fullName;
          });
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
      'isRead': false, // <-- NUEVO: Inicia como no leído
      'isEdited': false, // <-- NUEVO: Inicia sin editar
    };

    if (_editingMessageId != null) {
      // MODO EDICIÓN
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(_editingMessageId)
          .update({
        'text': text,
        'isEdited': true,
        'lastEditAt': FieldValue.serverTimestamp(),
      });
      setState(() => _editingMessageId = null);
    } else {
      // MODO ENVÍO NORMAL
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
                  colors: _myRole == 'student' 
                    ? [Colors.orange.shade700, Colors.orange.shade400]
                    : [Colors.blueAccent.shade400, Colors.purpleAccent.shade400],
                ),
              ),
              child: _myRole == 'student'
                ? const Icon(Icons.school_rounded, color: Colors.white, size: 20)
                : Text(
                    _getTwoInitials(widget.otherUserName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _myRole == 'student' ? "Coordinación de Pasantías" : widget.otherUserName,
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent_rounded, size: 80, color: Colors.blueAccent.withValues(alpha: 0.3)),
                          const SizedBox(height: 20),
                          const Text(
                            "Centro de Soporte",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Estás en comunicación con el equipo de soporte. Escribe tu duda o inconveniente aquí debajo y te responderemos lo antes posible.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _white40, fontSize: 14),
                          ),
                        ],
                      ),
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
                    final messageId = messages[index].id;

                    // Lógica para marcar como leído si es mensaje del OTRO
                    if (!isMe && msgData['isRead'] != true) {
                      FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .doc(messageId)
                          .update({'isRead': true});
                    }

                    String timeString = '';
                    if (msgData['timestamp'] != null) {
                      DateTime date = (msgData['timestamp'] as Timestamp)
                          .toDate();
                      timeString = DateFormat('hh:mm a').format(date);
                    }

                    return GestureDetector(
                      onLongPress: isMe ? () => _showEditDialog(messageId, msgData['text']) : null,
                      child: _buildMessageBubble(
                        msgData['text'],
                        isMe,
                        timeString,
                        msgData['isRead'] ?? false,
                        msgData['isEdited'] ?? false,
                      ),
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

  void _showEditDialog(String messageId, String currentText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
            title: const Text("Editar mensaje", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _editingMessageId = messageId;
                _messageController.text = currentText;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, bool isRead, bool isEdited) {
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEdited) 
                  const Text("(editado) ", style: TextStyle(color: _white30, fontSize: 10, fontStyle: FontStyle.italic)),
                Text(
                  time,
                  style: const TextStyle(color: _white30, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded, // Usamos done_rounded para check simple
                    size: 15,
                    color: isRead ? const Color(0xFF4FC3F7) : _white30, // Un azul un poco más vibrante para el visto
                  ),
                ]
              ],
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
      child: Column( // Cambiado a Column para apilar la edición sobre el input
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editingMessageId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 5),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  const Text("Editando mensaje...", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                    onPressed: () => setState(() {
                      _editingMessageId = null;
                      _messageController.clear();
                    }),
                  )
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: _editingMessageId != null ? Colors.blueAccent : _white10),
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
                  child: Icon(
                    _editingMessageId != null ? Icons.check_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
