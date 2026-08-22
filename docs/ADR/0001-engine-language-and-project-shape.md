# ADR-0001: Motor, lenguaje y forma del proyecto

- **Estado:** Aceptado
- **Fecha:** 2026-08-21

## Contexto

Anarchyball necesita gameplay 2D multiplataforma, iteración rápida, contenido data-driven y herramientas que puedan ejecutarse sin interfaz para validar contribuciones y niveles. El equipo debe poder extender el juego sin introducir una clase monolítica ni depender de un backend en el MVP.

## Decisión

- Godot `4.6.3-stable` oficial como versión exacta del motor.
- GDScript con tipado estático como lenguaje principal.
- Renderer Compatibility como punto de partida hasta completar profiling.
- Composición de escenas y componentes sobre herencia profunda.
- Godot Resources para definiciones estables y JSON versionado para LevelSpec generable.
- Windows como primer target; input y UI conservarán compatibilidad conceptual con gamepad y touch.
- Sin C#, backend ni plugins de gameplay externos durante la fundación, salvo ADR posterior con evidencia.

La instalación local disponible es `4.6.3.stable.mono.official.7d41c59c4`. Se acepta como host de desarrollo porque el proyecto no contiene C#; CI usa el build estándar de Godot `4.6.3-stable`. Ambos ejecutan el mismo proyecto GDScript y la misma suite.

## Evidencia de Phase 0

- `config/features` fue normalizado por Godot a `4.6`.
- Importación headless: exit code `0`.
- Bootstrap headless: exit code `0`.
- Bootstrap gráfico: exit code `0` sobre OpenGL 3.3 Compatibility.
- Renderer de desktop y mobile: `gl_compatibility`, cubierto por test.
- El build Linux de CI se descarga desde `godotengine/godot-builds` y se verifica contra `SHA512-SUMS.txt` oficial.

## Consecuencias

- El framework de tests queda decidido en ADR-0002.
- La lógica crítica debe poder probarse headless.
- Los formatos persistentes y LevelSpec tendrán versión explícita.
- Android/iOS no se exportan en el MVP inicial, pero no se aceptan dependencias device-specific en gameplay.
- Un cambio de motor, lenguaje principal o modelo data-driven requiere un ADR que reemplace este documento.
- Una actualización de Godot requiere import, smoke, tests y revisión de compatibilidad antes de modificar la versión fijada.

La sección `[dotnet]` que puede normalizar el editor Mono es metadata inerte mientras no existan scripts C#, `.csproj` ni dependencias .NET. No autoriza introducir C#.
