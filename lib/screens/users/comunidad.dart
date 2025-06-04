import 'package:flutter/material.dart';
import 'package:itevent/screens/users/admin_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';
import 'perfil.dart';
import 'perfil_asistente.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _usuarios = [];
  String _filtroRol = '';
  bool loading = true;
  int? matricula;

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
          final rol = usuario['roles']?['nombre']?.toLowerCase() ?? '';
          return rol.contains(_filtroRol.toLowerCase());
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
          'Comunidad',
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
                        hintText: 'Buscar por rol (ej. estudiante, staff)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _filtroRol.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _filtroRol = '';
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          _filtroRol = valor;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        usuariosFiltrados.isEmpty
                            ? const Center(
                              child: Text(
                                'No se encontraron usuarios con ese rol.',
                              ),
                            )
                            : ListView.builder(
                              itemCount: usuariosFiltrados.length,
                              itemBuilder: (context, index) {
                                final u = usuariosFiltrados[index];
                                final String nombreCompleto =
                                    '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}';
                                return _PersonaCard(
                                  name: nombreCompleto.trim(),
                                  role: u['roles']?['nombre'] ?? 'Sin rol',
                                  matricula: u['matricula'],
                                  imgur: u['foto_url'],
                                );
                              },
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

class _PersonaCard extends StatelessWidget {
  final String name;
  final String role;
  final int matricula;
  final String? imgur;

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur,
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
          if (role == 'Administrador') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminProfilePage(adminId: matricula),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilUsuarioPage(matricula: matricula),
              ),
            );
          }
        },
      ),
    );
  }
}
