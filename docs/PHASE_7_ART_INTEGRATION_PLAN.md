# Phase 7 - Plan de integración artística

- **Estado:** PROPUESTO para revisión
- **Fecha del inventario:** 2026-09-20
- **Alcance:** World 0 y la infraestructura mínima de presentación que necesita
- **Reglas preservadas:** `GR-CORE-001` a `GR-CORE-010`, `GR-CONFLICT-001`, `GR-COMBAT-001/002`, `GR-WORLD-001` a `GR-WORLD-005`, `GR-LEVEL-001` a `GR-LEVEL-009` y `GR-ENCOUNTER-001/002`

## 1. Conclusión ejecutiva

Los packs cubren con holgura fondos, tiles, props, criaturas auxiliares, efectos y música, pero no contienen la identidad principal de Anarchyball. El elenco "ball", sus estados de conflicto, los objetos ideológicos de World 0 y la UI propia todavía deben producirse.

La colección Warped no se tratará como un único estilo. Contiene varias familias internamente coherentes, pero con densidad de píxel, perspectiva, paleta y acabado diferentes. El spike local ya integrado usa **Twilight Forest** como base visible provisional de `w0_01`. Para conservar coherencia, esa familia será la columna ambiental de World 0 mientras supera la prueba de escala con personajes:

- `Environments/Tiwlight Forest Files` para capas, paleta y props visibles;
- `Playable Characters/Caves Hunter` únicamente como referencia de cadencia de animación;
- `Enemies/Caves Enemies` únicamente como referencia de ciclos y lectura lateral;
- `Items, VFX and Props/Caves Fx` como candidatos que deberán adaptarse a la escala Twilight.

Los packs Pozac siguen siendo viables, pero como biblioteca curada de VFX. No se importarán ni utilizarán en bloque. Cada efecto elegido recibirá un ID semántico, escala entera, paleta aprobada y un propósito jugable concreto.

## 2. Inventario observado

El directorio `assets/` contiene aproximadamente:

- 8.053 archivos y 154 MB;
- 6.688 PNG y 629 GIF;
- 572 fuentes `.ase`, `.aseprite` o `.psd`;
- 65 archivos de audio;
- 10 packs Pozac;
- Warped dividido en familias de entornos, personajes, enemigos, props/VFX, vehículos y música.

También contiene `__MACOSX`, archivos AppleDouble y previews que no deben entrar al import de runtime. Casi todo el material está todavía sin seguimiento en Git y `.gitattributes` no configura Git LFS.

### Familias Warped relevantes

| Familia | Cobertura interna | Uso propuesto |
|---|---|---|
| Twilight Forest | fondo por capas, tiles y props | base ambiental provisional de World 0 |
| Caves | entorno, tiles, props, jugador, enemigos y VFX | referencia técnica; no mezclar directamente con Twilight |
| City / City 2 | entorno urbano, personajes, enemigos y VFX | reservar para un mundo urbano posterior |
| Warped Station | estación, jugador, enemigos y VFX | reservar como referencia del Leviatán |
| Quiet Hill | entorno, jugador, enemigos, items y VFX | reservar para una zona de tensión/horror |
| Sewers | entorno, jugador, enemigo y VFX | reservar para una subzona coherente completa |
| Warped Lava | entorno, jugador, enemigos, items y VFX | reservar para una subzona coherente completa |
| Streets of Fight | escenario y personajes de beat 'em up | referencia de animación; no usar su piso en perspectiva en el side-scroller |

No se mezclarán directamente estas familias dentro de World 0. Un asset de otra familia solo entra después de redibujarse o recolorearse contra la biblia Twilight aprobada.

## 3. Biblia técnica provisional

### Resolución y pixel grid

- Mantener el viewport existente de 1280x720.
- El spike Twilight usa fuentes de 240 píxeles de alto a escala 3x; esta es la primera escala que debe validarse.
- Usar un grid fuente de 16x16, que a 3x ocupa 48x48 unidades de juego.
- Trabajar con escalas enteras y una misma densidad efectiva de píxel en foreground, personajes y VFX. Las capas lejanas pueden simplificarse deliberadamente por profundidad.
- Configurar filtro `nearest`, evitar mipmaps en sprites 2D y activar pixel snap donde no afecte la suavidad de cámara.
- Validar la escala 3x a 1280x720 antes de retocar colisiones, movimiento o convertir más assets.

### Personajes ball

- Lienzo fuente objetivo: 24x32 o 32x32 por frame a escala 3x; el laboratorio decidirá cuál conserva mejor accesorios y emblemas.
- Silueta visible: cuerpo de 48-54 unidades, compatible con el collider actual del jugador.
- El acabado conserva volumen, iluminación y detalle de pixel art compatibles con Warped; no imita el trazo tosco ni la planitud del meme.
- Polcompball se usa como gramática de identidad interior: combinaciones de color, particiones tipo bandera y símbolos cuando sean necesarios para distinguir cada ball.
- Los ojos son formas blancas expresivas, con contorno y sin pupilas ni iris.
- Capas: cuerpo animado, superficie ideológica, ojos, accesorio opcional, sombra y socket de arma.
- Para AnarchyBall, la superficie inicial es una diagonal amarilla/negra; el gran emblema frontal deja de ser necesario.
- El arma apunta con un pivot separado; no se generan ocho copias completas del cuerpo para cada ángulo.
- Los estados de conflicto se comunican con pose, icono y animación además de color.
- No se prioriza una animación de muerte: surrender, desarme, huida y neutralización son los finales canónicos del combate ordinario.

Cadencia de referencia tomada de los JSON de Caves Hunter. Sus lienzos de 80x80 sirven como referencia de timing y poses, no como tamaño directo del personaje final:

| Estado | Frames objetivo | Cadencia inicial |
|---|---:|---:|
| idle/blink | 6-8 | 100-140 ms |
| move/roll | 8-10 | 60-80 ms |
| jump start/rise/apex/fall/land | 8-11 total | 80-120 ms |
| fire/recoil | 3-5 | 60-80 ms |
| hurt | 3-4 | 80-100 ms |
| threatening | 4-6 | 90-120 ms |
| surrendering | 4-6 y hold | 100-140 ms |
| neutralized | 1 pose o loop de 4 | 120-180 ms |

No se producirán todavía crouch, dash, wall-cling o habilidades de clases futuras si el gameplay actual no las consume.

### VFX

Los sheets Pozac observados usan principalmente celdas de 64, 96, 128 y tamaños mayores. Frente al pixel grid Twilight a 3x, no son drop-in: a 1x tendrían un grano mucho más fino y a 3x resultarían enormes. Los elegidos deben recortarse, reducirse o redibujarse al grid del juego antes de exportarlos. Los efectos grandes se reservan para bosses, maquinaria o eventos de escenario.

Primer catálogo semántico propuesto:

- `vfx_muzzle_defensive`;
- `vfx_projectile_trail_player`;
- `vfx_projectile_trail_hostile`;
- `vfx_hit_valid_light`;
- `vfx_hit_blocked_neutral`;
- `vfx_resolve_break`;
- `vfx_surrender`;
- `vfx_machine_disable`;
- `vfx_pickup`;
- `vfx_checkpoint`;
- `vfx_landing_dust`;
- `vfx_leviathan_breach`, reservado para `w0_07`.

El feedback bloqueado y el impacto válido deben ser visualmente distintos. Eso permite que un intento contra un neutral enseñe target validity sin parecer daño aplicado.

## 4. Estructura de archivos propuesta

```text
assets/
  licenses/
  art/
    art_bible/
    actors/balls/
    world_0/
    vfx/
    ui/
  audio/
  THIRD_PARTY_ASSETS.md

# Los packs fuente permanecen localmente en sus carpetas actuales,
# ignorados por Git y fuera de las referencias de runtime.
```

Acciones de higiene:

1. conservar licencias y procedencia;
2. evitar que packs fuente, previews, GIF y archivos de trabajo se importen con `.gdignore` cuando sea posible;
3. copiar a `assets/art/` y `assets/audio/` únicamente exports curados usados por el runtime;
4. retirar `__MACOSX`, `.DS_Store` y AppleDouble del árbol de trabajo;
5. configurar Git LFS antes de versionar binarios pesados;
6. no publicar los packs fuente en un repositorio accesible como si fueran una redistribución de assets;
7. no usar archivos del pack como dataset de entrenamiento; cualquier generación o edición seguirá la interpretación de licencia aprobada y conservará registro de procedencia.

Los nombres de runtime serán `snake_case` y no dependerán de rutas del vendedor como `Effect (31)-Sheet.png`.

## 5. Arquitectura de presentación

La presentación observará el gameplay; nunca decidirá target validity, daño, surrender ni resolución.

### Componentes mínimos

1. Una escena de presentación de misión: recibe `LevelSpec`, construye únicamente decorado y puede reemplazarse sin tocar gameplay. El spike ya usa `presentation_scene` con este contrato.
2. `BallVisualDefinition` (`Resource` tipado): frames, emblema, paleta, offsets, sockets y nombres de animación.
3. `BallVisual` (`Node2D`): reproduce animación y compone cuerpo, ojos, emblema, accesorio y arma.
4. `VfxDefinition` (`Resource` tipado): `vfx_id`, `SpriteFrames`, loop, escala y offset.
5. `VfxEmitter` local: instancia one-shots desde señales de jugador, proyectil, receiver, resolve, checkpoint y rule object.

No se propone un autoload ni un manager visual global. El builder recibe una escena opcional y los actores reciben perfiles explícitos. La geometría y colisiones de `LevelSpec` permanecen autoritativas; el arte es una capa reemplazable. No se extrae un `LevelArtProfile` genérico hasta que la segunda misión demuestre datos realmente compartidos.

### Integración con lo existente

- `PlayerVisual` deja de dibujar círculos y pasa a controlar `BallVisual`, conservando un fallback debug.
- `CombatTarget` delega `_draw()` a una presentación hija y expone señales suficientes para `NEUTRAL`, `THREATENING`, `AGGRESSOR`, `SURRENDERING` y `NEUTRALIZED`.
- `EnemyArchetype` referencia una definición visual por ID o recurso, sin ramas por ideología.
- `LevelBuilder` conserva el `presentation_scene` opcional ya introducido; si no existe mantiene backdrop y plataformas debug para tests y prototipos.
- `AimProbe` y `HostileBolt` conservan física y efectos; una presentación hija reemplaza círculos/líneas.
- Los decorados de shipping se curan sobre la escena de misión sin contaminar `LevelSpec` con coordenadas cosméticas prematuras.

## 6. Slice artístico inicial: `w0_01_first_aggression`

Este nivel será el único consumidor de producción inicial. Antes de abrir las otras seis misiones se debe demostrar el flujo completo de importación, animación, señales, VFX y legibilidad.

### Reutilización directa o adaptada

- capas y props Twilight Forest ya curados en `assets/art/world_0/frontier_forest/`;
- timings de Caves Hunter como referencia, sin usar al humano como protagonista ni su tamaño de lienzo directamente;
- Caves Fx adaptado al grid Twilight para impactos pequeños, pickup y power-up;
- una selección de Pozac convertida al grid para muzzle flash, impacto válido, bloqueo y resolve break;
- música Warped solo después de elegir una pista que no compita con telegraphs y HUD.

### Assets que deben producirse

- `AnarchyBall`: idle, move, jump, fire, hurt y neutralized/recovery;
- `MerchantBall`: idle, alert, threatened, relieved;
- `RobberBall`: idle, threatening, committed attack, hurt, surrendering y neutralized;
- arma/socket y proyectil defensivo del Contractor;
- proyectil hostil del RobberBall;
- iconos no dependientes de color para neutral, amenaza, agresor, rendición y objetivo inválido;
- checkpoint, exit, tres pickups y señalética del tutorial;
- módulos de suelo/bordes que extiendan Twilight a los nueve tramos del LevelSpec;
- panel HUD pixel, barras legibles e iconos de teclado/gamepad coherentes;
- VFX semánticos enumerados para este slice.

### Criterios de aceptación

- no cambia movimiento, collider, velocidad de proyectil ni ventanas de target validity;
- neutral, amenaza, agresión y rendición se reconocen sin leer la etiqueta y sin depender solo de color;
- el muzzle coincide con el origen real del proyectil en ambos facing directions;
- no hay filtrado borroso, escalas fraccionales ni jitter visible de cámara;
- los VFX no ocultan al actor, la trayectoria o el momento de surrender;
- teclado y gamepad completan el nivel;
- importación, batch validation, smoke, runtime, suite y build Windows siguen pasando;
- se repiten los playtests humanos de P7.1 después del cambio visual antes de promover la misión.

## 7. Backlog visual por misión de World 0

| Misión | Base reutilizable | Producción faltante |
|---|---|---|
| `w0_01_first_aggression` | Twilight Forest curado + Caves Fx/Pozac adaptados | AnarchyBall, MerchantBall, RobberBall, tiles de frontera, HUD y estados de conflicto |
| `w0_02_contract_bridge` | misma frontera y tiles | EgoistBall, kit modular de puente, terminal/contrato, aceptar/cumplir/incumplir/salir |
| `w0_03_occupancy_workshop` | tiles y props base | MutualistBall, maquinaria, palancas, ciclos, señal de uso/abandono/disputa y props de taller |
| `w0_04_claim_and_access` | terreno y rutas de frontera | postes de claim, cercas, easement, fee/compensación, desvíos y feedback de consecuencias |
| `w0_05_hierarchy_without_titles` | módulos de asentamiento derivados | work crew, roles rotables, influencia informal, opt-in/opt-out y checkpoint coercitivo claramente distinto |
| `w0_06_common_pool` | arena y props derivados | AncomBall, Common Pool, enlaces de soporte, estaciones, escasez, borde de duelo y fases del boss |
| `w0_07_leviathan_escape` | toda la gramática anterior | fuerza del Leviatán, barricadas, drones, focos, alarma, breach y destrucción/escape; Station solo como referencia redibujada |

## 8. Qué falta generar más allá de World 0

### Identidad principal

- roster completo de balls y variaciones de emblemas/accesorios;
- bosses con silueta y fases propias;
- retratos y expresiones para diálogo;
- logo, key art y arte de tienda.

### Sistema ambiental

- transiciones coherentes entre tiles;
- variantes de daño, foreground y occlusion;
- puertas, checkpoints, señalética y máquinas de cada mundo;
- props ideológicos que comuniquen beneficio, coste y counterplay sin depender del texto.

### UI y accesibilidad

- fuente pixel legible con licencia compatible;
- iconos de acciones para teclado, Xbox, PlayStation y touch;
- cursores, botones, paneles, mapa, inventario y Archive;
- símbolos/patrones redundantes para estados que hoy usan color.

### Audio no cubierto por spritesheets

Warped Music aporta música. El primer perfil reutilizable de SFX ya cubre salto, disparo, daño, impactos válidos e inválidos, amenaza, agresión y surrender mediante `GameplayAudioProfile`; continúan faltando rodar/pasos, aterrizaje, pickups, UI final, checkpoints finales, maquinaria y ambientes. Deben compartir la misma taxonomía semántica de los VFX.

## 9. Orden de ejecución

### A0 - Gobernanza e importación

- catalogar licencia y procedencia;
- separar source/runtime;
- limpiar residuos;
- añadir `.gdignore` y Git LFS;
- fijar presets de importación pixel art.

Gate: Godot importa únicamente los assets curados y el repositorio no redistribuye por accidente los packs fuente.

Estado observado: parcialmente implementado fuera de este documento. Ya existen exclusiones en `.gitignore`, catálogo `assets/THIRD_PARTY_ASSETS.md`, copias de licencia y una selección curada de Twilight Forest y música. Faltan confirmar `.gdignore`, política de Git LFS y limpieza de residuos locales.

### A1 - Laboratorio visual

- [x] crear una escena `art_lab` fuera de campaña;
- [x] definir una plantilla reutilizable de atlas `32x32`, perfil de identidad y prompt maestro para todo el elenco ball;
- validar las alternativas 24x32 y 32x32 a 3x, collider, facing, arma pivotada, nearest y cámara;
- comparar Caves Fx y una docena máxima de candidatos Pozac;
- aprobar paleta, outlines, sombras y contraste.

Gate: AnarchyBall, un NPC y un agresor pueden mostrar todos los estados requeridos sin tocar reglas de gameplay.

Estado observado: existe un spike de presentación para `w0_01` que repite capas Twilight a 3x y aplica música/tema al shell. `levels/prototypes/art_lab.tscn` añade dos concept anchors generados y dos prototipos deterministas sobre grid exacto para comparar 24x32 y 32x32, facing, aim y los seis estados visuales. Sigue siendo provisional hasta comprobarlo visualmente en Godot y elegir una escala.

El set conceptual completo de World 0 está registrado en `world0_ball_roster.json` y puede revisarse sobre el entorno curado mediante `levels/prototypes/world0_roster_lab.tscn`. El registro histórico incluye nueve identidades: AnarchyBall, MerchantBall, RobberBall, EgoistBall, AgoristBall, MutualistBall, LeftLibertarianBall, BlackAnarchyBall y The AncomBall. Revisión 2026-09-22: AgoristBall queda como referencia conceptual de clase, no NPC a producir; no se borra el asset ni se altera aquí el roster runtime. Priorizar las cinco balls aliadas de `LEVEL_01_COALITION.md`; el arte del jefe espera aprobación de identidad. Continúan siendo anclajes conceptuales hasta reconstruirse en el atlas exacto.

### A2 - Presentación reemplazable

- [x] implementar `BallVisualDefinition` y `BallVisual` con fallback debug;
- [x] conectar movimiento del jugador y estados de conflicto de `CombatTarget` a keyposes visuales;
- [x] conectar movimiento, salto, disparo, daño y estados de conflicto al selector visual;
- [x] conectar esos eventos a un perfil de SFX reemplazable y espacializado;
- conectar proyectiles y resolve a VFX finales;
- conservar fallback debug;
- añadir validadores de referencias y nombres de animación.

Estado observado: AnarchyBall, MerchantBall y RobberBall cuentan con keyposes `768x96`, atlas de animación borrador `768x768` y perfiles explícitos integrados en `w0_01`. El runtime preserva detalle a `1x`, usa una escala corporal compartida por personaje y mantiene `idle` estable para evitar pulsación de tamaño. Selecciona `idle`, `move`, `jump`, `action`, `hurt`, `threatening`, `surrendering` y `neutralized` desde datos; disparo y pérdida de vida activan overrides temporales sin condicionar gameplay por identidad. Los intermedios repetidos del borrador todavía deben redibujarse antes del pase final.

Gate: cambiar un perfil visual no cambia resultados deterministas de combate.

### A3 - Art pass de `w0_01`

- producir el trío de personajes y su entorno;
- integrar VFX, HUD y props;
- ajustar exclusivamente offsets, timing visual y legibilidad;
- repetir todas las validaciones técnicas y humanas.

Gate: `w0_01` queda como plantilla comprobada para la siguiente misión.

### A4 - Producción secuencial

- ejecutar el mismo ciclo para `w0_02` a `w0_07`;
- generar únicamente assets consumidos por la misión activa;
- revisar la biblia después de cada gate sin abrir mundos posteriores.

## 10. Pruebas y evidencias

Automatizadas:

- todo `visual_id` y `vfx_id` resuelve;
- cada perfil contiene las animaciones obligatorias para su rol;
- frames, FPS/duraciones, offsets y escalas son válidos;
- el fallback headless funciona sin depender del render;
- los tests existentes de target validity, conflicto, LevelSpec y campaña no cambian.

Humanas:

- lectura de silueta y estados a velocidad real;
- ausencia de blur, jitter, z-fighting y popping;
- separación clara entre hit válido, hit bloqueado y surrender;
- contraste de HUD/fondo y prueba sin depender solo de color;
- teclado y gamepad;
- captura de referencia aprobada por misión antes de continuar.

## 11. Decisiones que no se toman todavía

- no se elige una familia Warped para cada mundo futuro;
- no se produce el roster completo;
- no se crea un importador universal de Aseprite hasta que dos flujos reales lo necesiten;
- no se modifica `LevelSpec` para decoración;
- no se cambia la resolución, física, cámara ni colisiones para acomodar sprites;
- no se generan assets de clases que siguen fuera de Phase 7.
