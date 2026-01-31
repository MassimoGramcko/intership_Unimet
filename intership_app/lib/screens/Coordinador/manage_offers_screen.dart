import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_offer_screen.dart'; // <--- IMPORTANTE: Asegúrate de que este archivo exista en la misma carpeta

class ManageOffersScreen extends StatelessWidget {
  const ManageOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Mis Ofertas Activas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        // Fondo con Gradiente Radial
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.3,
            colors: [
              Color(0xFF1E293B), // Azul oscuro pizarra
              Color(0xFF0F172A), // Casi negro
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_offers')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  return _OfferCard(data: data, docId: docId);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 100, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text("No tienes ofertas creadas", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Tus nuevas vacantes aparecerán aquí.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _OfferCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    bool isActive = data['isActive'] ?? false;
    int applicants = data['applicantsCount'] ?? 0;
    String title = data['title'] ?? 'Sin título';
    String type = data['type'] ?? data['modality'] ?? 'Presencial';

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      // Fondo al deslizar para borrar
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 32),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("¿Eliminar oferta?", style: TextStyle(color: Colors.white)),
            content: const Text("Esta acción borrará la oferta permanentemente y no se puede deshacer.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(ctx).pop(false)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: const StadiumBorder()),
                child: const Text("Sí, Eliminar", style: TextStyle(color: Colors.white)), 
                onPressed: () {
                   FirebaseFirestore.instance.collection('job_offers').doc(docId).delete();
                   Navigator.of(ctx).pop(true);
                }
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50).withOpacity(0.9), 
              const Color(0xFF1E293B).withOpacity(0.95), 
            ],
            stops: const [0.1, 0.9]
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(Icons.work_rounded, color: Colors.blueAccent.shade200, size: 24),
                ),
                const SizedBox(width: 15),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                       Text(
                        data['company'] ?? 'Empresa',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Switch
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: isActive,
                    activeColor: Colors.orangeAccent,
                    activeTrackColor: Colors.orangeAccent.withOpacity(0.4),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('job_offers').doc(docId).update({'isActive': val});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tags
            Row(
              children: [
                _buildTag(type, Icons.location_on_outlined, Colors.blueAccent),
                const SizedBox(width: 10),
                if (applicants > 0) 
                  _buildTag("$applicants Postulados", Icons.people_alt_outlined, Colors.greenAccent)
                else
                  _buildTag("Sin postulantes", Icons.hourglass_empty_rounded, Colors.white38),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10, thickness: 1),
            const SizedBox(height: 10),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 6),
                    Text(
                      "Creado: ${_formatDate(data['createdAt'])}",
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
                // --- BOTÓN EDITAR CONECTADO ---
                InkWell(
                  onTap: () {
                    // Navegación a la pantalla de Editar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditOfferScreen(
                          docId: docId,
                          currentData: data,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))
                    ),
                    child: const Row(
                      children: [
                        Text("Editar", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 14, color: Colors.orangeAccent)
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    Color finalColor = color == Colors.white38 ? Colors.white60 : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: finalColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: finalColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: finalColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: finalColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return "N/A";
  }
}