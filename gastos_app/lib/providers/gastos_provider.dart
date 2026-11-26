import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/categoria_repository.dart';
import '../data/gasto_repository.dart';
import '../data/presupuesto_repository.dart';
import '../models/categoria.dart';
import '../models/gasto.dart';
import '../models/presupuesto.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

/// Estado de la parte "de negocio": gastos, categorías y presupuestos.
/// Expone banderas de carga ([cargando], [sincronizando]) y [error] para que
/// la UI muestre spinners y mensajes.
class GastosProvider extends ChangeNotifier {
  GastosProvider({
    required GastoRepository gastoRepo,
    required CategoriaRepository categoriaRepo,
    required PresupuestoRepository presupuestoRepo,
    required SyncService sync,
    required NotificationService notificaciones,
  })  : _gastoRepo = gastoRepo,
        _categoriaRepo = categoriaRepo,
        _presupuestoRepo = presupuestoRepo,
        _sync = sync,
        _notificaciones = notificaciones;

  final GastoRepository _gastoRepo;
  final CategoriaRepository _categoriaRepo;
  final PresupuestoRepository _presupuestoRepo;
  final SyncService _sync;
  final NotificationService _notificaciones;

  bool cargando = false;
  bool sincronizando = false;
  String? error;
  DateTime? ultimaSync;

  List<Categoria> categorias = [];
  List<Gasto> gastos = [];
  List<Presupuesto> presupuestos = [];
  Map<String, double> totalesMes = {};
  Map<String, double> gastadoPorPresupuesto = {};

  double get totalMes => totalesMes.values.fold(0.0, (a, b) => a + b);

  Categoria? categoriaPorId(String id) {
    for (final c in categorias) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ----------------------------------------------------------- arranque
  Future<void> inicializar() async {
    // Evita mostrar datos de una sesión anterior mientras carga.
    gastos = [];
    presupuestos = [];
    categorias = [];
    totalesMes = {};
    gastadoPorPresupuesto = {};
    notifyListeners();

    await sincronizar(silencioso: true);
    await _ejecutar(() async {
      await _categoriaRepo.asegurarPorDefecto();
      await _recargar();
    });
  }

  Future<void> _recargar() async {
    categorias = await _categoriaRepo.todas();
    gastos = await _gastoRepo.todos();
    presupuestos = await _presupuestoRepo.todos();

    final ahora = DateTime.now();
    final (desdeMes, hastaMes) = Periodo.mensual.rango(ahora);
    totalesMes = await _gastoRepo.totalesPorCategoria(desdeMes, hastaMes);

    final gastado = <String, double>{};
    for (final p in presupuestos) {
      final (desde, hasta) = p.periodo.rango(ahora);
      gastado[p.id] =
          await _gastoRepo.totalEnRango(p.categoriaId, desde, hasta);
    }
    gastadoPorPresupuesto = gastado;
  }

  /// Ejecuta [accion] controlando los estados de carga y error.
  Future<void> _ejecutar(Future<void> Function() accion) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      await accion();
    } catch (e) {
      debugPrint('GastosProvider: $e');
      error = 'No se pudo completar la operación. Intenta de nuevo.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------- CRUD
  Future<bool> crearGasto({
    required double monto,
    required String descripcion,
    required DateTime fecha,
    required String categoriaId,
  }) async {
    var ok = false;
    await _ejecutar(() async {
      final g = await _gastoRepo.crear(
        monto: monto,
        descripcion: descripcion,
        fecha: fecha,
        categoriaId: categoriaId,
      );
      await _recargar();
      await _revisarPresupuestos(g.categoriaId);
      ok = true;
    });
    if (ok) unawaited(sincronizar(silencioso: true));
    return ok;
  }

  Future<bool> actualizarGasto(Gasto gasto) async {
    var ok = false;
    await _ejecutar(() async {
      await _gastoRepo.actualizar(gasto);
      await _recargar();
      await _revisarPresupuestos(gasto.categoriaId);
      ok = true;
    });
    if (ok) unawaited(sincronizar(silencioso: true));
    return ok;
  }

  Future<void> eliminarGasto(String id) async {
    // Quita el elemento de inmediato (lo necesita Dismissible).
    gastos = gastos.where((g) => g.id != id).toList();
    notifyListeners();
    await _ejecutar(() async {
      await _gastoRepo.eliminar(id);
      await _recargar();
    });
    unawaited(sincronizar(silencioso: true));
  }

  Future<void> guardarPresupuesto({
    required String categoriaId,
    required double monto,
    required Periodo periodo,
  }) async {
    await _ejecutar(() async {
      await _presupuestoRepo.guardar(
        categoriaId: categoriaId,
        monto: monto,
        periodo: periodo,
      );
      await _recargar();
      await _revisarPresupuestos(categoriaId);
    });
    unawaited(sincronizar(silencioso: true));
  }

  Future<void> eliminarPresupuesto(String id) async {
    await _ejecutar(() async {
      await _presupuestoRepo.eliminar(id);
      await _recargar();
    });
    unawaited(sincronizar(silencioso: true));
  }

  // ------------------------------------------------------ notificaciones
  Future<void> _revisarPresupuestos(String categoriaId) async {
    for (final p in presupuestos.where((p) => p.categoriaId == categoriaId)) {
      final gastado = gastadoPorPresupuesto[p.id] ?? 0;
      final porcentaje = gastado / p.monto * 100;
      if (porcentaje >= 80) {
        await _notificaciones.alertaPresupuesto(
          presupuestoId: p.id,
          categoria: categoriaPorId(p.categoriaId)?.nombre ?? 'tu categoría',
          porcentaje: porcentaje,
          periodo: p.periodo.name,
        );
      }
    }
  }

  // ---------------------------------------------------------------- nube
  Future<void> sincronizar({bool silencioso = false}) async {
    if (sincronizando) return;
    sincronizando = true;
    if (!silencioso) error = null;
    notifyListeners();
    try {
      await _sync.sincronizar();
      ultimaSync = DateTime.now();
      await _categoriaRepo.asegurarPorDefecto();
      await _recargar();
    } on SocketException {
      if (!silencioso) {
        error = 'Sin conexión. Tus datos siguen guardados en el dispositivo.';
      }
    } catch (e) {
      debugPrint('Sync: $e');
      if (!silencioso) error = 'No se pudo sincronizar con la nube.';
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }
}
