import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'auth_gate.dart';
import 'config/config_faltante.dart';
import 'config/env.dart';
import 'data/categoria_repository.dart';
import 'data/gasto_repository.dart';
import 'data/presupuesto_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/gastos_provider.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/crypto_service.dart';
import 'services/notification_service.dart';
import 'services/secure_session_storage.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  if (!Env.configurado) {
    runApp(const MaterialApp(home: ConfigFaltante()));
    return;
  }

  // Los tokens de sesión se guardan en Keystore/Keychain, no en texto plano.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );

  final notificaciones = NotificationService();
  await notificaciones.init();
  await notificaciones.programarRecordatorioSemanal();

  final crypto = CryptoService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(), BiometricService())..iniciar(),
        ),
        ChangeNotifierProvider(
          create: (_) => GastosProvider(
            gastoRepo: GastoRepository(crypto),
            categoriaRepo: CategoriaRepository(),
            presupuestoRepo: PresupuestoRepository(),
            sync: SyncService(),
            notificaciones: notificaciones,
          ),
        ),
      ],
      child: const GastosApp(home: AuthGate()),
    ),
  );
}
