import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventario_app/auth/login_screen.dart';
import 'package:inventario_app/screens/home_screen.dart';
//import 'package:inventario_app/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Muestra pantalla de carga mientras revisa sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si el usuario está autenticado, entra a Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Si no está autenticado, va al Login
        return const LoginScreen();
      },
    );
  }
}
