# Anarchyball: The Game

Base de desarrollo de un *action-platformer/shooter* 2D con progresión RPG ligera. El proyecto usa Godot 4.x estable y GDScript tipado, con una arquitectura orientada a composición, contenido data-driven y validación automatizada de niveles.

## Estado actual

El repositorio está en **Phase 0 - Foundation**. Incluye una escena de arranque mínima y la documentación necesaria para comenzar la implementación. Todavía no contiene gameplay del MVP.

## Empezar

Requisitos:

- Godot 4.x estable;
- Git;
- teclado y, para validar controles, un gamepad.

Abrir el editor:

```powershell
godot --editor --path .
```

Validar la importación sin interfaz:

```powershell
godot --headless --path . --editor --quit
```

El ejecutable puede llamarse de otra forma según la instalación local de Godot.

## Documentos de referencia

- [`docs/PROJECT_PLAN.md`](docs/PROJECT_PLAN.md): visión, mundo, producto y dirección general.
- [`docs/GAMEPLAY_RULES.md`](docs/GAMEPLAY_RULES.md): reglas canónicas e invariantes de gameplay.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): límites y flujo de la arquitectura técnica.
- [`docs/DEVELOPMENT_PHASES.md`](docs/DEVELOPMENT_PHASES.md): fases, alcance y criterios de aceptación del MVP.
- [`AGENTS.md`](AGENTS.md): contrato de trabajo para contribuciones asistidas.

## Principio rector

Anarchyball debe ser divertido como videojuego antes de depender de su tema. El protagonista puede responder a agresiones, proteger a terceros y participar en duelos consentidos, pero la iniciación ordinaria de fuerza no puede convertirse en una ruta jugable viable.

