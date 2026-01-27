import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'explore_tab.dart'; 
import 'profile_tab.dart'; 
import 'applications_tab.dart'; // <--- 1. IMPORTANTE: Importamos la nueva pestaña

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0; // Controla qué pestaña está activa

  // Lista de las 3 Pantallas
  final List<Widget> _pages = [
    // 1. Explorar (Muro de Ofertas)
    const ExploreTab(), 
    
    // 2. Mis Postulaciones (AHORA CONECTADO)
    const ApplicationsTab(),
    
    // 3. Perfil del Pasante
    const ProfileTab(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar cambia según la pestaña
      appBar: AppBar(
        title: Text(
          _getTitle(_currentIndex),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Quita la flecha de "atrás"
        elevation: 0,
      ),
      
      // Muestra la página seleccionada
      body: _pages[_currentIndex],
      
      // Barra de Navegación Inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryOrange, // Naranja activo
        unselectedItemColor: Colors.grey, // Gris inactivo
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Evita que se muevan los iconos
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Explorar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_history_outlined),
            label: "Postulaciones",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  // Título dinámico para la barra superior
  String _getTitle(int index) {
    switch (index) {
      case 0: return "Ofertas Disponibles";
      case 1: return "Mis Postulaciones";
      case 2: return "Mi Perfil";
      default: return "UNIMET Internship";
    }
  }
}