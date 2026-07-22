@tool
class_name ProfileSaveService
extends Node

## Versioned JSON profile persistence with an injectable path. Tests and tools
## must configure a unique path and never use DEFAULT_PROFILE_PATH.

signal profile_loaded(profile: PersistentProfileData, status: StringName, read_only: bool)
signal profile_saved(profile: PersistentProfileData)
signal save_rejected(reason: StringName)

const DEFAULT_PROFILE_PATH: String = "user://neon_loop_profile_v1.json"
const LOAD_STATUS_NOT_LOADED: StringName = &"not_loaded"
const LOAD_STATUS_LOADED: StringName = &"loaded"
const LOAD_STATUS_MISSING_DEFAULTS: StringName = &"missing_defaults"
const LOAD_STATUS_CORRUPT_DEFAULTS: StringName = &"corrupt_defaults"
const LOAD_STATUS_IO_DEFAULTS: StringName = &"io_defaults"
const LOAD_STATUS_FUTURE_READ_ONLY: StringName = &"future_version_read_only"
const SAVE_REJECTION_READ_ONLY: StringName = &"future_version_read_only"
const SAVE_REJECTION_IO: StringName = &"io_error"

var profile_path: String = DEFAULT_PROFILE_PATH
var last_load_status: StringName = LOAD_STATUS_NOT_LOADED
var last_error_message: String = ""
var is_read_only: bool = false
var current_profile: PersistentProfileData = PersistentProfileData.create_default()


func _init(configured_profile_path: String = DEFAULT_PROFILE_PATH) -> void:
	if not configured_profile_path.strip_edges().is_empty():
		profile_path = configured_profile_path


func configure_profile_path(configured_profile_path: String) -> bool:
	if configured_profile_path.strip_edges().is_empty():
		return false
	profile_path = configured_profile_path
	last_load_status = LOAD_STATUS_NOT_LOADED
	last_error_message = ""
	is_read_only = false
	current_profile = PersistentProfileData.create_default()
	return true


func load_profile() -> PersistentProfileData:
	last_error_message = ""
	is_read_only = false
	if not FileAccess.file_exists(profile_path):
		current_profile = PersistentProfileData.create_default()
		last_load_status = LOAD_STATUS_MISSING_DEFAULTS
		profile_loaded.emit(current_profile, last_load_status, is_read_only)
		return current_profile

	var file: FileAccess = FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		return _recover_defaults(
			LOAD_STATUS_IO_DEFAULTS,
			"could not open configured profile path for reading"
		)
	var source_text: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(source_text)
	if parse_error != OK:
		return _recover_defaults(
			LOAD_STATUS_CORRUPT_DEFAULTS,
			"malformed JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()]
		)
	var raw_root: Variant = parser.data
	if not raw_root is Dictionary:
		return _recover_defaults(
			LOAD_STATUS_CORRUPT_DEFAULTS,
			"profile JSON root must be an object"
		)
	var values: Dictionary = raw_root as Dictionary
	var raw_version: Variant = values.get("save_version", null)
	if not (raw_version is int or raw_version is float):
		return _recover_defaults(
			LOAD_STATUS_CORRUPT_DEFAULTS,
			"profile save_version is missing or invalid"
		)
	var save_version: int = int(raw_version)
	if save_version > PersistentProfileData.SAVE_VERSION:
		is_read_only = true
		last_load_status = LOAD_STATUS_FUTURE_READ_ONLY
		last_error_message = (
			"profile version %d is newer than supported version %d"
			% [save_version, PersistentProfileData.SAVE_VERSION]
		)
		current_profile = PersistentProfileData.from_dictionary(values)
		profile_loaded.emit(current_profile, last_load_status, is_read_only)
		return current_profile
	if save_version != PersistentProfileData.SAVE_VERSION:
		return _recover_defaults(
			LOAD_STATUS_CORRUPT_DEFAULTS,
			"unsupported profile version %d" % save_version
		)
	current_profile = PersistentProfileData.from_dictionary(values)
	last_load_status = LOAD_STATUS_LOADED
	profile_loaded.emit(current_profile, last_load_status, is_read_only)
	return current_profile


func save_profile(profile: PersistentProfileData) -> bool:
	if is_read_only:
		save_rejected.emit(SAVE_REJECTION_READ_ONLY)
		return false
	if profile == null:
		last_error_message = "cannot save a null profile"
		save_rejected.emit(SAVE_REJECTION_IO)
		return false
	var safe_profile: PersistentProfileData = profile.duplicate_profile()
	var source_text: String = JSON.stringify(safe_profile.to_dictionary(), "\t", true)
	if not _atomic_write(source_text + "\n"):
		save_rejected.emit(SAVE_REJECTION_IO)
		return false
	current_profile = safe_profile
	last_error_message = ""
	profile_saved.emit(current_profile)
	return true


## Development-only UI may call this explicit path. It removes only the exact
## configured profile and its own atomic-write siblings, then persists defaults.
func reset_profile() -> PersistentProfileData:
	_remove_if_present(profile_path + ".tmp")
	_remove_if_present(profile_path + ".bak")
	_remove_if_present(profile_path)
	is_read_only = false
	last_error_message = ""
	last_load_status = LOAD_STATUS_MISSING_DEFAULTS
	current_profile = PersistentProfileData.create_default()
	if not save_profile(current_profile):
		last_load_status = LOAD_STATUS_IO_DEFAULTS
	return current_profile


func _recover_defaults(status: StringName, error_message: String) -> PersistentProfileData:
	last_load_status = status
	last_error_message = error_message
	is_read_only = false
	current_profile = PersistentProfileData.create_default()
	profile_loaded.emit(current_profile, last_load_status, is_read_only)
	return current_profile


func _atomic_write(source_text: String) -> bool:
	var absolute_target: String = ProjectSettings.globalize_path(profile_path)
	var absolute_directory: String = absolute_target.get_base_dir()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		last_error_message = "could not create profile directory: error %d" % directory_error
		return false
	var temp_path: String = profile_path + ".tmp"
	var backup_path: String = profile_path + ".bak"
	_remove_if_present(temp_path)
	var temp_file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		last_error_message = "could not open atomic temporary profile for writing"
		return false
	temp_file.store_string(source_text)
	temp_file.flush()
	temp_file.close()
	var absolute_temp: String = ProjectSettings.globalize_path(temp_path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
	var target_existed: bool = FileAccess.file_exists(profile_path)
	if target_existed:
		_remove_if_present(backup_path)
		var backup_error: Error = DirAccess.rename_absolute(absolute_target, absolute_backup)
		if backup_error != OK:
			last_error_message = "could not stage existing profile for atomic replacement"
			_remove_if_present(temp_path)
			return false
	var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_target)
	if replace_error != OK:
		last_error_message = "could not atomically replace configured profile"
		if target_existed and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(absolute_backup, absolute_target)
		_remove_if_present(temp_path)
		return false
	_remove_if_present(backup_path)
	return true


func _remove_if_present(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
