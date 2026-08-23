class_name RunCoolingController
extends Node

## Finite player-facing Heat relief. It coordinates existing authorities but
## cannot access or mutate Night Pressure, threshold latches, or boss queues.

signal cooling_state_changed(subway_charges: int, shop_purchases_remaining: int)
signal cooling_applied(source_id: StringName, heat_reduction: int)
signal cooling_rejected(source_id: StringName, reason: StringName)
signal shop_purchase_resolved(result: Dictionary)
signal shop_visit_changed(
	is_active: bool,
	source_id: StringName,
	purchase_limit: int,
	purchases_used: int
)

const DEFAULT_TUNING: RunCoolingDefinition = preload(
	"res://data/run/milestone_3_cooling.tres"
)

@export var tuning: RunCoolingDefinition = DEFAULT_TUNING

var _run_director: RunDirector
var _reward_director: RewardDirector
var _patrol_controller: PatrolController
var _subway_charges: int = 0
var _shop_purchases_used: int = 0
var _shop_visit_active: bool = false
var _shop_visit_source_id: StringName = &""
var _shop_visit_purchase_limit: int = -1
var _shop_visit_purchases_used: int = 0
var _shop_visit_revision: int = -1
var _next_shop_visit_revision: int = 1
var _shop_purchase_resolving: bool = false
var _last_shop_purchase_result: Dictionary = {}


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING


func configure(
	run_director: RunDirector,
	reward_director: RewardDirector,
	patrol_controller: PatrolController
) -> void:
	_run_director = run_director
	_reward_director = reward_director
	_patrol_controller = patrol_controller
	reset_for_run()


func reset_for_run() -> void:
	_subway_charges = mini(
		maxi(tuning.initial_subway_reroute_charges, 0),
		maxi(tuning.subway_reroute_acquisition_cap, 0)
	)
	_shop_purchases_used = 0
	_shop_visit_active = false
	_shop_visit_source_id = &""
	_shop_visit_purchase_limit = -1
	_shop_visit_purchases_used = 0
	_shop_visit_revision = -1
	_shop_purchase_resolving = false
	_last_shop_purchase_result.clear()
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	_emit_shop_visit_changed()


## Starts one shop visit without replenishing global stock. A negative limit
## preserves the baseline route shop's unlimited-by-visit behavior; card-owned
## Convenience Store visits pass 1.
func begin_shop_visit(source_id: StringName, max_purchases: int = -1) -> bool:
	if source_id == &"" or max_purchases < -1 or _shop_visit_active:
		return false
	_shop_visit_active = true
	_shop_visit_source_id = source_id
	_shop_visit_purchase_limit = max_purchases
	_shop_visit_purchases_used = 0
	_shop_visit_revision = _next_shop_visit_revision
	_next_shop_visit_revision += 1
	_emit_shop_visit_changed()
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	return true


func end_shop_visit() -> bool:
	if not _shop_visit_active:
		return false
	_shop_visit_active = false
	_shop_visit_source_id = &""
	_shop_visit_purchase_limit = -1
	_shop_visit_purchases_used = 0
	_shop_visit_revision = -1
	_emit_shop_visit_changed()
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	return true


func request_subway_reroute() -> bool:
	if _subway_charges <= 0:
		cooling_rejected.emit(&"subway_reroute", &"no_charges")
		return false
	if (
		_run_director == null
		or _patrol_controller == null
		or _run_director.current_state != RunDirector.RunState.PATROLLING
		or not _patrol_controller.can_reroute()
	):
		cooling_rejected.emit(&"subway_reroute", &"invalid_state")
		return false
	# All rejection checks complete before mutation. Godot signal delivery is
	# synchronous, so Heat and the finite charge commit before PatrolController
	# emits the next authored occurrence; encounter eligibility therefore sees
	# the cooled tier. No random stream or Night Pressure state is touched here.
	_subway_charges -= 1
	_run_director.apply_heat_delta(-maxi(tuning.subway_heat_reduction, 0))
	if not _patrol_controller.request_reroute():
		push_error("Validated Subway Reroute could not commit its authored route advance.")
		return false
	cooling_applied.emit(&"subway_reroute", maxi(tuning.subway_heat_reduction, 0))
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	return true


func request_shop_cooling(
	expected_visit_revision: int = -1,
	expected_source_id: StringName = &""
) -> bool:
	return bool(
		request_shop_cooling_result(
			expected_visit_revision,
			expected_source_id
		).get("accepted", false)
	)


## Performs one atomic finite-stock purchase and returns the exact authority
## result. The optional context defaults retain historical direct fixtures;
## production callers bind both the active visit revision and source.
func request_shop_cooling_result(
	expected_visit_revision: int = -1,
	expected_source_id: StringName = &""
) -> Dictionary:
	var preview: Dictionary = get_shop_purchase_preview(
		expected_visit_revision,
		expected_source_id
	)
	if _shop_purchase_resolving:
		return _as_shop_result(preview, false, &"reentrant_request")
	if not bool(preview.get("valid", false)):
		var rejected: Dictionary = _as_shop_result(
			preview,
			false,
			StringName(preview.get("reason", &"invalid"))
		)
		_publish_shop_result(rejected)
		return rejected.duplicate(true)

	_shop_purchase_resolving = true
	# The guard is raised before spend_coins because its synchronous signal may
	# invoke presentation callbacks. Stock and Heat can commit only once.
	if not _reward_director.spend_coins(maxi(tuning.shop_cooling_coin_cost, 0)):
		var failed: Dictionary = _as_shop_result(preview, false, &"transaction_failed")
		_shop_purchase_resolving = false
		_publish_shop_result(failed)
		return failed.duplicate(true)
	_shop_purchases_used += 1
	if _shop_visit_active:
		_shop_visit_purchases_used += 1
	_run_director.apply_heat_delta(-maxi(tuning.shop_heat_reduction, 0))

	var result: Dictionary = _as_shop_result(preview, true, &"ok")
	result.merge(_current_shop_after_values(), true)
	_last_shop_purchase_result = result.duplicate(true)
	var applied_source_id: StringName = StringName(result.get("source_id", &"shop_cooling"))
	cooling_applied.emit(applied_source_id, maxi(tuning.shop_heat_reduction, 0))
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	if _shop_visit_active:
		_emit_shop_visit_changed()
	shop_purchase_resolved.emit(result.duplicate(true))
	_shop_purchase_resolving = false
	return result.duplicate(true)


func get_subway_charges() -> int:
	return _subway_charges


func get_shop_purchases_remaining() -> int:
	return maxi(tuning.shop_cooling_purchase_limit - _shop_purchases_used, 0)


func is_shop_visit_active() -> bool:
	return _shop_visit_active


func get_shop_visit_source_id() -> StringName:
	return _shop_visit_source_id


func get_shop_visit_revision() -> int:
	return _shop_visit_revision


func get_shop_visit_purchases_remaining() -> int:
	if not _shop_visit_active or _shop_visit_purchase_limit < 0:
		return -1
	return maxi(_shop_visit_purchase_limit - _shop_visit_purchases_used, 0)


## Non-mutating exact transaction forecast for a focused shop decision.
func get_shop_purchase_preview(
	expected_visit_revision: int = -1,
	expected_source_id: StringName = &""
) -> Dictionary:
	var reason: StringName = _shop_purchase_rejection_reason(
		expected_visit_revision,
		expected_source_id
	)
	var valid: bool = reason == &"ok"
	var coins_before: int = (
		_reward_director.get_coin_total() if _reward_director != null else 0
	)
	var heat_before: int = _run_director.heat if _run_director != null else 0
	var heat_after: int = heat_before
	var coins_after: int = coins_before
	var global_stock_before: int = get_shop_purchases_remaining()
	var visit_stock_before: int = get_shop_visit_purchases_remaining()
	if valid:
		coins_after = coins_before - maxi(tuning.shop_cooling_coin_cost, 0)
		heat_after = maxi(heat_before - maxi(tuning.shop_heat_reduction, 0), 0)
	var global_stock_after: int = (
		maxi(global_stock_before - 1, 0) if valid else global_stock_before
	)
	var visit_stock_after: int = visit_stock_before
	if valid and visit_stock_before >= 0:
		visit_stock_after = maxi(visit_stock_before - 1, 0)
	var source_id: StringName = (
		_shop_visit_source_id if _shop_visit_active else &"shop_cooling"
	)
	return {
		"preview": true,
		"valid": valid,
		"can_purchase": valid,
		"accepted": false,
		"reason": reason,
		"visit_revision": _shop_visit_revision,
		"source_id": source_id,
		"coin_cost": maxi(tuning.shop_cooling_coin_cost, 0),
		"heat_reduction": maxi(tuning.shop_heat_reduction, 0),
		"heat_reduction_applied": heat_before - heat_after,
		"coins_before": coins_before,
		"coins_after": coins_after,
		"heat_before": heat_before,
		"heat_after": heat_after,
		"heat_tier_before": _heat_tier_for_value(heat_before),
		"heat_tier_after": _heat_tier_for_value(heat_after),
		"reward_quality_tier_before": _reward_quality_for_value(heat_before),
		"reward_quality_tier_after": _reward_quality_for_value(heat_after),
		"reward_quality_before": _reward_quality_for_value(heat_before),
		"reward_quality_after": _reward_quality_for_value(heat_after),
		"reward_multiplier_before": _reward_multiplier_for_value(heat_before),
		"reward_multiplier_after": _reward_multiplier_for_value(heat_after),
		"global_stock_before": global_stock_before,
		"global_stock_after": global_stock_after,
		"visit_stock_before": visit_stock_before,
		"visit_stock_after": visit_stock_after,
		"night_pressure_before": (
			_run_director.night_pressure if _run_director != null else 0.0
		),
		"night_pressure_after": (
			_run_director.night_pressure if _run_director != null else 0.0
		),
		"night_pressure": (
			_run_director.night_pressure if _run_director != null else 0.0
		),
	}


func preview_shop_purchase(
	expected_visit_revision: int = -1,
	expected_source_id: StringName = &""
) -> Dictionary:
	return get_shop_purchase_preview(expected_visit_revision, expected_source_id)


func get_last_shop_purchase_result() -> Dictionary:
	return _last_shop_purchase_result.duplicate(true)


func get_snapshot() -> Dictionary:
	return {
		"subway_charges": _subway_charges,
		"subway_acquisition_cap": tuning.subway_reroute_acquisition_cap,
		"subway_heat_reduction": tuning.subway_heat_reduction,
		"shop_purchases_used": _shop_purchases_used,
		"shop_purchases_remaining": get_shop_purchases_remaining(),
		"shop_purchase_limit": tuning.shop_cooling_purchase_limit,
		"shop_coin_cost": tuning.shop_cooling_coin_cost,
		"shop_heat_reduction": tuning.shop_heat_reduction,
		"shop_visit_active": _shop_visit_active,
		"shop_visit_source_id": _shop_visit_source_id,
		"shop_visit_purchase_limit": _shop_visit_purchase_limit,
		"shop_visit_purchases_used": _shop_visit_purchases_used,
		"shop_visit_purchases_remaining": get_shop_visit_purchases_remaining(),
		"shop_visit_revision": _shop_visit_revision,
		"next_shop_visit_revision": _next_shop_visit_revision,
		"shop_purchase_preview": get_shop_purchase_preview(),
		"last_shop_purchase_result": _last_shop_purchase_result.duplicate(true),
	}


func _emit_shop_visit_changed() -> void:
	shop_visit_changed.emit(
		_shop_visit_active,
		_shop_visit_source_id,
		_shop_visit_purchase_limit,
		_shop_visit_purchases_used
	)


func _shop_purchase_rejection_reason(
	expected_visit_revision: int,
	expected_source_id: StringName
) -> StringName:
	var revision_provided: bool = expected_visit_revision != -1
	var source_provided: bool = expected_source_id != &""
	if (
		expected_visit_revision < -1
		or expected_visit_revision == 0
		or revision_provided != source_provided
	):
		return &"malformed_context"
	if revision_provided:
		if not _shop_visit_active or expected_visit_revision != _shop_visit_revision:
			return &"stale_visit"
		if expected_source_id != _shop_visit_source_id:
			return &"wrong_source"
	if get_shop_purchases_remaining() <= 0:
		return &"sold_out"
	if _shop_visit_active and get_shop_visit_purchases_remaining() == 0:
		return &"visit_limit_reached"
	if (
		_run_director == null
		or _reward_director == null
		or _run_director.current_state != RunDirector.RunState.SHOP
	):
		return &"invalid_state"
	if _run_director.heat <= 0:
		return &"heat_already_zero"
	if _reward_director.get_coin_total() < maxi(tuning.shop_cooling_coin_cost, 0):
		return &"insufficient_coins"
	return &"ok"


func _as_shop_result(
	preview: Dictionary,
	accepted: bool,
	reason: StringName
) -> Dictionary:
	var result: Dictionary = preview.duplicate(true)
	result["preview"] = false
	result["valid"] = accepted
	result["can_purchase"] = accepted
	result["accepted"] = accepted
	result["reason"] = reason
	result["resulting_visit_revision"] = _shop_visit_revision
	if not accepted:
		result["coins_after"] = result.get("coins_before", 0)
		result["heat_after"] = result.get("heat_before", 0)
		result["heat_tier_after"] = result.get("heat_tier_before", 0)
		result["reward_quality_tier_after"] = result.get(
			"reward_quality_tier_before",
			0
		)
		result["reward_quality_after"] = result.get("reward_quality_before", 0)
		result["reward_multiplier_after"] = result.get(
			"reward_multiplier_before",
			1.0
		)
		result["global_stock_after"] = result.get("global_stock_before", 0)
		result["visit_stock_after"] = result.get("visit_stock_before", -1)
		result["night_pressure_after"] = result.get("night_pressure_before", 0.0)
		result["night_pressure"] = result.get("night_pressure_before", 0.0)
		result["heat_reduction_applied"] = 0
	return result


func _publish_shop_result(result: Dictionary) -> void:
	_last_shop_purchase_result = result.duplicate(true)
	_shop_purchase_resolving = true
	var source_id: StringName = StringName(result.get("source_id", &"shop_cooling"))
	cooling_rejected.emit(source_id, StringName(result.get("reason", &"invalid")))
	shop_purchase_resolved.emit(result.duplicate(true))
	_shop_purchase_resolving = false


func _current_shop_after_values() -> Dictionary:
	var heat_value: int = _run_director.heat
	return {
		"coins_after": _reward_director.get_coin_total(),
		"heat_after": heat_value,
		"heat_tier_after": _run_director.get_heat_tier(),
		"reward_quality_tier_after": _run_director.get_reward_quality_tier(),
		"reward_quality_after": _run_director.get_reward_quality_tier(),
		"reward_multiplier_after": _run_director.get_reward_multiplier(),
		"global_stock_after": get_shop_purchases_remaining(),
		"visit_stock_after": get_shop_visit_purchases_remaining(),
		"night_pressure_after": _run_director.night_pressure,
		"night_pressure": _run_director.night_pressure,
		"resulting_visit_revision": _shop_visit_revision,
	}


func _heat_tier_for_value(heat_value: int) -> int:
	if _run_director == null or _run_director.heat_definition == null:
		return 0
	return _run_director.heat_definition.tier_for_heat(heat_value)


func _reward_multiplier_for_value(heat_value: int) -> float:
	if _run_director == null or _run_director.heat_definition == null:
		return 1.0
	return _run_director.heat_definition.reward_multiplier_for_tier(
		_heat_tier_for_value(heat_value)
	)


func _reward_quality_for_value(heat_value: int) -> int:
	if _run_director == null or _run_director.heat_definition == null:
		return 0
	var current_heat_quality: int = _run_director.heat_definition.reward_quality_for_tier(
		_run_director.get_heat_tier()
	)
	var target_heat_quality: int = _run_director.heat_definition.reward_quality_for_tier(
		_heat_tier_for_value(heat_value)
	)
	return clampi(
		_run_director.get_reward_quality_tier()
		- current_heat_quality
		+ target_heat_quality,
		0,
		4
	)
