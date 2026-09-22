# Phase 7 - World 0: The Anarchist Frontier

- **Estado:** EN DESARROLLO; P7.0 COMPLETADA, P7.1-P7.3 IMPLEMENTADAS Y PENDIENTES DE EVIDENCIA HUMANA
- **Inicio:** 2026-09-20
- **Dependencia:** Phase 6 aprobada y cerrada el 2026-09-20
- **Plan visual propuesto:** [`PHASE_7_ART_INTEGRATION_PLAN.md`](PHASE_7_ART_INTEGRATION_PLAN.md)
- **Reglas afectadas:** `GR-WORLD-001` a `GR-WORLD-005`, `GR-LEVEL-001` a `GR-LEVEL-009`, `GR-ENCOUNTER-001/002`, `GR-TELEM-001/002` y las reglas canónicas de conflicto aplicables

## Revisión activa — 2026-09-22

Avance implementado: entrada independiente `NIVEL 1 · NUEVO TALLER`, ambientación
industrial Warped y primer encuentro acumulativo BlackAnarchy junto a las tres
balls previas. No incluye todavía parte 3 ni jefe. Véase estado reproducible en
`LEVEL_01_COALITION.md`; el progreso histórico se conserva por separado.

La producción siguiente se rige por [LEVEL_01_COALITION.md](LEVEL_01_COALITION.md):
parte 1 Mutualist/Ancom/Egoist; parte 2 BlackAnarchy; parte 3 LeftLibertarian;
jefe estatista local con los cinco apoyos. Agorist es clase, no NPC. Se preservan
los prototipos existentes y sus IDs; routing, guardado y onboarding se migrarán
con pruebas, no por renombrado de archivos. Identidad del jefe pendiente de aprobación.

Secuencia pendiente: validar taller → coordinación/relevos BlackAnarchy →
uso/acceso reversible LeftLibertarian → enseñar apoyos e integrar jefe →
playtest de recorrido completo y reanudación. Los checklists P7.0–P7.3 conservan
su evidencia histórica; P7.4–P7.7 y las siete misiones siguientes son material
fuente, **no el orden de backlog vigente**. Gate humano: probar las tres partes,
checkpoint antes del jefe y sus resoluciones con teclado/gamepad; reunir tres
`first_clear` y tres `clean_replay` del nivel compuesto.

## Objetivo histórico (sustituido por la revisión activa)

Construir el primer mundo real de campaña como siete misiones independientes, conectadas por un flujo mínimo y producidas de una en una. World 0 debe enseñar movimiento, target validity, defensa de terceros, surrender y las primeras reglas ideológicas; después debe recombinarlas durante la incursión del Leviatán.

La fase no consiste en convertir prototipos en campaña por cambio de nombre. Cada misión candidata a shipping tendrá un `LevelSpec`, una ficha editorial, evidencia propia, curación humana y un ID estable nuevo.

## Decisión de producción

World 0 se implementará en orden. Solo la misión activa entra en detalle de producción; las siguientes permanecen como briefs hasta superar el gate anterior.

El primer slice será `w0_01_first_aggression` porque reutiliza contratos ya aprobados —movimiento, MerchantBall, agresión observable, defensa de terceros y surrender— y añade únicamente las capacidades nuevas que ahora sí tienen uso comprobado: entrada de campaña, transición entre misiones y progreso local mínimo.

`occupancy_workshop_draft` permanece intacto como fixture técnico. `w0_03_occupancy_workshop` será otro nivel, con geometría, pacing, perfil y evidencia de campaña propios.

## Paquete histórico de misiones (no acumulativo con el nivel compuesto)

| Orden | ID | Función principal | Tipo | Primera vuelta |
|---:|---|---|---|---:|
| 1 | `w0_01_first_aggression` | onboarding, MerchantBall, agresión, defensa y rendición | misión corta | 6-8 min |
| 2 | `w0_02_contract_bridge` | EgoistBall, contrato simple y cumplimiento | misión estándar | 8-10 min |
| 3 | `w0_03_occupancy_workshop` | MutualistBall, uso actual, exclusión y maquinaria | misión estándar | 10-12 min |
| 4 | `w0_04_claim_and_access` | apropiación, easement, compensación y acceso | misión estándar | 8-10 min |
| 5 | `w0_05_hierarchy_without_titles` | influencia informal y jerarquía voluntaria frente a coerción | clímax | 12-14 min |
| 6 | `w0_06_common_pool` | mutual aid, recurso común y duelo con The AncomBall | clímax | 12-15 min |
| 7 | `w0_07_leviathan_escape` | incursión y escape recombinando reglas anteriores | misión estándar | 8-10 min |

Objetivo provisional: 64-79 minutos dentro de misiones y 75-95 minutos con transiciones e intermisiones breves. Los rangos orientan la curación; nunca autorizan espera, oleadas repetidas, diálogo obligatorio o backtracking artificial.

## Límites de alcance

Phase 7 incluye:

- Contractor como única clase requerida;
- el primer nivel compuesto y sus fichas por parte; el resto de World 0 requiere replanificación;
- flujo mínimo de inicio, desbloqueo, transición y reanudación de campaña;
- reglas, actores y encounters necesarios para esas misiones;
- assets Warped prioritarios, arte nuevo solo cuando falte, telemetría y curación humana;
- presión policial recurrente y jefe estatista local como cierre del nivel 1; no el boss final Leviathan;

Phase 7 no incluye:

- Runner, Tinkerer, Trader o Agorist jugables;
- The Agora completa, tiendas, crafting o progresión RPG;
- producción de mundos posteriores;
- el boss final The LeviathanBall;
- backend, nube, multiplayer o economía persistente;
- arte, audio, narrativa o localización finales.

Las rutas opcionales pueden declarar tags futuros, pero la ruta obligatoria siempre usa Contractor y movimiento base.

## Backlog ejecutable

### P7.0 - Brief de mundo y auditoría de contratos

- [x] crear una matriz de las siete misiones con regla primaria, beneficio, coste, counterplay, encounters y dependencias;
- [x] identificar capacidades reutilizables y gaps reales sin abrir abstracciones genéricas;
- [x] definir el contrato mínimo de navegación y progreso entre más de una misión;
- [x] reservar los IDs de nivel del paquete y los IDs de contenido de P7.1 sin registrar contenido futuro inexistente;
- [x] definir eventos de telemetría y criterios de aceptación antes de implementar;
- [x] identificar el cambio de LevelSpec que requiere ADR antes de P7.1.

Resultado: [`PHASE_7_CONTRACT_AUDIT.md`](PHASE_7_CONTRACT_AUDIT.md) confirma que movimiento, conflicto, composición, catálogo, builder y telemetría base son reutilizables. Los gaps acotados son shell/progreso de campaña, checkpoints por nivel, autoridad de finalización, archivo de intentos incompletos y una ventana real entre agresión e impacto. El brief de `w0_01_first_aggression` fija perfil, cinco beats, IDs y gates antes de escribir gameplay.

Gate:

- cada misión puede explicar qué decisión nueva aporta;
- ningún sistema se implementa solo para una misión futura sin consumidor actual;
- el orden de dependencias permite construir `w0_01_first_aggression` sin diseñar todo el mundo en código.

### P7.1 - Campaign slice y `w0_01_first_aggression`

- [x] implementar el flujo mínimo de entrada, inicio de misión, finalización, retorno y reanudación;
- [x] crear un LevelSpec nuevo; no reutilizar ni renombrar `mvp_vertical_slice`;
- [x] crear su perfil `short_mission`, documentando la excepción de primera vuelta 6-8 min por onboarding;
- [x] enseñar movimiento, aim, target validity, defensa de MerchantBall y surrender mediante acciones observables;
- [x] conservar MerchantBall como objetivo ofensivo inválido y registrar intentos inválidos;
- [x] incluir ruta base de 7-11 pantallas efectivas y como máximo un checkpoint;
- [ ] completar el nivel con Contractor usando teclado y gamepad;
- [ ] reunir tres `first_clear` y tres `clean_replay` antes de promoverlo.

Gate:

- un jugador nuevo entiende a quién puede defender y cuándo RobberBall se convierte en Aggressor;
- el nivel termina, registra su evidencia y vuelve al shell sin un manager global innecesario; el desbloqueo se prueba de forma determinista y la primera transición real se integra en P7.2;
- importación, validación por lote, smoke, runtime, suite y build Windows pasan.

Estado técnico al 2026-09-20: shell y misión están integrados como escena principal; importación, lote de 6 LevelSpecs y 2 perfiles, smoke, arranque runtime, 95/95 tests y export Windows pasan. Permanecen abiertos el playtest humano con ambos controles y las tres muestras de cada perfil antes de promover el draft.

### P7.2 - `w0_02_contract_bridge`

- [x] definir un contrato simple, consentimiento explícito, cumplimiento observable y salida disponible;
- [x] introducir EgoistBall sin convertirlo en una facción criminal genérica;
- [x] expresar bridge/access contract mediante datos y el componente más pequeño que cubra sus usos reales;
- [x] construir cinco beats a lo largo de 12-18 pantallas efectivas y 1-2 checkpoints;
- [x] ofrecer al menos una resolución no ofensiva y registrar incumplimiento, persecución o puzzle;
- [ ] curar el candidato con evidencia humana propia.

Gate: la mecánica demuestra que escribir una norma y hacerla cumplir son problemas distintos, sin declarar un ganador filosófico mediante diálogo.

Estado técnico al 2026-09-20: `w0_02_contract_bridge` está registrado como segunda misión real de campaña y usa un contrato data-driven con estados `offered -> active -> performed -> breached -> resolved`. El consentimiento abre el acceso, el incumplimiento activa una persecución/puzzle sin volver ofensivamente válido a EgoistBall, la resolución por desvío reabre el retorno y habilita la recompensa, y la ruta base permite rechazar el contrato y completar el nivel. La extensión de `LevelSpec v0` está documentada en ADR-0008 y cuenta con validación de referencias, checkpoint, telemetría y pruebas deterministas. Importación, lote de 7 LevelSpecs y 3 perfiles, arranque de campaña y misión, 110/110 tests y export Windows pasan sobre el árbol combinado con la integración audiovisual. Permanecen abiertos el playtest humano con teclado/gamepad, la comprobación de los cinco beats y la evidencia `first_clear`/`clean_replay` antes de promover el draft.

### P7.3 - `w0_03_occupancy_workshop`

- [x] crear un LevelSpec y perfil de campaña separados del fixture de Phase 6;
- [x] reutilizar `occupancy_machine` y el enforcer únicamente donde encajen;
- [x] mostrar primero utilidad real de maquinaria abandonada y después exclusión/disputa;
- [x] diseñar 12-18 pantallas efectivas, 1-2 checkpoints y cinco beats de misión estándar;
- [x] incluir rutas que usen la maquinaria sin volverla requisito de clase;
- [ ] comparar pacing y comprensión contra los hallazgos del prototipo, no contra su geometría.
- [x] separar ruta obligatoria de estilo visual y reconstruir los ascensos finales con piso elevado y columnas continuas;
- [ ] ambientar el recorrido como taller comunal conectado y sustituir pasillos vacíos por desafíos de ocupación estatal y decisiones de traversal;
- [x] abrir con una PoliceBall obligatoria y alternar arenas cerradas de policía, patrullas Ancom desescalables y disputas Egoist con resolución observable;
- [x] añadir un ascensor activable y conservar una ruta baja de recuperación para evitar bloqueos de progreso;

Gate: el candidato cumple 10-12 min de primera vuelta por decisiones y recombinación, no por inflar el prototipo.

Estado técnico al 2026-09-20: `w0_03_occupancy_workshop` es una tercera misión independiente de 14 pantallas equivalentes, cinco secciones y dos checkpoints. Añade placements mínimos de actores neutrales y los estados compatibles `abandoned`/`disputed` mediante ADR-0009. La ruta enseña restauración de maquinaria, muestra una operación actual que excluye uso simultáneo y termina en una disputa con dos resoluciones: operar una máquina alternativa antes de la agresión o responder defensivamente después de una orden de detención comprometida. `occupancy_workshop_draft` permanece intacto como fixture. Importación, lote de 8 LevelSpecs y 4 perfiles, arranque de campaña y misión, 117/117 tests y export Windows pasan; queda abierta la comparación humana de pacing y comprensión.

### P7.4 - `w0_04_claim_and_access`

- [ ] permitir establecer un claim controlado que cambie traversal o acceso de terceros;
- [ ] ofrecer easement, fee/contrato, compensación, abandono o ruta alternativa según el encounter;
- [ ] hacer visible la consecuencia del claim antes de pedir una decisión;
- [ ] mantener toda escalada ofensiva bajo `TargetValidity` y razones inspeccionables;
- [ ] construir y curar una misión estándar de 8-10 min.

Gate: la apropiación crea una consecuencia espacial comprensible y al menos dos respuestas prácticas sin convertir una disputa en agresión automática.

### P7.5 - `w0_05_hierarchy_without_titles`

- [ ] crear una subzona de influencia informal con efectos observables sobre NPC y rutas;
- [ ] demostrar una mitigación mediante rotación o facilitación distribuida;
- [ ] presentar después un work crew voluntario con opt-in y salida real;
- [ ] contrastarlo con un checkpoint coercitivo cuya detención sí activa agresión;
- [ ] mantener separadas las identidades mecánicas exigidas por `GR-WORLD-005`;
- [ ] curar un clímax de 12-14 min con 2-3 checkpoints.

Gate: el jugador experimenta la diferencia entre coordinación, influencia informal y autoridad que impide salir.

### P7.6 - `w0_06_common_pool`

- [ ] implementar `CommonPool` con un beneficio real de mutual aid;
- [ ] introducir escasez visible que obligue a priorizar curación, soporte o traversal;
- [ ] hacer rotables o reemplazables los roles de soporte;
- [ ] construir el duelo reglado con The AncomBall sin habilitar fuerza fuera de su contexto;
- [ ] evitar que focused DPS ignore la red de apoyo;
- [ ] preparar la interrupción o transición hacia la incursión sin incluir todavía el mundo final.
- [ ] introducir patrullas Ancom desconfiadas con evasión/desescalada y agresión solo tras compromiso observable.
- [ ] configurar las patrullas Ancom para surrender/retirada temprana tras escalar, reutilizando la política de arquetipo sin condicionar por facción.

Gate: cooperación y escasez se entienden jugando; el duelo usa consentimiento y conserva surrender/target validity.

### P7.7 - `w0_07_leviathan_escape`

- [ ] escalar la ocupación ya visible mediante refuerzos del Leviatán que clasifican asociaciones sin borrar sus diferencias;
- [ ] recombinar mutual aid, maquinaria, rutas de escape, movimiento y defensa de terceros;
- [ ] reutilizar reglas anteriores con recordatorios seguros y breves;
- [ ] construir presión de escape sin autoscroll injusto ni espera pasiva;
- [ ] cerrar World 0 con aliados todavía ideológicamente distintos;
- [ ] registrar finalización del mundo y transición provisional al siguiente hito.

Gate: el escape funciona como examen jugable de World 0 y no como una cinemática larga o una preview del boss final.

### P7.8 - Curación integral y cierre

- [ ] recorrer el nivel compuesto (tres partes y jefe) desde una partida limpia;
- [ ] verificar desbloqueo, reanudación, checkpoints y transición entre escenas;
- [ ] comprobar Contractor, teclado y gamepad en todas las rutas obligatorias;
- [ ] reunir evidencia de primera vuelta y repetición limpia por candidato promovido;
- [ ] ajustar duración por sección, densidad, backtracking y checkpoints;
- [ ] ejecutar validación completa, CI y build Windows;
- [ ] registrar deuda y decisiones de recorte sin ocultarlas en contenido placeholder.

## Gate final de Phase 7

- [ ] las tres partes y el jefe tienen referencias estables, perfiles, escenas curadas y transición/checkpoint probados;
- [ ] World 0 enseña las reglas una a una y las recombina en el escape;
- [ ] ninguna misión requerida depende de una clase posterior;
- [ ] ningún actor es atacable por ideología o nombre;
- [ ] las corrientes convergen contra la incursión sin perder diferencias mecánicas;
- [ ] duración, ruta efectiva y checkpoints se apoyan en evidencia humana;
- [ ] una partida limpia puede comenzar, avanzar, reanudarse y completar el mundo;
- [ ] suite, contenido, importación, runtime y build reproducible pasan;
- [ ] no quedan softlocks conocidos con teclado o gamepad.

## Estrategia de pruebas

Cada subfase debe incluir:

1. pruebas unitarias para lógica determinista nueva;
2. fixtures válidos e inválidos para datos y referencias;
3. validación por lote de todo el catálogo y todos los LevelSpecs;
4. arranque headless de la misión activa;
5. playtest humano con teclado y gamepad;
6. perfiles `first_clear` y `clean_replay` para candidatos a shipping;
7. reporte de archivos, reglas `GR-*`, pruebas y limitaciones conocidas.

## Primer paso recomendado

El siguiente paso es **validar P7.1, P7.2 y P7.3 manualmente** con teclado y gamepad. Para P7.3 se debe comprobar que una máquina abandonada habilita utilidad real, una máquina ocupada rechaza uso simultáneo, la máquina disputada no concede permiso ofensivo, ambas resoluciones del encounter funcionan y los dos checkpoints restauran estados. Después se reunirán tres muestras `first_clear` y tres `clean_replay` de cada candidato. P7.4 no comenzará hasta revisar esa evidencia y decidir si el pacing del slice requiere curación.
