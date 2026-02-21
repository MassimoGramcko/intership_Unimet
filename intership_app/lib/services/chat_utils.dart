import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ¡Aquí estaba el detalle! Faltaba la carpeta "Chat" en la ruta
import 'package:intership_app/screens/Chat/chat_screen.dart';

Future<void> iniciarOabrirChat({
  required BuildContext context,
  required String currentUserId,
  required String otherUserId,
  required String otherUserName,
}) async {
  
  // 1. Generamos el ID único combinando los IDs en orden alfabético
  String chatId = currentUserId.compareTo(otherUserId) > 0 
      ? '${currentUserId}_$otherUserId' 
      : '${otherUserId}_$currentUserId';

  // 2. Registramos el chat en Firebase
  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
    'users': [currentUserId, otherUserId], 
    'lastUpdate': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // 3. Verificamos que la pantalla siga activa antes de navegar (Esto quita la advertencia azul)
  if (!context.mounted) return;

  // 4. Navegamos a la pantalla de chat
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatId: chatId, 
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      ),
    ),
  );
}