class_name CombatDamageNumber
extends Label

## Short-lived damage readout. This node is presentation-only and receives the
## already-resolved authoritative damage amount from CombatFeedback.

const LIGHT_COLOR: Color = Color(1.0, 0.91, 0.42, 1.0)
const HEAVY_COLOR: Color = Color(1.0, 0.42, 0.72, 1.0)

var _lifetime: float = 0.62
var _heavy: bool = false


func configure(damage: float, heavy: bool = false) -> void:
	_heavy = heavy
	text = "%d" % maxi(0, int(round(damage)))
	modulate = HEAVY_COLOR if heavy else LIGHT_COLOR
	if heavy:
		text = "! %s !" % text


func _ready() -> void:
	z_index = 45
	pivot_offset = size * 0.5
	scale = Vector2(1.15, 1.15) if _heavy else Vector2.ONE

	var destination: Vector2 = position + Vector2(0.0, -18.0 if _heavy else -14.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", destination, _lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, _lifetime * 0.72).set_delay(_lifetime * 0.28)
	if _heavy:
		tween.tween_property(self, "scale", Vector2(0.92, 0.92), _lifetime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
