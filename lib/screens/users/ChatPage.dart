import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final int destinatarioId;

  const ChatPage({
    super.key,
    required this.userId,
    required this.destinatarioId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _mensajeController = TextEditingController();
  List<Map<String, dynamic>> _mensajes = [];
  String _nombreDestinatario = '';
  String? _fotoDestinatario;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosChat();
    _setupRealtimeSubscription();
  }

  Future<void> _cargarDatosChat() async {
    try {
      // Obtener información del destinatario
      final destinatarioData = await supabase
          .from('usuarios')
          .select('nombre, apellido, foto_url')
          .eq('matricula', widget.destinatarioId)
          .single();

      // Obtener historial de mensajes
      final mensajesData = await supabase
          .from('mensajes')
          .select()
          .or('and(remitente_id.eq.${widget.userId},destinatario_id.eq.${widget.destinatarioId}),and(remitente_id.eq.${widget.destinatarioId},destinatario_id.eq.${widget.userId})')
          .order('fecha_envio', ascending: false);

      setState(() {
        _nombreDestinatario = '${destinatarioData['nombre']} ${destinatarioData['apellido']}';
        _fotoDestinatario = destinatarioData['foto_url'];
        _mensajes = List<Map<String, dynamic>>.from(mensajesData);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el chat: $e')),
      );
    }
  }

  void _setupRealtimeSubscription() {
    supabase
        .channel('chat_${widget.userId}_${widget.destinatarioId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (payload) {
            final nuevoMensaje = payload.newRecord;
            if ((nuevoMensaje['remitente_id'] == widget.userId && 
                 nuevoMensaje['destinatario_id'] == widget.destinatarioId) ||
                (nuevoMensaje['remitente_id'] == widget.destinatarioId && 
                 nuevoMensaje['destinatario_id'] == widget.userId)) {
              setState(() {
                _mensajes.insert(0, nuevoMensaje);
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _enviarMensaje() async {
    final contenido = _mensajeController.text.trim();
    if (contenido.isEmpty) return;

    try {
      await supabase.from('mensajes').insert({
        'remitente_id': widget.userId,
        'destinatario_id': widget.destinatarioId,
        'contenido': contenido,
      });

      _mensajeController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _fotoDestinatario != null 
                  ? NetworkImage(_fotoDestinatario!)
                  : null,
              child: _fotoDestinatario == null 
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(_nombreDestinatario),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = _mensajes[index];
                      final esMio = mensaje['remitente_id'] == widget.userId;
                      
                      return Align(
                        alignment: esMio 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esMio ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            mensaje['contenido'] as String,
                            style: TextStyle(
                              color: esMio ? Colors.blue[900] : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mensajeController,
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onSubmitted: (_) => _enviarMensaje(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
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


