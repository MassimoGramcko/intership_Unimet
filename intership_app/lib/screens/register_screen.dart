import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'student_home.dart'; // <--- 1. IMPORTANTE: Importamos la pantalla destino

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Variable para guardar la carrera seleccionada
  String? selectedCareer;
  
  // Lista de carreras de la UNIMET
  final List<String> careers = [
    "Ing. de Sistemas",
    "Ing. de Producción",
    "Ing. Civil",
    "Ing. Mecánica",
    "Ing. Química",
    "Psicología",
    "Economía Empresarial",
    "Contaduría Pública",
    "Derecho",
    "Idiomas Modernos",
    "Estudios Liberales",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Estudiante"),
        backgroundColor: AppTheme.primaryOrange, 
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Crea tu cuenta",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: AppTheme.secondaryBlue 
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Completa tus datos para postularte a pasantías.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // 1. Nombres y Apellidos
              _buildTextField(label: "Nombres", icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(label: "Apellidos", icon: Icons.person_outline),
              const SizedBox(height: 15),

              // 2. Identificación
              _buildTextField(
                label: "Cédula de Identidad", 
                icon: Icons.badge_outlined,
                isNumber: true
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Carnet Estudiantil", 
                icon: Icons.card_membership,
                isNumber: true
              ),
              const SizedBox(height: 15),

              // 3. Contacto
              _buildTextField(
                label: "Correo (UNIMET / Gmail)", 
                icon: Icons.email_outlined,
                inputType: TextInputType.emailAddress
              ),
              const SizedBox(height: 15),

              // 4. Lista Desplegable de Carreras
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Carrera",
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
                value: selectedCareer,
                items: careers.map((String career) {
                  return DropdownMenuItem<String>(
                    value: career,
                    child: Text(career),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedCareer = newValue;
                  });
                },
              ),
              const SizedBox(height: 15),

              // 5. Contraseña
              _buildTextField(
                label: "Contraseña", 
                icon: Icons.lock_outline,
                isPassword: true
              ),

              const SizedBox(height: 40),

              // BOTÓN FINAL ACTUALIZADO
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // 2. CAMBIO AQUÍ: Navegación al Home
                  onPressed: () {
                    // Usamos pushAndRemoveUntil para que no pueda volver atrás al registro
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
                      (route) => false, 
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "CREAR CUENTA",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para crear inputs más rápido
  Widget _buildTextField({
    required String label, 
    required IconData icon, 
    bool isPassword = false,
    bool isNumber = false,
    TextInputType? inputType,
  }) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : (inputType ?? TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}