@tool
class_name CallBackupDefinition
extends Resource

## Authored Call Backup rules. The controller owns the finite runtime ledger;
## this Resource contains no mutable run state.

@export var id: StringName = &"call_backup"
@export var display_name: String = "Call Backup"
@export_multiline var description: String = (
	"Deploy two temporary allies. They fight for 12 active combat seconds or until defeated."
)
@export var icon: Texture2D
@export_range(1, 8, 1) var ally_count: int = 2
@export_range(0.1, 120.0, 0.1) var active_combat_duration_seconds: float = 12.0
@export_range(0, 20, 1) var initial_charges: int = 2
@export_range(0.0, 180.0, 0.1) var cooldown_seconds: float = 30.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("Call Backup id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("Call Backup display name must not be empty")
	if description.strip_edges().is_empty():
		errors.append("Call Backup description must not be empty")
	if ally_count != 2:
		errors.append("vertical-slice Call Backup must spawn exactly two allies")
	if active_combat_duration_seconds <= 0.0:
		errors.append("Call Backup duration must be positive")
	if initial_charges <= 0:
		errors.append("Call Backup must have a finite positive charge count")
	if cooldown_seconds < 0.0:
		errors.append("Call Backup cooldown must not be negative")
	return errors
