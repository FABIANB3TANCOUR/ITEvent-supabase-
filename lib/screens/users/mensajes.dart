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
  int? adminId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminIdYUsuarios();
  }

  Future<void> _loadAdminIdYUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('adminId');

    if (id == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    adminId = id;

    final data = await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido, roles(nombre), foto_url')
        .order('nombre');

    setState(() {
      _usuarios = List<Map<String, dynamic>>.from(data);
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
                                  adminId: adminId!,
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
  final int adminId;

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur,
    required this.adminId,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatPage(adminId: adminId, destinatarioId: matricula),
            ),
          );
        },
      ),
    );
  }
}
