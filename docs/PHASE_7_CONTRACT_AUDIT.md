# Phase 7.0 - Auditoría de contratos y brief inicial

- **Estado:** COMPLETADA
- **Fecha:** 2026-09-20
- **Alcance:** flujo mínimo de campaña y `w0_01_first_aggression`
- **Reglas afectadas:** `GR-WORLD-001/002`, `GR-LEVEL-001` a `GR-LEVEL-009`, `GR-ENCOUNTER-001/002`, `GR-TELEM-001/002` y reglas canónicas de conflicto

## Conclusión

El motor de Phase 6 puede construir el primer nivel de campaña sin reemplazar movimiento, combate, actores, target validity, encuentros, LevelSpec, validación ni telemetría base. P7.1 necesita cuatro extensiones acotadas y comprobables:

1. un shell local de campaña que cargue misiones registradas y reciba su finalización;
2. progreso versionado separado del snapshot de checkpoint, con checkpoints aislados por `level_id`;
3. autoridad de finalización que pueda bloquear `EXIT` mientras un encounter declarado como obligatorio siga abierto;
4. archivo de intentos reiniciados o abandonados para que completion rate no cuente únicamente éxitos.

No se justifica un autoload, un quest manager global, diálogo genérico, árbol RPG, hub completo ni una nueva versión incompatible de LevelSpec. La única extensión prevista para LevelSpec v0 es un campo opcional de obligatoriedad en placements de encounter; debe quedar registrada en un ADR antes de implementarse y actualizar schema, validator, fixtures y tests.

## Evidencia inspeccionada

- `project.godot` inicia directamente `occupancy_workshop_draft.tscn`;
- `LevelBuilder` construye una sola misión y emite `slice_completed()` sin identidad ni destino;
- `SliceFlowController` solo permite volver a jugar después de completar;
- `LocalSaveStore` escribe siempre `user://saves/vertical_slice.json` y ningún runtime consume `load_checkpoint()`;
- `LevelExitMarker` archiva `level_completed` inmediatamente al contacto, sin consultar objetivos;
- `EncounterRuntimeObserver` resuelve neutralización e interacción de regla, pero no gobierna la salida;
- `LocalRunTelemetry` archiva únicamente recorridos completados;
- LevelSpec v0 contiene geometría y placements, pero no orden de campaña ni progreso;
- `encounter_third_party_defense`, los arquetipos actuales y `TargetValidity` prueban la composición necesaria para defensa de terceros.

## Matriz de reutilización

| Capacidad | Estado | Decisión para P7.1 |
|---|---|---|
| `PlayerController` y movimiento | suficiente | reutilizar sin ramas de mundo o misión |
| input abstracto | suficiente | conservar acciones y bindings actuales |
| cámara, HUD y accesibilidad | suficiente para greybox | reutilizar y curar legibilidad durante playtest |
| `ConflictStateComponent` | suficiente | conservar `THREATENING -> AGGRESSOR -> SURRENDERING` |
| `TargetValidity` y efectos | suficiente | seguir como única autoridad ofensiva |
| composición de `CombatTarget` | suficiente con ajuste de timing | reutilizar escena y datos; no crear una jerarquía RobberBall |
| `EncounterDefinition` | suficiente para el brief | crear un encounter de campaña específico y usar resoluciones declaradas |
| `EncounterRuntimeObserver` | parcialmente suficiente | consultar su estado desde la nueva autoridad local de finalización |
| LevelSpec v0 | suficiente salvo objetivo obligatorio | añadir solo `encounters[].required_for_completion`, opcional y `false` por defecto |
| `LevelValidator` | suficiente como base | validar el nuevo boolean y referencias de la misión |
| `LevelBuilder` | suficiente como constructor | emitir identidad de nivel y delegar la decisión de salida |
| checkpoint runtime | suficiente dentro de una misión | conservar `RunCheckpointState`, cambiar almacenamiento a ruta por nivel y cargarlo al reanudar |
| progreso de campaña | inexistente | añadir estado y store pequeños, versionados y explícitos |
| navegación entre escenas | inexistente | añadir shell y controlador locales; no autoload |
| telemetría de nivel | suficiente para runs completados | añadir outcome y archivo de restart/abandon sin convertirlo en analytics online |
| perfiles/reportes | suficiente | crear perfil propio del candidato y aceptar schemas históricos al agregar outcome |

## Matriz funcional de World 0

Esta matriz fija la responsabilidad de cada misión sin convertir todavía sus ideas en APIs o datos registrados.

| Misión | Regla/decisión primaria | Beneficio o promesa | Coste o tensión | Counterplay principal | Dependencia de producción |
|---|---|---|---|---|---|
| `w0_01_first_aggression` | elegibilidad por agresión observable | defensa anticipable de uno mismo y terceros | no se puede usar fuerza contra Neutral/Threatening | leer telegraph, moverse, intervenir tras compromiso, forzar surrender | contratos actuales + gaps G7.0-01 a G7.0-05 |
| `w0_02_contract_bridge` | acuerdo de acceso y cumplimiento | acceso confiable a un puente/servicio | obligación aceptada, reputación y enforcement | cumplir, terminar acuerdo, salida o ruta alternativa | shell aprobado; auditar interacción contractual en P7.2 |
| `w0_03_occupancy_workshop` | occupancy and use | maquinaria abandonada vuelve a producir acceso | uso actual excluye uso simultáneo y puede generar disputa | operar, esperar, negociar o usar bypass base | componentes de Phase 6; LevelSpec nuevo y perfil shipping propio |
| `w0_04_claim_and_access` | apropiación con externalidad espacial | control estable de un recurso reclamado | el claim afecta una ruta usada por terceros | easement, fee, compensación, abandono o ruta alternativa | lecciones de contrato y exclusión de P7.2-P7.3 |
| `w0_05_hierarchy_without_titles` | influencia informal y disponibilidad de salida | coordinación social y work crew eficiente | concentración de influencia o autoridad que impide abandonar | rotación, facilitación distribuida, opt-out, salida y defensa ante detención | contratos previos + gap de influencia auditado solo al iniciar P7.5 |
| `w0_06_common_pool` | mutual aid con recurso común finito | resiliencia, soporte y reemplazo de roles | no alcanza para alimentar simultáneamente todos los sistemas | repriorizar pool, alterar red de soporte y duelo voluntario | voluntary duel existente + sistema CommonPool auditado en P7.6 |
| `w0_07_leviathan_escape` | incursión que reclama jurisdicción sobre asociaciones | cooperación entre capacidades ya aprendidas | presión externa sobre grupos distintos | mutual aid, maquinaria, escape, traversal y defensa de terceros | solo después de que P7.1-P7.6 estén jugables y curadas |

## Gaps comprobados y contrato mínimo

### G7.0-01 - Entrada y navegación de campaña

Problema: la escena principal es un prototipo y no existe propietario de la transición entre misiones.

Contrato propuesto:

- `WorldDefinition`, un `Resource` tipado con `world_id` y una lista ordenada de misiones instaladas;
- `CampaignMissionDefinition`, un `Resource` tipado con `mission_id`, nombre visible y `PackedScene` de la misión;
- `CampaignFlowController`, local a `campaign_shell.tscn`, que muestra misiones disponibles, instancia una misión y vuelve al shell al finalizar;
- inicialmente se registra solo `w0_01_first_aggression`; las misiones futuras no apuntan a escenas inexistentes.

La lógica de desbloqueo se prueba en P7.1 con una lista sintética de dos misiones, pero la transición real hacia `w0_02_contract_bridge` se integra en P7.2 cuando esa escena exista.

### G7.0-02 - Progreso y checkpoint tienen ciclos distintos

Problema: `LocalSaveStore.DEFAULT_PATH` es único, se sobrescribe entre niveles y nunca se carga. Un checkpoint de intento no equivale al progreso de campaña.

Contrato propuesto:

- `CampaignProgressState` schema v0: `world_id`, `active_mission_id` y `completed_mission_ids`;
- `CampaignProgressStore`: `user://saves/campaign_v0.json`;
- checkpoints por misión: `user://saves/checkpoints/<level_id>.json`;
- Nueva partida comienza `w0_01_first_aggression` sin checkpoint previo;
- Continuar abre `active_mission_id` y restaura su checkpoint si es válido;
- completar marca la misión una sola vez; replay comienza limpio salvo elección explícita de continuar intento.

No se serializa el árbol ni se introduce inventario, XP, equipo o múltiples slots.

### G7.0-03 - `EXIT` no puede ser la única autoridad

Problema: `LevelExitMarker` registra éxito y archiva la corrida antes de que otra capa pueda comprobar el objetivo. Esto permitiría abandonar a MerchantBall y aun completar la misión.

Contrato propuesto:

- `LevelExitMarker` solicita finalización; no decide ni guarda por sí mismo;
- `LevelBuilder` centraliza la decisión local usando los observers que él mismo construyó;
- `encounters[].required_for_completion` declara qué placements bloquean salida;
- `false` por defecto conserva los prototipos existentes;
- si falta una resolución obligatoria, `EXIT` permanece disponible visualmente pero muestra feedback accionable;
- al aprobar, el orden es: registrar `level_completed`, archivar run, emitir `level_completed(level_id)`, mostrar resumen;
- al confirmar continuar, emitir `completion_continue_requested(level_id)` para que el shell cambie de escena.

P7.1 requiere un ADR antes de extender LevelSpec v0. No se agregan campos de campaña, targets editoriales ni lógica arbitraria al spec.

### G7.0-04 - Completion rate no observa intentos fallidos

Problema: `user://telemetry/runs/` recibe solo finalizaciones. El reporte puede mostrar 100 % aunque existan muchos reinicios o abandonos.

Contrato propuesto:

- cada snapshot archivado declara `run_outcome`: `completed`, `restarted` o `abandoned`;
- completar, reiniciar desde el menú y volver al shell archivan exactamente una vez;
- los retries de checkpoint permanecen dentro de la misma corrida;
- el agregador acepta runs históricos sin outcome e infiere `completed` por su evento final;
- cierre forzado del proceso permanece como limitación conocida; no se construye recuperación transaccional en P7.1.

No se añaden eventos de campaña a la telemetría en P7.1: `level_loaded`, `level_completed`, `encounter_resolved`, `retry` e `invalid_target_attempt` ya cubren las preguntas de diseño. El progreso local no es telemetría.

### G7.0-05 - Debe existir ventana entre agresión e impacto

Problema: el comportamiento `attack_third_party` confirma la agresión y aplica el efecto al actor protegido en la misma actualización. El estado es correcto, pero el jugador no dispone de una ventana real entre compromiso e impacto.

Contrato propuesto:

- conservar el telegraph previo como `THREATENING` no atacable;
- al ejecutar la confiscación, pasar a `AGGRESSOR` y mostrar una línea/anticipación breve;
- aplicar el primer efecto después de una ventana ajustable y comprobada;
- permitir que el jugador responda durante esa ventana sin exigir que MerchantBall reciba primero;
- cubrir orden de estado, señal e impacto con una prueba determinista.

El ajuste pertenece al comportamiento reusable y no se condiciona por RobberBall o World 0.

## IDs reservados

Los siete IDs de nivel quedan fijados por el paquete de `PROJECT_PLAN.md` §12.8. Los IDs de reglas, actores y encounters futuros se decidirán en el brief de su subfase para evitar contratos prematuros. P7.0 reserva además los siguientes IDs del único contenido activo, P7.1; se registrarán únicamente cuando sus datos existan:

| Tipo | ID |
|---|---|
| mundo | `world_00_anarchist_frontier` |
| misión/nivel | `w0_01_first_aggression` |
| actor | `enemy_robber_confiscator` |
| encounter | `encounter_first_aggression` |
| placement | `encounter_merchant_robbery` |
| checkpoint | `checkpoint_before_confiscation` |
| reward | `pickup_merchant_thanks` |

`npc_merchant_neutral`, `class_contractor`, el perfil de movimiento, la escena compuesta de actor y los contratos de conflicto se reutilizan. La misión no declara una `IdeologyRuleDefinition`: su regla primaria es la elegibilidad por agresión que funda el tutorial de World 0.

## Brief de `w0_01_first_aggression`

### Intención

Enseñar que el jugador puede prepararse ante una amenaza y responder cuando el acto de agresión se compromete, sin atacar a actores neutrales ni esperar pasivamente el primer daño. MerchantBall permanece neutral durante todo el encounter. RobberBall no es hostil por identidad: su confiscación observable produce la transición.

### Perfil de producción

| Campo | Target |
|---|---:|
| clasificación | `short_mission` |
| lifecycle inicial | `generated_draft` |
| primera vuelta | 360-480 s |
| repetición limpia | 120-240 s |
| completionist | 420-600 s |
| ruta efectiva | 7-11 pantallas |
| intervalo de checkpoint | 150-300 s |
| checkpoints | 1 |
| encounters sustanciales | 1 |

La primera vuelta puede llegar a ocho minutos por onboarding. La repetición debe sentirse como misión corta y no se alarga para imitar una misión estándar.

### Objetivo visible

`Protege a MerchantBall cuando la confiscación se convierta en agresión, fuerza la rendición de RobberBall y alcanza la salida.`

### Cinco beats

| Beat | Experiencia | Evidencia |
|---|---|---|
| introducir | movimiento base, salto, cámara y lectura de MerchantBall neutral | el jugador llega sin ayuda externa al primer descanso |
| demostrar | aim y bloqueo de objetivo neutral; RobberBall anuncia la confiscación como `THREATENING` | MerchantBall sigue inválido y los intentos se registran sin castigo moral global |
| desafiar | RobberBall ejecuta la confiscación, pasa a `AGGRESSOR` antes del impacto y comienza el encounter | razón `FORCED_CONFISCATION` visible y ventana defensiva real |
| combinar | defender mientras se usa traversal corto, cobertura y Contractor Defensive Response | movimiento y conflicto se resuelven con la misma autoridad de target validity |
| culminar | RobberBall entra en surrender, el encounter se resuelve y la ruta a `EXIT` queda validada | no se aplica fuerza durante surrender y la finalización exige resolución |

### Geometría y pacing

- cinco secciones legibles, sin corredores vacíos usados como duración;
- dos desafíos de plataformas con propósitos distintos: onboarding y cobertura/movilidad durante defensa;
- un checkpoint antes de la confiscación, aproximadamente tras 2.5-4 minutos de primera vuelta;
- reward de misión sobre la ruta base después de resolver el encounter;
- salida visible durante el cierre, pero bloqueada de forma explicable mientras el encounter obligatorio siga abierto;
- sin rutas que requieran clases posteriores y sin diálogo no interactivo largo.

### Encounter

`encounter_first_aggression` tendrá:

- actor protegido: `npc_merchant_neutral`;
- enemigo: `enemy_robber_confiscator`;
- estado inicial neutral y telegraph `THREATENING`;
- razón de agresión: `FORCED_CONFISCATION`;
- resolución obligatoria inicial: `force_robber_surrender`;
- fracaso de intento: derrota del jugador; el checkpoint permite retry rápido;
- sin resolución ofensiva antes del compromiso y sin premio letal.

No se reutiliza directamente `encounter_third_party_defense`: se reutilizan sus contratos y componentes, mientras la definición nueva mantiene el tutorial con un solo RobberBall y una resolución inequívoca.

## Criterios de aceptación de P7.1

### Automatizados

- `WorldDefinition` rechaza IDs duplicados, orden vacío y escenas inexistentes;
- progreso de campaña round-trip, rechazo de schema desconocido y desbloqueo determinista;
- checkpoints de dos niveles no colisionan;
- LevelSpec rechaza tipo inválido en `required_for_completion`;
- un encounter obligatorio abierto bloquea finalización y uno resuelto la permite;
- RobberBall se vuelve Aggressor antes de aplicar el primer efecto a MerchantBall;
- Neutral, Threatening y Surrendering conservan las decisiones canónicas de target validity;
- restart/abandon/completed producen un único archivo con outcome correcto;
- batch validation, importación, smoke, suite, runtime y build Windows pasan.

### Humanas

- un jugador nuevo identifica MerchantBall como neutral y RobberBall como válido solo después del compromiso;
- teclado y gamepad completan la ruta base con Contractor;
- el checkpoint reanuda el encounter sin estado fantasma;
- salir antes de resolver comunica qué falta y no crea softlock;
- tres `first_clear` y tres `clean_replay` quedan archivadas antes de promoción;
- duración proviene de movimiento, lectura y defensa, no de espera o exposición.

## Decisiones diferidas

- transición real a `w0_02_contract_bridge`, hasta que P7.2 registre una escena válida;
- hub, mapa del Political Compass y The Agora;
- branching, múltiples slots de guardado y selección de clase;
- diálogos, cinematics o quest scripting genéricos;
- encounters opcionales con resolución al cruzar `EXIT`; se diseñarán cuando una misión activa los necesite;
- reglas de contratos, occupancy de campaña, claims, influencia social y CommonPool.

## Resultado de P7.0

P7.1 puede comenzar sin tocar sistemas futuros. Sus cambios se limitan al shell de campaña, progreso/checkpoints, finalización declarativa, outcome de telemetría, timing defensivo y el contenido nuevo de `w0_01_first_aggression`.
