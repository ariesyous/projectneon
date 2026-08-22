extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/unit/wp03_district_plan_suite.gd"),
	preload("res://tests/integration/wp03_district_plan_ui_suite.gd"),
	preload("res://tests/integration/milestone_4_1_inventory_ui_suite.gd"),
	preload("res://tests/unit/milestone_5_card_system_suite.gd"),
	preload("res://tests/integration/milestone_5_card_ui_suite.gd"),
	preload("res://tests/integration/milestone_5_route_effects_suite.gd"),
	preload("res://tests/unit/wp02_core_run_loop_suite.gd"),
	preload("res://tests/integration/wp02_state_clarity_suite.gd"),
]


func _init() -> void:
	call_deferred("_run_suites")


func _run_suites() -> void:
	var suites: Array = []
	for suite_script: Script in SUITE_SCRIPTS:
		suites.append(suite_script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertion_total: int = 0
	for test_result: Dictionary in result.get("results", []):
		assertion_total += int(test_result.get("assertion_count", 0))
	print(
		"WP03_AFFECTED_SUMMARY=%d/%d tests, %d assertions, %d failed, %d skipped"
		% [
			int(result.get("passed", 0)),
			int(result.get("total", 0)),
			assertion_total,
			int(result.get("failed", 0)),
			int(result.get("skipped", 0)),
		]
	)
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		var unsuccessful: Array[Dictionary] = []
		for test_result: Dictionary in result.get("results", []):
			if not bool(test_result.get("passed", false)) or bool(test_result.get("skipped", false)):
				unsuccessful.append(test_result)
		print("WP03_AFFECTED_FAILURES=" + JSON.stringify(unsuccessful))
	var exit_code: int = 0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	for _frame: int in range(10):
		await process_frame
	quit(exit_code)
