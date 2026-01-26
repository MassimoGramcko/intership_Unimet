import 'package:flutter/material.dart';
import 'package:intership_app/presentation/screens/internship_detail_screen.dart';
import 'package:intership_app/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. CONTROL DE NAVEGACIÓN (Índice de la barra inferior)
  int _currentIndex = 0;

  // 2. LISTA DE DATOS (Simulamos una base de datos)
  final List<Map<String, String>> _allInternships = [
    {
      "title": "Desarrollador Flutter Jr",
      "company": "Tech Solutions C.A.",
      "location": "Caracas (El Rosal)",
      "category": "Sistemas",
      "mode": "Remoto"
    },
    {
      "title": "Asistente Administrativo",
      "company": "Banco Mercantil",
      "location": "Caracas (La Florida)",
      "category": "Administración",
      "mode": "Presencial"
    },
    {
      "title": "Diseñador UI/UX",
      "company": "StartUp Vzla",
      "location": "Remoto",
      "category": "Diseño",
      "mode": "Remoto"
    },
    {
      "title": "Analista de Datos",
      "company": "Polar",
      "location": "Caracas (Los Cortijos)",
      "category": "Sistemas",
      "mode": "Híbrido"
    },
  ];

  // 3. VARIABLES PARA EL FILTRO
  List<Map<String, String>> _filteredInternships = [];
  String _searchQuery = "";
  String _selectedCategory = "Todas";

  @override
  void initState() {
    super.initState();
    _filteredInternships = _allInternships; // Al inicio mostramos todo
  }

  // FUNCIÓN PARA FILTRAR
  void _runFilter(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allInternships;
    } else {
      results = _allInternships
          .where((item) =>
              item["title"]!.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              item["company"]!.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    // Aplicar filtro de categoría si no es "Todas"
    if (_selectedCategory != "Todas") {
      results = results.where((item) => 
        _selectedCategory == "Remoto" ? item["mode"] == "Remoto" : item["category"] == _selectedCategory
      ).toList();
    }

    setState(() {
      _searchQuery = enteredKeyword;
      _filteredInternships = results;
    });
  }

  // FUNCIÓN PARA CAMBIAR CATEGORÍA (CHIPS)
  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _runFilter(_searchQuery); // Volvemos a filtrar con la nueva categoría
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si el índice es 1, mostramos el Perfil (truco sencillo para navegación)
    if (_currentIndex == 1) {
      return ProfileScreen(
        onBack: () {
          setState(() {
            _currentIndex = 0; // Volver al Home
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hola, Massimo 👋",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003399))),
                      Text("Encuentra tu pasantía ideal",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.notifications_none, color: Colors.black54),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // BARRA DE BÚSQUEDA FUNCIONAL
              TextField(
                onChanged: (value) => _runFilter(value),
                decoration: InputDecoration(
                  hintText: "Buscar cargo, empresa...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // FILTROS (CHIPS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("Todas"),
                    _buildFilterChip("Sistemas"),
                    _buildFilterChip("Remoto"),
                    _buildFilterChip("Administración"),
                    _buildFilterChip("Diseño"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text("Recomendadas para ti",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // LISTA DE RESULTADOS
              Expanded(
                child: _filteredInternships.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredInternships.length,
                        itemBuilder: (context, index) => _buildInternshipCard(_filteredInternships[index]),
                      )
                    : const Center(
                        child: Text("No se encontraron resultados 😔", style: TextStyle(color: Colors.grey)),
                      ),
              ),
            ],
          ),
        ),
      ),

      // BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF003399),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          _updateCategory(label);
        },
        selectedColor: const Color(0xFF003399),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInternshipCard(Map<String, String> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF003399)),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["title"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(data["company"]!, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                if (data["mode"] == "Remoto")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                    child: const Text("Remoto", style: TextStyle(fontSize: 10, color: Colors.green)),
                  )
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(data["location"]!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InternshipDetailScreen(
                        title: data["title"]!,
                        company: data["company"]!,
                        location: data["location"]!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003399),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Ver Detalles", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}