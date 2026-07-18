@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EXPECTED_STREAMS: Array[StringName] = [
	&"encounters",
	&"spawns",
	&"rewards",
	&"equipment",
	&"cards",
	&"enemy_variants",
	&"cosmetic",
]


func suite_name() -> String:
	return "milestone_3_randomness"


func test_supplied_and_generated_authoritative_run_seeds() -> void:
	var director: RunDirector = _new_run_director()
	_expect_equal(director.start_run(-8675309, true), -8675309, "seed: supplied signed integer retained")
	_expect_equal(director.run_seed, -8675309, "seed: RunDirector owns supplied seed")
	_expect_equal(director.get_random_streams().get_run_seed(), -8675309, "seed: streams receive supplied seed")
	var first_generated: int = director.restart_new_seed()
	var second_generated: int = director.restart_new_seed()
	_expect_true(first_generated > 0, "seed: first generated seed is positive")
	_expect_true(second_generated > 0, "seed: second generated seed is positive")
	_expect_true(first_generated != second_generated, "seed: nonce prevents duplicate adjacent generation")
	_expect_equal(director.run_seed, second_generated, "seed: latest generated seed is authoritative")


func test_versioned_fnv1a32_subseed_derivation_has_locked_vectors() -> void:
	_expect_equal(
		RunRandomStreams.derive_subseed(424242, &"encounters", 1),
		819973087,
		"derivation: encounters locked FNV-1a vector"
	)
	_expect_equal(
		RunRandomStreams.derive_subseed(424242, &"cosmetic", 1),
		480742754,
		"derivation: cosmetic locked FNV-1a vector"
	)
	_expect_equal(
		RunRandomStreams.derive_subseed(-7, &"rewards", 1),
		3253719257,
		"derivation: signed seed canonicalization vector"
	)
	_expect_true(
		RunRandomStreams.derive_subseed(424242, &"encounters", 1)
		!= RunRandomStreams.derive_subseed(424242, &"encounters", 2),
		"derivation: schema version changes subseed"
	)


func test_exact_named_stream_contract_and_run_scoped_ownership() -> void:
	var director: RunDirector = _new_run_director()
	director.start_run(5001, true)
	var streams: RunRandomStreams = director.get_random_streams()
	_expect_equal(streams.get_parent(), director, "streams: component is a RunDirector child")
	_expect_equal(streams.get_declared_stream_names(), EXPECTED_STREAMS, "streams: exactly seven required names")
	_expect_equal(streams.get_random_schema_version(), 1, "streams: schema version exposed")
	_expect_equal(streams.get_derivation_algorithm_id(), &"fnv1a32_utf8_v1", "streams: algorithm exposed")
	for stream_name: StringName in EXPECTED_STREAMS:
		_expect_true(streams.has_stream(stream_name), "streams: declared %s" % String(stream_name))
	_expect_false(streams.has_stream(&"shared_gameplay"), "streams: no fragile shared gameplay stream")
	_expect_equal(streams.draw_index(&"unknown", 4), -1, "streams: undeclared stream rejects draw")


func test_same_seed_reproduces_every_named_stream() -> void:
	var left: RunRandomStreams = _new_streams(5002)
	var right: RunRandomStreams = _new_streams(5002)
	for stream_name: StringName in EXPECTED_STREAMS:
		var left_sequence: Array[int] = _draw_sequence(left, stream_name, 19, 16)
		var right_sequence: Array[int] = _draw_sequence(right, stream_name, 19, 16)
		_expect_equal(left_sequence, right_sequence, "reproducibility: %s sequence" % String(stream_name))
		_expect_equal(left.get_draw_count(stream_name), 16, "reproducibility: %s draw count" % String(stream_name))


func test_stable_candidate_ordering_ignores_input_and_presentation_order() -> void:
	var unordered_streams: RunRandomStreams = _new_streams(5003)
	var ordered_streams: RunRandomStreams = _new_streams(5003)
	var unordered: Array[StringName] = [&"viper_signal", &"alley_scuffle", &"arcade_ambush"]
	var ordered: Array[StringName] = [&"alley_scuffle", &"arcade_ambush", &"viper_signal"]
	for draw_index: int in range(20):
		_expect_equal(
			unordered_streams.choose_stable_id(RunRandomStreams.STREAM_ENCOUNTERS, unordered),
			ordered_streams.choose_stable_id(RunRandomStreams.STREAM_ENCOUNTERS, ordered),
			"ordering: encounter draw %d" % draw_index
		)
	var duplicates: Array[StringName] = [&"b", &"a", &"c", &"a"]
	var duplicate_streams: RunRandomStreams = _new_streams(9003)
	var unique_streams: RunRandomStreams = _new_streams(9003)
	for draw_index: int in range(12):
		_expect_equal(
			duplicate_streams.choose_stable_id(RunRandomStreams.STREAM_REWARDS, duplicates),
			unique_streams.choose_stable_id(RunRandomStreams.STREAM_REWARDS, [&"a", &"b", &"c"]),
			"ordering: duplicate stable ids cannot alter draw %d" % draw_index
		)


func test_each_named_stream_is_isolated_from_every_other_stream() -> void:
	for noisy_stream: StringName in EXPECTED_STREAMS:
		var noisy: RunRandomStreams = _new_streams(5004)
		var baseline: RunRandomStreams = _new_streams(5004)
		_draw_sequence(noisy, noisy_stream, 23, 31)
		for observed_stream: StringName in EXPECTED_STREAMS:
			if observed_stream == noisy_stream:
				continue
			_expect_equal(
				_draw_sequence(noisy, observed_stream, 23, 12),
				_draw_sequence(baseline, observed_stream, 23, 12),
				"isolation: %s draws do not alter %s" % [String(noisy_stream), String(observed_stream)]
			)


func test_extra_cosmetic_draws_never_change_gameplay_outcomes() -> void:
	var baseline: RunRandomStreams = _new_streams(5005)
	var cosmetic_noise: RunRandomStreams = _new_streams(5005)
	_draw_sequence(cosmetic_noise, RunRandomStreams.STREAM_COSMETIC, 97, 200)
	for gameplay_stream: StringName in EXPECTED_STREAMS:
		if gameplay_stream == RunRandomStreams.STREAM_COSMETIC:
			continue
		_expect_equal(
			_draw_sequence(cosmetic_noise, gameplay_stream, 31, 24),
			_draw_sequence(baseline, gameplay_stream, 31, 24),
			"cosmetic isolation: %s" % String(gameplay_stream)
		)


func test_different_seed_variation_over_documented_sixty_four_seed_sample() -> void:
	var sequences: Dictionary[String, bool] = {}
	for seed: int in range(1, 65):
		var streams: RunRandomStreams = _new_streams(seed)
		var sequence: Array[int] = _draw_sequence(
			streams,
			RunRandomStreams.STREAM_ENCOUNTERS,
			11,
			8
		)
		sequences[JSON.stringify(sequence)] = true
	_expect_true(
		sequences.size() >= 56,
		"variation: at least 56 unique encounter sequences across seeds 1 through 64 (got %d)" % sequences.size()
	)


func test_stream_state_capture_restore_and_same_seed_reset() -> void:
	var streams: RunRandomStreams = _new_streams(5006)
	_draw_sequence(streams, RunRandomStreams.STREAM_REWARDS, 13, 5)
	var captured: Dictionary[StringName, Dictionary] = streams.capture_states()
	var expected_tail: Array[int] = _draw_sequence(streams, RunRandomStreams.STREAM_REWARDS, 13, 10)
	_expect_true(streams.restore_states(captured), "state: complete snapshot restores")
	_expect_equal(
		_draw_sequence(streams, RunRandomStreams.STREAM_REWARDS, 13, 10),
		expected_tail,
		"state: restored generator reproduces tail"
	)
	streams.reset_for_seed(5006)
	_expect_equal(streams.get_draw_count(RunRandomStreams.STREAM_REWARDS), 0, "state: same-seed reset clears draw count")
	var incomplete: Dictionary[StringName, Dictionary] = captured.duplicate(true)
	incomplete.erase(RunRandomStreams.STREAM_CARDS)
	_expect_false(streams.restore_states(incomplete), "state: incomplete snapshot rejected")


func test_gameplay_scripts_contain_no_unseeded_global_random_calls() -> void:
	var script_paths: Array[String] = []
	_collect_gd_files("res://scripts", script_paths)
	var forbidden: Array[String] = [
		"randi()",
		"randf()",
		"randomize()",
		".shuffle()",
		".pick_random()",
	]
	var violations: Array[String] = []
	for path: String in script_paths:
		var source: String = FileAccess.get_file_as_string(path)
		for token: String in forbidden:
			if source.contains(token):
				violations.append("%s contains %s" % [path, token])
	_expect_true(not script_paths.is_empty(), "global randomness: gameplay scripts discovered")
	_expect_equal(violations, [], "global randomness: no forbidden unseeded calls")


func _new_run_director() -> RunDirector:
	var director: RunDirector = track(RunDirector.new()) as RunDirector
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.name = "RunRandomStreams"
	director.add_child(streams)
	director._ready()
	director.set_process(false)
	return director


func _new_streams(seed: int) -> RunRandomStreams:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams.reset_for_seed(seed)
	return streams


func _draw_sequence(
	streams: RunRandomStreams,
	stream_name: StringName,
	candidate_count: int,
	draws: int
) -> Array[int]:
	var sequence: Array[int] = []
	for draw_index: int in range(draws):
		sequence.append(streams.draw_index(stream_name, candidate_count))
	return sequence


func _collect_gd_files(directory_path: String, output: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child_path: String = directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_gd_files(child_path, output)
		elif entry.ends_with(".gd"):
			output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
	output.sort()


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
