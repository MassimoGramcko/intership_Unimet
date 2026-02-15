import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';
import 'profile_tab.dart'; 
import 'explore_tab.dart'; 
import 'applications_tab.dart'; 

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  // Función para cerrar sesión
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: user == null
          ? const Center(child: Text("No hay sesión activa"))
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- HEADER CON EFECTO DE LUZ ---
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
                         IconButton(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                        )
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // --- ESTADÍSTICAS (Postulaciones y Favoritas) ---
                    // AHORA CON EL NUEVO DISEÑO
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

                        return Row(
                          children: [
                            // Tarjeta 1: Postulaciones (Naranja Intenso)
                            Expanded(
                              child: _buildPremiumStatCard(
                                countPostulaciones, 
                                "Postulaciones", 
                                Icons.send_rounded, 
                                AppTheme.primaryOrange
                              ),
                            ),
                            const SizedBox(width: 15), 
                            
                            // Tarjeta 2: Favoritas (Rosado Neón)
                            Expanded(
                              child: _buildPremiumStatCard(
                                "0", 
                                "Favoritas", 
                                Icons.favorite_rounded, 
                                Colors.pinkAccent
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- CUERPO DEL DASHBOARD ---
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu Próximo Paso", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // --- TARJETA HERO: EXPLORAR ---
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
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9), 
                            fontSize: 14
                          )
                        ),
                        
                         const SizedBox(height: 25),
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ]
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

                // --- TARJETAS SECUNDARIAS (Ya actualizadas) ---
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Mis Solicitudes",
                        subtitle: "Ver estado",
                        icon: Icons.folder_open_rounded,
                        accentColor: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplicationsTab(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildActionCard(
                        context,
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

  // --- NUEVO WIDGET PARA LAS TARJETAS DE ESTADÍSTICAS (PREMIUM) ---
  Widget _buildPremiumStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), // Un poco más de espacio interno
      decoration: BoxDecoration(
        // Degradado oscuro + toque de color
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B), // Fondo base (Slate 800)
            color.withOpacity(0.2),  // Tinte de color
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)), // Borde sutil
        // Sombra suave del color del icono (Glow)
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono brillante
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2), 
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                )
              ]
            ),
            child: Icon(icon, color: Colors.white, size: 22), // Icono blanco para contraste
          ),
          const SizedBox(width: 12),
          // Textos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6), 
                  fontSize: 11
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET PARA ACCESOS RÁPIDOS (PREMIUM) ---
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B), 
              accentColor.withOpacity(0.15), 
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded, 
                      color: Colors.white.withOpacity(0.3), 
                      size: 16
                    ),
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