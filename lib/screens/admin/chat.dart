import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final int? adminId;
  final int? remitenteId;
  final int? destinatarioId;

  const ChatPage({
    super.key,
    this.adminId,
    this.remitenteId,
    this.destinatarioId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // AQUÍ

  List<Map<String, dynamic>> _mensajes = [];
  Map<int, String> _nombresUsuarios = {};
  RealtimeChannel? _canalMensajes;

  bool get soyAdmin => widget.adminId != null && widget.remitenteId == null;

  int get idYo {
    if (soyAdmin) return widget.adminId!;
    return widget.remitenteId!;
  }

  int get idOtro {
    if (soyAdmin) return widget.destinatarioId!;
    return widget.adminId ?? widget.destinatarioId!;
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _cargarMensajes();
    _escucharMensajes();
  }

  @override
  void dispose() {
    _canalMensajes?.unsubscribe(); // Cancela la suscripción Realtime
    _mensajeController.dispose(); // Libera el TextEditingController
    _scrollController.dispose(); // Libera el ScrollController
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    final data = await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido')
        .eq('matricula', idOtro);

    final Map<int, String> nombres = {};
    for (final u in data) {
      final id = u['matricula'] as int;
      final nombreCompleto = '${u['nombre']} ${u['apellido']}';
      nombres[id] = nombreCompleto;
    }

    setState(() {
      _nombresUsuarios = nombres;
    });
  }

  Future<void> _cargarMensajes() async {
    final data = await supabase
        .from('mensajes')
        .select()
        .order('fecha_envio', ascending: true);
    ;

    setState(() {
      _mensajes =
          data.where((m) {
            if (soyAdmin) {
              return (m['admin_id'] == idYo &&
                      m['destinatario_id'] == idOtro) ||
                  (m['remitente_id'] == idOtro && m['admin_id'] == idYo);
            } else if (widget.adminId != null) {
              return (m['remitente_id'] == idYo && m['admin_id'] == idOtro) ||
                  (m['admin_id'] == idOtro && m['destinatario_id'] == idYo);
            } else {
              return (m['remitente_id'] == idYo &&
                      m['destinatario_id'] == idOtro) ||
                  (m['remitente_id'] == idOtro && m['destinatario_id'] == idYo);
            }
          }).toList();
    });
  }

  void _escucharMensajes() {
    _canalMensajes = supabase.channel('mensajes_realtime');

    _canalMensajes!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (payload) {
            final nuevo = payload.newRecord;

            final valido =
                soyAdmin
                    ? (nuevo['admin_id'] == idYo &&
                            nuevo['destinatario_id'] == idOtro) ||
                        (nuevo['remitente_id'] == idOtro &&
                            nuevo['admin_id'] == idYo)
                    : widget.adminId != null
                    ? (nuevo['remitente_id'] == idYo &&
                            nuevo['admin_id'] == idOtro) ||
                        (nuevo['admin_id'] == idOtro &&
                            nuevo['destinatario_id'] == idYo)
                    : (nuevo['remitente_id'] == idYo &&
                            nuevo['destinatario_id'] == idOtro) ||
                        (nuevo['remitente_id'] == idOtro &&
                            nuevo['destinatario_id'] == idYo);

            if (!valido || _mensajes.any((m) => m['id'] == nuevo['id'])) return;

            setState(() {
              _mensajes.add(nuevo);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          },
        )
        .subscribe();
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    Map<String, dynamic> nuevoMensaje;

    if (soyAdmin) {
      nuevoMensaje = {
        'admin_id': idYo,
        'destinatario_id': idOtro,
        'contenido': texto,
      };
    } else if (widget.adminId != null) {
      nuevoMensaje = {
        'remitente_id': idYo,
        'admin_id': idOtro,
        'contenido': texto,
      };
    } else {
      nuevoMensaje = {
        'remitente_id': idYo,
        'destinatario_id': idOtro,
        'contenido': texto,
      };
    }

    await supabase.from('mensajes').insert(nuevoMensaje);
    _mensajeController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nombresUsuarios[idOtro] ?? 'Chat'),
        backgroundColor: const Color(0xFF3966CC),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,

              padding: const EdgeInsets.all(12),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final msg = _mensajes[index];
                final bool esMio =
                    soyAdmin
                        ? msg['admin_id'] == idYo
                        : msg['remitente_id'] == idYo;

                final String nombre =
                    esMio
                        ? 'Yo'
                        : (_nombresUsuarios[msg['remitente_id']] ?? 'Admin');

                return Align(
                  alignment:
                      esMio ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                        esMio
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              esMio
                                  ? const Color(0xFF3966CC)
                                  : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['contenido'],
                          style: TextStyle(
                            color: esMio ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3966CC)),
                  onPressed: _enviarMensaje,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
