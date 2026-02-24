import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart'; // IMPORTANTE: Para manejar coordenadas
import '../../config/theme.dart';
import 'location_picker_screen.dart'; // Asegúrate que la ruta sea correcta

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _wageController = TextEditingController();

  // Variables de estado
  String _modality = 'Presencial';
  bool _isLoading = false;

  // NUEVO: Variables para guardar coordenadas
  double? _latitude;
  double? _longitude;

  // NUEVO: Función para abrir el mapa
  Future<void> _pickLocation() async {
    // Navegamos a la pantalla del mapa y esperamos (await) el resultado
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    // Si el usuario seleccionó algo (no se devolvió con "atrás" sin guardar)
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });

      // Feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ubicación guardada del mapa"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // Función para enviar a Firebase
  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('job_offers').add({
        // 1. Datos básicos
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(), // Nombre del lugar
        'wage': _wageController.text.trim(),

        // NUEVO: Guardamos las coordenadas (pueden ser null si no eligió mapa)
        'latitude': _latitude,
        'longitude': _longitude,

        // 2. FECHAS
        'createdAt': FieldValue.serverTimestamp(),

        // 3. MODALIDAD
        'modality': _modality,
        'type': _modality,
        'isRemote': _modality == 'Remoto',

        // 4. Datos por defecto
        'isActive': true,
        'applicantsCount': 0,
        'isFeatured': false,
        'colorHex': '#FF5733',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Oferta publicada exitosamente!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo Dark Slate
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nueva Oferta",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Información del Puesto"),
              const SizedBox(height: 15),

              _buildTextField(
                _titleController,
                "Título",
                "Ej: Desarrollador Mobile",
                Icons.work_outline,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _companyController,
                "Empresa",
                "Ej: Tech Solutions",
                Icons.business,
              ),

              const SizedBox(height: 25),
              _buildSectionTitle("Detalles"),
              const SizedBox(height: 15),

              // --- AQUI MODIFICAMOS LA FILA DE UBICACIÓN Y MODALIDAD ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna Izquierda: Ubicación (Texto + Botón Mapa)
                  Expanded(
                    flex: 3, // Le damos más espacio a la ubicación
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ubicación",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Campo de Texto
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _locationController,
                                  style: const TextStyle(color: Colors.white),
                                  validator: (value) =>
                                      value!.isEmpty ? "Requerido" : null,
                                  decoration: InputDecoration(
                                    hintText: "Ej: Torre A",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),

                                    prefixIcon: const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white54,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Botón del Mapa
                            InkWell(
                              onTap: _pickLocation,
                              child: Container(
                                height: 50, // Misma altura aprox que el input
                                width: 50,
                                decoration: BoxDecoration(
                                  // Si ya seleccionó coordenadas, se pone verde
                                  color: _latitude != null
                                      ? Colors.green.withValues(alpha: 0.8)
                                      : Colors.orange,

                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                ),
                                child: Icon(
                                  _latitude != null ? Icons.check : Icons.map,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_latitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              "Coordenadas guardadas",
                              style: TextStyle(
                                color: Colors.greenAccent[400],
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Columna Derecha: Modalidad
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Modalidad",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height:
                              50, // Altura fija para alinear con el de al lado
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),

                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _modality,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              items: ['Presencial', 'Remoto', 'Híbrido'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) =>
                                  setState(() => _modality = newValue!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- FIN DE LA MODIFICACIÓN ---
              const SizedBox(height: 15),

              _buildTextField(
                _wageController,
                "Remuneración",
                "Ej: 100 USD / No remunerado",
                Icons.attach_money,
              ),

              const SizedBox(height: 25),
              _buildSectionTitle("Descripción"),
              const SizedBox(height: 15),
              _buildTextField(
                _descController,
                "Requisitos y funciones...",
                "",
                Icons.description,
                maxLines: 5,
              ),

              const SizedBox(height: 40),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "PUBLICAR AHORA",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryOrange,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            validator: (value) => value!.isEmpty ? "Campo requerido" : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),

              prefixIcon: maxLines == 1
                  ? Icon(icon, color: Colors.white54)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
