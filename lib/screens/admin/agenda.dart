import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'agenda_detail.dart';
import 'main_navigator.dart';
import 'perfil.dart';

class AgendaUsuario extends StatefulWidget {
  const AgendaUsuario({super.key});

  @override
  State<AgendaUsuario> createState() => _AgendaUsuarioState();
}

class _AgendaUsuarioState extends State<AgendaUsuario> {
  /// Cliente de Supabase
  final supabase = Supabase.instance.client;

  /// Lista con los eventos obtenidos de la BD
  List<dynamic> eventos = [];

  /// Indicador de carga
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  /// Obtiene todos los eventos ordenados por fecha de inicio
  Future<void> _cargarEventos() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('eventos')
          .select()
          .order('fecha_inicio');
      if (mounted) {
        setState(() {
          eventos = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar eventos: $e')));
        setState(() => isLoading = false);
      }
    }
  }

  /// Muestra un diálogo para crear un nuevo evento
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilScreen()),
              ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Agenda de Eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : eventos.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Por el momento no cuentas con\nningun evento.\nExplora más eventos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _cargarEventos,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading:
                          evento['logo_url'] != null &&
                                  evento['logo_url'].toString().isNotEmpty
                              ? Image.network(
                                evento['logo_url'],
                                width: 70,
                                height: 70,
                                fit: BoxFit.contain,
                              )
                              : null,
                      title: Text(
                        evento['nombre_evento'] ?? 'Sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${evento['fecha_inicio']}  -  ${evento['fecha_fin']}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    AgendaEventoScreen(idEvento: evento['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Comunidad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
        ],
      ),
    );
  }
}
