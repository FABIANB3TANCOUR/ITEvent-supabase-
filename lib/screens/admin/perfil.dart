import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modif_perfil.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<int?> obtenerAdminId() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // Consulta para obtener adminId basado en user.id (UUID)
    final response = await supabase
        .from('administradores')
        .select('id')
        .eq('uuid_usuario', user.id) // suponer que hay campo uuid_usuario
        .maybeSingle();

    if (response != null && response['id'] != null) {
      return response['id'] as int;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... tu UI previa
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            title: const Text(
              'Mi perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final adminId = await obtenerAdminId();
                if (adminId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se encontró el ID del admin')),
                  );
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ModifPerfil(adminId: adminId)),
                );
              },
            ),
          ),
          // resto de widgets...
        ],
      ),
    );
  }
}
