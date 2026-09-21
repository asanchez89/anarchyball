# World 0 runtime ball prototypes

Esta carpeta contiene dos niveles de material por cada ball integrada:

- `*_keyposes.png`: ocho poses fuente en una tira `768x96`;
- `*_animation_draft.png`: atlas de prueba `768x768`, organizado en ocho filas de estado.

`tools/art/build_ball_keypose_atlases.gd` divide las hojas conceptuales aprobadas en ocho segmentos, recorta transparencia y calcula **una sola escala por personaje** usando la pose de mayor tamaño. Cada figura cabe en un máximo de `88x88` y comparte baseline `y=90` dentro de celdas `96x96`. El concepto se reduce con Lanczos una sola vez; el runtime lo muestra a `1x`.

Los atlas resultantes miden `768x96` y permiten validar inmediatamente:

- escala 3x frente a Twilight Forest;
- pivote y collider;
- facing;
- lectura de idle, movement, action, threatening, surrendering y neutralized;
- conexión data-driven mediante `BallVisualDefinition`.

Los atlas `*_animation_draft.png` reutilizan esas poses para probar el contrato de runtime, los tiempos y las transiciones. Sus filas son, en orden: `idle`, `move`, `jump`, `action`, `hurt`, `threatening`, `surrendering` y `neutralized`. `idle` mantiene una pose estable para evitar el efecto de agrandamiento/encogimiento artificial. El borrador de `move` conserva una pose direccional estable: la pose conceptual de giro no se reproduce como paso. `source_facing_direction` declara la orientación original del arte y el runtime voltea solo el sprite, no el nodo que calcula inclinación y movimiento. Las celdas vacías al final de una fila no forman parte de su ciclo; `BallVisualDefinition` declara el número de frames y FPS de cada estado.

Antes de promoción a producción deben redibujarse los intermedios sobre el mismo atlas maestro `768x768` y completar los ciclos definidos en `assets/art/art_bible/ball_generation/README.md`. No se deben ampliar keyposes de baja resolución ni declarar los borradores como animación final.
