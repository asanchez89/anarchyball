# Código fuente

El código se incorporará por capacidad demostrada, no creando jerarquías vacías por anticipado.

Estructura objetivo:

- `actors/`: player, enemigos, NPC y bosses compuestos;
- `components/`: capacidades reutilizables sin conocimiento de mundos;
- `combat/`: conflicto, elegibilidad de objetivos, efectos y Resolve;
- `classes/`: loadouts y habilidades;
- `ideology/`: reglas y modificadores data-driven;
- `core/`: arranque y contratos transversales mínimos;
- `hub/`, `rpg/`, `dialogue/`, `ui/`, `save/`: sistemas que se crearán en su fase correspondiente.

La dirección permitida de dependencias está en `docs/ARCHITECTURE.md`.

