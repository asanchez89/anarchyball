# Nivel 1 — Asociaciones bajo asedio

**Revisión vigente 2026-09-23:** `LEVEL_01_PARTS_2_3.md` reemplaza los desafíos
principales y duraciones de partes 2/3 de este documento. Sus secciones de
coordinación/corredor quedan como antecedentes. El jefe no está en la entrega actual.

Revisión: 2026-09-22. Implementación incremental, no nivel completo.
El taller constituye la parte 1. Existe un primer encuentro acumulativo de la
parte 2; su expansión, la parte 3 y el jefe siguen pendientes.
La identidad propuesta del jefe requiere aprobación antes de arte
o producción. Este nivel no equivale automáticamente a todo World 0.

## Estructura y continuidad

| Tramo | Reparto principal | Verbo distintivo | Resultado visible |
|---|---|---|---|
| 1. Taller comunal | Mutualist, Ancom, Egoist | operar sin desplazar; resistir presión colectiva; esquivar saqueadores | maquinaria útil, rendición colectiva, restitución y recompensas |
| 2. Nadie manda aquí | se incorpora BlackAnarchy | distribuir coordinación y rotar facilitadores | varios equipos sostienen rutas sin depender de una sola voz |
| 3. Reclamo y paso | se incorpora LeftLibertarian | compatibilizar uso de un recurso y acceso de terceros | corredor transitable junto a una instalación productiva |
| Clímax. La fuerza no es un título | las cinco balls colaboran | combinar los verbos aprendidos bajo ataque | neutralizar al comandante y liberar la salida |

PoliceBall sigue siendo el agresor recurrente en las tres partes: requisa, redada
y detención deben ser observables. Ni el uniforme ni una ideología habilitan daño.
No se sustituye ninguna de las tres balls del taller. Agorist es una clase de
AnarchyBall, no un NPC independiente ni un aliado requerido; su implementación
jugable sigue en Phase 8. Contractor debe poder completar todo el recorrido.

## Parte 1 — conservar y conectar

La progresión es acumulativa: parte 2 conserva Mutualist/Ancom/Egoist y añade
BlackAnarchy; parte 3 conserva las cuatro y añade LeftLibertarian. Tras enseñar
brevemente cada nuevo verbo, alternar combinaciones de dos o tres antes del
clímax de cinco apoyos. No hacer tramos exclusivos ni cinco tareas por sala.

Se mantiene `WORKSHOP_REDESIGN.md`: recepción, producción, depósito, almacén y
despacho; no se reinicia su diseño por introducir las otras partes. El despacho
se convertirá en transición hacia el barrio de BlackAnarchy, no en final global.
Mutualist enseña maquinaria, Ancom resistencia colectiva y Egoist evasión de robo
con restitución al resolver; el botiquín ya no resuelve su desafío. Antes del
jefe, un ensayo seguro debe demostrar el apoyo Ancom de cobertura/recuperación;
la tregua por sí sola no enseña ese apoyo. No se exige un nuevo sector Ancom.

## Parte 2 — BlackAnarchy: coordinación distribuida

Base narrativa: `STORY_BIBLE.md` §3.7 y el brief histórico §6.5. No representar
a BlackAnarchy como manipulación ni a PopularBall como enemigo por ser influyente.
La fortaleza es organizar cooperación sin mando obligatorio; la tensión es la
dependencia accidental de un único facilitador.

1. **Enseñar:** dos equipos esperan la señal de PopularBall. Una ruta de retorno
   permanece libre; una señal visible muestra quién espera a quién.
2. **Practicar:** con BlackAnarchy, el jugador asigna voluntariamente un
   facilitador por equipo y prueba la rotación. Elegir cobertura o relevos cambia
   qué tramo queda atendido; no se resuelve leyendo tres diálogos o pulsando tres
   botones equivalentes.
3. **Presión:** una redada policial interrumpe un puesto. El jugador llega por una
   ruta alternativa y releva la función para sostener el avance; la coordinación
   distribuida mantiene el otro equipo activo.
4. **Combinar:** escoger el orden de dos apoyos permite cruzar y defender a terceros.
   Abandonar la tarea no convierte a los vecinos en hostiles. La policía no se
   vuelve pacífica porque se haya completado el puzzle.

Escenario: patio de reunión, puestos de trabajo y pasarelas comunicadas. Reutilizar
Warped para estructuras y props; señales/iconos funcionales, fuente legible y
feedback audiovisual explican los cambios. Sin plataformas sin soporte.

## Parte 3 — LeftLibertarian: recurso y corredor

Base narrativa: `STORY_BIBLE.md` §3.6 y el brief histórico §6.4. La fortaleza es
hacer compatible la producción con el acceso; la tensión son efectos reales sobre
terceros, no un examen de respuesta ideológica correcta.

1. **Enseñar:** usar una toma de agua pone en marcha una instalación, pero su
   disposición corta un sendero previo. Mostrar ambos efectos antes de confirmar.
2. **Practicar:** elegir entre conservar producción con un corredor de paso,
   reducir/desplazar la toma o renunciar al uso y cruzar por otra ruta.
3. **Presión:** PoliceBall intenta requisar la instalación mientras el jugador
   mantiene o recupera el corredor. Combatir a la policía no resuelve por sí solo
   el conflicto de acceso entre vecinos.
4. **Combinar:** resolver caudal y tránsito en dos alturas. Cada alternativa tiene
   coste espacial o de suministro visible y una salida con movimiento base.

Sin dinero obligatorio, economía persistente ni crafting nuevos. Compensación
monetaria queda como variante futura, no requisito de esta primera versión.
Actualización aprobada: `LEVEL_01_ECONOMY.md` reemplaza la restricción de dinero
local; permite servicios de taller con componentes garantizados y tienda en sats
ficticios. Continúan excluidos crafting y simulación económica persistente.
Revertir una elección debe permitir recuperar el paso; nadie queda atrapado.

## Jefe propuesto — KraterocracyBall, Comandante de la Requisa

**Candidato, no elección definitiva.** Referencia consultada el 2026-09-22:
[Kraterocracy en Polcompball](https://polcompball.wiki/Kraterocracy), que la
caracteriza mediante dominio por la fuerza y describe una ball negra con omega
azul oscuro. Nuestra adaptación: comandante estatista local de ocupación;
no avatar, cría ni versión menor de The LeviathanBall. Silueta grande (probar
2,5–3 diámetros), símbolo reconocible y ojos sin pupilas. El arte final no está
generado ni se importan imágenes de la wiki; verificar permisos por asset antes
de reutilizarlo. La wiki es referencia de ficción visual, no autoridad histórica.

Alternativa: [Police Statism](https://polcompball.wiki/Police_Statism), más ligada
a la policía secreta, pero menos diferenciada visualmente de los agentes comunes.
No producir ambos candidatos. El nombre interno provisional del encounter es
`frontier_coalition_boss`; no registrar contenido hasta decidir el candidato.

El comandante se presenta antes del final mediante órdenes de requisa; en la
arena ejecuta captura y ataque contra la coalición. Ese acto, no su emblema,
establece `AGGRESSOR`. Su respuesta a Resolve agotado será desarme/neutralización,
sin fase de rendición fingida ni ejecución del derrotado.

### Combate y apoyos

| Aliado | Apoyo observable | Acción del jugador |
|---|---|---|
| Mutualist | elevador y cobertura móvil | elegir altura y momento para evitar barrido y responder |
| Ancom | reserva compartida acotada | elegir cobertura temporal o recuperación; no ambas ilimitadas |
| Egoist | alijo de emergencia cedido explícitamente | recogerlo cuando convenga, sin convertirlo en llave obligatoria |
| BlackAnarchy | relevo entre puestos de apoyo | redistribuir operadores cuando un puesto queda inutilizado |
| LeftLibertarian | corredor lateral preservado | mantener una salida mientras otros sistemas ocupan el centro |

Tres fases: barrido/embestida telegrafiados; refuerzos policiales limitados e
interrupción de un puesto; combinación de patrones y contraataque final.
Los apoyos crean ventanas, no sustituyen el combate con cinco interruptores.
Máximo dos decisiones de apoyo simultáneas; sin oleadas infinitas ni pausas largas
de invulnerabilidad. Los aliados no requieren escolta permanente ni pueden morir
fuera de pantalla causando softlock. Un puesto interrumpido se recupera o releva.
Todas las fuerzas indirectas consultan TargetValidity; neutralizado el jefe,
cesa inmediatamente el daño de jugador y aliados.

Cada apoyo principal se demuestra antes de necesitarlo. El encuentro reúne a las
cinco balls sin convertir la amistad, el duelo o los coleccionables opcionales en
checklists ocultos de desbloqueo. El reto es aprovechar ayudas, no convencer a
todos de adoptar la ideología de AnarchyBall.

## Longitud, guardado y migración

- Primera vuelta provisional: parte 1, 8–12 min; parte 2, 5–7; parte 3, 5–7;
  jefe, 3–5. Total 21–31 min, por validar; no es el presupuesto de una misión
  estándar de 8–12 ni autorización para rellenar recorrido.
- Checkpoint entre partes, antes del jefe y tras bloques de riesgo según playtest.
  Morir en el jefe no obliga a repetir las tres partes. Guardar parte, mecanismos,
  elecciones de acceso y apoyos; probar reanudación con cada ruta resuelta.
- Conservar los IDs y saves existentes. `w0_03_occupancy_workshop` será la fuente
  de la parte 1; `w0_05_hierarchy_without_titles` y `w0_04_claim_and_access` son
  briefs fuente de las partes 2 y 3, en ese orden, no números de presentación.
- `w0_01_first_aggression` y `w0_02_contract_bridge` permanecen prototipos jugables
  de onboarding/contratos. No exigirlos como dos niveles previos al nuevo nivel 1.
  Integración del onboarding, routing y migración de progreso requieren un cambio
  posterior probado; esta revisión no altera el catálogo ni borra escenas.
- `w0_06_common_pool` y `w0_07_leviathan_escape` dejan de imponer un duelo Ancom
  y un escape obligatorio después de este jefe. Sus ideas son material reutilizable.
  La extensión restante de World 0 queda por replanificar, no se presume eliminada.

## Orden de producción y aceptación

1. Validar parte 1 con teclado/gamepad y fijar su salida de transición.
2. Prototipar coordinación/relevos, probar estados y construir parte 2.
3. Prototipar acceso/uso reversible, probar todas las salidas y construir parte 3.
4. Aprobar identidad del jefe; enseñar apoyos faltantes; producir arena y fases.
5. Integrar routing/save, resumir estado por parte y probar el nivel completo.

Reglas afectadas: GR-WORLD-005, GR-LEVEL-001..010, GR-BOSS-001..003,
GR-ENCOUNTER-001/002, GR-COMBAT-002, GR-RETRY-001 y GR-ECON-001.
No se cambia elegibilidad ofensiva ni se crean excepciones por ideología.
Pruebas futuras: relevos idempotentes, aislamiento de señal, acceso reversible,
recuperación de puestos, checkpoint por parte y neutralización que detiene apoyos.
P7.4/P7.5 se ordenan por experiencia, no por numeración histórica de archivos.

## Avance jugable 2026-09-22

- Menú: `NIVEL 1 · NUEVO TALLER` / `CONTINUAR AVANCE`; escena
  `levels/world_0/w0_01_coalition_workshop.tscn`. ID nuevo y checkpoint separado;
  no modifica ni completa la campaña antigua. Su salida dice fin del avance.
- Taller y primer encuentro BlackAnarchy: una alimentación Mutualist sirve a
  dos equipos; la agresión policial interrumpe la señal central, mientras cada
  relevo local mantiene su ruta independientemente. Hay presión colectiva Ancom y
  saqueadores Egoist en esa misma sección. Asignación reversible y restauración en checkpoint.
- Warped sci-fi-interior-platform reemplaza todo el terreno de templo del taller:
  pisos y placas metálicas, columnas arriostradas, fondo industrial y guías de
  ascensor compradas. Arte móvil y colisión comparten ancho y superficie de apoyo.
- BlackAnarchy usa arte generado desde su concepto propio, cuatro frames por
  estado; varios estados comparten fila. Se reutiliza el cañón separado existente.
- Pendiente: ampliar la parte 2 más allá de este encuentro introductorio,
  implementar acceso reversible de LeftLibertarian, ayudas y jefe; migración
  definitiva de campaña; playtest físico de teclado/gamepad y tiempos.
- Validación del avance: `tools/phase0/verify_all.cmd` completo en Godot 4.6.3,
  importación, validación de datos, smoke y 164 tests aprobados. Capturas del
  menú y zonas industriales revisadas; no sustituyen una partida humana completa.
# Apertura revisada — septiembre 2026

Antes del taller se superan tres controles policiales consecutivos (1, 2 y 3
unidades) con puertas de resolución. Hay reposición de munición y salud antes del
tercero; después, checkpoint y tienda para vender las recompensas y prepararse.
Las interacciones Mutualist, Ancom, Egoist y BlackAnarchy conservan su secuencia
posterior. El bloque original desde x=850 se desplazó 1800 px junto con decoración,
señales y terminales de coordinación; longitud actual del avance: 19900 px.
Validación automatizada: 183 pruebas. Balance y duración pendientes de playtest.
# Retorno desde el equipo B

La caída desde `crew_gallery` a `crew_lower` dispone de tres peldaños permanentes
de retorno (`crew_backtrack_low/mid/high`), con soportes industriales, anchura
120 px y ascensos de 80/80/75 px. Permiten volver a la galería y alimentación
sin pagar, encender equipos ni completar combate. La pasarela coordinada sigue
siendo un atajo horizontal, no la única salida del desnivel. GR-LEVEL-003/010 y
GR-CORE-008; validar físicamente los cuatro saltos con alimentación apagada.
