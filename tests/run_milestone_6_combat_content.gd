extends SceneTree

## Standalone focused runner for the Milestone 6 actor/combat content suite.

const CombatContentSuiteScript: Script = preload(
	"res://tests/unit/milestone_6_combat_content_suite.gd"
)


func _init() -> void:
	call_deferred("_run_combat_content_suite")


func _run_combat_content_suite() -> void:
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(
		[CombatContentSuiteScript.new()],
		"",
		"",
		{},
		true
	)
	print("MILESTONE_6_COMBAT_CONTENT_RESULTS=" + JSON.stringify(result))
	quit(0 if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0 else 1)
