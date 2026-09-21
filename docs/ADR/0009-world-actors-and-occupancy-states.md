# ADR-0009: actores de mundo y estados canónicos de occupancy

- Estado: aceptado
- Fecha: 2026-09-20

## Contexto

`w0_03_occupancy_workshop` debe mostrar una máquina abandonada que vuelve a ser útil, una operación actual que excluye el uso simultáneo y un título anterior que lleva el conflicto a disputa. Los placements de encounter existentes solo materializan participantes de conflicto y los estados técnicos `available/occupied` del prototipo no expresan por completo `ABANDONED` y `DISPUTED` de `GAMEPLAY_RULES.md` §12.3.

## Decisión

- `LevelSpec v0` admite la colección opcional `actors` para colocar actores de catálogo que no pertenecen a un encounter.
- Cada placement declara únicamente `id`, `archetype_id`, `x` e `y`; no contiene comportamiento arbitrario.
- `RuleStateObject` conserva los estados existentes y añade `abandoned` y `disputed` de forma compatible.
- Una máquina `abandoned` puede pasar a `occupied` mediante la misma interacción base.
- Una máquina `occupied` o `disputed` mantiene activa su consecuencia espacial, pero no permite que el jugador sustituya al operador mediante una interacción ordinaria.
- `disputed` describe una controversia y no concede elegibilidad ofensiva.

## Consecuencias

- Los LevelSpecs existentes continúan siendo válidos; `actors` y los nuevos valores son opcionales.
- El builder puede presentar NPC neutrales sin inventar encounters vacíos.
- El schema, validator, builder, checkpoint del objeto de regla y tests cubren la extensión.
- Un actor colocado sigue usando un `EnemyArchetype` registrado y `TargetValidity`; el placement no puede cambiar su legitimidad ofensiva.
