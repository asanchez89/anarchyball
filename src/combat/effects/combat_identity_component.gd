class_name CombatIdentityComponent
extends Node

enum Authority {
	PLAYER,
	NPC,
	MACHINE,
}

@export var stable_id: StringName = &"unknown_actor"
@export var authority: Authority = Authority.NPC
