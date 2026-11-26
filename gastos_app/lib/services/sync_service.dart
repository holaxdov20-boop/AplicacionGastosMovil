import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_database.dart';

/// Sincronización bidireccional SQLite <-> Supabase (tablas PostgREST).
///
/// Estrategia (offline-first):
///  1. Subir borrados locales y luego eliminar la fila local.
///  2. Subir (upsert) filas con `synced = 0`.
///  3. Descargar todo y aplicar lo que sea más reciente
///     (gana la fila con `updated_at` mayor).
///  4. Quitar filas locales ya sincronizadas que ya no existen en la nube
///     (borradas desde otro dispositivo).
class SyncService {
  SupabaseClient get _cliente => Supabase.instance.client;

  static const _tablas = ['categorias', 'presupuestos', 'gastos'];

  /// Columnas compartidas entre SQLite y Supabase (sin banderas locales).
  static const _columnas = {
    'categorias': ['id', 'nombre', 'color', 'updated_at'],
    'presupuestos': ['id', 'categoria_id', 'monto', 'periodo', 'updated_at'],
    'gastos': [
      'id',
      'categoria_id',
      'monto',
      'descripcion_cifrada',
      'fecha',
      'updated_at'
    ],
  };

  Future<void> sincronizar() async {
    if (_cliente.auth.currentUser == null) {
      throw StateError('No hay sesión iniciada.');
    }
    final d = await AppDatabase.instance.db;

    // 1) Borrados (orden inverso por las llaves foráneas).
    for (final t in ['gastos', 'presupuestos', 'categorias']) {
      final borrados = await d.query(t, columns: ['id'], where: 'deleted = 1');
      for (final fila in borrados) {
        final id = fila['id'] as String;
        await _cliente.from(t).delete().eq('id', id);
        await d.delete(t, where: 'id = ?', whereArgs: [id]);
      }
    }

    // 2) Altas y modificaciones pendientes.
    for (final t in _tablas) {
      final pendientes =
          await d.query(t, where: 'synced = 0 AND deleted = 0');
      if (pendientes.isEmpty) continue;
      final cargaUtil = pendientes
          .map((f) => {for (final c in _columnas[t]!) c: f[c]})
          .toList();
      await _cliente.from(t).upsert(cargaUtil);
      await d.update(t, {'synced': 1}, where: 'synced = 0 AND deleted = 0');
    }

    // 3) Descarga y mezcla.
    final idsRemotos = <String, Set<String>>{};
    for (final t in _tablas) {
      final remotos = await _cliente.from(t).select();
      idsRemotos[t] = {for (final r in remotos) r['id'] as String};
      for (final r in remotos) {
        await _aplicarRemoto(d, t, r);
      }
    }

    // 4) Limpieza de lo que ya no existe en la nube.
    for (final t in ['gastos', 'presupuestos', 'categorias']) {
      final locales = await d.query(t, columns: ['id'], where: 'synced = 1');
      for (final fila in locales) {
        final id = fila['id'] as String;
        if (!idsRemotos[t]!.contains(id)) {
          await d.delete(t, where: 'id = ?', whereArgs: [id]);
        }
      }
    }
  }

  Future<void> _aplicarRemoto(
      Database d, String tabla, Map<String, dynamic> remoto) async {
    final id = remoto['id'] as String;
    final datos = _aLocal(tabla, remoto);
    final local = await d.query(tabla,
        columns: ['updated_at'], where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      await d.insert(tabla, datos);
    } else {
      final fechaLocal = DateTime.parse(local.first['updated_at'] as String);
      final fechaRemota = DateTime.parse(datos['updated_at'] as String);
      if (fechaRemota.isAfter(fechaLocal)) {
        await d.update(tabla, datos, where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Map<String, Object?> _aLocal(String tabla, Map<String, dynamic> r) {
    final m = <String, Object?>{};
    for (final c in _columnas[tabla]!) {
      Object? v = r[c];
      if (c == 'updated_at' || c == 'fecha') {
        // Normaliza a ISO-8601 UTC para que las comparaciones de texto
        // en SQLite sean consistentes.
        v = DateTime.parse(v as String).toUtc().toIso8601String();
      } else if (c == 'monto') {
        v = (v as num).toDouble();
      }
      m[c] = v;
    }
    m['synced'] = 1;
    m['deleted'] = 0;
    return m;
  }
}
