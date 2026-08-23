extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/unit/milestone_3_randomness_suite.gd"),
	preload("res://tests/unit/milestone_3_run_authority_suite.gd"),
	preload("res://tests/unit/milestone_4_equipment_synergy_suite.gd"),
	preload("res://tests/integration/milestone_4_reward_combat_suite.gd"),
	preload("res://tests/unit/milestone_4_1_inventory_safety_suite.gd"),
	preload("res://tests/integration/milestone_4_1_inventory_ui_suite.gd"),
	preload("res://tests/integration/milestone_4_2_inventory_drag_suite.gd"),
	preload("res://tests/unit/milestone_5_card_system_suite.gd"),
	preload("res://tests/integration/milestone_5_card_ui_suite.gd"),
	preload("res://tests/integration/milestone_5_route_effects_suite.gd"),
	preload("res://tests/unit/milestone_6_runtime_systems_suite.gd"),
	preload("res://tests/unit/milestone_6_combat_content_suite.gd"),
	preload("res://tests/integration/milestone_6_presentation_suite.gd"),
	preload("res://tests/integration/milestone_6_game_run_suite.gd"),
	preload("res://tests/integration/wp01_interface_visual_language_suite.gd"),
	preload("res://tests/unit/wp02_core_run_loop_suite.gd"),
	preload("res://tests/integration/wp02_state_clarity_suite.gd"),
	preload("res://tests/unit/wp03_district_plan_suite.gd"),
	preload("res://tests/integration/wp03_district_plan_ui_suite.gd"),
	preload("res://tests/unit/wp04_balance_runtime_suite.gd"),
	preload("res://tests/unit/wp04_reward_shop_authority_suite.gd"),
	preload("res://tests/integration/wp04_build_reward_shop_ui_suite.gd"),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var suites: Array = []
	for script: Script in SUITE_SCRIPTS:
		suites.append(script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertions: int = 0
	for entry: Dictionary in result.get("results", []):
		assertions += int(entry.get("assertion_count", 0))
	print("WP04_AFFECTED_SUMMARY=%d/%d tests, %d assertions, %d failed, %d skipped" % [
		int(result.get("passed", 0)), int(result.get("total", 0)), assertions,
		int(result.get("failed", 0)), int(result.get("skipped", 0)),
	])
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		print("WP04_AFFECTED_FAILURES=" + JSON.stringify(result.get("results", [])))
	var code: int = 0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	paused = false
	for _frame: int in range(8):
		await process_frame
	quit(code)
