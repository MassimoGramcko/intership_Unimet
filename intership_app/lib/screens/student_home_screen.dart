import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  // Lista de las 3 pantallas principales
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeTab(),          // 0: Lista de Ofertas (¡AHORA CONECTADA!)
    const ApplicationsTab(),  // 1: Mis Postulaciones
    const ProfileTab(),       // 2: Mi Perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Postulaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- PESTAÑA 1: INICIO (Lista de Ofertas - CONECTADA A FIREBASE) ---
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ofertas de Pasantía",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            // Usamos StreamBuilder para escuchar la base de datos en tiempo real
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('isActive', isEqualTo: true) // Solo mostrar ofertas activas
                  .orderBy('createdAt', descending: true) // Las más nuevas primero
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // 1. Si está cargando, mostramos ruedita
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Si hay error
                if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar ofertas: ${snapshot.error}"));
                }

                // 3. Si no hay datos o la lista está vacía
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          "Aún no hay ofertas publicadas",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // 4. ¡Si hay ofertas! Las mostramos en una lista
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var offer = snapshot.data!.docs[index];
                    var data = offer.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: Text(
                          data['title'] ?? 'Sin título',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['company'] ?? 'Empresa desconocida'),
                            const SizedBox(height: 5),
                            Text(
                              data['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis, // Cortar texto si es muy largo
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Aquí iría la navegación al detalle (lo haremos luego)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Detalle en construcción...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text("Ver", style: TextStyle(fontSize: 12)),
                        ),
                      ),
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
}

// --- PESTAÑA 2: POSTULACIONES ---
class ApplicationsTab extends StatelessWidget {
  const ApplicationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Aquí verás el estado de tus postulaciones"),
    );
  }
}

// --- PESTAÑA 3: PERFIL (Datos del Estudiante) ---
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Variable para guardar los datos descargados
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // --- LÓGICA DE USUARIO ---
  void _getUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // Usamos el UID seguro
      var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      
      if (mounted) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            userData?['nombres'] ?? "Estudiante",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            userData?['carrera'] ?? "Carrera no definida",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          
          // Tarjeta de Información
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email, "Correo", userData?['email'] ?? "-"),
                  const Divider(),
                  _buildInfoRow(Icons.badge, "Carnet", userData?['carnet'] ?? "-"),
                  const Divider(),
                  _buildInfoRow(Icons.credit_card, "Cédula", userData?['cedula'] ?? "-"),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar Sesión"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        )
      ],
    );
  }
}