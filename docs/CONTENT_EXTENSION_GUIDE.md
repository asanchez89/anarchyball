# Guía de extensión de contenido del MVP

Esta guía describe el camino mínimo para añadir contenido sin modificar el núcleo ni `PlayerController`.

## Antes de editar

1. Define la experiencia y su criterio de aceptación.
2. Identifica las reglas `GR-*` afectadas.
3. Reutiliza componentes y contratos existentes.
4. Usa IDs `snake_case` estables; el nombre visible puede cambiar.

## Añadir un enemigo

1. Crea un `EnemyArchetype` `.tres` en `data/content/enemies/`.
2. Selecciona una escena compuesta existente y configura Resolve, comportamiento, estado inicial, permisos y tags.
3. Regístralo en `data/content/default_catalog.tres`.
4. Añade una prueba de registro y estructura. No añadas una rama por enemigo al jugador, arma o target validity.

## Añadir un encounter

1. Crea un `EncounterDefinition` en `data/content/encounters/`.
2. Declara objetivo, criterio de éxito, triggers de agresión, actores y resoluciones.
3. Regístralo en el catálogo y referencia sus enemigos por ID.
4. Prueba referencias, legitimidad y al menos dos resoluciones cuando sea práctico.

## Añadir una regla ideológica

1. Crea un `IdeologyRuleDefinition` en `data/content/ideology/`.
2. Declara beneficio/coste cuando corresponda, hooks limitados y `counterplay_tags`.
3. El obstáculo debe comunicar su regla antes de exigir lore.
4. Registra la definición y cubre su estructura. Nunca condicionales por nombre de mundo dentro del player.

## Añadir un nivel o variante

1. Copia la forma de `data/levels/mvp_hardening_variant.json`.
2. Cambia `level_id`, composición, placements y referencias; conserva `schema_version` compatible.
3. Toda ruta requerida debe ser superable con movimiento base. Marca rutas opcionales con `required: false` y `route_tags`.
4. Carga el archivo mediante `LevelSpecLoader` y ejecútalo contra `LevelValidator` en una prueba.
5. Construye la escena con `LevelBuilder`, realiza playtest humano y conserva el LevelSpec junto a la escena promovida.

## Verificación

```powershell
$env:GODOT_BIN = "C:\ruta\a\godot_console.exe"
.\tools\phase0\verify_all.cmd
.\tools\phase5\build_windows.cmd
```

Un dato inválido debe fallar indicando archivo y campo. Un nivel válido sigue siendo un borrador hasta superar playtest humano.
