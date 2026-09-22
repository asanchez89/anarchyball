# AncomBall — diagonal roja/negra

Edición mediante la herramienta integrada ImageGen, 2026-09-22.
Referencia: `ancom_ball_animation_draft.png`. Resultado original conservado sin
reescalar ni modificar píxeles: `ancom_ball_animation_v2.png` (1254 × 1254, alfa).

## Prompt usado

Edit this game sprite atlas precisely. Preserve exactly its 8 columns by 8 rows,
64 complete characters, equally spaced square cells and transparent background.
Correct EVERY sphere's flag: clearly diagonal bicolor with RED covering the entire
upper-left HALF of the spherical body and near BLACK the lower-right HALF.
Boundary runs lower-left to upper-right across the sphere center. Red must extend
down the LEFT cheek to the lower-left edge, NOT a narrow red forehead stripe or
bandana. Especially fix rows 6,7,8 where red shrinks to a band. Preserve polished
shaded volume, white eyes WITHOUT pupils, dark outline, consistent body diameter
and foot alignment, side ear device, tiny top antenna, left-facing three-quarter
direction. All 64 frames have same sphere size and the SAME broad half-red
half-black diagonal flag regardless expression. Preserve row states: idle,
movement, jump, shooting recoil, hurt, threat, surrender, neutralized. Last two
rows subdued serious tired eyes, never happy. Remove external red smear/jet/flame
effects from movement/action/hurt: only body animation, no floating strange
objects; cannon is rendered separately by game. Keep each character fully inside
its own cell with generous transparent padding, no clipping, no labels, no grid,
no background. Output square transparent PNG with exact regular 8x8 layout.

## Integración y validación

`ancom_ball_visual.tres` usa AtlasTexture con margen transparente lógico de 2 px
para una cuadrícula de 1256 × 1256, celdas de 157 px. No altera el PNG.
Rectángulos de cuerpo calibrados excluyen antena, accesorio lateral y efecto de
salto para mantener el tamaño nominal de 76 × 76 y apoyo local y=18.
El cañón continúa como sprite independiente.

Reglas GR: ninguna modificada; cambio exclusivamente de presentación.
Importación headless y suite completa: 180 pruebas, 0 errores y 0 fallos.
Se comprueba rojo en la mitad inferior izquierda de todos los frames, ocho
frames distintos por estado, márgenes laterales y anclaje. La prueba cromática
detecta la regresión a una franja, no certifica una proporción exacta 50/50.
Vista reproducible: `tools/art/capture_ancom_review.gd`.
Pendiente aprobación visual humana de la animación en movimiento dentro del nivel.
