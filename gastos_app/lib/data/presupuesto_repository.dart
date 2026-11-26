import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/presupuesto.dart';
import 'app_database.dart';

class PresupuestoRepository {
  static const _uuid = Uuid();

  Future<Database> get _db => AppDatabase.instance.db;

  Future<List<Presupuesto>> todos() async {
    final d = await _db;
    final filas = await d.query('presupuestos', where: 'deleted = 0');
    return filas.map(Presupuesto.fromMap).toList();
  }

  /// Crea el presupuesto o actualiza el existente de esa categoría y periodo.
  Future<void> guardar({
    required String categoriaId,
    required double monto,
    required Periodo periodo,
  }) async {
    final d = await _db;
    final ahora = DateTime.now().toUtc().toIso8601String();
    final existente = await d.query(
      'presupuestos',
      columns: ['id'],
      where: 'categoria_id = ? AND periodo = ? AND deleted = 0',
      whereArgs: [categoriaId, periodo.name],
      limit: 1,
    );
    if (existente.isNotEmpty) {
      await d.update(
        'presupuestos',
        {'monto': monto, 'updated_at': ahora, 'synced': 0},
        where: 'id = ?',
        whereArgs: [existente.first['id']],
      );
    } else {
      await d.insert('presupuestos', {
        'id': _uuid.v4(),
        'categoria_id': categoriaId,
        'monto': monto,
        'periodo': periodo.name,
        'updated_at': ahora,
        'synced': 0,
        'deleted': 0,
      });
    }
  }

  Future<void> eliminar(String id) async {
    final d = await _db;
    await d.update(
      'presupuestos',
      {
        'deleted': 1,
        'synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
