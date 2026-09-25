# Nivel 1 — rediseño vertical aprobado

Estado: candidato implementado y validado automáticamente; pendiente de playtest humano. Sustituye la geometría lineal y las
descripciones de retirada sin cobertura de la iteración anterior.
No amplía alcance al jefe ni a un sistema de biografías.

## Estado actual — 24 de septiembre de 2026

Las tres partes tienen rutas verticales obligatorias, regresos permanentes,
compuertas de desafío, tres tiendas y nueve desvíos/reservas de exploración.
Se implementaron retirada con dos coberturas Ancom, cerco BlackAnarchy,
corredores anunciados LeftLibertarian y cargador de cuatro disparos del arma 1.
La arena conjunta anterior al jefe conserva las mecánicas por subgrupo.

La auditoría continua de parte 1 pasó en `reports/part_one_continuous_seventh.log`
(reporte 321): un solo posicionamiento inicial, recorrido hasta su salida y
regreso. Se retiró el apoyo redundante `platform_disputed_mill`, que solapaba
el descenso de producción con un desnivel de 5 px. La vuelta pasa por encima
de las repisas fijas de despacho y depósito, sin atravesarlas hacia abajo.
Los cuatro controles superiores de ascensor conservan su apoyo estando
apagadas las pasarelas; pruebas específicas verifican requisito y parada.

Validación final de esta iteración: `tools/phase0/verify_all.cmd` con Godot
4.6.3 pasó importación, validación de catálogo/9 LevelSpecs/5 perfiles,
arranque smoke y **298 tests en 33 suites**, sin fallos, omitidos ni huérfanos.
Evidencia: `reports/vertical_redesign_handoff_full.log` y
`reports/report_322/results.xml`. Incluye recorridos continuos de ida/vuelta
de las tres partes, regresos locales, puertas, llamadas de ascensor, combate,
proyectiles/coberturas, recarga, economía y persistencia. `git diff --check`
también pasó. No se realizó commit ni push.

Los apartados «Avance verificable» y las entradas posteriores son un historial
de validaciones parciales, no una lista acumulativa de tareas pendientes.
La navegación automatizada abre puertas y detiene IA; no certifica por sí sola
la experiencia de combate. El balance bajo fuego sostenido, la claridad de
señales/sonidos, duración y controles físicos requieren playtest humano.
El nivel continúa siendo un borrador jugable hasta superar ese playtest.
El arma rara permanece como propuesta separada; no se implementaron jefe ni
sistema biográfico. Los tres nichos de archivo son reservas editoriales con
suministros actuales, no coleccionables biográficos ficticios.

## Reglas de producción

- Ruta principal con ascenso y descenso reales en cada parte; tramos horizontales
  de descanso permitidos. No basta añadir terrazas opcionales a un suelo continuo.
- Cada máquina declara destino y beneficio: avance, recurso visible, atajo o
  ventaja táctica. Retirar mecanismos redundantes; no pagar por un callejón vacío.
- Arquitectura Warped industrial con soporte, coberturas físicas y aperturas
  que corten líneas de tiro largas. Sin muros invisibles ni invulnerabilidad por distancia.
- Desvíos cortos reconectan; el retorno usa movimiento base. Ascensores llamables
  desde ambos extremos. Cámara anticipa destino vertical; sin saltos a ciegas.
- Resolver encuentros sigue siendo obligatorio cuando se declara así; ninguna
  ruta elevada ni secreta evita la compuerta física correspondiente.
  La extensión vertical de su colisión se representa como un campo energético
  de la propia puerta Warped, con trama y pulso visibles; se apaga al abrirse.
- Tres ATM conservan inventario compartido y se sitúan en descansos protegidos.

## Trazado por bloques

Las alturas definitivas se validarán contra el perfil de movimiento real. Estos
bloques expresan conectividad obligatoria, no anchos que supuestamente prueben duración.

### Parte 1 — aprender el taller

1. Entrada policial en suelo amplio; ruta a nave de carga.
2. Ascenso obligatorio: montacargas con llamadas y escalones de retorno. Parada
   lateral visible de munición pesada; llegada arriba abre continuación.
3. Cruce de nave y descenso escalonado hasta tienda/checkpoint, destino visible.
4. Colectivo Ancom entre taller bajo y galería alta: retirada hacia refugio
   accesible; dos rutas de aproximación, sin disparar a todos desde la entrada.
5. Circuito Egoist: subir un lateral y bajar el opuesto, robo y devolución física.
6. Servicio Mutualist abre conexión transversal al siguiente bloque.

Desvíos: `p1_ammo_balcony`, `p1_salvage_underpass`.
El paso inferior del almacén entra desde el segundo escalón, desciende al
depósito de piezas bajo la nave y termina en una pared de soporte. Regresa
por un escalón propio; no conecta al otro lado de la nave ni evita la patrulla.
Secreto principal/reserva: `archive_niche_p1_office`, oficina superior con pista
ambiental y suministros provisionales. Sin autor asignado.

### Parte 2 — rodear y romper el cerco

1. Entrada policial y reserva; ascenso a pasarelas de montaje.
2. Presentación BlackAnarchy en circuito con dos accesos físicos a cada altura.
3. Servicio Mutualist abre pasarela transversal/cobertura útil, no tregua automática.

El servicio de montaje despliega `p2_maintenance_walkway` a 495 px entre
el último escalón de descenso y la cobertura de entrada al colectivo. Abre
también su compuerta mecánica existente, sin abrir la de combate. El pago
confirmado conecta esa ruta alta con una reserva visible de 40 balas ligeras;
el suelo sigue siendo el regreso alternativo. La pasarela no atraviesa el
colectivo ni evita su resolución. Pago, apoyo y recogida usan el checkpoint
existente; no se cobra de nuevo al volver ni se duplica la munición.

4. Ancom protege retirada entre dos alturas; descenso a tienda/checkpoint.

La entrada del colectivo de parte 2 incluye un bloque industrial sólido de
80 px de subida. Corta las líneas de tiro desde el suelo anterior; se puede
saltar encima y volver atrás con movimiento base. No concede inmunidad por
distancia: la protección procede de la geometría y afecta a ambos bandos.
Para cumplir esa cobertura, los proyectiles estándar de ambos bandos se
detienen ante cuerpos sólidos de terreno y compuertas. Las pasarelas delgadas
permiten el cruce descendente desde arriba, pero no ascendente ni lateral,
para que los tiradores elevados puedan atacar hacia abajo (GR-LEVEL-002).
Se comprueba el segmento
recorrido en cada paso físico para no atravesar paredes delgadas. No cambia
TargetValidity ni concede inmunidad a actores; los pulsos de suelo mantienen
su propia marca anunciada y no se convierten en proyectiles.
5. Egoist persigue por circuito inferior/superior acotado.
6. BlackAnarchy avanzado obliga a remontar; policía en salida del bloque.

La salida del flanqueo avanzado se apoya en un bloque sólido a la altura
de su plataforma superior (490 px), con compuerta encima. No existe paso bajo
ese bloque; al otro lado, un escalón a 570 px permite descender y regresar.
La reserva de registros permanece opcional y no cruza la compuerta.

Desvíos: `p2_heavy_overlook`, `p2_repair_cache`.
El mirador remonta desde `p2_flank_vertical_upper` a `p2_heavy_cache`, un
apoyo opcional anterior a la puerta con el suministro pesado existente.
La reserva de registros se alcanza desde allí remontando hacia la izquierda;
la ruta vuelve por los mismos apoyos y no cruza ninguna puerta sin resolver.
Secreto principal/reserva: `archive_niche_p2_records`, cuarto de registros tras
maquinaria; pista luminosa y acceso lateral, loot provisional.

### Parte 3 — leer y combinar

1. LeftLibertarian en recinto amplio: primer corredor seguro y aviso inequívoco.
2. Descenso por apoyos conectados; Mutualist habilita conexión útil.
3. BlackAnarchy vertical y Ancom protegido alternan antes del descanso/checkpoint.
4. Egoist y corredores LeftLibertarian entre alturas, con regreso permanente.
5. Policía antes de preparación final; arena acumulativa con las cinco balls,
   etapas legibles y presupuesto limitado. Zona segura final con ATM.

La arena acumulativa termina en una galería sólida a 490 px, conectada a
`coalition_upper`. La compuerta compartida se apoya en esa galería: el suelo
inferior no permite llegar a la salida. Un escalón permanente al otro lado
permite bajar al checkpoint y regresar una vez resuelto el encuentro. El
servicio Mutualist conserva su apoyo táctico opcional, no sustituye la tregua.
El primer emisor LeftLibertarian ocupa un puesto permanente de 300 px de ancho,
80 px sobre la pasarela baja. Se alcanza y abandona con salto base; separa al
emisor fijo de las balls móviles y deja espacio al Ancom y a su retirada sin
convertirlos en enemigos fuera de alcance.

Desvíos: `p3_ammo_return`, `p3_salvage_gallery`.
Secreto principal/reserva: `archive_niche_p3_reading_room`, nicho de lectura bajo
la galería; suministros provisionales, sin implementar archivo biográfico.
La galería de saqueadores acaba en un apoyo sólido elevado: obliga a subir
para continuar. Bajo ella queda un recoveco de suministros con pared de fondo;
su salida regresa hacia la izquierda al escalón de acceso, sin cruzar la puerta.
El segundo desvío remonta desde las plataformas del pulso avanzado hacia una
galería lateral de piezas. Ambos usan saltos base y conservan los desafíos.

El pulso avanzado también debe exigir una subida real: su salida se apoya
en `p3_pulse_exit_gallery`, sólido a 490 px conectado a la plataforma superior.
La compuerta se eleva a esa galería; no queda un pasillo inferior que permita
ignorar las alturas. `p3_pulse_exit_return` a 570 px permite bajar y regresar
desde la patrulla siguiente. La reserva de piezas sigue siendo una excursión
opcional hacia la izquierda, no una llave ni una resolución del encuentro.
Aplica GR-LEVEL-001/003/005/008/010 sin modificar las reglas de tregua.

## Cambios de mecánicas

El reloj de los encuentros exclusivamente Ancom se ajusta a 15 segundos;
la arena mixta conserva su reloj compartido de 65 segundos y sus etapas.
Validación del ajuste: importación y catálogo correctos; 45 tests de tregua y
14 de audio pasan en `reports/downward_projectiles_tests.log`. Ese primer lote
detectó un fallo del fixture de plataforma (transformación física inicial);
corregido, los cinco tests de proyectiles pasan en
`reports/downward_projectiles_focused.log` (reporte 325). Cubren descenso lento
y rápido, bloqueo ascendente/lateral, cañón sobre pasarela y sólido posterior.
No es un playtest humano de dificultad; no se volvió a ejecutar la suite total.
Ancom: una retirada coordinada a la vez. Ball herida vulnerable y sin curarse
busca refugio junto a camaradas; hasta dos saludables cercanos cubren su posición
anterior con separación y, si es alcanzable, distinta altura. Cooldown y aviso.
No sustitución instantánea ni teletransporte. Rendición de una sigue resolviendo
su colectivo, no otros subgrupos de la arena. Agresión individual observable.
Cada colectivo necesita espacio libre de refugio además de los puestos de
patrulla. El apoyo de parte 2 se extiende antes de su compuerta para alojar
la retirada sin superponer cuerpos ni reducir la separación táctica.

BlackAnarchy: autonomía como contraste con protección colectiva. Un integrante
presiona frontalmente y otro busca acceso lateral; romper el cerco obliga a
reposicionar con aviso y concede bonus limitado no explotable oscilando entre
dos puntos. Rendición individual; regreso acotado físico. No es una afirmación
de que la ideología implique agresión, sino un patrón de estos encuentros.

Parámetros iniciales del cerco: 0.6 s entre dos agresores a altura próxima,
salida que cruza sus límites y requiere desplazamiento real del jugador;
bonus de 2 s con tope de 6 s y cooldown de 5 s. La salida usa la zona jugable
del encuentro, no el núcleo estrecho del reloj pasivo. Fuera del encuentro,
sin dos agresores o por movimiento de enemigos sin moverse no hay premio.
Tras romperlo vuelve el aviso de 1.4 s; estado y límite persisten en checkpoint.
Una vez cerrado el cerco, ambos flancos mantienen sus posiciones horizontales
registradas hasta romperlo o perder la formación. No arrastran continuamente
la frontera al correr el jugador: debe poder atravesarla antes de una puerta.
La zona del flanqueo añade 500 px desde los puestos extremos: su límite lógico
no debe cancelar la maniobra antes de cruzar un flanco físicamente accesible.
Las compuertas y el alcance de persecución siguen limitando el desplazamiento.
El cerco solo se confirma después de asentarse la formación: no se anuncia
mientras los integrantes siguen saltando o corriendo hacia sus flancos.
Los puestos del mismo lado se separan y cada integrante conserva su propio
anclaje al cerrar el cerco; no convergen todos sobre el extremo del grupo.

LeftLibertarian: alternar corredores seguros amplios sobre apoyos alcanzables;
aviso sonoro distinto, carga creciente y descarga corta. Forma/trama además de
color. Daño bajo, empuje seguro y bonus limpio con tope; daño no reinicia reloj.
Buscar primero efectos Warped. No mezclar esta enseñanza con una arena saturada.

Arma 1: ajuste tras playtest del usuario: daño 5 (antes 4), intervalo 0.20 s
(antes 0.22), cuatro tiros y recarga automática 0.65 s (antes 0.75).
El ajuste mejora respuesta sin modificar resistencia enemiga ni elegibilidad.
HUD cuatro segmentos y sonido. Cambiar de arma no
borra la recarga. No aumentar globalmente Resolve a la vez para ocultar mala IA.

El disparo enemigo reproduce el cue espacial `fire` al crear el proyectil,
reutilizando el asset existente. No depende de acertar ni se reproduce por
animaciones de robo, contacto o amenaza. Impacto conserva su cue separado.
Aplica GR-LEVEL-001/002 y GR-RETRY-001 sin cambiar sus reglas.

Validación del ajuste: importación y contenido correctos; 40 tests de audio y
economía sin fallos (`reports/fire_audio_balance_tests.log`, reporte 323).
Prueba nueva verifica el cue al lanzar hacia ambos lados sin impacto y silencio
de una acción visual sin proyectil. El balance y la mezcla audible final quedan
sujetos a playtest; headless comprueba eventos/recursos, no escucha perceptual.

## Secretos y arma rara

Dos desvíos menores y un secreto principal por parte como reparto inicial.
Inventario editorial de ubicaciones y pendientes: `level_design/w0_01_exploration_routes.json`.
Ningún recurso obligatorio escondido; sin fuego indiscriminado a paredes ni
caídas ciegas. Recompensas físicas con procedencia, aura y persistencia existentes.
Las reservas de archivo son metadata de desarrollo, no pickups falsos visibles.

Arma candidata a concretar antes de implementar: remachadora industrial lenta,
precisa, penetración solo de cobertura ligera señalizada, jamás compuertas ni
objetivos protegidos. Propuesta de alcance acotado: usa munición pesada existente,
se conserva en checkpoint del intento y se pierde en NUEVO TALLER; sin desbloqueo
persistente de campaña. Debe presentarse al usuario antes de producir ese sistema.

## Secuencia y evidencia

1. Documentos y trazado de las tres partes (este contrato).
2. Tramo representativo parte 1: subir, premio, bajar, reconectar y secreto.
3. Tres encuentros representativos y arma con recarga; pruebas de counterplay.
4. Extender geometría/mecánicas, retirar mecanismos sin función, ubicar reservas.
5. Arena conjunta; presentación Warped, cámara, señales y audio.
6. Tests de rutas, bypass, IA, recarga, pagos, loot y retry; import, suite, capturas.
7. Reportar límites humanos de diversión, duración, audio y dispositivos.

Reglas afectadas: GR-LEVEL-001/002/003/005/008/010,
GR-ENCOUNTER-001/002, GR-ECON-001/002, GR-RETRY-001.
TargetValidity y no iniciación de agresión permanecen sin excepciones nuevas.

### Avance verificable de la iteración

- Prototipo de subida y bajada de producción en parte 1, con oficina opcional
  y suministros; reserva editorial del archivo, sin sistema biográfico.
- Llamadas de ascensor seleccionan una parada sin teletransportarlo.
  Los cuatro montacargas disponen de estaciones de llamada inferiores y
  superiores, condicionadas a su alimentación; no son pagos adicionales.
- Desvío inferior del almacén en parte 1: entrada descendente desde el segundo
  escalón, premio de munición/piezas, pared de fondo y regreso físico probado.
- Parte 2: galería inicial de montaje a 300 px sobre la entrada, sin suelo
  transitable inferior continuo; cuatro peldaños de 75 px y descenso reversible.
  Encuentro BlackAnarchy y su compuerta trasladados a esa galería. Validación
  física de los peldaños en ambos accesos; faltan los demás bloques de la parte.
- Parte 2 avanzada: salida del flanqueo a 160 px sobre el suelo inferior,
  soporte sólido que corta el paso bajo, compuerta elevada y escalón permanente
  de regreso. Prueba física recorre ambos lados y verifica por separado que
  caminar abajo no cruza el soporte, la puerta cerrada bloquea arriba y la
  abierta permite avanzar. Captura `zone_26400.png` revisada con arte Warped.
  La munición pesada se trasladó a un apoyo opcional 80 px más arriba para
  no convertir el premio de exploración en un objeto del recorrido obligatorio.
- Parte 3: galería de transferencia después del servicio, BlackAnarchy en
  tres alturas y descenso reversible hasta el colectivo. Desvío `p3_ammo_return`
  con 12 de munición pesada y 10 piezas; acceso y regreso con salto base.
  Se añadieron también el nicho inferior de lectura y la galería de piezas;
  sus accesos y regresos tienen pruebas físicas, no certificación de playtest.
- Arma principal con cuatro disparos, recarga y persistencia en checkpoint;
  segmentos y aviso sonoro conectados. Falta evaluación auditiva humana.
- Retirada Ancom asigna hasta dos coberturas separadas; estado y cooldown
  persisten. Una prueba física adicional recorre los cinco colectivos durante
  tres segundos por maniobra: herida y dos coberturas llegan a sus destinos,
  sin curación ni resolución prematura. Detectó y corrigió un bucle de salto
  entre apoyos solapados casi coplanares y falta de espacio libre en parte 2.
  La navegación ahora camina entre esos apoyos conservando los sondeos reales
  de suelo/pared. Esto no sustituye playtest de eficacia bajo fuego sostenido.
- Pulso señala el suelo seguro de la misma superficie con marcas animadas
  y aviso sonoro; descarga integrada de cinco frames `Warped shooting fx/spark`,
  sin modificar el original y a escala entera. Los carriles se recortan con
  rayos físicos ante paredes y puertas. Se señala además un apoyo superior
  cercano con un carril de 120 px, solo si el salto base cabe en el aviso y
  su arco con la cápsula del jugador no atraviesa sólidos. Plataformas móviles,
  apagadas, demasiado altas o bajo techos bloqueantes no se anuncian como
  escape. Falta evaluar su lectura en un recorrido humano continuo.
- Cerco: detección de formación, salida activa, bonus limitado, nuevo aviso
  y persistencia implementados. Pruebas sintéticas cubren cap y no-premio al
  quedarse quieto. Prueba física de presentación: las patrullas parten de sus
  puestos reales, cierran el cerco y el jugador lo rompe corriendo con su
  aceleración base, antes de la puerta. Detectó y corrigió la frontera móvil
  de los flancos y una zona lógica demasiado estrecha. La evidencia del combate
  combinado se detalla debajo. Las dos variantes avanzadas también tienen
  prueba física: carrera en parte 3 y salto hacia el apoyo superior en parte 2.
  La formación espera a que se asienten los integrantes y guarda sus anclajes
  individuales. Se corrigieron arcos que aprobaban una esquina usando una
  sonda menor que el cuerpo real; ahora ambos radios coinciden.
- Tutorial actualizado: cobertura colectiva, ruptura del cerco, señales del
  pulso, cuatro tiros/recarga y restitución mediante bolsa física. No presenta
  los contadores iniciales como duración universal de todos los encuentros.
- Arena conjunta: galería de salida elevada y descenso permanente al descanso
  final. Checkpoint desplazado a 39210 para dejar libre la cápsula de respawn;
  caja decorativa recolocada sobre el escalón. Capturas 38600/39180 revisadas.
  Pruebas físicas de ida/vuelta y comprobación de soporte inferior bloqueante;
  sigue pendiente evaluar el combate combinado durante una partida continua.
- Pendientes principales: auditoría del recorrido continuo (incluidos largos
  suelos de continuación), eficacia de la cobertura Ancom bajo fuego sostenido,
  utilidad de los demás mecanismos anteriores y lectura de la arena conjunta
  durante una partida completa. El arma rara sigue como propuesta.

Prueba posterior de corredores superiores: `reports/pulse_jump_horizontal.log`,
40 tests sin fallos. Incluye salto con desplazamiento horizontal y aceleración
real, y rechazo de plataforma desactivada o con techo bloqueante. Es evidencia
acotada de alcance, no una prueba humana del desafío completo.

Validación intermedia más reciente: `reports/vertical_revision_full.log` pasó
importación, contenido, smoke y 275 tests en 31 suites (reporte 268), incluyendo
VFX, carriles superiores, nuevos retornos, llamadas y campo visible de puertas.
`git diff --check` sin errores. Esto no certifica el ritmo de una partida humana
ni da por terminado el rediseño completo.

Tras elevar la salida avanzada de parte 2: `reports/p2_rise_final.log`,
17 tests de rutas y coalición sin fallos (reporte 271). Incluye el nuevo apoyo
opcional, retorno y bloqueo/cruce físico de la compuerta. La suite completa
de 275 tests precede este último ajuste de geometría.

Regresión táctica posterior: `reports/collective_cover_regression.log`,
41 tests sin fallos (reporte 277). Incluye movimiento físico de los cinco
colectivos, saltos, rechazo de obstáculos, treguas y checkpoint. Captura del
apoyo ampliado de parte 2 (`zone_23100.png`) revisada.

Validación completa posterior a la salida de la arena y corrección del motor:
`reports/vertical_arena_full.log`, importación, contenido, smoke y 278 tests
en 31 suites sin fallos (reporte 279). Comprobación reforzada del checkpoint
repetida aparte en `reports/coalition_checkpoint_final.log`, también correcta.
No acredita todavía balance bajo fuego sostenido ni recorrido humano continuo.

Cerco físico posterior: `reports/flank_physical_regression.log`, 42 tests de
treguas sin fallos. La prueba nueva usa puestos originales y aceleración real
para formar y romper el cerco de introducción; el límite de premios y la
restauración conservan sus pruebas anteriores. La suite completa de 278 tests
es anterior a este ajuste de posiciones y zona BlackAnarchy.

Variantes avanzadas: `reports/flank_advanced_final_regression.log`, 43 tests
sin fallos. Se forman y rompen físicamente los tres cercos independientes,
con carrera o salto base, puestos separados y restauración de anclajes.
La corrección del radio de sondeo también pasó retiradas colectivas y saltos
Egoist. No generalizar estas rutas concretas a todas las posiciones posibles
del jugador.

Arena mixta: prueba física con las cuatro etapas habilitadas, daño normal,
robo confirmado y pulsos/proyectiles presentes. El jugador forma y rompe el
cerco sin superar dos ataques simultáneos; no se fuerza una resolución global.
El HUD distingue CERCO CERRADO de CERCO ROTO. Captura `mixed_live.png` revisada:
panel legible. Un apoyo permanente adicional separa al emisor y al Ancom del
tráfico móvil y hace visible al jugador entre los saqueadores. La prueba se
amplió con retirada del Ancom amenazado después de romper el cerco: alcanza
su refugio sin curación mientras siguen activos los otros grupos. Pendiente
evaluar la densidad durante todo el recorrido de la arena, no solo esa ventana.
Regresión focalizada: `reports/mixed_flank_regression.log`, nueve pruebas de
cerco, arena mixta, resolución y checkpoint sin fallos (reporte 296).
Tras separar el puesto elevado: `reports/mixed_post_final.log`, diez pruebas
de arena y rutas sin fallos. Incluye acceso/retorno al apoyo nuevo y retirada
física con ataques mixtos; captura final `mixed_live.png` revisada.

Primer montacargas: `reports/first_lift_physical_final.log`, tres tests sin
fallos (reporte 302). La prueba nueva embarca con salto base, viaja sobre el
ascensor real, recoge munición y llave mediante solapamiento físico y regresa
al suelo. No invoca callbacks de recogida ni teletransporta durante el trayecto.
La prueba habilita el ascensor directamente: el pago se acredita por las
pruebas de economía, no por este recorrido. Las nueve reservas de exploración
ya tienen una ubicación jugable; siguen sujetas a revisión de pistas y ritmo.

Cobertura física de disparos: ambos proyectiles ordinarios comprueban el tramo
recorrido contra terreno, incluyendo el origen dentro de un sólido. Los cañones
comprueban también su desplazamiento de salida para no generar una bala al otro
lado de una pared cercana. `reports/projectile_cover_latest.log`: dos tests sin
fallos (reporte 305), con muro fino, origen interior y trayectoria libre.
La entrada del colectivo de parte 2 tiene cobertura escalable de 80 px; su prueba
lanza ambos proyectiles hacia los cuatro actores desde el acceso inferior y
comprueba que, al subir, existe un ángulo libre. La selección de posiciones de
cobertura Ancom descarta puntos enterrados en soportes superpuestos. Los cinco
colectivos completan retirada y coberturas físicas en
`reports/cover_relay_physical.log` (reporte 306). Captura `zone_23100.png` revisada:
apoyo y acceso visibles; las etiquetas de depuración siguen siendo densas.

Validación posterior de esta revisión: `reports/physical_cover_final_full.log`,
importación, datos, smoke y 285 tests en 32 suites sin fallos (reporte 307).
Incluye proyectiles reales contra la cobertura de parte 2 y las cinco maniobras
colectivas tras descartar destinos enterrados. No certifica todavía duración,
balance, sonido percibido ni controles de gamepad mediante playtest humano.

Servicio de montaje de parte 2: pasarela y reserva visible implementadas con
arte existente. `reports/paid_walkway_test.log`: 33 tests de economía/rutas sin
fallos (reporte 308), incluidos saltos de ida/vuelta, recogida física y persistencia
del pago/apoyo/recompensa sin duplicados. `reports/paid_walkway_regression.log`:
70 tests de economía/IA sin fallos (reporte 309), con retiradas de los cinco
colectivos. Importación y validación del catálogo/nueve LevelSpecs pasan.
Capturas de ruta activada y modal de pago revisadas; el modal identifica el
servicio concreto y conserva Cancelar como opción inicial. No cambia controles
ni resuelve la compuerta del colectivo. Reglas existentes GR-LEVEL-010,
GR-ECON-001/002 y GR-RETRY-001; no introduce excepciones de legitimidad.

Auditoría continua en curso: la cámara actual abarca los 720 px de altura del
nivel. `test_workshop_continuous_routes.gd` comprueba ida y regreso sin reposicionar
entre tramos, con aceleración base y aterrizajes locales dentro de la cámara.
Se abren puertas y se desactiva IA exclusivamente para aislar navegación:
no acredita combate, pagos ni duración de una partida. La primera pasada de
ambas partes nuevas pasó (reporte 311); la parte 3 se repite tras elevar la
salida de pulsos. Las duraciones del runner no son duración objetivo del nivel.

Próxima auditoría: recorrido continuo de parte 1, en especial retornos desde
los descensos de depósito (425 → 650), despacho (275 → 630) y salida de equipos
(440 → 630). Son candidatos detectados por datos, no bloqueos físicos confirmados:
deben probarse junto con pasarelas activadas y llamadas de ascensor antes de
decidir qué escalones permanentes faltan. No certificarlos por los saltos
aislados existentes ni asumir que una máquina pagada garantiza el retorno.

Salida elevada de pulsos implementada: capturas `zone_35150.png` y
`zone_35700.png` revisadas. El contenedor `p3_pulse_storage` se recolocó sobre
el escalón para no quedar enterrado. `reports/continuous_vertical_full.log`:
importación, contenido, smoke y 289 tests en 33 suites sin fallos (reporte 312).
Incluye ambos recorridos continuos actualizados, bloqueo del suelo bajo la
galería incluso con puerta abierta y paso superior solo tras abrirla. Los
recorridos de prueba tienen puertas abiertas/IA detenida: no son playtest de
balance, sonido, dispositivos ni tiempo de juego completo. Parte 1 sigue
pendiente de la auditoría continua descrita arriba.

Retornos de parte 1: añadir apoyos permanentes donde el descenso excede el
salto base (altura ideal aproximada 107 px, sin habilidades). El depósito
conecta la pasarela de 425 con el escalón de 575 mediante un apoyo a 500.
El despacho conecta su estación de 275 con el suelo de 630 mediante cuatro
escalones a 350/425/500/575; su compuerta conserva resolución por patrulla o
panel y se apoya en el último escalón. Su pasarela pagada sigue siendo una
conexión alta adicional, no el único retorno. El descenso hacia las patrullas
de equipos añade un apoyo bajo a 570 antes del puesto existente a 530.
También se añade el apoyo intermedio a 500 en la salida del colectivo de
despacho. Ninguno abre puertas ni resuelve encuentros. GR-LEVEL-001/003/005/010.

Las llamadas superiores A/B/C/D necesitan un pequeño apoyo fijo independiente
de la pasarela apagada. De lo contrario, la colocación general sobre suelo
las traslada a un piso inferior al construir el nivel y dejan de servir a
la parada alta. Se conservan las condiciones de alimentación/pago; los apoyos
de 120–160 px solo sostienen la terminal, no habilitan la pasarela completa.
La validación debe comprobar posición runtime y parada invocada, además de los
datos editoriales. La prueba runtime detectó que la galería D también puede
estar apagada por coordinación: su terminal recibe el mismo apoyo fijo.
Las compuertas Egoist de almacén/despacho se separan 100–110 px de las llamadas
superiores y se apoyan en los escalones sólidos a 575, evitando terminales
superpuestas con el campo de la puerta. Conservan sus IDs y resolución.
