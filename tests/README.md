# Tests

Capas previstas:

- `unit`: estados, target validity, movimiento calculable y modificadores;
- `integration`: player, armas, encuentros, checkpoints y carga de niveles;
- `fixtures`: datos válidos e inválidos usados por validadores;
- smoke test: importación headless y arranque de la escena principal.

El framework seleccionado es GdUnit4 6.2.1; consultar `docs/ADR/0002-test-framework.md`.

Ejecutar toda la validación en Windows:

```powershell
$env:GODOT_BIN = "C:\ruta\a\godot_console.exe"
.\tools\phase0\verify_all.cmd
```

La suite headless no simula transporte de input físico. `test_foundation.gd` valida acciones y bindings; `src/input/input_diagnostics.tscn` permite comprobar hardware real.
