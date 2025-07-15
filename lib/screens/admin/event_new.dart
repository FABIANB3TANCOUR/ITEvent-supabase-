import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NuevoEventoScreen extends StatefulWidget {
  const NuevoEventoScreen({super.key});

  @override
  State<NuevoEventoScreen> createState() => _NuevoEventoScreenState();
}

class _NuevoEventoScreenState extends State<NuevoEventoScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cupoController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _portadaUrlController = TextEditingController();
  final _estadoController = TextEditingController();
  final _municipioController = TextEditingController();
  final _direccionController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  LatLng? _ubicacionSeleccionada;

  List<Map<String, dynamic>> _organizadores = [];
  List<int> _organizadoresSeleccionados = [];

  bool _isLoading = true;

  static const String _mapboxApiKey = 'TU_API_KEY_MAPBOX';

  @override
  void initState() {
    super.initState();
    _cargarOrganizadores();
  }

  Future<void> _cargarOrganizadores() async {
    try {
      final response = await supabase
          .from('personal_eventos')
          .select('id, nombre')
          .eq('rol_id', 3);

      setState(() {
        _organizadores = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _mostrarError('Error al cargar organizadores: $e');
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => esInicio ? _fechaInicio = fecha : _fechaFin = fecha);
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
          final coords = data['features'][0]['center'];
          final latLng = LatLng(coords[1], coords[0]);

          setState(() => _ubicacionSeleccionada = latLng);
          await _abrirMapa(ubicacionInicial: latLng);
        }
      }
    } catch (e) {
      _mostrarError('Error en la búsqueda: $e');
    }
  }

  Future<void> _abrirMapa({LatLng? ubicacionInicial}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaUbicacion(
          ubicacionInicial: ubicacionInicial ?? _ubicacionSeleccionada ?? const LatLng(19.4326, -99.1332),
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
        final direccion = data['features'][0]['place_name'] ?? 'Ubicación seleccionada';
        _direccionController.text = direccion;
      }
    } catch (e) {
      _direccionController.text = 'Coordenadas: ${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null || _ubicacionSeleccionada == null) {
      _mostrarError('Completa todos los campos obligatorios');
      return;
    }
    if (_organizadoresSeleccionados.isEmpty) {
      _mostrarError('Debes seleccionar al menos un organizador');
      return;
    }

    try {
      final response = await supabase.from('eventos').insert({
        'nombre_evento': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'cupo_total': int.tryParse(_cupoController.text) ?? 0,
        'logo_url': _logoUrlController.text.trim(),
        'portada_url': _portadaUrlController.text.trim(),
        'fecha_inicio': _fechaInicio!.toIso8601String(),
        'fecha_fin': _fechaFin!.toIso8601String(),
        'estado': _estadoController.text.trim(),
        'municipio': _municipioController.text.trim(),
        'latitud': _ubicacionSeleccionada!.latitude,
        'longitud': _ubicacionSeleccionada!.longitude,
        'direccion': _direccionController.text.trim(),
      }).select().single();

      print('Respuesta insert evento: $response');

      // Cambia 'id' si tu tabla usa otro nombre para el campo PK
      final idEvento = response['id'] ?? response['id_evento'];

      if (idEvento == null) {
        _mostrarError('No se pudo obtener el ID del evento creado');
        return;
      }

      for (final idPersonal in _organizadoresSeleccionados) {
        await supabase.from('evento_personal').insert({
          'id_evento': idEvento,
          'id_personal': idPersonal,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Evento creado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $mensaje')),
    );
  }

  Widget _buildCheckboxesOrganizadores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Selecciona organizadores*', style: TextStyle(fontSize: 16)),
        ),
        ..._organizadores.map((org) {
          return CheckboxListTile(
            title: Text(org['nombre']),
            value: _organizadoresSeleccionados.contains(org['id']),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _organizadoresSeleccionados.add(org['id']);
                } else {
                  _organizadoresSeleccionados.remove(org['id']);
                }
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        _buildTextField('URL del logo (opcional)', _logoUrlController, esOpcional: true),
        if (_logoUrlController.text.isNotEmpty)
          Image.network(
            _logoUrlController.text,
            height: 80,
            errorBuilder: (_, __, ___) => _buildPlaceholder('Logo'),
          ),
        const SizedBox(height: 16),
        _buildTextField('URL de portada (opcional)', _portadaUrlController, esOpcional: true),
        if (_portadaUrlController.text.isNotEmpty)
          Image.network(
            _portadaUrlController.text,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder('Portada'),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool esOpcional = false, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: esOpcional ? null : (value) => value!.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? fecha, bool esInicio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _seleccionarFecha(esInicio),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                fecha != null
                    ? '${fecha.day}/${fecha.month}/${fecha.year}'
                    : 'Seleccionar fecha',
                style: TextStyle(color: fecha != null ? Colors.black : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubicación*', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar dirección',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _ubicacionSeleccionada == null ? 'Selecciona una ubicación' : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _buscarDireccion,
              ),
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: _abrirMapa,
              ),
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

  Widget _buildPlaceholder(String tipo) {
    return Container(
      color: Colors.grey[200],
      height: tipo == 'Logo' ? 80 : 120,
      child: Center(child: Text('Imagen de $tipo no disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Evento'),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    _buildTextField('Nombre del evento*', _nombreController),
                    _buildDateField('Fecha de inicio*', _fechaInicio, true),
                    _buildDateField('Fecha de término*', _fechaFin, false),
                    _buildTextField('Capacidad*', _cupoController, maxLines: 1),
                    _buildTextField('Descripción', _descripcionController, maxLines: 3),
                    _buildTextField('Estado*', _estadoController),
                    _buildTextField('Municipio*', _municipioController),
                    _buildLocationField(),
                    _buildCheckboxesOrganizadores(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _guardarEvento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('GUARDAR EVENTO', style: TextStyle(color: Colors.white)),
                    ),
                  ],
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
          onTap: (tapPosition, point) => setState(() => _ubicacionSeleccionada = point),
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
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
          _mapController.move(_ubicacionSeleccionada!, _mapController.camera.zoom);
        },
      ),
    );
  }
}
