import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Acceso único a la base SQLite local.
///
/// Cada tabla tiene dos banderas para la sincronización:
///  * `synced`  = 0 si hay cambios pendientes de subir a la nube.
///  * `deleted` = 1 si el registro fue borrado localmente (borrado lógico);
///                se elimina físicamente cuando el borrado llega a la nube.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), 'gastos.db');
    return openDatabase(
      ruta,
      version: 1,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        await d.execute('''
          CREATE TABLE categorias (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            color INTEGER NOT NULL,
            updated_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )''');
        await d.execute('''
          CREATE TABLE presupuestos (
            id TEXT PRIMARY KEY,
            categoria_id TEXT NOT NULL
              REFERENCES categorias(id) ON DELETE CASCADE,
            monto REAL NOT NULL CHECK (monto > 0),
            periodo TEXT NOT NULL CHECK (periodo IN ('semanal','mensual')),
            updated_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )''');
        await d.execute('''
          CREATE TABLE gastos (
            id TEXT PRIMARY KEY,
            categoria_id TEXT NOT NULL
              REFERENCES categorias(id) ON DELETE RESTRICT,
            monto REAL NOT NULL CHECK (monto > 0),
            descripcion_cifrada TEXT NOT NULL DEFAULT '',
            fecha TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )''');
        await d.execute('CREATE INDEX idx_gastos_fecha ON gastos(fecha)');
        await d.execute(
            'CREATE INDEX idx_gastos_categoria ON gastos(categoria_id)');
      },
    );
  }

  /// Borra todos los datos locales (se usa al cerrar sesión para que otra
  /// cuenta en el mismo dispositivo no vea información ajena).
  Future<void> limpiar() async {
    final d = await db;
    await d.transaction((t) async {
      await t.delete('gastos');
      await t.delete('presupuestos');
      await t.delete('categorias');
    });
  }
}
