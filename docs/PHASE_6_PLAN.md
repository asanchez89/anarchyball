# Phase 6 - Content Factory v1

- **Estado:** EN CURSO; P6.1-P6.5 IMPLEMENTADAS, P6.3-P6.5 PENDIENTES DE PLAYTEST HUMANO
- **Inicio:** 2026-09-12
- **Dependencia:** MVP aprobado en Phase 5
- **Reglas afectadas:** `GR-CORE-006` a `GR-CORE-008`, `GR-ENCOUNTER-001/002`, `GR-WORLD-001/002`, `GR-LEVEL-001` a `GR-LEVEL-005`, `GR-TELEM-001`

## Objetivo

Demostrar que el motor aprobado puede producir contenido nuevo de forma repetible, validada y observable sin añadir ramas por mundo, clase o enemigo al núcleo. La fase entrega una fábrica pequeña y comprobada, no World 0 completo.

La prueba vertical será un borrador inspirado en **MutualistBall: occupancy and use**: maquinaria sin uso cambia de operador, su activación transforma una ruta y el jugador debe entender exclusión, uso actual y counterplay mediante el espacio antes que mediante lore.

## Resultado jugable esperado

Un segundo nivel corto, provisionalmente `occupancy_workshop_draft`, debe permitir:

1. introducir una máquina inactiva y comunicar su estado;
2. demostrar cómo ocuparla o activarla cambia plataformas o acceso;
3. enfrentar un operador que solo adquiere legitimidad ofensiva mediante un acto observable;
4. resolver el encounter por neutralización defensiva o por interacción/bypass;
5. alcanzar la salida con Contractor y movimiento base;
6. registrar ruta, resolución, retries, daño e intentos contra objetivos inválidos.

## Entregables

### Plantillas y herramientas

- plantilla mínima de `IdeologyRuleDefinition` con parámetros, hooks y counterplay;
- plantilla mínima de `EnemyArchetype` y `EncounterDefinition` por composición;
- plantilla de LevelSpec v0 con secciones enseñar, demostrar, desafiar y combinar;
- auditoría por lote de catálogo y LevelSpecs con errores que indiquen archivo y campo;
- fixtures válidos e inválidos para referencias, geometría, rutas y rewards;
- documentación actualizada con el flujo exacto desde borrador hasta contenido curado.

### Contenido de prueba

- segunda regla `rule_occupancy_and_use`;
- componente o hook mínimo para maquinaria ocupable, solo si los contratos existentes no pueden expresarlo;
- nuevo arquetipo `enemy_occupancy_enforcer`, construido con escena y componentes reutilizables;
- encounter `encounter_occupancy_dispute` con agresión inspeccionable y dos resoluciones prácticas;
- segundo nivel `occupancy_workshop_draft.json` creado por datos;
- escena de preview generada por `LevelBuilder`, sin lógica específica dentro de `PlayerController`.

## Backlog propuesto

### P6.1 - Auditoría de contratos

- [x] mapear qué parte del experimento cabe en los contratos actuales;
- [x] documentar únicamente los gaps comprobados;
- [x] definir criterios de aceptación y telemetría antes de crear contenido.

Resultado: [`PHASE_6_CONTRACT_AUDIT.md`](PHASE_6_CONTRACT_AUDIT.md). La auditoría conserva LevelSpec v0 y los contratos de combate, y asigna extensiones acotadas a P6.2-P6.4 antes de crear el segundo nivel.

### P6.2 - Plantillas y validación por lote

- [x] añadir plantillas copiables con IDs placeholder válidos;
- [x] crear una entrada headless que cargue catálogo y todos los LevelSpecs seleccionados;
- [x] fallar antes de runtime ante referencias, hooks o geometría inválidos;
- [x] añadir pruebas para cada diagnóstico nuevo.

Resultado: LevelSpec v0 acepta el campo opcional y cerrado `rule_objects`; los hooks soportados están centralizados; el validador rechaza campos desconocidos, referencias locales rotas, IDs duplicados y placements fuera de bounds; `ContentBatchValidator` audita el catálogo completo y todos los LevelSpecs descubiertos. `tools/phase6/validate_content.cmd` forma parte de `verify_all` y CI. Las plantillas viven en `templates/phase6/` y quedan excluidas del export.

Evidencia local del 2026-09-12: catálogo + 3 LevelSpecs válidos, importación y smoke aprobados, 12/12 suites y 64/64 pruebas sin errores.

### P6.3 - Regla de occupancy and use

- [x] implementar `rule_occupancy_and_use` como datos;
- [x] expresar activación, estado ocupado y counterplay mediante un hook acotado;
- [x] asegurar señal visual y textual no dependiente solo del color;
- [x] evitar condicionales por `level_id`, mundo o ideología en componentes core.

Resultado: el hook técnico `occupancy_machine` construye `RuleStateObject` con estados `INACTIVE`, `AVAILABLE`, `OCCUPIED` y `DISABLED`. `AVAILABLE -> OCCUPIED` usa la acción abstracta `interact`, habilita solo las plataformas referenciadas, emite `rule_state_changed` y conserva su estado en `world_rule_state`. La señal combina texto, símbolos, silueta y color. `phase6_occupancy_preview.json` presenta dos colocaciones reales y mantiene una ruta base en suelo.

Evidencia automatizada local del 2026-09-12: catálogo + 4 LevelSpecs válidos, importación y smoke aprobados, 13/13 suites y 68/68 pruebas sin errores. El playtest humano de teclado y gamepad sigue pendiente antes de considerar curada la mecánica.

#### Prueba manual de P6.3

Ejecutar `res://levels/prototypes/occupancy_rule_preview.tscn`. Con teclado y luego gamepad:

1. acercarse a `MACHINE_SAFE_USE` y confirmar que aparece `F / X: OCCUPY + OPERATE`;
2. interactuar y comprobar el cambio textual/simbólico `[○] AVAILABLE -> [◆] OCCUPIED`;
3. comprobar que la plataforma translúcida se vuelve sólida y permite apoyarse;
4. repetir con `MACHINE_DISPUTED_USE`;
5. recorrer el suelo hasta `EXIT` sin usar las máquinas para confirmar el bypass base;
6. reportar prompts ilegibles, activación a distancia, colisión tardía o cualquier softlock.

### P6.4 - Enemigo y encounter

- [x] componer `enemy_occupancy_enforcer` reutilizando conflicto, Resolve, efectos y comportamiento existentes;
- [x] declarar el evento que lo convierte en Aggressor;
- [x] ofrecer neutralización defensiva y bypass/interacción cuando sea práctico;
- [x] comprobar que surrender invalida el objetivo inmediatamente.

Resultado: `EnemyArchetype` declara ahora la razón de agresión, el texto de amenaza y el tiempo de telegraph. El nuevo enforcer comienza `DISPUTED`, anuncia una orden de detención en `THREATENING` y solo pasa a `AGGRESSOR` con `DETAIN_ORDER_EXECUTED`. `EncounterRuntimeObserver` permanece local a cada placement, observa sus actores y `rule_object_ids`, acepta únicamente resoluciones declaradas y emite una sola vez `encounter_resolved` con `encounter_id` y `resolution`. Operar la máquina antes de que se comprometa la agresión cierra el comportamiento pendiente; neutralizar al enforcer después de la agresión produce la resolución defensiva. No se modificaron `PlayerController`, armas ni `TargetValidity`.

Evidencia automatizada local del 2026-09-12: catálogo + 4 LevelSpecs válidos, importación, smoke y arranque headless de `occupancy_rule_preview.tscn` aprobados; 14/14 suites y 75/75 pruebas sin errores. El export Windows también fue generado correctamente. Falta el playtest humano con teclado y gamepad.

#### Prueba manual de P6.4

Ejecutar `res://levels/prototypes/occupancy_rule_preview.tscn`, una vez con teclado y otra con gamepad:

1. llegar a `MACHINE_DISPUTED_USE` y disparar al enforcer mientras muestra `[?] DISPUTED`; debe responder `BLOCK_DISPUTED` sin perder Resolve;
2. permanecer cerca hasta ver `[!] THREATENING` y `DETENTION ORDER: VACATE OR BE DETAINED`; un disparo durante este aviso todavía debe quedar bloqueado;
3. esperar a `[⚔] AGGRESSOR · DETAIN_ORDER_EXECUTED`, defenderse y reducir su Resolve;
4. agotar Resolve y comprobar que `SURRENDERING` bloquea nuevos efectos de inmediato y que solo se registra `neutralize_enforcer` al llegar a neutralización;
5. reiniciar y, como ruta alternativa, operar la máquina durante el aviso; debe aparecer `OPERATE_OR_BYPASS_MACHINE` y el enforcer debe cancelar el comportamiento ofensivo;
6. completar el nivel por el suelo sin depender de la plataforma opcional y reportar texto solapado, ventanas demasiado cortas, proyectiles injustos o softlocks.

### P6.5 - Segundo nivel data-driven

- [x] construir `occupancy_workshop_draft` desde LevelSpec;
- [x] validar ruta base, salida, recursos, encounter y secciones;
- [x] comprobar checkpoint/retry si el recorrido supera unos pocos minutos;
- [x] producir telemetría local comparable con el vertical slice.

Resultado: `occupancy_workshop_draft.json` compone un recorrido de 6.300 px con cinco secciones —enseñar, demostrar, defender, desafiar y combinar—, cinco máquinas, cinco plataformas opcionales, dos encounters, cuatro recursos y dos checkpoints. Seis plataformas de suelo forman la ruta requerida con movimiento base; la maquinaria añade rutas elevadas sin ser obligatoria. El nivel combina defensa de tercero y disputa de occupancy, y conserva los observers de encounter dentro del snapshot de checkpoint para permitir repetir una resolución después de retry.

Evidencia automatizada local del 2026-09-12: catálogo + 5 LevelSpecs válidos, importación, smoke y arranque headless de `occupancy_workshop_draft.tscn` aprobados; 15/15 suites y 81/81 pruebas sin errores. Se corrigió el sensor de collectibles para escuchar la capa física del jugador y se cubrió contacto, desaparición y señal de recolección. El export Windows incluye correctamente el nuevo nivel. El playtest humano determina todavía pacing, legibilidad y ausencia real de softlocks.

#### Prueba manual integral de P6.5

Ejecutar `res://levels/prototypes/occupancy_workshop_draft.tscn` con teclado y luego gamepad:

1. operar `MACHINE_SAFE_TEACH` y comprobar que materializa únicamente su plataforma elevada;
2. atravesar la segunda zona una vez por suelo y otra usando `MACHINE_ROUTE_DEMONSTRATION`, verificando que ambas rutas continúan disponibles;
3. en la defensa de MerchantBall, esperar la agresión contra tercero, neutralizar ambos agresores y alcanzar `CHECKPOINT_AFTER_DEFENSE`;
4. ante `MACHINE_DISPUTED_WORKSHOP`, disparar durante `DISPUTED` y `THREATENING` para confirmar bloqueo; luego operar la máquina durante la orden y confirmar `OPERATE_OR_BYPASS_MACHINE`;
5. caer antes del segundo checkpoint para volver al primero: la máquina disputada, el enforcer y el observer deben recuperar el snapshot sin conservar la resolución anterior;
6. repetir la disputa, esperar `DETAIN_ORDER_EXECUTED`, neutralizar al enforcer y confirmar `NEUTRALIZE_ENFORCER` y el bloqueo inmediato durante surrender;
7. recorrer la combinación final por suelo, probar la última máquina, recoger los cuatro recursos y llegar a `EXIT` sin softlock.

### P6.6 - Curación y cierre

- ejecutar importación, smoke y suite completa;
- realizar playtest con teclado y gamepad;
- corregir softlocks, legibilidad y pacing con evidencia;
- promover el borrador solo después de aprobación humana.

## Gate de salida

- [ ] la segunda regla cambia espacio o interacción y muestra counterplay antes del lore;
- [ ] el nuevo enemigo se registra por ID y se compone sin modificar `PlayerController`, armas ni `TargetValidity`;
- [ ] el encounter registra la razón de agresión y admite dos resoluciones cuando es práctico;
- [ ] el segundo nivel nace de LevelSpec, pasa validación y se construye headlessly;
- [ ] la ruta requerida se completa con Contractor y movimiento base;
- [ ] un lote con fixtures inválidos falla indicando archivo, campo y causa;
- [ ] telemetría registra las señales de diseño requeridas;
- [ ] suite completa, smoke e importación pasan;
- [ ] teclado y gamepad pasan playtest humano sin softlocks conocidos;
- [ ] ningún contenido se promueve a shipping sin curación humana.

## No objetivos

- construir World 0 completo;
- implementar Runner, Tinkerer, Trader o Agorist;
- crear The Agora, progresión RPG o economía persistente;
- cambiar LevelSpec de versión sin un gap incompatible comprobado;
- crear un editor visual genérico, scripting arbitrario o generación procedural infinita;
- producir arte, audio o narrativa final.

## Riesgos y controles

| Riesgo | Control |
|---|---|
| El hook de maquinaria se convierte en sistema genérico prematuro | implementar el componente más pequeño que satisfaga dos usos concretos del nivel |
| La nueva regla solo cambia texto | exigir transformación espacial/interactiva y counterplay observable |
| El enemigo introduce excepciones de NAP | conservar `TargetValidity` como única autoridad y probar transiciones |
| El nivel válido resulta aburrido o confuso | mantenerlo como draft hasta playtest y usar telemetría para pacing |
| Las plantillas duplican datos | referenciar Resources registrados por IDs estables |

## Orden de implementación

1. P6.1 Auditoría de contratos.
2. P6.2 Plantillas y validación por lote.
3. P6.3 Regla de occupancy and use.
4. P6.4 Enemigo y encounter.
5. P6.5 Segundo nivel data-driven.
6. P6.6 Curación y cierre.

No se inicia Phase 7 hasta superar este gate.
