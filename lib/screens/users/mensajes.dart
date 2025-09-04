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
  List<Map<String, dynamic>> _usuariosConChat = [];
  List<Map<String, dynamic>> _usuariosSinChat = [];
  String _filtroBusqueda = '';
  int? matricul;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsuariosYMensajes();
  }

  Future<void> _loadUsuariosYMensajes() async {
    final prefs = await SharedPreferences.getInstance();
    matricul = prefs.getInt('matricula');

    if (matricul == null) {
      setState(() => loading = false);
      return;
    }
    final int matricula = matricul!;

    // Cargar usuarios normales
    final dataUsuarios = await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido, roles(nombre), foto_url')
        .neq('matricula', matricula)
        .order('nombre');

    // Cargar administradores
    final dataAdmins = await supabase
        .from('administradores')
        .select('id, nombre, correo, foto_url');

    // Convertir y unificar
    final List<Map<String, dynamic>> listaUsuarios =
        List<Map<String, dynamic>>.from(dataUsuarios);

    final listaAdmins =
        List<Map<String, dynamic>>.from(dataAdmins).map((admin) {
          return {
            'matricula': admin['id'] ?? 0, // si es null, asigna 0
            'nombre': admin['nombre'] ?? '',
            'apellido': '',
            'roles': {'nombre': 'Administrador'},
            'foto_url': admin['foto_url'] ?? '',
          };
        }).toList();

    final todos = [...listaUsuarios, ...listaAdmins];

    // Traer mensajes
    final mensajes = await supabase
        .from('mensajes')
        .select('remitente_id, destinatario_id, fecha_envio, estado')
        .or('remitente_id.eq.$matricula,destinatario_id.eq.$matricula');

    final mensajesFiltrados = mensajes.where(
      (m) => (m['estado'] ?? '') == 'enviado' || (m['estado'] ?? '') == 'visto',
    );

    final ultimoMensaje = <int, DateTime>{};
    final remitentesNoVistos = <int>{};

    for (final msg in mensajesFiltrados) {
      final int remitenteId = msg['remitente_id'] ?? 0;
      final int destinatarioId = msg['destinatario_id'] ?? 0;
      final String fechaStr = msg['fecha_envio'] ?? '';
      if (fechaStr.isEmpty) continue; // ignorar si no hay fecha

      final otroId = remitenteId == matricula ? destinatarioId : remitenteId;

      DateTime fecha;
      try {
        fecha = DateTime.parse(fechaStr);
      } catch (_) {
        continue; // ignorar si el parse falla
      }

      if (!ultimoMensaje.containsKey(otroId) ||
          fecha.isAfter(ultimoMensaje[otroId]!)) {
        ultimoMensaje[otroId] = fecha;
      }

      if ((msg['estado'] ?? '') == 'enviado' && destinatarioId == matricula) {
        remitentesNoVistos.add(remitenteId);
      }
    }

    final usuariosConChat =
        todos
            .where(
              (u) =>
                  u['matricula'] != null &&
                  ultimoMensaje.containsKey(u['matricula']),
            )
            .toList();
    final usuariosSinChat =
        todos
            .where(
              (u) =>
                  u['matricula'] == null ||
                  !ultimoMensaje.containsKey(u['matricula']),
            )
            .toList();

    for (final usuario in usuariosConChat) {
      final int userMatricula = usuario['matricula'] ?? 0;
      usuario['noVisto'] = remitentesNoVistos.contains(userMatricula);
    }

    usuariosConChat.sort((a, b) {
      final fechaA = ultimoMensaje[a['matricula']] ?? DateTime(2000);
      final fechaB = ultimoMensaje[b['matricula']] ?? DateTime(2000);
      return fechaB.compareTo(fechaA);
    });

    setState(() {
      _usuariosConChat = usuariosConChat;
      _usuariosSinChat = usuariosSinChat;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuariosBuscados =
        [..._usuariosConChat, ..._usuariosSinChat].where((usuario) {
          final nombre = usuario['nombre']?.toLowerCase() ?? '';
          final apellido = usuario['apellido']?.toLowerCase() ?? '';
          return nombre.contains(_filtroBusqueda) ||
              apellido.contains(_filtroBusqueda);
        }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Colors.black12,
            ),
          ),
        ),
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
                        hintText: 'Buscar nombre o apellido',
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
                        usuariosBuscados.isEmpty
                            ? const Center(
                              child: Text('No se encontraron usuarios'),
                            )
                            : ListView.builder(
                              itemCount: usuariosBuscados.length,
                              itemBuilder: (context, index) {
                                final usuario = usuariosBuscados[index];
                                return _PersonaCard(
                                  name:
                                      '${usuario['nombre']} ${usuario['apellido']}',
                                  role: usuario['roles']['nombre'],
                                  matricula: usuario['matricula'],
                                  imgur: usuario['foto_url'],
                                  remitente: matricul!,
                                  noVisto: usuario['noVisto'] ?? false,
                                  onReturn: _loadUsuariosYMensajes,
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
  final bool noVisto;
  final VoidCallback onReturn;

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur,
    required this.remitente,
    required this.noVisto,
    required this.onReturn,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (noVisto)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () async {
          final isAdmin = role.toLowerCase() == 'administrador';

          await Supabase.instance.client
              .from('mensajes')
              .update({'estado': 'visto'})
              .eq('remitente_id', matricula)
              .eq('destinatario_id', remitente)
              .eq('estado', 'enviado');

          await Navigator.push(
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
          onReturn();
        },
      ),
    );
  }
}
