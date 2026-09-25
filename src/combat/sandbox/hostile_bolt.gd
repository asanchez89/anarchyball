class_name HostileBolt
extends Area2D

@export_range(1.0, 3000.0, 1.0) var speed: float = 360.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 4.0
@export_range(0.0, 1000.0, 1.0) var damage_amount: float = 10.0

var direction: Vector2 = Vector2.LEFT
var source_identity: CombatIdentityComponent
var _animation_elapsed: float = 0.0

@onready var missile_sprite: Sprite2D = $MissileSprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var destination := global_position + direction * speed * delta
	if not ProjectileTerrain.obstruction(get_world_2d(), global_position, destination).is_empty():
		queue_free()
		return
	global_position = destination
	_animation_elapsed += delta
	missile_sprite.frame = int(_animation_elapsed * 12.0) % missile_sprite.hframes
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func configure(new_direction: Vector2, source: CombatIdentityComponent) -> void:
	direction = new_direction.normalized() if not new_direction.is_zero_approx() else Vector2.LEFT
	source_identity = source
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	var receiver := body.get_node_or_null("EffectReceiver") as EffectReceiverComponent
	if receiver == null or source_identity == null:
		return
	receiver.receive_effect(
		source_identity,
		EffectContext.encounter_effect(EffectContext.EffectType.KINETIC_DAMAGE),
		damage_amount
	)
	queue_free()
