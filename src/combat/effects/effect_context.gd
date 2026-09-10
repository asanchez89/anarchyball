class_name EffectContext
extends RefCounted

enum EffectType {
	KINETIC_DAMAGE,
	STUN,
	KNOCKBACK,
	DISARM,
	EMP,
	HACK,
	SLOW,
	SHIELD_BREAK,
}

enum Origin {
	DIRECT,
	PROJECTILE,
	INDIRECT,
}

var effect_type: EffectType = EffectType.KINETIC_DAMAGE
var origin: Origin = Origin.DIRECT
var requires_target_validity: bool = true
var voluntary_duel_id: StringName = &""


static func offensive(
	type: EffectType = EffectType.KINETIC_DAMAGE,
	source_origin: Origin = Origin.DIRECT,
	duel_id: StringName = &""
) -> EffectContext:
	var context := EffectContext.new()
	context.effect_type = type
	context.origin = source_origin
	context.requires_target_validity = true
	context.voluntary_duel_id = duel_id
	return context


static func encounter_effect(
	type: EffectType = EffectType.KINETIC_DAMAGE,
	source_origin: Origin = Origin.PROJECTILE
) -> EffectContext:
	var context := EffectContext.new()
	context.effect_type = type
	context.origin = source_origin
	context.requires_target_validity = false
	return context
