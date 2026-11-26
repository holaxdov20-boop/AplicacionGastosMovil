import 'package:flutter/material.dart';

/// Pantalla que se muestra si la app se ejecutó sin las variables de entorno.
class ConfigFaltante extends StatelessWidget {
  const ConfigFaltante({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Falta la configuración de Supabase.\n\n'
              'Crea env.json a partir de env.example.json y ejecuta:\n\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
