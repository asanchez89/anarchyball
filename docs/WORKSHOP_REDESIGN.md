# Taller comunal — rediseño jugable

Estado: implementación candidata; requiere playtest humano. Diseño autorizado 2026-09-21.

Reglas: GR-CORE-001/004/005/007/008/010, GR-COMBAT-002, GR-ENCOUNTER-002,
GR-LEVEL-001..010. La precisión del apoyo corresponde a GR-MOVE-001.

## Papel en el nivel compuesto (2026-09-22)

Este taller pasa a ser la **parte 1 del primer nivel**, conservando Mutualist,
Ancom y Egoist. Le siguen BlackAnarchy, LeftLibertarian y un jefe estatista con
apoyos de las cinco balls según [LEVEL_01_COALITION.md](LEVEL_01_COALITION.md).
El despacho será una transición, no el final del nivel completo. Esta decisión
es documental: la escena y el progreso actuales aún conservan la salida anterior.
No se sustituye el taller por un sector exclusivo Mutualist ni se añade Agorist NPC.

## Recorrido

| Zona | Espacio | Problema y consecuencia |
|---|---|---|
| Recepción | 0–1800 | Una requisa activa; neutralizar la PoliceBall libera la puerta. Desnivel para esquivar. |
| Producción | 1800–4500 | Prensa en uso y molino disputado permanecen intactos. Restaurar la alimentación alternativa, subir al panel y habilitar una pasarela útil. Ascensor reutilizable, escalones de recuperación. |
| Depósito | 4500–7300 | Aproximarse por niveles escalonados a la baliza de tregua. Retirarse cancela advertencia; tregua o rendición libera la pasarela del depósito. |
| Almacén | 7300–10300 | Egoist autoriza recuperar un botiquín alto. Escalones cortos o elevador restaurado permiten alcanzarlo; encuentro sin temporizador de agresión por proximidad. |
| Despacho | 10300–14400 | Policía ocupa suelo y pasarela. Baliza Ancom abre atajo, alijo Egoist cura, alimentación Mutualist habilita control superior. Salida por neutralización o reruteo, sin exigir todas las soluciones. |

Primera vuelta objetivo: 8–12 min; repetición: 4–6; completionist: 10–16.
La anchura de 14.400 px no equivale a duración: ascensos y recorridos interiores
aportan ruta efectiva; medir tres primeras vueltas y tres repeticiones. Si no
sostiene duración activa, reclasificar en vez de añadir espera o enemigos de relleno.
Checkpoints tras producción y antes del despacho; ajustar al tiempo observado.

## Presentación

Warped sci-fi-interior-platform: fondo industrial, pisos y placas metálicas,
pasarelas con columnas arriostradas y guías de ascensor de cyberpunk-corridor.
El taller ya no usa el terreno de templo de Twilight Forest.
Props Warped existentes: estaciones de trabajo, consolas, depósitos,
botiquines y checkpoints. Cada zona se compone con placements explícitos,
señalización funcional y conexiones entre controles y destinos. La baliza usa
arte de señal existente diferenciado de maquinaria. Nada depende de un placeholder.
Elevadores con apoyos/guías, superficie de al menos 288 px, parada de embarque,
colisión unidireccional y arte recortado al ancho físico exacto.

## Aceptación

- Llegar a la salida por combate y por panel alternativo con policía activa.
- Tregua y suministros tienen beneficios locales, sin bloquear globalmente la salida.
- Los controles con dependencia indican qué falta; no se activan fuera de orden.
- Las caídas permiten volver a intentarlo sin reiniciar maquinaria ni quedar encerrado.
- Checkpoints restauran mecanismos, rutas liberadas, rendiciones y recursos.
- Probar apoyo de ascensor con física real, además de geometría y referencias.
- Verificar teclado y gamepad en playtest; no confundir pruebas headless con input físico.

## Validación de la candidata

2026-09-21: `tools/phase0/verify_all.cmd` completo: importación, validación de
contenido, smoke y 158 tests aprobados. Incluye transporte físico en ascensor,
dependencias, tregua/rendición, salida bajo fuego, restauración de checkpoints
y estado visual de pasarelas. Capturas de cinco zonas mediante
`tools/art/capture_workshop_review.gd`; se corrigió el terreno que tapaba actores.
Pendiente: partidas completas con teclado/gamepad, medición de tiempos y ajuste
de dificultad. Las pruebas de geometría no sustituyen estas partidas.
