# Phase 0 - Plan operativo de Foundation

- **Estado:** DONE
- **Fecha de inicio:** 2026-08-21
- **Commit base:** `cc87b4a`
- **Responsable del gate:** revisión humana del proyecto ejecutable

## 1. Resultado esperado

Phase 0 termina con un repositorio Godot reproducible, probado por línea de comandos y listo para comenzar el sandbox de movimiento de Phase 1. No entrega todavía un player controller ni gameplay de combate.

La fase debe responder con evidencia estas preguntas:

1. ¿Qué versión exacta de Godot usa el proyecto?
2. ¿El proyecto importa y arranca sin errores en local y headless?
3. ¿Qué framework ejecutará tests deterministas y cómo comunica un fallo a CI?
4. ¿Teclado y gamepad producen las mismas acciones abstractas?
5. ¿Un entorno limpio puede repetir las validaciones con un único entry point documentado?

## 2. Estado de partida

| Capacidad | Estado | Evidencia |
|---|---|---|
| Repositorio Git en `main` | Hecho | commit `cc87b4a` |
| Ignores, atributos y convenciones | Hecho | `.gitignore`, `.gitattributes`, `.editorconfig` |
| Documentos de autoridad | Hecho | `AGENTS.md` y `docs/` |
| Proyecto Godot mínimo | Hecho | import headless exit `0` |
| Escena bootstrap | Hecho | smoke exit `0` |
| Versión exacta del motor | Hecho | Godot `4.6.3-stable` |
| Input abstracto | Hecho | 15 acciones y harness visual |
| Framework de tests | Hecho | GdUnit4 `6.2.1`, ADR-0002 |
| Smoke tests locales | Hecho | `tools/phase0/verify_all.cmd` |
| CI | Hecho | `.github/workflows/ci.yml` |

La instalación local no está en `PATH`; los entry points aceptan `-GodotBinary` o `GODOT_BIN` y nunca guardan la ruta personal.

## 3. Alcance

### Incluido

- versión exacta y reproducible de Godot 4.x estable;
- renderer Compatibility validado como baseline;
- proyecto importable y escena bootstrap ejecutable;
- acciones de input del vertical slice con teclado y gamepad;
- arquitectura preparada para touch sin implementar UI táctil;
- framework de tests elegido mediante spike;
- un test trivial positivo y otro intencionalmente fallido durante el spike;
- comandos locales únicos para import, smoke y tests;
- CI mínima que replique esos comandos;
- ADR y guía de contribución actualizados.

### Excluido

- `PlayerController`, física, cámara o debug room jugable;
- armas, enemigos, Resolve o estados de conflicto;
- LevelSpec, builder, validator y telemetría;
- export Windows de producción;
- controles táctiles visibles;
- plugins de gameplay o servicios externos.

## 4. Backlog ejecutable

Los estados válidos son `DONE`, `READY`, `BLOCKED` y `PENDING`.

| ID | Tarea | Entregable verificable | Dependencia | Estado |
|---|---|---|---|---|
| P0-01 | Cerrar foundation documental | base versionada y árbol limpio | ninguna | DONE |
| P0-02 | Spike de versión de Godot | versión exacta seleccionada, comando disponible y ADR actualizado | instalar/localizar Godot | DONE |
| P0-03 | Normalizar proyecto con el editor elegido | `project.godot` importado y resguardado por la versión seleccionada | P0-02 | DONE |
| P0-04 | Validar renderer Compatibility | bootstrap abre sin errores gráficos y decisión registrada | P0-03 | DONE |
| P0-05 | Definir acciones de input | InputMap completo con bindings keyboard/gamepad | P0-03 | DONE |
| P0-06 | Crear diagnóstico de input | escena/harness muestra acciones y vectores sin consultar dispositivo | P0-05 | DONE |
| P0-07 | Spike de framework de tests | matriz, prueba pass/fail headless y ADR-0002 | P0-02 | DONE |
| P0-08 | Crear entry points locales | comandos/scripts para import, smoke y tests | P0-03, P0-07 | DONE |
| P0-09 | Añadir smoke tests | bootstrap carga y sale con código correcto | P0-08 | DONE |
| P0-10 | Configurar CI mínima | workflow replica import, smoke y tests | P0-08, P0-09 | DONE |
| P0-11 | Documentar toolchain | README contiene instalación, versión y comandos exactos | P0-02, P0-08 | DONE |
| P0-12 | Auditar gate de Phase 0 | checklist con evidencia y árbol limpio | P0-04, P0-06, P0-07, P0-10, P0-11 | DONE |

## 5. Orden de ejecución

### Bloque A - Toolchain

1. Instalar o localizar la versión estable candidata de Godot estándar, no .NET.
2. Ejecutar el bootstrap desde editor y headless.
3. Confirmar renderer Compatibility y ausencia de errores de importación.
4. Registrar versión exacta y método de obtención en ADR-0001 o un ADR sucesor.

Resultado: P0-02, P0-03 y P0-04 cerrados.

### Bloque B - Input contract

1. Registrar todas las acciones requeridas por `GAMEPLAY_RULES.md` §3.1.
2. Crear bindings iniciales para teclado/mouse y gamepad.
3. Exponer `aim_vector` como concepto, sin congelar todavía free aim, ocho direcciones o aim assist.
4. Añadir un harness visual/debug que muestre intensidad, pressed/released y vector.
5. Verificar manualmente que el código consumidor solo menciona acciones.

Resultado: P0-05 y P0-06 cerrados.

### Bloque C - Test runner

1. Probar los candidatos compatibles con la versión exacta de Godot.
2. Ejecutar por CLI un test que pasa.
3. Ejecutar temporalmente un test que falla y comprobar exit code no-cero y salida legible.
4. Evaluar mantenimiento, velocidad, typed GDScript, fixtures y uso en CI.
5. Elegir uno y registrar ADR-0002; eliminar del árbol cualquier candidato descartado.

Resultado: P0-07 cerrado sin arrastrar dos frameworks.

### Bloque D - Reproducibilidad

1. Crear entry points locales pequeños para import, smoke y tests.
2. Garantizar que no dependan de una ruta personal absoluta.
3. Ejecutarlos dos veces desde un checkout limpio de artefactos generados.
4. Configurar CI usando los mismos entry points.
5. Documentar prerrequisitos, comandos y resolución de errores frecuentes.

Resultado: P0-08 a P0-11 cerrados.

### Bloque E - Gate

Revisar evidencia, deuda, estado de Git y checklist. Phase 1 no comienza con tareas parcialmente verificadas de input o testing.

## 6. Spike de Godot

### Criterios de selección

La versión elegida debe:

- ser una release estable oficial de Godot 4.x, no beta ni RC;
- usar el build estándar sin C#;
- abrir e importar el proyecto sin conversión destructiva inesperada;
- ejecutar Compatibility en el hardware Windows de desarrollo;
- permitir ejecución headless estable;
- ser compatible con el framework de tests elegido;
- contar con export templates accesibles para el futuro build Windows.

### Evidencia a guardar

- salida de `--version`;
- comando exacto o mecanismo para localizar el ejecutable;
- resultado de importación headless;
- resultado de arranque headless del bootstrap;
- renderer efectivo;
- cualquier warning aceptado con justificación.

### Decisión resultante

Actualizar el ADR con:

- versión exacta;
- variante del binario;
- renderer baseline;
- política de actualización: no subir minor/patch sin ejecutar smoke, tests y una revisión breve de compatibilidad.

## 7. Spike de framework de tests

### Candidatos

- GdUnit4;
- GUT;
- harness GDScript mínimo propio solo como control comparativo, no como preferencia inicial.

### Matriz de evaluación

| Criterio | Peso |
|---|---:|
| Compatibilidad con la versión exacta de Godot | Obligatorio |
| Exit code fiable en headless | Obligatorio |
| Instalación reproducible y versionable | Obligatorio |
| Salida de fallos legible en CI | Alto |
| Soporte de typed GDScript y dobles/fixtures | Alto |
| Velocidad para unit tests | Medio |
| Escenas de integración | Medio |
| Mantenimiento y documentación | Medio |
| Coste de actualización | Medio |

No se selecciona un framework solo porque abra dentro del editor. Debe demostrar pass/fail por CLI.

### Resultado esperado

`docs/ADR/0002-test-framework.md` debe registrar candidatos, prueba ejecutada, decisión, versión fijada, comando oficial y consecuencias.

## 8. Contrato de input de Phase 0

Acciones obligatorias:

```text
move_left
move_right
jump
crouch_or_drop
attack_primary
attack_secondary
aim_left
aim_right
aim_up
aim_down
ability_1
ability_2
interact
dodge_or_dash
pause
```

`aim_vector` se deriva de las cuatro acciones de aim o de una abstracción equivalente. El gameplay futuro no consulta nombres de teclas, botones, modelo de gamepad ni plataforma.

Bindings iniciales propuestos:

| Acción | Teclado/mouse | Gamepad |
|---|---|---|
| Movimiento | A/D y flechas | stick izquierdo / D-pad |
| Salto | Space | botón inferior |
| Crouch/drop | S / flecha abajo | D-pad abajo o stick |
| Ataque primario | mouse izquierdo | trigger derecho |
| Ataque secundario | mouse derecho | trigger izquierdo |
| Aim | mouse convertido a vector | stick derecho |
| Ability 1/2 | Q/E | shoulders |
| Interact | F | botón izquierdo |
| Dodge/dash | Shift | botón derecho |
| Pause | Escape | Start/Menu |

Los nombres concretos de botones se mostrarán mediante el sistema de prompts, no se codificarán en gameplay. El spike puede ajustar bindings por ergonomía sin cambiar los nombres de acción.

## 9. Comandos objetivo

Los entry points finales pueden ser scripts PowerShell o comandos documentados, pero deben cubrir estas operaciones conceptuales:

```text
verify_import
run_smoke
run_tests
verify_all
```

`verify_all` debe fallar al primer error y devolver exit code no-cero. CI debe llamar estos mismos entry points en lugar de duplicar lógica extensa dentro del workflow.

## 10. Gate de salida

Phase 0 solo cambia a `DONE` cuando:

- [x] versión exacta de Godot fijada y documentada;
- [x] renderer Compatibility validado;
- [x] importación headless sin errores;
- [x] bootstrap arranca y termina correctamente en headless;
- [x] test positivo pasa por CLI;
- [x] fallo intencional del spike produjo exit code `100`;
- [x] teclado y gamepad mapean las mismas acciones abstractas;
- [x] harness no contiene ramas por dispositivo en lógica de gameplay;
- [x] CI replica import, smoke y tests locales;
- [x] README documenta preparación y ejecución;
- [x] ADR-0001 refleja la versión exacta;
- [x] ADR-0002 registra el framework de tests;
- [x] no quedan errores no explicados; el warning headless de GdUnit4 está documentado en ADR-0002;
- [x] cambios de la fase listos para commit de cierre.

## 11. Riesgos de la fase

| Riesgo | Mitigación |
|---|---|
| Elegir una versión por novedad | exigir release estable, test runner compatible y smoke real |
| CI distinta del entorno local | reutilizar los mismos entry points |
| Test framework pesado | timebox del spike y eliminación de candidatos descartados |
| Input atado a PC | acciones abstractas y harness con keyboard/gamepad |
| Convertir el harness en gameplay prematuro | limitarlo a observación de input y bootstrap |
| Empezar Phase 1 sin toolchain reproducible | checklist bloqueante P0-12 |

## 12. Resultado y handoff a Phase 1

Phase 0 entrega:

1. Godot 4.6.3 fijado y verificado;
2. bootstrap ejecutable con diagnóstico de input;
3. acciones abstractas con bindings desktop/gamepad;
4. GdUnit4 6.2.1 con exit codes y reportes;
5. import, smoke, tests y CI reproducibles.

El siguiente bloque permitido es **Phase 1 - Feel First Sandbox**: `PlayerMovementProfile`, controller, cámara y debug room. No se habilitan todavía RPG, enemigos, ideologías ni motor de niveles.
