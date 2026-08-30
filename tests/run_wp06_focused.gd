extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/unit/wp06_world_presentation_suite.gd"),
	preload("res://tests/integration/wp06_game_run_presentation_suite.gd"),
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
	print("WP06_FOCUSED_SUMMARY=%d/%d tests, %d assertions, %d failed, %d skipped" % [
		int(result.get("passed", 0)), int(result.get("total", 0)), assertions,
		int(result.get("failed", 0)), int(result.get("skipped", 0)),
	])
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		print("WP06_FOCUSED_FAILURES=" + JSON.stringify(result.get("results", [])))
	var code: int = 0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	paused = false
	for _frame: int in range(10):
		await process_frame
	quit(code)
