# Plantillas de Content Factory v1

Estas plantillas son puntos de partida copiables, no contenido registrado ni shipping.

1. Copia el archivo al directorio correspondiente bajo `data/content/` o `data/levels/`.
2. Sustituye todos los IDs `*_template` por IDs estables en `snake_case`.
3. Registra Resources nuevos en `data/content/default_catalog.tres`.
4. Conserva LevelSpec v0 y usa solamente hooks declarados por `IdeologyRuleDefinition`.
5. Ejecuta `tools/phase6/validate_content.cmd` y la suite completa.
6. Mantén el nivel como draft hasta aprobar playtest humano.

La ficha `level_playtest_profile_template.json` es editorial y permanece fuera de `LevelSpec v0`. Copiarla a `data/level_profiles/<level_id>.json` permite declarar clasificación, rangos, beats y evidencia humana sin cambiar el schema del nivel. Un `technical_prototype` declara en cambio `retain_as_prototype` y un ID diferente para su sucesor de campaña.

`rule_objects` es opcional y el hook runtime `occupancy_machine` construye su estado visible y persistente. Un placement de encounter puede declarar `rule_object_ids` para que su observador local produzca una resolución configurada por interacción. El JSON nunca puede contener scripts, métodos o expresiones ejecutables.
