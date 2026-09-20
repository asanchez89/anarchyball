# ADR-0007: encuentros requeridos para completar un nivel

- Estado: aceptado
- Fecha: 2026-09-20

## Contexto

La primera misión de campaña enseña defensa de terceros. Permitir que la salida complete la misión antes de resolver el encounter contradice esa intención y hace imposible medir el aprendizaje. Los prototipos existentes, en cambio, deben conservar su comportamiento.

## Decisión

LevelSpec v0 admite el campo opcional `encounters[].required_for_completion`, booleano y falso por defecto. `LevelBuilder` es la autoridad local que consulta los `EncounterRuntimeObserver` antes de confirmar la salida. La regla no depende de mundo, ideología, facción ni clase.

## Consecuencias

- Los LevelSpec existentes siguen siendo válidos sin migración.
- Una salida bloqueada debe ofrecer feedback y permitir un intento posterior.
- Las misiones pueden exigir encounters concretos sin introducir un manager global.
- El validador y el schema rechazan tipos distintos de booleano.
