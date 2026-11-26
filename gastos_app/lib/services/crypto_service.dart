import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cifrado AES-256-GCM de datos sensibles (descripción de los gastos).
///
/// * La clave de 256 bits se genera una sola vez con un generador seguro y se
///   guarda en Keystore (Android) / Keychain (iOS) vía flutter_secure_storage.
/// * Cada valor usa un IV aleatorio de 12 bytes; el resultado se guarda como
///   `iv_base64:cifrado_base64`. GCM además autentica el contenido, por lo que
///   cualquier alteración se detecta al descifrar.
class CryptoService {
  CryptoService([FlutterSecureStorage? almacenamiento])
      : _almacenamiento = almacenamiento ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _nombreClave = 'aes_key_v1';
  static const mensajeNoDisponible = '[contenido no disponible en este dispositivo]';

  final FlutterSecureStorage _almacenamiento;
  Encrypter? _cifrador;

  Future<Encrypter> _obtenerCifrador() async {
    final existente = _cifrador;
    if (existente != null) return existente;

    var claveB64 = await _almacenamiento.read(key: _nombreClave);
    if (claveB64 == null) {
      claveB64 = Key.fromSecureRandom(32).base64;
      await _almacenamiento.write(key: _nombreClave, value: claveB64);
    }
    return _cifrador =
        Encrypter(AES(Key.fromBase64(claveB64), mode: AESMode.gcm));
  }

  Future<String> cifrar(String textoPlano) async {
    if (textoPlano.isEmpty) return '';
    final cifrador = await _obtenerCifrador();
    final iv = IV.fromSecureRandom(12);
    final cifrado = cifrador.encrypt(textoPlano, iv: iv);
    return '${iv.base64}:${cifrado.base64}';
  }

  Future<String> descifrar(String almacenado) async {
    if (almacenado.isEmpty) return '';
    try {
      final partes = almacenado.split(':');
      if (partes.length != 2) return mensajeNoDisponible;
      final cifrador = await _obtenerCifrador();
      return cifrador.decrypt(
        Encrypted.fromBase64(partes[1]),
        iv: IV.fromBase64(partes[0]),
      );
    } catch (_) {
      // Clave distinta (otro dispositivo) o dato alterado.
      return mensajeNoDisponible;
    }
  }
}
