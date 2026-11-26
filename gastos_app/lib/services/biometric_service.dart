import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Huella dactilar / Face ID mediante local_auth.
/// Si el dispositivo no tiene biometría ni bloqueo de pantalla configurado,
/// [disponible] es false y la app omite el bloqueo.
class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifica tu identidad para abrir Mis Gastos',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }
}
