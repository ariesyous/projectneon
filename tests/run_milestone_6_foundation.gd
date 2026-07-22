extends SceneTree

## Standalone focused runner for the two Milestone-6 foundation suites. The
## editor plugin still discovers their test_* wrappers during cumulative runs.

const PersistenceSuiteScript: Script = preload(
	"res://tests/unit/milestone_6_persistence_settings_suite.gd"
)
const AudioTutorialSuiteScript: Script = preload(
	"res://tests/unit/milestone_6_audio_tutorial_suite.gd"
)


func _init() -> void:
	call_deferred("_run_foundation_suites")


func _run_foundation_suites() -> void:
	var suites: Array = [
		PersistenceSuiteScript.new(),
		AudioTutorialSuiteScript.new(),
	]
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	print("MILESTONE_6_FOUNDATION_RESULTS=" + JSON.stringify(result))
	quit(0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1)
