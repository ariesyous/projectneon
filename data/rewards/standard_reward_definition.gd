@tool
class_name StandardRewardDefinition
extends Resource

## One authored standard coins-and-Scrap reward. RewardDirector selects and
## applies it; equipment and District Cards retain separate typed authorities.

@export var id: StringName = &"street_cache"
@export var display_name: String = "Street Cache"
@export_range(0, 5, 1) var quality_tier: int = 0
@export_range(0, 100000, 1) var coins: int = 20
@export_range(0, 100000, 1) var scrap: int = 2
