import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOfferCandidatesScreen extends StatelessWidget {
  final String offerId;
  final String offerTitle;

  const AdminOfferCandidatesScreen({
    super.key,
    required this.offerId,
    required this.offerTitle,
  });

  // Función para cambiar el estado (Aceptar/Rechazar)
  void _updateStatus(String applicationId, String newStatus) {
    FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Candidatos: $offerTitle"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('offerId', isEqualTo: offerId) // Filtramos por esta oferta
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("Aún no hay postulantes", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var application = snapshot.data!.docs[index];
              var appData = application.data() as Map<String, dynamic>;
              String studentId = appData['studentId'];
              String status = appData['status'] ?? 'En revisión';

              // Colores según estado
              Color statusColor = Colors.orange;
              if (status == 'Aceptado') statusColor = Colors.green;
              if (status == 'Rechazado') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER: Nombre del Estudiante ---
                      // Usamos FutureBuilder para buscar el nombre usando el ID
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) return const Text("Cargando nombre...");
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          return Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo[100],
                                child: Text(
                                  (userData?['nombres']?[0] ?? "E").toUpperCase(),
                                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData?['nombres'] ?? "Estudiante Desconocido",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      userData?['email'] ?? "",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: statusColor,
                              )
                            ],
                          );
                        },
                      ),
                      
                      const Divider(height: 30),

                      // --- BOTONES DE ACCIÓN ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'Rechazado')
                            OutlinedButton.icon(
                              onPressed: () => _updateStatus(application.id, 'Rechazado'),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Rechazar", style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            ),
                          const SizedBox(width: 10),
                          if (status != 'Aceptado')
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(application.id, 'Aceptado'),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Aceptar", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}