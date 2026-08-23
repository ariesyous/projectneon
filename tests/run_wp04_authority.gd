extends SceneTree

const SUITE_SCRIPT: Script = preload(
	"res://tests/unit/wp04_reward_shop_authority_suite.gd"
)


func _init() -> void:
	call_deferred("_run_suite")


func _run_suite() -> void:
	var suites: Array = [SUITE_SCRIPT.new()]
	var runner: McpTestRunner = McpTestRunner.new()
	var result: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var assertion_total: int = 0
	for test_result: Dictionary in result.get("results", []):
		assertion_total += int(test_result.get("assertion_count", 0))
	print(
		"WP04_REWARD_SHOP_AUTHORITY_SUMMARY=%d/%d tests, %d assertions, %d failed, %d skipped"
		% [
			int(result.get("passed", 0)),
			int(result.get("total", 0)),
			assertion_total,
			int(result.get("failed", 0)),
			int(result.get("skipped", 0)),
		]
	)
	if int(result.get("failed", 0)) > 0 or int(result.get("skipped", 0)) > 0:
		print("WP04_REWARD_SHOP_AUTHORITY_FAILURES=" + JSON.stringify(result.get("results", [])))
	var exit_code: int = (
		0
		if int(result.get("failed", 0)) == 0 and int(result.get("skipped", 0)) == 0
		else 1
	)
	result.clear()
	suites.clear()
	runner = null
	for _frame: int in range(5):
		await process_frame
	quit(exit_code)
