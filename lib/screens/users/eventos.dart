import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_detail.dart';
import 'main_navigator.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final supabase = Supabase.instance.client;
  static const String _mapboxApiKey =
      'TU_API_KEY_MAPBOX'; // Reemplaza con tu API key

  List<dynamic> eventos = [];
  bool isLoading = true;
  bool _showMap = false; // Nuevo estado para alternar entre lista y mapa

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final matricula = prefs.getInt('matricula');
      if (matricula == null) throw Exception('Matrícula no encontrada');

      final registros = await supabase
          .from('registros')
          .select('id_evento')
          .eq('matricula', matricula);

      final List<int> idsRegistrados =
          registros
              .map((r) => r['id_evento'])
              .where((id) => id != null)
              .map<int>((id) => id as int)
              .toList();

      final data = await supabase
          .from('eventos')
          .select('''
            id,
            nombre_evento,
            fecha_inicio,
            fecha_fin,
            logo_url,
            latitud,
            longitud,
            municipio,
            estado
          ''')
          .order('fecha_inicio');

      final eventosFiltrados =
          idsRegistrados.isEmpty
              ? data
              : data
                  .where((evento) => !idsRegistrados.contains(evento['id']))
                  .toList();

      if (mounted) {
        setState(() {
          eventos = eventosFiltrados;
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

  Widget _buildMapView() {
    final eventosConUbicacion =
        eventos
            .where((e) => e['latitud'] != null && e['longitud'] != null)
            .toList();

    if (eventosConUbicacion.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay eventos con ubicación disponible',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _showMap = false),
              child: const Text('Ver lista de eventos'),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _calculateCenter(eventosConUbicacion),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$_mapboxApiKey',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers:
              eventosConUbicacion.map((evento) {
                return Marker(
                  point: LatLng(
                    (evento['latitud'] as num).toDouble(),
                    (evento['longitud'] as num).toDouble(),
                  ),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EventDetailUser(eventId: evento['id']),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            evento['nombre_evento'] ?? 'Evento',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  LatLng _calculateCenter(List<dynamic> eventos) {
    if (eventos.isEmpty)
      return const LatLng(19.4326, -99.1332); // CDMX por defecto

    double latSum = 0;
    double lngSum = 0;

    for (final evento in eventos) {
      latSum += (evento['latitud'] as num).toDouble();
      lngSum += (evento['longitud'] as num).toDouble();
    }

    return LatLng(latSum / eventos.length, lngSum / eventos.length);
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _cargarEventos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: eventos.length,
        itemBuilder: (context, index) {
          final evento = eventos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading:
                  evento['logo_url'] != null &&
                          evento['logo_url'].toString().isNotEmpty
                      ? Image.network(
                        evento['logo_url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.event),
                      )
                      : const Icon(Icons.event, size: 40),
              title: Text(
                evento['nombre_evento'] ?? 'Sin nombre',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(evento['fecha_inicio'])} - ${_formatDate(evento['fecha_fin'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (evento['municipio'] != null && evento['estado'] != null)
                    Text(
                      '${evento['municipio']}, ${evento['estado']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailUser(eventId: evento['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_back, color: Colors.white),
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
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'Ver lista' : 'Ver mapa',
          ),
        ],
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
                      onPressed: _cargarEventos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : _showMap
              ? _buildMapView()
              : _buildListView(),
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
