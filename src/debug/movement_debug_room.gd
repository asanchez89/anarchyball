class_name MovementDebugRoom
extends Node2D

@export var spawn_position: Vector2 = Vector2(120.0, 570.0)
@export var fall_reset_height: float = 840.0

@onready var player: PlayerController = %Player


func _ready() -> void:
	player.reset_at(spawn_position)
	(player.get_node("Health") as HealthComponent).depleted.connect(_on_player_depleted)


func _process(_delta: float) -> void:
	if player.global_position.y > fall_reset_height:
		_reset_player()
	if InputActions.is_ability_1_just_pressed():
		player.add_camera_shake(8.0)


func _on_player_depleted() -> void:
	_reset_player()


func _reset_player() -> void:
	player.reset_at(spawn_position)
	(player.get_node("Health") as HealthComponent).reset()
