import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data =
          await supabase
              .from('usuarios')
              .select('''
            id,
            nombre,
            apellido,
            rol,
            correo,
            telefono,
            foto_url
          ''')
              .eq('id', widget.matricula)
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
                  Container(
                    color: Colors.blue[900],
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

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
                                user?['rol'] ?? 'Sin rol',
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
                        Column(
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
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Notas personales (placeholder)
                  const Padding(
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
                        Text('Escribe Notas'),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Sección de contacto
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contacto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mantente en contacto con $fullName intercambiando información de contacto',
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              // Acción para intercambiar info
                            },
                            child: const Text(
                              'Contactar información',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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
