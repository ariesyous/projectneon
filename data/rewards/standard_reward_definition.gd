@tool
class_name StandardRewardDefinition
extends Resource

## A Milestone 3 standard coins-and-Scrap reward. Equipment and cards remain
## compatibility streams only until their owning milestones.

@export var id: StringName = &"street_cache"
@export var display_name: String = "Street Cache"
@export_range(0, 5, 1) var quality_tier: int = 0
@export_range(0, 100000, 1) var coins: int = 20
@export_range(0, 100000, 1) var scrap: int = 2
