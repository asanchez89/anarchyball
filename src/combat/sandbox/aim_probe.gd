class_name AimProbe
extends Area2D

@export_range(1.0, 3000.0, 1.0) var speed: float = 760.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 2.0
@export_range(0.0, 1000.0, 1.0) var effect_amount: float = 10.0

var direction: Vector2 = Vector2.RIGHT
var source_identity: CombatIdentityComponent
var effect_context: EffectContext


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
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


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("76e6ff"))
	draw_line(Vector2(-16.0, 0.0), Vector2(-5.0, 0.0), Color("76e6ff80"), 4.0, true)


func _on_area_entered(area: Area2D) -> void:
	var receiver := area.get_node_or_null("EffectReceiver") as EffectReceiverComponent
	if receiver != null and source_identity != null and effect_context != null:
		receiver.receive_effect(source_identity, effect_context, effect_amount)
		queue_free()
		return
	if area.has_method("register_probe_hit"):
		area.call("register_probe_hit")
		queue_free()
