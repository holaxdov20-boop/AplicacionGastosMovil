import 'package:supabase_flutter/supabase_flutter.dart';

/// Envoltorio de Supabase Auth (correo + contraseña).
class AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Session? get sesion => _auth.currentSession;

  Future<void> iniciarSesion(String email, String password) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Devuelve true si ya quedó con sesión; false si Supabase exige confirmar
  /// el correo antes de iniciar sesión.
  Future<bool> registrar(String email, String password) async {
    final r = await _auth.signUp(email: email.trim(), password: password);
    return r.session != null;
  }

  /// Cierra la sesión solo localmente (no requiere red).
  Future<void> cerrarSesion() => _auth.signOut(scope: SignOutScope.local);
}
