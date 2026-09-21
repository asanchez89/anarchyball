class_name GameplayAudioProfile
extends Resource

@export var jump: AudioStream
@export var fire: AudioStream
@export var hurt: AudioStream
@export var impact_allowed: AudioStream
@export var impact_blocked: AudioStream
@export var threat: AudioStream
@export var aggression: AudioStream
@export var surrender: AudioStream
@export var pickup: AudioStream
@export var gate_open: AudioStream
@export var rule_interaction: AudioStream
@export var contract_state: AudioStream
@export var encounter_resolved: AudioStream
@export var checkpoint: AudioStream
@export var boss_phase: AudioStream
@export var completion_denied: AudioStream
@export var level_complete: AudioStream
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -10.0
@export_range(0.1, 4.0, 0.05) var pitch_scale: float = 1.0
@export var retrigger_cue_ids: Array[StringName] = [&"fire"]
@export var max_duration_seconds: Dictionary = {
	&"jump": 0.38,
	&"impact_allowed": 0.65,
	&"impact_blocked": 0.55,
	&"threat": 1.0,
	&"aggression": 0.8,
	&"pickup": 0.7,
	&"gate_open": 0.85,
	&"rule_interaction": 0.65,
	&"contract_state": 0.65,
	&"checkpoint": 0.8,
}


func stream_for(cue_id: StringName) -> AudioStream:
	match cue_id:
		&"jump": return jump
		&"fire": return fire
		&"hurt": return hurt
		&"impact_allowed": return impact_allowed
		&"impact_blocked": return impact_blocked
		&"threat": return threat
		&"aggression": return aggression
		&"surrender": return surrender
		&"pickup": return pickup
		&"gate_open": return gate_open
		&"rule_interaction": return rule_interaction
		&"contract_state": return contract_state
		&"encounter_resolved": return encounter_resolved
		&"checkpoint": return checkpoint
		&"boss_phase": return boss_phase
		&"completion_denied": return completion_denied
		&"level_complete": return level_complete
		_: return null


func has_cue(cue_id: StringName) -> bool:
	return stream_for(cue_id) != null


func should_retrigger(cue_id: StringName) -> bool:
	return cue_id in retrigger_cue_ids


func max_duration_for(cue_id: StringName) -> float:
	return float(max_duration_seconds.get(cue_id, 0.0))
