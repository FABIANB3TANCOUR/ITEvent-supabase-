import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart'; // Pantalla destino (EventScreen)

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({Key? key}) : super(key: key);

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? error;
  bool loading = false;

  Future<void> login() async {
    final matricula = matriculaController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      error = null;
      loading = true;
    });

    if (matricula.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Por favor ingresa matrícula y contraseña';
        loading = false;
      });
      return;
    }

    try {
      // Consulta la tabla "administradores" en Supabase
      final admin =
          await Supabase.instance.client
              .from('administradores')
              .select()
              .eq('id', matricula)
              .eq('password', password) // ➜ Usa hashing o Auth en producción
              .maybeSingle();

      if (admin != null) {
        if (!mounted) return;
        final adminId = admin['id'] as int; // <- tu consulta previa
        final nombre = admin['nombre'] as String; // si existe el campo
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('adminId', adminId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventScreen()),
        );
      } else {
        setState(() => error = 'Matrícula o contraseña incorrectos');
      }
    } catch (e) {
      setState(() => error = 'Error al conectarse a la base de datos');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    matriculaController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Administrador')),
      body: _loginForm(),
    );
  }

  Widget _loginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Text(
              'ITEvent',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No. Matrícula',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese aquí',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contraseña',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Ingrese aquí',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
