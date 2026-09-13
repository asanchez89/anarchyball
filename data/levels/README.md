# LevelSpec

Este directorio contiene el contrato persistente `LevelSpec v0` y los borradores de nivel validados:

- `level_spec_v0.schema.json`: forma y tipos del JSON;
- `phase3_content_preview.json`: borrador jugable de referencia.
- `mvp_vertical_slice.json`: composición jugable de Phase 4 con narrativa breve, gate y checkpoint.
- `mvp_hardening_variant.json`: variante compacta de regresión creada solo con datos; no es contenido shipping hasta superar playtest humano.
- `phase6_occupancy_preview.json`: preview jugable de P6.3 con dos máquinas stateful y ruta base siempre disponible; continúa siendo draft.
- `occupancy_workshop_draft.json`: nivel extendido de P6.5 con cinco secciones, maquinaria opcional, dos encounters, recursos y checkpoints; continúa siendo draft hasta playtest humano.

Las comprobaciones semánticas —IDs de catálogo, ownership, escenas, soporte de spawn/salida y alcanzabilidad con movimiento base— pertenecen a `LevelValidator`. Un archivo que no supere ambas capas no debe llegar a `LevelBuilder` ni considerarse nivel publicable.

LevelSpec v0 admite `rule_objects` como colección opcional cerrada. Cada objeto referencia un hook soportado, plataformas declaradas y un counterplay de la regla activa. El hook `occupancy_machine` activa sus plataformas únicamente mientras el objeto está `occupied`; su estado y el de los observers de encounter forman parte del checkpoint. `tools/phase6/validate_content.cmd` valida en lote todos los LevelSpecs de este directorio.
