import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class PerfilUsuarioPage extends StatefulWidget {
  final String userId;

  const PerfilUsuarioPage({super.key, required this.userId});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() => _isLoading = true);

    try {
      final data = await supabase
          .from('usuarios')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      setState(() {
        userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  void navegarStaff(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/eventlist');
        break;
      case 1:
        Navigator.pushNamed(context, '/agendas');
        break;
      case 2:
        Navigator.pushNamed(context, '/comunidad');
        break;
      case 3:
        Navigator.pushNamed(context, '/mensajes');
        break;
      case 4:
        Navigator.pushNamed(context, '/notificaciones');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No se encontraron datos del usuario.',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => navegarStaff(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Asistentes'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificación'),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue[900],
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                userData?['nombre'] ?? 'Nombre no disponible',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userData?['imagen_url'] != null && userData!['imagen_url'].isNotEmpty
                      ? NetworkImage(userData!['imagen_url'])
                      : null,
                  child: userData?['imagen_url'] == null || userData!['imagen_url'].isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?['nombre'] ?? 'Nombre no disponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userData?['rol'] ?? 'Rol no disponible'}\n${userData?['institucion'] ?? ''}\n${userData?['ubicacion'] ?? ''}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: const [
                    Icon(Icons.mail_outline, color: Colors.white),
                    SizedBox(height: 4),
                    Text(
                      'Mensaje',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas Personales',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(userData?['notas_personales'] ?? 'Escribe Notas'),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contacto',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantente en contacto con ${userData?['nombre'] ?? 'el usuario'} intercambiando información de contacto',
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      // Acción para contactar al usuario
                    },
                    child: const Text(
                      'Contactar información',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
