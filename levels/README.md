# Niveles

Escenas curadas y prototipos jugables. Un nivel generado permanece como borrador hasta pasar `LevelValidator` y playtest humano.

Los mundos se crearán de uno en uno cuando su regla, obstáculo, counterplay, encuentros y criterios de aceptación estén definidos.

`prototypes/occupancy_rule_preview.tscn` permite probar P6.3 sin alterar la escena principal: acercarse a cada máquina y pulsar `F` o `X` de gamepad cambia `AVAILABLE -> OCCUPIED` y materializa la plataforma marcada.

`prototypes/occupancy_workshop_draft.tscn` es el recorrido extendido de P6.5 para probar maquinaria, rutas base y opcionales, legitimidad defensiva, dos encounters, recursos y retry desde checkpoint en una sola sesión.
