import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilInvitadoPage extends StatefulWidget {
  final String uuid;

  const PerfilInvitadoPage({super.key, required this.uuid});

  @override
  State<PerfilInvitadoPage> createState() => _PerfilInvitadoPageState();
}

class _PerfilInvitadoPageState extends State<PerfilInvitadoPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? invitadoData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosInvitado();
  }

  Future<void> _cargarDatosInvitado() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('usuarios')
          .select()
          .eq('uuid_usuario', widget.uuid)
          .maybeSingle();

      setState(() {
        invitadoData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del invitado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (invitadoData == null) {
      return Scaffold(
        body: Center(child: Text('No se encontraron datos del invitado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Invitado'),
        backgroundColor: Colors.blue[900],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    invitadoData?['foto_url'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    invitadoData?['nombre'] ?? 'Nombre no disponible',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(invitadoData?['descripcion'] ?? 'Sin descripción'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
