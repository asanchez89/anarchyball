# Auditoría de partes 2 y 3

> Registro de la iteración anterior. No certifica el rediseño vertical actual:
> consultar `LEVEL_01_VERTICAL_REDESIGN.md` para avances y pendientes vigentes.

Escena: `levels/world_0/w0_01_coalition_workshop.tscn`.
Contrato: `LEVEL_01_PARTS_2_3.md`; no incluye jefe, commit ni push.

| Requisito | Evidencia implementada y comprobación |
| --- | --- |
| Conservar parte 1 y añadir ambas partes | Datos del nivel: encuentros originales conservados; seis nuevos encuentros en parte 2 y siete en parte 3. Suite de regresión incluye economía, desplazamiento y resolución anteriores. |
| BlackAnarchy | `encounter_black_anarchy_flank.tres`, `_advance_flankers`: aviso, objetivos alternos, regreso físico acotado, dos ataques como límite y bonus de rendición con tope. Prueba de aviso, presupuesto y bonus persistente en `test_ceasefire_challenge.gd`. |
| LeftLibertarian | `marked_pulse.gd`: una marca, espera visible, radio adaptable a apoyo, daño 3, empuje hacia dentro con distancia de frenado, bonus limpio limitado. Pruebas de restauración, plataformas y daño durante el aviso. |
| Alternancia y alturas | Datos `p2_*` y `p3_*`: Policía, Black, Ancom, Egoist y Left; nuevo flanqueo elevado con recompensa. Once trayectos físicos y grafo de alcance en `test_new_workshop_routes.gd`. |
| Mutualist | Dos compuertas de mantenimiento pagadas y ayuda opcional elevada en arena. `service_gates`, componentes protegidos previos y confirmación de pago; prueba de checkpoint y exclusión de resolución de combate. ADR-0012. |
| Tres tiendas | `additional_shops` y `WorkshopEconomy.shops`: compra/venta e inventario compartido. Pruebas de saldo, cantidades, protección de objetos y restauración en `test_workshop_economy.gd`. Tienda de parte 2 retirada del recinto Egoist. |
| Arena acumulativa | `encounter_workshop_coalition.tres`: cuatro parejas y Mutualist neutral, etapas 0/12/24/36, 65 segundos compartidos, dos ataques y una marca. Pruebas de ambas resoluciones, rendición limitada al subgrupo y restitución física. |
| Legitimidad y persistencia | `TargetValidity` sigue siendo autoridad; prueba de inmunidad previa a agresión y tras rendición. Checkpoint en cuatro etapas conserva reloj, estados, marca, inventario robado y saldo, sin recompensas duplicadas. |
| Zona segura final | Puerta final 38820, checkpoint 39150, ATM 39600 y salida 40000; no hay contenido de jefe. |
| Arte y apoyo | Warped para taller, soportes, props y tiendas; atlas Left nuevo. Capturas de ambas partes, arena y 16 frames por ball en ambos sentidos. Tests de apoyo/escala, transparencia y frames distintos. |

## Límites de la evidencia

Las pruebas físicas automatizadas no son un recorrido humano completo. Los
objetivos de 8–10 y 9–12 minutos permanecen sujetos a playtest; no se presentan
como duraciones medidas. No se certifica balance final, dificultad percibida ni
legibilidad de todos los efectos durante juego humano. Teclado/gamepad tienen
pruebas de acciones y menús, no una sesión manual completa de estas partes.
WASAPI no abrió en la captura local: audio dummy, sin comprobación auditiva.
Los niveles siguen siendo borradores jugables hasta el playtest humano exigido
por AGENTS.md. No se implementó contenido de jefe.
