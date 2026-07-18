class_name RunCoolingController
extends Node

## Finite player-facing Heat relief. It coordinates existing authorities but
## cannot access or mutate Night Pressure, threshold latches, or boss queues.

signal cooling_state_changed(subway_charges: int, shop_purchases_remaining: int)
signal cooling_applied(source_id: StringName, heat_reduction: int)
signal cooling_rejected(source_id: StringName, reason: StringName)

const DEFAULT_TUNING: RunCoolingDefinition = preload(
	"res://data/run/milestone_3_cooling.tres"
)

@export var tuning: RunCoolingDefinition = DEFAULT_TUNING

var _run_director: RunDirector
var _reward_director: RewardDirector
var _patrol_controller: PatrolController
var _subway_charges: int = 0
var _shop_purchases_used: int = 0


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
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())


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
	_run_director.apply_heat_delta(-maxi(tuning.shop_heat_reduction, 0))
	cooling_applied.emit(&"shop_cooling", maxi(tuning.shop_heat_reduction, 0))
	cooling_state_changed.emit(_subway_charges, get_shop_purchases_remaining())
	return true


func get_subway_charges() -> int:
	return _subway_charges


func get_shop_purchases_remaining() -> int:
	return maxi(tuning.shop_cooling_purchase_limit - _shop_purchases_used, 0)


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
	}
