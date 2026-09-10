# Phase 2 - Ethical Combat Kernel

- **Estado:** COMPLETADA Y APROBADA
- **Inicio:** 2026-09-08
- **Reglas afectadas:** `GR-CORE-001` a `GR-CORE-005`, `GR-CORE-009`, `GR-CONFLICT-001`, `GR-COMBAT-001`, `GR-COMBAT-002`

## Objetivo

Hacer estructural la regla central del juego: toda fuerza ofensiva controlada por el jugador consulta una sola autoridad para saber quién puede recibirla y por qué. El resultado debe ser visible, comprobable y compartido por efectos directos, proyectiles e indirectos.

## Implementación

- `ConflictStateComponent` con `NEUTRAL`, `DISPUTED`, `THREATENING`, `AGGRESSOR`, `SURRENDERING` y `NEUTRALIZED`;
- razones explícitas de agresión y referencia al tercero protegido;
- `EffectContext`, identidad de origen y `TargetPermission` inspeccionable;
- `TargetValidity` como autoridad pura compartida, sin autoload;
- `EffectReceiverComponent` como único punto de aplicación o bloqueo;
- Health para el jugador y Resolve para balls/máquinas;
- duelo voluntario por ID y participantes explícitos;
- categorías de permiso para máquinas y propiedad;
- surrender inmediato al agotar Resolve y neutralización posterior;
- telegraph visible antes de `AGGRESSOR`;
- dos arquetipos mecánicos: guardia que ataca al jugador y confiscador que agrede a un NPC protegido;
- máquina hostil destructible y máquina neutral ajena protegida;
- HUD/debug con estado, razón, Resolve y última decisión de target validity;
- dirección de lanzamiento restringida al lado hacia el que mira la figura.

## Casos automatizados obligatorios

- [x] Neutral bloquea daño ofensivo del jugador.
- [x] Disputed bloquea daño ofensivo.
- [x] Threatening bloquea hasta el compromiso.
- [x] Aggressor permite daño.
- [x] Agresión contra tercero vuelve válido al atacante.
- [x] Surrendering bloquea inmediatamente.
- [x] Duelo voluntario permite efecto entre participantes.
- [x] Orígenes direct, projectile e indirect comparten decisión.
- [x] Máquina hostil permite daño.
- [x] Máquina neutral ajena lo bloquea.
- [x] Un actor rendido no vuelve a combate sin reset explícito.
- [x] Resolve solo disminuye cuando el efecto fue permitido.
- [x] Lanzamientos hacia ambos lados y aim vertical respetan `facing_direction`.
- [x] El jugador no puede etiquetar su propio ataque como efecto de encounter para saltarse la autoridad.

## Guion de playtest

1. Disparar a `NEUTRAL`, `DISPUTED` y al guardia durante `THREATENING`; verificar el bloqueo textual.
2. Esperar el `!` y el compromiso del guardia; esquivar su proyectil y responder antes del impacto.
3. Ver la agresión del confiscador contra `NPC PROTEGIDO` y comprobar que el motivo es `THIRD_PARTY_AGGRESSION`.
4. Agotar el Resolve de ambos agresores y comprobar `SURRENDERING -> NEUTRALIZED`; disparar durante rendición debe bloquearse.
5. Agotar el Resolve del duelo consentido aunque permanezca Neutral.
6. Desactivar `MÁQUINA HOSTIL` y comprobar que `MÁQUINA AJENA` no recibe efecto.
7. Probar mouse y stick derecho detrás del personaje mirando a izquierda y derecha; todo lanzamiento debe salir al lado visible de la figura.
8. Confirmar que estado, razón y decisión se entienden sin depender solamente del color.

## Gate pendiente

- [x] los 10 casos de `GAMEPLAY_RULES.md` §25.1 están automatizados;
- [x] escena reproducible con dos arquetipos, NPC protegido, duelo y dos permisos de máquina;
- [x] importación y smoke headless;
- [x] ausencia de barra moral o recompensa letal;
- [x] playtest humano del flujo completo con teclado/mouse y gamepad;
- [x] confirmar legibilidad de telegraph y surrender a velocidad real.

Playtest aprobado por el usuario el 2026-09-08. Phase 3 queda desbloqueada.
