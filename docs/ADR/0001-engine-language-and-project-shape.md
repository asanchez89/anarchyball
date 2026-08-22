# ADR-0001: Motor, lenguaje y forma del proyecto

- **Estado:** Aceptado
- **Fecha:** 2026-08-21

## Contexto

Anarchyball necesita gameplay 2D multiplataforma, iteración rápida, contenido data-driven y herramientas que puedan ejecutarse sin interfaz para validar contribuciones y niveles. El equipo debe poder extender el juego sin introducir una clase monolítica ni depender de un backend en el MVP.

## Decisión

- Godot 4.x estable como motor.
- GDScript con tipado estático como lenguaje principal.
- Renderer Compatibility como punto de partida hasta completar profiling.
- Composición de escenas y componentes sobre herencia profunda.
- Godot Resources para definiciones estables y JSON versionado para LevelSpec generable.
- Windows como primer target; input y UI conservarán compatibilidad conceptual con gamepad y touch.
- Sin C#, backend ni plugins de gameplay externos durante la fundación, salvo ADR posterior con evidencia.

## Consecuencias

- La versión exacta de Godot y el framework de tests siguen sujetos a spike.
- La lógica crítica debe poder probarse headless.
- Los formatos persistentes y LevelSpec tendrán versión explícita.
- Android/iOS no se exportan en el MVP inicial, pero no se aceptan dependencias device-specific en gameplay.
- Un cambio de motor, lenguaje principal o modelo data-driven requiere un ADR que reemplace este documento.

