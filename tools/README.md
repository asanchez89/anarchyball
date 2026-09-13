# Herramientas

Lugar para `LevelBuilder`, `LevelValidator`, playtesting automatizado y utilidades de telemetría local.

Las herramientas deben producir resultados reproducibles y mensajes de error accionables. La telemetría del MVP es local y no requiere backend.

`phase0/` contiene los entry points canónicos de importación, smoke y tests. En Windows usar `phase0/verify_all.cmd`; CI llama la misma lógica a través de `phase0/verify_all.ps1`.

`phase6/validate_content.cmd` registra y valida todo el catálogo y cada LevelSpec JSON de `data/levels/` en un solo proceso headless. El schema JSON se excluye del lote. Esta auditoría forma parte de `phase0/verify_all` y por tanto también de CI.
