extends GdUnitTestSuite


func test_surrendered_actor_cannot_reenter_combat_without_reset() -> void:
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	conflict.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	conflict.begin_surrender()

	assert_bool(conflict.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)).is_false()
	assert_int(conflict.current_state).is_equal(ConflictStateComponent.State.SURRENDERING)

	conflict.neutralize()
	assert_bool(conflict.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)).is_false()
	conflict.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	assert_bool(conflict.commit_aggression(ConflictStateComponent.AggressorReason.ENCOUNTER_SCRIPT)).is_true()


func test_resolve_reaching_threshold_requests_surrender_once() -> void:
	var resolve := auto_free(ResolveComponent.new()) as ResolveComponent
	resolve.maximum_resolve = 30.0
	resolve.surrender_threshold = 0.0
	resolve.reset()
	var emission_count: Array[int] = [0]
	resolve.surrender_threshold_reached.connect(func() -> void: emission_count[0] += 1)

	resolve.reduce(10.0)
	resolve.reduce(20.0)
	resolve.reduce(10.0)

	assert_float(resolve.current_resolve).is_equal(0.0)
	assert_int(emission_count[0]).is_equal(1)


func test_allowed_effect_reduces_resolve_and_blocked_effect_does_not() -> void:
	var source := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	source.stable_id = &"player"
	source.authority = CombatIdentityComponent.Authority.PLAYER
	var identity := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	identity.stable_id = &"opponent"
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	var resolve := auto_free(ResolveComponent.new()) as ResolveComponent
	resolve.maximum_resolve = 30.0
	resolve.reset()
	var receiver := auto_free(EffectReceiverComponent.new()) as EffectReceiverComponent
	receiver.bind_for_test(identity, conflict, resolve)

	var blocked := receiver.receive_effect(source, EffectContext.offensive(), 10.0)
	assert_bool(blocked.allowed).is_false()
	assert_float(resolve.current_resolve).is_equal(30.0)

	conflict.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	var applied := receiver.receive_effect(source, EffectContext.offensive(), 10.0)
	assert_bool(applied.allowed).is_true()
	assert_float(resolve.current_resolve).is_equal(20.0)
