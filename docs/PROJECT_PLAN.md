# Anarchyball: The Game
## Documento de planificación de producto, diseño y arquitectura para implementación con Codex

**Estado:** Documento base de preproducción - revisión 0.2  
**Objetivo:** Convertir la idea de *Anarchyball* en un side-scroller shooter/RPG 2D, data-driven y multiplataforma, diseñado desde el inicio para que Codex pueda implementar, probar y asistir en la generación de niveles.  
**Plataformas objetivo:** Steam (Windows primero), Android e iOS.  
**Motor elegido:** Godot 4.x estable + GDScript tipado.  
**Principio rector:** primero debe funcionar como videojuego; la divulgación ideológica debe emerger de las mecánicas, los conflictos y las consecuencias del mundo, no de largas exposiciones. AnarchyBall no dispone de una ruta jugable basada en iniciar agresión: el sistema de combate debe hacer viable completar el juego respetando de forma estructural la no iniciación de la fuerza.

---

# 1. Resumen ejecutivo

*Anarchyball: The Game* será un videojuego 2D de acción, plataformas y disparos con progresión RPG ligera. Su mundo se inspira en la cultura visual de las *countryballs/polcompballs*: todos los personajes, NPC, enemigos y jefes son "balls" que representan ideologías, corrientes políticas, roles institucionales o subculturas.

La estructura del mundo se inspira conceptualmente en un Political Compass: el jugador comienza en la zona anarquista/libertaria inferior y recorre progresivamente regiones ideológicas más estatistas hasta ascender hacia el extremo autoritario, donde se encuentra **The LeviathanBall**, representación del Estado como institución expansiva y monopolística.

El juego tiene una intención divulgativa favorable al anarcocapitalismo, pero no debe ser propaganda plana. Las ideologías rivales deben presentar preocupaciones reconocibles y, cuando corresponda, fortalezas reales. El jugador debe entender por qué alguien podría sostener esas posiciones y luego experimentar sus tensiones institucionales mediante gameplay.

La resolución no consiste en destruir todas las ideologías. Tras derrotar al Leviatán se alcanza una **panarquía**: múltiples comunidades y asociaciones conservan preferencias culturales, económicas y organizativas distintas, pero dejan de reclamar jurisdicción coercitiva universal sobre terceros. El epílogo muestra versiones voluntarias de esas sociedades. Un cliffhanger final puede introducir a un personaje proponiendo un nuevo "contrato social", sugiriendo que el Leviatán siempre puede intentar reconstruirse mediante nuevas justificaciones.

---

# 2. Visión del producto

## 2.1 Fantasía del jugador

El jugador controla a **AnarchyBall**, una ball libertaria que recorre un mundo fragmentado en sistemas ideológicos. Combate agresiones, atraviesa obstáculos institucionales, discute con rivales, forma alianzas improbables y desarrolla una build basada en una de cinco clases jugables.

La fantasía central no es "matar ideologías". Es:

- sobrevivir a sistemas que intentan imponerse;
- encontrar rutas alternativas a restricciones;
- defenderse de agresores sin convertir al protagonista en un atacante indiscriminado;
- descubrir cómo diferentes instituciones producen incentivos y obstáculos distintos;
- demostrar que orden, cooperación y coordinación pueden existir sin un monopolio territorial de autoridad;
- terminar construyendo una coalición suficientemente amplia para derrotar al Leviatán.

## 2.2 Pilares de diseño

1. **Gameplay primero.** Cada concepto político debe convertirse en interacción jugable.
2. **Side-scroller auténtico.** Plataformas, movilidad, combate, lectura del escenario y boss fights siguen siendo el núcleo.
3. **RPG ligero, no simulador.** Clases, habilidades, equipo, hub y progresión; sin convertirse en 4X o city builder.
4. **Ideas convertidas en reglas.** Una ideología modifica objetos, obstáculos, enemigos y reglas del nivel.
5. **NAP como regla estructural del protagonista.** AnarchyBall no puede iniciar agresión como parte normal de su moveset; el combate ofensivo se habilita ante agresión iniciada o inminente, defensa de terceros y duelos consentidos.
6. **Rivales con argumentos.** Los bosses pueden estar equivocados desde la tesis del juego sin ser caricaturas vacías.
7. **Panarquía como desenlace.** La victoria no exige homogeneidad ideológica.
8. **Arquitectura AI-friendly.** Los niveles y reglas deben ser legibles y modificables por Codex mediante datos y validadores.

---

# 3. Género y estructura

## 3.1 Género principal

**2D side-scroller action platformer + shooter + RPG ligero.**

Referencias estructurales deseables, sin copiar contenido:

- claridad y progresión de mecánicas de un action-platformer;
- exploración y secretos moderados;
- builds y habilidades suficientes para ofrecer estilos distintos;
- bosses con patrones legibles y fases temáticas;
- hub central para preparación, progreso y diálogo;
- niveles predominantemente lineales con rutas alternativas por clase.

No se busca un metroidvania puro en la primera versión. Puede haber backtracking opcional y secretos desbloqueables, pero el diseño debe permitir terminar el juego mediante una progresión de mundos clara.

## 3.2 Core loop

1. Regresar a **The Agora**.
2. Elegir nodo/región del mapa ideológico.
3. Seleccionar clase/loadout.
4. Entrar en un nivel.
5. Traversal + combate + obstáculo ideológico + secretos.
6. Encontrar NPC, mini-boss o conflicto institucional.
7. Resolver encounter o boss.
8. Obtener recursos, habilidades, lore y aliados.
9. Regresar a The Agora.
10. Mejorar build y desbloquear siguiente nodo.

---

# 4. Mundo y mapa ideológico

## 4.1 Political Compass como geografía conceptual

El mapa usa dos ejes conceptuales:

- Horizontal: orientación económica/colectiva <-> mercado/propiedad privada.
- Vertical: autoridad política/coerción territorial <-> libertad/anarquía.

No es necesario copiar literalmente una gráfica existente ni usar coordenadas doctrinales exactas. Debe ser un mapa propio y estilizado que comunique el recorrido político.

El trayecto principal asciende desde el extremo anarquista hacia zonas progresivamente más autoritarias. El **mundo final** se sitúa en la parte superior central y culmina en The LeviathanBall.

## 4.2 Regla narrativa del mapa

Moverse horizontalmente cambia la forma de organizar recursos, propiedad, intercambio y cultura.

Moverse verticalmente cambia la intensidad con la que una institución puede imponer reglas a terceros.

Esta distinción debe aparecer desde el tutorial: dos ideologías pueden estar muy alejadas en economía y, al mismo tiempo, compartir una oposición fuerte al Estado.

---

# 5. Arco narrativo principal

## 5.1 World 0 - The Anarchist Frontier

El primer mundo sirve como tutorial mecánico y filosófico. No es "el mundo del Ancom", sino **el mundo de los anarquismos**.

El recorrido introduce de forma progresiva:

- AnarchyBall;
- EgoistBall;
- AgoristBall;
- MutualistBall;
- LeftLibertarianBall;
- BlackAnarchyBall;
- AncomBall como boss/rival final del mundo.

La función del mundo es mostrar que la palabra "anarquía" contiene disputas reales:

- propiedad y posesión;
- jerarquía vs. autoridad coercitiva;
- apropiación original;
- derechos morales y egoísmo;
- cooperación colectiva;
- liderazgo informal;
- mercados y comunas.

El enfrentamiento con AncomBall puede ser un duelo voluntario o una disputa reglada. En la fase final irrumpe una fuerza del Leviatán que declara ilegales las asociaciones de todos los anarquistas por igual. El boss fight se interrumpe y las facciones colaboran para escapar.

Esto establece la primera coalición.

## 5.2 World 1 - The Night Watch

Zona de **MinarchyBall** y **ClassicalLiberalBall**.

Tema: cómo un Estado mínimo adquiere facultades adicionales durante emergencias.

Cadena narrativa posible:

- policía y tribunales limitados;
- "temporary security act";
- impuesto temporal;
- checkpoints temporales;
- licencias temporales;
- expansión de poderes.

Un MinarchyBall puede necesitar ser rescatado de otro MinarchyBall que ha justificado sucesivas expansiones del poder. La historia debe evitar "minarquista tonto"; el conflicto es el problema del ratchet institucional.

Al final, varios minarquistas reconocen que el Leviatán puede terminar absorbiendo el propio orden limitado que querían proteger.

## 5.3 Mundos intermedios - orden provisional

El orden exacto se define durante preproducción. Deben aparecer ideologías claramente identificables y diferenciadas. Candidatos:

- RepublicanBall / DemocraticBall;
- SocialdemBall;
- CorporatistBall;
- MonarchyBall;
- CommunistBall;
- MarxistLeninistBall;
- StalinistBall;
- FascistBall;
- otras corrientes si agregan una mecánica distinta y no repiten contenido.

Cada mundo necesita una identidad jugable propia y no debe existir solo porque "falta representar una ideología".

## 5.4 Final world - Leviathan

La parte superior central del mapa converge en una región que ha absorbido mecanismos, símbolos y justificaciones de distintos sistemas.

Boss final: **The LeviathanBall**.

Posibles fases:

1. Tradition/Crown - autoridad por tradición.
2. Majority - autoridad legitimada por mayoría.
3. Planning - autoridad por necesidad de coordinación.
4. Security/Emergency - autoridad por protección.
5. Leviathan - el monopolio ya no necesita una justificación ideológica específica.

La coalición formada a lo largo del juego participa mecánicamente en el enfrentamiento.

## 5.5 Epílogo - Panarchy

Tras la derrota del Leviatán, el Political Compass deja de ser una cuadrícula territorial y se transforma visualmente en una **red de asociaciones y comunidades**.

Ejemplos:

- AncomBall mantiene una comuna voluntaria;
- MutualistBall organiza federaciones/cooperativas;
- SocialdemBall crea redes voluntarias de ayuda, seguros y mutualidad;
- RepublicanBall conserva asociaciones democráticas para sus miembros;
- MonarchyBall puede conservar una comunidad tradicional/monárquica voluntaria;
- MinarchyBall puede convertir sus funciones preferidas en una asociación de defensa/justicia sin monopolio territorial;
- AnarchyBall conserva comunidades de propiedad privada y mercado.

No todas las doctrinas pueden conservarse intactas: elementos definitorios basados en coerción territorial, partido único, persecución o colectivización forzada deben desaparecer. Se preservan preocupaciones, preferencias culturales y formas voluntarias compatibles.

### Cliffhanger

Un **ContractarianBall** o personaje equivalente propone:

> crear una autoridad común limitada mediante un contrato voluntario.

El documento contiene una cláusula que pretende vincular también a futuros residentes o terceros. AnarchyBall detecta la semilla del problema.

Corte a negro.

---

# 6. Personajes, NPC, enemigos y bosses

## 6.1 Regla visual

Todo el elenco principal conserva el formato "ball":

- cuerpo esférico;
- ojos simples;
- emblema/colores identificables;
- accesorios mínimos;
- animación expresiva sin abandonar la simplicidad.

La estética debe inspirarse en el lenguaje visual de las countryballs/polcompballs, pero el proyecto debe desarrollar un estilo propio suficiente para convertirse en una IP reconocible.

## 6.2 Nomenclatura

Ejemplos:

- The AncomBall;
- The MutualistBall;
- The MinarchyBall;
- The RepublicanBall;
- The SocialdemBall;
- The CorporatistBall;
- The MonarchyBall;
- The FascistBall;
- The StalinistBall;
- The LeviathanBall.

Los NPC comunes pueden usar el nombre de su corriente sin artículo: `SocialdemBall`, `MutualistBall`, etc.

## 6.3 Enemigos comunes

Una ideología no convierte automáticamente a todos sus ciudadanos en enemigos.

Los enemigos representan **acciones coercitivas, aparatos institucionales o individuos agresores**, por ejemplo:

- TaxCollectorBall;
- RegulatorBall;
- CustomsBall;
- PartyGuardBall;
- CommissarBall;
- RoyalGuardBall;
- SecretPoliceBall;
- ConscriptBall;
- CorporateGuardBall;
- CensorBall;
- InspectorBall.

Esto evita que la fantasía del jugador sea "disparar a quien piensa distinto".

---

# 7. NAP y sistema de combate

## 7.1 Principio de diseño

El juego puede ser shooter y, al mismo tiempo, tener como protagonista a un personaje que defiende la no iniciación de la fuerza. La solución no será un sistema de karma donde el jugador pueda comportarse como agresor y simplemente aceptar una penalización.

**AnarchyBall no puede completar el juego mediante una ruta de agresión iniciada.** Esta restricción forma parte de la identidad del personaje y del diseño del combate.

El sistema debe cumplir cuatro objetivos:

- no obligar al jugador a recibir el primer disparo antes de poder defenderse;
- permitir defensa de terceros y rescates proactivos;
- permitir varias respuestas a una agresión además de matar enemigos;
- conservar disputas filosóficas ambiguas sin declarar automáticamente cuál teoría de propiedad es correcta.

## 7.2 Estados de conflicto

Todo personaje relevante utiliza un estado de conflicto explícito. La implementación puede separar internamente `ConflictState` de `Disposition/Faction`, pero a nivel de diseño se reconocen estos estados:

- **Neutral** - no existe una agresión activa ni una disputa que habilite fuerza.
- **Disputed** - existe una disputa normativa, contractual o de propiedad, pero el juego no concede todavía justificación automática para usar fuerza.
- **Threatening** - existe una amenaza creíble o un telegraph de coerción; el jugador puede preparar defensa, evadir o interactuar.
- **Aggressor** - el actor ha iniciado una agresión o una acción coercitiva suficientemente inmediata. Las acciones ofensivas defensivas quedan habilitadas.
- **Surrendering** - el actor abandona la agresión; deja de ser un objetivo ofensivo válido.
- **Neutralized** - el encounter terminó por rendición, desarme, huida, stun, arresto u otra resolución.

`VoluntaryDuel` se modela como un contexto adicional: dos partes han consentido temporalmente el combate y pueden dañarse dentro de las reglas acordadas sin ser tratadas como agresores.

## 7.3 Qué cuenta como inicio de agresión

No es necesario esperar a recibir daño. Una ball puede convertirse en **Aggressor** cuando:

- dispara, golpea o inicia un ataque;
- apunta/amenaza de forma inmediata con fuerza para imponer obediencia;
- intenta detener, secuestrar o conscribir al jugador o a un tercero;
- confisca físicamente propiedad o recursos mediante fuerza;
- invade o destruye propiedad en un encounter donde el derecho relevante ya fue establecido por la misión;
- ejecuta una orden coercitiva que impide al jugador abandonar una interacción;
- agrede a un NPC neutral;
- activa una máquina o unidad cuyo propósito inmediato es ejercer esa coerción.

Ejemplo: un RoyalGuardBall puede pedir documentos sin ser todavía un objetivo ofensivo. Si intenta detener al jugador por negarse a someterse, pasa a Aggressor. Un TaxCollectorBall puede hablar primero; cuando intenta confiscar físicamente recursos, inicia el encounter.

## 7.4 Defensa de terceros

AnarchyBall puede intervenir aunque la agresión no esté dirigida contra él.

Casos de uso:

- defender a MerchantBall de un robo/confiscación;
- impedir una conscripción;
- liberar a un detenido cuando el encounter establece la detención como coercitiva;
- proteger una comunidad atacada;
- detener destrucción o requisa de propiedad;
- rescatar NPC durante redadas.

Esto permite que el protagonista sea proactivo sin convertirlo en un agresor.

## 7.5 Disputas ambiguas

Las disputas doctrinales del World 0 no deben resolverse automáticamente mediante el estado Aggressor.

Ejemplos:

- título de propiedad vs. occupancy-and-use;
- apropiación original y servidumbres;
- incumplimiento contractual discutido;
- uso de un recurso con reclamaciones incompatibles.

Estos encounters entran en **Disputed** y exigen otra forma de gameplay antes de habilitar fuerza:

- negociación;
- arbitraje;
- investigación;
- restitución;
- duelo consentido;
- bypass/ruta alternativa;
- resolución específica de quest.

Esto evita que el motor convierta una teoría filosófica concreta en una verdad invisible impuesta por código.

## 7.6 Gating de daño y friendly fire

Las acciones ofensivas del jugador solo producen daño/Resolve loss contra:

- Aggressors;
- participantes válidos de un VoluntaryDuel;
- máquinas hostiles/destructibles;
- targets explícitamente habilitados por un encounter.

Contra un Neutral o Disputed, AnarchyBall no ejecuta una agresión válida: puede bajar el arma, cancelar el disparo o hacer que el proyectil no aplique daño. La primera vez puede aparecer un feedback breve como `Not an aggressor`.

Esto es una regla diegética del protagonista, no un sistema de moralidad opcional.

## 7.7 Respuestas posibles a una agresión

El objetivo de un encounter no debe ser siempre `Defeat all enemies`. Según clase y situación, el jugador puede:

- combatir;
- evadir;
- desarmar;
- stun/neutralizar;
- hackear/desactivar sistemas;
- negociar;
- contratar apoyo;
- escapar por una ruta alternativa;
- proteger a un tercero hasta que termine la amenaza.

Esto preserva la identidad de Runner, Tinkerer, Trader y Agorist dentro de un juego shooter.

## 7.8 Derrota no equivale a muerte

Para mantener el tono:

- las balls pueden rendirse;
- perder el arma;
- quedar aturdidas;
- huir rodando;
- ser detenidas por otra facción;
- abandonar el encounter.

Los vehículos, torretas, drones y máquinas sí pueden destruirse.

Cuando una ball entra en **Surrendering**, deja inmediatamente de ser un objetivo ofensivo válido. El juego no recompensa continuar atacándola.

## 7.9 Duelo voluntario

El sistema admite encounters donde dos partes aceptan combatir bajo reglas explícitas. Estos encounters son útiles para tutoriales, rivalidades y bosses ideológicos, especialmente The AncomBall en World 0.

## 7.10 Reputación: relación contextual, no barra moral

Se elimina la idea de una **Reputation moral global** usada para castigar agresiones iniciadas. Como AnarchyBall no puede adoptar esa ruta de forma normal, esa barra sería redundante y convertiría el NAP en un sistema de karma.

Sí pueden existir reputaciones o relaciones contextuales por decisiones sociales:

- confianza de una red anarquista;
- relación con una comunidad;
- historial contractual;
- reputación comercial;
- confianza de un aliado.

Estas métricas reaccionan a promesas, contratos, rescates, traiciones o decisiones de quest, no a una contabilidad genérica de `good/evil`.

---

# 8. Clases jugables

Las clases son **estilos de acción**, no posiciones morales. Todas usan el mismo PlayerController base, modifican habilidades, recursos y rutas disponibles, y todas respetan la regla estructural de no iniciar agresión. Ninguna clase necesita violar el NAP para ser viable.

## 8.1 Contractor

Fantasía: defensa armada profesional.

Gameplay:

- armas convencionales;
- mejor control de recoil/precisión;
- escudos o armor;
- bonificaciones al responder a un Aggressor;
- habilidades de protección de NPC.

Mecánica temática posible: **Defensive Response**: al ser agredido o defender a un tercero, obtiene un buff temporal.

## 8.2 Runner

Fantasía: libertad de movimiento y evasión.

Gameplay:

- dash;
- wall jump;
- slide;
- vault;
- grappling hook si el scope lo permite;
- disarm/stun;
- mayor capacidad de ignorar rutas institucionales.

Es la clase más compatible con runs de mínima confrontación.

## 8.3 Tinkerer

Fantasía: resolver conflictos atacando sistemas, no personas.

Gameplay:

- drones;
- EMP;
- trampas;
- hacking;
- control temporal de torretas;
- activación remota de maquinaria;
- construcción de plataformas/gadgets limitados.

## 8.4 Trader

Fantasía: resolver problemas mediante capital, intercambio y contratos.

No se simula una economía completa. **Capital funciona como recurso de combate/utility.**

Puede comprar en tiempo real:

- supply drops;
- munición;
- medical contract;
- escudo temporal;
- apoyo de un SecurityBall;
- acceso temporal a shortcuts;
- conversión de loot en recursos.

Funciona parcialmente como clase support/summoner.

## 8.5 Agorist

Fantasía: evadir restricciones y crear intercambios no autorizados.

Gameplay:

- stealth;
- smoke;
- rutas de contrabando;
- black markets;
- bypass de permisos;
- contraband weapons;
- túneles, vents y accesos ocultos;
- reducción de detección en checkpoints.

Cada mundo reinterpreta su fantasía: smuggling en Monarchy, black market en planificación central, redes clandestinas en Fascism, evasión regulatoria en corporatismo, etc.

## 8.6 Escuelas filosóficas / lenses

Las **clases de combate** y las **escuelas filosóficas** son sistemas separados. Un jugador puede combinar, por ejemplo, `Runner + Natural Rights` o `Trader + Consequentialist`.

La separación evita que una clase parezca "la clase que respeta el NAP" y otra parezca moralmente inconsistente. Todas las builds respetan la no iniciación de fuerza; cambia la forma de interpretar conflictos y las herramientas adicionales disponibles.

### Natural Rights / Rothbardian

Foco: derechos, propiedad, defensa y restitución.

Posibles perks:

- `Rights Sense`: feedback contextual más preciso sobre Aggressor, third-party defense y claims ya establecidos;
- registro de `Claim` cuando existe daño/confiscación comprobada;
- mejores opciones de restitución y recuperación de propiedad;
- bonuses defensivos cuando el encounter tiene una agresión inequívoca.

No obtiene permiso especial para atacar neutrales.

### Consequentialist

Foco: resultados, reducción de daño y soluciones institucionales eficientes.

Posibles perks:

- bonus por resolver encounters con poco collateral damage;
- mejor stun/de-escalation;
- evaluación de resultados/risks;
- recompensas por proteger terceros y preservar infraestructura.

### Austrian / Institutional

Foco: información, escasez, coordinación e incentivos.

Posibles perks:

- detectar bottlenecks;
- revelar surplus/scarcity;
- descubrir rutas de intercambio;
- identificar distorsiones de precio o asignación que abren alternativas de gameplay.

### Polycentric Legal

Foco: arbitraje, jurisdicción competitiva y resolución de disputas.

Posibles perks:

- detectar `Arbitration Available`;
- presentar evidencia o claims;
- transformar algunos encounters Disputed en resolución contractual;
- mejores opciones de surrender/restitution.

Estas lenses deben mantenerse pequeñas. Son una capa de build secundaria, no cuatro campañas ni cuatro sistemas completos de diálogo.

---

# 9. Progresión RPG

## 9.1 Objetivo

Dar decisiones de build y recompensa por explorar sin transformar el juego en un RPG estadístico pesado.

## 9.2 Progresión sugerida

- nivel general del personaje;
- puntos de habilidad;
- árbol pequeño por clase;
- armas/equipo;
- 2-3 slots de habilidades activas;
- pasivas;
- una escuela filosófica/lens secundaria;
- relaciones contextuales y confianza contractual cuando una quest lo requiera;
- unlocks permanentes del hub;
- codex/lore.

## 9.3 Cambio de clase

El jugador puede cambiar de clase/loadout en **The Agora**. No se crean cinco campañas separadas.

La progresión puede compartir un nivel global y usar especialización por clase para evitar repetir grind.

## 9.4 Límites de scope

No incluir en la primera versión:

- economía persistente compleja;
- crafting profundo;
- loot aleatorio estilo ARPG;
- árboles de 100 nodos;
- reputación global tipo karma o reputación por veinte facciones;
- hambre, vivienda, población o producción por hora.

---

# 10. The Agora - hub principal

The Agora es una base RPG, no un 4X.

Áreas máximas iniciales:

1. **Workshop** - armas y gadgets.
2. **Market** - consumibles, compras y equipo.
3. **Safehouse** - clases, loadouts y entrenamiento.
4. **Archive** - conceptos, lore, argumentos y material divulgativo opcional.
5. **Coalition Hall** - personajes, quests y acceso narrativo a mundos.

No existen timers, granjas, minas ni recursos que se recolectan cada hora.

La Agora se transforma visualmente conforme se incorporan personajes de otras corrientes. Es el lugar donde la coalición se vuelve visible.

---

# 11. Regla de diseño para ideologías

Cada ideología debe traducirse a cinco elementos:

| Elemento | Pregunta |
|---|---|
| Objeto | ¿Qué ve físicamente el jugador? |
| Obstáculo | ¿Qué le impide avanzar? |
| Regla | ¿Cómo cambia el gameplay? |
| Counterplay | ¿Qué puede hacer el jugador? |
| Idea | ¿Qué tensión o argumento representa? |

Además, cada mundo debe tener como máximo:

- 1 regla global principal;
- 2-4 obstáculos ideológicos;
- un set de enemigos característicos;
- 1 boss principal;
- variaciones suficientes para no repetir la misma gimmick.

La filosofía debe nacer del encounter. El Archive puede contener explicación más extensa para quien quiera profundizar.

---

# 12. World 0 - mecánicas propuestas

## 12.1 Ancap start: Aggression tutorial

Encounter inicial:

- MerchantBall neutral;
- RobberBall inicia confiscación/asalto;
- RobberBall pasa de Neutral/Threatening a Aggressor al iniciar el robo;
- el jugador aprende defensa, stun, shooting y defensa de terceros;
- MerchantBall permanece Neutral y no es un target ofensivo válido.

Lección: el NAP no exige recibir el primer golpe; prohíbe iniciar agresión y permite defender a terceros.

## 12.2 EgoistBall: ¿por qué obedecer?

Mecánica:

- contratos simples y gates;
- EgoistBall ignora un acuerdo;
- persecución o puzzle muestra que una norma necesita mecanismos de cumplimiento y reputación.

No se pretende "refutar al egoísmo"; se introduce el problema de fundamentar reglas morales y contractuales.

## 12.3 MutualistBall: occupancy and use

Mecánica:

- maquinaria/fábrica abandonada;
- título antiguo vs. uso actual;
- activar/desactivar maquinaria cambia plataformas;
- un recurso ocupado no puede ser utilizado simultáneamente por cualquiera.

Lección: incluso sistemas que rechazan propiedad privada convencional necesitan reglas de exclusión sobre recursos escasos.

## 12.4 LeftLibertarianBall: original appropriation

Mecánica:

- el jugador reclama un recurso;
- el claim crea una barrera y afecta una ruta usada por terceros;
- opciones: easement, fee, compensación, abandono del claim o ruta alternativa.

Lección: apropiación y acceso pueden entrar en conflicto.

## 12.5 BlackAnarchyBall: informal hierarchy

Mecánica:

- comunidad sin cargos formales;
- una PopularBall tiene un **Social Influence Aura**;
- NPC copian decisiones, cierran rutas o cambian actitud según su influencia;
- luego la comunidad introduce rotación/facilitadores para reducir concentración informal.

Lección: abolir títulos no elimina automáticamente influencia o jerarquías de facto.

## 12.6 Hierarchy vs coercive authority

Dos encounters consecutivos:

**Work crew voluntario**
- ForemanBall coordina;
- el jugador puede aceptar;
- puede abandonar;
- consecuencia: termina contrato.

**Checkpoint coercitivo**
- CommanderBall exige obediencia;
- el jugador intenta salir;
- salida denegada;
- rechazo produce detención/agresión.

Lección: jerarquía funcional voluntaria no es necesariamente autoridad coercitiva.

## 12.7 Ancom territory

Mecánica principal: **Common Pool / Mutual Aid**.

- NPC comparten curación y munición;
- daño puede ser redistribuido;
- roles rotan;
- supports se reemplazan;
- cooperación produce resiliencia real.

Tensión secundaria:
- recurso común insuficiente obliga a priorizar defensa/healing/plataformas;
- la coordinación colectiva tiene un coste de decisión.

Boss: **The AncomBall**.

El encounter se interrumpe por invasión del Leviatán. Las mecánicas aprendidas en el mundo se combinan para escapar.

---

# 13. Ejemplos de mecánicas para mundos posteriores

## 13.1 SocialdemBall

Regla global:
- withholding automático sobre pickups monetarios;
- estaciones de curación públicas gratuitas.

Obstáculos:
- TaxGate;
- PermitGate;
- Bureaucratic Queue;
- Inspection checkpoint.

Importante: mostrar beneficio y coste, no solo debuff.

## 13.2 Communist/Planned Economy

Regla global:
- asignación de suministros por zona.

Obstáculos:
- Quota Gate;
- Central Supply;
- Price-Control Shop con stock limitado;
- maquinaria sincronizada/planificada.

Counterplay:
- Agorist encuentra black markets;
- Trader crea intercambios;
- Tinkerer manipula maquinaria;
- Runner evita gates.

## 13.3 CorporatistBall

Regla global:
- mercados privados formalmente existentes, pero acceso condicionado por privilegios/licencias.

Obstáculos:
- License Gate;
- Exclusive Charter;
- Patent Gate;
- Customs Barrier.

Tema divulgativo:
**corporatismo/cronyism no equivale a libre mercado.**

## 13.4 Republican/DemocraticBall

Regla global:
- votaciones cambian elementos del nivel.

Ejemplos:
- se abre/cierra un puente;
- cambia un impuesto;
- se desbloquea una zona;
- una mayoría puede beneficiar o perjudicar al jugador.

Tema:
legitimidad de mayoría vs. consentimiento individual.

## 13.5 FascistBall / StalinistBall

Al aproximarse al Leviatán aumenta la coerción ambiental:

- surveillance;
- propaganda;
- conscription;
- restricted zones;
- secret police;
- checkpoints;
- industrial war machinery.

El jugador debe sentir espacialmente que está ascendiendo hacia autoridad concentrada.

---

# 14. Arquitectura técnica elegida

## 14.1 Motor y lenguaje

- **Godot 4.x estable** al iniciar el proyecto.
- **GDScript con tipado estático**.
- Renderer 2D adecuado a targets móviles; elegir Compatibility/Mobile durante el spike técnico según profiling.
- Evitar dependencia de C# en la primera versión para simplificar export multiplataforma.

## 14.2 Plataformas

Prioridad de desarrollo:

1. Windows/Steam.
2. Android.
3. iOS.
4. Linux/macOS si el coste de mantenimiento es bajo.

La lógica de input debe ser agnóstica al dispositivo desde el primer prototipo:

- keyboard/mouse;
- gamepad;
- touch.

## 14.3 Backend

No backend en MVP/vertical slice.

Save local primero. Integraciones de Steam Cloud, Google Play o iCloud se evalúan después.

## 14.4 Herramientas

- Git + GitHub;
- Git LFS para assets binarios pesados;
- Godot Editor;
- Aseprite/Krita u otra herramienta 2D según estilo final;
- Codex sobre el repositorio;
- CI con GitHub Actions cuando exista una build reproducible;
- Steamworks/GodotSteam solo después de validar core gameplay.

---

# 15. Arquitectura de software

## 15.1 Principio

**Composición sobre herencia profunda.**

Evitar árboles de clases enormes como `Enemy -> IdeologyEnemy -> CommunistEnemy -> GuardEnemy`.

Preferir componentes reutilizables:

- Health/Resolve;
- AggressionComponent / ConflictStateComponent;
- TargetValidityComponent;
- WeaponComponent;
- MovementComponent;
- FactionComponent;
- InteractionComponent;
- StatusEffectComponent;
- LootComponent;
- IdeologyModifierComponent.

## 15.2 Player

Un solo `PlayerController` base:

- movement;
- jump;
- interaction;
- aim;
- weapon;
- health/resolve;
- abilities.

La clase se aplica como `ClassLoadout`/Resource:

- stats;
- active abilities;
- passive abilities;
- allowed equipment;
- class-specific interactions.

## 15.3 BallCharacter

Escena reusable:

- CharacterBody2D;
- BodySprite;
- Eyes;
- IdeologySymbol;
- AccessoryAnchor;
- WeaponAnchor;
- CollisionShape;
- AnimationPlayer;
- StateMachine;
- componentes.

Las variaciones visuales se definen por datos.

## 15.4 Servicios/autoloads mínimos

Candidatos:

- `GameState`;
- `SaveService`;
- `SceneRouter`;
- `AudioService`;
- `EventBus` solo si evita acoplamiento real;
- `DataRegistry`.

No crear managers globales sin necesidad.

---

# 16. Estructura recomendada del repositorio

```text
anarchyball/
├── AGENTS.md
├── project.godot
├── docs/
│   ├── PROJECT_PLAN.md
│   ├── ARCHITECTURE.md
│   ├── GAMEPLAY_RULES.md
│   ├── LEVEL_DESIGN.md
│   └── ADR/
├── src/
│   ├── actors/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── npcs/
│   │   └── bosses/
│   ├── components/
│   ├── combat/
│   ├── classes/
│   ├── ideology/
│   │   ├── rules/
│   │   ├── modifiers/
│   │   └── factions/
│   ├── rpg/
│   ├── dialogue/
│   ├── hub/
│   ├── ui/
│   ├── save/
│   └── core/
├── levels/
│   ├── world_00_anarchists/
│   ├── world_01_minarchy/
│   └── prototypes/
├── data/
│   ├── levels/
│   ├── enemies/
│   ├── classes/
│   ├── ideology/
│   └── dialogue/
├── assets/
│   ├── art/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
├── tools/
│   ├── level_builder/
│   ├── level_validator/
│   ├── playtest/
│   └── telemetry/
└── tests/
    ├── unit/
    ├── integration/
    └── fixtures/
```

---

# 17. Niveles data-driven para Codex

## 17.1 Objetivo

Codex no debería editar manualmente miles de nodos de una `.tscn` para generar un nivel.

Se define un formato de **LevelSpec** legible por humanos y agentes. El juego o una herramienta de editor convierte esa especificación en una escena jugable.

## 17.2 Ejemplo LevelSpec

```json
{
  "id": "w0_mutualist_02",
  "world": "anarchist_frontier",
  "theme": "mutualist_industry",
  "difficulty": 2,
  "target_duration_seconds": 420,
  "required_mechanics": [
    "occupancy_use",
    "aggression"
  ],
  "sections": [
    {
      "id": "intro",
      "type": "traversal",
      "length": 800
    },
    {
      "id": "crane_dispute",
      "type": "ideology_puzzle",
      "rule": "occupancy_use"
    },
    {
      "id": "combat_01",
      "type": "combat",
      "encounter": "property_dispute"
    }
  ]
}
```

## 17.3 Dos estados del nivel

**Generated draft**
- creado/modificado por Codex;
- validado automáticamente;
- usado para experimentación.

**Curated shipping level**
- draft seleccionado;
- abierto/refinado en Godot;
- arte, ritmo y secretos ajustados manualmente;
- se conserva un LevelSpec para documentación y tests.

No se pretende que todo nivel final sea procedural.

---

# 18. Level Validator

El validador es una pieza central para trabajar con Codex.

Debe comprobar al menos:

- spawn válido;
- salida alcanzable;
- gaps dentro de límites del personaje;
- plataformas sin overlaps imposibles;
- checkpoints;
- enemigos colocados sobre superficies válidas;
- ausencia de softlocks conocidos;
- recursos mínimos para encounters obligatorios;
- referencias de assets/data válidas;
- reglas ideológicas requeridas presentes;
- duración/longitud dentro de rango aproximado.

Las capacidades físicas del jugador deben estar parametrizadas:

- velocidad;
- aceleración;
- gravedad;
- fuerza de salto;
- air control;
- dash si está desbloqueado;
- altura/anchura del collider.

No confiar en intuición espacial del LLM cuando una condición puede verificarse matemáticamente.

---

# 19. Playtesting automatizado y telemetría

## 19.1 Objetivo

Permitir que Codex reciba feedback sobre sus niveles.

Registrar por intento:

- completion rate;
- tiempo de finalización;
- muertes/derrotas por sección;
- daño recibido;
- ammo/resource starvation;
- rutas utilizadas;
- checkpoints;
- encounters evitados;
- errores/softlocks.

## 19.2 Bot

El bot no necesita jugar como humano perfecto. Puede existir en fases:

**Fase A**
- navegación geométrica;
- verifica reachability.

**Fase B**
- comportamiento básico de movimiento;
- simula saltos y hazards.

**Fase C**
- agente simple de combate;
- genera estadísticas útiles.

El playtesting humano sigue siendo obligatorio para validar "fun".

---

# 20. Contrato de trabajo con Codex

Codex debe trabajar como desarrollador sobre un proyecto con reglas explícitas, no como generador de archivos aislados.

## 20.1 Documentos de autoridad

Orden de prioridad sugerido:

1. `AGENTS.md`
2. `docs/PROJECT_PLAN.md`
3. `docs/ARCHITECTURE.md`
4. `docs/GAMEPLAY_RULES.md`
5. ADRs aceptados
6. código existente y tests

## 20.2 Reglas para cada tarea de Codex

Antes de modificar:

- leer archivos relevantes;
- identificar sistemas afectados;
- no duplicar una abstracción existente;
- mantener scope de la tarea.

Después de modificar:

- ejecutar tests;
- validar import del proyecto;
- ejecutar level validator si aplica;
- describir brevemente cambios;
- indicar deuda o decisiones pendientes;
- no declarar terminado un feature si no se puede probar.

## 20.3 Principios de implementación

- código simple > arquitectura especulativa;
- no crear sistema genérico hasta que existan al menos dos usos reales;
- evitar managers globales innecesarios;
- datos antes que `if world == X`;
- reglas ideológicas deben ser componibles;
- todo gameplay crítico debe tener una forma automatizable de prueba;
- no introducir plugins externos sin justificar su mantenimiento;
- no cambiar estilo visual/narrativo sin actualizar documentación.

---

# 21. Testing y CI

## 21.1 Capas

**Unit tests**
- fórmulas;
- stats;
- aggression/conflict state transitions;
- target validity y damage gating;
- voluntary duel;
- third-party defense;
- class modifiers;
- economy de Trader;
- ideology modifiers;
- save serialization.

**Integration tests**
- player + weapon;
- NPC aggression;
- surrender;
- checkpoint;
- ideology obstacle;
- level loading.

**Validation tests**
- LevelSpec;
- scene references;
- data registries.

**Smoke test**
- Godot abre/importa el proyecto sin errores;
- una escena bootstrap puede iniciarse;
- build/export de target principal cuando CI esté listo.

Puede adoptarse GdUnit4, GUT u otra solución tras un spike corto; no congelar el framework antes de probar compatibilidad con la versión de Godot elegida.

## 21.2 CI mínima

En pull requests:

1. validar formato/datos;
2. ejecutar Godot headless import;
3. ejecutar tests;
4. ejecutar LevelSpec validation;
5. fallar ante referencias rotas.

Builds completos multiplataforma pueden ejecutarse en ramas/tags de release para reducir coste.

---

# 22. Vertical slice inicial

## 22.1 Objetivo

Validar que el proyecto es divertido y que la arquitectura AI-friendly funciona.

Duración: **5-10 minutos**.

Contenido mínimo:

- AnarchyBall controlable;
- keyboard + gamepad;
- movimiento satisfactorio;
- jump;
- disparo;
- una clase inicial: Contractor;
- Aggression/Conflict State system;
- transición Neutral -> Threatening/Aggressor;
- gating de daño contra neutrales;
- 2 tipos de enemigos;
- 1 NPC neutral;
- 1 encounter de defensa de terceros;
- 1 obstáculo ideológico;
- 1 sección de plataformas;
- 1 checkpoint;
- 1 mini-boss/boss simple;
- HUD;
- save mínimo;
- LevelSpec -> LevelBuilder;
- LevelValidator;
- telemetría básica;
- un build Windows reproducible.

No intentar implementar World 0 entero antes de validar esto.

## 22.2 Tema recomendado del slice

Usar una sección temprana de **The Anarchist Frontier** porque permite validar:

- NAP;
- balls Neutral/Disputed/Threatening/Aggressor;
- combate;
- diálogo corto;
- propiedad/contrato como obstáculo;
- estética;
- boss/rival.

---

# 23. Fases de implementación

## Phase 0 - Foundation

Entregables:

- repo;
- `AGENTS.md`;
- Godot project;
- estructura de carpetas;
- input abstraction;
- bootstrap scene;
- CI smoke test;
- coding conventions;
- ADR-001: stack.

## Phase 1 - Movement & Combat Sandbox

Entregables:

- PlayerController;
- cámara;
- collisions;
- jump/movement;
- weapon;
- projectile;
- simple enemy;
- damage/resolve;
- debug room.

Criterio: el movimiento debe sentirse bien antes de añadir RPG.

## Phase 2 - Vertical Slice Systems

Entregables:

- AggressionComponent / ConflictState;
- Neutral/Disputed/Threatening/Aggressor/Surrendering/Neutralized;
- damage gating para neutrales y surrendered;
- third-party defense;
- VoluntaryDuel context;
- NPC interaction;
- Contractor;
- checkpoint;
- boss framework;
- HUD;
- save mínimo.

## Phase 3 - Data-Driven Level Pipeline

Entregables:

- LevelSpec schema;
- LevelBuilder;
- validator;
- sample generated levels;
- debug visualization de métricas de salto;
- tests.

Esta fase valida explícitamente el uso de Codex como diseñador asistido.

## Phase 4 - The Agora & RPG

Entregables:

- class selection;
- progression;
- equipment;
- Workshop;
- Market;
- Safehouse;
- Archive;
- Coalition Hall.

Mantener hub compacto.

## Phase 5 - World 0

Entregables:

- Egoist;
- Mutualist;
- Left-Libertarian;
- Black Anarchist;
- Ancom;
- Leviathan incursion;
- boss;
- tutorial completo;
- primeras rutas específicas por clase.

## Phase 6 - Remaining Classes

Entregables:

- Runner;
- Tinkerer;
- Trader;
- Agorist;
- balance inicial;
- rutas alternativas;
- habilidades.

## Phase 7 - Ideological Worlds

Crear mundos uno por uno. Cada mundo entra solo después de completar:

- design sheet;
- regla global;
- 2-4 obstáculos;
- enemigos;
- boss;
- LevelSpec templates;
- tests.

## Phase 8 - Leviathan & Panarchy

Entregables:

- final world;
- multi-phase boss;
- coalition mechanics;
- transformed map;
- epilogue jugable;
- cliffhanger contractarian.

## Phase 9 - Platform & Release

- Steam integration;
- achievements;
- Steam Deck/gamepad;
- Android UI/performance;
- iOS export/signing;
- cloud saves si aporta valor;
- localization;
- accessibility;
- store compliance.

---

# 24. Backlog inicial para Codex

## Epic A - Project foundation

- AB-001 Crear proyecto Godot y estructura.
- AB-002 Crear `AGENTS.md`.
- AB-003 Configurar input actions.
- AB-004 Crear bootstrap/debug scene.
- AB-005 Configurar test framework tras spike.
- AB-006 Crear CI headless smoke test.

## Epic B - Player

- AB-010 Implementar PlayerController.
- AB-011 Jump tuning.
- AB-012 CameraController.
- AB-013 WeaponComponent.
- AB-014 Projectile.
- AB-015 Health/Resolve.
- AB-016 InteractionComponent.

## Epic C - Combat ethics

- AB-020 Implementar `ConflictState`/AggressionComponent.
- AB-021 Implementar Neutral/Disputed/Threatening/Aggressor/Surrendering/Neutralized.
- AB-022 Implementar transiciones de agresión antes del daño físico.
- AB-023 Implementar damage gating contra Neutral/Disputed/Surrendering.
- AB-024 Implementar surrender/neutralization.
- AB-025 Implementar third-party defense trigger.
- AB-026 Implementar VoluntaryDuel context.
- AB-027 Implementar feedback `Not an aggressor` sin barra moral global.
- AB-028 Crear tests de estados y targets válidos.

## Epic D - Enemies

- AB-030 Base EnemyBrain.
- AB-031 RangedAggressorBall.
- AB-032 MeleeAggressorBall.
- AB-033 Basic turret/drone.
- AB-034 Boss state machine.

## Epic E - Level pipeline

- AB-040 Definir LevelSpec v0.
- AB-041 JSON loader.
- AB-042 LevelBuilder.
- AB-043 Jump reachability validator.
- AB-044 Spawn/exit validator.
- AB-045 Enemy placement validator.
- AB-046 Telemetry logger.
- AB-047 Prototype playtest bot.

## Epic F - Vertical slice

- AB-050 Construir nivel tutorial.
- AB-051 MerchantBall + RobberBall encounter.
- AB-052 Ideology obstacle prototype.
- AB-053 Contractor skill.
- AB-054 Mini-boss.
- AB-055 Save/checkpoint.
- AB-056 Packaging Windows.

---

# 25. Definition of Done

Un ticket de gameplay no está terminado hasta que:

- funciona en la escena objetivo;
- no rompe input;
- no genera errores en consola;
- tiene test cuando la lógica es determinista;
- usa datos/config si la variación lo exige;
- no introduce dependencia circular;
- está documentado si crea una nueva convención;
- puede ser reproducido por otro desarrollador/Codex;
- se ha probado al menos con keyboard y gamepad si afecta control;
- si afecta niveles, pasa LevelValidator;
- si afecta combate, demuestra mediante test que Neutral/Disputed/Surrendering no reciben daño ofensivo fuera de excepciones explícitas.

Un nivel no está terminado hasta que:

- spawn y salida son válidos;
- puede completarse con la clase base requerida;
- no tiene softlocks conocidos;
- sus checkpoints funcionan;
- su gimmick ideológica es comprensible;
- existe counterplay;
- su boss/encounter cumple el NAP design cuando aplica;
- ha sido jugado por un humano;
- la telemetría no muestra un cuello de botella accidental obvio.

---

# 26. Anti-scope: cosas que no debemos construir todavía

- mundo abierto continuo;
- 4X;
- city builder;
- economía macro persistente;
- multiplayer;
- PvP;
- MMO;
- blockchain/token;
- procedural generation infinita;
- servidor backend;
- marketplace online;
- 20 clases;
- crafting profundo;
- árbol político exhaustivo;
- representación de toda ideología existente;
- voice acting completo en la primera fase.

La versión 1 debe ganar profundidad mediante combinaciones de sistemas pequeños, no mediante cantidad ilimitada de features.

---

# 27. Riesgos principales

## Riesgo: "juego-podcast"

Mitigación: toda idea debe tener objeto, obstáculo, regla y counterplay antes de recibir diálogo largo.

## Riesgo: propaganda plana

Mitigación: mostrar fortalezas reales de sistemas rivales y dejar que los personajes formulen objeciones reconocibles.

## Riesgo: shooter incompatible con NAP

Mitigación: NAP como restricción estructural del moveset, ConflictState, defensa de terceros, agresión inminente antes del primer daño, duelos voluntarios, surrender y damage gating contra neutrales.

## Riesgo: RPG que se convierte en estrategia

Mitigación: limitar The Agora, hacer que Trader use Capital como recurso de acción y evitar simulación de población/economía.

## Riesgo: generación de niveles de baja calidad

Mitigación: LevelSpec + validator + telemetría + selección humana + refinamiento en editor.

## Riesgo: dependencia excesiva de Codex

Mitigación: documentación, tests, schemas y arquitectura que permitan entender el proyecto sin depender de contexto conversacional.

## Riesgo: scope ideológico infinito

Mitigación: solo entra una ideología si produce una mecánica distinta y sirve al arco narrativo.

---

# 28. Decisiones abiertas

Estas decisiones deben resolverse mediante pequeños spikes, no discusión infinita:

1. estilo visual final: pixel art vs. alta resolución vector-like;
2. cámara y resolución base;
3. aiming: 360°, 8 direcciones o auto-aim asistido;
4. touch controls exactos;
5. health vs. Resolve como nombre visible;
6. tamaño de árbol de habilidades;
7. framework de testing;
8. JSON puro vs. Resources de Godot como formato final de ciertos datos;
9. grado de backtracking;
10. orden final de mundos intermedios;
11. localización inicial: español/inglés o inglés primero;
12. tono de humor y nivel de referencias filosóficas explícitas.

---

# 29. Primer prompt de implementación para Codex

Cuando se cree el repositorio, el primer trabajo de Codex debería ser **fundacional**, no intentar implementar el juego completo.

Prompt recomendado:

> Lee `AGENTS.md` y `docs/PROJECT_PLAN.md`. Inicializa la base del proyecto Godot 4.x con GDScript tipado sin implementar todavía contenido narrativo. Crea una estructura mínima y mantenible para un side-scroller 2D: bootstrap scene, PlayerController, input actions para teclado/gamepad/touch abstracto, cámara básica y una debug room con suelo y plataformas. Añade un smoke test/headless validation apropiado para Godot y documenta cualquier decisión arquitectónica no cubierta por el plan en `docs/ADR/`. Mantén el alcance estricto: no implementes RPG, ideologías, enemigos ni level generation todavía. Al terminar, ejecuta las validaciones disponibles y reporta archivos modificados, pruebas ejecutadas y decisiones pendientes.

El segundo prompt debe enfocarse exclusivamente en **movement feel** y sandbox de combate.

---

# 30. Criterio de éxito de preproducción

La preproducción puede considerarse exitosa cuando exista un vertical slice donde:

- controlar a AnarchyBall sea divertido sin depender del tema político;
- el combate transmita claramente Neutral/Threatening/Aggressor/defense y no permita una ruta normal de agresión contra neutrales;
- una mecánica ideológica pueda entenderse jugando;
- al menos dos clases sugieran rutas diferentes;
- Codex pueda crear una variante de nivel mediante LevelSpec;
- el validador detecte un salto imposible o un softlock básico;
- el nivel pueda abrirse, probarse y corregirse en Godot;
- exista un build Windows compartible.

Solo después de cumplir esto debe comenzar la producción sistemática de mundos.

---

# 31. Principio final del proyecto

**Anarchyball debe ser primero un buen videojuego y después un vehículo de ideas.**

La tesis del juego no se demuestra porque un cuadro de diálogo declare que AnarchyBall tiene razón. Se demuestra cuando el jugador compara reglas, incentivos, restricciones y alternativas; aprende a distinguir jerarquía voluntaria de autoridad coercitiva; forma alianzas con personajes que siguen pensando distinto; derrota al Leviatán y termina en una panarquía donde la diversidad institucional puede existir sin una soberanía única. El propio sistema de combate debe reforzar esa tesis: AnarchyBall responde a agresión, protege a terceros y resuelve disputas ambiguas antes de habilitar la fuerza; no existe una ruta normal de "murderhobo con penalización".

La arquitectura debe reflejar la misma filosofía de diseño: sistemas pequeños, componibles, verificables y capaces de coexistir sin que una sola clase monolítica controle todo.
