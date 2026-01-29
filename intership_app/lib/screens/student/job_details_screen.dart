import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'explore_tab.dart'; // Importamos esto para acceder a la clase JobOffer

class JobDetailsScreen extends StatelessWidget {
  final JobOffer offer;

  const JobDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      // Botón de Aplicar Flotante en la parte inferior
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Postulación enviada con éxito! (Simulación)")),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: AppTheme.primaryOrange.withOpacity(0.5),
          ),
          child: const Text("Postularme Ahora", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR CON IMAGEN DE FONDO SUTIL
          SliverAppBar(
            backgroundColor: AppTheme.backgroundDark,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(color: offer.brandColor.withOpacity(0.1)), // Fondo con tinte del color de la marca
                  Center(
                    child: Hero( // Animación suave del logo
                      tag: offer.id, 
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.business, size: 60, color: offer.brandColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Empresa
                  Text(
                    offer.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${offer.company} • ${offer.location}",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),
                  
                  const SizedBox(height: 20),

                  // Etiquetas (Tags)
                  Row(
                    children: [
                      _buildTag(offer.type, Colors.purpleAccent),
                      const SizedBox(width: 10),
                      _buildTag(offer.wage, Colors.greenAccent),
                      const SizedBox(width: 10),
                      if (offer.isRemote) _buildTag("Remoto", Colors.blueAccent),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 30),

                  // Descripción (Texto de relleno por ahora si no hay en DB)
                  const Text("Descripción del Puesto", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "Estamos buscando un ${offer.title} apasionado para unirse a nuestro equipo en ${offer.company}. \n\n"
                    "Responsabilidades:\n"
                    "• Colaborar con el equipo de diseño y desarrollo.\n"
                    "• Escribir código limpio y mantenible.\n"
                    "• Participar en revisiones de código.\n\n"
                    "Si tienes ganas de aprender y crecer profesionalmente, ¡esta es tu oportunidad!",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.6, fontSize: 15),
                  ),

                  const SizedBox(height: 30),
                  const Text("Requisitos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "• Estudiante de últimos semestres.\n"
                    "• Conocimientos básicos en el área.\n"
                    "• Proactivo y responsable.",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.6, fontSize: 15),
                  ),
                  
                  const SizedBox(height: 100), // Espacio extra para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}