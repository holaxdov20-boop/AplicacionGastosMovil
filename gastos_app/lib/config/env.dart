/// Configuración inyectada en tiempo de compilación, NUNCA en el código:
///
///   flutter run --dart-define-from-file=env.json
///
/// (env.json está en .gitignore; usa env.example.json como plantilla).
/// La clave "anon" de Supabase es pública por diseño; la protección real de
/// los datos la da Row Level Security (ver supabase/schema.sql).
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
