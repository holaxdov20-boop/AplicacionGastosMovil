import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/categoria.dart';
import 'app_database.dart';

class CategoriaRepository {
  static const _uuid = Uuid();

  static const _porDefecto = [
    ('Comida', 0xFFE57373),
    ('Transporte', 0xFF64B5F6),
    ('Hogar', 0xFF81C784),
    ('Ocio', 0xFFBA68C8),
    ('Salud', 0xFFFFB74D),
    ('Educación', 0xFF4DB6AC),
    ('Ropa', 0xFFF06292),
    ('Otros', 0xFF90A4AE),
  ];

  Future<Database> get _db => AppDatabase.instance.db;

  Future<List<Categoria>> todas() async {
    final d = await _db;
    final filas =
        await d.query('categorias', where: 'deleted = 0', orderBy: 'nombre');
    return filas.map(Categoria.fromMap).toList();
  }

  Future<Categoria> crear(String nombre, int color) async {
    final d = await _db;
    final id = _uuid.v4();
    final ahora = DateTime.now().toUtc().toIso8601String();
    await d.insert('categorias', {
      'id': id,
      'nombre': nombre,
      'color': color,
      'updated_at': ahora,
      'synced': 0,
      'deleted': 0,
    });
    return Categoria(
      id: id,
      nombre: nombre,
      color: color,
      updatedAt: DateTime.parse(ahora).toLocal(),
    );
  }

  /// Crea las categorías iniciales si todavía no existe ninguna.
  Future<void> asegurarPorDefecto() async {
    if ((await todas()).isNotEmpty) return;
    for (final (nombre, color) in _porDefecto) {
      await crear(nombre, color);
    }
  }
}
