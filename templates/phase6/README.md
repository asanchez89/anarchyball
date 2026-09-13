# Plantillas de Content Factory v1

Estas plantillas son puntos de partida copiables, no contenido registrado ni shipping.

1. Copia el archivo al directorio correspondiente bajo `data/content/` o `data/levels/`.
2. Sustituye todos los IDs `*_template` por IDs estables en `snake_case`.
3. Registra Resources nuevos en `data/content/default_catalog.tres`.
4. Conserva LevelSpec v0 y usa solamente hooks declarados por `IdeologyRuleDefinition`.
5. Ejecuta `tools/phase6/validate_content.cmd` y la suite completa.
6. Mantén el nivel como draft hasta aprobar playtest humano.

`rule_objects` es opcional y el hook runtime `occupancy_machine` construye su estado visible y persistente. Un placement de encounter puede declarar `rule_object_ids` para que su observador local produzca una resolución configurada por interacción. El JSON nunca puede contener scripts, métodos o expresiones ejecutables.
