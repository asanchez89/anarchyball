# ADR-0006: Perfiles editoriales y evidencia local de playtest

- **Estado:** Aceptado
- **Fecha:** 2026-09-13

## Contexto

La producción de niveles necesita comparar intención y resultados humanos sin convertir tiempos, clasificación o muestras observadas en geometría ejecutable. `LevelSpec v0` es un contrato cerrado y la telemetría inicial solo conservaba la última corrida, por lo que no podía demostrar el gate de primeras vueltas y repeticiones limpias.

## Decisión

- Las fichas editoriales viven en `data/level_profiles/<level_id>.json` y no son entrada de `LevelBuilder`.
- Un perfil declara lifecycle, clasificación, cinco beats, objetivos de evidencia y, para candidatos de campaña, rangos de duración, ruta efectiva y checkpoints.
- Un `technical_prototype` no puede promoverse a shipping; declara explícitamente `retain_as_prototype` y un `campaign_successor_id` diferente.
- La telemetría local v1 añade `run_id`, perfil de prueba, tiempo con control, distancia recorrida, pantallas efectivas y backtracking.
- Cada recorrido completado conserva `latest_run.json` y una copia inmutable por corrida bajo `user://telemetry/runs`.
- El reporte de playtest agrega corridas por `level_id`, calcula tiempos por sección y checkpoint y conserva el gate humano como decisión externa.

## Consecuencias

- `LevelSpec v0` y ADR-0004 permanecen sin cambios.
- Los perfiles y reportes pueden evolucionar sin introducir lógica editorial en runtime de gameplay.
- La distancia recorrida es una señal observada, no una prueba automática de calidad o diversión.
- `occupancy_workshop_draft` permanece como fixture jugable; `w0_03_occupancy_workshop` será otro LevelSpec con presupuesto de campaña propio.
