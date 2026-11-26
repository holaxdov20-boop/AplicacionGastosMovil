/// Periodo de un presupuesto.
enum Periodo {
  semanal,
  mensual;

  String get etiqueta => this == Periodo.semanal ? 'Semanal' : 'Mensual';

  /// Rango [desde, hasta) del periodo que contiene a [ahora].
  /// La semana empieza el lunes.
  (DateTime, DateTime) rango(DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    if (this == Periodo.semanal) {
      final inicio = hoy.subtract(Duration(days: hoy.weekday - 1));
      return (inicio, inicio.add(const Duration(days: 7)));
    }
    return (DateTime(hoy.year, hoy.month), DateTime(hoy.year, hoy.month + 1));
  }
}

/// Límite de gasto para una [Categoria] en un [Periodo] (relación N:1).
class Presupuesto {
  const Presupuesto({
    required this.id,
    required this.categoriaId,
    required this.monto,
    required this.periodo,
    required this.updatedAt,
  });

  final String id;
  final String categoriaId;
  final double monto;
  final Periodo periodo;
  final DateTime updatedAt;

  factory Presupuesto.fromMap(Map<String, Object?> m) => Presupuesto(
        id: m['id'] as String,
        categoriaId: m['categoria_id'] as String,
        monto: (m['monto'] as num).toDouble(),
        periodo: Periodo.values.byName(m['periodo'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
      );
}
