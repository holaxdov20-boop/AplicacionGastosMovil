import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';

/// Decide qué pantalla mostrar según el estado de autenticación y vuelve a
/// bloquear la app si estuvo más de 30 s en segundo plano.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  static const _tiempoParaBloquear = Duration(seconds: 30);
  DateTime? _enSegundoPlano;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _enSegundoPlano = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final desde = _enSegundoPlano;
      _enSegundoPlano = null;
      if (desde != null &&
          DateTime.now().difference(desde) > _tiempoParaBloquear) {
        context.read<AuthProvider>().bloquear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (context.watch<AuthProvider>().estado) {
      case AuthEstado.iniciando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthEstado.sinSesion:
        return const LoginScreen();
      case AuthEstado.bloqueado:
        return const LockScreen();
      case AuthEstado.autenticado:
        return const HomeScreen();
    }
  }
}
