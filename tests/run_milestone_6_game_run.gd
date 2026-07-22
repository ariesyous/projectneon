extends SceneTree

const GameRunSuiteScript: Script = preload(
	"res://tests/integration/milestone_6_game_run_suite.gd"
)


func _init() -> void:
	call_deferred("_run_suite")


func _run_suite() -> void:
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites([GameRunSuiteScript.new()], "", "", {}, true)
	print("MILESTONE_6_GAME_RUN_RESULTS=" + JSON.stringify(result))
	quit(0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1)
