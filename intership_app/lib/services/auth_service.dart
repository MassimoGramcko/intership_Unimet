import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- PARTE A: REGISTRO (Crear cuenta y guardar datos) ---
  Future<String?> registerStudent({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String cedula,
    required String carnet,
    required String carrera,
  }) async {
    try {
      // 1. Crear el usuario en el sistema de seguridad
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Guardar sus datos personales en la Base de Datos
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'role': 'student', // <-- ¡Aquí definimos que es estudiante!
        'nombres': nombres,
        'apellidos': apellidos,
        'cedula': cedula,
        'carnet': carnet,
        'carrera': carrera,
        'email': email,
        'createdAt': DateTime.now(),
      });

      return null; // Null significa "Todo salió bien"
    } on FirebaseAuthException catch (e) {
      return e.message; // Devuelve el error (ej: "Email ya existe")
    } catch (e) {
      return "Ocurrió un error desconocido";
    }
  }

  // --- PARTE B: LOGIN (Ingresar y verificar rol) ---
  Future<User?> loginUser({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Error de autenticación";
    }
  }
}