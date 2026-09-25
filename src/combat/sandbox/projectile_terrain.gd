class_name ProjectileTerrain
extends RefCounted
## Shared terrain sweep for muzzle placement and flight, independent of faction.


static func obstruction(world: World2D, origin: Vector2, destination: Vector2) -> Dictionary:
	var ray := PhysicsRayQueryParameters2D.create(origin, destination, 1)
	ray.hit_from_inside = true
	while true:
		var hit := world.direct_space_state.intersect_ray(ray)
		if hit.is_empty():
			return {}
		var body := hit.collider as CollisionObject2D
		if body == null or not body.has_method("allows_projectile_passage") or not bool(body.call("allows_projectile_passage", origin, destination, hit.normal)):
			return hit
		# Keep looking: a permeable deck must not conceal a wall or gate behind it.
		var excluded: Array[RID] = ray.exclude
		excluded.append(body.get_rid())
		ray.exclude = excluded
	return {}
