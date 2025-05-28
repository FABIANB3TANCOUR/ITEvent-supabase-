import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'perfil_asistente.dart';
import 'perfil_invitado.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> participantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarParticipantes();
  }

  Future<void> _cargarParticipantes() async {
    setState(() => _isLoading = true);

    try {
      // Obtener usuarios cuyo rol no sea 'Administrador'
      final List<dynamic> data = await supabase
          .from('usuarios')
          .select()
          .neq('rol', 'Administrador')
          .order('nombre')
          .limit(100);

      setState(() {
        participantes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar participantes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        leading: GestureDetector(
          onTap: () {
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PerfilUsuarioPage(userId: currentUser.id)),
              );
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Participantes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : participantes.isEmpty
              ? const Center(child: Text('No hay participantes disponibles.'))
              : ListView.builder(
                  itemCount: participantes.length,
                  itemBuilder: (context, index) {
                    final user = participantes[index];
                    return PersonaCard(
                      id: user['id'].toString(),
                      name: user['nombre'] ?? 'Sin nombre',
                      role: user['rol'] ?? 'Sin rol',
                      location: user['ubicacion'] ?? 'Sin ubicación',
                      image: user['imagen_url'] ?? 'https://via.placeholder.com/150',
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // participantes
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Aquí deberías implementar la navegación adecuada,
          // según tu lógica de MainNavigatorInvitado o similar
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Participantes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificación',
          ),
        ],
      ),
    );
  }
}

class PersonaCard extends StatelessWidget {
  final String id;
  final String name;
  final String role;
  final String location;
  final String image;

  const PersonaCard({
    super.key,
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(image), radius: 25),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$role\n$location'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (role.toLowerCase() == 'staff') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PerfilUsuarioPage(userId: id)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PerfilInvitadoPage(uuid: id)),
            );
          }
        },
      ),
    );
  }
}
