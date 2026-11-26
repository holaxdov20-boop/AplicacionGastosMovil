/// Categoría de gasto (p. ej. Comida, Transporte).
class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.color,
    required this.updatedAt,
  });

  final String id;
  final String nombre;

  /// Color ARGB almacenado como entero (0xFFRRGGBB).
  final int color;
  final DateTime updatedAt;

  factory Categoria.fromMap(Map<String, Object?> m) => Categoria(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        color: m['color'] as int,
        updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
      );
}
