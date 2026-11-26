import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_app/utils/validators.dart';

void main() {
  group('Validators.monto', () {
    test('acepta enteros y hasta 2 decimales', () {
      expect(Validators.monto('120'), isNull);
      expect(Validators.monto('12.50'), isNull);
      expect(Validators.monto('12,5'), isNull);
    });

    test('rechaza vacío, cero, negativos y más de 2 decimales', () {
      expect(Validators.monto(''), isNotNull);
      expect(Validators.monto('0'), isNotNull);
      expect(Validators.monto('-5'), isNotNull);
      expect(Validators.monto('12.555'), isNotNull);
      expect(Validators.monto('abc'), isNotNull);
    });

    test('rechaza montos fuera de rango', () {
      expect(Validators.monto('1000001'), isNotNull);
    });

    test('parseMonto convierte coma decimal', () {
      expect(Validators.parseMonto('12,5'), 12.5);
      expect(Validators.parseMonto('x'), isNull);
    });
  });

  group('Validators.email / password', () {
    test('email', () {
      expect(Validators.email('alguien@correo.com'), isNull);
      expect(Validators.email('sin-arroba'), isNotNull);
      expect(Validators.email('  '), isNotNull);
    });

    test('password exige 8+ caracteres con letras y números', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('a1'), isNotNull);
    });
  });

  group('Validators.descripcion / sanitizar', () {
    test('limita la longitud', () {
      expect(Validators.descripcion('a' * 200), isNull);
      expect(Validators.descripcion('a' * 201), isNotNull);
    });

    test('sanitizar quita caracteres de control y espacios repetidos', () {
      expect(Validators.sanitizar('  hola\u0000  mundo\n '), 'hola mundo');
    });
  });
}
