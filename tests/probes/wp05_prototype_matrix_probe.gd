extends SceneTree

## The owner-selected production set removed the Part A GameRun enable/freeze
## seams. Historical Part A matrix output remains in the decision record; the
## live post-selection matrix is now tests/probes/wp05_production_matrix_probe.gd.


func _init() -> void:
	print("WP05_PART_A_MATRIX_ARCHIVED=true")
	print("WP05_PART_A_MATRIX_RECORD=res://docs/product/WP05_PROTOTYPE_COMPARISON.md")
	print("WP05_CURRENT_MATRIX_PROBE=res://tests/probes/wp05_production_matrix_probe.gd")
	quit(0)
