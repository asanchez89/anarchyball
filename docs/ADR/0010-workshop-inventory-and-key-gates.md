# ADR-0010: inventario local y puertas con llave

- Estado: aceptado como parte de la ampliación de gameplay aprobada.

`RunEconomyDefinition` configura inventario, armas, premios, iconos, costes y
tienda por IDs estables. `RunInventory` contiene solo estado del intento y
`WorkshopEconomy` compone los servicios en LevelBuilder. No hay autoload ni
cartera monetaria externa. Sats son enteros ficticios; no hay tipos de cambio.

LevelSpec v0 añade el campo opcional `gates[].key_resource_id` cuando
`required_tag = mission_key`. Validator exige un pickup de tipo key. El builder
exige además un perfil económico que conecte ese pickup a la llave protegida.
Schema/validator anteriores conservan sus campos y comportamiento.

El contenedor de checkpoint v0 conserva su forma. `world_rule_state.inventory`
es un payload opcional con `version = 1`, stacks, sats y tokens de recompensa o
servicio. Un checkpoint anterior sin payload usa la reserva inicial; si está
después de una puerta nueva recibe la llave de compatibilidad para no atraparlo.
Las nuevas instancias de NPC usan el ID del placement, evitando colisiones entre
arquetipos repetidos. Los snapshots antiguos sin esa identidad conservan la
posición inicial de cada NPC, en lugar de copiar una posición ambigua.

El precio/consumo de munición no sustituye TargetValidity. Llaves y componentes
de misión no se venden. El servicio se paga una vez; el estado del pago y la
máquina se restauran junto al inventario. La reserva de emergencia solo existe
cuando ambas municiones están vacías, no tiene valor de venta ni otorga sats.

Incremento compatible: `world_rule_state.loot_drops` guarda por ID de pickup
disponibilidad y posición de los restos abandonados. Es opcional; los checkpoints
anteriores conservan sus pagos automáticos mediante tokens de encuentro y no
reciben otro lote físico. Inventario, actor y pickup se restauran juntos.

Extensión compatible de drops temporales: cada registro puede incluir
`remaining`, `expired` y `collected`. Si faltan, la migración local usa
duración completa, no expirado y los tokens de inventario anteriores.
No se guardan nodos ni relojes del sistema: el tiempo restante es de gameplay.
Un snapshot anterior a caducar puede recrear el drop con su tiempo restante;
uno posterior conserva un registro terminal y no lo resucita. Los nodos
recogidos/caducados se liberan; los registros pequeños permiten retry/save.

Animación de salida: el campo opcional `motion` guarda arco activo, tiempo
transcurrido, origen y destino como números compatibles con JSON. Un checkpoint
en vuelo continúa el arco sin repetir la recompensa; snapshots antiguos sin
`motion` conservan su posición y se consideran asentados.
