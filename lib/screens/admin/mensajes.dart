import 'package:flutter/material.dart';
import 'package:itevent/screens/admin/chat.dart';
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
  Map<int, Map<String, dynamic>> _ultimosMensajes = {};
  String _filtroBusqueda = '';
  int? adminId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminIdYUsuarios();
    _setupRealtimeSubscription();
  }

  Future<void> _loadAdminIdYUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('adminId');

    if (id == null) {
      setState(() => loading = false);
      return;
    }

    adminId = id;

    final data = await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido, roles(nombre), foto_url')
        .order('nombre');

    // Obtener últimos mensajes para cada usuario
    for (var usuario in data) {
      final mensajes = await supabase
          .from('mensajes')
          .select()
          .or('and(remitente_id.eq.${adminId},destinatario_id.eq.${usuario['matricula']}),and(remitente_id.eq.${usuario['matricula']},destinatario_id.eq.${adminId})')
          .order('fecha_envio', ascending: false)
          .limit(1);

      if (mensajes.isNotEmpty) {
        _ultimosMensajes[usuario['matricula']] = mensajes[0];
      }
    }

    setState(() {
      _usuarios = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  void _setupRealtimeSubscription() {
    supabase
        .channel('mensajes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (payload) {
            final nuevoMensaje = payload.newRecord;
            final remitenteId = nuevoMensaje['remitente_id'];
            final destinatarioId = nuevoMensaje['destinatario_id'];
            
            if (remitenteId == adminId || destinatarioId == adminId) {
              final otroUsuarioId = remitenteId == adminId ? destinatarioId : remitenteId;
              setState(() {
                _ultimosMensajes[otroUsuarioId] = nuevoMensaje;
              });
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados = _usuarios.where((usuario) {
      final nombre = usuario['nombre']?.toLowerCase() ?? '';
      final apellido = usuario['apellido']?.toLowerCase() ?? '';
      return nombre.contains(_filtroBusqueda) || apellido.contains(_filtroBusqueda);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap: () => Navigator.push(
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: usuariosFiltrados.isEmpty
                      ? const Center(child: Text('No se encontraron usuarios'))
                      : ListView.builder(
                          itemCount: usuariosFiltrados.length,
                          itemBuilder: (context, index) {
                            final usuario = usuariosFiltrados[index];
                            final ultimoMensaje = _ultimosMensajes[usuario['matricula']];
                            return _PersonaCard(
                              name: '${usuario['nombre']} ${usuario['apellido']}',
                              role: usuario['roles']['nombre'],
                              matricula: usuario['matricula'],
                              imgur: usuario['foto_url'],
                              adminId: adminId!,
                              ultimoMensaje: ultimoMensaje?['contenido'],
                              esMio: ultimoMensaje?['remitente_id'] == adminId,
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
  final String? ultimoMensaje;
  final bool? esMio;

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur,
    required this.adminId,
    this.ultimoMensaje,
    this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 40,
          backgroundImage: (imgur != null && imgur!.isNotEmpty)
              ? NetworkImage(imgur!)
              : null,
          child: (imgur == null || imgur!.isEmpty)
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            if (ultimoMensaje != null)
              Text(
                '${esMio == true ? 'Tú: ' : ''}$ultimoMensaje',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(adminId: adminId, destinatarioId: matricula),
            ),
          );
        },
      ),
    );
  }
}