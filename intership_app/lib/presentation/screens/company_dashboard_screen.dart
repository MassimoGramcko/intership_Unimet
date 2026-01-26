import 'package:flutter/material.dart';
import 'package:intership_app/presentation/screens/login_screen.dart';
import 'package:intership_app/presentation/screens/create_offer_screen.dart';

// CAMBIO IMPORTANTE: Ahora es StatefulWidget para poder actualizar la lista
class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  // 1. LISTA DE OFERTAS (Ya no son widgets fijos, es una lista de datos)
  List<Map<String, dynamic>> myOffers = [
    {"title": "Desarrollador Flutter Jr", "candidates": "35 postulantes", "isActive": true},
    {"title": "Diseñador UI/UX", "candidates": "12 postulantes", "isActive": true},
    {"title": "Analista QA", "candidates": "0 postulantes", "isActive": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Empresa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mis Ofertas Publicadas",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
            ),
            const SizedBox(height: 10),
            const Text(
              "Gestiona tus vacantes activas aquí.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 2. CONSTRUIMOS LA LISTA USANDO LOS DATOS DE 'myOffers'
            Expanded(
              child: ListView.builder(
                itemCount: myOffers.length,
                itemBuilder: (context, index) {
                  final offer = myOffers[index];
                  return _buildMyOfferCard(
                    offer['title'], 
                    offer['candidates'], 
                    offer['isActive']
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 3. ESPERAMOS EL RESULTADO DE LA PANTALLA DE CREAR
          final newOffer = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOfferScreen()),
          );

          // 4. SI VOLVIÓ CON DATOS, ACTUALIZAMOS LA LISTA
          if (newOffer != null) {
            setState(() {
              // Insertamos al principio (índice 0) para que salga arriba
              myOffers.insert(0, newOffer);
            });
          }
        },
        backgroundColor: const Color(0xFFFF6600),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Oferta", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMyOfferCard(String title, String candidates, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Expanded permite que el texto ocupe el espacio disponible sin romper el diseño
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(candidates, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isActive ? "Activa" : "Cerrada",
                      style: TextStyle(fontSize: 12, color: isActive ? Colors.green : Colors.grey),
                    ),
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF003399)),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}