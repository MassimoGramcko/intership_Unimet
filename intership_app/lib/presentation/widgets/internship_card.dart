import 'package:flutter/material.dart';
import 'package:intership_app/presentation/screens/internship_detail_screen.dart';

class InternshipCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final bool isRemote; // 1. Agregado para arreglar dashboard_screen

  const InternshipCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    this.isRemote = false, // 2. Valor por defecto (si no lo pones, asume que no es remoto)
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILA SUPERIOR: Título + Badge de Remoto (si aplica)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF003399)
                    ),
                  ),
                ),
                // Solo mostramos esto si isRemote es true
                if (isRemote)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50], 
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Text("Remoto", style: TextStyle(fontSize: 10, color: Colors.green)),
                  )
              ],
            ),
            const SizedBox(height: 5),
            Text(company, style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 10),
            
            // UBICACIÓN
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // BOTÓN VER DETALLES
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InternshipDetailScreen(
                        title: title,
                        company: company,
                        location: location, // 3. Aquí enviamos la ubicación requerida
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