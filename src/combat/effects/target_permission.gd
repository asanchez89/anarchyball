class_name TargetPermission
extends RefCounted

enum Decision {
	ALLOW_AGGRESSOR,
	ALLOW_DUEL,
	ALLOW_HOSTILE_MACHINE,
	ALLOW_SCRIPTED_TARGET,
	ALLOW_ENCOUNTER_EFFECT,
	BLOCK_NEUTRAL,
	BLOCK_DISPUTED,
	BLOCK_THREATENING,
	BLOCK_SURRENDERED,
	BLOCK_OWNED_NEUTRAL,
	BLOCK_DISPUTED_PROPERTY,
	BLOCK_INVALID_TARGET,
}

var allowed: bool
var decision: Decision


func _init(is_allowed: bool, result_decision: Decision) -> void:
	allowed = is_allowed
	decision = result_decision


func decision_name() -> String:
	return Decision.keys()[decision]


static func allow(result_decision: Decision) -> TargetPermission:
	return TargetPermission.new(true, result_decision)


static func block(result_decision: Decision) -> TargetPermission:
	return TargetPermission.new(false, result_decision)
