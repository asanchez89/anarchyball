# ADR-0002: Framework de tests

- **Estado:** Aceptado
- **Fecha:** 2026-08-21

## Contexto

Phase 0 exige tests GDScript ejecutables por CLI, exit codes fiables, reportes legibles y compatibilidad explícita con Godot 4.6.3. El framework debe servir después para lógica determinista y escenas de integración sin introducir C#.

## Candidatos

### GdUnit4 6.2.1

- declara compatibilidad específica con Godot 4.6.3;
- runner CLI con exit codes, fail-fast y reportes HTML/JUnit;
- typed GDScript, fixtures, mocks y soporte de escenas;
- release 6.2.1 incluye una corrección del cierre del runner de CI.

Fuente: [release oficial de GdUnit4 6.2.1](https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.2.1).

### GUT 9.6.1

- soporta Godot 4.6.x;
- CLI y export de JUnit;
- proyecto maduro y API sencilla.

Fuente: [release oficial de GUT 9.6.1](https://github.com/bitwes/Gut/releases/tag/v9.6.1).

### Harness propio

- control total y dependencia mínima;
- coste injustificado de mantener discovery, assertions, reportes, lifecycle y CI.

## Decisión

Usar **GdUnit4 6.2.1**, fijado y vendorizado en `addons/gdUnit4/` con su licencia MIT. El runner canónico es:

```text
res://addons/gdUnit4/bin/GdUnitCmdTool.gd
```

Los tests del proyecto viven fuera del addon, bajo `tests/`. Los reportes se generan en `reports/` y no se versionan.

## Evidencia del spike

- Godot ejecutado: `4.6.3.stable.mono.official.7d41c59c4`.
- Suite positiva de Foundation: exit code `0`.
- Probe deliberadamente fallido: exit code `100`.
- Reportes HTML y JUnit generados correctamente.
- Importación del addon sin errores de script.

GdUnit4 avisa que los `InputEvent` de UI no se transportan en modo headless. Phase 0 prueba la configuración del InputMap de forma determinista y ofrece un harness visual para hardware real. Futuras pruebas que dependan de transporte real de input usarán una escena de integración no-headless o una capa de input inyectable.

## Consecuencias

- CI usa `--ignoreHeadlessMode` solo para tests compatibles con headless.
- No se aceptan tests de interacción que aparenten validar input físico en headless.
- Actualizar GdUnit4 requiere revisar compatibilidad, licencia, import, suite positiva y failure probe.
- No se incorpora un segundo framework de tests sin un ADR que justifique la coexistencia o migración.
