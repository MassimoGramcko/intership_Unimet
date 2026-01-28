import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_offer_screen.dart';
import 'admin_offer_candidates_screen.dart'; // <--- IMPORTANTE: La pantalla que creamos antes

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  // Función para borrar oferta real en Firebase
  void _deleteOffer(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("¿Seguro que deseas eliminar esta oferta?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('offers').doc(id).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Oferta eliminada")),
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- APPBAR (ESTILO LIMPIO) ---
      appBar: AppBar(
        title: const Text(
          "Panel de Coordinación",
          style: TextStyle(
            color: Colors.indigo, // Usamos color directo por si AppTheme falla
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. RESUMEN (TARJETAS DE COLORES) - ESTÁTICO POR AHORA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildSummaryCard("57", "Publicadas", Colors.blue.shade50, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryCard("8", "Empresas", Colors.purple.shade50, Colors.purple),
                const SizedBox(width: 12),
                _buildSummaryCard("124", "Postulados", Colors.orange.shade50, Colors.orange),
              ],
            ),
          ),

          // 2. SECCIÓN GESTIONAR OFERTAS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Gestionar Ofertas",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateOfferScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Nueva"),
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. LISTA DE OFERTAS (CONECTADA A FIREBASE)
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // Estado: Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Estado: Vacío
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No hay ofertas activas", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                // Estado: Con Datos
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var offer = snapshot.data!.docs[index];
                    var data = offer.data() as Map<String, dynamic>;

                    // Extraer datos o usar valores por defecto
                    String company = data['company'] ?? 'Empresa';
                    String title = data['title'] ?? 'Puesto';
                    bool isActive = data['isActive'] ?? true;
                    
                    // Colores dinámicos
                    String initial = company.isNotEmpty ? company[0].toUpperCase() : "?";
                    Color logoColor = Colors.blue.shade800;
                    if (index % 2 == 0) logoColor = Colors.indigo; // Variar colores un poco

                    return _buildManageOfferCard(
                      context,
                      docId: offer.id,
                      company: company,
                      role: title,
                      status: isActive ? "Activa" : "Cerrada",
                      statusColor: isActive ? Colors.green : Colors.grey,
                      logoColor: logoColor,
                      initial: initial,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET AUXILIAR: TARJETA DE RESUMEN
  Widget _buildSummaryCard(String count, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: TARJETA DE OFERTA CONECTADA
  Widget _buildManageOfferCard(
    BuildContext context, {
    required String docId,
    required String company,
    required String role,
    required String status,
    required Color statusColor,
    required Color logoColor,
    required String initial,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: logoColor,
                radius: 24,
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(company, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          
          // --- BOTONES DE ACCIÓN ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón ELIMINAR
              TextButton.icon(
                onPressed: () => _deleteOffer(context, docId),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),

              // Botón VER POSTULANTES (El más importante)
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar a la pantalla de candidatos pasando el ID de la oferta
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminOfferCandidatesScreen(
                        offerId: docId,
                        offerTitle: role,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade50, // Fondo suave
                  foregroundColor: Colors.indigo,        // Texto e icono oscuro
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.people, size: 18),
                label: const Text("Ver Postulantes"),
              ),
            ],
          )
        ],
      ),
    );
  }
}