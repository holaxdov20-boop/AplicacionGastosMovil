/// Validación y saneamiento de entradas del usuario.
class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _montoValido = RegExp(r'^\d{1,9}([.,]\d{1,2})?$');
  static final _controles = RegExp(r'[\u0000-\u001F\u007F]');

  static const maxDescripcion = 200;
  static const maxMonto = 1000000.0;

  static String? email(String? v) {
    final texto = (v ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu correo';
    if (texto.length > 254 || !_email.hasMatch(texto)) {
      return 'Correo no válido';
    }
    return null;
  }

  static String? password(String? v) {
    final texto = v ?? '';
    if (texto.length < 8) return 'Mínimo 8 caracteres';
    if (texto.length > 72) return 'Máximo 72 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(texto) ||
        !RegExp(r'\d').hasMatch(texto)) {
      return 'Usa letras y números';
    }
    return null;
  }

  /// Convierte "12,50" o "12.50" a double; devuelve null si no es válido.
  static double? parseMonto(String? v) {
    final texto = (v ?? '').trim();
    if (!_montoValido.hasMatch(texto)) return null;
    return double.tryParse(texto.replaceAll(',', '.'));
  }

  static String? monto(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Ingresa un monto';
    final valor = parseMonto(v);
    if (valor == null) return 'Usa un número con hasta 2 decimales';
    if (valor <= 0) return 'El monto debe ser mayor a 0';
    if (valor > maxMonto) return 'Monto demasiado alto';
    return null;
  }

  static String? descripcion(String? v) {
    if ((v ?? '').length > maxDescripcion) {
      return 'Máximo $maxDescripcion caracteres';
    }
    return null;
  }

  /// Quita caracteres de control y espacios repetidos.
  static String sanitizar(String v) =>
      v.replaceAll(_controles, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
