import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/gasto.dart';
import '../services/crypto_service.dart';
import 'app_database.dart';

/// CRUD de gastos. La descripción se cifra antes de escribir en SQLite y se
/// descifra al leer.
class GastoRepository {
  GastoRepository(this._crypto);

  final CryptoService _crypto;
  static const _uuid = Uuid();

  Future<Database> get _db => AppDatabase.instance.db;

  String _iso(DateTime f) => f.toUtc().toIso8601String();

  Future<Gasto> _aGasto(Map<String, Object?> m) async => Gasto(
        id: m['id'] as String,
        monto: (m['monto'] as num).toDouble(),
        descripcion:
            await _crypto.descifrar(m['descripcion_cifrada'] as String? ?? ''),
        fecha: DateTime.parse(m['fecha'] as String).toLocal(),
        categoriaId: m['categoria_id'] as String,
        updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
      );

  // ---------------------------------------------------------------- READ
  Future<List<Gasto>> todos() async {
    final d = await _db;
    final filas =
        await d.query('gastos', where: 'deleted = 0', orderBy: 'fecha DESC');
    return Future.wait(filas.map(_aGasto));
  }

  // -------------------------------------------------------------- CREATE
  Future<Gasto> crear({
    required double monto,
    required String descripcion,
    required DateTime fecha,
    required String categoriaId,
  }) async {
    final d = await _db;
    final id = _uuid.v4();
    final ahora = DateTime.now();
    await d.insert('gastos', {
      'id': id,
      'categoria_id': categoriaId,
      'monto': monto,
      'descripcion_cifrada': await _crypto.cifrar(descripcion),
      'fecha': _iso(fecha),
      'updated_at': _iso(ahora),
      'synced': 0,
      'deleted': 0,
    });
    return Gasto(
      id: id,
      monto: monto,
      descripcion: descripcion,
      fecha: fecha,
      categoriaId: categoriaId,
      updatedAt: ahora,
    );
  }

  // -------------------------------------------------------------- UPDATE
  Future<void> actualizar(Gasto g) async {
    final d = await _db;
    await d.update(
      'gastos',
      {
        'categoria_id': g.categoriaId,
        'monto': g.monto,
        'descripcion_cifrada': await _crypto.cifrar(g.descripcion),
        'fecha': _iso(g.fecha),
        'updated_at': _iso(DateTime.now()),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [g.id],
    );
  }

  // -------------------------------------------------------------- DELETE
  /// Borrado lógico: la fila se elimina físicamente al sincronizar.
  Future<void> eliminar(String id) async {
    final d = await _db;
    await d.update(
      'gastos',
      {'deleted': 1, 'synced': 0, 'updated_at': _iso(DateTime.now())},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------ TOTALES
  Future<double> totalEnRango(
      String categoriaId, DateTime desde, DateTime hasta) async {
    final d = await _db;
    final r = await d.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM gastos '
      'WHERE deleted = 0 AND categoria_id = ? AND fecha >= ? AND fecha < ?',
      [categoriaId, _iso(desde), _iso(hasta)],
    );
    return (r.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> totalesPorCategoria(
      DateTime desde, DateTime hasta) async {
    final d = await _db;
    final r = await d.rawQuery(
      'SELECT categoria_id, SUM(monto) AS total FROM gastos '
      'WHERE deleted = 0 AND fecha >= ? AND fecha < ? '
      'GROUP BY categoria_id',
      [_iso(desde), _iso(hasta)],
    );
    return {
      for (final f in r)
        f['categoria_id'] as String: (f['total'] as num).toDouble(),
    };
  }
}
