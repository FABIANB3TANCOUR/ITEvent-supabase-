import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido a ITEvent"),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: const Text(
          "Esta es la pantalla principal después de iniciar sesión.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}