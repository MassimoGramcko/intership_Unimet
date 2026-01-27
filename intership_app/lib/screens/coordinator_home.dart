import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'admin_dashboard_tab.dart'; // 1. Validar Ofertas
import 'admin_students_tab.dart';  // 2. Directorio Estudiantes
import 'admin_profile_tab.dart';   // 3. Perfil Coordinador (NUEVO)

class CoordinatorHomeScreen extends StatefulWidget {
  const CoordinatorHomeScreen({super.key});

  @override
  State<CoordinatorHomeScreen> createState() => _CoordinatorHomeScreenState();
}

class _CoordinatorHomeScreenState extends State<CoordinatorHomeScreen> {
  int _currentIndex = 0;

  // Lista de las 3 pantallas principales del Coordinador
  final List<Widget> _pages = [
    const AdminDashboardTab(), // Pestaña 0: Validar
    const AdminStudentsTab(),  // Pestaña 1: Estudiantes
    const AdminProfileTab(),   // Pestaña 2: Perfil (YA CONECTADO)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Coordinación", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondaryBlue, // Azul institucional
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Evita botón de atrás automático
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.secondaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Mantiene etiquetas visibles
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Validar"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Estudiantes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}