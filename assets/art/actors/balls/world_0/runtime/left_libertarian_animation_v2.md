# LeftLibertarian — bandera blanca

Generado con image_gen integrado a petición del usuario, 2026-09-23.
Referencia de estilo: black_anarchy_animation_v2.png. Emblema: imagen adjunta
del usuario, A negra con barra horizontal roja y círculo rojo sobre blanco.
Atlas 4×4: idle, movimiento, acción/amenaza, rendición. Archivo original
conservado. Integrada en `left_libertarian_ball_visual.tres` y retrato del tutorial.
Calibración por frame excluye el accesorio superior: cuerpo runtime 76×76,
apoyo y=18, atlas 4×4 con celda de 313×300px sobre región
`Rect2(0, 30, 1252, 1200)`. El recorte de recurso elimina contaminación entre
filas sin alterar el PNG original. GR-LEVEL-002, sin cambios de gameplay.
Importación headless aprobada; 12 pruebas en `reports/left_v2_tests.log`.
Capturas revisadas de frames y del nivel, incluyendo retrato vinculado a v2.

## Prompt utilizado

Use case: precise-object-edit. Create corrected LeftLibertarian game animation sprite sheet using image 1 (BlackAnarchy 4x4 sheet) as exact layout, style, silhouette and pose reference; image 2 is authoritative emblem reference. Replace black sphere surface with WHITE flag color, softly shaded white/light grey, and replace white circled A with reference emblem: BLACK capital A legs, RED horizontal crossbar, RED circle. Emblem on side cheek away from eyes, fully readable and consistent in all 16 frames. Keep eyes distinct black outlines, no symbol overlapping eyes. Same glossy outlined game-ball style, same sphere diameter and baseline across frames, same 4 columns x4 rows evenly spaced grid. Row1 idle four blinking poses; row2 movement four subtly leaning poses with same body diameter; row3 threatening/action four tense poses; row4 surrender four tired lowered eyes, not happy. Keep small dark top cord accessory similar to BlackAnarchy. No yellow, no purple body sectors, no equality symbol. No extra text, grid lines or labels. True transparent background alpha, not checkerboard. Every complete ball entirely within its cell with generous transparent margin. Preserve exact registration and sizing of source sheet as closely as possible. Square spritesheet.
