import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'create_offer_screen.dart'; // Importamos la pantalla de creación

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // --- CAMBIO AQUÍ: APPBAR BLANCO (ESTILO LIMPIO) ---
      appBar: AppBar(
        title: const Text(
          "Panel de Coordinación",
          style: TextStyle(
            color: AppTheme.secondaryBlue, // Texto oscuro (Azul)
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white, // Fondo blanco
        elevation: 0, // Sin sombra
        centerTitle: false, // Alineado a la izquierda
        automaticallyImplyLeading: false,
        actions: [
          // Ícono de notificaciones decorativo
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // --------------------------------------------------

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RESUMEN (TARJETAS DE COLORES)
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
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18, color: AppTheme.primaryOrange),
                    label: const Text("Filtrar", style: TextStyle(color: AppTheme.primaryOrange)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. LISTA DE OFERTAS
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildManageOfferCard(
                  context, // Pasamos el contexto para poder navegar
                  company: "KPMG",
                  role: "Auditor Junior",
                  date: "Publicado: 24 Oct",
                  status: "Activa",
                  statusColor: Colors.green,
                  logoColor: Colors.blue.shade900,
                  initial: "K",
                ),
                _buildManageOfferCard(
                  context,
                  company: "Farmatodo",
                  role: "Pasante de Logística",
                  date: "Publicado: 20 Oct",
                  status: "Activa",
                  statusColor: Colors.green,
                  logoColor: Colors.blue,
                  initial: "F",
                ),
                // Tarjeta con botón flotante integrado visualmente
                Stack(
                  children: [
                    _buildManageOfferCard(
                      context,
                      company: "Nestlé",
                      role: "Pasante de Mercadeo",
                      date: "Publicado: 15 Oct",
                      status: "Cerrada",
                      statusColor: Colors.grey,
                      logoColor: Colors.brown,
                      initial: "N",
                    ),
                    Positioned(
                      right: 0,
                      bottom: 20,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navegar a Crear Oferta (Vacía)
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateOfferScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text("Nueva Oferta", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
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
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
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
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: TARJETA DE OFERTA
  Widget _buildManageOfferCard(BuildContext context, {
    required String company,
    required String role,
    required String date,
    required String status,
    required Color statusColor,
    required Color logoColor,
    required String initial,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.3), // Fondo crema muy suave
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
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
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {
                  // AQUÍ RESTAURÉ LA NAVEGACIÓN A EDITAR (PARA QUE NO SE PIERDA)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateOfferScreen(
                        currentTitle: role,
                        currentCompany: company,
                      )
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                label: const Text("Editar", style: TextStyle(color: Colors.blue)),
              ),
              TextButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Oferta eliminada"))
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),
            ],
          )
        ],
      ),
    );
  }
}