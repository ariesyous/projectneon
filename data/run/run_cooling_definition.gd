@tool
class_name RunCoolingDefinition
extends Resource

## Finite per-run cooling. Neither source may change Night Pressure or latched
## progression, and neither source regenerates through elapsed time.

@export_range(0, 20, 1) var initial_subway_reroute_charges: int = 2
@export_range(0, 20, 1) var subway_reroute_acquisition_cap: int = 2
@export_range(0, 100, 1) var subway_heat_reduction: int = 15
@export_range(0, 20, 1) var shop_cooling_purchase_limit: int = 2
@export_range(0, 100000, 1) var shop_cooling_coin_cost: int = 60
@export_range(0, 100, 1) var shop_heat_reduction: int = 18
