class_name AttackPositionRegistry
extends Node

## Stable, deterministic reservations around a target. Slots are limited and
## unique, preventing combatants from converging on one exact position.

const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)

var _target_slots: Dictionary = {}
var _attacker_reservations: Dictionary = {}
var _slot_x_offsets: Array[float] = [-28.0, 28.0, -28.0, 28.0, -28.0, 28.0]
var _combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE


func configure(combat_space: CombatSpaceDefinition) -> void:
	_combat_space = combat_space if combat_space != null else DEFAULT_COMBAT_SPACE


func reserve(attacker: ActorController, target: ActorController, maximum_distance: float) -> bool:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return false
	_cleanup_invalid()
	var attacker_id: int = attacker.get_instance_id()
	var target_id: int = target.get_instance_id()
	if _attacker_reservations.has(attacker_id):
		var current: Dictionary = _attacker_reservations[attacker_id]
		if int(current.get("target_id", -1)) == target_id:
			return true
		release_attacker(attacker)

	var slots: Dictionary = _target_slots.get(target_id, {})
	var best_slot: int = -1
	var best_distance_squared: float = INF
	for slot_index: int in range(_slot_x_offsets.size()):
		if slots.has(slot_index):
			continue
		var slot_position: Vector2 = _slot_world_position(attacker, target, slot_index)
		if target.global_position.distance_to(slot_position) > maximum_distance:
			continue
		var distance_squared: float = attacker.global_position.distance_squared_to(slot_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_slot = slot_index
	if best_slot < 0:
		return false

	slots[best_slot] = attacker_id
	_target_slots[target_id] = slots
	_attacker_reservations[attacker_id] = {
		"target_id": target_id,
		"slot_index": best_slot,
		"attacker": weakref(attacker),
		"target": weakref(target),
	}
	return true


func has_reservation(attacker: ActorController, target: ActorController = null) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	_cleanup_invalid()
	var record: Dictionary = _attacker_reservations.get(attacker.get_instance_id(), {})
	if record.is_empty():
		return false
	return target == null or int(record.get("target_id", -1)) == target.get_instance_id()


func get_world_position(attacker: ActorController) -> Vector2:
	if attacker == null or not is_instance_valid(attacker):
		return Vector2.INF
	_cleanup_invalid()
	var record: Dictionary = _attacker_reservations.get(attacker.get_instance_id(), {})
	if record.is_empty():
		return Vector2.INF
	var target_ref: WeakRef = record.get("target") as WeakRef
	var attacker_ref: WeakRef = record.get("attacker") as WeakRef
	if target_ref == null or attacker_ref == null:
		return Vector2.INF
	var target: ActorController = target_ref.get_ref() as ActorController
	var reserved_attacker: ActorController = attacker_ref.get_ref() as ActorController
	if (
		target == null
		or reserved_attacker == null
		or not is_instance_valid(target)
		or not is_instance_valid(reserved_attacker)
	):
		return Vector2.INF
	var slot_index: int = int(record.get("slot_index", -1))
	if slot_index < 0 or slot_index >= _slot_x_offsets.size():
		return Vector2.INF
	return _slot_world_position(reserved_attacker, target, slot_index)


func _slot_world_position(
	attacker: ActorController,
	target: ActorController,
	slot_index: int
) -> Vector2:
	# Both teams can use all six stable slots. This preserves the original
	# middle-lane preference through nearest-distance selection while allowing
	# all three permanent crew members to engage one elite or boss.
	var slot_lane: int = int(floor(float(slot_index) / 2.0))
	return _combat_space.clamp_actor_position(
		Vector2(
			target.global_position.x + _slot_x_offsets[slot_index],
			_combat_space.lane_y(slot_lane)
		)
	)


func release_attacker(attacker: ActorController) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	_release_attacker_id(attacker.get_instance_id())


func release_target(target: ActorController) -> void:
	if target == null or not is_instance_valid(target):
		return
	var target_id: int = target.get_instance_id()
	var slots: Dictionary = _target_slots.get(target_id, {})
	var attacker_ids: Array = slots.values().duplicate()
	for attacker_id: Variant in attacker_ids:
		_attacker_reservations.erase(int(attacker_id))
	_target_slots.erase(target_id)


func release_actor(actor: ActorController) -> void:
	release_attacker(actor)
	release_target(actor)


func clear_all() -> void:
	_target_slots.clear()
	_attacker_reservations.clear()


func get_snapshot() -> Array[Dictionary]:
	_cleanup_invalid()
	var result: Array[Dictionary] = []
	var attacker_ids: Array = _attacker_reservations.keys()
	attacker_ids.sort()
	for attacker_id: Variant in attacker_ids:
		var record: Dictionary = _attacker_reservations[int(attacker_id)]
		result.append({
			"attacker_instance_id": int(attacker_id),
			"target_instance_id": int(record.get("target_id", -1)),
			"slot_index": int(record.get("slot_index", -1)),
		})
	return result


func _release_attacker_id(attacker_id: int) -> void:
	var record: Dictionary = _attacker_reservations.get(attacker_id, {})
	if record.is_empty():
		return
	var target_id: int = int(record.get("target_id", -1))
	var slot_index: int = int(record.get("slot_index", -1))
	var slots: Dictionary = _target_slots.get(target_id, {})
	slots.erase(slot_index)
	if slots.is_empty():
		_target_slots.erase(target_id)
	else:
		_target_slots[target_id] = slots
	_attacker_reservations.erase(attacker_id)


func _cleanup_invalid() -> void:
	var attacker_ids: Array = _attacker_reservations.keys().duplicate()
	for attacker_id: Variant in attacker_ids:
		var record: Dictionary = _attacker_reservations[int(attacker_id)]
		var attacker_ref: WeakRef = record.get("attacker") as WeakRef
		var target_ref: WeakRef = record.get("target") as WeakRef
		if (
			attacker_ref == null
			or target_ref == null
			or not is_instance_valid(attacker_ref.get_ref())
			or not is_instance_valid(target_ref.get_ref())
		):
			_release_attacker_id(int(attacker_id))
