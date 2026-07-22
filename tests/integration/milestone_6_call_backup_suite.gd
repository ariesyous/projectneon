@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.0001
const BACKUP_TUNING: CallBackupDefinition = preload(
	"res://data/interventions/milestone_6_call_backup.tres"
)


class BackupHarness extends RefCounted:
	var active_container: Node2D
	var retired_container: Node2D
	var created_ids: Array[int] = []
	var registered_ids: Array[int] = []
	var removed_ids: Array[int] = []
	var removal_reasons: Array[StringName] = []
	var fail_spawn_index: int = -1
	var fail_registration_attempt: int = -1
	var registration_attempts: int = 0

	func spawn_ally(token: int, ally_index: int) -> Node2D:
		if ally_index == fail_spawn_index:
			return null
		var ally: Node2D = Node2D.new()
		ally.name = "Backup%03d_%d" % [token, ally_index]
		created_ids.append(ally.get_instance_id())
		return ally

	func register_ally(ally: Node2D) -> bool:
		registration_attempts += 1
		if registration_attempts == fail_registration_attempt:
			return false
		active_container.add_child(ally)
		registered_ids.append(ally.get_instance_id())
		return true

	func remove_ally(ally: Node2D, reason: StringName) -> void:
		removed_ids.append(ally.get_instance_id())
		removal_reasons.append(reason)
		if ally.get_parent() != null:
			ally.get_parent().remove_child(ally)
		retired_container.add_child(ally)


class BackupSignalCapture extends RefCounted:
	var accepted_tokens: Array[int] = []
	var accepted_ally_counts: Array[int] = []
	var rejected_reasons: Array[StringName] = []
	var ended_tokens: Array[int] = []
	var ended_reasons: Array[StringName] = []
	var removed_count: int = 0

	func on_accepted(
		activation_token: int,
		allies: Array[Node2D],
		_charges_remaining: int
	) -> void:
		accepted_tokens.append(activation_token)
		accepted_ally_counts.append(allies.size())

	func on_rejected(reason: StringName) -> void:
		rejected_reasons.append(reason)

	func on_ended(activation_token: int, reason: StringName) -> void:
		ended_tokens.append(activation_token)
		ended_reasons.append(reason)

	func on_ally_removed(
		_activation_token: int,
		_ally: Node2D,
		_reason: StringName
	) -> void:
		removed_count += 1


func suite_name() -> String:
	return "milestone_6_call_backup"


func test_authored_call_backup_resource_contract() -> void:
	_expect_equal(BACKUP_TUNING.id, &"call_backup", "backup: stable id")
	_expect_equal(BACKUP_TUNING.display_name, "Call Backup", "backup: exact player-facing name")
	_expect_equal(BACKUP_TUNING.ally_count, 2, "backup: exactly two temporary allies")
	_expect_approx(
		BACKUP_TUNING.active_combat_duration_seconds,
		12.0,
		"backup: exact eligible combat duration"
	)
	_expect_equal(BACKUP_TUNING.initial_charges, 2, "backup: finite authored charges")
	_expect_approx(BACKUP_TUNING.cooldown_seconds, 30.0, "backup: authored cooldown")
	_expect_equal(BACKUP_TUNING.validation_errors(), PackedStringArray(), "backup: resource validates")


func test_invalid_and_unconfigured_requests_are_authoritatively_immutable() -> void:
	var setup: Dictionary = _new_controller()
	var controller: CallBackupController = setup.controller as CallBackupController
	var harness: BackupHarness = setup.harness as BackupHarness
	var capture: BackupSignalCapture = setup.capture as BackupSignalCapture
	controller.set_simulation_enabled(true)
	controller.set_combat_available(true)
	var unconfigured: Dictionary = controller.get_snapshot()
	_expect_false(controller.request_activation(), "backup rejection: unconfigured request")
	_expect_equal(controller.get_snapshot(), unconfigured, "backup rejection: unconfigured ledger immutable")
	_expect_equal(capture.rejected_reasons, [CallBackupController.REASON_UNCONFIGURED], "backup rejection: precise unconfigured reason")
	_configure(controller, harness)
	controller.set_combat_available(false)
	var invalid_state: Dictionary = controller.get_snapshot()
	_expect_false(controller.request_activation(), "backup rejection: travel cannot activate")
	_expect_equal(controller.get_snapshot(), invalid_state, "backup rejection: invalid state immutable")
	_expect_equal(capture.rejected_reasons.back(), CallBackupController.REASON_INVALID_STATE, "backup rejection: precise state reason")
	_expect_equal(harness.created_ids.size(), 0, "backup rejection: invalid requests never invoke factory")


func test_two_allies_use_only_eligible_combat_lifetime_and_expire_exactly_once() -> void:
	var setup: Dictionary = _new_controller()
	var controller: CallBackupController = setup.controller as CallBackupController
	var harness: BackupHarness = setup.harness as BackupHarness
	var capture: BackupSignalCapture = setup.capture as BackupSignalCapture
	_configure(controller, harness)
	controller.set_simulation_enabled(true)
	controller.set_combat_available(true)
	_expect_true(controller.request_activation(), "backup activation: request accepted")
	_expect_equal(capture.accepted_tokens, [1], "backup activation: first stable token")
	_expect_equal(capture.accepted_ally_counts, [2], "backup activation: exactly two refs published")
	_expect_equal(controller.get_active_token(), 1, "backup activation: active token")
	_expect_equal(controller.get_last_accepted_token(), 1, "backup activation: accepted token ledger")
	_expect_equal(controller.get_charges_remaining(), 1, "backup activation: one charge consumed")
	_expect_equal(controller.get_active_allies().size(), 2, "backup activation: two allies tracked")
	_expect_equal(harness.active_container.get_child_count(), 2, "backup activation: two allies registered")
	controller.set_simulation_enabled(false)
	controller.step_eligible_time(8.0)
	_expect_approx(controller.get_active_duration_remaining(), 12.0, "backup lifetime: pause excluded")
	controller.set_simulation_enabled(true)
	controller.set_combat_available(false)
	controller.step_eligible_time(8.0)
	_expect_approx(controller.get_active_duration_remaining(), 12.0, "backup lifetime: travel excluded")
	controller.set_combat_available(true)
	controller.step_eligible_time(11.99)
	_expect_equal(controller.get_active_allies().size(), 2, "backup lifetime: allies remain before edge")
	controller.step_eligible_time(0.02)
	_expect_equal(controller.get_active_token(), -1, "backup lifetime: active token closes")
	_expect_equal(controller.get_active_allies().size(), 0, "backup lifetime: registry clears")
	_expect_equal(harness.active_container.get_child_count(), 0, "backup lifetime: external actors removed")
	_expect_equal(harness.removed_ids.size(), 2, "backup lifetime: each actor removed exactly once")
	_expect_equal(
		harness.removal_reasons,
		[CallBackupController.END_DURATION_EXPIRED, CallBackupController.END_DURATION_EXPIRED],
		"backup lifetime: exact duration reason"
	)
	_expect_equal(capture.removed_count, 2, "backup lifetime: two removal signals")
	_expect_equal(capture.ended_tokens, [1], "backup lifetime: activation ends once")
	_expect_equal(capture.ended_reasons, [CallBackupController.END_DURATION_EXPIRED], "backup lifetime: end reason")
	controller.step_eligible_time(20.0)
	_expect_equal(harness.removed_ids.size(), 2, "backup lifetime: repeated steps cannot remove twice")


func test_defeat_terminal_and_restart_cleanup_are_exact_and_clear_stale_state() -> void:
	var setup: Dictionary = _new_controller()
	var controller: CallBackupController = setup.controller as CallBackupController
	var harness: BackupHarness = setup.harness as BackupHarness
	var capture: BackupSignalCapture = setup.capture as BackupSignalCapture
	_configure(controller, harness)
	controller.set_simulation_enabled(true)
	controller.set_combat_available(true)
	controller.set_cooldown_multiplier(0.8)
	_expect_true(controller.request_activation(), "backup defeat: activation accepted")
	_expect_approx(controller.get_cooldown_duration(), 24.0, "backup defeat: crew modifier applies data-driven cooldown")
	var allies: Array[Node2D] = controller.get_active_allies()
	_expect_true(controller.notify_ally_defeated(allies[0]), "backup defeat: first ally removed")
	_expect_false(controller.notify_ally_defeated(allies[0]), "backup defeat: duplicate notification rejected")
	_expect_equal(controller.get_active_allies().size(), 1, "backup defeat: second ally remains")
	_expect_true(controller.notify_ally_defeated(allies[1]), "backup defeat: second ally removed")
	_expect_equal(controller.get_active_allies().size(), 0, "backup defeat: all defeated clears registry")
	_expect_equal(capture.ended_reasons, [CallBackupController.END_ALLIES_DEFEATED], "backup defeat: exact end reason")
	controller.step_eligible_time(24.0)
	_expect_true(controller.can_activate(), "backup terminal: cooldown completion permits second use")
	_expect_true(controller.request_activation(), "backup terminal: second activation accepted")
	_expect_equal(capture.accepted_tokens, [1, 2], "backup terminal: tokens are monotonic")
	controller.cleanup_for_terminal_state()
	_expect_equal(controller.get_active_allies().size(), 0, "backup terminal: active refs clear")
	_expect_equal(harness.active_container.get_child_count(), 0, "backup terminal: actors leave composition")
	_expect_equal(capture.ended_reasons.back(), CallBackupController.END_TERMINAL, "backup terminal: precise reason")
	_expect_equal(harness.removed_ids.size(), 4, "backup terminal: every spawned actor removed once")
	controller.reset_for_run()
	_expect_equal(controller.get_charges_remaining(), 2, "backup restart: charges restored")
	_expect_equal(controller.get_active_token(), -1, "backup restart: no stale active token")
	_expect_equal(controller.get_last_accepted_token(), -1, "backup restart: accepted ledger cleared")
	_expect_approx(controller.get_cooldown_remaining(), 0.0, "backup restart: cooldown cleared")
	_expect_approx(controller.get_cooldown_duration(), 30.0, "backup restart: crew multiplier cleared")
	_expect_equal(controller.get_active_allies().size(), 0, "backup restart: no stale actor refs")


func test_spawn_and_registration_failures_roll_back_without_consuming_authority() -> void:
	var spawn_setup: Dictionary = _new_controller()
	var spawn_controller: CallBackupController = spawn_setup.controller as CallBackupController
	var spawn_harness: BackupHarness = spawn_setup.harness as BackupHarness
	var spawn_capture: BackupSignalCapture = spawn_setup.capture as BackupSignalCapture
	spawn_harness.fail_spawn_index = 1
	_configure(spawn_controller, spawn_harness)
	spawn_controller.set_simulation_enabled(true)
	spawn_controller.set_combat_available(true)
	var spawn_before: Dictionary = spawn_controller.get_snapshot()
	_expect_false(spawn_controller.request_activation(), "backup transaction: second spawn failure rejected")
	_expect_equal(spawn_controller.get_snapshot(), spawn_before, "backup transaction: spawn failure ledger immutable")
	_expect_equal(spawn_capture.rejected_reasons, [CallBackupController.REASON_SPAWN_FAILED], "backup transaction: spawn reason")
	_expect_equal(spawn_harness.active_container.get_child_count(), 0, "backup transaction: no actor registered")
	_expect_equal(spawn_harness.removed_ids.size(), 1, "backup transaction: first proposed actor rolled back")

	var registration_setup: Dictionary = _new_controller()
	var registration_controller: CallBackupController = registration_setup.controller as CallBackupController
	var registration_harness: BackupHarness = registration_setup.harness as BackupHarness
	var registration_capture: BackupSignalCapture = registration_setup.capture as BackupSignalCapture
	registration_harness.fail_registration_attempt = 2
	_configure(registration_controller, registration_harness)
	registration_controller.set_simulation_enabled(true)
	registration_controller.set_combat_available(true)
	var registration_before: Dictionary = registration_controller.get_snapshot()
	_expect_false(registration_controller.request_activation(), "backup transaction: second registration failure rejected")
	_expect_equal(
		registration_controller.get_snapshot(),
		registration_before,
		"backup transaction: registration failure ledger immutable"
	)
	_expect_equal(
		registration_capture.rejected_reasons,
		[CallBackupController.REASON_REGISTRATION_FAILED],
		"backup transaction: registration reason"
	)
	_expect_equal(registration_harness.active_container.get_child_count(), 0, "backup transaction: registered actor rolled back")
	_expect_equal(registration_harness.removed_ids.size(), 2, "backup transaction: both proposed actors removed")


func test_cooldown_and_exhaustion_rejections_do_not_mutate_ledgers() -> void:
	var setup: Dictionary = _new_controller()
	var controller: CallBackupController = setup.controller as CallBackupController
	var harness: BackupHarness = setup.harness as BackupHarness
	_configure(controller, harness)
	controller.set_simulation_enabled(true)
	controller.set_combat_available(true)
	_expect_true(controller.request_activation(), "backup finite: first use")
	controller.step_eligible_time(12.0)
	var cooldown_snapshot: Dictionary = controller.get_snapshot()
	_expect_equal(controller.get_validity_reason(), CallBackupController.REASON_COOLDOWN, "backup finite: cooldown reason")
	_expect_false(controller.request_activation(), "backup finite: cooldown request rejected")
	_expect_equal(controller.get_snapshot(), cooldown_snapshot, "backup finite: cooldown rejection immutable")
	controller.step_eligible_time(18.0)
	_expect_true(controller.request_activation(), "backup finite: second use after cooldown")
	controller.step_eligible_time(12.0)
	_expect_equal(controller.get_state_name(), CallBackupController.STATE_EXHAUSTED, "backup finite: exhausted state")
	var exhausted_snapshot: Dictionary = controller.get_snapshot()
	_expect_false(controller.request_activation(), "backup finite: exhausted request rejected")
	_expect_equal(controller.get_snapshot(), exhausted_snapshot, "backup finite: exhausted rejection immutable")
	_expect_equal(controller.get_validity_reason(), CallBackupController.REASON_NO_CHARGES, "backup finite: no-charge reason")


func _new_controller() -> Dictionary:
	var host: Node2D = track(Node2D.new()) as Node2D
	var active_container: Node2D = Node2D.new()
	active_container.name = "ActiveBackupAllies"
	var retired_container: Node2D = Node2D.new()
	retired_container.name = "RetiredBackupAllies"
	host.add_child(active_container)
	host.add_child(retired_container)
	var harness: BackupHarness = BackupHarness.new()
	harness.active_container = active_container
	harness.retired_container = retired_container
	var controller: CallBackupController = track(CallBackupController.new()) as CallBackupController
	controller.definition = BACKUP_TUNING
	var capture: BackupSignalCapture = BackupSignalCapture.new()
	controller.activation_accepted.connect(capture.on_accepted)
	controller.activation_rejected.connect(capture.on_rejected)
	controller.activation_ended.connect(capture.on_ended)
	controller.ally_removed.connect(capture.on_ally_removed)
	controller._ready()
	controller.set_process(false)
	return {
		"controller": controller,
		"harness": harness,
		"capture": capture,
	}


func _configure(controller: CallBackupController, harness: BackupHarness) -> void:
	controller.configure(
		Callable(harness, "spawn_ally"),
		Callable(harness, "register_ally"),
		Callable(harness, "remove_ally")
	)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= EPSILON,
		"%s (expected %.6f, got %.6f)" % [context, expected, actual]
	)
