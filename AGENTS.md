# AGENTS.md

## Alcance

Estas instrucciones aplican a todo el repositorio.

## Fuentes de autoridad

Antes de implementar, leer en este orden:

1. `AGENTS.md`;
2. `docs/PROJECT_PLAN.md` para producto, narrativa y alcance;
3. `docs/GAMEPLAY_RULES.md` para gameplay momento a momento;
4. `docs/ARCHITECTURE.md` para dependencias y contratos técnicos;
5. `docs/DEVELOPMENT_PHASES.md` para alcance de la fase actual;
6. ADR aceptados en `docs/ADR/`;
7. código y tests existentes.

Si `GAMEPLAY_RULES.md` contradice una descripción general de gameplay de `PROJECT_PLAN.md`, prevalece `GAMEPLAY_RULES.md`. No cambiar una regla `GR-*` de forma implícita: proponer primero el cambio documental.

## Reglas de implementación

- Usar Godot 4.x estable y GDScript con tipado estático.
- Favorecer composición y componentes; evitar jerarquías profundas.
- Mantener valores ajustables en `Resource` o configuración, no dispersos en scripts.
- Consumir acciones abstractas de input; el gameplay no comprueba dispositivos concretos.
- Centralizar elegibilidad de objetivos. Armas, proyectiles, drones, trampas y aliados deben consultar la misma autoridad.
- No condicionar el núcleo por nombres de mundos, ideologías, facciones o clases.
- Referenciar contenido mediante IDs estables en `snake_case`.
- No crear un autoload, manager global o abstracción genérica sin una necesidad comprobable.
- Las rutas obligatorias usan movimiento base; las rutas de clase son opcionales y se declaran mediante tags.
- Los niveles generados son borradores hasta superar validación y playtest humano.

## Calidad

Toda contribución debe:

- identificar las reglas `GR-*` afectadas;
- incluir o actualizar tests para lógica determinista;
- validar referencias y datos modificados;
- ejecutar importación headless cuando Godot esté disponible;
- comprobar teclado y gamepad cuando cambie controles;
- reportar archivos, pruebas y limitaciones conocidas.

No declarar terminado gameplay que solo existe en código y no puede reproducirse en una escena o prueba.

## Límites del MVP

El MVP no incluye backend, multijugador, mundo abierto, 4X, city builder, crafting profundo, economía persistente, generación procedural infinita ni el roster completo de mundos y clases. Consultar `docs/DEVELOPMENT_PHASES.md` antes de ampliar alcance.

