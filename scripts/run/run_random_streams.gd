class_name RunRandomStreams
extends Node

## Run-scoped deterministic generators. Sub-seeds use FNV-1a over a canonical
## UTF-8 payload and never depend on Variant.hash(), process state, or platform
## byte order. Gameplay content selection remains with its owning system.

const STREAM_ENCOUNTERS: StringName = &"encounters"
const STREAM_SPAWNS: StringName = &"spawns"
const STREAM_REWARDS: StringName = &"rewards"
const STREAM_EQUIPMENT: StringName = &"equipment"
const STREAM_CARDS: StringName = &"cards"
const STREAM_ENEMY_VARIANTS: StringName = &"enemy_variants"
const STREAM_COSMETIC: StringName = &"cosmetic"
const DECLARED_STREAM_NAMES: Array[StringName] = [
	STREAM_ENCOUNTERS,
	STREAM_SPAWNS,
	STREAM_REWARDS,
	STREAM_EQUIPMENT,
	STREAM_CARDS,
	STREAM_ENEMY_VARIANTS,
	STREAM_COSMETIC,
]
const FNV1A_OFFSET_BASIS: int = 2166136261
const FNV1A_PRIME: int = 16777619
const UINT32_MODULUS: int = 4294967296
const DEFAULT_SCHEMA: RunRandomSchemaDefinition = preload(
	"res://data/run/milestone_3_random_schema.tres"
)

@export var schema_definition: RunRandomSchemaDefinition = DEFAULT_SCHEMA

var _run_seed: int = 0
var _generators: Dictionary[StringName, RandomNumberGenerator] = {}
var _draw_counts: Dictionary[StringName, int] = {}


func _ready() -> void:
	if schema_definition == null:
		schema_definition = DEFAULT_SCHEMA
	if _generators.is_empty():
		reset_for_seed(_run_seed)


func reset_for_seed(run_seed: int) -> void:
	_run_seed = run_seed
	_generators.clear()
	_draw_counts.clear()
	for stream_name: StringName in DECLARED_STREAM_NAMES:
		var generator: RandomNumberGenerator = RandomNumberGenerator.new()
		generator.seed = derive_subseed(
			_run_seed,
			stream_name,
			get_random_schema_version()
		)
		_generators[stream_name] = generator
		_draw_counts[stream_name] = 0


func get_run_seed() -> int:
	return _run_seed


func get_random_schema_version() -> int:
	var definition: RunRandomSchemaDefinition = (
		schema_definition if schema_definition != null else DEFAULT_SCHEMA
	)
	return maxi(definition.random_schema_version, 1)


func get_derivation_algorithm_id() -> StringName:
	var definition: RunRandomSchemaDefinition = (
		schema_definition if schema_definition != null else DEFAULT_SCHEMA
	)
	return definition.derivation_algorithm_id


func get_declared_stream_names() -> Array[StringName]:
	return DECLARED_STREAM_NAMES.duplicate()


func has_stream(stream_name: StringName) -> bool:
	return DECLARED_STREAM_NAMES.has(stream_name)


func draw_index(stream_name: StringName, candidate_count: int) -> int:
	if candidate_count <= 0 or not has_stream(stream_name):
		return -1
	var generator: RandomNumberGenerator = _generators.get(stream_name) as RandomNumberGenerator
	if generator == null:
		reset_for_seed(_run_seed)
		generator = _generators.get(stream_name) as RandomNumberGenerator
	if generator == null:
		return -1
	var result: int = generator.randi_range(0, candidate_count - 1)
	_draw_counts[stream_name] = _draw_counts.get(stream_name, 0) + 1
	return result


func choose_stable_id(stream_name: StringName, candidate_ids: Array[StringName]) -> StringName:
	if candidate_ids.is_empty():
		return &""
	var seen_ids: Dictionary[StringName, bool] = {}
	var sorted_ids: Array[StringName] = []
	for candidate_id: StringName in candidate_ids:
		if candidate_id == &"" or seen_ids.has(candidate_id):
			continue
		seen_ids[candidate_id] = true
		sorted_ids.append(candidate_id)
	if sorted_ids.is_empty():
		return &""
	sorted_ids.sort()
	var selected_index: int = draw_index(stream_name, sorted_ids.size())
	return sorted_ids[selected_index] if selected_index >= 0 else &""


func get_draw_count(stream_name: StringName) -> int:
	return _draw_counts.get(stream_name, 0)


func capture_states() -> Dictionary[StringName, Dictionary]:
	var states: Dictionary[StringName, Dictionary] = {}
	for stream_name: StringName in DECLARED_STREAM_NAMES:
		var generator: RandomNumberGenerator = _generators.get(stream_name) as RandomNumberGenerator
		states[stream_name] = {
			"state": generator.state if generator != null else 0,
			"draw_count": get_draw_count(stream_name),
		}
	return states


func restore_states(states: Dictionary[StringName, Dictionary]) -> bool:
	for stream_name: StringName in DECLARED_STREAM_NAMES:
		if not states.has(stream_name):
			return false
	for stream_name: StringName in DECLARED_STREAM_NAMES:
		var generator: RandomNumberGenerator = _generators.get(stream_name) as RandomNumberGenerator
		if generator == null:
			return false
		var record: Dictionary = states[stream_name]
		generator.state = int(record.get("state", generator.state))
		_draw_counts[stream_name] = maxi(int(record.get("draw_count", 0)), 0)
	return true


func get_debug_snapshot() -> Dictionary:
	var counts: Dictionary[StringName, int] = {}
	var sub_seeds: Dictionary[StringName, int] = {}
	for stream_name: StringName in DECLARED_STREAM_NAMES:
		counts[stream_name] = get_draw_count(stream_name)
		sub_seeds[stream_name] = derive_subseed(
			_run_seed,
			stream_name,
			get_random_schema_version()
		)
	return {
		"run_seed": _run_seed,
		"random_schema_version": get_random_schema_version(),
		"derivation_algorithm_id": get_derivation_algorithm_id(),
		"draw_counts": counts,
		"sub_seeds": sub_seeds,
	}


static func derive_subseed(run_seed: int, stream_name: StringName, schema_version: int) -> int:
	var canonical_payload: String = "neon-loop|schema:%d|seed:%d|stream:%s" % [
		maxi(schema_version, 1),
		run_seed,
		String(stream_name),
	]
	var hash_value: int = FNV1A_OFFSET_BASIS
	for byte_value: int in canonical_payload.to_utf8_buffer():
		hash_value = ((hash_value ^ byte_value) * FNV1A_PRIME) % UINT32_MODULUS
	return hash_value if hash_value != 0 else 1
