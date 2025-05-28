import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'modif_perfil.dart';

class PerfilPropioStaff extends StatelessWidget {
  const PerfilPropioStaff({super.key});

  Future<int?> obtenerOrganizadorId() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('organizadores')
        .select('id')
        .eq('uuid_usuario', user.id)
        .maybeSingle();

    return response?['id'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            title: const Text(
              'Mi perfil (Staff)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final organizadorId = await obtenerOrganizadorId();
                if (organizadorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se encontró el ID del organizador')),
                  );
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModifPerfil(
                      adminId: organizadorId,
                      rol: 'staff',
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Aquí puedes mostrar más datos del perfil del staff...'),
          ),
        ],
      ),
    );
  }
}
