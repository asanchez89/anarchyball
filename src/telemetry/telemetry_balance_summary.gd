class_name TelemetryBalanceSummary
extends RefCounted


static func summarize(snapshot: Dictionary) -> Dictionary:
	var summary := {
		"duration_seconds": float(snapshot.get("elapsed_seconds", 0.0)),
		"playtest_profile": String(snapshot.get("playtest_profile", "unspecified")),
		"effective_route_screens": float(snapshot.get("effective_route_screens", 0.0)),
		"backtracking_screens": float(snapshot.get("backtracking_pixels", 0.0)) / LocalRunTelemetry.REFERENCE_VIEWPORT_WIDTH,
		"completed": false,
		"retries": 0,
		"defeats": 0,
		"damage_received": 0.0,
		"invalid_target_attempts": 0,
		"rule_state_changes": 0,
		"encounter_resolutions": [],
		"routes": [],
		"recommendations": [],
	}
	for event_value: Variant in snapshot.get("events", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		var event_name := String(event.get("event", ""))
		var payload := event.get("payload", {}) as Dictionary
		match event_name:
			"level_completed":
				summary["completed"] = true
			"retry":
				summary["retries"] = int(summary["retries"]) + 1
			"defeat":
				summary["defeats"] = int(summary["defeats"]) + 1
			"damage_received":
				summary["damage_received"] = float(summary["damage_received"]) + float(payload.get("amount", 0.0))
			"invalid_target_attempt":
				summary["invalid_target_attempts"] = int(summary["invalid_target_attempts"]) + 1
			"rule_state_changed":
				summary["rule_state_changes"] = int(summary["rule_state_changes"]) + 1
			"encounter_resolved":
				var resolution := String(payload.get("resolution", ""))
				if not resolution.is_empty() and resolution not in summary["encounter_resolutions"]:
					summary["encounter_resolutions"].append(resolution)
			"route_taken":
				for tag_value: Variant in payload.get("route_tags", []) as Array:
					var tag := String(tag_value)
					if tag not in summary["routes"]:
						summary["routes"].append(tag)
	_add_recommendations(summary)
	return summary


static func completion_line(snapshot: Dictionary) -> String:
	var summary := summarize(snapshot)
	var resolutions := summary["encounter_resolutions"] as Array
	var routes := summary["routes"] as Array
	return "Tiempo %.1f min · reintentos %d · intentos inválidos %d\nMáquinas %d · resoluciones %s · rutas %s\nPerfil %s · recorrido %.1f pantallas · retroceso %.1f" % [
		float(summary["duration_seconds"]) / 60.0,
		int(summary["retries"]),
		int(summary["invalid_target_attempts"]),
		int(summary["rule_state_changes"]),
		", ".join(resolutions) if not resolutions.is_empty() else "ninguna",
		", ".join(routes) if not routes.is_empty() else "base",
		String(summary["playtest_profile"]),
		float(summary["effective_route_screens"]),
		float(summary["backtracking_screens"]),
	]


static func _add_recommendations(summary: Dictionary) -> void:
	var recommendations := summary["recommendations"] as Array
	if int(summary["invalid_target_attempts"]) >= 3:
		recommendations.append("Revisar legibilidad de target validity antes de aumentar dificultad.")
	if int(summary["retries"]) >= 4:
		recommendations.append("Revisar daño, checkpoint y picos de dificultad.")
	if bool(summary["completed"]):
		var minutes := float(summary["duration_seconds"]) / 60.0
		if minutes < 5.0:
			recommendations.append("El slice termina por debajo del rango; revisar pacing.")
		elif minutes > 12.0:
			recommendations.append("El slice supera el rango; revisar fricción y claridad.")
