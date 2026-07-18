class_name CoinClusterTuning
extends Resource

## All Milestone 1 timing and manual-bonus tuning for coin clusters.
## Bonus entries use basis points (100 basis points = 1%). Entry zero applies
## to the first successful manual collection, entry one to the second, etc.

@export_range(100, 10000, 1, "or_greater") var auto_collect_delay_msec: int = 2500
@export_range(100, 10000, 1, "or_greater") var manual_streak_window_msec: int = 3000
@export var manual_bonus_basis_points_by_streak: PackedInt32Array = PackedInt32Array([
	250,
	500,
	750,
	1000,
])
