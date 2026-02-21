import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importación usando el nombre del paquete para evitar errores de ruta
import 'package:intership_app/services/chat_utils.dart';

class ListaUsuariosScreen extends StatelessWidget {
  const ListaUsuariosScreen({super.key});

  // Función para obtener iniciales (Ej: "Alessandro Gramcko" -> "AG")
  String _getTwoInitials(String fullName) {
    if (fullName.isEmpty) return "??";
    List<String> nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.isEmpty || nameParts[0].isEmpty) return "??";

    String initials = nameParts[0][0];
    if (nameParts.length > 1) {
      initials += nameParts.last[0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Estudiantes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          // Filtramos para no aparecer nosotros mismos
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No hay estudiantes registrados.", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(vertical: 15),
            itemBuilder: (context, index) {
              final userDoc = users[index];
              
              // --- AQUÍ USAMOS LA VARIABLE 'data' PARA QUE NO SALGA EL AVISO AMARILLO ---
              final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
              
              // Extraemos los campos exactos de tu base de datos (vistos en tu captura)
              final String firstName = data['firstName']?.toString() ?? '';
              final String lastName = data['lastName']?.toString() ?? '';
              final String userName = '$firstName $lastName'.trim().isEmpty ? 'Estudiante' : '$firstName $lastName'.trim();
              final String career = data['career']?.toString() ?? 'Sin carrera';
              final String iniciales = _getTwoInitials(userName);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blueAccent.shade400, Colors.purpleAccent.shade400],
                      ),
                    ),
                    child: Text(
                      iniciales,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(career, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  onTap: () {
                    // Abrir chat usando la utilidad
                    iniciarOabrirChat(
                      context: context,
                      currentUserId: currentUserId,
                      otherUserId: userDoc.id,
                      otherUserName: userName,
                    );
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