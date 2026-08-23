extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/unit/wp04_balance_runtime_suite.gd"),
	preload("res://tests/unit/wp04_reward_shop_authority_suite.gd"),
	preload("res://tests/integration/wp04_build_reward_shop_ui_suite.gd"),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _run_and_quit("WP04_FOCUSED_SUMMARY")


func _run_and_quit(summary_key: String) -> void:
	var suites: Array = []
	for script: Script in SUITE_SCRIPTS:
		suites.append(script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertions: int = 0
	for entry: Dictionary in result.get("results", []):
		assertions += int(entry.get("assertion_count", 0))
	print("%s=%d/%d tests, %d assertions, %d failed, %d skipped" % [
		summary_key,
		int(result.get("passed", 0)), int(result.get("total", 0)), assertions,
		int(result.get("failed", 0)), int(result.get("skipped", 0)),
	])
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		print("WP04_FAILURES=" + JSON.stringify(result.get("results", [])))
	var code: int = 0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	paused = false
	for _frame: int in range(5):
		await process_frame
	quit(code)
