# Flujo de Git

## Ramas

| Rama | Propósito |
|---|---|
| `main` | Versiones estables (etiquetas `v0.1.0`, `v0.1.1`) |
| `develop` | Integración de funcionalidades |
| `feature/base-datos` | Modelo de datos, SQLite, cifrado, repositorios |
| `feature/sync-notificaciones` | Esquema Supabase, sincronización, notificaciones |
| `feature/gastos-crud` | Validación, estado, pantallas de gastos/resumen/presupuestos |
| `feature/login` | Autenticación, biometría, bloqueo (se integra con **Pull Request**) |
| `hotfix/proteger-secretos` | Corrección urgente sobre `main` (`env.json` no estaba en `.gitignore`) |

## Convención de commits

`tipo(alcance): descripción en imperativo` — tipos usados: `feat`, `fix`, `docs`, `chore`.

## Cómo se generó el historial

El script `scripts/git_flow.sh` crea el repositorio con los commits, ramas, merges (`--no-ff`) y etiquetas, en el orden descrito arriba. Se ejecuta **una vez**, dentro de la carpeta del proyecto, con tu usuario de Git ya configurado:

```bash
git config --global user.name  "Tu Nombre"
git config --global user.email "tu@correo.com"
bash scripts/git_flow.sh
```

Al terminar, el script deja `feature/login` **sin fusionar** para que abras el Pull Request en GitHub.

## Publicar en GitHub

1. Crea un repositorio **público y vacío** en GitHub (sin README ni .gitignore).
2. Desde la carpeta del proyecto:

```bash
git remote add origin https://github.com/TU_USUARIO/gastos_app.git
git push -u origin main
git push origin develop feature/base-datos feature/sync-notificaciones feature/gastos-crud feature/login hotfix/proteger-secretos
git push origin --tags
```

## Pull Request `feature/login` → `develop`

1. En GitHub: **Pull requests → New pull request**, base `develop`, compare `feature/login`.
2. Pega la descripción de [`PULL_REQUEST_feature-login.md`](PULL_REQUEST_feature-login.md).
3. **Revisión (auto-revisión documentada):** en la pestaña *Files changed* deja al menos 2–3 comentarios en líneas concretas (por ejemplo: límite de intentos en `auth_provider.dart`, tokens en `secure_session_storage.dart`, bloqueo por inactividad en `auth_gate.dart`) y usa **Review changes → Comment/Approve**. Si GitHub no te deja aprobar tu propio PR, deja la revisión como *Comment* y documenta en el cuerpo del PR el resultado de la checklist.
4. **Merge pull request** (se recomienda *Create a merge commit*).
5. Actualiza tu copia local:

```bash
git checkout develop && git pull origin develop
```

6. Para dejar `main` con el login, abre un segundo PR `develop` → `main` (o `git merge --no-ff develop` en `main`) y etiqueta `v0.2.0`.

> Toma capturas de pantalla del PR, de la revisión y de `git log --oneline --graph --all` para el reporte.
