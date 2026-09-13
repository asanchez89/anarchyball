# Herramientas

Lugar para `LevelBuilder`, `LevelValidator`, playtesting automatizado y utilidades de telemetría local.

Las herramientas deben producir resultados reproducibles y mensajes de error accionables. La telemetría del MVP es local y no requiere backend.

`phase0/` contiene los entry points canónicos de importación, smoke y tests. En Windows usar `phase0/verify_all.cmd`; CI llama la misma lógica a través de `phase0/verify_all.ps1`.

`phase6/validate_content.cmd` registra y valida todo el catálogo y cada LevelSpec JSON de `data/levels/` en un solo proceso headless. El schema JSON se excluye del lote. Esta auditoría forma parte de `phase0/verify_all` y por tanto también de CI.

`phase6/report_playtests.cmd` agrega las corridas archivadas en `user://telemetry/runs`, las compara con la ficha de `data/level_profiles/` y escribe un reporte local ignorado por Git bajo `telemetry/`. El juego permite seleccionar el perfil antes de comenzar y conserva cada recorrido completo además de `latest_run.json`.
