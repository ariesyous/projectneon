class_name SynergySystem
extends Node

## Run-scoped authority for three active equipment slots, three ordered
## backpack slots, deterministic build aggregation, and non-mutating previews.

signal equipment_changed(
	slot_index: int,
	previous_item: EquipmentDefinition,
	current_item: EquipmentDefinition
)
signal backpack_changed(
	slot_index: int,
	previous_item: EquipmentDefinition,
	current_item: EquipmentDefinition
)
signal build_changed(snapshot: Dictionary)
signal synergy_activated(synergy: SynergyDefinition)
signal synergy_deactivated(synergy: SynergyDefinition)
signal modifiers_changed(flat_modifiers: Dictionary, percent_modifiers: Dictionary)
signal tags_changed(tag_counts: Dictionary)

const RESPONSIBILITY: String = "Own active equipment, backpack storage, synergies, and derived build modifiers."
const SLOT_COUNT: int = 3
const BACKPACK_SLOT_COUNT: int = 3
const AREA_EQUIPPED: StringName = &"equipped"
const AREA_BACKPACK: StringName = &"backpack"
const DEFAULT_EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const DEFAULT_SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)

@export var equipment_catalogue: EquipmentCatalogue = DEFAULT_EQUIPMENT_CATALOGUE
@export var synergy_catalogue: SynergyCatalogue = DEFAULT_SYNERGY_CATALOGUE

var _slots: Array[EquipmentDefinition] = []
var _backpack: Array[EquipmentDefinition] = []
var _equipment_by_id: Dictionary[StringName, EquipmentDefinition] = {}
var _active_synergy_by_id: Dictionary[StringName, SynergyDefinition] = {}
var _tag_counts: Dictionary[StringName, int] = {}
var _flat_modifiers: Dictionary[StringName, float] = {}
var _percent_modifiers: Dictionary[StringName, float] = {}
var _triggered_effects: Array[TriggeredEffectDefinition] = []
var _inventory_revision: int = 0


func _init() -> void:
	_slots.resize(SLOT_COUNT)
	_backpack.resize(BACKPACK_SLOT_COUNT)


func _ready() -> void:
	_rebuild_catalogue_index()
	_validate_catalogues()
	_recalculate_build()


func configure(
	new_equipment_catalogue: EquipmentCatalogue,
	new_synergy_catalogue: SynergyCatalogue
) -> void:
	equipment_catalogue = (
		new_equipment_catalogue
		if new_equipment_catalogue != null
		else DEFAULT_EQUIPMENT_CATALOGUE
	)
	synergy_catalogue = (
		new_synergy_catalogue
		if new_synergy_catalogue != null
		else DEFAULT_SYNERGY_CATALOGUE
	)
	_rebuild_catalogue_index()
	_validate_catalogues()
	reset_for_run()


func reset_for_run() -> void:
	var previous_slots: Array[EquipmentDefinition] = _slots.duplicate()
	var previous_backpack: Array[EquipmentDefinition] = _backpack.duplicate()
	_slots.clear()
	_slots.resize(SLOT_COUNT)
	_backpack.clear()
	_backpack.resize(BACKPACK_SLOT_COUNT)
	_inventory_revision += 1
	_recalculate_build()
	for slot_index: int in range(SLOT_COUNT):
		if previous_slots[slot_index] != null:
			equipment_changed.emit(slot_index, previous_slots[slot_index], null)
	for slot_index: int in range(BACKPACK_SLOT_COUNT):
		if previous_backpack[slot_index] != null:
			backpack_changed.emit(slot_index, previous_backpack[slot_index], null)


func equip(item: EquipmentDefinition, slot_index: int = -1) -> bool:
	if not is_catalogue_item(item) or owns_equipment(item.id):
		return false
	var target_slot: int = slot_index
	if target_slot < 0:
		target_slot = first_empty_slot()
	if (
		target_slot < 0
		or target_slot >= SLOT_COUNT
		or _slots[target_slot] != null
	):
		return false
	_slots[target_slot] = item
	_inventory_revision += 1
	_recalculate_build()
	equipment_changed.emit(target_slot, null, item)
	return true


func equip_by_id(equipment_id: StringName, slot_index: int = -1) -> bool:
	return equip(get_catalogue_item(equipment_id), slot_index)


func remove(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT or _slots[slot_index] == null:
		return false
	var previous_item: EquipmentDefinition = _slots[slot_index]
	_slots[slot_index] = null
	_inventory_revision += 1
	_recalculate_build()
	equipment_changed.emit(slot_index, previous_item, null)
	return true


## Stores a newly acquired catalogue item. Occupied storage can only be
## replaced when the caller explicitly confirms that exact destination.
func store(
	item: EquipmentDefinition,
	backpack_slot: int = -1,
	replace_confirmed: bool = false,
	expected_revision: int = -1
) -> bool:
	if not _can_acquire(item, expected_revision):
		return false
	var target_slot: int = backpack_slot
	if target_slot < 0:
		target_slot = first_empty_backpack_slot()
	if target_slot < 0 or target_slot >= BACKPACK_SLOT_COUNT:
		return false
	var previous_item: EquipmentDefinition = _backpack[target_slot]
	if previous_item != null and not replace_confirmed:
		return false
	_backpack[target_slot] = item
	_inventory_revision += 1
	backpack_changed.emit(target_slot, previous_item, item)
	build_changed.emit(get_snapshot())
	return true


## Equips a newly acquired item without silently destroying the outgoing item.
## An occupied active slot moves to backpack storage. Replacing an occupied
## backpack destination requires explicit confirmation from presentation.
func acquire_equipped(
	item: EquipmentDefinition,
	equipment_slot: int = -1,
	outgoing_backpack_slot: int = -1,
	replace_backpack_confirmed: bool = false,
	expected_revision: int = -1
) -> bool:
	if not _can_acquire(item, expected_revision):
		return false
	var target_slot: int = equipment_slot
	if target_slot < 0:
		target_slot = first_empty_slot()
	if target_slot < 0 or target_slot >= SLOT_COUNT:
		return false

	var previous_equipped: EquipmentDefinition = _slots[target_slot]
	var target_backpack_slot: int = outgoing_backpack_slot
	var previous_backpack: EquipmentDefinition = null
	if previous_equipped != null:
		if target_backpack_slot < 0:
			target_backpack_slot = first_empty_backpack_slot()
		if target_backpack_slot < 0 or target_backpack_slot >= BACKPACK_SLOT_COUNT:
			return false
		previous_backpack = _backpack[target_backpack_slot]
		if previous_backpack != null and not replace_backpack_confirmed:
			return false

	_slots[target_slot] = item
	if previous_equipped != null:
		_backpack[target_backpack_slot] = previous_equipped
	_inventory_revision += 1
	_recalculate_build()
	equipment_changed.emit(target_slot, previous_equipped, item)
	if previous_equipped != null:
		backpack_changed.emit(target_backpack_slot, previous_backpack, previous_equipped)
	return true


## Atomically equips a stored item and places the former active item into the
## selected backpack slot. Nothing is destroyed by this operation.
func swap_equipped_with_backpack(
	equipment_slot: int,
	backpack_slot: int,
	expected_revision: int = -1
) -> bool:
	if (
		not _revision_matches(expected_revision)
		or equipment_slot < 0
		or equipment_slot >= SLOT_COUNT
		or backpack_slot < 0
		or backpack_slot >= BACKPACK_SLOT_COUNT
		or _backpack[backpack_slot] == null
	):
		return false
	var previous_equipped: EquipmentDefinition = _slots[equipment_slot]
	var previous_backpack: EquipmentDefinition = _backpack[backpack_slot]
	_slots[equipment_slot] = previous_backpack
	_backpack[backpack_slot] = previous_equipped
	_inventory_revision += 1
	_recalculate_build()
	equipment_changed.emit(equipment_slot, previous_equipped, previous_backpack)
	backpack_changed.emit(backpack_slot, previous_backpack, previous_equipped)
	return true


## Moves an active item to storage. An occupied storage destination is only
## replaced after a named confirmation in the UI.
func move_equipped_to_backpack(
	equipment_slot: int,
	backpack_slot: int = -1,
	replace_confirmed: bool = false,
	expected_revision: int = -1
) -> bool:
	if (
		not _revision_matches(expected_revision)
		or equipment_slot < 0
		or equipment_slot >= SLOT_COUNT
		or _slots[equipment_slot] == null
	):
		return false
	var target_slot: int = backpack_slot
	if target_slot < 0:
		target_slot = first_empty_backpack_slot()
	if target_slot < 0 or target_slot >= BACKPACK_SLOT_COUNT:
		return false
	var previous_backpack: EquipmentDefinition = _backpack[target_slot]
	if previous_backpack != null and not replace_confirmed:
		return false
	var previous_equipped: EquipmentDefinition = _slots[equipment_slot]
	_slots[equipment_slot] = null
	_backpack[target_slot] = previous_equipped
	_inventory_revision += 1
	_recalculate_build()
	equipment_changed.emit(equipment_slot, previous_equipped, null)
	backpack_changed.emit(target_slot, previous_backpack, previous_equipped)
	return true


## Destructive removal is deliberately separate from ordinary selection and
## requires the expected stable ID plus the current inventory revision.
func discard_confirmed(
	area: StringName,
	slot_index: int,
	expected_item_id: StringName,
	expected_revision: int
) -> bool:
	if expected_item_id == &"" or not _revision_matches(expected_revision):
		return false
	if area == AREA_EQUIPPED:
		var equipped: EquipmentDefinition = get_equipped_item(slot_index)
		if equipped == null or equipped.id != expected_item_id:
			return false
		_slots[slot_index] = null
		_inventory_revision += 1
		_recalculate_build()
		equipment_changed.emit(slot_index, equipped, null)
		return true
	if area == AREA_BACKPACK:
		var stored: EquipmentDefinition = get_backpack_item(slot_index)
		if stored == null or stored.id != expected_item_id:
			return false
		_backpack[slot_index] = null
		_inventory_revision += 1
		backpack_changed.emit(slot_index, stored, null)
		build_changed.emit(get_snapshot())
		return true
	return false


func is_catalogue_item(item: EquipmentDefinition) -> bool:
	return (
		item != null
		and item.id != &""
		and _equipment_by_id.get(item.id) == item
		and item.validation_errors().is_empty()
	)


func get_catalogue_item(equipment_id: StringName) -> EquipmentDefinition:
	return _equipment_by_id.get(equipment_id) as EquipmentDefinition


func get_sorted_catalogue() -> Array[EquipmentDefinition]:
	return equipment_catalogue.get_sorted_items() if equipment_catalogue != null else []


func has_equipment(equipment_id: StringName) -> bool:
	for item: EquipmentDefinition in _slots:
		if item != null and item.id == equipment_id:
			return true
	return false


func owns_equipment(equipment_id: StringName) -> bool:
	if has_equipment(equipment_id):
		return true
	for item: EquipmentDefinition in _backpack:
		if item != null and item.id == equipment_id:
			return true
	return false


func first_empty_slot() -> int:
	for slot_index: int in range(SLOT_COUNT):
		if _slots[slot_index] == null:
			return slot_index
	return -1


func first_empty_backpack_slot() -> int:
	for slot_index: int in range(BACKPACK_SLOT_COUNT):
		if _backpack[slot_index] == null:
			return slot_index
	return -1


func get_equipped_item(slot_index: int) -> EquipmentDefinition:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return null
	return _slots[slot_index]


func get_backpack_item(slot_index: int) -> EquipmentDefinition:
	if slot_index < 0 or slot_index >= BACKPACK_SLOT_COUNT:
		return null
	return _backpack[slot_index]


func get_backpack_items() -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = []
	for item: EquipmentDefinition in _backpack:
		if item != null:
			result.append(item)
	return result


func get_owned_items_stable() -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = get_equipped_items()
	result.append_array(get_backpack_items())
	result.sort_custom(_equipment_before)
	return result


func get_inventory_revision() -> int:
	return _inventory_revision


func get_equipped_items() -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = []
	for item: EquipmentDefinition in _slots:
		if item != null:
			result.append(item)
	return result


func get_equipped_items_stable() -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = get_equipped_items()
	result.sort_custom(_equipment_before)
	return result


func get_tag_count(tag: StringName) -> int:
	return _tag_counts.get(tag, 0)


func get_tag_counts() -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for tag: StringName in _tag_counts:
		result[tag] = _tag_counts[tag]
	return result


func get_flat_modifier(stat_id: StringName) -> float:
	return _flat_modifiers.get(stat_id, 0.0)


func get_percent_modifier(stat_id: StringName) -> float:
	return _percent_modifiers.get(stat_id, 0.0)


func get_flat_modifiers() -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for stat_id: StringName in _flat_modifiers:
		result[stat_id] = _flat_modifiers[stat_id]
	return result


func get_percent_modifiers() -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for stat_id: StringName in _percent_modifiers:
		result[stat_id] = _percent_modifiers[stat_id]
	return result


func get_triggered_effects() -> Array[TriggeredEffectDefinition]:
	return _triggered_effects.duplicate()


func is_synergy_active(synergy_id: StringName) -> bool:
	return _active_synergy_by_id.has(synergy_id)


func get_active_synergies() -> Array[SynergyDefinition]:
	var result: Array[SynergyDefinition] = []
	for synergy: SynergyDefinition in _active_synergy_by_id.values():
		result.append(synergy)
	result.sort_custom(_synergy_before)
	return result


func get_synergy_progress() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if synergy_catalogue == null:
		return result
	for synergy: SynergyDefinition in synergy_catalogue.get_sorted_synergies():
		result.append(_progress_snapshot(synergy, _tag_counts, _active_synergy_by_id))
	return result


func preview_equipment(
	item: EquipmentDefinition,
	slot_index: int = -1,
	outgoing_backpack_slot: int = -1
) -> Dictionary:
	if not is_catalogue_item(item) or owns_equipment(item.id):
		return {"valid": false, "reason": &"invalid_or_duplicate"}
	var target_slot: int = slot_index
	if target_slot < 0:
		target_slot = first_empty_slot()
	if target_slot < 0:
		var replacement_previews: Array[Dictionary] = []
		for replacement_slot: int in range(SLOT_COUNT):
			replacement_previews.append(
				preview_equipment(item, replacement_slot, outgoing_backpack_slot)
			)
		return {
			"valid": false,
			"reason": &"replacement_required",
			"requires_replacement": true,
			"replacement_previews": replacement_previews,
		}
	if target_slot >= SLOT_COUNT:
		return {"valid": false, "reason": &"invalid_slot"}

	var proposed_slots: Array[EquipmentDefinition] = _slots.duplicate()
	var previous_item: EquipmentDefinition = proposed_slots[target_slot]
	var backpack_target: int = outgoing_backpack_slot
	var displaced_backpack_item: EquipmentDefinition = null
	if previous_item != null:
		if backpack_target < 0:
			backpack_target = first_empty_backpack_slot()
		if backpack_target >= 0 and backpack_target < BACKPACK_SLOT_COUNT:
			displaced_backpack_item = _backpack[backpack_target]
	proposed_slots[target_slot] = item
	var proposed: Dictionary = _aggregate(proposed_slots)
	var proposed_tags: Dictionary = proposed.get("tag_counts", {})
	var proposed_active: Dictionary = proposed.get("active", {})
	var immediate_activations: Array[StringName] = []
	var deactivations: Array[StringName] = []
	var alternative_progress: Array[Dictionary] = []
	var progress: Array[Dictionary] = []
	for synergy: SynergyDefinition in synergy_catalogue.get_sorted_synergies():
		var before_count: int = _tag_counts.get(synergy.required_tag, 0)
		var after_count: int = proposed_tags.get(synergy.required_tag, 0)
		var was_active: bool = _active_synergy_by_id.has(synergy.id)
		var will_be_active: bool = proposed_active.has(synergy.id)
		var entry: Dictionary = {
			"id": synergy.id,
			"display_name": synergy.display_name,
			"tag": synergy.required_tag,
			"threshold": synergy.threshold,
			"before": before_count,
			"after": after_count,
			"was_active": was_active,
			"will_be_active": will_be_active,
		}
		progress.append(entry)
		if will_be_active and not was_active:
			immediate_activations.append(synergy.id)
		elif was_active and not will_be_active:
			deactivations.append(synergy.id)
		if after_count > before_count and not will_be_active:
			alternative_progress.append(entry)
	return {
		"valid": true,
		"equipment_id": item.id,
		"display_name": item.display_name,
		"slot_index": target_slot,
		"replaces_id": previous_item.id if previous_item != null else &"",
		"replaces_name": previous_item.display_name if previous_item != null else "",
		"requires_replacement": previous_item != null,
		"inventory_revision": _inventory_revision,
		"outgoing_backpack_slot": backpack_target,
		"requires_backpack_target": previous_item != null and backpack_target < 0,
		"leaves_behind_id": (
			displaced_backpack_item.id if displaced_backpack_item != null else &""
		),
		"leaves_behind_name": (
			displaced_backpack_item.display_name if displaced_backpack_item != null else ""
		),
		"immediate_activations": immediate_activations,
		"deactivations": deactivations,
		"alternative_progress": alternative_progress,
		"progress": progress,
		"tag_counts_after": proposed_tags,
	}


func get_snapshot() -> Dictionary:
	var slot_snapshots: Array[Dictionary] = _slot_snapshots(_slots)
	var backpack_snapshots: Array[Dictionary] = _slot_snapshots(_backpack)
	var active_ids: Array[StringName] = []
	for synergy: SynergyDefinition in get_active_synergies():
		active_ids.append(synergy.id)
	return {
		"slot_count": SLOT_COUNT,
		"slots": slot_snapshots,
		"backpack_slot_count": BACKPACK_SLOT_COUNT,
		"backpack_slots": backpack_snapshots,
		"inventory_revision": _inventory_revision,
		"owned_count": get_owned_items_stable().size(),
		"tag_counts": _tag_counts.duplicate(),
		"synergy_progress": get_synergy_progress(),
		"active_synergy_ids": active_ids,
		"flat_modifiers": _flat_modifiers.duplicate(),
		"percent_modifiers": _percent_modifiers.duplicate(),
		"triggered_effect_count": _triggered_effects.size(),
	}


func get_build_summary() -> String:
	var names: PackedStringArray = PackedStringArray()
	for item: EquipmentDefinition in get_equipped_items():
		names.append(item.display_name)
	return ", ".join(names) if not names.is_empty() else "None"


func get_active_synergy_summary() -> String:
	var names: PackedStringArray = PackedStringArray()
	for synergy: SynergyDefinition in get_active_synergies():
		names.append(synergy.display_name)
	return ", ".join(names) if not names.is_empty() else "None"


func _rebuild_catalogue_index() -> void:
	_equipment_by_id.clear()
	if equipment_catalogue == null:
		return
	var duplicate_ids: Dictionary[StringName, bool] = {}
	for item: EquipmentDefinition in equipment_catalogue.items:
		if item == null or item.id == &"" or duplicate_ids.has(item.id):
			continue
		if _equipment_by_id.has(item.id):
			_equipment_by_id.erase(item.id)
			duplicate_ids[item.id] = true
			continue
		_equipment_by_id[item.id] = item


func _validate_catalogues() -> void:
	if equipment_catalogue == null or synergy_catalogue == null:
		push_error("SynergySystem requires equipment and synergy catalogues.")
		return
	for error_message: String in equipment_catalogue.validation_errors():
		push_error("Equipment catalogue: %s" % error_message)
	for error_message: String in synergy_catalogue.validation_errors():
		push_error("Synergy catalogue: %s" % error_message)


func _can_acquire(item: EquipmentDefinition, expected_revision: int) -> bool:
	return (
		_revision_matches(expected_revision)
		and is_catalogue_item(item)
		and not owns_equipment(item.id)
	)


func _revision_matches(expected_revision: int) -> bool:
	return expected_revision < 0 or expected_revision == _inventory_revision


func _slot_snapshots(items: Array[EquipmentDefinition]) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for slot_index: int in range(items.size()):
		var item: EquipmentDefinition = items[slot_index]
		snapshots.append({
			"slot_index": slot_index,
			"id": item.id if item != null else &"",
			"display_name": item.display_name if item != null else "EMPTY",
			"tags": (
				item.sorted_tags()
				if item != null
				else Array([], TYPE_STRING_NAME, &"", null)
			),
			"major_effects": item.major_effects if item != null else PackedStringArray(),
			"icon": item.icon if item != null else null,
		})
	return snapshots


func _recalculate_build() -> void:
	var previous_active: Dictionary[StringName, SynergyDefinition] = {}
	for synergy_id: StringName in _active_synergy_by_id:
		previous_active[synergy_id] = _active_synergy_by_id[synergy_id]
	var aggregate: Dictionary = _aggregate(_slots)
	_tag_counts.clear()
	var aggregated_tags: Dictionary = aggregate.get("tag_counts", {})
	for tag_value: Variant in aggregated_tags:
		var tag: StringName = StringName(tag_value)
		_tag_counts[tag] = int(aggregated_tags[tag_value])
	_flat_modifiers.clear()
	var aggregated_flat: Dictionary = aggregate.get("flat_modifiers", {})
	for stat_value: Variant in aggregated_flat:
		var stat_id: StringName = StringName(stat_value)
		_flat_modifiers[stat_id] = float(aggregated_flat[stat_value])
	_percent_modifiers.clear()
	var aggregated_percent: Dictionary = aggregate.get("percent_modifiers", {})
	for stat_value: Variant in aggregated_percent:
		var stat_id: StringName = StringName(stat_value)
		_percent_modifiers[stat_id] = float(aggregated_percent[stat_value])
	_active_synergy_by_id.clear()
	var aggregated_active: Dictionary = aggregate.get("active", {})
	for synergy_id_value: Variant in aggregated_active:
		var synergy: SynergyDefinition = aggregated_active[synergy_id_value] as SynergyDefinition
		if synergy != null:
			_active_synergy_by_id[synergy.id] = synergy
	_triggered_effects.clear()
	var aggregated_effects: Array = aggregate.get("triggered_effects", [])
	for effect_value: Variant in aggregated_effects:
		var effect: TriggeredEffectDefinition = effect_value as TriggeredEffectDefinition
		if effect != null:
			_triggered_effects.append(effect)

	var deactivated: Array[SynergyDefinition] = []
	for synergy: SynergyDefinition in previous_active.values():
		if not _active_synergy_by_id.has(synergy.id):
			deactivated.append(synergy)
	deactivated.sort_custom(_synergy_before)
	for synergy: SynergyDefinition in deactivated:
		synergy_deactivated.emit(synergy)

	var activated: Array[SynergyDefinition] = []
	for synergy: SynergyDefinition in _active_synergy_by_id.values():
		if not previous_active.has(synergy.id):
			activated.append(synergy)
	activated.sort_custom(_synergy_before)
	for synergy: SynergyDefinition in activated:
		synergy_activated.emit(synergy)

	tags_changed.emit(_tag_counts.duplicate())
	modifiers_changed.emit(_flat_modifiers.duplicate(), _percent_modifiers.duplicate())
	build_changed.emit(get_snapshot())


func _aggregate(slots: Array[EquipmentDefinition]) -> Dictionary:
	var tag_counts: Dictionary[StringName, int] = {}
	var flat_modifiers: Dictionary[StringName, float] = {}
	var percent_modifiers: Dictionary[StringName, float] = {}
	var triggered_effects: Array[TriggeredEffectDefinition] = []
	var items: Array[EquipmentDefinition] = []
	for item: EquipmentDefinition in slots:
		if item != null:
			items.append(item)
	items.sort_custom(_equipment_before)
	for item: EquipmentDefinition in items:
		var tags: Array[StringName] = item.sorted_tags()
		for tag: StringName in tags:
			tag_counts[tag] = tag_counts.get(tag, 0) + 1
		_accumulate_components(item.modifiers, item.triggered_effects, flat_modifiers, percent_modifiers, triggered_effects)

	var active: Dictionary[StringName, SynergyDefinition] = {}
	var synergies: Array[SynergyDefinition] = (
		synergy_catalogue.get_sorted_synergies()
		if synergy_catalogue != null
		else []
	)
	for synergy: SynergyDefinition in synergies:
		if tag_counts.get(synergy.required_tag, 0) < synergy.threshold:
			continue
		active[synergy.id] = synergy
		_accumulate_components(synergy.modifiers, synergy.triggered_effects, flat_modifiers, percent_modifiers, triggered_effects)
	triggered_effects.sort_custom(_effect_before)
	return {
		"tag_counts": tag_counts,
		"flat_modifiers": flat_modifiers,
		"percent_modifiers": percent_modifiers,
		"active": active,
		"triggered_effects": triggered_effects,
	}


func _accumulate_components(
	modifiers: Array[EquipmentModifierDefinition],
	effects: Array[TriggeredEffectDefinition],
	flat_modifiers: Dictionary[StringName, float],
	percent_modifiers: Dictionary[StringName, float],
	triggered_effects: Array[TriggeredEffectDefinition]
) -> void:
	var sorted_modifiers: Array[EquipmentModifierDefinition] = modifiers.duplicate()
	sorted_modifiers.sort_custom(_modifier_before)
	for modifier: EquipmentModifierDefinition in sorted_modifiers:
		if modifier == null:
			continue
		if modifier.operation == EquipmentModifierDefinition.Operation.FLAT:
			flat_modifiers[modifier.stat_id] = (
				flat_modifiers.get(modifier.stat_id, 0.0) + modifier.amount
			)
		else:
			percent_modifiers[modifier.stat_id] = (
				percent_modifiers.get(modifier.stat_id, 0.0) + modifier.amount
			)
	for effect: TriggeredEffectDefinition in effects:
		if effect != null:
			triggered_effects.append(effect)


func _progress_snapshot(
	synergy: SynergyDefinition,
	tag_counts: Dictionary[StringName, int],
	active: Dictionary[StringName, SynergyDefinition]
) -> Dictionary:
	return {
		"id": synergy.id,
		"display_name": synergy.display_name,
		"tag": synergy.required_tag,
		"count": tag_counts.get(synergy.required_tag, 0),
		"threshold": synergy.threshold,
		"active": active.has(synergy.id),
		"major_effects": synergy.major_effects,
		"badge": synergy.badge,
	}


func _equipment_before(left: EquipmentDefinition, right: EquipmentDefinition) -> bool:
	return String(left.id) < String(right.id)


func _synergy_before(left: SynergyDefinition, right: SynergyDefinition) -> bool:
	return String(left.id) < String(right.id)


func _modifier_before(
	left: EquipmentModifierDefinition,
	right: EquipmentModifierDefinition
) -> bool:
	if left == null:
		return false
	if right == null:
		return true
	return String(left.id) < String(right.id)


func _effect_before(left: TriggeredEffectDefinition, right: TriggeredEffectDefinition) -> bool:
	return String(left.id) < String(right.id)
