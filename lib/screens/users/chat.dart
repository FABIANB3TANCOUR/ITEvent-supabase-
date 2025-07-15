import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _mensajes = [];
  Map<int, String> _nombresUsuarios = {};
  RealtimeChannel? _canalMensajes;

  final List<String> _palabrasProhibidas = [
    'tonto',
    'menso',
    'pendejo',
    'idiota',
    'estupido',
    'mierda',
    'verga',
    'estupida',
    'imbecil',
    'tarado',
    'puto',
    'puta',
    'pito',
    'chinga',
    'chingada',
    'vrg',
    'maldita',
    'perra',
    'maldito',
    'culero',
    'culera',
    'culo',
    'zorra',
    'pinche',
    'puñetas',
    'maricon',
    'joto',
  ];

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
    _canalMensajes?.unsubscribe();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _censurarTexto(String? texto) {
    if (texto == null) return '';
    String resultado = texto;
    for (final palabra in _palabrasProhibidas) {
      final regex = RegExp(
        r'\b' + RegExp.escape(palabra) + r'\b',
        caseSensitive: false,
      );
      resultado = resultado.replaceAllMapped(
        regex,
        (match) => '*' * match.group(0)!.length,
      );
    }
    return resultado;
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
  final textoOriginal = _mensajeController.text.trim();
  if (textoOriginal.isEmpty) return;

  final textoCensurado = _censurarTexto(textoOriginal);

  final nuevoMensaje = {
    'remitente_id': idYo,
    'destinatario_id': idOtro,
    'contenido': textoCensurado,
  };

  try {
    await supabase.from('mensajes').insert(nuevoMensaje);
    _mensajeController.clear();

    // 🔄 1. Obtener nombre del remitente
    final remitenteData = await supabase
        .from('usuarios')
        .select('nombre, apellido')
        .eq('matricula', idYo)
        .single();

    final nombreRemitente = '${remitenteData['nombre']} ${remitenteData['apellido']}';

    // 🔄 2. Obtener email del destinatario
    final destinatarioData = await supabase
        .from('usuarios')
        .select('email')
        .eq('matricula', idOtro)
        .single();

    final emailDestinatario = destinatarioData['email'];

    // 🔄 3. Llamar a función edge de Deno para enviar correo
    final response = await supabase.functions.invoke('send-email', body: {
      'to': [emailDestinatario],
      'subject': 'Nuevo mensaje en la app',
      'html': '<strong>Te ha llegado un mensaje de $nombreRemitente.</strong>',
    });

    if (response.status != 200) {
      debugPrint('❌ Error al enviar correo: ${response.data}');
    }

    // 🔄 4. Auto scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  } catch (e) {
    debugPrint('Error al enviar mensaje o correo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar mensaje o notificación')),
    );
  }
}


  Future<void> _seleccionarImagen() async {
    try {
      Uint8List? bytes;
      String? filename;

      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null ||
            result.files.isEmpty ||
            result.files.first.bytes == null) {
          debugPrint('No se seleccionó imagen o está vacía.');
          return;
        }

        bytes = result.files.first.bytes!;
        filename =
            'chat_${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          debugPrint('No se seleccionó imagen de la galería.');
          return;
        }

        bytes = await picked.readAsBytes();
        filename =
            'chat_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      }

      if (bytes.isEmpty) {
        debugPrint('Los bytes de la imagen están vacíos.');
        return;
      }

      debugPrint('Subiendo imagen como: $filename');

      await supabase.storage
          .from('imagenes')
          .uploadBinary(
            filename,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage
          .from('imagenes')
          .getPublicUrl(filename);
      debugPrint('Imagen subida correctamente: $publicUrl');

      await _enviarImagen(publicUrl);
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    }
  }

  Future<void> _enviarImagen(String url) async {
    final nuevoMensaje = {
      'remitente_id': idYo,
      'destinatario_id': idOtro,
      'imagen_url': url,
      'contenido': null, // evitar null para cumplir NOT NULL
    };
    await supabase.from('mensajes').insert(nuevoMensaje);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nombresUsuarios[idOtro] ?? 'Chat'),
        backgroundColor: Colors.blue,
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
                      if (msg['contenido'] != null)
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
                            _censurarTexto(msg['contenido']),
                            style: TextStyle(
                              color: esMio ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      if (msg['imagen_url'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              msg['imagen_url'],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder:
                                  (context, error, stackTrace) => const Text(
                                    'Error al cargar la imagen',
                                    style: TextStyle(color: Colors.black),
                                  ),
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
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.green),
                  onPressed: _seleccionarImagen,
                ),
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
