class_name TargetValidity
extends RefCounted


static func evaluate(
	source: CombatIdentityComponent,
	target: EffectReceiverComponent,
	context: EffectContext
) -> TargetPermission:
	if source == null or target == null or target.identity == null or context == null:
		return TargetPermission.block(TargetPermission.Decision.BLOCK_INVALID_TARGET)
	if not context.requires_target_validity and source.authority != CombatIdentityComponent.Authority.PLAYER:
		return TargetPermission.allow(TargetPermission.Decision.ALLOW_ENCOUNTER_EFFECT)
	if source.authority != CombatIdentityComponent.Authority.PLAYER or not context.requires_target_validity:
		return TargetPermission.block(TargetPermission.Decision.BLOCK_INVALID_TARGET)

	if target.target_kind == EffectReceiverComponent.TargetKind.MACHINE:
		return _evaluate_machine(target.machine_permission)
	if target.target_kind == EffectReceiverComponent.TargetKind.PLAYER:
		return TargetPermission.block(TargetPermission.Decision.BLOCK_INVALID_TARGET)

	if target.duel_context != null and target.duel_context.permits(
		source.stable_id,
		target.identity.stable_id,
		context.voluntary_duel_id
	):
		return TargetPermission.allow(TargetPermission.Decision.ALLOW_DUEL)
	if target.conflict_state == null:
		return TargetPermission.block(TargetPermission.Decision.BLOCK_INVALID_TARGET)

	match target.conflict_state.current_state:
		ConflictStateComponent.State.AGGRESSOR:
			return TargetPermission.allow(TargetPermission.Decision.ALLOW_AGGRESSOR)
		ConflictStateComponent.State.DISPUTED:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_DISPUTED)
		ConflictStateComponent.State.THREATENING:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_THREATENING)
		ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_SURRENDERED)
		_:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_NEUTRAL)


static func _evaluate_machine(permission: EffectReceiverComponent.DamagePermission) -> TargetPermission:
	match permission:
		EffectReceiverComponent.DamagePermission.HOSTILE_DEVICE, EffectReceiverComponent.DamagePermission.FREE_DESTRUCTIBLE:
			return TargetPermission.allow(TargetPermission.Decision.ALLOW_HOSTILE_MACHINE)
		EffectReceiverComponent.DamagePermission.SCRIPTED_TARGET:
			return TargetPermission.allow(TargetPermission.Decision.ALLOW_SCRIPTED_TARGET)
		EffectReceiverComponent.DamagePermission.DISPUTED_PROPERTY:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_DISPUTED_PROPERTY)
		_:
			return TargetPermission.block(TargetPermission.Decision.BLOCK_OWNED_NEUTRAL)
