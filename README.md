# Anarchyball: The Game

Base de desarrollo de un *action-platformer/shooter* 2D con progresión RPG ligera. El proyecto usa Godot 4.x estable y GDScript tipado, con una arquitectura orientada a composición, contenido data-driven y validación automatizada de niveles.

## Estado actual

**Phase 0 - Foundation implementada.** El proyecto importa y ejecuta su bootstrap en Godot 4.6.3, dispone de input abstracto, diagnóstico visual, tests headless y CI reproducible. El siguiente trabajo de gameplay es Phase 1: movimiento y cámara.

## Empezar

Requisitos:

- Godot 4.6.3 estable, build estándar o Mono;
- Git;
- teclado y, para validar controles, un gamepad.

El proyecto sigue siendo GDScript-only aunque la instalación local de Godot sea Mono.

Configurar el ejecutable en la terminal actual cuando Godot no esté en `PATH`:

```powershell
$env:GODOT_BIN = "C:\ruta\a\Godot_v4.6.3-stable_console.exe"
```

Abrir el editor:

```powershell
& $env:GODOT_BIN --editor --path .
```

Validar la importación sin interfaz:

```powershell
.\tools\phase0\verify_all.cmd
```

Ese comando ejecuta, en orden:

1. importación headless;
2. smoke test del bootstrap;
3. suite GdUnit4.

También puede pasarse el binario explícitamente:

```powershell
.\tools\phase0\verify_all.cmd -GodotBinary "C:\ruta\a\godot_console.exe"
```

Los reportes quedan en `reports/` y no se versionan.

## Documentos de referencia

- [`docs/PROJECT_PLAN.md`](docs/PROJECT_PLAN.md): visión, mundo, producto y dirección general.
- [`docs/GAMEPLAY_RULES.md`](docs/GAMEPLAY_RULES.md): reglas canónicas e invariantes de gameplay.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): límites y flujo de la arquitectura técnica.
- [`docs/DEVELOPMENT_PHASES.md`](docs/DEVELOPMENT_PHASES.md): fases, alcance y criterios de aceptación del MVP.
- [`docs/PHASE_0_PLAN.md`](docs/PHASE_0_PLAN.md): backlog operativo y gate de la fase de fundación.
- [`docs/ADR/0002-test-framework.md`](docs/ADR/0002-test-framework.md): selección y límites de GdUnit4.
- [`AGENTS.md`](AGENTS.md): contrato de trabajo para contribuciones asistidas.

## Principio rector

Anarchyball debe ser divertido como videojuego antes de depender de su tema. El protagonista puede responder a agresiones, proteger a terceros y participar en duelos consentidos, pero la iniciación ordinaria de fuerza no puede convertirse en una ruta jugable viable.
