import 'package:flutter/material.dart';
import 'package:itevent/screens/admin/noti_new.dart';
import 'package:itevent/screens/admin/perfil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notificaciones = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotificaciones();
  }

  Future<void> _fetchNotificaciones() async {
    final data = await supabase
        .from('notificaciones')
        .select('id, titulo, descripcion, logo_url')
        .order('id', ascending: false);

    setState(() {
      _notificaciones = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  Future<void> _eliminarNotificacion(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Eliminar notificación?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await supabase.from('notificaciones').delete().eq('id', id);
      _fetchNotificaciones();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notificación eliminada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : _notificaciones.isEmpty
              ? const Center(child: Text('No hay notificaciones disponibles'))
              : ListView.separated(
                itemCount: _notificaciones.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final noti = _notificaciones[index];
                  return NotiCard(
                    id: noti['id'],
                    title: noti['titulo'],
                    subtitle: noti['descripcion'] ?? '',
                    logoUrl: noti['logo_url'],
                    onDelete: () => _eliminarNotificacion(noti['id']),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddNotificacionScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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

class NotiCard extends StatelessWidget {
  final int id;
  final String title;
  final String subtitle;
  final String? logoUrl;
  final VoidCallback onDelete;

  const NotiCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onDelete,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          logoUrl != null && logoUrl!.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(logoUrl!))
              : const Icon(Icons.notifications, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}
