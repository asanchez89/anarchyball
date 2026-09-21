class_name AimProbe
extends Area2D

@export_range(1.0, 3000.0, 1.0) var speed: float = 760.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 2.0
@export_range(0.0, 1000.0, 1.0) var effect_amount: float = 10.0

@onready var missile_sprite: Sprite2D = $MissileSprite

var direction: Vector2 = Vector2.RIGHT
var source_identity: CombatIdentityComponent
var effect_context: EffectContext
var _animation_elapsed: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_animation_elapsed += delta
	missile_sprite.frame = int(_animation_elapsed * 12.0) % missile_sprite.hframes
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func configure(
	new_direction: Vector2,
	new_source_identity: CombatIdentityComponent = null,
	new_effect_context: EffectContext = null
) -> void:
	direction = new_direction.normalized() if not new_direction.is_zero_approx() else Vector2.RIGHT
	rotation = direction.angle()
	source_identity = new_source_identity
	effect_context = new_effect_context


func _on_area_entered(area: Area2D) -> void:
	var receiver := area.get_node_or_null("EffectReceiver") as EffectReceiverComponent
	if receiver != null and source_identity != null and effect_context != null:
		receiver.receive_effect(source_identity, effect_context, effect_amount)
		queue_free()
		return
	if area.has_method("register_probe_hit"):
		area.call("register_probe_hit")
		queue_free()
