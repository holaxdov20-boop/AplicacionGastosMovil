#!/usr/bin/env bash
# Crea el historial de Git del proyecto: main, develop, 4 ramas feature/*,
# 1 hotfix/*, merges --no-ff, etiquetas y 21 commits.
# feature/login se deja SIN fusionar para abrir el Pull Request en GitHub.
#
# Uso (una sola vez, en la carpeta del proyecto, con tu user.name/user.email
# de Git ya configurados):
#     bash scripts/git_flow.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -d .git ]; then
  echo "Ya existe un repositorio Git en esta carpeta. No se hizo nada." >&2
  exit 1
fi
if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
  echo "Configura primero tu identidad: git config --global user.name/user.email" >&2
  exit 1
fi

commit() { # commit "mensaje" ruta...
  local mensaje="$1"; shift
  git add -- "$@"
  git commit -q -m "$mensaje"
  echo "  commit: $mensaje"
}

# --- Guardar las versiones finales y preparar las versiones iniciales ------
FINAL="$(mktemp -d)"
cp lib/main.dart                 "$FINAL/main.dart"
cp lib/screens/home_screen.dart  "$FINAL/home_screen.dart"
cp .gitignore                    "$FINAL/gitignore"
cp README.md                     "$FINAL/README.md"

cp scripts/v1_main.dart.txt lib/main.dart                 # main sin login
sed -i '/\[login\]/d' lib/screens/home_screen.dart        # home sin logout
grep -v '^env.json$' "$FINAL/gitignore" > .gitignore      # (el hotfix lo corrige)
printf '# Mis Gastos\n\nMVP de gestión de gastos personales (Flutter).\n' > README.md

# --- main ------------------------------------------------------------------
echo "main"
git init -q -b main
commit "chore: estructura inicial del proyecto Flutter" pubspec.yaml analysis_options.yaml .gitignore
commit "docs: README inicial" README.md

# --- develop ---------------------------------------------------------------
git checkout -q -b develop

# --- feature/base-datos ----------------------------------------------------
echo "feature/base-datos"
git checkout -q -b feature/base-datos
commit "feat(modelo): entidades Gasto, Categoria y Presupuesto" lib/models
commit "feat(db): base SQLite con llaves foraneas y banderas de sincronizacion" lib/data/app_database.dart
commit "feat(seguridad): cifrado AES-256-GCM con clave en almacenamiento seguro" lib/services/crypto_service.dart
commit "feat(db): repositorios con CRUD de gastos, categorias y presupuestos" lib/data/gasto_repository.dart lib/data/categoria_repository.dart lib/data/presupuesto_repository.dart
git checkout -q develop
git merge -q --no-ff feature/base-datos -m "Merge feature/base-datos into develop"

# --- feature/sync-notificaciones -------------------------------------------
echo "feature/sync-notificaciones"
git checkout -q -b feature/sync-notificaciones
commit "feat(cloud): esquema Supabase con RLS y configuracion por entorno" supabase lib/config
commit "feat(sync): sincronizacion bidireccional SQLite <-> Supabase" lib/services/sync_service.dart
commit "feat(notificaciones): alertas de presupuesto y recordatorio semanal programado" lib/services/notification_service.dart
git checkout -q develop
git merge -q --no-ff feature/sync-notificaciones -m "Merge feature/sync-notificaciones into develop"

# --- feature/gastos-crud ---------------------------------------------------
echo "feature/gastos-crud"
git checkout -q -b feature/gastos-crud
commit "feat(validacion): validadores de entrada y pruebas unitarias" lib/utils/validators.dart test
commit "feat(estado): GastosProvider con estados de carga y error" lib/providers/gastos_provider.dart
commit "feat(ui): formulario de gasto y lista con edicion y eliminacion" lib/utils/formato.dart lib/screens/gasto_form_screen.dart lib/screens/gastos_tab.dart
commit "feat(ui): resumen con fl_chart y pantalla de presupuestos" lib/screens/resumen_tab.dart lib/screens/presupuestos_tab.dart
commit "feat(app): pantalla principal y arranque de la aplicacion" lib/app.dart lib/screens/home_screen.dart lib/main.dart
git checkout -q develop
git merge -q --no-ff feature/gastos-crud -m "Merge feature/gastos-crud into develop"

# --- release v0.1.0 --------------------------------------------------------
echo "release v0.1.0"
git checkout -q main
git merge -q --no-ff develop -m "Release v0.1.0: MVP sin autenticacion"
git tag v0.1.0

# --- hotfix ----------------------------------------------------------------
echo "hotfix/proteger-secretos"
git checkout -q -b hotfix/proteger-secretos
cp "$FINAL/gitignore" .gitignore
commit "fix(seguridad): ignorar env.json y agregar plantilla env.example.json" .gitignore env.example.json
git checkout -q main
git merge -q --no-ff hotfix/proteger-secretos -m "Merge hotfix/proteger-secretos into main"
git tag v0.1.1
git checkout -q develop
git merge -q --no-ff hotfix/proteger-secretos -m "Merge hotfix/proteger-secretos into develop"

# --- feature/login (queda abierta para el Pull Request) --------------------
echo "feature/login"
git checkout -q -b feature/login
cp "$FINAL/main.dart"       lib/main.dart
cp "$FINAL/home_screen.dart" lib/screens/home_screen.dart
cp "$FINAL/README.md"       README.md
commit "feat(auth): Supabase Auth y sesion guardada en almacenamiento seguro" lib/services/auth_service.dart lib/services/secure_session_storage.dart
commit "feat(biometria): desbloqueo con huella o Face ID" lib/services/biometric_service.dart
commit "feat(auth): AuthProvider con limite de intentos fallidos" lib/providers/auth_provider.dart
commit "feat(ui): pantallas de login y de bloqueo biometrico" lib/screens/login_screen.dart lib/screens/lock_screen.dart
commit "feat(app): AuthGate con bloqueo por inactividad y cierre de sesion" lib/auth_gate.dart lib/main.dart lib/screens/home_screen.dart
commit "docs: README completo, flujo de Git y plantilla de Pull Request" README.md docs scripts

rm -rf "$FINAL"
echo
echo "Listo. Estás en la rama feature/login (versión completa de la app)."
echo "Total de commits (sin merges): $(git rev-list --no-merges --all --count)"
echo "Siguiente paso: publicar en GitHub y abrir el PR (ver docs/GIT_WORKFLOW.md)."
git status --short | head -5
