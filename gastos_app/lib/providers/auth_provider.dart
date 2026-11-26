import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_database.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

enum AuthEstado { iniciando, sinSesion, bloqueado, autenticado }

/// Estado de autenticación: login con Supabase + bloqueo biométrico.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._biometria);

  final AuthService _auth;
  final BiometricService _biometria;

  AuthEstado estado = AuthEstado.iniciando;
  bool cargando = false;
  String? error;
  String? info;

  bool _biometriaDisponible = false;

  // Límite de intentos fallidos (mitiga fuerza bruta desde la app).
  static const _maxIntentos = 5;
  static const _penalizacion = Duration(seconds: 30);
  int _intentos = 0;
  DateTime? _bloqueadoHasta;

  Future<void> iniciar() async {
    _biometriaDisponible = await _biometria.disponible();
    if (_auth.sesion == null) {
      estado = AuthEstado.sinSesion;
    } else {
      estado = _biometriaDisponible
          ? AuthEstado.bloqueado
          : AuthEstado.autenticado;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------- biometría
  Future<void> desbloquear() async {
    final ok = await _biometria.autenticar();
    if (ok) {
      estado = AuthEstado.autenticado;
      error = null;
    } else {
      error = 'No se pudo verificar tu identidad.';
    }
    notifyListeners();
  }

  /// Vuelve a pedir biometría (p. ej. tras un rato en segundo plano).
  void bloquear() {
    if (estado == AuthEstado.autenticado && _biometriaDisponible) {
      estado = AuthEstado.bloqueado;
      error = null;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------- login
  Future<void> iniciarSesion(String email, String password) =>
      _autenticar(() async {
        await _auth.iniciarSesion(email, password);
        return true;
      });

  Future<void> registrar(String email, String password) =>
      _autenticar(() async {
        final conSesion = await _auth.registrar(email, password);
        if (!conSesion) {
          info = 'Te enviamos un correo para confirmar tu cuenta. '
              'Después inicia sesión.';
        }
        return conSesion;
      });

  Future<void> _autenticar(Future<bool> Function() accion) async {
    final espera = _segundosDeEspera;
    if (espera > 0) {
      error = 'Demasiados intentos. Espera $espera s.';
      notifyListeners();
      return;
    }

    cargando = true;
    error = null;
    info = null;
    notifyListeners();
    try {
      if (await accion()) {
        _intentos = 0;
        estado = AuthEstado.autenticado;
      }
    } on AuthException catch (e) {
      _registrarFallo();
      error = _traducir(e.message);
    } on SocketException {
      error = 'Sin conexión a internet.';
    } catch (e) {
      debugPrint('Auth: $e');
      error = 'No se pudo completar la operación.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await _auth.cerrarSesion();
    } catch (e) {
      debugPrint('Auth signOut: $e');
    }
    // Borra los datos locales para que otra cuenta no los vea.
    await AppDatabase.instance.limpiar();
    estado = AuthEstado.sinSesion;
    error = null;
    info = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ helpers
  int get _segundosDeEspera {
    final hasta = _bloqueadoHasta;
    if (hasta == null) return 0;
    final restante = hasta.difference(DateTime.now()).inSeconds;
    if (restante <= 0) {
      _bloqueadoHasta = null;
      _intentos = 0;
      return 0;
    }
    return restante;
  }

  void _registrarFallo() {
    _intentos++;
    if (_intentos >= _maxIntentos) {
      _bloqueadoHasta = DateTime.now().add(_penalizacion);
    }
  }

  String _traducir(String mensaje) {
    final m = mensaje.toLowerCase();
    if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
    if (m.contains('already registered')) {
      return 'Ese correo ya está registrado.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    return 'No se pudo autenticar. Verifica tus datos.';
  }
}
