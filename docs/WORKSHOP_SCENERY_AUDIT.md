# Taller: decoración y utilidad

Se conservan alimentación A (servicio confirmado y ascensor hacia llave/munición),
panel A (retorno alto), montacargas B (acceso a suministros), alimentación y panel C
(ruta elevada de salida), llamadas de ascensores (recuperación sin bloqueo) y
alimentación de equipos (coordinación BlackAnarchy). No se agregan cobros nuevos.

Se retiran del nivel compuesto la prensa ocupada y el molino disputado: no tenían
resolución útil en el diseño actual. También se retiran el mecánico duplicado del
ascensor y el reclamante del molino. Sus arquetipos y escenas históricas permanecen.
El técnico de despacho se acerca a alimentación C; el operador de producción usa
la explicación mecánica vigente, no el diálogo de la prensa eliminada.

Los props decorativos no tienen interacción ni colisión. Se añaden 12 grupos de
cajas, suministros y servidores. El apoyo exige todo el ancho alpha sobre una
superficie permanente: excluye ascensores y plataformas controladas. Se ajusta
la posición al tramo válido más cercano, dejando 90 px a cada lado de las puertas
además del semiancho del prop. Sin apoyo válido, se omite con aviso. La capa
absoluta -1 evita depender de la jerarquía del escenario; arte de ascensores -8.

La selección de assets incluye
cajas, suministros y servidores; la capa decorativa supera a TerrainArt y su base
se ancla por el borde alpha visible. No se generan imágenes. El ATM usa
`cyberpunk-corridor-files/Props/PNG/small-terminal.png` de Warped con rótulo BTC.
Bitcoin sigue siendo moneda ficticia local, sin transacciones externas.

Reglas preservadas: GR-LEVEL-001, GR-ENCOUNTER-001, GR-ECON-002 y GR-CONFLICT-001.
Probar desde NUEVO TALLER; un checkpoint antiguo puede conservar posiciones de NPC.
Pendiente recorrido humano completo para evaluar densidad y legibilidad en combate.

La puerta de Despacho se coloca en x=16090, apoyada en el suelo de salida,
después del extremo de la pasarela elevada y antes de Coordinación. El panel C
o neutralizar la patrulla liberan ese paso real. Ya no queda incrustada en las
columnas bajo el jugador. No añade una habitación ni un requisito nuevo.
