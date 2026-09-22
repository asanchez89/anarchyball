# ADR-0011: posiciones explícitas por integrante de encuentro

Estado: aceptado para el rediseño espacial solicitado del colectivo.

LevelSpec v0 admite `encounters[].enemy_positions`, array opcional de puntos
absolutos `{x, y}`. Su longitud coincide con enemy_count o el roster por defecto.
Sin el campo se conserva la separación horizontal histórica de 130 px.
El builder aplica el mismo apoyo de suelo que a cualquier actor; no altera IDs,
permisos o membresía del encuentro. Schema y validator rechazan puntos inválidos,
fuera del nivel y longitudes inconsistentes. Los guardados de geometría anterior
no se reubican implícitamente: probar el rediseño desde NUEVO TALLER.
