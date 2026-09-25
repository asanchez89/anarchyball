# Nivel 1: exploración, recursos y confrontaciones

Diseño aprobado. Implementación incremental: no todo el rediseño es jugable aún.

## Reglas aceptadas

- Dos armas: primaria abundante de daño bajo y secundaria escasa de daño moderado.
- Bitcoin ficticio en satoshis enteros, sin redes ni dinero real.
- Loot determinista apilable: un pickup físico concede múltiples unidades.
- Llaves no consumibles ni vendibles; componentes de misión separados del loot
  comerciable. Ningún pago obligatorio depende de azar o recursos vendibles.
- Tienda local: vender mercancía, comprar munición y curación. Sin crafting ni
  simulación económica. Checkpoint restaura inventario, pagos y mundo juntos.
- Cada ascensor/pasarela aporta avance, recompensa, atajo o ventaja táctica.
- Alto el fuego: empieza tras agresión observable, avanza dentro de la zona y
  no se reinicia por defensa. Rendición o supervivencia resuelve; bonus sin causar
  daño separado del bonus sin recibir daño.
- Ancom: tres presentes inicialmente, retirada de heridas sin relevo, ataques por turnos y retirada colectiva
  al rendirse una integrante o terminar contador. Egoist: dos saqueadores ágiles,
  robo limitado recuperable, jamás llaves ni componentes de misión.
- Mutualist: servicio con coste anunciado en componentes, sin tregua ni agresión
  por rechazar el trato. BlackAnarchy: flanqueo autónomo y rendición individual.
  LeftLibertarian: marcas anunciadas y evasión limpia aceleran el alto el fuego.
  Ver `LEVEL_01_PARTS_2_3.md`: tiendas nuevas por parte y arena conjunta final.
- Policía: neutralización/evasión según objetivo, sin tregua automática.
- No confiscar por rendición: devolución, cesión, recompensa o abandono explícito;
  pago único por encuentro.

## Primer incremento

Inventario, armas, pickups, tienda, servicio Mutualist y llave en bifurcación.
Ascensor inicial con recompensa alta. IA de grupo/robo y alto el fuego incorporados
en el incremento descrito abajo. La combinación completa de partes 2/3 sigue pendiente.
Balance de munición y precios requiere playtest humano.

### Estado implementado

- Escena: `levels/world_0/w0_01_coalition_workshop.tscn`, botón NIVEL 1 del menú.
- Primaria: 120 iniciales, daño 5, intervalo 0.16 s. Secundaria: 16 iniciales,
  daño 14, intervalo 0.48 s. Clic izquierdo/RT y derecho/LT respectivamente.
- Tienda después de tres puestos policiales: vende piezas en lotes de 10, compra munición o curación;
  navegación por foco y ratón, cierre con botón o pausa/cancelar.
- Primera Police concede recompensa de misión: 40 sats y deja 20 piezas en un
  paquete recogible de restos abandonados, no confiscación.
- Apertura revisada: 1 / 2 / 3 PoliceBalls con puertas ligadas a neutralización.
  Segundo y tercer encuentro dejan 20 y 30 piezas adicionales repartidas entre
  sus integrantes. Cada PoliceBall neutralizada deja su propio paquete físico;
  se acredita al tocarlo, con sonido de recogida. Las posteriores dejan 10 piezas.
  Total garantizado: 70 piezas y 40 sats; venta total equivale a 180 sats.
  Munición y salud antes del tercer control. Tienda en x=3560 y checkpoint cercano.
  Taller posterior desplazado 1800 px, conservando relaciones entre objetos.
  Para evaluar este rediseño iniciar NUEVO TALLER: checkpoints de geometría
  anterior no se migran automáticamente a las nuevas posiciones.
- Antes de la máquina A: 10 componentes protegidos para un servicio de coste 10.
- Alimentación C y alimentación de equipos también cuestan 10 componentes cada
  una, con confirmación y recibo; los pickups de entrada a Despacho y Coordinación
  conceden cada lote antes del servicio. Los componentes no se venden ni se roban.
  Solo la primera colocación del mecánico ofrece diálogo tutorial. Las siguientes
  no crean burbuja; el servicio se solicita directamente en la máquina. Paneles
  dependientes y llamadas siguen gratuitos. Validator comprueba costes acumulados.
- Ascensor A: munición pesada ×12 y piezas ×20; salto desde arriba para obtener
  tarjeta de producción. Puerta más adelante exige esa llave, sin consumirla.
- Munición repartida por depósito, almacén, despacho y coordinación. Puesto y
  checkpoints permiten recuperar 20 ligeras si ambas reservas están vacías.
- Checkpoint guarda pagos, compras, recogidas, llaves y munición juntos. La moneda
  todavía pertenece al intento/nivel, no a una cartera global entre campañas.
- Iconos y dos armas del atlas Warped Props Pack 1. No se generó arte nuevo.
- NPC repetidos ya no comparten identidad de guardado; solo la burbuja más cercana
  recibe la interacción y permanece visible.

Verificación: importación, validación de contenido y 179 tests aprobados, incluidas
14 pruebas nuevas de economía/guardado/input/diálogos y alcance geométrico de la
llave. Capturas de tienda y zonas revisadas. Pendiente partida humana completa,
prueba con gamepad físico y balance; el alcance geométrico no sustituye playtest.
Los drops físicos están implementados para PoliceBall neutralizadas. No se han
implementado aún las nuevas mecánicas propuestas para BlackAnarchy/LeftLibertarian.

### Loot físico y menú del jugador

`actor_drop_rewards` configura restos abandonados por arquetipo. Los lotes de
encuentro existentes se reparten entre sus integrantes sin sumar otro premio.
La moneda de misión sigue siendo pago directo; los objetos requieren recogida.
El icono es Warped, a escala entera 2, apoyado por su borde alpha visible.
Checkpoint guarda disponibilidad, posición y recogidas junto al inventario.
Los checkpoints antiguos con pago automático no generan un segundo lote.

I / View del mando abre estadísticas e inventario y pausa el taller; I, Esc,
View, B o el botón de volver cierran sin disparar accidentalmente. Muestra vida,
velocidad, saldo, daño/cadencia/munición de ambas armas, stacks, valor de venta
y protección de objetos de misión. Es consulta: no hay crafting ni equipamiento
nuevo. La tienda sigue siendo el lugar para vender/comprar.

### Incremento de confrontaciones Ancom/Egoist

- Nuevo taller únicamente; las escenas históricas mantienen sus definiciones.
- Ancom: grupos de 3, 6 y 7; disparo rotativo cada 1.4 s, aviso previo de 1.2 s.
  La alerta del encuentro compromete a todas sus integrantes simultáneamente:
  cada una apunta y entra en ataque coordinado tras el aviso; los proyectiles se
  escalonan por turnos. No propaga agresión a otro encuentro ni a NPC neutrales.
  La primera agresión inicia 35 s compartidos. Una rendición retira al grupo;
  resistir el contador también abre la puerta y la pasarela del encuentro.
- Retirada: resistencia de 90 Resolve. Al quedar en 90% o menos,
  la herida busca espacio junto al camarada alcanzable más alejado del jugador,
  sin que otro ocupe su puesto, usando suelo y saltos alcanzables. No dispara
  durante el traslado, no se cura ni gana invulnerabilidad. Rendición a 35% de
  Resolve: **una sola rendición sigue resolviendo el colectivo**. Repliegue
  táctico no significa rendición. Cada integrante herida se repliega una vez.
  Se rechazan destinos ocupados o que no aumenten la distancia. El salto comienza en
  el punto alcanzable más próximo, sin caminar hasta debajo del destino final.
  El desplazamiento de la herida es deliberadamente rápido: 1200 px/s,
  salto a 1920 px/s y gravedad 14400 px/s², conservando alcance/altura del arco
  pero recorriéndolo tres veces más rápido. Pausa entre saltos: 0.08 s. Whoosh
  espacial de 0.32 s una vez al iniciar la retirada. No acelera a las Egoist.
- Egoist: 2, 3 y 4 saqueadores, persecución terrestre a 190 px/s, respetando
  suelo, paredes y separación. El intento próximo de confiscación habilita defensa.
  Contacto: 4 de daño, hasta 8 municiones ligeras y 2 piezas por vez; cooldown
  de 2 s por actor. Máximo sustraído por encuentro: 24 ligeras y 6 piezas.
  Llaves y componentes protegidos nunca se tocan. No roba sats ni munición pesada.
  Resolver exige todas las rendiciones o 26 s de resistencia. Los objetos robados
  salen en paquetes físicos con aura y arco de caída: no se devuelven hasta
  recogerlos. Estas bolsas no caducan; checkpoint conserva contenido y recogida.
  Cada saqueador que robe lleva su propia cuenta y suelta su propia bolsa al
  rendirse o quedar neutralizado. La tregua libera las bolsas restantes. Un
  checkpoint antiguo con un único paquete compartido sigue pudiendo recuperarlo.
  Los choques usan un golpe retro propio, también al agotar el cupo de robo.
- Persecución Egoist: radio de 420 px desde el puesto inicial, además del límite
  del encuentro. Al perder alcance vuelve andando/saltando y cesa la agresión
  al llegar a casa (10 px de tolerancia). Un nuevo cruce exige otro aviso de
  1.2 s y compromiso de agresión. No se cura ni devuelve/borra lo robado al
  volver. Sin integrantes enfrentando al jugador el contador se pausa.
  Persiguen también hacia pasarelas y ascensores activos dentro del mismo radio:
  salto de 1120 px/s, gravedad de 1600 px/s² (altura máxima 392 px), velocidad
  horizontal aérea máxima 320 px/s. Recalculan con la posición del apoyo móvil
  y pueden bajar por pasarelas unidireccionales al regresar. No atraviesan muros
  ni usan plataformas desactivadas. No cambia la tregua ni su permiso ofensivo.
- Lo sustraído vuelve al inventario al recoger cada bolsa de restitución;
  no es confiscación del equipo del NPC. Botiquines siguen curando pero no resuelven.
- Temporizadores solo avanzan dentro de la zona y con el jugador vivo; salir
  los pausa, no los reinicia. Disparar en defensa tampoco reinicia el reloj.
- Premio base: 20 sats; por supervivencia, +20 sin causar daño y +20 sin recibirlo.
  Condiciones independientes. El pago tiene ID único y no se duplica.
- Contador/barra compartida visible, briefing actualizado y puertas obligatorias.
  Retiradas las tres balizas que antes resolvían Ancom. Sus perchas sirven para
  esquivar y tomar posiciones; máquinas Mutualist conservan su función mecánica.
- Checkpoint conserva contador, turnos, robos pendientes y elegibilidad del bonus.
  Reintentar limpia proyectiles previos y restaura inventario y encuentro juntos.
- Arte y proyectiles existentes; no se generaron nuevos assets.

Para probar esta versión usar NUEVO TALLER: los checkpoints anteriores al rediseño
de los encuentros no representan estas nuevas condiciones.

Verificación de este incremento: importación headless y 193 pruebas aprobadas.
Diez pruebas nuevas cubren permiso ofensivo antes/después de agresión, rendición
colectiva frente a individual, contador/pausa, invalidación de soluciones antiguas,
robo limitado/protegido, restitución, checkpoint, puertas y persecución sobre suelo.
Capturas tras simular 150 pasos físicos: `challenge_collective.png` y
`challenge_raid.png` en `reports/workshop_review/`. No sustituyen playtest completo.

Reglas: GR-ECON-001/002, GR-COMBAT-001/002, GR-ENCOUNTER-001/002 y GR-RETRY-001.

Revisión colectiva: patrullas limitadas en Police/Ancom/Egoist, detenidas al
rendirse; comprobación de suelo y pared antes de moverse. Los puestos Ancom
mezclan suelo, escaleras y pasarelas industriales con soporte. Se mantiene
GR-CORE-002: la señal común inicia un ataque comprometido observable en cada
integrante, no permiso por ideología. GR-CONFLICT-001 y TargetValidity no cambian.

Rangos iniciales desde el punto de origen: Police ±65 px a 45 px/s; Ancom
±45 px a 35 px/s; Egoist ±70 px a 55 px/s antes de perseguir. Las persecuciones
Egoist se mantienen dentro de la zona del encuentro. La pausa breve de disparo
conserva el cañón apuntado. Tres pasarelas nuevas usan deck y soportes Warped;
el grupo reaprovecha además las escaleras existentes. Para probar la nueva
distribución, iniciar NUEVO TALLER (no reubicar actores de un guardado antiguo).

Verificación del incremento colectivo: importación, validación y 203 pruebas;
captura de las tres disposiciones y simulación de 150 pasos físicos del primer
grupo con todas sus integrantes en Aggressor. Pendiente recorrido humano y
balance de fuego cruzado. Reglas de plataformas: GR-LEVEL-003/010 sin cambios.

### Loot humorístico

PoliceBall abandona contratos sociales: «Firmado por ti. Aparentemente».
Sustituyen las piezas policiales manteniendo 2 sats/unidad y los 70 objetos
totales de las tres vistas iniciales. Las piezas de máquinas y de guardados
anteriores conservan su ID y siguen siendo vendibles.

Cada Ancom del colectivo cede 10 cepillos comunales («Uso común; cerdas por
cuenta propia»); cada Egoist cede 10 botellas de leche egoísta («La única y su
leche»). Ambos valen 2 sats/unidad. Son mercancías, no curación ni consumibles.
Se liberan al neutralizar al agresor o, voluntariamente, al resolver la tregua;
no se pueden extraer de actores neutrales durante el conflicto. El objeto
físico representa todo el lote. La recompensa de tregua en sats no cambia.
Estos dos nuevos ingresos requieren balance mediante playtest.

GR-ECON-001/002 y GR-RETRY-001: recogida única, guardado del estado físico,
sin duplicados por rendición seguida de tregua. No cambia TargetValidity.
Arte por ID en RunEconomyDefinition, tamaño visible uniforme de 84 px y
anclaje al suelo compartido. Tienda desplazable con foco; inventario con
descripciones y desplazamiento mediante flechas/D-pad.

Verificación: importación headless, validación y 206 pruebas aprobadas.
Las pruebas cubren venta, alpha/tamaño de iconos, cesión al finalizar tregua,
checkpoint sin duplicados y desplazamiento de tienda/inventario.
Capturas revisadas en reports/workshop_review: humorous_loot.png,
economy_shop.png y player_inventory.png. Pendiente playtest humano de la
economía ampliada y sensación de navegación con mando físico.
Prompts y procedencia: assets/art/props/world_0/humorous_loot_v1.md.

### Aura y caducidad

Todos los coleccionables disponibles tienen halo luminoso pulsante. Los objetos
estáticos del nivel no caducan. Solo los drops duran 90 segundos de gameplay
desde que aparecen: parpadeo moderado a 2 Hz y cuenta atrás durante los últimos
10 segundos. Tienda, inventario y pausa detienen el reloj. Parámetros en
RunEconomyDefinition; aura y parpadeo en PickupPresentationProfile.

Recoger o caducar elimina el nodo del drop (sprite, aura y colisión incluidos).
El checkpoint conserva el tiempo restante y un registro terminal pequeño:
retry restaura la instantánea, sin reiniciar el plazo ni duplicar recompensas.
Caducar no concede inventario ni progreso. Llaves y componentes protegidos
no pueden configurarse como loot temporal de actor. Reglas afectadas:
GR-ECON-001/002, GR-RETRY-001 y GR-LEVEL-002.

Validación del incremento: importación headless y 211 pruebas aprobadas.
Capturas revisadas: halo activo, aviso brillante/atenuado y escena tras caducar
en reports/workshop_review/pickup_*.png. Pendiente playtest humano para ajustar
duración e intensidad; no se cambiaron controles.

### Ajuste del colectivo de Despacho

Seis integrantes distribuidos en tres alturas dentro de 430 px horizontales,
con dos pasarelas cercanas y soportes industriales. Están activas antes
del combate; ascensos de 80 px y separación horizontal de 30 px mantienen
el salto base dentro del margen conservador de validación. La bajada derecha
conecta con el primer escalón de salida.
La pasarela de salida sigue condicionada a resolverlo. El alcance
Ancom pasa a 850 px para incluir la retaguardia desde la entrada del recinto.
Resolve del arquetipo colectivo: 90 (antes 60); retirada al 90%, conservando su
activación tras dos impactos ligeros. Una rendición retira al grupo y el alto
el fuego permanece en 35 s. Sin aumento de daño ni de frecuencia de disparo.
GR-LEVEL-002/003/010, GR-CORE-005 y GR-CONFLICT-001 permanecen intactas.
Probar desde Nuevo taller: los checkpoints conservan posiciones antiguas.

El colectivo final conserva siete integrantes en 480 px, añade dos pasarelas
de 210 px con ascensos de 80 px y hueco de 20 px; se apoyan visualmente sobre
la estructura existente y están disponibles antes del combate. El techo
conserva el descenso hacia salida. No requiere encender máquinas adicionales.
Pruebas físicas del jugador cubren subida y descenso, y los siete turnos
de disparo se comprueban desde el borde izquierdo del recinto.

### Escala y contacto de los coleccionables

La tregua Ancom solo avanza dentro del 70% central de la huella horizontal
inicial del grupo, sin los 350 px de detección exterior. Los bordes pausan sin
reiniciar. HUD indica pausa y dirección; el área no sigue patrullas/retiradas.
Disparos y rendición siguen funcionando en los bordes. No cambia Egoist.

Revisión táctica posterior: sustituir el intercambio de puestos por retirada
única hacia el camarada activo más distante del jugador con refugio alcanzable.
El destino queda junto al camarada, no encima; requiere ganar al menos 80 px de
distancia, apoyo activo, ruta física y separación de actores/destinos reservados.
Sin refugio válido no se mueve. Nadie avanza a sustituirla. Se conservan velocidad,
sonido, vulnerabilidad, Resolve, temporizador y rendición colectiva. Al cargar un
snapshot antiguo se descartan órdenes de reemplazo, sin teletransportar un salto
que ya estuviera en curso. El balance previo de relevo queda como histórico.

Los tres loots humorísticos usan ahora 28 píxeles lógicos en el eje mayor,
mostrados a 3 px de mundo por píxel lógico (84 px), coherente con los pickups
Warped a escala 3. Un shader de presentación aplica esa cuadrícula al PNG de
origen sin reescribirlo; el aura conserva su degradado suave.

DebugPickup calcula su sensor rectangular desde los límites visibles del sprite,
sin márgenes transparentes ni aura, más 6 px de tolerancia por lado. Cambiar arte
o escala actualiza el sensor. La recogida también comprueba solapamientos activos:
no requiere volver a entrar, saltar ni pulsar un botón al subir en ascensor.
No se han desplazado la munición del ascensor ni la llave de la ruta superior.
Se conservan ownership, efectos, temporizadores y recogida única.

Verificación: importación y 218 pruebas aprobadas, sin errores de runtime en
la suite final. Incluye recorrido físico del primer ascensor sin salto,
recogida de munición, llave superior sin recoger y activación de un item ya
solapado. Render de los loots revisado; queda pendiente valoración humana del
tamaño y detalle visual. GR-ECON-001/002 y GR-LEVEL-002, sin cambios de controles.
