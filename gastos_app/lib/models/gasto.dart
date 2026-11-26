/// Gasto personal. Pertenece a una [Categoria] (relación N:1).
///
/// La [descripcion] se guarda cifrada en SQLite y en la nube; en memoria
/// siempre vive descifrada.
class Gasto {
  const Gasto({
    required this.id,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.categoriaId,
    required this.updatedAt,
  });

  final String id;
  final double monto;
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final DateTime updatedAt;

  Gasto copyWith({
    double? monto,
    String? descripcion,
    DateTime? fecha,
    String? categoriaId,
  }) =>
      Gasto(
        id: id,
        monto: monto ?? this.monto,
        descripcion: descripcion ?? this.descripcion,
        fecha: fecha ?? this.fecha,
        categoriaId: categoriaId ?? this.categoriaId,
        updatedAt: updatedAt,
      );
}
