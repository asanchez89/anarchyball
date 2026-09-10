# Phase 1 - Feel First Sandbox

- **Estado:** DONE; gate aceptado tras playtest manual
- **Inicio:** 2026-08-22
- **Motor:** Godot 4.6.3 estable, renderer Compatibility
- **Reglas afectadas:** `GR-MOVE-001`, `GR-MOVE-002`, `GR-MOVE-003`, `GR-MOVE-004`

## Objetivo

Conseguir un sandbox jugable donde mover al protagonista ya resulte evaluable antes de construir combate, mundos o progresión. La geometría de prueba se deriva del mismo perfil que usa el controller.

## Alcance implementado

- `PlayerMovementProfile` como `Resource` único para velocidades, aceleración, gravedad, salto, coyote time, jump buffer y parámetros reservados de dash;
- movimiento horizontal con aceleración, desaceleración y control aéreo;
- salto variable, coyote time de 120 ms y jump buffer de 120 ms;
- cámara con límites, smoothing y screen shake graduable;
- sala corta con plataformas, hueco, reinicio al caer y métricas visibles;
- input abstracto compartido por teclado/mouse y gamepad;
- sonda de puntería sin daño contra una diana mecánica;
- pruebas deterministas del perfil, ventanas de salto y geometría base;
- smoke test de la escena principal jugable.

La sonda no es un arma de gameplay: no aplica daño, no selecciona personajes y no crea una autoridad paralela de objetivos. `TargetValidity`, enemigos, daño y Resolve pertenecen a Phase 2.

## Métricas iniciales

| Métrica | Valor |
|---|---:|
| Velocidad de carrera | 300 px/s |
| Gravedad | 1800 px/s² |
| Velocidad inicial de salto | 620 px/s |
| Tiempo al ápice | 344 ms |
| Altura máxima teórica | 106.8 px |
| Alcance horizontal ideal | 206.7 px |
| Alcance conservador para diseño | 165.3 px |
| Coyote time | 120 ms |
| Jump buffer | 120 ms |

Estas cifras son una línea base de tuning, no un contrato inmutable. Todo ajuste se hace en `data/player/default_movement_profile.tres`; las métricas y tests parten del mismo recurso.

## Criterios de aceptación

- [x] controller reproducible en una escena jugable;
- [x] coyote time y jump buffer cubiertos por tests;
- [x] altura y alcance derivados del perfil y visibles en HUD;
- [x] salto corto reduce la altura al soltar el botón;
- [x] cámara suavizada, limitada y con shake ajustable;
- [x] sala de plataformas diseñada según las métricas conservadoras;
- [x] importación headless sin errores;
- [x] smoke test de escena principal;
- [x] suite GdUnit4: 14/14 tests;
- [x] playtest humano comunicado por el responsable del proyecto;
- [x] corrección posterior: todo lanzamiento respeta el hemisferio de `facing_direction`.

El detalle de hardware y duración de la sesión no quedó registrado. El responsable aceptó el gate y autorizó comenzar Phase 2 el 2026-09-08, condicionado a corregir la orientación del disparo; la regresión quedó cubierta por tests.

## Guion de playtest

1. Recorrer las tres plataformas ascendentes sin herramientas de debug.
2. Saltar durante los primeros 120 ms después de abandonar un borde.
3. Presionar salto poco antes de aterrizar y comprobar que se ejecuta al tocar suelo.
4. Comparar un toque corto con mantener salto.
5. Cruzar el hueco del suelo corriendo y saltando.
6. Apuntar con mouse o stick derecho y acertar la diana con ataque primario.
7. Activar shake con `ability_1` y comprobar que la cámara vuelve a su centro.
8. Repetir con teclado/mouse y gamepad; registrar modelo del mando y cualquier binding confuso.

## Fuera de alcance

- dash como mecánica activa;
- armas que causen daño;
- enemigos o comportamiento hostil;
- Resolve, Mercy, conflicto o elegibilidad de objetivos;
- clases, mundos, RPG, generación y validación de niveles.
