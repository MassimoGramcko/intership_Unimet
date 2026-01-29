import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentsTab extends StatelessWidget {
  const AdminStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Estudiantes Registrados",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      // StreamBuilder escucha cambios en tiempo real
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos solo los usuarios que tengan role 'student'
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No hay estudiantes registrados aún"),
                ],
              ),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentData = students[index].data() as Map<String, dynamic>;
              final String name = studentData['name'] ?? 'Sin nombre';
              final String email = studentData['email'] ?? 'Sin correo';
              // Usamos la inicial del nombre para el avatar
              final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    foregroundColor: Colors.indigo,
                    child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(email),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    // Aquí podrías agregar una pantalla de detalle del estudiante en el futuro
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Estudiante: $name")),
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