# Arquitectura de Anarchyball

Inventario del taller: `RunInventory` pertenece al jugador y consume un
`RunEconomyDefinition` de la escena. `WorkshopEconomy` conecta recompensas y
servicios por IDs, sin ramas ideológicas ni autoload. Los efectos de ambas armas
siguen pasando por EffectReceiver/TargetValidity. Checkpoint guarda una instantánea
versionada bajo `world_rule_state.inventory`; snapshots antiguos sin esa clave
usan una reserva inicial de compatibilidad, sin duplicar pickups ya recogidos.

**Estado:** base arquitectónica v0.1  
**Motor:** Godot 4.x estable  
**Lenguaje:** GDScript tipado

Este documento fija límites técnicos. La visión vive en `PROJECT_PLAN.md`, las reglas canónicas de gameplay en `GAMEPLAY_RULES.md` y la secuencia de entrega en `DEVELOPMENT_PHASES.md`.

## 1. Objetivos

El motor de gameplay debe permitir añadir niveles, enemigos, clases y reglas ideológicas mediante datos y componentes, conservando cinco garantías:

1. movimiento ajustable y verificable;
2. una sola autoridad para conflicto y elegibilidad ofensiva;
3. actores construidos por composición;
4. contenido referenciado por IDs estables y validado antes de cargar;
5. niveles producibles como borradores estructurados y curables en Godot.

“Avanzado” significa extensible, observable y comprobable. No significa construir sistemas sin uso en el MVP.

## 2. Capas y dependencias

```text
Presentación (UI, audio, animación)
                |
Contenido (actores, encuentros, reglas, niveles)
                |
Gameplay reusable (movimiento, combate, interacción, clases)
                |
Contratos core (IDs, eventos de dominio, resultados, configuración)

Herramientas y tests -> pueden inspeccionar todas las capas
Datos              -> configuran contenido; no ejecutan reglas arbitrarias
```

Reglas:

- `core` no conoce actores, mundos ni UI;
- componentes reutilizables no conocen nombres de ideologías o niveles;
- contenido compone capacidades y datos, no duplica su lógica;
- presentación observa resultados, pero no decide target validity;
- herramientas usan los mismos contratos y perfiles que el runtime.

## 3. Núcleo de gameplay

### 3.1 Movimiento

`PlayerController` consume acciones abstractas y un `PlayerMovementProfile`. Coyote time, jump buffer, salto variable y métricas físicas se implementan una sola vez. El validador de niveles deriva alcance seguro del mismo perfil para evitar divergencias.

### 3.2 Conflicto y efectos

El flujo obligatorio es:

```text
Encounter event
  -> ConflictStateComponent cambia estado y registra la razón
  -> una acción crea EffectContext
  -> TargetValidity evalúa source + target + contexto
  -> EffectResolver aplica o bloquea el efecto
  -> presentación y telemetría observan el resultado
```

Ninguna arma, proyectil, trampa, drone o aliado contratado decide por sí mismo si un actor es atacable. `SURRENDERING` invalida el objetivo inmediatamente.

`EnemyArchetype.blocks_projectiles` controla únicamente la capa física de objetivo
de proyectiles. Operadores, mecánicos y reclamantes Mutualist la desactivan: los disparos los
atraviesan sin efecto ni feedback de impacto, conservando sensores de diálogo e
interacción. No concede permisos de daño ni cambia TargetValidity (ADR-0003,
GR-CONFLICT-001); no se deriva de nombres o afiliaciones en el código de combate.

### 3.3 Actores y clases

`BallCharacter` es una escena base visual y de integración. Sus capacidades se agregan mediante componentes. El jugador usa un único controller; `ClassLoadout` aporta habilidades, modificadores, equipo e interaction tags. Agregar una clase no debe requerir editar ramas por clase dentro del controller.

### 3.4 Encuentros y reglas de mundo

`EncounterDefinition` declara estados iniciales, triggers, objetivos, resoluciones y recompensas. Cada placement construido puede tener un `EncounterRuntimeObserver` local que relaciona sus actores y `rule_object_ids`, y emite como máximo una resolución declarada; no existe un quest manager global. Los placements opcionales `actors` materializan NPC de catálogo que existen en el mundo sin fingir que pertenecen a un encounter. `IdeologyRuleDefinition` configura hooks limitados sobre pickup, interacción, spawn o ambiente. Las reglas de mundo nunca aparecen como `if current_world == ...` en el player.

Los NPC neutrales o aliados pueden declarar líneas breves en su `EnemyArchetype`. `NpcDialogueBubble` presenta esas líneas en espacio de mundo, avanza mediante la acción abstracta `interact` y no modifica `ConflictState`, elegibilidad ofensiva ni resolución de encounters. El diálogo tutorial aporta contexto a una mecánica ya observable; no sustituye su implementación.

La presentación de World 0 centraliza su densidad de píxel y profundidad de superficie en `World0ArtMetrics`. El terreno, la decoración y los props pequeños de Warped usan escalas enteras y filtro nearest; ningún actor de presentación aplica escalas fraccionarias que produzcan píxeles desiguales. Los elementos de escenario sin función jugable se dibujan detrás del terreno. `WorldPropPlacement` ajusta todo prop apoyado a la superficie física de la plataforma bajo su coordenada horizontal; checkpoints, máquinas y futuros props grounded no dependen de offsets manuales. Los pickups que flotan conservan una política separada e intencional. `platforms[].art_style` separa semántica de ruta y presentación: `road` usa el pavimento principal, mientras `column_supported` usa el piso elevado de Warped y columnas continuas hasta el soporte inferior. `required` nunca decide qué arte estructural corresponde.

Las cuatro capas ambientales de World 0 usan `Parallax2D`: el cielo permanece casi fijo y montañas, árboles lejanos y árboles cercanos aumentan progresivamente su desplazamiento horizontal. La repetición corresponde al ancho escalado de cada textura y el desplazamiento vertical permanece unido a la cámara para no alterar la lectura de plataformas.

## 4. Motor de contenido

`InteractionBeacon` compone brillo pulsante y señal pixelada de tienda/checkpoint,
sin desplazar arte ni colisiones. El ATM conserva escala entera ×3; el checkpoint
conserva su huella y cuantiza detalles a la cuadrícula del terreno. Las señales
SHOP/CHECKPOINT permanecen visibles; el prompt comercial aparece en proximidad.
Aplica GR-LEVEL-002 sin cambiar interacción, pagos ni GR-RETRY-001.

Todo `RuleStateObject` compone automáticamente el mismo letrero: ACTIVATE para
activar, DOWN para llamadas de retorno del ascensor, ACTIVE tras operar y LOCKED
para estados no operables. Terminales de coordinación usan SWITCH y comercio
conserva SHOP mediante sobrescrituras de presentación por capacidad, no por ID.
El halo solo aparece si la acción está disponible; requisitos y restore actualizan
su estado sin alterar permisos. Los detalles se muestran al acercarse. Props
decorativos no reciben el componente. Nuevas máquinas heredan esta regla.

El pipeline de nivel será:

```text
LevelSpec JSON
  -> schema y referencias
  -> LevelValidator estático
  -> LevelBuilder
  -> escena de borrador jugable
  -> validación runtime y telemetría local
  -> ficha editorial externa + reporte de corridas
  -> decisión humana
      -> conservar como prototipo técnico, o
      -> curar como escena de shipping + LevelSpec conservado
```

El `LevelValidator` debe reutilizar perfiles reales de movimiento, registros de contenido y contratos de encounter. El formato tendrá versión explícita y migraciones cuando cambie de manera incompatible.

Las fichas de `data/level_profiles/` no son extensiones de `LevelSpec v0`. La telemetría archiva recorridos completos por `run_id`; el agregador deriva tiempos por sección/checkpoint y distancia recorrida sin convertir esas observaciones en reglas de gameplay. ADR-0006 define este límite.

## 5. Estado, guardado y servicios

En el MVP se permiten solo servicios con uso concreto:

- routing de escena si hay más de una escena navegable;
- guardado/checkpoint cuando exista el primer nivel;
- registro de datos al cargar contenido por ID;
- audio cuando haya assets que reproducir.

Un `EventBus` global no se crea por defecto. Las señales locales y dependencias inyectadas son preferibles. El save del MVP contiene versión de schema y datos explícitos; no serializa el árbol de nodos completo.

## 6. Observabilidad y errores

Debug builds deben poder mostrar o registrar:

- `ConflictState` y razón de transición;
- decisión de `TargetValidity`;
- estado y resolución del encounter;
- sección y checkpoint activos;
- IDs y referencias inválidas;
- métricas de alcance usadas por `LevelValidator`.

Un fallo de datos debe indicar archivo, ID y campo. No se toleran fallos silenciosos que produzcan encuentros incompletables.

## 7. Estrategia de pruebas

- lógica determinista fuera del árbol cuando sea práctico;
- pruebas unitarias para transición de estados, target validity y cálculos de movimiento;
- escenas de integración mínimas para proyectiles, NPC, surrender y checkpoints;
- fixtures LevelSpec válidos e intencionalmente imposibles;
- importación headless y arranque como smoke test;
- playtest humano obligatorio para movimiento, cámara, legibilidad y diversión.

## 8. Evolución

El avance del nivel compuesto configura `CrewCoordinationDefinition` mediante
Resource de escena: dos terminales, dos rutas independientes, alimentación y
encounter disruptor por IDs validados contra LevelSpec. `CrewCoordination` deriva
canales activos del suministro, agresión observada y asignaciones locales; no
modifica conflicto. Checkpoint serializa asignaciones con prefijo `crew:` y las
restaura después de actores y máquinas. No hay manager global ni nuevo formato
LevelSpec. La entrada de desarrollo del shell usa otro ID y no avanza la campaña.

La presentación industrial selecciona regiones de Warped a escala entera y
configura el mismo tileset para el arte de ascensores. `BallVisualDefinition`
admite atlas con columnas/filas declaradas y encuadre alpha optativo, con apoyo
visible fijo; las definiciones previas conservan 8×8 y 96px por celda.

Los controles de maquinaria admiten dependencias locales acíclicas (`requires`),
etiquetas/hints y llamadas de ascensor (`call_only`). Los observers pueden liberar
plataformas locales (`resolution_platform_ids`). Una definición debe habilitar
explícitamente `interaction_during_aggression` para resolver una salida bajo fuego;
no cambia ConflictState ni TargetValidity. Los ascensores usan AnimatableBody2D,
paradas y reinicio al restaurar checkpoint. El layout de scenery es exclusivamente
presentación: no controla colisión, legitimidad ni resolución.

Una abstracción nueva requiere dos usos reales o una invariancia crítica ya documentada. Una decisión que cambie stack, dependencias, formato persistente o una regla difícil de revertir se registra en `docs/ADR/`.
# Confrontaciones temporizadas del taller

`EncounterDefinition.ceasefire_challenge` compone un recurso opcional
`CeasefireChallengeDefinition`. `LevelBuilder` adjunta `CeasefireChallenge` al
observador, sin autoload ni decisiones por nombre de ideología. Modos genéricos:
fuego rotativo y persecución/contacto. `CombatTarget.externally_managed` evita dos
controladores de ataque simultáneos. Se mantiene `EffectReceiver`/`TargetValidity`.
El observador captura el estado del componente dentro de su snapshot existente.
Durante restore se suprimen los efectos de callbacks y se limpian proyectiles.
Los checkpoints de diseños previos requieren empezar el taller de nuevo.

`WorldLootDrops`, compuesto por `WorkshopEconomy`, materializa pickups inactivos
por ID estable de actor y los libera al neutralizarlo. Los perfiles económicos
seleccionan arquetipos y cantidades; no hay ramas ideológicas en combate.
`world_rule_state.loot_drops` es un payload opcional de disponibilidad/posición;
las recogidas usan los IDs del inventario. Sin payload, los tokens antiguos de
pago de encuentro evitan duplicar piezas ya acreditadas. `PlayerInventoryMenu`
consulta el inventario y perfiles existentes sin crear otro estado económico.

`DebugPickup` aplica un `PickupPresentationProfile` compartido: halo radial
aditivo pulsante, sin luces físicas por objeto. Todos los pickups heredan el
halo cuando están disponibles. El halo no mueve sprites, colisiones ni anclajes.
Solo `WorldLootDrops` configura duración y aviso desde RunEconomyDefinition.
El drop parpadea y muestra segundos restantes; pausa usa el árbol de gameplay.
Al recoger/caducar se elimina el Area2D y sus hijos; WorldLootDrops conserva
solo configuración y estado terminal para restaurar checkpoints. No hay
autoload, temporizador global ni recompensas al expirar (ADR-0010).

Al liberar loot, WorldLootDrops inicia un arco visual en DebugPickup desde la
posición de la ball hacia el punto cercano de apoyo. Duración (0.6 s), altura
(80 px) y espera de recogida (0.2 s) están en PickupPresentationProfile. Sprite,
aura y sensor se desplazan juntos; no es un proyectil ofensivo. El arco usa tiempo
de física, respeta pausa y se restaura en checkpoint. No cambia cantidades,
propiedad (GR-ECON-001/002), caducidad ni recompensas; conserva GR-RETRY-001.
Los pickups estáticos nunca llaman launch_drop y siguen disponibles de inmediato.

Audio de estados: CombatTarget traduce transiciones de conflicto a cues del
GameplayAudioProfile; restore_runtime_state suprime esos cues. GameplaySfxEmitter
agrupa avisos idénticos simultáneos mediante una ventana configurable por viewport,
sin afectar permisos, timers ni estado del encuentro. AccessGate separa
open_for_resolution (evento opened y animación) de restore_open (silencioso).
Desafíos, contratos y acceso por llave/tag comparten la apertura normal.
Reglas relacionadas: GR-CORE-005, GR-ENCOUNTER-001, GR-RETRY-001 y feedback §20.2;
no se modifica ninguna condición de agresión, rendición o apertura.

Coleccionables: set_art actualiza el sensor según el rectángulo alpha visible y
la escala final. set_pixel_grid_art adapta PNG de alta resolución a una cuadrícula
lógica con píxeles de mundo enteros, sin modificar el archivo original. El sensor
excluye aura y padding transparente; DebugPickup recoge tanto en body_entered
como durante un solapamiento activo (por ejemplo al habilitarse bajo el jugador).

GameplaySfxEmitter hereda Node2D para conservar la transformación del actor en
sus AudioStreamPlayer2D. Un Node intermedio rompía ese vínculo y situaba las
voces en el origen del mundo. Prueba gráfica de mezcla en
tools/audio/check_world_alerts.gd; offsets de volumen por cue en el perfil.

`CeasefireChallengeDefinition.collective_commitment` permite comprometer al
roster local completo tras el aviso; los disparos siguen por turnos. No cambia
TargetValidity. `enemy_positions` (ADR-0011) distribuye integrantes por alturas.
CombatTarget comparte `try_grounded_step` entre patrulla y persecución: rayos
de pared/apoyo, margen de borde y pasos barridos cortos impiden cruzar huecos.
El controlador externo decide cuándo ceder movimiento a la patrulla (Egoist
persigue dentro de su zona). Rendición/neutralización detienen el movimiento.

Retirada y retorno usan `BallTacticalMotor`, un CharacterBody2D local que mantiene
la colisión ofensiva en el Area2D del actor. Consulta apoyos activos, incluidos ascensores,
busca saltos balísticos alcanzables y rechaza arcos contra paredes/puertas;
la trayectoria se ejecuta con colisión física, nunca teletransporte. El origen
comparte los 24 px de apoyo de las balls. Las caídas ya iniciadas terminan incluso
si el encuentro se resuelve. Parámetros en CeasefireChallengeDefinition.
CeasefireChallenge conserva roles, destinos, repliegues usados, retorno, avisos
individuales y velocidades de salto en checkpoint. El retorno Egoist solo llama
`disengage_at_home` tras llegar físicamente; no concede rendición, loot ni cura.
`tactical_retreat` elige el camarada más alejado del jugador que ofrezca un
destino alcanzable en su apoyo activo. Se separa por `personal_space`, rechaza
actores/destinos reservados y exige `retreat_safety_gain`; no manda reemplazo.
Snapshots antiguos descartan el rol `relief`, pero completan cualquier salto
físico en curso. No se modifica el tiempo de tregua ni la zona de activación.
Reglas: GR-CONFLICT-001, GR-ENCOUNTER-001, GR-RETRY-001 y extensión táctica del
taller en GAMEPLAY_RULES. TargetValidity sigue siendo la única autoridad ofensiva.

Persecución vertical: el perfil Egoist alcanza 392 px de altura balística para
las pasarelas locales de 225–245 px y los montacargas. La separación entre
integrantes solo frena aproximaciones al mismo piso, no el acceso vertical.
El motor mantiene contacto de suelo para recibir velocidad de los ascensores.
Para regresar desde una pasarela unidireccional puede bajar a un apoyo válido
debajo: excluye únicamente esa pasarela hasta quedar por debajo, nunca paredes
ni plataformas sólidas. Checkpoint conserva el ID de esa excepción temporal.

La tienda separa Comprar/Vender; Vender filtra el
inventario actual a stacks comerciables positivos, permite elegir cantidad y
confirma antes de llamar a RunInventory.sell. Cancelar no cambia inventario;
tras vender refresca existencias/saldo y retira filas agotadas. Conserva
GR-ECON-002 y usa navegación ui estándar para teclado y mando.

Servicios Mutualist: las entradas de `machine_costs` abren confirmación antes
de descontar inventario. El modal muestra coste y existencias; cancelar conserva
los objetos. Confirmar revalida requisitos, paga una sola vez mediante el token
de servicio y activa la máquina con recibo en HUD. Usa el tema y navegación de
botones compartidos con la tienda. Conserva GR-ECON-002 y GR-RETRY-001; no añade
cobros a máquinas sin coste configurado ni cambia TargetValidity.

Saltos entre bloques sólidos: BallTacticalMotor prueba puntos alternativos de
despegue y aterrizaje cuando el arco preferido queda obstruido. Cada alternativa
respeta alcance balístico y consulta colisiones; no atraviesa paredes ni activa
plataformas. Un margen adicional de 4 px evita exigir un despegue exactamente
contra el lateral que rechaza la sonda de avance. Las pruebas cubren aterrizaje
diagonal sobre un bloque separado y persecución en `crew_return_a`, además de
pasarelas y retorno. Mantiene GR-ENCOUNTER-001 y GR-CONFLICT-001 sin cambios.

Feedback de robo: tras una transferencia efectiva de inventario en `try_contact`,
se instancia `TheftBurst` (escena configurable en el Resource del desafío) y se
reproduce el cue espacial `theft`. Las ondas pixeladas duran 0.42 s; las partículas
convergen desde la víctima hacia la posición del ladrón al contacto. No usa pose
de disparo, no se repite durante cooldown ni cuando se agota el cupo de robo.
El efecto hereda pausa y liberación del jugador, fija su posición mundial y se
autodestruye; no forma parte del estado persistente. No altera GR-CONFLICT-001,
GR-ENCOUNTER-001 ni las reglas de inventario de GAMEPLAY_RULES §19.
