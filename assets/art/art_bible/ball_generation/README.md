# Plantilla reutilizable de Ball

Esta carpeta define el contrato visual común para generar y reconstruir todas las balls. Las imágenes generadas son **anclajes conceptuales**: ningún resultado generativo entra al runtime hasta reconstruirse sobre este grid y superar revisión humana.

## 1. Atlas maestro

- Celda fuente: `96x96 px`.
- Atlas: `768x768 px`, ocho columnas por ocho filas.
- Escala de juego inicial: `1x`; no ampliar un sprite de baja resolución para simular detalle.
- Origen del actor: centro inferior de la celda, `(48, 90)`.
- Línea de suelo: `y = 90`; los seis píxeles restantes permiten sombra o deformación de aterrizaje.
- Cuerpo base recomendado: ancho `54-66 px`, alto `54-66 px`.
- Ojos: blancos, con contorno oscuro y **sin pupilas ni iris**.
- El cuerpo, ojos, superficie ideológica, accesorio y arma deben poder separarse en capas de trabajo aunque el export final se hornee.

`ball_sheet_layout.svg` conserva la antigua guía de baja resolución y queda deprecada; debe regenerarse al contrato `96x96` antes de usarse como guía de producción.

| Fila | Animación | Frames usados | Celdas reservadas |
|---:|---|---:|---:|
| 0 | `idle` | 6 | 8 |
| 1 | `move` | 8 | 8 |
| 2 | `jump` | 8 | 8 |
| 3 | `fire` | 4 | 8 |
| 4 | `hurt` | 4 | 8 |
| 5 | `threatening` | 4 | 8 |
| 6 | `surrendering` | 6 | 8 |
| 7 | `neutralized` | 4 | 8 |

Las celdas sobrantes permanecen transparentes. Reservarlas evita que cada ball cambie el orden del atlas y permite ampliar ciclos sin romper consumidores.

## 2. Invariantes y variables

### Invariantes del elenco

- acabado pixel art pulido y volumen compatible con los entornos Warped;
- luz principal superior izquierda y rim light frío/magenta moderado;
- silueta esférica reconocible, sin anatomía humanoide;
- ojos blancos sin pupilas;
- tamaño, pivote, línea de suelo, facing y orden de animaciones idénticos;
- el arma defensiva usa socket separado y no altera la identidad del cuerpo;
- lectura de `threatening`, `surrendering` y `neutralized` mediante pose y ojos, no solo color.

### Variables por ball

- `ball_id` estable en `snake_case`;
- colores y partición de la superficie ideológica;
- símbolo interior opcional;
- accesorio de silueta opcional;
- geometría de ojos por personalidad, siempre sin pupilas;
- emisor/arma solo si el rol de gameplay lo exige;
- pequeños cambios de proporción dentro del bounding box aprobado.

## 3. Perfil de generación

Duplicar `ball_profile.template.json`, renombrarlo `<ball_id>.json` y completar únicamente los campos variables. `anarchy_ball.example.json` muestra el concepto aprobado.

Los campos `surface` describen identidad visual, no lógica ideológica ni gameplay. Los nombres de facción o mundo nunca deben condicionar código base.

## 4. Prompt maestro

Sustituir los valores entre llaves con el perfil de la ball. Generar primero una hoja conceptual; después reconstruir manualmente el atlas exacto.

```text
Use case: stylized-concept
Asset type: reusable pixel-art character animation reference for a 2D side-scrolling game
Input images: Image 1 is the approved AnarchyBall finish, volume, lighting and pixel-density reference; additional images define only the new ball's internal colors, partitions or symbol.
Primary request: Create an original {display_name} ball character using the same production-quality visual language, proportions and animation grammar as the approved AnarchyBall.
Identity surface: {surface_description}.
Eyes: solid white expressive shapes with dark outlines; absolutely no pupils or irises; {eye_personality}.
Accessory: {accessory_description}.
Equipment: {equipment_description}; render it as a separable side attachment and do not bake it into the ideological surface.
Style/medium: polished high-detail retro pixel art, rounded dimensional volume, crisp hard pixel clusters, controlled upper-left key light and restrained cool/magenta rim light; compatible with the Warped environments. Do not imitate a crude or flat meme drawing finish.
Composition/framing: exactly eight isolated animation key poses in one horizontal row—idle, alert, movement turn, movement squash, jump rise, jump apex, role action, hurt—with consistent body identity and generous transparent gutters.
Constraints: genuinely transparent background; same approximate body scale and baseline in every pose; no pupils, irises, limbs, hands, feet, text, labels, grid, scenery, floor or watermark; do not introduce political symbols not listed in the profile. Concept reference only, not a production-ready spritesheet.
```

## 5. Flujo de producción

1. Aprobar el perfil JSON y las referencias permitidas.
2. Generar una hoja conceptual con el prompt maestro.
3. Revisar identidad, ojos, acabado y coherencia con el escenario.
4. Reconstruir sobre `ball_sheet_layout.svg` en una herramienta de pixel art.
5. Comprobar pivote, baseline, facing, socket, escala corporal compartida entre poses y ausencia de pulsación de tamaño no intencional.
6. Exportar `<ball_id>_sheet.png` y crear la definición visual correspondiente.
7. Validar todas las animaciones en `art_lab` antes de integrarlas a una misión.

La generación de nuevas balls debe variar únicamente el perfil y las referencias de identidad. Si una ball exige cambiar el grid o el contrato de animaciones, el cambio se discute como revisión de esta plantilla, no como excepción silenciosa.
