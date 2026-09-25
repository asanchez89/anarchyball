# Partes 2 y 3 — contrato de producción aprobado

Histórico de la primera integración. La nueva iteración aprobada se rige por
`LEVEL_01_VERTICAL_REDESIGN.md`, incluyendo parte 1 y retirada Ancom protegida.
Los resultados de pruebas siguientes no validan todavía ese rediseño.

Fecha: 2026-09-23. Estado: implementación y validación automatizada completas;
borrador jugable pendiente de playtest humano, no balance final certificado.
Esta revisión reemplaza la coordinación BlackAnarchy y el corredor
LeftLibertarian como desafíos principales de las partes 2/3. Sus variantes
amistosas y los prototipos existentes se conservan como contenido secundario.
No incluye escenario, combate ni producción de assets del jefe.

## Reglas de encuentros

- BlackAnarchy: flanqueo autónomo entre apoyos alcanzables, aviso antes de
  comprometer agresión, persecución limitada al recinto y regreso físico.
  Máximo dos ataques comprometidos simultáneos. Una rendición retira solo a
  ese integrante y acelera de forma limitada la tregua restante. Resolver
  por rendición de todos o supervivencia dentro del área central.
- LeftLibertarian: marcas temporales anunciadas sobre superficies, seguidas
  de pulsos de daño bajo y empuje moderado. Siempre queda una superficie
  segura alcanzable con salto base; nunca empujar a una caída inevitable.
  Una secuencia esquivada sin impacto da un avance limitado de tregua.
  Recibir daño no reinicia ni resta progreso. Resolver por tregua o por todas
  las rendiciones. Disputa/afiliación por sí solas no autorizan daño.
- Ancom conserva retirada sin reemplazo, vulnerabilidad durante traslado,
  rendición colectiva y contador central fijo. Egoist conserva robo acotado,
  persecución/salto, retorno físico y restitución en paquete recogible.
- PoliceBall conserva agresión observable y neutralización sin tregua propia.
- Mutualist permanece neutral: servicios con confirmación, componentes
  protegidos garantizados y pago único. Ofrece mecanismos adicionales
  (por ejemplo cobertura móvil y compuerta de mantenimiento), nunca un botón
  que resuelva automáticamente el combate o la tregua de otro grupo.

## Recorrido de parte 2 (objetivo 8–10 min, por medir)

Entrada policial y suministros; BlackAnarchy de dos integrantes; servicio
Mutualist con ventaja táctica; variante Ancom; checkpoint/ATM; variante Egoist
vertical; BlackAnarchy de tres integrantes; salida con presión policial.
Cada ascenso debe ofrecer avance, recompensa, retorno o cobertura. No usar
pasillos largos o vida enemiga para simular duración.

## Recorrido de parte 3 (objetivo 9–12 min, por medir)

LeftLibertarian de dos integrantes con una marca; servicio Mutualist; variante
BlackAnarchy vertical; variante Ancom; checkpoint/ATM; variante Egoist;
LeftLibertarian de tres integrantes; arena combinada; zona segura de cierre.
Las partes acumulan mecánicas previas, no sustituyen su reparto por una sola ball.

## Arena conjunta previa al jefe

Composición inicial: 2 Ancom, 2 Egoist, 2 BlackAnarchy, 2 LeftLibertarian y
1 Mutualist neutral. Tres alturas, retornos permanentes y salto base.
Todos están presentes, pero entran en acción por etapas anunciadas. Los que
no hayan comprometido agresión permanecen inválidos para ataques del jugador.
Un contador compartido, máximo dos ataques comprometidos y una marca peligrosa
simultánea. Rendición Ancom afecta solo a su subgrupo. Rendiciones BlackAnarchy
y evasión limpia LeftLibertarian conceden avances limitados y no duplicables.
Resolver al terminar la tregua o rendirse todos los agresores. El servicio
Mutualist es una ayuda; sus componentes están disponibles antes de entrar.
Restitución, loot y pagos mantienen procedencia y recogida explícitas.

## Economía, guardado y presentación

Tres ATM en total: el existente, uno nuevo en parte 2 y otro en parte 3.
Comparten inventario, ofertas y saldo del intento. La última zona segura tiene
acceso al ATM de parte 3; no obliga a atravesar de nuevo una arena hostil.
Checkpoints restauran etapas, temporizador, rendiciones, marcas pendientes,
pagos, mecanismos, drops y robos sin duplicación ni daño al cargar.
Warped es la primera opción; generar solo arte faltante, nunca placeholders de
shipping. Fuente, señales, aura, escala y apoyo conservan las reglas del taller.

## Evidencia requerida antes de cerrar la meta

### Estado de integración (2026-09-23)

- Partes 2 y 3 conectadas a `w0_01_coalition_workshop`; la parte 1 conserva
  sus desafíos. Los nuevos encuentros alternan patrullas y alturas.
- Flanqueo autónomo y pulsos registrados como contenido; LeftLibertarian usa
  atlas nuevo basado en el concepto local. Indicadores compactos en la arena.
- Tres ATM comparten inventario. Compuertas de mantenimiento usan servicio
  confirmado y componentes protegidos; no resuelven desafíos de combate.
- Arena `p3_final_coalition`: cuatro subgrupos de dos, Mutualist neutral,
  etapas 0/12/24/36 s, contador 65 s, presupuesto compartido y restitución física.
- Importación, catálogo y suite completa: 260 pruebas aprobadas; registro
  `reports/parts_three_final_pass.log`. Corrección posterior de retratos:
  11 pruebas aprobadas en `reports/portraits_tests.log`.
  La revisión final continúa; estos resultados no certifican
  por sí solos el recorrido humano completo.
- Capturas: `tools/art/capture_workshop_review.gd -- --part-two`,
  `--part-three`, `--mixed-arena`. Reportes locales en `reports/workshop_review`.

Saltos y retornos nuevos: grafo de alcance completo y once trayectos físicos
representativos con movimiento base en `test_new_workshop_routes.gd`.
Ambas vías de resolución de la arena y restitución recogible están probadas.

Persistencia: prueba integrada de checkpoint en las cuatro etapas de la arena,
incluida marca pendiente, estados de conflicto, robo, saldo y cierre de puerta,
aprobada en `reports/mixed_checkpoint_audit.log`.

Animación: `tools/art/capture_coalition_frames.gd` permite comparar los 16 frames
de BlackAnarchy y LeftLibertarian en ambos sentidos mediante el renderer real.
Revisión visual de tamaño, apoyo, símbolos y accesorios realizada; test de
frames distintos, transparencia, margen del atlas y apoyo estable extendido a
LeftLibertarian. No sustituye una prueba humana de legibilidad durante combate.

Revisión de ritmo: tienda de parte 2 retirada fuera de la zona Egoist y segundo
flanqueo BlackAnarchy con tercer escalón, integrante elevado y munición pesada
opcional como recompensa. Saltos de ida/vuelta añadidos a la prueba física.
Capturas actualizadas revisadas y `verify_all.cmd` aprobado en
`reports/parts_final_verification.log`. Auditoría por requisito en
`LEVEL_01_IMPLEMENTATION_AUDIT.md`. Duración
humana y manejo con teclado/gamepad no medidos. El render local no pudo abrir
WASAPI y usó audio dummy: no afirmar una comprobación auditiva realizada.

### Criterios de cierre

1. Recursos, catálogo, esquema y datos válidos; escena completa reproducible.
2. Tests de legitimidad, turnos, límites simultáneos, marcas seguras, bonus
   únicos, resolución por ambas vías y restauración en cada etapa.
3. Recorrido base completo, retornos y servicios sin softlocks; saltos físicos.
4. Tres tiendas funcionales con compra/venta compartida, sin reinicializar saldo.
5. Importación headless, suite completa y capturas de ambas partes y arena final.
6. Reportar evidencia/limitaciones de teclado, gamepad y duración humana;
   no declarar que el tiempo objetivo está verificado mediante ancho del mapa.

Reglas: GR-CORE-004/005/008, GR-CONFLICT-001, GR-ENCOUNTER-001/002,
GR-LEVEL-001/002/003/005/008/010, GR-RETRY-001, GR-ECON-001/002.
