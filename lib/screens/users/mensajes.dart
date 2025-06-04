import 'package:flutter/material.dart';
import 'package:itevent/screens/users/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';
import 'perfil.dart';

class MensajesScreen extends StatefulWidget {
  const MensajesScreen({super.key});

  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _usuarios = [];
  String _filtroBusqueda = '';
  int? matricula;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminIdYUsuarios();
  }

  Future<void> _loadAdminIdYUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    matricula = prefs.getInt('matricula');

    if (matricula == null) {
      setState(() => loading = false);
      return;
    }

    // Cargar usuarios normales
    final dataUsuarios = await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido, roles(nombre), foto_url')
        .neq('matricula', matricula!) // Excluir al usuario actual
        .order('nombre');

    // Cargar administradores
    final dataAdmins = await supabase
        .from('administradores')
        .select('id, nombre, correo, foto_url');

    // Convertir y unificar
    final List<Map<String, dynamic>> listaUsuarios =
        List<Map<String, dynamic>>.from(dataUsuarios);

    final List<Map<String, dynamic>> listaAdmins =
        List<Map<String, dynamic>>.from(dataAdmins).map((admin) {
          return {
            'matricula': admin['id'], // estandarizamos como matricula
            'nombre': admin['nombre'],
            'apellido': '', // vacío si no hay campo apellido
            'roles': {'nombre': 'Administrador'},
            'foot_url': admin['foot_url'],
          };
        }).toList();

    // Combinar usuarios y administradores
    setState(() {
      _usuarios = [...listaUsuarios, ...listaAdmins];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados =
        _usuarios.where((usuario) {
          final nombre = usuario['nombre']?.toLowerCase() ?? '';
          final apellido = usuario['apellido']?.toLowerCase() ?? '';
          return nombre.contains(_filtroBusqueda) ||
              apellido.contains(_filtroBusqueda);
        }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Mensajes',
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
              : Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o apellido',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          _filtroBusqueda = valor.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child:
                        usuariosFiltrados.isEmpty
                            ? const Center(
                              child: Text('No se encontraron usuarios'),
                            )
                            : ListView.builder(
                              itemCount: usuariosFiltrados.length,
                              itemBuilder: (context, index) {
                                final usuario = usuariosFiltrados[index];
                                return _PersonaCard(
                                  name:
                                      '${usuario['nombre']} ${usuario['apellido']}',
                                  role: usuario['roles']['nombre'],
                                  matricula: usuario['matricula'],
                                  imgur: usuario['foto_url'],
                                  remitente: matricula!,
                                );
                              },
                            ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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

class _PersonaCard extends StatelessWidget {
  final String name;
  final String role;
  final int matricula;
  final String? imgur;
  final int remitente;

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur,
    required this.remitente,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 40,
          backgroundImage:
              (imgur != null && imgur!.isNotEmpty)
                  ? NetworkImage(imgur!)
                  : null,
          child:
              (imgur == null || imgur!.isEmpty)
                  ? const Icon(Icons.person, size: 40)
                  : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final isAdmin = role.toLowerCase() == 'administrador';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatPage(
                    remitenteId: remitente,
                    destinatarioId: isAdmin ? null : matricula,
                    adminId: isAdmin ? matricula : null,
                  ),
            ),
          );
        },
      ),
    );
  }
}
