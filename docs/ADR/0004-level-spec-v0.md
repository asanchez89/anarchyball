# ADR-0004: LevelSpec v0 separa definición reusable y composición de nivel

- **Estado:** Aceptado
- **Fecha:** 2026-09-08

## Contexto

El motor necesita producir variantes legibles en diff y validables antes de runtime, sin duplicar estadísticas, escenas ni reglas en cada nivel. El formato es persistente y condicionará herramientas y contenido futuro.

## Decisión

- Las definiciones reutilizables y tipadas viven en Godot `Resource` y se registran por ID estable.
- La composición espacial vive en JSON `LevelSpec` con `schema_version` explícita.
- `LevelSpec v0` describe referencias, placements y tags; no acepta scripts arbitrarios.
- Loader y validator terminan antes de que `LevelBuilder` materialice nodos.
- La ruta requerida se valida con el mismo `PlayerMovementProfile` usado por el jugador.
- Las rutas de clase son opcionales y se expresan con `route_tags`.
- Un error reporta origen, campo y código; el builder no crea una versión parcial.
- Los niveles generados son borradores y requieren playtest humano.

## Consecuencias

- Cambiar parámetros de una definición puede crear una variante sin editar el controlador del jugador.
- Una versión incompatible del formato exige incrementar `schema_version` y definir migración o rechazo explícito.
- El schema JSON documenta forma y tipos; `LevelValidator` conserva las comprobaciones semánticas de Godot, referencias y alcanzabilidad.
- El catálogo inicial es deliberadamente pequeño y se ampliará por contenido, no por ramas ideológicas dentro del núcleo.
