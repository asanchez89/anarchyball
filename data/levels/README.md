# LevelSpec

Este directorio contiene el contrato persistente `LevelSpec v0` y los borradores de nivel validados:

- `level_spec_v0.schema.json`: forma y tipos del JSON;
- `phase3_content_preview.json`: borrador jugable de referencia.
- `mvp_vertical_slice.json`: composición jugable de Phase 4 con narrativa breve, gate y checkpoint.
- `mvp_hardening_variant.json`: variante compacta de regresión creada solo con datos; no es contenido shipping hasta superar playtest humano.
- `phase6_occupancy_preview.json`: preview jugable de P6.3 con dos máquinas stateful y ruta base siempre disponible; continúa siendo draft.
- `occupancy_workshop_draft.json`: nivel extendido de P6.5 con cinco secciones, maquinaria opcional, dos encounters, recursos y checkpoints; continúa siendo draft hasta playtest humano.
- `w0_01_first_aggression.json`: primera misión candidata de World 0.
- `w0_02_contract_bridge.json`: segunda misión candidata, con contrato y resolución no ofensiva.
- `w0_03_occupancy_workshop.json`: tercera misión candidata e independiente del fixture de Phase 6; introduce MutualistBall, estados abandonado/disputado y un title claim.

Las comprobaciones semánticas —IDs de catálogo, ownership, escenas, soporte de spawn/salida y alcanzabilidad con movimiento base— pertenecen a `LevelValidator`. Un archivo que no supere ambas capas no debe llegar a `LevelBuilder` ni considerarse nivel publicable.

LevelSpec v0 admite `rule_objects` y `actors` como colecciones opcionales cerradas. Cada rule object referencia un hook soportado, plataformas declaradas y un counterplay de la regla activa. El hook `occupancy_machine` activa sus plataformas mientras el objeto está `occupied` o `disputed`; una máquina `abandoned` puede ocuparse con la interacción base. `actors` coloca un arquetipo registrado sin asociarlo artificialmente a un encounter. El estado de los objetos de regla y de los observers forma parte del checkpoint. `tools/phase6/validate_content.cmd` valida en lote todos los LevelSpecs de este directorio.
