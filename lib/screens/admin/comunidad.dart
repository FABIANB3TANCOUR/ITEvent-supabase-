import 'package:flutter/material.dart';
import 'package:itevent/screens/admin/asistente_nuevo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigator.dart';
import 'perfil.dart';
import 'perfil_asistente.dart'; // Asegúrate de que acepte userId

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _fetchUsuarios() async {
    return await supabase
        .from('usuarios')
        .select('matricula, nombre, apellido, roles(nombre)')
        .order('nombre');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Comunidad',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Filtros (aún sin lógica, solo UI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(label: const Text('Todo'), onSelected: (_) {}),
                FilterChip(
                  label: const Text('Recomendado'),
                  onSelected: (_) {},
                ),
                FilterChip(label: const Text('Rol'), onSelected: (_) {}),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchUsuarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error.toString()}'),
                  );
                }
                final usuarios = snapshot.data ?? [];
                if (usuarios.isEmpty) {
                  return const Center(child: Text('No hay usuarios.'));
                }
                return ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final u = usuarios[index];
                    final String nombreCompleto =
                        '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}';
                    return _PersonaCard(
                      name: nombreCompleto.trim(),
                      role: u['roles']?['nombre'] ?? 'Sin rol',
                      matricula: u['matricula'] as int,
                      imgur: u['foto_url'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevoUsuarioScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => navigateToPage(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Asistentes'),
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

class _PersonaCard extends StatelessWidget {
  final String name;
  final String role;
  final int matricula;
  final String? imgur; // <- IMPORTANTE: tipo nullable

  const _PersonaCard({
    required this.name,
    required this.role,
    required this.matricula,
    this.imgur, // <- debe coincidir con el tipo nullable
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 40,
          backgroundImage:
              (imgur != null && imgur!.isNotEmpty)
                  ? NetworkImage(imgur!)
                  : null,
          child:
              (imgur == null || imgur!.isEmpty)
                  ? const Icon(Icons.person, size: 40)
                  : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilUsuarioPage(matricula: matricula),
              ),
            ),
      ),
    );
  }
}
