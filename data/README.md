# Datos de gameplay

Definiciones estables de clases, enemigos, encuentros, ideologías, diálogo y mundos. Usar IDs en `snake_case` y referencias validadas.

Godot `Resource` es la opción preferida para definiciones estables. JSON se reserva principalmente para especificaciones de nivel legibles y generables por herramientas.

`level_profiles/` contiene fichas editoriales asociadas por `level_id`. No son entrada de `LevelBuilder` ni amplían `LevelSpec v0`; describen clasificación, objetivos de playtest y la decisión de promoción o conservación como prototipo.
