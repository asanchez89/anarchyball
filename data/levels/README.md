# LevelSpec

Este directorio contiene el contrato persistente `LevelSpec v0` y los borradores de nivel validados:

- `level_spec_v0.schema.json`: forma y tipos del JSON;
- `phase3_content_preview.json`: borrador jugable de referencia.
- `mvp_vertical_slice.json`: composición jugable de Phase 4 con narrativa breve, gate y checkpoint.
- `mvp_hardening_variant.json`: variante compacta de regresión creada solo con datos; no es contenido shipping hasta superar playtest humano.

Las comprobaciones semánticas —IDs de catálogo, ownership, escenas, soporte de spawn/salida y alcanzabilidad con movimiento base— pertenecen a `LevelValidator`. Un archivo que no supere ambas capas no debe llegar a `LevelBuilder` ni considerarse nivel publicable.
