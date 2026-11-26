# Mis Gastos — MVP de gestión de gastos personales

App móvil hecha con **Flutter (Dart)**: registra gastos, los organiza por categoría, define presupuestos y avisa cuando estás cerca de tu límite. Funciona sin internet (SQLite) y sincroniza con **Supabase** cuando hay conexión.

## Funcionalidades

| Requisito | Implementación |
|---|---|
| Persistencia local | SQLite (`sqflite`), 3 entidades relacionadas: `Gasto`, `Categoria`, `Presupuesto` |
| CRUD de gastos | Crear, listar, editar (tocar) y eliminar (deslizar) |
| Autenticación | Supabase Auth (correo + contraseña) |
| Sincronización | Supabase (PostgREST), offline-first, bidireccional |
| Estados de carga/error | `GastosProvider` / `AuthProvider` exponen `cargando`, `sincronizando`, `error` |
| Sensor | Huella dactilar / Face ID (`local_auth`) al abrir la app y tras 30 s en segundo plano |
| Notificaciones | Local programada (recordatorio semanal) + alerta al llegar al 80 % del presupuesto |
| Seguridad | AES-256-GCM para descripciones, tokens en Keystore/Keychain, validación de entradas, RLS en la nube |
| Librerías de terceros | `fl_chart`, `intl`, `local_auth`, `flutter_local_notifications`, `flutter_secure_storage`, `encrypt`, `supabase_flutter`, `provider` |

## Requisitos previos

- Flutter 3.22 o superior (Dart 3.3+) — `flutter doctor` sin errores
- Una cuenta gratuita en [Supabase](https://supabase.com)
- Un teléfono o emulador Android/iOS (la biometría requiere huella/Face ID o PIN configurado)

## Instalación

### 1. Clonar y generar las carpetas de plataforma

```bash
git clone https://github.com/TU_USUARIO/gastos_app.git
cd gastos_app
flutter create --platforms=android,ios --project-name gastos_app .
flutter pub get
```

> `flutter create .` solo agrega `android/` e `ios/`; no sobrescribe `lib/` ni `pubspec.yaml`.

### 2. Configurar Supabase

1. Crea un proyecto en Supabase.
2. En **SQL Editor** ejecuta el contenido de `supabase/schema.sql` (crea las tablas y las políticas RLS).
3. En **Authentication → Providers → Email** puedes desactivar *Confirm email* mientras pruebas.
4. Copia `env.example.json` a `env.json` y pon tu **Project URL** y tu clave **anon public** (*Project Settings → API*):

```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ..."
}
```

`env.json` está en `.gitignore`; nunca lo subas.

### 3. Configuración de Android

**`android/app/build.gradle.kts`** (en Groovy el equivalente es `build.gradle`):

```kotlin
android {
    defaultConfig {
        minSdk = 23            // requerido por flutter_secure_storage
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // requerido por flutter_local_notifications
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**`MainActivity`** (`android/app/src/main/kotlin/.../MainActivity.kt`) — `local_auth` necesita `FlutterFragmentActivity`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**`android/app/src/main/AndroidManifest.xml`** — dentro de `<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

y dentro de `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### 4. Configuración de iOS (solo si compilas para iPhone)

En `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Usamos Face ID para proteger tus gastos.</string>
```

En `ios/Runner/AppDelegate.swift`, dentro de `application(_:didFinishLaunchingWithOptions:)`, antes del `return`:

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
}
```

### 5. Ejecutar

```bash
flutter run --dart-define-from-file=env.json
```

### 6. Pruebas unitarias

```bash
flutter test
```

## Estructura

```
lib/
├── main.dart                  Arranque, inyección de dependencias
├── app.dart                   MaterialApp (tema, localización es-MX)
├── auth_gate.dart             Login → bloqueo biométrico → app
├── config/                    Variables de entorno (--dart-define)
├── models/                    Gasto, Categoria, Presupuesto
├── data/                      SQLite + repositorios (CRUD)
├── services/                  Auth, biometría, cifrado, sync, notificaciones
├── providers/                 AuthProvider, GastosProvider (estado)
├── screens/                   Login, bloqueo, gastos, resumen, presupuestos
└── utils/                     Validadores y formato de moneda/fecha
supabase/schema.sql            Tablas + Row Level Security
docs/                          Flujo de Git y plantilla de Pull Request
scripts/git_flow.sh            Genera el historial de Git (ramas y commits)
```

## Seguridad (resumen)

- **Cifrado en reposo:** la descripción de cada gasto se cifra con AES-256-GCM (IV aleatorio por registro). La clave se genera en el dispositivo y vive en Keystore/Keychain. La nube solo guarda el texto cifrado.
- **Tokens:** la sesión de Supabase se persiste con `flutter_secure_storage`, no en SharedPreferences.
- **Validación:** correo, contraseña (8+ con letras y números), monto (≤ 2 decimales, > 0, tope), descripción (longitud + caracteres de control) y límite de 5 intentos de login por 30 s.
- **Autorización en la nube:** Row Level Security por `user_id`; las tablas rechazan filas de otros usuarios.
- **Secretos fuera del código:** `--dart-define-from-file` + `.gitignore`.
- **Cierre de sesión:** borra los datos locales.

## Limitaciones conocidas del MVP

- La clave de cifrado es **por dispositivo**: en otro teléfono los gastos sincronizados aparecen con la descripción como "contenido no disponible" (el monto, la fecha y la categoría sí se ven).
- La sincronización descarga todas las filas en cada ejecución (suficiente para un MVP; para datos grandes convendría sincronización incremental).
- Conflictos: gana el registro con `updated_at` más reciente.
- La zona horaria de las notificaciones está fija en `America/Mexico_City` (`notification_service.dart`).

## Flujo de ramas

Ver [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md).
