import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';
import 'modif_perfil.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String nombre = '';
  String correo = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  Future<void> _cargarDatosPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('adminId');
    if (adminId == null) return;

    final supabase = Supabase.instance.client;
    final data =
        await supabase
            .from('administradores')
            .select()
            .eq('id', adminId)
            .maybeSingle();

    if (data != null) {
      setState(() {
        nombre = data['nombre'] ?? '';
        correo = data['correo'] ?? '';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        leading: const Icon(Icons.person),
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: const Text("Todo"),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text("Recomendado"),
                        selected: true,
                        selectedColor: Colors.black45,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  ListTile(
                    leading: const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    title: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(correo),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModifPerfil(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Recomendaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _recomButton('Agregar localidad'),
                  _recomButton('Agregar afiliación'),
                  _recomButton('Agregar intereses'),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: (index) => navigateToPage(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Asistentes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificación',
          ),
        ],
      ),
    );
  }

  Widget _recomButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B5998),
        ),
        onPressed: () {},
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
