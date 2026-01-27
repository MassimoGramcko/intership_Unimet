import 'package:flutter/material.dart';
import '../config/theme.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. BARRA DE BÚSQUEDA Y FILTROS (Parte Superior)
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Buscador
              TextField(
                decoration: InputDecoration(
                  hintText: "Buscar pasantía (ej: Polar, Sistemas...)",
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),
              
              // Filtros Rápidos (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("Mi Carrera", true), // Activo
                    _buildFilterChip("Remoto", false),
                    _buildFilterChip("Presencial", false),
                    _buildFilterChip("Caracas", false),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. LISTA DE OFERTAS (Scroll Infinito)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Oferta 1: Ejemplo del PDF (Empresas Polar)
              _buildJobCard(
                company: "Empresas Polar",
                role: "Pasante de Ing. Producción",
                location: "Caracas - Los Cortijos",
                tags: ["Producción", "Industrial", "Presencial"],
                color: Colors.blue[900]!, // Color de marca simulado
              ),
              
              // Oferta 2: Otra de ejemplo
              _buildJobCard(
                company: "Nestlé Venezuela",
                role: "Analista de Datos (Sistemas)",
                location: "Remoto / Híbrido",
                tags: ["Sistemas", "SQL", "Excel"],
                color: Colors.brown,
              ),

              // Oferta 3: Ejemplo Bancario
              _buildJobCard(
                company: "Banco Mercantil",
                role: "Pasante de Finanzas",
                location: "Caracas - San Bernardino",
                tags: ["Economía", "Finanzas", "Excel"],
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET: Chip de Filtro
  Widget _buildFilterChip(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isActive ? AppTheme.primaryOrange : Colors.grey[200],
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // WIDGET: Tarjeta de Oferta
  Widget _buildJobCard({
    required String company,
    required String role,
    required String location,
    required List<String> tags,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo Simulado (Círculo con inicial)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      company[0], // Primera letra
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: color
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Títulos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                      ),
                      Text(
                        company,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Etiquetas (Tags)
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12, 
                    color: AppTheme.secondaryBlue,
                    fontWeight: FontWeight.w500
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 16),
            
            // Botón VER DETALLE
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Acción futura: Ver detalle
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryOrange),
                ),
                child: const Text(
                  "VER DETALLE", 
                  style: TextStyle(color: AppTheme.primaryOrange)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}