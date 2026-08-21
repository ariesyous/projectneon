extends SceneTree

## WP01 cumulative runner: the accepted Milestone 0-6 baseline plus the
## presentation-only Interface and Visual Language acceptance suite.

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/unit/milestone_1_combat_suite.gd"),
	preload("res://tests/integration/milestone_1_combat_director_suite.gd"),
	preload("res://tests/unit/milestone_1_reward_suite.gd"),
	preload("res://tests/unit/milestone_2_combat_space_suite.gd"),
	preload("res://tests/integration/milestone_2_intervention_suite.gd"),
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
	preload("res://tests/integration/milestone_6_call_backup_suite.gd"),
	preload("res://tests/unit/milestone_6_combat_content_suite.gd"),
	preload("res://tests/unit/milestone_6_persistence_settings_suite.gd"),
	preload("res://tests/unit/milestone_6_audio_tutorial_suite.gd"),
	preload("res://tests/integration/milestone_6_presentation_suite.gd"),
	preload("res://tests/integration/milestone_6_game_run_suite.gd"),
	preload("res://tests/integration/wp01_interface_visual_language_suite.gd"),
]


func _init() -> void:
	call_deferred("_run_cumulative_suites")


func _run_cumulative_suites() -> void:
	var suites: Array = []
	for suite_script: Script in SUITE_SCRIPTS:
		suites.append(suite_script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertion_total: int = 0
	for test_result: Dictionary in result.get("results", []):
		assertion_total += int(test_result.get("assertion_count", 0))
	print(
		"WP01_CUMULATIVE_SUMMARY=%d/%d tests, %d assertions, %d failed, %d skipped"
		% [
			int(result.get("passed", 0)),
			int(result.get("total", 0)),
			assertion_total,
			int(result.get("failed", 0)),
			int(result.get("skipped", 0)),
		]
	)
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		var unsuccessful_results: Array[Dictionary] = []
		for test_result: Dictionary in result.get("results", []):
			if not bool(test_result.get("passed", false)) or bool(test_result.get("skipped", false)):
				unsuccessful_results.append(test_result)
		print("WP01_CUMULATIVE_FAILURES=" + JSON.stringify(unsuccessful_results))
	var exit_code: int = 0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	for _frame: int in range(10):
		await process_frame
	quit(exit_code)
