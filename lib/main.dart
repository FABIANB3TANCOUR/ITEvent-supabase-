import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ← NUEVO

import 'screens/type_logins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← NUEVO

  await Supabase.initialize(
    // ← NUEVO
    url: 'https://bsiepzgutwsmbeftyrdd.supabase.co', // ← CAMBIA ESTO
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzaWVwemd1dHdzbWJlZnR5cmRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0MTUxMDQsImV4cCI6MjA2Mzk5MTEwNH0.5UxlIN7IueevK82QoWly1MoGil1kRSU8cFoygVns-T8', // ← CAMBIA ESTO
  );
  await initializeDateFormatting('es', null);
  runApp(const ITEventApp());
}

class ITEventApp extends StatelessWidget {
  const ITEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITEvent',
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162A87), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'ITE',
                    style: TextStyle(
                      fontSize: 36,
                      fontStyle: FontStyle.italic,
                      color: Colors.yellow[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'vent',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TypeLogin(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // const SizedBox(height: 15),
                  //   // ElevatedButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => const NuevoUsuarioScreen(),
                  //         ),
                  //       );
                  //     },

                  //     style: OutlinedButton.styleFrom(
                  //       minimumSize: const Size(double.infinity, 50),
                  //       side: const BorderSide(color: Colors.indigo),
                  //     ),
                  //     child: const Text(
                  //       'Registrarme',
                  //       style: TextStyle(color: Colors.indigo),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
