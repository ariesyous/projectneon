extends SceneTree

const SUITES: Array[Script] = [preload("res://tests/integration/playability_repair_suite.gd")]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var suites: Array = []
	for script: Script in SUITES:
		suites.append(script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertions: int = 0
	for entry: Dictionary in result.get("results", []):
		assertions += int(entry.get("assertion_count", 0))
	print("PLAYABILITY_REPAIRS=%d/%d tests, %d assertions, %d failed, %d skipped" % [int(result.passed), int(result.total), assertions, int(result.failed), int(result.skipped)])
	if int(result.failed) > 0 or int(result.skipped) > 0:
		print("PLAYABILITY_FAILURES=" + JSON.stringify(result.get("results", [])))
	var code: int = 0 if int(result.failed) == 0 and int(result.skipped) == 0 else 1
	result.clear()
	suites.clear()
	runner = null
	for frame: int in range(10):
		await process_frame
	quit(code)
