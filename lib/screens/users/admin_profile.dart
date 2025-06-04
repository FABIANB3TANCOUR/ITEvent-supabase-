import 'package:flutter/material.dart';
import 'package:itevent/screens/users/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';

class AdminProfilePage extends StatefulWidget {
  final int adminId;

  const AdminProfilePage({super.key, required this.adminId});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? admin;
  bool loading = true;
  int? remitente;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    remitente = prefs.getInt('matricula');
    if (remitente == null) return;

    try {
      final data =
          await supabase
              .from('administradores')
              .select('id, nombre, correo, foto_url')
              .eq('id', widget.adminId)
              .maybeSingle();

      setState(() {
        admin = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar administrador: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = admin?['nombre'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          name.isEmpty ? 'Perfil Admin' : name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : admin == null
              ? const Center(child: Text('Administrador no encontrado'))
              : Column(
                children: [
                  Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (admin?['foto_url'] != null &&
                                      (admin!['foto_url'] as String).isNotEmpty)
                                  ? NetworkImage(admin!['foto_url'])
                                  : null,
                          child:
                              (admin?['foto_url'] == null ||
                                      (admin!['foto_url'] as String).isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Administrador',
                                style: TextStyle(color: Colors.white),
                              ),
                              if ((admin?['correo'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  admin!['correo'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChatPage(
                                      remitenteId: remitente!,
                                      adminId: widget.adminId,
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            children: const [
                              Icon(Icons.mail_outline, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'Mensaje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Administrador del sistema, sin notas personales.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => navigateToPage(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Asistentes'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificación',
          ),
        ],
      ),
    );
  }
}
