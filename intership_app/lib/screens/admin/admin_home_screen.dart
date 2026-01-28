import 'package:flutter/material.dart';

// --- IMPORTACIONES ---
// Importamos la pieza nueva que creamos
import 'admin_dashboard_tab.dart'; 
// Importamos las otras pestañas (asegúrate de que estos archivos existan en tu carpeta)
import 'admin_students_tab.dart';  
import 'admin_profile_tab.dart';   

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // --- LISTA DE PANTALLAS ---
  // Aquí es donde conectamos tu nuevo AdminDashboardTab
  final List<Widget> _pages = [
    const AdminDashboardTab(), // <--- ¡AQUÍ ESTÁ TU NUEVO DASHBOARD!
    const AdminStudentsTab(),  // Pestaña de estudiantes
    const AdminProfileTab(),   // Pestaña de perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTANTE: No ponemos AppBar aquí porque el Dashboard ya tiene el suyo propio
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Para que los iconos no se muevan
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Estudiantes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}