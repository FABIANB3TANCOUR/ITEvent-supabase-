import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InicioScreen(),
    );
  }
}

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "ITEvent",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.yellow),
            ),
            SizedBox(height: 20),
            Image.asset("assets/albatros_logo.png", width: 100),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Iniciar Sesión"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: Text("Registrarme"),
            ),
          ],
        ),
      ),
    );
  }
}