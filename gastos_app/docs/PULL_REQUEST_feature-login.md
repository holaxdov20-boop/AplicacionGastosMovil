# feat: autenticación, biometría y bloqueo de la app

**Base:** `develop` ← **Compare:** `feature/login`

## Resumen

Agrega inicio de sesión / registro con Supabase Auth, persistencia segura de la sesión y desbloqueo con huella o Face ID. `AuthGate` decide qué pantalla mostrar y `HomeScreen` gana el botón de cerrar sesión.

## Cambios

- `AuthService` y `SecureSessionStorage`: login/registro y tokens guardados en Keystore/Keychain.
- `BiometricService`: huella / Face ID con `local_auth` (si el dispositivo no lo soporta, se omite el bloqueo).
- `AuthProvider`: estados `iniciando / sinSesion / bloqueado / autenticado`, mensajes de error traducidos y límite de 5 intentos fallidos por 30 s.
- `LoginScreen` y `LockScreen`.
- `AuthGate`: vuelve a bloquear tras 30 s en segundo plano.
- `main.dart` y `home_screen.dart`: cableado del login y botón de cerrar sesión (borra la base local).

## Cómo probar

1. `flutter run --dart-define-from-file=env.json`
2. Crear cuenta → debe entrar a la app.
3. Cerrar sesión → vuelve al login y los datos locales desaparecen.
4. Iniciar sesión con contraseña incorrecta 5 veces → mensaje de espera.
5. Cerrar la app y abrirla → pide huella / Face ID.
6. Mandar la app a segundo plano > 30 s → pide biometría al volver.

## Revisión (auto-revisión documentada)

| # | Punto revisado | Resultado |
|---|---|---|
| 1 | ¿Los tokens evitan SharedPreferences? | ✅ `SecureSessionStorage` usa `flutter_secure_storage` |
| 2 | ¿Hay secretos en el código? | ✅ No; `--dart-define-from-file` y `env.json` ignorado |
| 3 | ¿Los errores filtran detalles internos? | ✅ Mensajes genéricos traducidos; detalle solo en `debugPrint` |
| 4 | ¿Se valida la entrada antes de llamar a la red? | ✅ `Validators.email` / `Validators.password` |
| 5 | ¿Qué pasa si el dispositivo no tiene biometría? | ⚠️ Se omite el bloqueo (documentado en README) |
| 6 | ¿Datos de otra cuenta quedan en el teléfono? | ✅ `cerrarSesion()` ejecuta `AppDatabase.limpiar()` |
| 7 | ¿Hay pruebas? | ⚠️ Cubiertas las validaciones; falta probar `AuthProvider` con mocks (pendiente) |

**Decisión:** aprobado para integrar en `develop`. Pendientes anotados como mejoras futuras: pruebas de `AuthProvider` y recuperación de contraseña.
