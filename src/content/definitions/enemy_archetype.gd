class_name EnemyArchetype
extends ContentDefinition

@export_file("*.tscn") var actor_scene_path: String = ""
@export_range(1.0, 1000.0, 1.0) var maximum_resolve: float = 30.0
@export var behavior_id: StringName = &"static"
@export var initial_conflict_state: ConflictStateComponent.State = ConflictStateComponent.State.NEUTRAL
@export var aggressor_reason: ConflictStateComponent.AggressorReason = ConflictStateComponent.AggressorReason.NONE
@export_multiline var threat_text: String = ""
@export var target_kind: EffectReceiverComponent.TargetKind = EffectReceiverComponent.TargetKind.BALL
@export var machine_permission: EffectReceiverComponent.DamagePermission = EffectReceiverComponent.DamagePermission.OWNED_NEUTRAL
@export var is_boss: bool = false
@export_range(0.1, 0.9, 0.05) var phase_two_ratio: float = 0.5
@export_range(0.2, 5.0, 0.1) var attack_interval: float = 1.2
@export_range(50.0, 2000.0, 10.0) var activation_distance: float = 520.0
@export_range(0.1, 10.0, 0.1) var telegraph_delay: float = 1.5
@export_range(0.0, 3.0, 0.05) var commitment_impact_delay: float = 0.35


func is_structurally_valid() -> bool:
	return (
		has_valid_identity()
		and not actor_scene_path.is_empty()
		and maximum_resolve > 0.0
		and not behavior_id.is_empty()
		and (behavior_id == &"static" or aggressor_reason != ConflictStateComponent.AggressorReason.NONE)
		and attack_interval > 0.0
		and activation_distance > 0.0
		and telegraph_delay > 0.0
		and commitment_impact_delay >= 0.0
	)
