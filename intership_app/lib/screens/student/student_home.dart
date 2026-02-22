import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'profile_tab.dart'; 
import 'explore_tab.dart'; 
import 'applications_tab.dart'; 
import 'settings_screen.dart'; 
// Importación de las utilidades de chat
import 'package:intership_app/services/chat_utils.dart';
// IMPORTANTE: Importamos la pantalla de notificaciones que creamos
import '../notifications_screen.dart';// Ajusta la ruta si es necesario

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: user == null
          ? const Center(child: Text("No hay sesión activa", style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                   return _buildDashboardUI(context, user, 'Estudiante', 'Carrera no definida');
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String firstName = userData['firstName'] ?? 'Estudiante';
                final String career = userData['career'] ?? 'UNIMET';

                return _buildDashboardUI(context, user, firstName, career);
              },
            ),
    );
  }

  Widget _buildDashboardUI(BuildContext context, User? user, String name, String career) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double halfCardWidth = (screenWidth - 70) / 2;

    return SingleChildScrollView(
      child: Column(
        children: [
          // --- HEADER CON EFECTO DE LUZ (MANTENIDO) ---
          Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryOrange.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 70, left: 25, right: 25, bottom: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "¡Hola, $name!",
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: Text(
                                career.toUpperCase(),
                                style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                        // --- AQUÍ REEMPLAZAMOS EL ICONO SOLO DE AJUSTES POR UN ROW CON LA CAMPANITA ---
                        Row(
                          children: [
                            // 1. Campanita de Notificaciones
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('userId', isEqualTo: user?.uid)
                                  .where('isRead', isEqualTo: false) // Solo cuenta las no leídas
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount = snapshot.data!.docs.length;
                                }

                                return Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                        );
                                      },
                                      icon: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                      ),
                                    ),
                                    // El puntito rojo solo aparece si hay > 0
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            // 2. Botón de Configuración Original
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .where('studentId', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String countPostulaciones = "0";
                        if (snapshot.hasData) {
                          countPostulaciones = snapshot.data!.docs.length.toString();
                        }

                        // Reemplazamos el Row y los Expanded para que solo quede Postulaciones ocupando todo el ancho
                        return _buildPremiumStatCard(
                          countPostulaciones, 
                          "Postulaciones", 
                          Icons.send_rounded, 
                          AppTheme.primaryOrange
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu Próximo Paso", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExploreTab()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.3), 
                          blurRadius: 20, 
                          offset: const Offset(0, 10)
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
                        const SizedBox(height: 20),
                        const Text("Explorar Ofertas", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          "Encuentra la pasantía ideal para tu carrera hoy mismo.", 
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text("Buscar Ahora", style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Accesos Rápidos", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildActionCard(
                      context,
                      width: halfCardWidth,
                      title: "Mis Solicitudes",
                      subtitle: "Ver estado",
                      icon: Icons.folder_open_rounded,
                      accentColor: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ApplicationsTab()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      width: halfCardWidth,
                      title: "Mi Perfil y CV",
                      subtitle: "Editar datos",
                      icon: Icons.person_rounded,
                      accentColor: Colors.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileTab()),
                        );
                      },
                    ),
                    
                    // --- TARJETA DE CHAT CON LÓGICA MEJORADA ---
                    _buildActionCard(
                      context,
                      width: double.infinity,
                      title: "Chat con Coordinador",
                      subtitle: "Consultas directas y soporte",
                      icon: Icons.chat_bubble_rounded,
                      accentColor: Colors.tealAccent.shade400,
                      onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Buscando coordinador...")),
                        );

                        try {
                          // Búsqueda flexible por rol
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .where('role', whereIn: ['coordinador', 'coordinator'])
                              .limit(1)
                              .get();

                          if (!context.mounted) return;

                          if (querySnapshot.docs.isNotEmpty) {
                            final coordDoc = querySnapshot.docs.first;
                            final coordData = coordDoc.data();
                            
                            String coordName = "${coordData['firstName'] ?? ''} ${coordData['lastName'] ?? ''}".trim();
                            if (coordName.isEmpty) coordName = "Coordinador";

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            iniciarOabrirChat(
                              context: context,
                              currentUserId: user?.uid ?? '',
                              otherUserId: coordDoc.id,
                              otherUserName: coordName,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No se encontró un coordinador activo.")),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO (MANTENIENDO TU DISEÑO ORIGINAL) ---
  Widget _buildPremiumStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E293B), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)), 
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22), 
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color accentColor, required VoidCallback onTap, double? width}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 160, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1E293B), accentColor.withOpacity(0.15)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.3), size: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}