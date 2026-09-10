# ADR-0003: Elegibilidad ofensiva centralizada

- **Estado:** Aceptado
- **Fecha:** 2026-09-08

## Contexto

La no iniciación ordinaria de fuerza es una invariancia del protagonista, no una penalización opcional. Armas, proyectiles, drones y trampas futuras no pueden duplicar condiciones ni interpretar por separado el estado del objetivo.

## Decisión

- `EffectContext` declara tipo de efecto, origen y contexto de duelo.
- La identidad del origen conserva la autoridad raíz; un efecto indirecto del jugador sigue siendo del jugador.
- `TargetValidity.evaluate(source, target, context)` es la única función que decide permiso ofensivo.
- La decisión devuelve un `TargetPermission` explícito y observable, no solo un booleano.
- `EffectReceiverComponent` consulta esa autoridad antes de modificar Health o Resolve.
- Los balls se evalúan por `ConflictState` o duelo consentido; las máquinas por `DamagePermission`.
- `SURRENDERING` y `NEUTRALIZED` bloquean de inmediato.
- La implementación es una clase pura y componentes inyectados, no un autoload global.

## Consecuencias

- Todo efecto ofensivo nuevo debe construir un `EffectContext` y pasar por `EffectReceiverComponent`.
- El origen `INDIRECT` no concede permisos adicionales.
- Presentation puede observar la decisión, pero no reemplazarla.
- Agregar una excepción requiere un contexto explícito y tests; no se aceptan ramas por clase, enemigo, facción o mundo.
