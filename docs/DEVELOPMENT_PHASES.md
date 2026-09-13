# Fases de desarrollo de Anarchyball

**Estado:** roadmap operativo v1.1; MVP aprobado
**Fecha base:** 2026-08-21  
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

### Phase 7 - World 0: The Anarchist Frontier

Construir sus segmentos con el patrón enseñar, demostrar, desafiar, combinar y culminar. Incluir Egoist, Mutualist, Left-Libertarian, Black Anarchist, Ancom y la incursión del Leviatán sin romper los contratos del MVP.

### Phase 8 - Classes, Agora and RPG Lite

Agregar Runner, Tinkerer, Trader y Agorist de una en una. Luego construir The Agora compacta, progresión compartida, equipo y Archive. Cada clase debe completar contenido requerido y heredar target validity.

### Phase 9 - Ideological Worlds

Producir un mundo a la vez. Ninguno entra al backlog de producción sin design sheet, regla principal, beneficio/coste cuando corresponda, counterplay, 2-4 obstáculos, enemigos, boss, templates y tests.

### Phase 10 - Leviathan and Panarchy

Crear mundo final, boss por justificaciones, contribuciones mecánicas de la coalición, mapa transformado, epílogo jugable y cliffhanger contractarian.

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
| Port prematuro | tiempo móvil frena core loop | conservar abstracciones, aplazar polish por plataforma |

## 8. Próximo hito recomendado

El MVP técnico y su gate humano están aprobados. El próximo hito es **Phase 6 - Content Factory v1**:

1. convertir los contratos existentes en plantillas y validación por lote;
2. probarlos con una segunda regla ideológica, un nuevo arquetipo enemigo y un segundo nivel data-driven;
3. someter el nuevo nivel a validación automatizada y playtest humano antes de promoverlo.

World 0 completo, las clases restantes, The Agora y el RPG permanecen fuera de alcance hasta superar el gate de Phase 6. La comprobación del build en máquina limpia y la observación del CI remoto siguen como tareas operativas previas a un release público.
