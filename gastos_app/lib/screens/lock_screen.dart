import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Pantalla de bloqueo: pide huella / Face ID al abrir la app.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().desbloquear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint, size: 96, color: tema.colorScheme.primary),
                const SizedBox(height: 16),
                Text('App bloqueada', style: tema.textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (auth.error != null)
                  Text(auth.error!,
                      style: TextStyle(color: tema.colorScheme.error)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.read<AuthProvider>().desbloquear(),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Desbloquear'),
                ),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().cerrarSesion(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
