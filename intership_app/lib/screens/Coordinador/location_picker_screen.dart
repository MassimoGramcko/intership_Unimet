import 'dart:convert'; // Para procesar la respuesta del buscador
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Para conectar al buscador
import '../../config/theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Coordenadas iniciales (Caracas por defecto)
  LatLng _currentCenter = const LatLng(10.4806, -66.9036);
  
  // Controlador para mover el mapa programáticamente
  final MapController _mapController = MapController();
  
  // Controlador del texto de búsqueda
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;

  // --- FUNCIÓN PARA BUSCAR DIRECCIÓN ---
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus(); // Ocultar teclado

    try {
      // Usamos la API gratuita de Nominatim (OpenStreetMap)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'com.unimet.intership_app', // Identificador requerido por OSM
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          final newLocation = LatLng(lat, lon);

          // 1. Actualizamos el pin
          setState(() {
            _currentCenter = newLocation;
          });

          // 2. Movemos la cámara del mapa
          _mapController.move(newLocation, 16.0);
          
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No se encontraron resultados"), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. EL MAPA
          FlutterMap(
            mapController: _mapController, // Vinculamos el controlador
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                // Al tocar, movemos el marcador a ese punto
                setState(() {
                  _currentCenter = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.unimet.intership_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.redAccent,
                      size: 50,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BARRA DE BÚSQUEDA (Top)
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Card(
              elevation: 8,
              color: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Buscar lugar (ej: Torre Banesco)...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchLocation(), // Buscar al dar Enter
                      ),
                    ),
                    _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: SizedBox(
                                width: 20, height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: AppTheme.primaryOrange),
                            onPressed: _searchLocation,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // 3. BOTÓN CONFIRMAR (Bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Retornar las coordenadas seleccionadas
                Navigator.pop(context, _currentCenter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 10,
              ),
              child: const Text(
                "CONFIRMAR UBICACIÓN",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}