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
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? adminData;
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

    final data =
        await supabase
            .from('administradores')
            .select('id, nombre, correo, fecha_registro, foto_url')
            .eq('id', adminId)
            .maybeSingle();

    setState(() {
      adminData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Perfil del Administrador',
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
              : adminData == null
              ? const Center(child: Text("No se encontró el perfil"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    width: 400,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              (adminData!['foto_url'] != null &&
                                      adminData!['foto_url']
                                          .toString()
                                          .isNotEmpty)
                                  ? NetworkImage(adminData!['foto_url'])
                                  : null,
                          child:
                              (adminData!['foto_url'] == null ||
                                      adminData!['foto_url'].toString().isEmpty)
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          adminData!['nombre'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          adminData!['correo'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Registro: ${adminData!['fecha_registro'] != null ? adminData!['fecha_registro'].toString().split('T').first : 'No disponible'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditarPerfilScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
}
