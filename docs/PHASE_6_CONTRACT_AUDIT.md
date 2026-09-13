# Phase 6.1 - Auditoría de contratos

- **Estado:** COMPLETADA
- **Fecha:** 2026-09-12
- **Alcance:** contratos necesarios para `rule_occupancy_and_use`, `enemy_occupancy_enforcer`, `encounter_occupancy_dispute` y `occupancy_workshop_draft`
- **Reglas revisadas:** `GR-CORE-001` a `GR-CORE-008`, `GR-CONFLICT-001`, `GR-COMBAT-001/002`, `GR-ENCOUNTER-001/002`, `GR-WORLD-001/002`, `GR-LEVEL-001` a `GR-LEVEL-005`, `GR-RETRY-001`, `GR-TELEM-001`

## Conclusión

El núcleo aprobado soporta sin cambios el movimiento base, los estados `DISPUTED -> THREATENING -> AGGRESSOR`, la elegibilidad ofensiva, Resolve/surrender, los IDs de contenido, la composición de arquetipos, las rutas etiquetadas y la telemetría general de una partida.

El experimento de occupancy and use no cabe por completo en los contratos actuales. Hace falta representar un objeto de regla con estado, conectarlo a geometría declarada, persistirlo en checkpoint y registrar su interacción. También hace falta que un arquetipo declare la razón de agresión y que el runtime identifique cuál resolución declarada cerró un encounter.

Estas capacidades se implementarán como extensiones pequeñas y tipadas. No se creará un autoload, un event bus, un intérprete de scripts ni una rama por ideología dentro de `PlayerController`.

## Mapa de capacidades

| Necesidad | Contrato existente | Resultado de auditoría |
|---|---|---|
| IDs y referencias estables | `ContentDefinition`, `ContentCatalog`, `ContentRegistry` | Reutilizable sin cambios conceptuales |
| Regla ideológica declarativa | `IdeologyRuleDefinition` con `hook_id`, parámetros y counterplay | Parcial: almacena datos, pero el hook no se valida ni materializa |
| Disputa sin permiso ofensivo | `ConflictStateComponent.DISPUTED` y `TargetValidity` | Reutilizable; no se cambia la regla de combate |
| Telegraph y agresión posterior | `begin_threatening()` y `commit_aggression()` | Reutilizable; falta elegir la razón desde el arquetipo |
| Enemigo compuesto | `EnemyArchetype` + `combat_target.tscn` | Reutilizable para el primer enforcer; no requiere escena nueva |
| Dos resoluciones declaradas | `EncounterDefinition.allowed_resolutions` | Parcial: el runtime no determina ni emite el ID de resolución |
| Ruta base y alternativa | plataformas `required`, `route_tags` y `LevelValidator` | Reutilizable; Contractor debe completar la ruta requerida |
| Máquina que transforma ruta | `AccessGate` y `DebugPlatform` | No cubierto: el gate solo abre su propia colisión y está especializado en contrato |
| Persistencia de la regla | `RunCheckpointState.world_rule_state` | El contenedor sirve; captura/restauración solo reconoce `AccessGate` |
| Observabilidad | `LocalRunTelemetry` | Parcial: faltan cambios de estado de la regla y resolución explícita |
| Validación de un nivel | `LevelSpecLoader` + `LevelValidator` | Reutilizable por archivo; no existe validación por lote |
| Schema estricto | `level_spec_v0.schema.json` | Solo documenta la forma; el loader runtime no aplica JSON Schema ni rechaza todo campo desconocido |

## Gaps comprobados y decisión mínima

### P6-G01 - Hook de regla sin contrato runtime

`IdeologyRuleDefinition.hook_id` acepta cualquier ID no vacío. `LevelBuilder` utiliza la regla únicamente para color, etiqueta y validación de gates; no existe una lista de hooks soportados ni un objeto que consuma el hook.

Decisión:

- P6.2 centralizará los IDs de hook soportados y el validador rechazará uno desconocido;
- P6.3 añadirá solo el hook `occupancy_machine`;
- el hook representa una capacidad técnica, no el nombre de un mundo o facción.

### P6-G02 - LevelSpec no representa objetos de regla stateful

LevelSpec v0 contiene plataformas, gates, encounters, recursos y checkpoints, pero no puede declarar una máquina que cambie otras piezas del nivel.

Decisión:

- añadir a v0 un campo opcional y compatible `rule_objects`;
- cada entrada tendrá forma cerrada: `id`, `hook_id`, posición, `initial_state`, `target_platform_ids` y `interaction_tag`;
- no se aceptarán scripts, métodos, expresiones ni parámetros ejecutables desde JSON;
- `hook_id` deberá coincidir con la regla activa y los targets deberán referenciar plataformas existentes.

Agregar un campo opcional mantiene compatibilidad con los LevelSpecs v0 existentes. Si durante P6.2 se descubre una incompatibilidad real, se detendrá el trabajo y se propondrá una migración versionada.

### P6-G03 - Falta un objeto de maquinaria reutilizable

`AccessGate` alterna su propia colisión y contiene presentación específica de contrato. `DebugPlatform` no expone activación. Reutilizarlos para occupancy and use mezclaría dos mecánicas distintas.

Decisión:

- P6.3 creará un `RuleStateObject` local y componible, no global;
- estados mínimos: `INACTIVE`, `AVAILABLE`, `OCCUPIED` y `DISABLED`;
- la interacción usará la acción abstracta `interact`;
- el objeto emitirá un cambio de estado y habilitará/deshabilitará únicamente las plataformas listadas por ID;
- tendrá texto y símbolo además de color;
- se probará con dos colocaciones reales: una demostración segura y la máquina disputada.

No se diseñará un sistema universal de electricidad, crafting o automatización.

### P6-G04 - Razón de agresión codificada por comportamiento

`CombatTarget.apply_archetype()` traduce `behavior_id`, pero `CombatTarget` elige `ATTACK_COMMITTED` o `THIRD_PARTY_AGGRESSION` internamente. Esto impide declarar que el enforcer se vuelve agresor al ejecutar una expulsión/detención observable.

Decisión:

- añadir `aggressor_reason` a `EnemyArchetype`;
- los comportamientos activos exigirán una razón distinta de `NONE`;
- `enemy_occupancy_enforcer` comenzará en `DISPUTED`, podrá pasar por `THREATENING` y solo será atacable después de comprometer `DETAIN_ORDER_EXECUTED`;
- `TargetValidity`, armas y `PlayerController` no cambian.

### P6-G05 - Encounter declarativo sin resolución runtime explícita

`EncounterDefinition` enumera resoluciones, pero hoy la telemetría registra la neutralización de un actor sin `encounter_id` ni `resolution`. Un bypass tampoco cierra un runtime de encounter.

Decisión:

- P6.4 añadirá un observador local por encounter construido por `LevelBuilder`;
- observará actores y rule objects ya declarados;
- emitirá una sola resolución perteneciente a `allowed_resolutions`;
- para el experimento se usarán `neutralize_enforcer` y `operate_or_bypass_machine`;
- no se construirá todavía un quest manager global.

### P6-G06 - Checkpoint especializado en AccessGate

`RunCheckpointState.world_rule_state` ya puede guardar datos explícitos, pero `LevelBuilder` solo captura y restaura `AccessGate`.

Decisión:

- conservar `world_rule_state` y su schema actual;
- capturar el estado de cada `RuleStateObject` por ID estable;
- restaurarlo directamente junto con gates, actores y rewards;
- no crear un servicio global de guardado.

### P6-G07 - Telemetría insuficiente para evaluar la regla

La telemetría existente cubre secciones, retries, daño, rutas, target validity, derrota y finalización. No distingue cambios de la máquina ni la resolución concreta del encounter.

Decisión:

- añadir el evento `rule_state_changed`;
- normalizar `encounter_resolved` con `encounter_id` y `resolution`;
- conservar `route_taken` para el bypass y las rutas alternativas;
- no enviar datos fuera de la máquina.

### P6-G08 - Validación aislada e incompleta

No existe un comando que valide catálogo y varios LevelSpecs en una sola ejecución. Además, el catálogo solo comprueba identidad/duplicados al registrarse, las definiciones no referenciadas pueden escapar de validación estructural y no se comprueba unicidad de IDs locales entre todas las colecciones del nivel.

Decisión:

- P6.2 añadirá una entrada Godot headless para auditoría por lote;
- validará estructura de todas las definiciones del catálogo, hooks soportados, referencias de `rule_objects`, IDs locales duplicados y archivos seleccionados;
- cada error conservará archivo, campo, código y causa;
- los tests unitarios seguirán cubriendo cada regla determinista; el batch no sustituye la suite.

## Contratos que quedan congelados

Durante Phase 6 no se permite modificar estas invariantes para acomodar contenido:

- `TargetValidity` sigue siendo la única autoridad ofensiva;
- `SURRENDERING` y `NEUTRALIZED` bloquean fuerza inmediatamente;
- una disputa de occupancy and use comienza como `DISPUTED`, no como permiso de ataque;
- la ruta requerida usa Contractor y movimiento base;
- las rutas opcionales se declaran mediante tags;
- LevelSpec no ejecuta código arbitrario;
- el contenido generado continúa siendo draft hasta aprobación humana.

## Criterios de aceptación fijados antes del contenido

1. La primera máquina segura enseña `AVAILABLE -> OCCUPIED` sin combate.
2. El cambio de estado altera una plataforma o acceso de forma visible, textual y reversible por checkpoint.
3. La máquina disputada no convierte automáticamente a ninguna ball en Aggressor.
4. El enforcer empieza `DISPUTED`; su intento observable de detención pasa por `THREATENING` y luego `AGGRESSOR` con `DETAIN_ORDER_EXECUTED`.
5. Antes de la agresión, dispararle produce `BLOCK_DISPUTED`; después, la defensa es válida.
6. Surrender o neutralización bloquean inmediatamente nuevos efectos ofensivos.
7. El encounter registra exactamente una de sus resoluciones declaradas.
8. La salida es alcanzable con Contractor por movimiento base, aunque no se use la máquina disputada.
9. Retry restaura actores, rewards y estado de las máquinas al snapshot del checkpoint.
10. Añadir regla, enemigo, encounter y nivel no modifica `PlayerController`, armas ni `TargetValidity`.

## Contrato de telemetría para el experimento

| Evento | Payload mínimo | Pregunta de diseño |
|---|---|---|
| `section_entered` / `section_completed` | `section_id` | ¿Dónde se atasca el jugador? |
| `rule_state_changed` | `rule_id`, `object_id`, `from_state`, `to_state`, `interaction_tag` | ¿Se descubre y comprende la máquina? |
| `route_taken` | `route_tags` | ¿Se opera la máquina o se elige bypass? |
| `invalid_target_attempt` | `target_id`, `decision` | ¿La disputa se comunica antes del combate? |
| `encounter_resolved` | `encounter_id`, `resolution` | ¿Qué resolución se utilizó? |
| `damage_received` | `amount`, `position` | ¿Existe un pico accidental? |
| `checkpoint_used` / `retry` / `defeat` | IDs, causa y posición | ¿El retry funciona y evita softlocks? |
| `level_completed` | sin datos obligatorios | ¿La ruta llega a conclusión? |

## Asignación a los siguientes bloques

| Bloque | Gaps que resuelve |
|---|---|
| P6.2 | G01, parte de G02 y G08: contratos cerrados, plantillas y validación por lote |
| P6.3 | G02, G03, G06 y G07: rule object, maquinaria, checkpoint y evento de estado |
| P6.4 | G04, G05 y normalización de `encounter_resolved` |
| P6.5 | integración de todos los contratos en `occupancy_workshop_draft` |

## Evidencia y límites

La auditoría inspeccionó las definiciones de contenido, catálogo/registro, LevelSpec v0, builder, validator, `CombatTarget`, conflicto/efectos, checkpoint y telemetría existentes. P6.1 no cambia gameplay ni datos, por lo que no requiere una nueva ejecución de Godot. Las 55 pruebas aprobadas al cierre de Phase 5 permanecen como baseline; P6.2 deberá ejecutar la suite completa al introducir código.
