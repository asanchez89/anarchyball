# Phase 3 - Content Engine

- **Estado:** COMPLETADA Y APROBADA
- **Inicio:** 2026-09-08
- **Reglas afectadas:** `GR-ENCOUNTER-001`, `GR-ENCOUNTER-002`, `GR-ECON-001`, `GR-LEVEL-002` a `GR-LEVEL-005`, `GR-TELEM-001`

## Objetivo

Convertir el movimiento y combate aprobados en una plataforma de producción de contenido. Una especificación declarativa validada debe poder construir un nivel jugable sin modificar `PlayerController` ni introducir condiciones por clase, mundo o ideología en el núcleo.

## Contrato LevelSpec v0

El formato persistente es JSON y declara `schema_version: 0`. El schema de referencia vive en `data/levels/level_spec_v0.schema.json`.

Campos obligatorios:

- identidad estable del nivel;
- spawn, salida y límites;
- ruta al `PlayerMovementProfile` base;
- IDs de loadout y regla temática;
- plataformas con distinción requerida/opcional y `route_tags`;
- placements de encounters y recursos;
- secciones de telemetría.

Las definiciones reutilizables permanecen como `Resource`: `ClassLoadout`, `EnemyArchetype`, `EncounterDefinition` e `IdeologyRuleDefinition`. `ContentRegistry` rechaza IDs inválidos o duplicados y `LevelValidator` resuelve todas las referencias antes de construir el árbol.

## Pipeline implementado

```text
JSON LevelSpec v0
  -> LevelSpecLoader
  -> ContentRegistry + LevelValidator
  -> LevelBuilder
  -> escena jugable generada + telemetría local
```

El validador comprueba schema, IDs, referencias, recursos, ownership, spawn/salida, geometría, rutas opcionales, estructura de encounters y alcance conservador de la ruta requerida con el perfil base. Los errores incluyen archivo, campo, código y descripción; un spec inválido muestra el diagnóstico y no construye contenido parcial.

## Escena y fixtures

- `data/levels/phase3_content_preview.json`: borrador válido que alimenta la escena principal;
- `tests/fixtures/levels/impossible_gap_level.json`: ruta requerida intencionalmente imposible;
- `levels/prototypes/generated_level_preview.tscn`: host mínimo del builder;
- la sala manual de Phase 2 se conserva en `levels/prototypes/movement_debug_room.tscn`.

La ruta opcional declara `runner`; no es necesaria para completar el nivel. El encuentro se instancia desde catálogo y la regla ideológica modifica presentación mediante parámetros de datos.

## Telemetría local v0

`LocalRunTelemetry` registra en memoria y guarda al completar en `user://telemetry/latest_run.json`:

- carga y finalización del nivel;
- entrada/finalización de secciones;
- caída, derrota y retry al spawn;
- daño recibido;
- ruta opcional tomada;
- actor neutralizado/resolución del encounter;
- intento de efecto sobre objetivo inválido.

No existe backend ni envío remoto.

## Cobertura automatizada

- catálogo válido, IDs duplicados e IDs inestables;
- fixture válido;
- referencia desconocida con campo exacto;
- campo obligatorio ausente;
- salto imposible rechazado;
- construcción de player, ruta, encounter, salida, HUD y telemetría;
- variante visual alterada solo por datos;
- eventos soportados y rechazo de evento desconocido.

## Gate técnico

- [x] modificar una definición cambia la variante sin editar el player;
- [x] un ID desconocido falla con archivo y campo;
- [x] el salto imposible intencional es rechazado;
- [x] spawn y salida se conectan por movimiento base;
- [x] datos inválidos no producen un runtime parcial silencioso;
- [x] importación headless, smoke y suite automatizada;
- [x] playtest humano del nivel generado hasta `EXIT`;
- [x] confirmar que la ruta requerida es cómoda y la ruta `runner` se percibe como opcional;
- [x] revisar `user://telemetry/latest_run.json` tras completar una partida.

Playtest aprobado por el usuario el 2026-09-09. Phase 4 queda desbloqueada. Todo nivel generado continúa siendo borrador hasta playtest, conforme a `GR-LEVEL-005`.
