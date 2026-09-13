# Guía de extensión de contenido del MVP

Esta guía describe el camino mínimo para añadir contenido sin modificar el núcleo ni `PlayerController`.

## Antes de editar

1. Define la experiencia y su criterio de aceptación.
2. Identifica las reglas `GR-*` afectadas.
3. Reutiliza componentes y contratos existentes.
4. Usa IDs `snake_case` estables; el nombre visible puede cambiar.

Puedes comenzar desde `templates/phase6/`. Las plantillas no están registradas ni se incluyen en el build; deben copiarse, renombrarse y registrarse explícitamente.

## Añadir un enemigo

1. Crea un `EnemyArchetype` `.tres` en `data/content/enemies/`.
2. Selecciona una escena compuesta existente y configura Resolve, comportamiento, estado inicial, permisos y tags. Todo comportamiento distinto de `static` debe declarar `aggressor_reason`; usa `threat_text` y `telegraph_delay` para que el acto sea observable antes del ataque.
3. Regístralo en `data/content/default_catalog.tres`.
4. Añade una prueba de registro y estructura. No añadas una rama por enemigo al jugador, arma o target validity.

## Añadir un encounter

1. Crea un `EncounterDefinition` en `data/content/encounters/`.
2. Declara objetivo, criterio de éxito, triggers de agresión, actores y resoluciones. Las resoluciones runtime deben mapearse con `neutralization_resolution` o `rule_interaction_resolution`, y pertenecer a `allowed_resolutions`.
3. Regístralo en el catálogo y referencia sus enemigos por ID. Un placement puede asociar `rule_object_ids` locales para que su observador cierre la resolución de interacción.
4. Prueba referencias, legitimidad y al menos dos resoluciones cuando sea práctico.

## Añadir una regla ideológica

1. Crea un `IdeologyRuleDefinition` en `data/content/ideology/`.
2. Declara beneficio/coste cuando corresponda, hooks limitados y `counterplay_tags`.
3. El obstáculo debe comunicar su regla antes de exigir lore.
4. Registra la definición y cubre su estructura. Nunca condicionales por nombre de mundo dentro del player.

Los hooks runtime disponibles son `access_gate` y `occupancy_machine`. Para el segundo, declara `rule_objects` en LevelSpec con plataformas objetivo e `interaction_tag`: el builder crea un `RuleStateObject`, mantiene la ruta base intacta y guarda su estado en checkpoint. Un hook nuevo exige primero un consumidor tipado, validación y pruebas; el JSON nunca ejecuta código.

## Añadir un nivel o variante

1. Copia la forma de `data/levels/mvp_hardening_variant.json`.
2. Cambia `level_id`, composición, placements y referencias; conserva `schema_version` compatible.
3. Toda ruta requerida debe ser superable con movimiento base. Marca rutas opcionales con `required: false` y `route_tags`.
4. Carga el archivo mediante `LevelSpecLoader` y ejecútalo contra `LevelValidator` en una prueba.
5. Construye la escena con `LevelBuilder`, realiza playtest humano y conserva el LevelSpec junto a la escena promovida.

## Verificación

```powershell
$env:GODOT_BIN = "C:\ruta\a\godot_console.exe"
.\tools\phase6\validate_content.cmd
.\tools\phase0\verify_all.cmd
.\tools\phase5\build_windows.cmd
```

La validación por lote carga todo el catálogo y cada JSON de `data/levels/`, excluyendo el schema. Comprueba también definiciones no referenciadas, hooks soportados, campos cerrados, IDs locales, bounds y referencias de `rule_objects` y `encounters[].rule_object_ids`. Un dato inválido debe fallar indicando archivo y campo. Un nivel válido sigue siendo un borrador hasta superar playtest humano.
