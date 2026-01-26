import 'package:flutter/material.dart';

class InternshipDetailScreen extends StatelessWidget {
  final String title;
  final String company;
  final String location; // ¡Aquí agregamos lo que faltaba!

  const InternshipDetailScreen({
    super.key,
    required this.title,
    required this.company,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la Oferta"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003399),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABECERA
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business, size: 40, color: Color(0xFF003399)),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          company,
                          style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ETIQUETAS (Aquí usamos la variable location)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTag(location, Icons.location_on_outlined),
                      const SizedBox(width: 10),
                      _buildTag("Tiempo Completo", Icons.access_time),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // DESCRIPCIÓN
                  const Text(
                    "Descripción del Puesto",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Estamos buscando un estudiante apasionado por la tecnología para unirse a nuestro equipo. \n\n"
                    "Responsabilidades:\n"
                    "• Desarrollo de nuevas funcionalidades.\n"
                    "• Corrección de errores y optimización.\n"
                    "• Colaboración con el equipo de diseño.\n\n"
                    "Requisitos:\n"
                    "• Conocimientos en Flutter/Dart.\n"
                    "• Ganas de aprender.",
                    style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // BOTÓN DE POSTULARSE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Postulación enviada con éxito! 🚀"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context); // Regresa al Home después de postularse
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003399),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "POSTULARME AHORA",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }
}