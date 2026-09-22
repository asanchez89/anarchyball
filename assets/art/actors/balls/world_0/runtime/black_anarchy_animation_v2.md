# BlackAnarchy — corrección de bandera v2

Generada mediante imagegen integrado a partir de `black_anarchy_animation_v1.png`.
Bandera confirmada por el usuario: cuerpo negro liso y A blanca encerrada en un
círculo, separada de los ojos blancos sin pupilas. Conserva sombreado, volumen,
orientación izquierda y la distribución de cuatro columnas por cuatro filas.
No se enviaron assets comprados. La versión v1 queda como histórico descartado.
No cambia reglas GR ni comportamiento: modificación exclusivamente visual.
Varios estados siguen compartiendo fila como en v1; no amplía el repertorio.

PNG original RGBA de 1254×1254, celdas de 313×313 como v1. El encuadre del
renderer ignora alpha <= 0.01 para no contar ruido de exportación de 1/255;
no se reescribe la imagen. Importación, validación y 165 tests aprobados.
Captura del taller revisada para comprobar escala y apoyo.

## Corrección de tamaño entre frames

La silueta completa incluía el adorno superior: normalizar su altura hacía variar
la esfera. `black_anarchy_ball_visual.tres` ahora declara 16 rectángulos de cuerpo
en coordenadas de celda, excluyendo ese adorno. El renderer calibra la esfera a
76×76 y alinea su centro horizontal y apoyo a y=18; conserva la celda completa
para no recortar accesorios. La compensación también corrige el achatamiento de
los frames de movimiento de la hoja. No se modifica el PNG ni la colisión.
Las pruebas verifican ambos ejes del cuerpo y el punto de apoyo por frame.

## Prompt exacto

Use case: precise-object-edit. Input image is the edit target: a 4x4 game animation spritesheet. Correct the character identity in ALL SIXTEEN frames: body painted uniformly black/charcoal, with ONE clearly legible WHITE anarchist circled capital A (Ⓐ) on the right side cheek, separated from and never covering either eye. Remove ALL green and red flag bands and remove the three linked colored rings, replacing them with that white circled A. Small top braided knot becomes black too. Preserve polished shaded spherical volume, charcoal highlights, subtle purple rim, identical circular body size, left-facing three-quarter orientation, white eyes without pupils, same poses/expression sequence and exact evenly spaced 4 columns x 4 rows layout. Row1 idle attentive, row2 moving lean, row3 working/intent, row4 tired/relenting not smiling. Do not add mouth, limbs, weapons, extra symbols, text or new accessories. Keep every complete ball inside its cell with generous transparent gutters on ALL sides and a stable foot baseline across each row. Actual transparent RGBA background; no checkerboard or opaque backdrop. Square output, preserve original layout. Black surface must remain shaded and dimensional, not flat. The circled A must be a recognizable A with two legs and crossbar within a closed circle in every frame, never abstract loops.
