import 'package:flutter/material.dart';
import 'package:intership_app/presentation/screens/profile_screen.dart';
import 'package:intership_app/presentation/widgets/internship_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Índice para controlar qué pestaña está activa (0, 1 o 2)
  int _selectedIndex = 0;

  // Lista de Pantallas para cada pestaña
  final List<Widget> _pages = [
    const HomeTab(),          // Pestaña 0: Inicio
    const ApplicationsTab(),  // Pestaña 1: Mis Postulaciones (AHORA ES INTERACTIVA)
    const ProfileScreen(),    // Pestaña 2: Perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El cuerpo cambia según la pestaña seleccionada
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      // --- BARRA DE NAVEGACIÓN INFERIOR ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF003399), // Azul activo
        unselectedItemColor: Colors.grey,           // Gris inactivo
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), 
            activeIcon: Icon(Icons.assignment),
            label: 'Postulaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// WIDGET 1: PESTAÑA DE INICIO
// -------------------------------------------------------
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = "Todas";
  final List<String> _categories = ["Todas", "Remoto", "Presencial", "Híbrido", "Pagas"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hola, Massimo 👋",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003399))),
                  Text("Encuentra tu pasantía ideal",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              
              const SizedBox(height: 25),

              // BARRA DE BÚSQUEDA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text("Buscar cargo, empresa...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // FILTROS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: const Color(0xFF003399),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 30),

              // DESTACADOS
              const Text("🔥 Recomendados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFeaturedCard("Flutter Dev", "Google", Colors.blue),
                    _buildFeaturedCard("UI Designer", "Apple", Colors.black),
                    _buildFeaturedCard("Data Analyst", "Amazon", Colors.orange),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // LISTA VERTICAL
              const Text("🕒 Nuevas Ofertas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const InternshipCard(
                title: "Desarrollador Mobile",
                company: "Tech Solutions",
                location: "Caracas (Híbrido)",
                isRemote: false,
              ),
              const InternshipCard(
                title: "Diseñador UX/UI",
                company: "Creative Studio",
                location: "Remoto",
                isRemote: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(String title, String company, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.business, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2),
          const SizedBox(height: 5),
          Text(company, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// WIDGET 2: PESTAÑA "MIS POSTULACIONES" (ACTUALIZADA)
// -------------------------------------------------------
class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  // Ahora la lista está aquí y se puede modificar
  final List<Map<String, dynamic>> _applications = [
    {
      "title": "Desarrollador Flutter Jr",
      "company": "Tech Solutions",
      "status": "En revisión",
      "color": Colors.orange,
    },
    {
      "title": "Analista de Datos",
      "company": "Polar",
      "status": "Visto",
      "color": Colors.blue,
    },
    {
      "title": "Diseñador UI/UX",
      "company": "StartUp Vzla",
      "status": "Rechazado",
      "color": Colors.red,
    },
    {
      "title": "Soporte Técnico",
      "company": "Cantv",
      "status": "Enviado",
      "color": Colors.grey,
    },
  ];

  // Función para eliminar un elemento de la lista
  void _removeApplication(int index) {
    setState(() {
      _applications.removeAt(index);
    });
    
    // Muestra un mensaje abajo confirmando la acción
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Postulación retirada correctamente"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mis Postulaciones", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003399))),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // Si no hay postulaciones, mostramos un diseño vacío
      body: _applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("No tienes postulaciones activas", 
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final item = _applications[index];
                return _buildItem(
                  index, 
                  item["title"], 
                  item["company"], 
                  item["status"], 
                  item["color"]
                );
              },
            ),
    );
  }

  Widget _buildItem(int index, String title, String company, String status, Color color) {
    // Dismissible permite borrar deslizando el dedo
    return Dismissible(
      key: Key(title + company), // Llave única para identificar la tarjeta
      direction: DismissDirection.endToStart, // Deslizar de derecha a izquierda
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeApplication(index);
      },
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
            side: BorderSide(color: Colors.grey.shade200)
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.business_center_outlined, color: Color(0xFF003399)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(company),
          
          // Lado derecho: Estado + Botón X
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(status, 
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => _removeApplication(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}