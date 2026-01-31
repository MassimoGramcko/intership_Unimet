import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import '../auth/login_screen.dart';
import 'create_offer_screen.dart';
import 'manage_offers_screen.dart'; 
import 'coordinator_applications_screen.dart'; // <--- NAVEGACIÓN SOLICITUDES

class CoordinatorHome extends StatefulWidget {
  const CoordinatorHome({super.key});

  @override
  State<CoordinatorHome> createState() => _CoordinatorHomeState();
}

class _CoordinatorHomeState extends State<CoordinatorHome> {
  
  // Color principal naranja (Hardcoded para no depender de otro archivo)
  final Color primaryOrange = const Color(0xFFFF6B00);

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fecha en inglés para evitar errores de locale
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo de seguridad
      body: Stack(
        children: [
          // CAPA 1: Fondo oscuro moderno con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
          ),

          // CAPA 2: Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Hola, Coordinador 👋",
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 35),

                  // TARJETAS KPI (SOLICITUDES Y OFERTAS)
                  Row(
                    children: [
                      // --- TARJETA DE SOLICITUDES ---
                      _buildModernKpiCard(
                        title: "Solicitudes",
                        collectionName: "applications",
                        icon: Icons.people_alt_rounded,
                        accentColor: Colors.orangeAccent,
                        gradientColors: [primaryOrange.withOpacity(0.8), Colors.orange[800]!],
                        // NAVEGACIÓN CORRECTA A SOLICITUDES
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CoordinatorApplicationsScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      
                      // --- TARJETA DE OFERTAS ---
                      _buildModernKpiCard(
                        title: "Ofertas Activas",
                        collectionName: "job_offers",
                        icon: Icons.business_center_rounded,
                        accentColor: Colors.blueAccent,
                        gradientColors: [Colors.blueAccent.withOpacity(0.8), Colors.blue[800]!],
                        // NAVEGACIÓN CORRECTA A GESTIONAR OFERTAS
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageOffersScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  
                  // TÍTULO SECCIÓN
                  Row(
                    children: [
                      const Text("Actividad Reciente", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5))
                    ],
                  ),
                  const SizedBox(height: 20),

                  // LISTA DE ACTIVIDAD
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .orderBy('appliedAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: primaryOrange),
                        ));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildModernEmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return _buildModernReviewTile(data);
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const CreateOfferScreen())
            );
          },
          backgroundColor: primaryOrange,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          label: const Text("Crear Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildModernKpiCard({
    required String title,
    required String collectionName,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    VoidCallback? onTap, 
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, snapshot) {
          // Filtramos solo si es job_offers para contar las activas, si no cuenta todo
          int count = 0;
          if (snapshot.hasData) {
            if (collectionName == 'job_offers') {
               count = snapshot.data!.docs.where((doc) => doc['isActive'] == true).length;
            } else if (collectionName == 'applications') {
               count = snapshot.data!.docs.where((doc) => doc['status'] == 'Pendiente').length;
            } else {
               count = snapshot.data!.docs.length;
            }
          }
          
          return GestureDetector(
            onTap: onTap,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withOpacity(0.2),
                    gradientColors[1].withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(icon, size: 100, color: accentColor.withOpacity(0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$count",
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernReviewTile(Map<String, dynamic> data) {
    String status = (data['status'] ?? 'Pendiente').toString().toLowerCase();
    
    Color statusColor;
    String statusText;

    if (status == 'pendiente' || status == 'reviewing') {
        statusColor = Colors.orange;
        statusText = 'Pendiente';
    } else if (status == 'aceptado' || status == 'accepted') {
        statusColor = Colors.greenAccent;
        statusText = 'Aceptado';
    } else if (status == 'rechazado' || status == 'rejected') {
        statusColor = Colors.redAccent;
        statusText = 'Rechazado';
    } else {
        statusColor = Colors.blue;
        statusText = 'Nuevo';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[400]!, Colors.purple[400]!]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['studentName'] ?? 'Estudiante', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded, color: Colors.white.withOpacity(0.5), size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data['jobTitle'] ?? 'Puesto desconocido', 
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 8)]
            ),
            child: Text(
              statusText, 
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule_send_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text("Todo al día", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            "No hay nuevas solicitudes pendientes.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}