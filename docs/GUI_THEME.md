# Tema de interfaz del taller

El recurso compartido `assets/ui/game_theme.tres` aplica la fuente Press Start 2P
del briefing, panel opaco azul oscuro, borde cian, títulos amarillos y foco de
3 px amarillo. Botones rectangulares con estados normal, hover, pulsado y
deshabilitado. No requiere imágenes generadas ni autoload.

Consumidores: menú de campaña, tienda, menú del jugador y overlay de briefing/pausa.
El menú muestra un solo frame de AnarchyBall. La tienda reutiliza los iconos de
armas Warped del perfil económico; conserva precios, inventario y transacciones.
El foco inicial vuelve a Nuevo taller al regresar a campaña. Las acciones UI
incluyen bindings explícitos para arriba/abajo, aceptar y cancelar en teclado y
gamepad, sin modificar bindings de gameplay.

Reglas GR afectadas: ninguna cambia; presentación de la economía GR-ECON-002.
Capturas: `tools/art/capture_workshop_review.gd -- --menu` y `-- --economy`.
Revisión visual realizada a 1280 × 720. Pendiente prueba humana con mando físico
y adaptación específica a otras relaciones de aspecto. Este cambio no rediseña
el HUD de gameplay ni las burbujas de diálogo.

El menú del jugador (`PlayerInventoryMenu`) usa I / View, con estadísticas e
inventario en dos columnas. Pausa el mundo, comparte el retrato de un solo frame
y admite cierre por I/View, Esc/B o botón. No se abre sobre tienda, briefing,
pausa o finalización. El HUD anuncia el acceso. Captura: `-- --inventory`.

Validación: importación headless y 182 pruebas aprobadas; recurso compartido,
bindings de ambos dispositivos, retrato de un solo frame y restauración del foco.
