# Fases de desarrollo de Anarchyball

**Estado:** roadmap operativo v1.3; MVP aprobado
**Fecha base:** 2026-08-21  
**Última revisión:** 2026-09-12
**Objetivo:** llegar primero a un MVP jugable con un motor de gameplay y contenido suficientemente sólido para producir después niveles, enemigos, clases y mecánicas sin reescribir el núcleo.

## 1. Definición de éxito

El MVP no es una versión reducida de toda la campaña. Es una **vertical slice de 8-12 minutos** que demuestra simultáneamente:

- que moverse, saltar, apuntar y responder a amenazas es divertido;
- que la no iniciación de agresión funciona como regla estructural y legible;
- que un enemigo puede rendirse y dejar de ser objetivo válido;
- que un encounter admite más de una resolución práctica;
- que una regla ideológica cambia el espacio o la interacción y tiene counterplay;
- que una clase modifica la forma de jugar sin estar codificada dentro del player;
- que un nivel nace de datos, se valida, se construye y registra telemetría local;
- que el proyecto importa, ejecuta tests y produce un build Windows reproducible.

Al terminar el MVP debe ser barato crear **contenido nuevo**; no necesariamente debe ser barato crear una categoría de juego completamente nueva.

## 2. Alcance jugable del MVP

### Experiencia

Una misión temprana de **The Anarchist Frontier**:

1. tutorial corto de movimiento y disparo sobre un objetivo mecánico;
2. encuentro MerchantBall/RobberBall: amenaza, confiscación comprometida, defensa de tercero y rendición;
3. sección de plataformas con checkpoint y una ruta opcional etiquetada;
4. obstáculo ideológico basado en acceso/contrato o maquinaria ocupada, con dos counterplays;
5. encuentro con dos arquetipos de agresor y una máquina hostil;
6. mini-boss que establece la legitimidad del combate, cambia de fase y termina por Resolve/surrender;
7. resumen de misión y reinicio rápido desde checkpoint durante los intentos fallidos.

### Contenido mínimo

- una clase jugable: `Contractor`;
- una habilidad observable: `Defensive Response`;
- un NPC neutral y uno protegido;
- dos arquetipos de enemigo reutilizables;
- una torreta, drone o máquina hostil;
- un mini-boss;
- una regla ideológica;
- un nivel completo y al menos un fixture imposible para el validador;
- HUD mínimo, pausa, audio placeholder y feedback visual no dependiente solo del color;
- save/checkpoint local mínimo.

### Fuera del MVP

- The Agora completa;
- las otras cuatro clases;
- World 0 completo y mundos posteriores;
- árboles RPG extensos, crafting o loot aleatorio;
- generación procedural de niveles de shipping;
- backend, nube, logros, tiendas de plataforma o multiplayer;
- arte final, voice acting y localización completa;
- controles táctiles finales, aunque la arquitectura de input y UI no debe impedirlos.

## 3. Capacidades del motor exigidas por el MVP

| Capacidad | Evidencia en el MVP | Extensión posterior |
|---|---|---|
| Input abstracto | teclado y gamepad alimentan las mismas acciones | touch y aim assist sin ramas en gameplay |
| Movimiento configurable | controller usa `PlayerMovementProfile` | perfiles, assists y Runner opcional |
| Composición de actores | NPC, agresores y boss comparten componentes | nuevos enemigos combinando capacidades |
| Conflicto central | una API decide todo efecto ofensivo | nuevas armas, drones, summons y traps sin loopholes |
| Encounter data-driven | triggers, objetivos y resoluciones declarados | quests y bosses con el mismo contrato |
| Clases por loadout | Contractor se aplica sin ramas en controller | Runner, Tinkerer, Trader y Agorist por datos/componentes |
| Reglas ideológicas | una regla modifica entorno/interacción | catálogo de reglas por mundo |
| LevelSpec versionado | el nivel/fixture carga desde spec | generación asistida y migraciones |
| Builder + Validator | produce escena y rechaza una ruta imposible | plantillas, métricas y lotes de niveles |
| Checkpoint/save | retry conserva estado necesario | progreso de campaña y The Agora |
| Observabilidad | razones de agresión, resolución y softlocks | balance automatizado y herramientas editoriales |
| Tests/build | suite headless y build Windows | CI, Android/iOS y regresión de contenido |

Este es el significado concreto de “motor avanzado” para el proyecto: contratos estables, extensiones por composición, datos validados, diagnóstico y pruebas. El MVP evita networking, ECS propio, scripting arbitrario, editores visuales personalizados y otras infraestructuras que no prueban el core loop.

## 4. Fases hasta el MVP

Las duraciones se expresan en iteraciones; se estiman después del primer spike y no funcionan como fechas contractuales.

### Phase 0 - Foundation

**Meta:** repositorio ejecutable y decisiones reversibles documentadas.

Entregables:

- Git, ignores, atributos y convenciones;
- proyecto Godot y escena bootstrap;
- estructura inicial y documentos de autoridad;
- ADR de stack;
- selección mediante spike de versión exacta de Godot y framework de tests;
- acciones de input abstractas y smoke import.

Gate de salida:

- el proyecto abre sin errores en la versión elegida;
- la escena principal arranca en headless;
- un test trivial se ejecuta localmente;
- teclado y gamepad generan acciones, no llamadas device-specific.

### Phase 1 - Feel First Sandbox

**Meta:** demostrar que controlar a AnarchyBall es divertido sin contenido narrativo.

Entregables:

- `PlayerMovementProfile`;
- movimiento horizontal, aceleración, frenado y air control;
- salto variable, coyote time y jump buffer;
- cámara con límites, smoothing probado y screen shake ajustable;
- aim abstracto, arma/projectile básicos y dummy mecánico;
- debug room con métricas visibles y sección corta de plataformas.

Gate de salida:

- movimiento aprobado por playtest humano con teclado y gamepad;
- 30 minutos de repetición sin fallos de input/cámara conocidos;
- tests de coyote time, buffer y alcance base;
- no se inicia producción de World 0 antes de superar este gate.

### Phase 2 - Ethical Combat Kernel

**Meta:** cerrar la invariancia más riesgosa del juego: quién puede recibir fuerza y por qué.

Entregables:

- `ConflictStateComponent` con estados canónicos;
- razones explícitas de transición a `AGGRESSOR`;
- `TargetValidity` y `EffectContext` compartidos;
- Health para player, Resolve para balls y permisos para máquinas;
- telegraph `THREATENING -> AGGRESSOR`;
- defensa de terceros, duelo voluntario y surrender;
- dos arquetipos de enemigo y una máquina;
- tests de todos los casos de `GAMEPLAY_RULES.md` §25.1.

Gate de salida:

- neutral, disputed, threatening no comprometido y surrendering bloquean efectos ofensivos;
- armas directas e indirectas usan la misma decisión;
- el jugador puede actuar antes del primer impacto y defender un NPC;
- debug muestra estado, razón y permiso;
- no existe una barra moral global ni una recompensa letal.

### Phase 3 - Content Engine

**Meta:** convertir el núcleo en una plataforma de producción de contenido comprobable.

Entregables:

- registros por ID estable;
- `ClassLoadout`, `EnemyArchetype`, `EncounterDefinition` e `IdeologyRuleDefinition` mínimos;
- schema `LevelSpec v0` con versión explícita;
- loader, `LevelBuilder` y mensajes de error accionables;
- `LevelValidator` para referencias, spawn/salida, geometría base, encuentros y recursos;
- fixture válido y fixture imposible;
- telemetría local de secciones, retry, daño, rutas, resolución e invalid-target attempts.

Gate de salida:

- modificar datos cambia una variante sin editar el player;
- un ID desconocido falla con archivo y campo;
- el validador rechaza el salto imposible intencional;
- el nivel requerido es alcanzable con movimiento y clase base;
- los datos inválidos no producen un fallo silencioso en runtime.

### Phase 4 - MVP Vertical Slice

**Meta:** ensamblar las capacidades en una experiencia completa de 8-12 minutos.

Entregables:

- Contractor y `Defensive Response`;
- nivel descrito en §2;
- checkpoint/retry rápido y save mínimo versionado;
- HUD y feedback de conflicto;
- objetivo, introducción y cierre breves;
- mini-boss con legitimidad, regla temática, adaptación y surrender;
- audio/arte placeholder coherentes y legibles;
- menú mínimo de inicio, pausa y reinicio.

Gate de salida:

- un jugador nuevo completa el slice sin explicación externa;
- entiende por presentación cuándo el objetivo es válido;
- el obstáculo ideológico se entiende antes de leer lore;
- existen al menos dos resoluciones o rutas en un encounter obligatorio cuando es práctico;
- el retry desde checkpoint tarda pocos segundos y no repite diálogo largo.

### Phase 5 - MVP Hardening

**Meta:** convertir el slice en una base compartible, medible y resistente a regresiones.

Entregables:

- corrección de bloqueos y problemas de legibilidad detectados en playtests;
- balance inicial basado en telemetría local;
- opciones básicas de accesibilidad: shake, subtítulos, escalado y señales no basadas solo en color;
- suite headless estable;
- pipeline de CI mínimo;
- export preset y build Windows reproducible;
- guía para añadir un enemigo, encounter, regla y nivel sin tocar el núcleo.

Gate final del MVP:

- todos los criterios de `GAMEPLAY_RULES.md` §26 pasan;
- tres playtests completos consecutivos no encuentran softlocks;
- una variante de nivel se crea por datos y pasa validación;
- un segundo arquetipo se añade por composición sin modificar `PlayerController`;
- build Windows se ejecuta en una máquina limpia de desarrollo;
- deuda y decisiones abiertas quedan registradas, no escondidas en comentarios.

## 5. Fases después del MVP

### Phase 6 - Content Factory v1

Endurecer plantillas, herramientas de editor, fixtures, generador asistido y documentación. Probar la extensibilidad creando una segunda regla ideológica, un tercer enemigo y un segundo nivel. Solo promover a shipping contenido curado y probado por humanos.

Entregables adicionales para diseño de niveles:

- plantilla de ficha editorial asociada a `level_id`, sin romper el schema cerrado de `LevelSpec v0`;
- clasificación de misión y objetivos de primera vuelta, repetición limpia, completionist, ruta efectiva y checkpoints;
- reporte derivado de telemetría con tiempo total, tiempo por sección, retry, uso de checkpoints y rutas;
- comparación del segundo nivel contra su presupuesto, con decisión explícita de expandirlo, recortarlo o reclasificarlo.

Gate de producción de niveles:

- el segundo nivel supera validación estructural y puede completarse con movimiento base;
- cinco beats aparecen a escala de nivel o existe una excepción justificada por el tipo de misión;
- al menos tres primeras vueltas de jugadores nuevos y tres repeticiones limpias quedan registradas antes de promoverlo;
- el tiempo no proviene principalmente de espera, diálogo obligatorio, oleadas repetidas o backtracking forzado;
- cualquier extensión de `LevelSpec v0` actualiza schema, parser, validator, fixtures y tests mediante una decisión ADR; si es incompatible, también crea nueva versión y migración.

Un segundo nivel retenido explícitamente como `technical_prototype` no se promociona ni necesita simular escala de campaña. Debe conservar una ficha validada, producir el reporte de evidencia y apuntar a un `campaign_successor_id` distinto. Para World 0, `occupancy_workshop_draft` queda como fixture y `w0_03_occupancy_workshop` será una misión separada.

### Phase 7 - World 0: The Anarchist Frontier

Construir sus segmentos con el patrón enseñar, demostrar, desafiar, combinar y culminar. Incluir Egoist, Mutualist, Left-Libertarian, Black Anarchist, Ancom y la incursión del Leviatán sin romper los contratos del MVP. Usar el paquete provisional de siete misiones de `PROJECT_PLAN.md` §12.8: 64-79 minutos de misiones y 75-95 minutos al incluir transiciones, intermisiones y hub. Revisar el rango después de cada lote de playtests, sin rellenar segmentos para cumplirlo.

El plan operativo vive en [`PHASE_7_PLAN.md`](PHASE_7_PLAN.md). La producción comienza por P7.0 y `w0_01_first_aggression`; las demás misiones no entran simultáneamente al backlog detallado.

P7.1 ya dispone de shell local, progreso versionado, checkpoint por nivel, finalización condicionada, outcomes de telemetría y el draft independiente `w0_01_first_aggression`. Su promoción queda bloqueada hasta completar teclado/gamepad y reunir tres recorridos `first_clear` y tres `clean_replay`.

### Phase 8 - Classes, Agora and RPG Lite

Agregar Runner, Tinkerer, Trader y Agorist de una en una. Luego construir The Agora compacta, progresión compartida, equipo y Archive. Cada clase debe completar contenido requerido y heredar target validity.

### Phase 9 - Ideological Worlds

Producir un mundo a la vez siguiendo los paquetes provisionales de `PROJECT_PLAN.md` §13.6. Ninguno entra al backlog de producción sin design sheet, regla principal, beneficio/coste cuando corresponda, counterplay, 2-4 familias de obstáculos, enemigos, boss, templates y tests. El punto de partida es cuatro misiones estándar y un clímax, aproximadamente 45-65 minutos de juego de misión; el número final se decide por variedad mecánica y datos, no por cuota.

Gate por mundo:

- la regla primaria se prueba primero en un prototype aislado;
- la primera misión demuestra una fortaleza o promesa comprensible y la segunda introduce su límite;
- cada misión posterior añade una decisión nueva, no solo más enemigos o decoración;
- el clímax combina la regla con sistemas conocidos y establece legitimidad de combate cuando aplica;
- el paquete completo tiene perfiles humanos de primera vuelta y repetición limpia antes de iniciar el siguiente mundo;
- corrientes agrupadas conservan subzonas y mecánicas diferenciadas conforme a `GR-WORLD-005`.

### Phase 10 - Leviathan and Panarchy

Crear las cinco misiones de Leviathan y las dos viñetas jugables de Panarchy descritas en `PROJECT_PLAN.md` §13.6. El boss cambia entre Tradition, Majority, Planning, Security y Leviathan; la coalición aporta verbos y counterplays jugables, no solo cameos. El epílogo transforma el mapa, muestra asociaciones voluntarias y cierra con el cliffhanger contractarian sin combate obligatorio.

Gate de campaña:

- Leviathan ocupa 50-64 minutos de misiones y su boss final 12-15 minutos de primera vuelta;
- Panarchy ocupa 7-10 minutos y conserva control del jugador durante el cierre;
- la campaña completa cae inicialmente entre 403 y 514 minutos de misiones, aproximadamente 8-11 horas con Agora e intermisiones;
- cada aliado requerido en el boss final fue presentado y tiene una contribución mecánica observable;
- ninguna fase final exige recordar una regla que no se haya reintroducido de forma breve y segura.

### Phase 11 - Platform and Release

Optimización, Steam/Steam Deck, Android, iOS, localización, accesibilidad completa, achievements, saves de plataforma, compliance y preparación de tiendas. Ninguna integración comercial debe bloquear el gameplay offline.

## 6. Orden para ampliar el motor después del MVP

Para evitar una reescritura, cada nuevo contenido debe usar este orden:

1. definir experiencia y criterio de aceptación;
2. intentar expresarla con contratos existentes;
3. si falta capacidad, agregar el componente o hook más pequeño;
4. cubrirlo con una prueba y observabilidad;
5. crear contenido data-driven;
6. validar y construir;
7. playtest humano y curación;
8. registrar telemetría y ajustar.

Una nueva ideología no justifica una rama en `PlayerController`. Un enemigo nuevo no justifica una jerarquía profunda. Una excepción de target validity necesita una regla explícita del encounter, no un nombre especial.

## 7. Riesgos y puntos de corte

| Riesgo | Señal temprana | Acción |
|---|---|---|
| Sobrearquitectura | semanas sin escena divertida | detener infraestructura y cerrar Phase 1 |
| Motor rígido | segundo enemigo exige editar player/weapon | extraer contrato comprobado y añadir test |
| NAP confuso | muchos invalid-target attempts | mejorar telegraph/feedback antes de culpar al jugador |
| Scope narrativo | diálogo antes de existir mecánica | exigir objeto, regla, obstáculo y counterplay |
| LevelSpec frágil | datos inválidos fallan en runtime | mover la comprobación al schema/validator |
| Generación mediocre | specs válidos pero aburridos | mantener curación y playtest humano obligatorios |
| Duración artificial | el tiempo crece por espera, diálogo o repetición | medir por sección y recortar, reclasificar o añadir decisiones reales |
| Escala espacial engañosa | `bounds.width` parece largo pero la ruta es trivial | medir ruta efectiva en pantallas equivalentes y probar recorrido limpio |
| Port prematuro | tiempo móvil frena core loop | conservar abstracciones, aplazar polish por plataforma |

## 8. Presupuesto operativo de niveles

Los valores canónicos viven en `GAMEPLAY_RULES.md` §22 y su intención de producto en `PROJECT_PLAN.md` §11.1. Resumen para planificación:

| Tipo | Primera vuelta | Repetición limpia | Completionist | Ruta efectiva | Checkpoints |
|---|---:|---:|---:|---:|---:|
| Desafío opcional | 1-3 min | menos de 2 min | hasta 4 min | 2-5 pantallas | 0 |
| Misión corta | 4-7 min | 2-4 min | 6-10 min | 7-11 pantallas | 0-1 |
| Misión estándar | 8-12 min | 4-6 min | 10-16 min | 12-18 pantallas | 1-2 |
| Clímax | 12-15 min | 6-9 min | 15-22 min | 16-24 pantallas | 2-3 |

Cada nivel atraviesa este ciclo:

1. **Brief:** tipo, regla primaria, cinco beats, counterplay y objetivos de tiempo/recorrido.
2. **Greybox:** ruta base completa, rutas opcionales y checkpoints; sin usar arte o diálogo para ocultar falta de espacio jugable.
3. **Validación:** referencias, geometría, alcance base, objetivos y ausencia de softlocks.
4. **Playtest:** primera vuelta, repetición limpia y completionist cuando corresponda; tiempo por sección y punto de derrota.
5. **Curación:** ajustar densidad y cadencia; luego arte, secretos y exposición opcional.

Cada mundo posterior atraviesa un ciclo equivalente: beneficio o promesa, coste, counterplay, combinación y clímax. El target inicial es cuatro misiones estándar y un clímax; un paquete se reduce si no sostiene cinco decisiones diferentes.

Una pantalla equivalente mide recorrido efectivo normalizado contra el viewport actual de referencia de 1280 px. Ascensos, descensos y retornos significativos cuentan; el ancho del bounding box no basta. Si cambia el viewport base, las fichas se renormalizan.

Los specs `mvp_vertical_slice` y `occupancy_workshop_draft` son evidencia del pipeline y los contratos actuales, no de la escala final de campaña. `occupancy_workshop_draft` queda retenido como `technical_prototype`: no se expande ni se reclasifica como misión de campaña. Su sucesor `w0_03_occupancy_workshop` será un LevelSpec separado, diseñado contra el presupuesto de una misión estándar y sin alargar contenido mediante más vida enemiga o exposición.

El sobre provisional completo es de 44 misiones/viñetas y 403-514 minutos de primera vuelta dentro de niveles. Los desafíos opcionales viven primero dentro del presupuesto completionist de cada misión y no aumentan este conteo por defecto. Solo se convierte en backlog el mundo activo; el resto conserva estatus de planificación hasta superar el gate del mundo anterior.

## 9. Próximo hito recomendado

El MVP y **Phase 6 - Content Factory v1** están aprobados. Phase 6 cerró el 2026-09-20 con `occupancy_workshop_draft` retenido como prototipo técnico no promocionable. Sus recorridos históricos sin perfil no se reclasifican; el gate de tres primeras vueltas y tres repeticiones limpias se aplicará al primer candidato real a shipping.

El próximo hito es **Phase 7 - World 0: The Anarchist Frontier**:

1. crear el plan ejecutable de World 0 a partir del paquete provisional de siete misiones;
2. producir primero un slice de campaña pequeño con brief, cinco beats, presupuesto y ficha editorial;
3. mantener `occupancy_workshop_draft` como fixture y crear `w0_03_occupancy_workshop` como LevelSpec independiente cuando corresponda;
4. reutilizar los contratos del MVP y abrir extensiones únicamente ante gaps comprobados;
5. validar, medir y curar cada candidato antes de ampliar el siguiente lote.

Las clases restantes, The Agora y el RPG siguen fuera de alcance hasta Phase 8. La comprobación del build en máquina limpia y la observación del CI remoto continúan como tareas operativas previas a un release público.
