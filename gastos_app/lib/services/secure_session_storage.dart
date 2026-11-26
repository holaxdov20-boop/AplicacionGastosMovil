import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guarda la sesión de Supabase (access + refresh token) en Keystore/Keychain
/// en lugar de SharedPreferences (texto plano).
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage()
      : super(
          initialize: () async {},
          hasAccessToken: () => _almacen.containsKey(key: _clave),
          accessToken: () => _almacen.read(key: _clave),
          removePersistedSession: () => _almacen.delete(key: _clave),
          persistSession: (sesion) =>
              _almacen.write(key: _clave, value: sesion),
        );

  static const _clave = 'supabase_session';
  static const _almacen = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}
