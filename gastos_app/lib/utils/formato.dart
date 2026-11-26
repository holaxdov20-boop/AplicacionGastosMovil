import 'package:intl/intl.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

/// 1234.5 -> "$1,234.50"
String dinero(num valor) => _moneda.format(valor);

/// 2026-11-25 -> "25 nov 2026"
String fechaCorta(DateTime fecha) => DateFormat.yMMMd('es_MX').format(fecha);
