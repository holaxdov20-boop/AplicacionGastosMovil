import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_app/models/presupuesto.dart';

void main() {
  // Miércoles 25 de noviembre de 2026.
  final miercoles = DateTime(2026, 11, 25, 18, 17);

  test('la semana va de lunes a lunes', () {
    final (desde, hasta) = Periodo.semanal.rango(miercoles);
    expect(desde, DateTime(2026, 11, 23));
    expect(hasta, DateTime(2026, 11, 30));
  });

  test('el mes va del día 1 al día 1 del mes siguiente', () {
    final (desde, hasta) = Periodo.mensual.rango(miercoles);
    expect(desde, DateTime(2026, 11, 1));
    expect(hasta, DateTime(2026, 12, 1));
  });

  test('diciembre rueda correctamente a enero', () {
    final (_, hasta) = Periodo.mensual.rango(DateTime(2026, 12, 15));
    expect(hasta, DateTime(2027, 1, 1));
  });
}
