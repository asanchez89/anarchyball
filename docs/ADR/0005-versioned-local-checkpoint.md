# ADR-0005: Checkpoint local explícito y versionado

- **Estado:** Aceptado
- **Fecha:** 2026-09-09

## Contexto

El vertical slice necesita retry rápido y persistencia mínima. Serializar el árbol de escena acoplaría el save a nombres y estructura interna, mientras que un manager global anticiparía necesidades que el MVP todavía no tiene.

## Decisión

- `RunCheckpointState` contiene únicamente datos de dominio necesarios para restaurar el intento.
- El formato incluye `schema_version`, `level_id`, checkpoint, posición, Health, estado de actores, rewards y estado de regla.
- `LocalSaveStore` escribe y lee JSON local sin autoload ni backend.
- El runtime conserva la instancia y restaura componentes directamente para que el retry sea inmediato.
- Una versión desconocida se rechaza; no se intenta interpretar silenciosamente.

## Consecuencias

- Cambiar la forma persistente exige migración o nueva versión.
- El checkpoint no guarda nodos, señales, timers ni recursos completos.
- El save del slice no equivale todavía a progresión RPG ni perfiles múltiples.
- Un futuro servicio global de saves deberá aparecer solo cuando existan al menos dos flujos navegables que lo necesiten.
