import 'package:flutter/material.dart';
import 'package:itevent/screens/users/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final int matricula;

  const PerfilUsuarioPage({super.key, required this.matricula});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? user;
  bool loading = true;
  int? matricula;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    matricula = prefs.getInt('matricula');
    if (matricula == null) return;
    try {
      final data =
          await supabase
              .from('usuarios')
              .select('''
        matricula,
        nombre,
        apellido,
        roles(nombre),
        correo,
        telefono,
        foto_url,
        nota,
        presentate,
        autoriza_datos
      ''')
              .eq('matricula', widget.matricula)
              .maybeSingle();

      setState(() {
        user = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar usuario: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${user?['nombre'] ?? ''} ${user?['apellido'] ?? ''}'.trim();
    final bool autorizacion = user?['autoriza_datos'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          fullName.isEmpty ? 'Perfil' : fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('Usuario no encontrado'))
              : Column(
                children: [
                  // Cabecera azul

                  // Bloque gris con avatar y datos
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
                              (user?['foto_url'] != null &&
                                      (user!['foto_url'] as String).isNotEmpty)
                                  ? NetworkImage(user!['foto_url'])
                                  : null,
                          child:
                              (user?['foto_url'] == null ||
                                      (user!['foto_url'] as String).isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?['roles']['nombre'] ?? 'Sin rol',
                                style: const TextStyle(color: Colors.white),
                              ),
                              if ((user?['correo'] ?? '').toString().isNotEmpty)
                                Text(
                                  user!['correo'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              if ((user?['telefono'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'Tel: ${user!['telefono']}',
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
                                      remitenteId: matricula!,
                                      destinatarioId: widget.matricula,
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

                  // Notas personales (placeholder)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notas Personales',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(user?['nota'] ?? 'No hay notas'),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Sección de contacto
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
