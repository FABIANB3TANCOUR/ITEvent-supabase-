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

  // Variables de estado
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  LatLng? _ubicacionSeleccionada;
  List<Map<String, dynamic>> _organizadores = [];
  int? _organizadorSeleccionado;
  bool _isLoading = true;

  // Mapbox
  static const String _mapboxApiKey = 'TU_API_KEY_MAPBOX';

  @override
  void initState() {
    super.initState();
    _cargarOrganizadores();
  }

  Future<void> _cargarOrganizadores() async {
    try {
      final response = await supabase.from('organizadores').select('id, nombre');
      setState(() {
        _organizadores = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _mostrarError('Error al cargar organizadores: $e');
    }
  }

  // --- Funciones para fechas ---
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

  // --- Funciones para Mapbox ---
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

  // --- Guardado en Supabase ---
  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null || _ubicacionSeleccionada == null) {
      _mostrarError('Completa todos los campos obligatorios');
      return;
    }

    try {
      await supabase.from('eventos').insert({
        'nombre_evento': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'cupo_total': int.tryParse(_cupoController.text) ?? 0,
        'logo_url': _logoUrlController.text.trim(),
        'portada_url': _portadaUrlController.text.trim(),
        'fecha_inicio': _fechaInicio!.toIso8601String(),
        'fecha_fin': _fechaFin!.toIso8601String(),
        'estado': _estadoController.text.trim(),
        'municipio': _municipioController.text.trim(),
        'organizador_id': _organizadorSeleccionado,
        'latitud': _ubicacionSeleccionada!.latitude,
        'longitud': _ubicacionSeleccionada!.longitude,
        'direccion': _direccionController.text.trim(),
      });

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

  // --- Widgets ---
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

  Widget _buildOrganizadorDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: _organizadorSeleccionado,
        hint: const Text('Selecciona un organizador*'),
        items: _organizadores.map((org) {
          return DropdownMenuItem<int>(
            value: org['id'] as int,
            child: Text(org['nombre'].toString()),
          );
        }).toList(),
        onChanged: (int? value) => setState(() => _organizadorSeleccionado = value),
        decoration: const InputDecoration(border: OutlineInputBorder()),
        validator: (value) => value == null ? 'Selecciona un organizador' : null,
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
                    _buildTextField('Estado*', _estadoController, maxLines: 1),
                    _buildTextField('Municipio*', _municipioController, maxLines: 1),
                    _buildLocationField(),
                    _buildOrganizadorDropdown(),
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

// -------------------- PANTALLA DEL MAPA (Versión actualizada) --------------------
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
            urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=${widget.apiKey}',
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