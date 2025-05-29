import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bienvenida.dart';

class LoginStaffPage extends StatefulWidget {
  const LoginStaffPage({super.key});

  @override
  State<LoginStaffPage> createState() => _LoginStaffPageState();
}

class _LoginStaffPageState extends State<LoginStaffPage> {
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? error;

  Future<void> login() async {
    final matricula = matriculaController.text.trim();
    final password = passwordController.text.trim();
    setState(() => error = null);

    if (matricula.isEmpty || password.isEmpty) {
      setState(() => error = 'Por favor ingresa matrícula y contraseña');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('organizadores')
          .select()
          .eq('matricula', matricula)
          .eq('contrasena', password)
          .maybeSingle();

      if (response != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaBienvenida()),
        );
      } else {
        setState(() => error = 'Matrícula o contraseña incorrectos');
      }
    } catch (e) {
      setState(() => error = 'Error al conectarse a Supabase');
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
      appBar: AppBar(title: const Text('Login Staff')),
      body: _loginForm(),
    );
  }

  Widget _loginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Text('ITEvent',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No. Matrícula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese aquí',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Ingrese aquí',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
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
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
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
