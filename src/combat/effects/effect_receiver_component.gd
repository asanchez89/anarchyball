class_name EffectReceiverComponent
extends Node

signal effect_applied(permission: TargetPermission, amount: float)
signal effect_blocked(permission: TargetPermission)

enum TargetKind {
	BALL,
	MACHINE,
	PLAYER,
}

enum DamagePermission {
	HOSTILE_DEVICE,
	FREE_DESTRUCTIBLE,
	OWNED_NEUTRAL,
	DISPUTED_PROPERTY,
	SCRIPTED_TARGET,
}

@export var target_kind: TargetKind = TargetKind.BALL
@export var machine_permission: DamagePermission = DamagePermission.OWNED_NEUTRAL
@export var identity_path: NodePath
@export var conflict_state_path: NodePath
@export var resolve_path: NodePath
@export var health_path: NodePath
@export var duel_context_path: NodePath

var identity: CombatIdentityComponent
var conflict_state: ConflictStateComponent
var resolve: ResolveComponent
var health: HealthComponent
var duel_context: VoluntaryDuelContext
var last_permission: TargetPermission


func _ready() -> void:
	identity = get_node_or_null(identity_path) as CombatIdentityComponent
	conflict_state = get_node_or_null(conflict_state_path) as ConflictStateComponent
	resolve = get_node_or_null(resolve_path) as ResolveComponent
	health = get_node_or_null(health_path) as HealthComponent
	duel_context = get_node_or_null(duel_context_path) as VoluntaryDuelContext


func bind_for_test(
	target_identity: CombatIdentityComponent,
	target_conflict: ConflictStateComponent = null,
	target_resolve: ResolveComponent = null,
	target_duel: VoluntaryDuelContext = null
) -> void:
	identity = target_identity
	conflict_state = target_conflict
	resolve = target_resolve
	duel_context = target_duel


func receive_effect(
	source: CombatIdentityComponent,
	context: EffectContext,
	amount: float
) -> TargetPermission:
	last_permission = TargetValidity.evaluate(source, self, context)
	if not last_permission.allowed:
		effect_blocked.emit(last_permission)
		return last_permission
	if resolve != null:
		resolve.reduce(amount)
	elif health != null:
		health.damage(amount)
	effect_applied.emit(last_permission, amount)
	return last_permission
