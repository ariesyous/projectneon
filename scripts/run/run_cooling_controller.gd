class_name RunCoolingController
extends Node

## Finite player-facing Heat relief. It coordinates existing authorities but
## cannot access or mutate Night Pressure, threshold latches, or boss queues.

signal cooling_state_changed(subway_charges: int, shop_purchases_remaining: int)
signal cooling_applied(source_id: StringName, heat_reduction: int)
signal cooling_rejected(source_id: StringName, reason: StringName)
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
		or not _patrol_controller.request_reroute()
	):
		cooling_rejected.emit(&"subway_reroute", &"invalid_state")
		return false
	_subway_charges -= 1
	_run_director.apply_heat_delta(-maxi(tuning.subway_heat_reduction, 0))
	cooling_applied.emit(&"subway_reroute", maxi(tuning.subway_heat_reduction, 0))
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	return true


func request_shop_cooling() -> bool:
	if get_shop_purchases_remaining() <= 0:
		cooling_rejected.emit(&"shop_cooling", &"sold_out")
		return false
	if _shop_visit_active and get_shop_visit_purchases_remaining() == 0:
		cooling_rejected.emit(_shop_visit_source_id, &"visit_limit_reached")
		return false
	if (
		_run_director == null
		or _reward_director == null
		or _run_director.current_state != RunDirector.RunState.SHOP
	):
		cooling_rejected.emit(&"shop_cooling", &"invalid_state")
		return false
	if _run_director.heat <= 0:
		cooling_rejected.emit(&"shop_cooling", &"heat_already_zero")
		return false
	if not _reward_director.spend_coins(maxi(tuning.shop_cooling_coin_cost, 0)):
		cooling_rejected.emit(&"shop_cooling", &"insufficient_coins")
		return false
	_shop_purchases_used += 1
	if _shop_visit_active:
		_shop_visit_purchases_used += 1
	_run_director.apply_heat_delta(-maxi(tuning.shop_heat_reduction, 0))
	var applied_source_id: StringName = (
		_shop_visit_source_id if _shop_visit_active else &"shop_cooling"
	)
	cooling_applied.emit(applied_source_id, maxi(tuning.shop_heat_reduction, 0))
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	if _shop_visit_active:
		_emit_shop_visit_changed()
	return true


func get_subway_charges() -> int:
	return _subway_charges


func get_shop_purchases_remaining() -> int:
	return maxi(tuning.shop_cooling_purchase_limit - _shop_purchases_used, 0)


func is_shop_visit_active() -> bool:
	return _shop_visit_active


func get_shop_visit_source_id() -> StringName:
	return _shop_visit_source_id


func get_shop_visit_purchases_remaining() -> int:
	if not _shop_visit_active or _shop_visit_purchase_limit < 0:
		return -1
	return maxi(_shop_visit_purchase_limit - _shop_visit_purchases_used, 0)


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
	}


func _emit_shop_visit_changed() -> void:
	shop_visit_changed.emit(
		_shop_visit_active,
		_shop_visit_source_id,
		_shop_visit_purchase_limit,
		_shop_visit_purchases_used
	)
