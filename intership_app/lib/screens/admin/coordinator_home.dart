import 'package:flutter/material.dart';
// Asegúrate de que esta ruta sea correcta según tu estructura de carpetas
// Si te da error en 'theme.dart', cámbialo a: import '../config/theme.dart';
import '../../config/theme.dart'; 

import 'admin_dashboard_tab.dart'; // 1. Validar Ofertas
import 'admin_students_tab.dart';  // 2. Directorio Estudiantes
import 'admin_profile_tab.dart';   // 3. Perfil Coordinador

class CoordinatorHomeScreen extends StatefulWidget {
  const CoordinatorHomeScreen({super.key});

  @override
  State<CoordinatorHomeScreen> createState() => _CoordinatorHomeScreenState();
}

class _CoordinatorHomeScreenState extends State<CoordinatorHomeScreen> {
  int _currentIndex = 0;

  // Lista de las 3 pestañas
  final List<Widget> _pages = [
    const AdminDashboardTab(), // Pestaña 0: Inicio/Validar
    const AdminStudentsTab(),  // Pestaña 1: Estudiantes
    const AdminProfileTab(),   // Pestaña 2: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Quitamos el AppBar de aquí para que cada pestaña maneje el suyo propio
      // y evitar tener "doble barra" o títulos incorrectos.
      body: _pages[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        // Usamos tu tema si está disponible, si no, azul por defecto
        selectedItemColor: AppTheme.secondaryBlue, 
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Inicio", // "Validar" sonaba muy técnico, Inicio es más estándar
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Estudiantes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}