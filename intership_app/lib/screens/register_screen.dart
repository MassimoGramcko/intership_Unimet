import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // <--- Verifica que esta ruta no tenga error
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para capturar el texto
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variable para el selector de carreras
  String? _selectedCarrera;
  
  // Lista de carreras de la Unimet (puedes agregar más)
  final List<String> _carreras = [
    'Ingeniería de Sistemas',
    'Ingeniería Civil',
    'Ingeniería Mecánica',
    'Ingeniería Química',
    'Ingeniería de Producción',
    'Psicología',
    'Derecho',
    'Administración',
    'Contaduría',
    'Economía',
    'Educación',
    'Idiomas Modernos',
    'Matemáticas',
    'Estudios Liberales'
  ];

  bool _isLoading = false;

  void _register() async {
    // 1. Validar que no haya campos vacíos
    if (_nombresController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _selectedCarrera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Mostrar ruedita de carga
    });

    final authService = AuthService();
    
    // 2. Llamar al servicio de Registro
    String? result = await authService.registerStudent(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      cedula: _cedulaController.text.trim(),
      carnet: _carnetController.text.trim(),
      carrera: _selectedCarrera!,
    );

    setState(() {
      _isLoading = false; // Ocultar ruedita
    });

    if (result == null) {
      // Éxito: Navegar al Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada con éxito! Por favor inicia sesión.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Error: Mostrar mensaje rojo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Estudiante")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              
              // Campos del formulario
              TextField(controller: _nombresController, decoration: const InputDecoration(labelText: "Nombres", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: "Apellidos", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _cedulaController, decoration: const InputDecoration(labelText: "Cédula", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _carnetController, decoration: const InputDecoration(labelText: "Carnet", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              
              // Dropdown (Lista desplegable)
              DropdownButtonFormField<String>(
                value: _selectedCarrera,
                decoration: const InputDecoration(labelText: "Carrera", border: OutlineInputBorder()),
                items: _carreras.map((String carrera) {
                  return DropdownMenuItem<String>(
                    value: carrera,
                    child: Text(carrera),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCarrera = newValue;
                  });
                },
              ),
              
              const SizedBox(height: 10),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo Unimet", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController, 
                decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              
              // Botón de Registrar
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Crear Cuenta"),
                  ),
              
              TextButton(
                onPressed: () {
                   Navigator.pop(context); 
                },
                child: const Text("¿Ya tienes cuenta? Ingresa aquí"),
              )
            ],
          ),
        ),
      ),
    );
  }
}