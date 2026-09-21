# Arquitectura de Anarchyball

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

### 3.3 Actores y clases

`BallCharacter` es una escena base visual y de integración. Sus capacidades se agregan mediante componentes. El jugador usa un único controller; `ClassLoadout` aporta habilidades, modificadores, equipo e interaction tags. Agregar una clase no debe requerir editar ramas por clase dentro del controller.

### 3.4 Encuentros y reglas de mundo

`EncounterDefinition` declara estados iniciales, triggers, objetivos, resoluciones y recompensas. Cada placement construido puede tener un `EncounterRuntimeObserver` local que relaciona sus actores y `rule_object_ids`, y emite como máximo una resolución declarada; no existe un quest manager global. Los placements opcionales `actors` materializan NPC de catálogo que existen en el mundo sin fingir que pertenecen a un encounter. `IdeologyRuleDefinition` configura hooks limitados sobre pickup, interacción, spawn o ambiente. Las reglas de mundo nunca aparecen como `if current_world == ...` en el player.

Los NPC neutrales o aliados pueden declarar líneas breves en su `EnemyArchetype`. `NpcDialogueBubble` presenta esas líneas en espacio de mundo, avanza mediante la acción abstracta `interact` y no modifica `ConflictState`, elegibilidad ofensiva ni resolución de encounters. El diálogo tutorial aporta contexto a una mecánica ya observable; no sustituye su implementación.

La presentación de World 0 centraliza su densidad de píxel y profundidad de superficie en `World0ArtMetrics`. El terreno, la decoración y los props pequeños de Warped usan escalas enteras y filtro nearest; ningún actor de presentación aplica escalas fraccionarias que produzcan píxeles desiguales. Los elementos de escenario sin función jugable se dibujan detrás del terreno. `WorldPropPlacement` ajusta todo prop apoyado a la superficie física de la plataforma bajo su coordenada horizontal; checkpoints, máquinas y futuros props grounded no dependen de offsets manuales. Los pickups que flotan conservan una política separada e intencional. `platforms[].art_style` separa semántica de ruta y presentación: `road` usa el pavimento principal, mientras `column_supported` usa el piso elevado de Warped y columnas continuas hasta el soporte inferior. `required` nunca decide qué arte estructural corresponde.

Las cuatro capas ambientales de World 0 usan `Parallax2D`: el cielo permanece casi fijo y montañas, árboles lejanos y árboles cercanos aumentan progresivamente su desplazamiento horizontal. La repetición corresponde al ancho escalado de cada textura y el desplazamiento vertical permanece unido a la cámara para no alterar la lectura de plataformas.

## 4. Motor de contenido

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

Una abstracción nueva requiere dos usos reales o una invariancia crítica ya documentada. Una decisión que cambie stack, dependencias, formato persistente o una regla difícil de revertir se registra en `docs/ADR/`.
