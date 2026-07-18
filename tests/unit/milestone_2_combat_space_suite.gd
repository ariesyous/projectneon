@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.00001
const HYDRANT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)

var _combat_space: CombatSpaceDefinition = CombatSpaceDefinition.new()


func suite_name() -> String:
	return "milestone_2_combat_space"


func test_downtown_combat_space_has_one_inclusive_actor_origin_contract() -> void:
	_expect_approx(_combat_space.minimum_x(), 164.0, "space: left actor-origin edge")
	_expect_approx(_combat_space.maximum_x(), 456.0, "space: right actor-origin edge")
	_expect_approx(_combat_space.minimum_y(), 194.0, "space: back actor-origin edge")
	_expect_approx(_combat_space.maximum_y(), 258.0, "space: front actor-origin edge")
	_expect_equal(_combat_space.lane_count(), 3, "space: exactly three authored lanes")
	_expect_equal(
		[_combat_space.lane_y(0), _combat_space.lane_y(1), _combat_space.lane_y(2)],
		[194.0, 226.0, 258.0],
		"space: authored lane centres"
	)
	_expect_true(
		_combat_space.contains_actor_position(Vector2(164.0, 194.0)),
		"space: minimum corner is inclusive"
	)
	_expect_true(
		_combat_space.contains_actor_position(Vector2(456.0, 258.0)),
		"space: maximum corner is inclusive"
	)
	_expect_false(
		_combat_space.contains_actor_position(Vector2(163.999, 226.0)),
		"space: point immediately left is excluded"
	)
	_expect_false(
		_combat_space.contains_actor_position(Vector2(456.001, 226.0)),
		"space: point immediately right is excluded"
	)
	_expect_equal(
		_combat_space.clamp_actor_position(Vector2(-100.0, 900.0)),
		Vector2(164.0, 258.0),
		"space: position clamps to authored inclusive edges"
	)


func test_lane_mapping_and_nearest_lane_are_deterministic() -> void:
	_expect_approx(_combat_space.lane_y(-1), 194.0, "lanes: low index clamps")
	_expect_approx(_combat_space.lane_y(99), 258.0, "lanes: high index clamps")
	_expect_equal(_combat_space.nearest_lane_index(194.0), 0, "lanes: exact back lane")
	_expect_equal(_combat_space.nearest_lane_index(226.0), 1, "lanes: exact middle lane")
	_expect_equal(_combat_space.nearest_lane_index(258.0), 2, "lanes: exact front lane")
	_expect_equal(
		_combat_space.nearest_lane_index(210.0),
		0,
		"lanes: exact tie resolves to lower stable lane index"
	)


func test_fire_hydrant_authored_tuning_matches_milestone_2_contract() -> void:
	_expect_equal(HYDRANT_TUNING.id, &"fire_hydrant", "hydrant: stable content id")
	_expect_approx(HYDRANT_TUNING.range_radius, 112.0, "hydrant: circular range")
	_expect_equal(HYDRANT_TUNING.damage, 18, "hydrant: light deterministic damage")
	_expect_approx(HYDRANT_TUNING.knockback_force, 300.0, "hydrant: strong knockback")
	_expect_approx(HYDRANT_TUNING.knockback_duration, 0.30, "hydrant: knockback duration")
	_expect_approx(HYDRANT_TUNING.knockback_direction_x, -1.0, "hydrant: authored leftward blast")
	_expect_approx(HYDRANT_TUNING.cooldown_seconds, 8.0, "hydrant: fixed cooldown")
	_expect_approx(HYDRANT_TUNING.water_duration, 0.55, "hydrant: water timing")
	_expect_approx(HYDRANT_TUNING.impact_duration, 0.28, "hydrant: impact timing")
	_expect_approx(HYDRANT_TUNING.rejection_duration, 0.50, "hydrant: rejection timing")


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= EPSILON,
		"%s (expected %.6f, got %.6f)" % [context, expected, actual]
	)
