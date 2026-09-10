extends GdUnitTestSuite

var _player_source: CombatIdentityComponent


func before_test() -> void:
	_player_source = auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	_player_source.stable_id = &"player"
	_player_source.authority = CombatIdentityComponent.Authority.PLAYER


func test_neutral_cannot_receive_offensive_damage() -> void:
	_assert_ball_decision(
		ConflictStateComponent.State.NEUTRAL,
		false,
		TargetPermission.Decision.BLOCK_NEUTRAL
	)


func test_disputed_cannot_receive_offensive_damage() -> void:
	_assert_ball_decision(
		ConflictStateComponent.State.DISPUTED,
		false,
		TargetPermission.Decision.BLOCK_DISPUTED
	)


func test_threatening_cannot_receive_damage_before_commitment() -> void:
	_assert_ball_decision(
		ConflictStateComponent.State.THREATENING,
		false,
		TargetPermission.Decision.BLOCK_THREATENING
	)


func test_aggressor_can_receive_offensive_damage() -> void:
	_assert_ball_decision(
		ConflictStateComponent.State.AGGRESSOR,
		true,
		TargetPermission.Decision.ALLOW_AGGRESSOR
	)


func test_aggression_against_third_party_makes_attacker_valid() -> void:
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(ConflictStateComponent.State.THREATENING)
	assert_bool(conflict.commit_aggression(
		ConflictStateComponent.AggressorReason.THIRD_PARTY_AGGRESSION,
		&"protected_merchant"
	)).is_true()
	var receiver := _ball_receiver(&"confiscator", conflict)
	var permission := TargetValidity.evaluate(_player_source, receiver, EffectContext.offensive())

	assert_bool(permission.allowed).is_true()
	assert_int(conflict.aggressor_reason).is_equal(ConflictStateComponent.AggressorReason.THIRD_PARTY_AGGRESSION)
	assert_str(String(conflict.protected_target_id)).is_equal("protected_merchant")


func test_surrendering_immediately_blocks_further_damage() -> void:
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	conflict.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	assert_bool(conflict.begin_surrender()).is_true()
	var receiver := _ball_receiver(&"surrendering_actor", conflict)
	var permission := TargetValidity.evaluate(_player_source, receiver, EffectContext.offensive())

	assert_bool(permission.allowed).is_false()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.BLOCK_SURRENDERED)


func test_voluntary_duel_participants_can_damage_each_other() -> void:
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	var duel := auto_free(VoluntaryDuelContext.new()) as VoluntaryDuelContext
	duel.duel_id = &"training_duel"
	duel.participant_ids = [&"player", &"duelist"]
	duel.active = true
	var receiver := _ball_receiver(&"duelist", conflict, duel)
	var context := EffectContext.offensive(
		EffectContext.EffectType.KINETIC_DAMAGE,
		EffectContext.Origin.DIRECT,
		&"training_duel"
	)
	var permission := TargetValidity.evaluate(_player_source, receiver, context)

	assert_bool(permission.allowed).is_true()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.ALLOW_DUEL)


func test_indirect_player_attacks_obey_same_target_validity() -> void:
	var receiver := _ball_receiver(&"neutral_for_drone", _conflict(ConflictStateComponent.State.NEUTRAL))
	for origin: EffectContext.Origin in [EffectContext.Origin.DIRECT, EffectContext.Origin.PROJECTILE, EffectContext.Origin.INDIRECT]:
		var context := EffectContext.offensive(EffectContext.EffectType.KINETIC_DAMAGE, origin)
		var permission := TargetValidity.evaluate(_player_source, receiver, context)
		assert_bool(permission.allowed).is_false()
		assert_int(permission.decision).is_equal(TargetPermission.Decision.BLOCK_NEUTRAL)


func test_hostile_machine_can_be_damaged() -> void:
	var receiver := _machine_receiver(EffectReceiverComponent.DamagePermission.HOSTILE_DEVICE)
	var permission := TargetValidity.evaluate(_player_source, receiver, EffectContext.offensive())
	assert_bool(permission.allowed).is_true()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.ALLOW_HOSTILE_MACHINE)


func test_owned_neutral_machine_cannot_be_casually_destroyed() -> void:
	var receiver := _machine_receiver(EffectReceiverComponent.DamagePermission.OWNED_NEUTRAL)
	var permission := TargetValidity.evaluate(_player_source, receiver, EffectContext.offensive())
	assert_bool(permission.allowed).is_false()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.BLOCK_OWNED_NEUTRAL)


func test_player_cannot_mark_its_own_attack_as_encounter_effect_to_bypass_rules() -> void:
	var receiver := _ball_receiver(&"neutral_bypass_target", _conflict(ConflictStateComponent.State.NEUTRAL))
	var permission := TargetValidity.evaluate(
		_player_source,
		receiver,
		EffectContext.encounter_effect()
	)
	assert_bool(permission.allowed).is_false()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.BLOCK_INVALID_TARGET)


func _assert_ball_decision(
	state: ConflictStateComponent.State,
	expected_allowed: bool,
	expected_decision: TargetPermission.Decision
) -> void:
	var receiver := _ball_receiver(&"test_ball", _conflict(state))
	var permission := TargetValidity.evaluate(_player_source, receiver, EffectContext.offensive())
	assert_bool(permission.allowed).is_equal(expected_allowed)
	assert_int(permission.decision).is_equal(expected_decision)


func _conflict(state: ConflictStateComponent.State) -> ConflictStateComponent:
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(state)
	return conflict


func _ball_receiver(
	id: StringName,
	conflict: ConflictStateComponent,
	duel: VoluntaryDuelContext = null
) -> EffectReceiverComponent:
	var identity := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	identity.stable_id = id
	var receiver := auto_free(EffectReceiverComponent.new()) as EffectReceiverComponent
	receiver.target_kind = EffectReceiverComponent.TargetKind.BALL
	receiver.bind_for_test(identity, conflict, null, duel)
	return receiver


func _machine_receiver(permission: EffectReceiverComponent.DamagePermission) -> EffectReceiverComponent:
	var identity := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	identity.stable_id = &"test_machine"
	identity.authority = CombatIdentityComponent.Authority.MACHINE
	var receiver := auto_free(EffectReceiverComponent.new()) as EffectReceiverComponent
	receiver.target_kind = EffectReceiverComponent.TargetKind.MACHINE
	receiver.machine_permission = permission
	receiver.bind_for_test(identity)
	return receiver
