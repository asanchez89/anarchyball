# Anarchyball: The Game

Base de desarrollo de un *action-platformer/shooter* 2D con progresión RPG ligera. El proyecto usa Godot 4.x estable y GDScript tipado, con una arquitectura orientada a composición, contenido data-driven y validación automatizada de niveles.

## Estado actual

**MVP aprobado; Phase 6 - Content Factory v1 en curso.** P6.1 auditó los contratos, P6.2 añadió plantillas y validación por lote, y P6.3 incorpora la primera regla espacial stateful mediante `occupancy_machine`. El proyecto continúa siendo GDScript-only y no requiere backend.

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
2. validación por lote del catálogo y los LevelSpecs;
3. smoke test de la sala jugable;
4. suite GdUnit4.

También puede pasarse el binario explícitamente:

```powershell
.\tools\phase0\verify_all.cmd -GodotBinary "C:\ruta\a\godot_console.exe"
```

Los reportes quedan en `reports/` y no se versionan.

Generar el build Windows cuando estén instalados los export templates oficiales de Godot 4.6.3:

```powershell
.\tools\phase5\build_windows.cmd
```

El resultado queda en `builds/windows/` y no se versiona. CI publica esa carpeta como artefacto después de verificar su template mediante SHA-512.

## Documentos de referencia

- [`docs/PROJECT_PLAN.md`](docs/PROJECT_PLAN.md): visión, mundo, producto y dirección general.
- [`docs/GAMEPLAY_RULES.md`](docs/GAMEPLAY_RULES.md): reglas canónicas e invariantes de gameplay.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): límites y flujo de la arquitectura técnica.
- [`docs/DEVELOPMENT_PHASES.md`](docs/DEVELOPMENT_PHASES.md): fases, alcance y criterios de aceptación del MVP.
- [`docs/PHASE_0_PLAN.md`](docs/PHASE_0_PLAN.md): backlog operativo y gate de la fase de fundación.
- [`docs/PHASE_1_PLAN.md`](docs/PHASE_1_PLAN.md): alcance implementado, métricas y guion de playtest de movimiento.
- [`docs/PHASE_2_PLAN.md`](docs/PHASE_2_PLAN.md): núcleo ético, cobertura canónica y guion de validación de combate.
- [`docs/PHASE_3_PLAN.md`](docs/PHASE_3_PLAN.md): contrato de contenido, pipeline, telemetría y gate del Content Engine.
- [`docs/PHASE_4_PLAN.md`](docs/PHASE_4_PLAN.md): recorrido del slice, sistemas integrados y guion de aceptación humana.
- [`docs/PHASE_5_PLAN.md`](docs/PHASE_5_PLAN.md): hardening, accesibilidad, balance, build y gate final del MVP.
- [`docs/PHASE_6_PLAN.md`](docs/PHASE_6_PLAN.md): alcance, backlog y gate de la primera fábrica de contenido.
- [`docs/PHASE_6_CONTRACT_AUDIT.md`](docs/PHASE_6_CONTRACT_AUDIT.md): mapa de contratos, gaps y criterios fijados antes del nuevo contenido.
- [`docs/CONTENT_EXTENSION_GUIDE.md`](docs/CONTENT_EXTENSION_GUIDE.md): procedimiento para añadir contenido sin tocar el núcleo.
- [`docs/ADR/0005-versioned-local-checkpoint.md`](docs/ADR/0005-versioned-local-checkpoint.md): contrato de checkpoint/save local.
- [`docs/ADR/0004-level-spec-v0.md`](docs/ADR/0004-level-spec-v0.md): separación entre Resources reutilizables y composición JSON.
- [`docs/ADR/0003-centralized-target-validity.md`](docs/ADR/0003-centralized-target-validity.md): autoridad única para elegibilidad ofensiva.
- [`docs/ADR/0002-test-framework.md`](docs/ADR/0002-test-framework.md): selección y límites de GdUnit4.
- [`AGENTS.md`](AGENTS.md): contrato de trabajo para contribuciones asistidas.

## Principio rector

Anarchyball debe ser divertido como videojuego antes de depender de su tema. El protagonista puede responder a agresiones, proteger a terceros y participar en duelos consentidos, pero la iniciación ordinaria de fuerza no puede convertirse en una ruta jugable viable.
