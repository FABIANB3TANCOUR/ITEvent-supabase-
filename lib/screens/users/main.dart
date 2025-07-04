import 'package:flutter/material.dart';
import 'package:itevent/screens/users/eventos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_detail.dart';
import 'main_navigator.dart';
import 'perfil.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
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
      final prefs = await SharedPreferences.getInstance();
      final matricula = prefs.getInt('matricula');

      if (matricula == null) {
        throw Exception('No se encontró la matrícula del usuario.');
      }

      final data = await supabase
          .from('registros')
          .select('eventos(*)') // JOIN con eventos
          .eq('matricula', matricula);

      final eventosRegistrados =
          data
              .where((row) => row['eventos'] != null)
              .map((row) => row['eventos'])
              .toList();

      if (mounted) {
        setState(() {
          eventos = eventosRegistrados;
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
          'Eventos',
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
                      'Por el momento no cuentas con\nningun evento.\nEspera a que existan mas eventos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventosScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Agregar evento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
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
                                (_) => EventDetailUser(eventId: evento['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      floatingActionButton:
          eventos.isNotEmpty
              ? FloatingActionButton(
                backgroundColor: Colors.indigo,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventosScreen()),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
