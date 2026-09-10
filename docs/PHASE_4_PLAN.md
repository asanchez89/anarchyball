# Phase 4 - MVP Vertical Slice

- **Estado:** COMPLETADA Y APROBADA
- **Inicio:** 2026-09-09
- **Reglas afectadas:** `GR-CORE-001` a `GR-CORE-010`, `GR-CONFLICT-001`, `GR-COMBAT-001/002`, `GR-WORLD-001/002`, `GR-ENCOUNTER-001/002`, `GR-BOSS-001` a `003`, `GR-RETRY-001`, `GR-ECON-001`, `GR-LEVEL-001` a `005`, `GR-TELEM-001`

## Objetivo

Ensamblar el núcleo aprobado en una experiencia completa y autocontenida de The Anarchist Frontier. El slice debe enseñar movimiento, target validity y defensa de terceros; aplicar una regla ideológica con counterplay; guardar un checkpoint; culminar en un mini-boss legítimo y permitir llegar a una conclusión mediante combate defensivo o evasión.

## Recorrido implementado

1. Introducción breve con objetivo y controles.
2. Desafío corto de plataformas con suministro no reclamado.
3. MerchantBall neutral y confiscadores que hacen observable la agresión contra un tercero.
4. Gate contractual: Contractor puede presentar credenciales con `F/X`; el bypass superior usa movimiento base.
5. Ruta elevada opcional `runner` y recompensa de misión explícita.
6. Checkpoint antes del encuentro final.
7. Checkpoint Commander y torreta hostil; el Commander telegrafía, comete agresión, adapta su patrón al 50% de Resolve y se rinde al agotarlo.
8. La salida permanece alcanzable para permitir `force_surrender` o `evade_checkpoint`.
9. Cierre breve, telemetría y guardado local.

## Sistemas cerrados en esta fase

- `ContractorDefensiveResponse` compuesto desde el `ClassLoadout`: al activarse una agresión válida aumenta temporalmente cadencia y efecto. No modifica permisos de target validity ni añade ramas al `PlayerController`.
- HUD de Health, arma, habilidad, objetivo, regla ideológica y Resolve del boss.
- feedback puntual `NOT AN AGGRESSOR`, telegraph visual, labels de estado y tonos sintéticos placeholder que no dependen solo del color.
- menú inicial y final, pausa y reinicio con teclado, mouse o acciones UI de gamepad.
- checkpoint con posición, Health baseline, estados/Resolve de actores, rewards recogidos y estado del gate.
- retry inmediato por caída o Health agotado, sin recargar escena ni repetir introducción.
- save local explícito `schema_version: 0` en `user://saves/vertical_slice.json`; telemetría separada en `user://telemetry/latest_run.json`.
- extensiones opcionales compatibles de `LevelSpec v0`: `slice`, `gates` y `checkpoints`.

## Cobertura automatizada

- round-trip y rechazo de versión desconocida del checkpoint;
- activación y reset de Defensive Response;
- validación y construcción del slice con Contractor, NPC, boss, gate, checkpoint y UI;
- restauración de `ConflictState` y Resolve al retry;
- contrato de legitimidad, adaptación y resoluciones del boss;
- cobertura previa de movimiento, dirección de disparo, target validity, contenido, LevelSpec y telemetría.

## Gate técnico

- [x] escena principal construida desde `mvp_vertical_slice.json`;
- [x] Contractor y Defensive Response observables;
- [x] neutral, defensa de tercero, dos enemigos y máquina hostil;
- [x] regla contractual explicada al primer uso y con dos counterplays;
- [x] checkpoint/save/retry versionados y reproducibles;
- [x] boss con legitimidad, telegraph, adaptación, Resolve y surrender;
- [x] dos resoluciones prácticas: combatir o evadir;
- [x] HUD, inicio, pausa, reinicio y cierre;
- [x] arte vectorial y tonos placeholder coherentes;
- [x] importación headless, smoke y suite automatizada;
- [x] un jugador nuevo completa el slice sin explicación externa;
- [x] duración aceptada mediante playtest manual;
- [x] lectura correcta de Neutral/Threatening/Aggressor/Surrendering aprobada manualmente;
- [x] retry desde checkpoint percibido como inmediato y sin pérdida injusta;
- [x] teclado/mouse y gamepad aprobados en hardware real.

Playtest aprobado por el usuario el 2026-09-09. Phase 5 queda autorizada.
