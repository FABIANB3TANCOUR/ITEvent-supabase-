import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditEventScreen extends StatefulWidget {
  final int eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final supabase = Supabase.instance.client;
  static const String _mapboxApiKey =
      'pk.eyJ1IjoidGhlbWFtaXRhczQzIiwiYSI6ImNtYmlpZWV0ZzA2MWUybXB6NDk4eGU3ZDIifQ.g2P3tNXrG58VBYiOL8Ob1Q';

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cupoController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _portadaUrlController = TextEditingController();
  final _estadoController = TextEditingController();
  final _municipioController = TextEditingController();
  final _direccionController = TextEditingController();

  List<dynamic> _organizadoresDisponibles = [];
  List<int> _organizadoresSeleccionados = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  LatLng? _ubicacionSeleccionada;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  String? limpiarTexto(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isEmpty ? null : texto;
  }

  Future<void> _loadEventData() async {
    try {
      final data =
          await supabase
              .from('eventos')
              .select()
              .eq('id', widget.eventId)
              .maybeSingle();

      // Obtener todos los usuarios que pueden ser organizadores (rol_id = 3)
      final organizadoresDisponibles = await supabase
          .from('usuarios')
          .select()
          .eq(
            'rol_id',
            3,
          ); // suponiendo que rol_id = 3 corresponde a organizadores

      // Obtener los organizadores que ya están asignados al evento
      final organizadoresEvento = await supabase
          .from('evento_organizador')
          .select('id_usuario') // obtenemos los IDs de usuario asignados
          .eq('id_evento', widget.eventId);

      if (data != null) {
        _nombreController.text = data['nombre_evento'] ?? '';
        _descripcionController.text = data['descripcion'] ?? '';
        _cupoController.text = (data['cupo_total'] ?? '').toString();
        _logoUrlController.text = data['logo_url'] ?? '';
        _portadaUrlController.text = data['portada_url'] ?? '';
        _estadoController.text = data['estado'] ?? '';
        _municipioController.text = data['municipio'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _fechaInicio = DateTime.tryParse(data['fecha_inicio'] ?? '');
        _fechaFin = DateTime.tryParse(data['fecha_fin'] ?? '');

        if (data['latitud'] != null && data['longitud'] != null) {
          _ubicacionSeleccionada = LatLng(
            (data['latitud'] as num).toDouble(),
            (data['longitud'] as num).toDouble(),
          );
        }
      }

      // Guardar todos los organizadores disponibles
      _organizadoresDisponibles = organizadoresDisponibles;

      // Guardar los IDs de los organizadores seleccionados para el evento
      _organizadoresSeleccionados =
          organizadoresEvento
              .map<int>((org) => org['id_usuario'] as int)
              .toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar el evento: $e')));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateEvent() async {
    if (_fechaInicio == null ||
        _fechaFin == null ||
        _ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos obligatorios.'),
        ),
      );
      return;
    }

    try {
      // 1. Actualizar datos del evento principal
      await supabase
          .from('eventos')
          .update({
            'nombre_evento': limpiarTexto(_nombreController),
            'descripcion': limpiarTexto(_descripcionController),
            'cupo_total': int.tryParse(_cupoController.text) ?? 0,
            'logo_url': limpiarTexto(_logoUrlController),
            'portada_url': limpiarTexto(_portadaUrlController),
            'fecha_inicio': _fechaInicio?.toIso8601String(),
            'fecha_fin': _fechaFin?.toIso8601String(),
            'estado': limpiarTexto(_estadoController),
            'municipio': limpiarTexto(_municipioController),
            'latitud': _ubicacionSeleccionada!.latitude,
            'longitud': _ubicacionSeleccionada!.longitude,
            'direccion': _direccionController.text.trim(),
          })
          .eq('id', widget.eventId);

      // 2. Eliminar organizadores actuales del evento
      await supabase
          .from('evento_organizador')
          .delete()
          .eq('id_evento', widget.eventId);

      // 3. Insertar nuevos organizadores seleccionados
      final nuevosOrganizadores =
          _organizadoresSeleccionados
              .map(
                (idUsuario) => {
                  'id_evento': widget.eventId,
                  'id_usuario': idUsuario,
                },
              )
              .toList();

      if (nuevosOrganizadores.isNotEmpty) {
        await supabase.from('evento_organizador').insert(nuevosOrganizadores);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento actualizado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _buscarDireccion() async {
    if (_direccionController.text.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(_direccionController.text)}.json?access_token=$_mapboxApiKey&limit=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'].isNotEmpty) {
          final coords = data['features'][0]['center']; // [long, lat]
          final latLng = LatLng(coords[1], coords[0]);

          setState(() => _ubicacionSeleccionada = latLng);
          await _abrirMapa(ubicacionInicial: latLng);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en la búsqueda: $e')));
    }
  }

  Future<void> _abrirMapa({LatLng? ubicacionInicial}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapaUbicacion(
              ubicacionInicial:
                  ubicacionInicial ??
                  _ubicacionSeleccionada ??
                  const LatLng(19.4326, -99.1332),
              apiKey: _mapboxApiKey,
            ),
      ),
    );

    if (result != null) {
      setState(() => _ubicacionSeleccionada = result);
      await _actualizarDireccionDesdeCoords(result);
    }
  }

  Future<void> _actualizarDireccionDesdeCoords(LatLng coords) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${coords.longitude},${coords.latitude}.json?access_token=$_mapboxApiKey&limit=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final direccion =
            data['features'][0]['place_name'] ?? 'Ubicación seleccionada';
        _direccionController.text = direccion;
      }
    } catch (e) {
      _direccionController.text =
          'Coordenadas: ${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          isInicio
              ? (_fechaInicio ?? DateTime.now())
              : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = selected;
        } else {
          _fechaFin = selected;
        }
      });
    }
  }

  Widget _buildDatePicker(String label, bool isInicio) {
    final selectedDate = isInicio ? _fechaInicio : _fechaFin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(isInicio: isInicio),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedDate != null
                      ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                      : 'Seleccionar fecha',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type ?? TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _buscarDireccion,
              ),
              IconButton(icon: const Icon(Icons.map), onPressed: _abrirMapa),
            ],
          ),
          if (_ubicacionSeleccionada != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Coordenadas: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(4)}, ${_ubicacionSeleccionada!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modificar datos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3966CC),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162A87), Colors.white],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        width: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar imagen o logo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _logoUrlController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'URL del logo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_logoUrlController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Image.network(
                                    _logoUrlController.text,
                                    height: 80,
                                    errorBuilder:
                                        (_, __, ___) => const Text(
                                          'No se pudo cargar la imagen',
                                        ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Agregar imagen de portada:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _portadaUrlController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'URL de portada',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_portadaUrlController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Image.network(
                                    _portadaUrlController.text,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Text(
                                          'No se pudo cargar la portada',
                                        ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),
                            _buildTextField(
                              'Nombre del evento',
                              _nombreController,
                            ),
                            _buildDatePicker('Fecha de inicio', true),
                            _buildDatePicker('Fecha de termino', false),
                            _buildTextField(
                              'Capacidad',
                              _cupoController,
                              type: TextInputType.number,
                            ),
                            _buildTextField(
                              'Descripción',
                              _descripcionController,
                              maxLines: 3,
                            ),
                            _buildTextField('Estado', _estadoController),
                            _buildTextField('Municipio', _municipioController),
                            _buildLocationField(),
                            const SizedBox(height: 10),
                            const Text(
                              'Organizadores:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Column(
                              children:
                                  _organizadoresDisponibles.map<Widget>((org) {
                                    final idUsuario =
                                        org['matricula']
                                            as int; // ID del usuario
                                    final nombre = org['nombre'] ?? '';
                                    final seleccionado =
                                        _organizadoresSeleccionados.contains(
                                          idUsuario,
                                        );

                                    return CheckboxListTile(
                                      title: Text(nombre),
                                      value: seleccionado,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _organizadoresSeleccionados.add(
                                              idUsuario,
                                            );
                                          } else {
                                            _organizadoresSeleccionados.remove(
                                              idUsuario,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),

                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _updateEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3966CC),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Actualizar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Volver',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cupoController.dispose();
    _logoUrlController.dispose();
    _portadaUrlController.dispose();
    _estadoController.dispose();
    _municipioController.dispose();
    _direccionController.dispose();
    super.dispose();
  }
}

class MapaUbicacion extends StatefulWidget {
  final LatLng ubicacionInicial;
  final String apiKey;

  const MapaUbicacion({
    required this.ubicacionInicial,
    required this.apiKey,
    Key? key,
  }) : super(key: key);

  @override
  State<MapaUbicacion> createState() => _MapaUbicacionState();
}

class _MapaUbicacionState extends State<MapaUbicacion> {
  late final MapController _mapController;
  LatLng? _ubicacionSeleccionada;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _ubicacionSeleccionada = widget.ubicacionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona la ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_ubicacionSeleccionada != null) {
                Navigator.pop(context, _ubicacionSeleccionada);
              }
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _ubicacionSeleccionada!,
          initialZoom: 15.0,
          onTap:
              (tapPosition, point) =>
                  setState(() => _ubicacionSeleccionada = point),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=${widget.apiKey}',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _ubicacionSeleccionada!,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
                width: 40,
                height: 40,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () {
          _mapController.move(
            _ubicacionSeleccionada!,
            _mapController.camera.zoom,
          );
        },
      ),
    );
  }
}
