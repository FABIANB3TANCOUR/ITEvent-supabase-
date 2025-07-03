import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:itevent/screens/users/agenda_detail.dart';
import 'package:itevent/screens/users/main.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itevent/services/email_services.dart';

class EventDetailUser extends StatefulWidget {
  final int eventId;

  const EventDetailUser({super.key, required this.eventId});

  @override
  State<EventDetailUser> createState() => _EventDetailUserState();
}

class _EventDetailUserState extends State<EventDetailUser> {
  final supabase = Supabase.instance.client;
  final emailService = EmailService('https://bsiepzgutwsmbeftyrdd.supabase.co/functions/v1/notificaciones');

  static const String _mapboxApiKey = 'pk.eyJ1IjoidGhlbWFtaXRhczQzIiwiYSI6ImNtYmlpZWV0ZzA2MWUybXB6NDk4eGU3ZDIifQ.g2P3tNXrG58VBYiOL8Ob1Q';

  Map<String, dynamic>? event;
  bool _isLoading = true;
  String localidad = '';
  int? matricula;
  bool yaRegistrado = false;
  LatLng? _ubicacionEvento;

  @override
  void initState() {
    super.initState();
    _loadUserAndEventDetail();
  }

  Future<void> _loadUserAndEventDetail() async {
    final prefs = await SharedPreferences.getInstance();
    matricula = prefs.getInt('matricula');
    await _loadEventDetail();
    if (matricula != null) await _verificarRegistro();
  }

  Future<void> _loadEventDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('eventos')
          .select('''
            id,
            nombre_evento,
            cupo_total,
            fecha_inicio,
            fecha_fin,
            portada_url,
            created_at,
            descripcion,
            estado,
            municipio,
            direccion,
            latitud,
            longitud,
            organizadores ( nombre )
          ''')
          .eq('id', widget.eventId)
          .maybeSingle();

      setState(() {
        event = data;
        _isLoading = false;
        
        if (data != null && data['latitud'] != null && data['longitud'] != null) {
          _ubicacionEvento = LatLng(
            (data['latitud'] as num).toDouble(),
            (data['longitud'] as num).toDouble(),
          );
        }
      });
      
      if (event?['municipio'] != null && event?['estado'] != null) {
        localidad = '${event!['municipio']}, ${event!['estado']}';
      } else {
        localidad = 'Ubicación no disponible';
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el evento: $e')));
      }
    }
  }

  Future<void> _verificarRegistro() async {
    if (matricula == null) return;

    final result = await supabase
        .from('registros')
        .select()
        .eq('matricula', matricula!)
        .eq('id_evento', widget.eventId)
        .maybeSingle();

    setState(() {
      yaRegistrado = result != null;
    });
  }

  Future<void> _registrarse() async {
   if (matricula == null) return;

  try {
    // Insertar el registro en la tabla
    await supabase.from('registros').insert({
      'matricula': matricula,
      'id_evento': widget.eventId,
    });

    // Obtener correo del usuario
    final userData = await supabase
        .from('usuarios')
        .select('correo, nombre')
        .eq('matricula', matricula!)
        .maybeSingle();

    final correo = userData?['correo'];
    final nombre = userData?['nombre'];
    final nombreEvento = event?['nombre_evento'] ?? 'Evento';

    // Enviar correo solo si hay correo válido
    if (correo != null && correo.contains('@')) {
      final enviado = await emailService.sendEmail(
        to: correo,
        subject: 'Registro confirmado a "$nombreEvento"',
        htmlContent: '''
          <p>Hola $nombre 👋</p>
          <p>Te has registrado exitosamente al evento: <strong>$nombreEvento</strong>.</p>
          <p>¡Gracias por usar nuestra app!</p>
        ''',
      );

      if (!enviado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso, pero error al enviar correo.')),
        );
      }
    }

    // Mostrar mensaje y navegar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso al evento')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EventScreen()),
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    }
  }
  }

  Widget _buildMapaUbicacion() {
    if (_ubicacionEvento == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Ubicación no disponible'),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _ubicacionEvento!,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$_mapboxApiKey',
              userAgentPackageName: 'com.example.itevent',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: _ubicacionEvento!,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Eventos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Evento no encontrado'))
              : ListView(
                  children: [
                    if (event?['portada_url'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                        child: Image.network(
                          event!['portada_url'],
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event?['nombre_evento'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localidad,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            _formatearFecha(event?['fecha_fin'] ?? ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          _seccionTitulo('Sobre el evento'),
                          const SizedBox(height: 12),
                          _infoCard([
                            _infoText('Descripción', event?['descripcion']),
                            _infoText(
                              'Organizador',
                              event?['organizadores']?['nombre'],
                            ),
                            _infoText(
                              'Cupo total',
                              event?['cupo_total']?.toString(),
                            ),
                            _infoText(
                              'Fecha de inicio',
                              _formatearFecha(event?['fecha_inicio'] ?? ''),
                            ),
                            _infoText(
                              'Fecha de fin',
                              _formatearFecha(event?['fecha_fin'] ?? ''),
                            ),
                            _infoText(
                              'Creado en',
                              _formatearFecha(event?['created_at'] ?? ''),
                            ),
                          ]),
                          
                          // Sección de ubicación con mapa
                          const SizedBox(height: 25),
                          _seccionTitulo('Ubicación del evento'),
                          const SizedBox(height: 12),
                          if (event?['direccion'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                event!['direccion'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          _buildMapaUbicacion(),
                          
                          const SizedBox(height: 25),
                          _actionButton('Ver actividades', Colors.blue, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AgendaEventoScreen(
                                  idEvento: widget.eventId,
                                ),
                              ),
                            );
                          }),
                          if (!yaRegistrado)
                            _actionButton(
                              'Registrarme al evento',
                              Colors.green,
                              _registrarse,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatearFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return '${fecha.day.toString().padLeft(2, '0')} ${_mesNombre(fecha.month)}, ${fecha.year}';
    } catch (_) {
      return fechaISO;
    }
  }

  String _mesNombre(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _actionButton(
    String texto,
    Color color,
    VoidCallback onPressed, {
    Color colorTexto = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: colorTexto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        child: Text(texto),
      ),
    );
  }
}