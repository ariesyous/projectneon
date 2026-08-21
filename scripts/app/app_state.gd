@tool
class_name NeonAppState
extends Node

## Scene-independent profile/settings coordinator. Runtime run state, Heat,
## Night Pressure, outcomes, and random streams never live here.

signal profile_ready(profile: PersistentProfileData, status: StringName, read_only: bool)
signal settings_changed(settings: GameSettingsData)
signal unlocks_granted(content_ids: Array[StringName])
signal persistence_rejected(reason: StringName)

const UNLOCK_POLICY: UnlockPolicyDefinition = preload(
	"res://data/persistence/milestone_6_unlock_policy.tres"
)

var development_full_content_access: bool = OS.is_debug_build()
var profile: PersistentProfileData = PersistentProfileData.create_default()
var _save_service: ProfileSaveService = null
var _owns_save_service: bool = false
var _initialized: bool = false


func _ready() -> void:
	if not _initialized:
		initialize()


func initialize(
	service_override: ProfileSaveService = null,
	full_content_access: bool = OS.is_debug_build()
) -> void:
	if _owns_save_service and _save_service != null and is_instance_valid(_save_service):
		_save_service.queue_free()
	_owns_save_service = false
	_save_service = service_override
	if _save_service == null:
		_save_service = get_node_or_null("/root/SaveService") as ProfileSaveService
	if _save_service == null:
		_save_service = ProfileSaveService.new()
		_save_service.name = "LocalSaveService"
		add_child(_save_service)
		_owns_save_service = true
	development_full_content_access = full_content_access
	profile = _save_service.load_profile()
	_initialized = true
	profile_ready.emit(profile, _save_service.last_load_status, _save_service.is_read_only)
	settings_changed.emit(profile.settings)


func reload_profile() -> PersistentProfileData:
	if _save_service == null:
		initialize()
	else:
		profile = _save_service.load_profile()
		profile_ready.emit(profile, _save_service.last_load_status, _save_service.is_read_only)
		settings_changed.emit(profile.settings)
	return profile


func update_settings(settings: GameSettingsData) -> bool:
	if _save_service == null:
		initialize()
	if _save_service.is_read_only:
		persistence_rejected.emit(ProfileSaveService.SAVE_REJECTION_READ_ONLY)
		return false
	var before: PersistentProfileData = profile.duplicate_profile()
	profile.settings = (
		settings.sanitized_copy() if settings != null else GameSettingsData.create_default()
	)
	if not _save_service.save_profile(profile):
		profile = before
		persistence_rejected.emit(ProfileSaveService.SAVE_REJECTION_IO)
		return false
	settings_changed.emit(profile.settings)
	return true


## Call exactly once when RunDirector finalizes a run summary. The two retained
## breadth grants are idempotent; retired crew-rule IDs remain historical only.
func record_completed_run(outcome_id: StringName, elites_defeated: int) -> Array[StringName]:
	var no_grants: Array[StringName] = []
	if _save_service == null:
		initialize()
	if _save_service.is_read_only:
		persistence_rejected.emit(ProfileSaveService.SAVE_REJECTION_READ_ONLY)
		return no_grants
	if not UNLOCK_POLICY.is_valid_outcome(outcome_id):
		persistence_rejected.emit(&"invalid_outcome")
		return no_grants
	var before: PersistentProfileData = profile.duplicate_profile()
	profile.lifetime_statistics.record_completed_run(outcome_id, elites_defeated)
	var granted: Array[StringName] = UNLOCK_POLICY.apply_completed_run(
		profile,
		outcome_id,
		elites_defeated
	)
	if not _save_service.save_profile(profile):
		profile = before
		persistence_rejected.emit(ProfileSaveService.SAVE_REJECTION_IO)
		return no_grants
	if not granted.is_empty():
		unlocks_granted.emit(granted)
	return granted


func reset_profile_for_development() -> PersistentProfileData:
	if _save_service == null:
		initialize()
	profile = _save_service.reset_profile()
	profile_ready.emit(profile, _save_service.last_load_status, _save_service.is_read_only)
	settings_changed.emit(profile.settings)
	return profile


func get_accessible_crew_ids() -> Array[StringName]:
	return profile.get_accessible_crew_ids(development_full_content_access)


func get_accessible_equipment_ids() -> Array[StringName]:
	return profile.get_accessible_equipment_ids(development_full_content_access)


func get_accessible_card_ids() -> Array[StringName]:
	return profile.get_accessible_card_ids(development_full_content_access)


func get_save_service() -> ProfileSaveService:
	return _save_service
