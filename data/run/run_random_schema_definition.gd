@tool
class_name RunRandomSchemaDefinition
extends Resource

## Versioned compatibility contract for run-scoped deterministic streams.

@export_range(1, 1000000, 1) var random_schema_version: int = 1
@export var derivation_algorithm_id: StringName = &"fnv1a32_utf8_v1"
@export var declared_stream_names: Array[StringName] = [
	&"encounters",
	&"spawns",
	&"rewards",
	&"equipment",
	&"cards",
	&"enemy_variants",
	&"cosmetic",
]
