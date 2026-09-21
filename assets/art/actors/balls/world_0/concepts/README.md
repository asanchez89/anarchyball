# World 0 ball concept set

## AnComBall revision 2

`ancom_ball_concept_v2.png` was generated from the accepted AnComBall design as an eight-pose production sheet. Its ordered poses are idle, move, jump, fire, hurt, threaten, surrender, and neutralized. Surrender uses lowered tired eyes and a powered-down emitter; neutralized uses flat or closed eyes and an inactive emitter. Neither state uses smiles, bubbles, orbiting particles, or unexplained side objects.

Conceptos generados con la herramienta integrada de OpenAI el 2026-09-20. Usan como referencias el concepto aprobado de AnarchyBall y el preview curado de Twilight Forest.

No son spritesheets de producción: las poses no tienen celdas, offsets ni registro exactos. Deben reconstruirse sobre `assets/art/art_bible/ball_generation/ball_sheet_layout.svg`.

## Prompt set

Todos usan el prompt maestro documentado en `assets/art/art_bible/ball_generation/README.md`. Las variables finales están registradas en `world0_ball_roster.json` y se concretaron así:

- `merchant_ball`: crema/teal, nudo de intercambio original, pouch de ledger; neutral, alert y threatened.
- `robber_ball`: vino/charcoal, cadena rota, hood y tether de confiscación; threatening, attack, surrender y neutralized.
- `egoist_ball`: teal `#036A66`/negro `#141414`, gafas sin pupilas visibles; skeptical y contract refusal.
- `agorist_ball`: gris `#7F7F7F`/charcoal `#202020`, motivo triangular original y tag de mercado; offer y evade.
- `mutualist_ball`: naranja `#F7941E`/negro `#141414`, strokes de intercambio, goggles y tool key; inspect y operate.
- `left_libertarian_ball`: amarillo/dark violet, marcas de ruta originales y survey ribbon; claim y negotiate.
- `black_anarchy_ball`: bandas verde `#00853E`, rojo `#E31B22` y negro `#141414`, motivo comunitario original; influence y coordinate.
- `ancom_ball`: rojo `#DD0000`/negro `#141414`, red de ayuda original y support projector; guard, support, duel y alliance.
- `police_ball_leviathan`: negro `#141414` con triángulo invertido azul naval `#00187B`, gorra policial y blasón original de Leviatán coronado; alerta, patrulla, ataque, daño y derrota.

Invariantes aplicados a todos: pixel art pulido, volumen redondo, key light superior izquierda, rim light magenta moderado, ojos blancos sin pupilas/iris, transparencia real, ausencia de extremidades y símbolos políticos no listados.

Las identidades cromáticas investigadas se usan como referencia semiótica. Los motivos centrales y accesorios son diseños originales del proyecto, no copias de iconos comunitarios.

## Revisión de legibilidad V2

`agorist_ball_concept_v2.png`, `egoist_ball_concept_v2.png` y `mutualist_ball_concept_v2.png` reemplazan la cuarta pose lateral ambigua. La nueva pose representa giro durante desplazamiento mediante inclinación/squash del cuerpo, conservando ambos ojos blancos completos. El manifiesto de World 0 apunta exclusivamente a estas versiones.

`police_ball_leviathan_concept_v2.png` reemplaza visualmente al enforcer genérico. Conserva la geometría de Police Statism (campo negro, triángulo naval y gorra), pero usa un blasón original de serpiente marina coronada para aludir al Leviatán hobbesiano sin copiar una insignia estatal real. El generador mantiene el ID técnico `occupancy_enforcer_ball` para no romper contenido existente.

`mutualist_ball_concept_v3.png` reemplaza el trazo circular ambiguo de V2 por el símbolo inequívoco de mutualismo: dos flechas circulares contrapuestas, negra sobre naranja y naranja sobre negro. La forma, color y dirección se conservan en las ocho poses para que el emblema siga siendo legible a escala de juego.

`mutualist_ball_concept_v4.png` reduce y desplaza ese emblema al tercio inferior del cuerpo. Mantiene una zona de exclusión alrededor de los ojos en todas las poses para que las flechas nunca oculten ni se confundan con la expresión facial. Es la fuente activa del atlas runtime.
