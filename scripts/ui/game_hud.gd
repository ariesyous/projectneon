@tool
class_name GameHUD
extends CanvasLayer

## Presents authoritative run snapshots and forwards player intent. It never
## calculates or owns combat, health, intervention, timing, or reward state.

signal hydrant_activation_requested()
signal hydrant_preview_requested(is_visible: bool)
signal fullscreen_requested()
signal primary_action_requested()
signal extraction_requested()
signal lap_extract_requested(decision_token: int)
signal lap_push_requested(decision_token: int)
signal subway_reroute_requested()
signal backup_activation_requested()
signal environment_activation_requested(
	action_id: StringName,
	expected_context_revision: int,
	request_token: int
)
signal focus_activation_requested(
	target_instance_id: int,
	attack_id: StringName,
	expected_context_revision: int,
	request_token: int
)
signal backup_activation_context_requested(
	expected_context_revision: int,
	request_token: int
)
signal environment_preview_requested(is_visible: bool)
signal shop_cooling_requested(expected_visit_revision: int, expected_source_id: StringName)
signal restart_same_seed_requested()
signal restart_new_seed_requested()
signal equipment_acquisition_requested(
	encounter_instance_id: int,
	choice_token: int,
	choice_index: int,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
)
signal equipment_reward_decline_requested(encounter_instance_id: int, choice_token: int)
signal inventory_preview_requested(
	action: StringName,
	source_area: StringName,
	source_slot: int,
	target_slot: int,
	equipment_id: StringName,
	expected_revision: int
)
signal inventory_swap_requested(
	equipment_slot: int,
	backpack_slot: int,
	expected_revision: int
)
signal inventory_move_requested(
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
)
signal inventory_discard_requested(
	area: StringName,
	slot_index: int,
	equipment_id: StringName,
	expected_revision: int
)
signal district_card_planning_open_requested()
signal district_card_planning_close_requested()
signal district_card_placement_staged(
	card_id: StringName,
	slot_id: StringName,
	hand_revision: int,
	route_revision: int
)
signal district_card_placement_confirm_requested(confirmation_token: int)
signal district_card_placement_cancel_requested(confirmation_token: int)
signal district_plan_choice_requested(
	card_id: StringName,
	offer_revision: int,
	lifecycle_revision: int,
	lap_id: StringName,
	block_id: StringName
)
signal district_card_reward_acquisition_requested(
	encounter_id: int,
	choice_token: int,
	choice_index: int,
	hand_revision: int
)
signal district_card_reward_skip_requested(encounter_id: int, choice_token: int)

enum HydrantPresentationState {
	AVAILABLE,
	UNAVAILABLE,
	COOLING_DOWN,
}

enum DistrictCardPanelMode {
	CLOSED,
	PLANNING,
	REWARD,
}

const RESPONSIBILITY: String = "Run presentation and player input forwarding"
const ONBOARDING_EXPANDED_SECONDS: float = 12.0
const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const MAX_SAFE_INSET: Vector2 = Vector2(32.0, 24.0)
const HYDRANT_PANEL_BASE_POSITION: Vector2 = Vector2(990.0, 270.0)
const HELP_PANEL_BASE_POSITION: Vector2 = Vector2(280.0, 500.0)
const HELP_BUTTON_BASE_POSITION: Vector2 = Vector2(20.0, 652.0)
const FULLSCREEN_BUTTON_BASE_POSITION: Vector2 = Vector2(140.0, 652.0)
const LAB_PURPOSE_BASE_POSITION: Vector2 = Vector2(20.0, 620.0)
const HYDRANT_READY_COLOR: Color = Color("72f0d0")
const HYDRANT_UNAVAILABLE_COLOR: Color = Color("ffbf69")
const HYDRANT_COOLDOWN_COLOR: Color = Color("a987ff")
const DISTRICT_CARD_HAND_CAPACITY: int = 3
const DISTRICT_ROUTE_SLOT_COUNT: int = 5

const ICON_HEALTH: Texture2D = preload("res://assets/ui/icons/wp01/health.svg")
const ICON_HEAT: Texture2D = preload("res://assets/ui/icons/wp01/heat.svg")
const ICON_PRESSURE: Texture2D = preload("res://assets/ui/icons/wp01/pressure.svg")
const ICON_COINS: Texture2D = preload("res://assets/ui/icons/wp01/coins.svg")
const ICON_PHASE_PLAN: Texture2D = preload("res://assets/ui/icons/wp01/phase_plan.svg")
const ICON_PHASE_FIGHT: Texture2D = preload("res://assets/ui/icons/wp01/phase_fight.svg")
const ICON_PHASE_REWARD: Texture2D = preload("res://assets/ui/icons/wp01/phase_reward.svg")
const ICON_PHASE_SHOP: Texture2D = preload("res://assets/ui/icons/wp01/phase_shop.svg")
const ICON_PHASE_EXTRACT: Texture2D = preload("res://assets/ui/icons/wp01/phase_extract.svg")
const ICON_PHASE_RESULT: Texture2D = preload("res://assets/ui/icons/wp01/phase_result.svg")
const ICON_ENVIRONMENT: Texture2D = preload("res://assets/ui/icons/wp01/environment.svg")
const ICON_FOCUS: Texture2D = preload("res://assets/ui/icons/wp01/focus.svg")
const ICON_BACKUP: Texture2D = preload("res://assets/ui/icons/wp01/backup.svg")
const ICON_CONFIRM: Texture2D = preload("res://assets/ui/icons/wp01/confirm.svg")
const ICON_POWER_BOX: Texture2D = preload(
	"res://assets/icons/interventions/power_box.svg"
)

@onready var timer_label: Label = $Root/RunStatusPanel/TimerLabel
@onready var root_control: Control = $Root
@onready var minimap_panel: Panel = $Root/MinimapPanel
@onready var run_status_panel: Panel = $Root/RunStatusPanel
@onready var resources_panel: Panel = $Root/ResourcesPanel
@onready var crew_panel: Panel = $Root/CrewPanel
@onready var build_panel: Panel = $Root/BuildPanel
@onready var cards_panel: Panel = $Root/CardsPanel
@onready var heat_label: Label = $Root/RunStatusPanel/HeatLabel
@onready var heat_meter: ProgressBar = $Root/RunStatusPanel/HeatMeter
@onready var night_pressure_label: Label = $Root/RunStatusPanel/NightPressureLabel
@onready var night_pressure_meter: ProgressBar = $Root/RunStatusPanel/NightPressureMeter
@onready var threshold_label: Label = $Root/RunStatusPanel/ThresholdLabel
@onready var route_title: Label = $Root/MinimapPanel/Title
@onready var route_label: Label = $Root/MinimapPanel/Route
@onready var resource_values: Label = $Root/ResourcesPanel/Values
@onready var crew_state_label: Label = $Root/CrewPanel/CrewState
@onready var health_meter: ProgressBar = $Root/CrewPanel/HealthMeter
@onready var health_label: Label = $Root/CrewPanel/HealthLabel
@onready var crew_status_label: Label = $Root/CrewPanel/StatusLabel

@onready var hydrant_state_label: Label = $Root/InterventionsPanel/StateLabel
@onready var hydrant_button: Button = $Root/InterventionsPanel/HydrantButton
@onready var hydrant_cooldown_meter: ProgressBar = $Root/InterventionsPanel/CooldownMeter
@onready var hydrant_cooldown_label: Label = $Root/InterventionsPanel/CooldownLabel
@onready var hydrant_feedback_label: Label = $Root/InterventionsPanel/FeedbackLabel
@onready var interventions_panel: Panel = $Root/InterventionsPanel

@onready var help_panel: Panel = $Root/HelpPanel
@onready var help_button: Button = $Root/HelpButton
@onready var fullscreen_button: Button = $Root/FullscreenButton
@onready var lab_purpose_label: Label = $Root/LabPurpose
@onready var audio_unlock_panel: Panel = $Root/AudioUnlockPanel
@onready var audio_unlock_label: Label = $Root/AudioUnlockPanel/Label
@onready var landscape_panel: Panel = $Root/LandscapePanel
@onready var run_actions_title: Label = $Root/CardsPanel/Title
@onready var primary_action_button: Button = $Root/CardsPanel/Card01
@onready var backup_button: Button = $Root/CardsPanel/BackupButton
@onready var subway_reroute_button: Button = $Root/CardsPanel/Card02
@onready var shop_cooling_button: Button = $Root/CardsPanel/Card03
@onready var district_card_compact_panel: Panel = (
	$Root/CardsPanel/DistrictCardCompactPanel
)
@onready var district_card_compact_summary: Label = (
	$Root/CardsPanel/DistrictCardCompactPanel/Summary
)
@onready var district_card_open_button: Button = (
	$Root/CardsPanel/DistrictCardCompactPanel/OpenCards
)
@onready var district_card_panel: Panel = $Root/DistrictCardPanel
@onready var district_card_title: Label = $Root/DistrictCardPanel/Title
@onready var district_card_counts: Label = $Root/DistrictCardPanel/Counts
@onready var district_card_close_button: Button = $Root/DistrictCardPanel/Close
@onready var district_card_choice_01: DistrictCardDragSlot = $Root/DistrictCardPanel/Choice01
@onready var district_card_choice_02: DistrictCardDragSlot = $Root/DistrictCardPanel/Choice02
@onready var district_card_choice_03: DistrictCardDragSlot = $Root/DistrictCardPanel/Choice03
@onready var district_card_choice_icon_01: TextureRect = $Root/DistrictCardPanel/Choice01/Icon
@onready var district_card_choice_icon_02: TextureRect = $Root/DistrictCardPanel/Choice02/Icon
@onready var district_card_choice_icon_03: TextureRect = $Root/DistrictCardPanel/Choice03/Icon
@onready var district_card_choice_details_01: Label = $Root/DistrictCardPanel/Choice01/Details
@onready var district_card_choice_details_02: Label = $Root/DistrictCardPanel/Choice02/Details
@onready var district_card_choice_details_03: Label = $Root/DistrictCardPanel/Choice03/Details
@onready var district_card_instruction: Label = $Root/DistrictCardPanel/Instruction
@onready var district_route_slot_01: DistrictCardDragSlot = $Root/DistrictCardPanel/RouteSlot01
@onready var district_route_slot_02: DistrictCardDragSlot = $Root/DistrictCardPanel/RouteSlot02
@onready var district_route_slot_03: DistrictCardDragSlot = $Root/DistrictCardPanel/RouteSlot03
@onready var district_route_slot_04: DistrictCardDragSlot = $Root/DistrictCardPanel/RouteSlot04
@onready var district_route_slot_05: DistrictCardDragSlot = $Root/DistrictCardPanel/RouteSlot05
@onready var district_card_route_preview: Label = $Root/DistrictCardPanel/RoutePreview
@onready var district_card_feedback: Label = $Root/DistrictCardPanel/Feedback
@onready var district_card_skip_button: Button = $Root/DistrictCardPanel/SkipKeepHand
@onready var district_card_confirm_button: Button = $Root/DistrictCardPanel/Confirm
@onready var district_card_cancel_button: Button = $Root/DistrictCardPanel/Cancel
@onready var extraction_panel: Panel = $Root/ExtractionPanel
@onready var extraction_button: Button = $Root/ExtractionPanel/ExtractionButton
@onready var summary_panel: Panel = $Root/RunSummaryPanel
@onready var summary_title: Label = $Root/RunSummaryPanel/Title
@onready var summary_details: Label = $Root/RunSummaryPanel/Details
@onready var summary_same_seed_button: Button = $Root/RunSummaryPanel/RestartSameSeed
@onready var summary_new_seed_button: Button = $Root/RunSummaryPanel/RestartNewSeed
@onready var boss_trigger_panel: Panel = $Root/BossTriggerPanel
@onready var boss_same_seed_button: Button = $Root/BossTriggerPanel/RestartSameSeed
@onready var boss_new_seed_button: Button = $Root/BossTriggerPanel/RestartNewSeed
@onready var auto_help_label: Label = $Root/HelpPanel/AutoHelp
@onready var build_title_button: LinkButton = $Root/BuildPanel/Title
@onready var build_slot_01: LinkButton = $Root/BuildPanel/Slot01
@onready var build_slot_02: LinkButton = $Root/BuildPanel/Slot02
@onready var build_slot_03: LinkButton = $Root/BuildPanel/Slot03
@onready var build_details_panel: Panel = $Root/BuildDetailsPanel
@onready var build_details_close: Button = $Root/BuildDetailsPanel/Close
@onready var equipment_details_label: Label = $Root/BuildDetailsPanel/EquipmentDetails
@onready var synergy_details_label: Label = $Root/BuildDetailsPanel/SynergyDetails
@onready var backpack_title_label: Label = $Root/BuildDetailsPanel/BackpackTitle
@onready var synergy_badge_01: TextureRect = $Root/BuildDetailsPanel/SynergyBadge01
@onready var synergy_badge_02: TextureRect = $Root/BuildDetailsPanel/SynergyBadge02
@onready var synergy_badge_03: TextureRect = $Root/BuildDetailsPanel/SynergyBadge03
@onready var equipped_inventory_01: EquipmentDragSlot = $Root/BuildDetailsPanel/Equipped01
@onready var equipped_inventory_02: EquipmentDragSlot = $Root/BuildDetailsPanel/Equipped02
@onready var equipped_inventory_03: EquipmentDragSlot = $Root/BuildDetailsPanel/Equipped03
@onready var backpack_inventory_01: EquipmentDragSlot = $Root/BuildDetailsPanel/Backpack01
@onready var backpack_inventory_02: EquipmentDragSlot = $Root/BuildDetailsPanel/Backpack02
@onready var backpack_inventory_03: EquipmentDragSlot = $Root/BuildDetailsPanel/Backpack03
@onready var inventory_action_01: Button = $Root/BuildDetailsPanel/ActionTarget01
@onready var inventory_action_02: Button = $Root/BuildDetailsPanel/ActionTarget02
@onready var inventory_action_03: Button = $Root/BuildDetailsPanel/ActionTarget03
@onready var inventory_action_prompt: Label = $Root/BuildDetailsPanel/ActionPrompt
@onready var inventory_discard_button: Button = $Root/BuildDetailsPanel/Discard
@onready var inventory_confirm_button: Button = $Root/BuildDetailsPanel/Confirm
@onready var inventory_cancel_button: Button = $Root/BuildDetailsPanel/Cancel
@onready var equipment_reward_panel: Panel = $Root/EquipmentRewardPanel
@onready var reward_target_01: EquipmentDragSlot = $Root/EquipmentRewardPanel/Target01
@onready var reward_target_02: EquipmentDragSlot = $Root/EquipmentRewardPanel/Target02
@onready var reward_target_03: EquipmentDragSlot = $Root/EquipmentRewardPanel/Target03
@onready var reward_store_01: EquipmentDragSlot = $Root/EquipmentRewardPanel/Store01
@onready var reward_store_02: EquipmentDragSlot = $Root/EquipmentRewardPanel/Store02
@onready var reward_store_03: EquipmentDragSlot = $Root/EquipmentRewardPanel/Store03
@onready var reward_pack_target_label: Label = $Root/EquipmentRewardPanel/PackTargetLabel
@onready var reward_pack_target_01: Button = $Root/EquipmentRewardPanel/PackTarget01
@onready var reward_pack_target_02: Button = $Root/EquipmentRewardPanel/PackTarget02
@onready var reward_pack_target_03: Button = $Root/EquipmentRewardPanel/PackTarget03
@onready var reward_choice_01: EquipmentDragSlot = $Root/EquipmentRewardPanel/Choice01
@onready var reward_choice_02: EquipmentDragSlot = $Root/EquipmentRewardPanel/Choice02
@onready var reward_choice_03: EquipmentDragSlot = $Root/EquipmentRewardPanel/Choice03
@onready var reward_choice_icon_01: TextureRect = $Root/EquipmentRewardPanel/Choice01/Icon
@onready var reward_choice_icon_02: TextureRect = $Root/EquipmentRewardPanel/Choice02/Icon
@onready var reward_choice_icon_03: TextureRect = $Root/EquipmentRewardPanel/Choice03/Icon
@onready var reward_choice_details_01: Label = $Root/EquipmentRewardPanel/Choice01/Details
@onready var reward_choice_details_02: Label = $Root/EquipmentRewardPanel/Choice02/Details
@onready var reward_choice_details_03: Label = $Root/EquipmentRewardPanel/Choice03/Details
@onready var reward_instruction_label: Label = $Root/EquipmentRewardPanel/Instruction
@onready var reward_confirmation_label: Label = $Root/EquipmentRewardPanel/Confirmation
@onready var reward_confirm_button: Button = $Root/EquipmentRewardPanel/Confirm
@onready var reward_cancel_button: Button = $Root/EquipmentRewardPanel/Cancel
@onready var reward_keep_current_button: Button = $Root/EquipmentRewardPanel/KeepCurrent

var phase_banner: NeonPhaseBanner = null
var action_toast: NeonToast = null
var build_callout: NeonBuildCallout = null
var shop_decision_panel: Panel = null
var shop_cooling_choice: NeonChoiceCard = null
var shop_leave_choice: NeonChoiceCard = null
var shop_comparison: NeonStatComparison = null
var shop_plan_button: Button = null
var focus_placeholder_button: NeonInterventionButton = null
var extraction_continue_button: NeonChoiceCard = null
var extraction_plan_button: Button = null
var extraction_title: Label = null
var extraction_instruction: Label = null
var extraction_preview: NeonStatComparison = null
var _health_icon: TextureRect = null
var _heat_icon: TextureRect = null
var _pressure_icon: TextureRect = null
var _coins_icon: TextureRect = null

var _onboarding_remaining: float = ONBOARDING_EXPANDED_SECONDS
var _hydrant_state: int = HydrantPresentationState.UNAVAILABLE
var _hydrant_cooldown_remaining: float = 0.0
var _hydrant_cooldown_total: float = 1.0
var _hydrant_valid_enemy_count: int = 0
var _hydrant_feedback: String = "NO ENEMY IN RANGE"
var _fullscreen_active: bool = false
var _audio_unlock_completed: bool = false
var _pending_safe_area: Rect2i = Rect2i()
var _pending_window_size: Vector2i = Vector2i.ZERO
var _scrap_total: int = 0
var _last_run_snapshot: Dictionary = {}
var _last_flow_state: int = -1
var _build_snapshot: Dictionary = {}
var _build_slot_buttons: Array[LinkButton] = []
var _equipped_inventory_buttons: Array[EquipmentDragSlot] = []
var _backpack_inventory_buttons: Array[EquipmentDragSlot] = []
var _inventory_action_buttons: Array[Button] = []
var _synergy_badges: Array[TextureRect] = []
var _reward_target_buttons: Array[EquipmentDragSlot] = []
var _reward_store_buttons: Array[EquipmentDragSlot] = []
var _reward_pack_target_buttons: Array[Button] = []
var _reward_choice_buttons: Array[EquipmentDragSlot] = []
var _reward_choice_icons: Array[TextureRect] = []
var _reward_choice_details: Array[Label] = []
var _reward_choices: Array[EquipmentDefinition] = []
var _reward_previews_by_choice: Array[Dictionary] = []
var _reward_encounter_id: int = -1
var _reward_choice_token: int = -1
var _standard_reward_preview: Dictionary = {}
var _selected_reward_choice: int = -1
var _selected_reward_destination: StringName = &""
var _selected_reward_slot: int = -1
var _selected_reward_backpack_slot: int = -1
var _selected_reward_outgoing_backpack_slot: int = -1
var _equipment_choice_in_flight: bool = false
var _reward_drag_active: bool = false
var _selected_inventory_area: StringName = &""
var _selected_inventory_slot: int = -1
var _selected_inventory_id: StringName = &""
var _pending_inventory_action: StringName = &""
var _pending_inventory_target: int = -1
var _pending_inventory_preview: Dictionary = {}
var _inventory_action_in_flight: bool = false
var _inventory_management_enabled: bool = false
var _district_card_snapshot: Dictionary = {}
var _district_patrol_snapshot: Dictionary = {}
var _district_loop_snapshot: Dictionary = {}
var _district_card_hand: Array[DistrictCardDefinition] = []
var _district_card_choices: Array[DistrictCardDefinition] = []
var _district_route_slots: Array[Dictionary] = []
var _district_card_choice_buttons: Array[DistrictCardDragSlot] = []
var _district_card_choice_icons: Array[TextureRect] = []
var _district_card_choice_details: Array[Label] = []
var _district_route_slot_buttons: Array[DistrictCardDragSlot] = []
var _district_card_panel_mode: int = DistrictCardPanelMode.CLOSED
var _district_card_hand_revision: int = -1
var _district_card_route_revision: int = -1
var _district_card_planning_allowed: bool = false
var _district_selected_card_index: int = -1
var _district_selected_card_id: StringName = &""
var _district_selected_slot_id: StringName = &""
var _district_confirmation_token: int = -1
var _district_card_reward_encounter_id: int = -1
var _district_card_reward_choice_token: int = -1
var _district_card_reward_can_skip: bool = true
var _district_card_action_in_flight: bool = false
var _district_card_stage_in_flight: bool = false
var _district_card_drag_cancelled: bool = false
var _focused_district_plan: bool = false
var _district_plan_offer_revision: int = -1
var _district_plan_lifecycle_revision: int = -1
var _district_plan_lap_id: StringName = &""
var _district_plan_block_id: StringName = &""
var _crew_display_name: String = "JAX"
var _backup_snapshot: Dictionary = {}
var _environment_snapshot: Dictionary = {}
var _focus_snapshot: Dictionary = {}
var _shop_snapshot: Dictionary = {}
var _last_shop_purchase_result: Dictionary = {}
var _route_journey_text: String = (
	"HIDEOUT>PATROL>FIGHT\nGEAR>EXIT/BOSS\nN0 00% L0 > PATROL"
)


func _ready() -> void:
	root_control.theme = NeonUiTokens.create_theme()
	_install_wp01_components()
	hydrant_button.pressed.connect(_on_hydrant_button_pressed)
	hydrant_button.mouse_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.mouse_exited.connect(_on_hydrant_preview_exited)
	hydrant_button.focus_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.focus_exited.connect(_on_hydrant_preview_exited)
	help_button.pressed.connect(_toggle_help)
	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	primary_action_button.pressed.connect(_on_primary_action_pressed)
	backup_button.pressed.connect(_on_backup_pressed)
	subway_reroute_button.pressed.connect(_on_subway_reroute_pressed)
	shop_cooling_button.pressed.connect(_on_shop_cooling_pressed)
	extraction_button.pressed.connect(_on_extraction_pressed)
	shop_cooling_choice.pressed.connect(_on_shop_cooling_pressed)
	shop_leave_choice.pressed.connect(_on_primary_action_pressed)
	extraction_continue_button.pressed.connect(_on_extraction_continue_pressed)
	shop_plan_button.pressed.connect(_on_district_card_open_pressed)
	extraction_plan_button.pressed.connect(_on_district_card_open_pressed)
	summary_same_seed_button.pressed.connect(_on_restart_same_seed_pressed)
	summary_new_seed_button.pressed.connect(_on_restart_new_seed_pressed)
	boss_same_seed_button.pressed.connect(_on_restart_same_seed_pressed)
	boss_new_seed_button.pressed.connect(_on_restart_new_seed_pressed)
	_build_slot_buttons = [build_slot_01, build_slot_02, build_slot_03]
	_equipped_inventory_buttons = [
		equipped_inventory_01,
		equipped_inventory_02,
		equipped_inventory_03,
	]
	_backpack_inventory_buttons = [
		backpack_inventory_01,
		backpack_inventory_02,
		backpack_inventory_03,
	]
	_inventory_action_buttons = [inventory_action_01, inventory_action_02, inventory_action_03]
	_synergy_badges = [synergy_badge_01, synergy_badge_02, synergy_badge_03]
	_reward_target_buttons = [reward_target_01, reward_target_02, reward_target_03]
	_reward_store_buttons = [reward_store_01, reward_store_02, reward_store_03]
	_reward_pack_target_buttons = [
		reward_pack_target_01,
		reward_pack_target_02,
		reward_pack_target_03,
	]
	_reward_choice_buttons = [reward_choice_01, reward_choice_02, reward_choice_03]
	_reward_choice_icons = [reward_choice_icon_01, reward_choice_icon_02, reward_choice_icon_03]
	_reward_choice_details = [
		reward_choice_details_01,
		reward_choice_details_02,
		reward_choice_details_03,
	]
	_district_card_choice_buttons = [
		district_card_choice_01,
		district_card_choice_02,
		district_card_choice_03,
	]
	_district_card_choice_icons = [
		district_card_choice_icon_01,
		district_card_choice_icon_02,
		district_card_choice_icon_03,
	]
	_district_card_choice_details = [
		district_card_choice_details_01,
		district_card_choice_details_02,
		district_card_choice_details_03,
	]
	_district_route_slot_buttons = [
		district_route_slot_01,
		district_route_slot_02,
		district_route_slot_03,
		district_route_slot_04,
		district_route_slot_05,
	]
	build_title_button.pressed.connect(_toggle_build_details)
	build_details_close.pressed.connect(_toggle_build_details)
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		_build_slot_buttons[slot_index].pressed.connect(
			_on_equipment_slot_pressed.bind(slot_index)
		)
		_equipped_inventory_buttons[slot_index].pressed.connect(
			_on_inventory_item_pressed.bind(SynergySystem.AREA_EQUIPPED, slot_index)
		)
		_equipped_inventory_buttons[slot_index].equipment_drag_started.connect(
			_on_equipment_drag_started
		)
		_equipped_inventory_buttons[slot_index].equipment_drag_ended.connect(
			_on_equipment_drag_ended
		)
		_equipped_inventory_buttons[slot_index].equipment_drop_requested.connect(
			_on_inventory_drag_drop
		)
		_backpack_inventory_buttons[slot_index].pressed.connect(
			_on_inventory_item_pressed.bind(SynergySystem.AREA_BACKPACK, slot_index)
		)
		_backpack_inventory_buttons[slot_index].equipment_drag_started.connect(
			_on_equipment_drag_started
		)
		_backpack_inventory_buttons[slot_index].equipment_drag_ended.connect(
			_on_equipment_drag_ended
		)
		_backpack_inventory_buttons[slot_index].equipment_drop_requested.connect(
			_on_inventory_drag_drop
		)
		_inventory_action_buttons[slot_index].pressed.connect(
			_on_inventory_action_target_pressed.bind(slot_index)
		)
		_reward_target_buttons[slot_index].pressed.connect(
			_on_reward_target_pressed.bind(slot_index)
		)
		_reward_target_buttons[slot_index].equipment_drop_requested.connect(
			_on_reward_drag_drop
		)
		_reward_store_buttons[slot_index].pressed.connect(
			_on_reward_store_pressed.bind(slot_index)
		)
		_reward_store_buttons[slot_index].equipment_drop_requested.connect(
			_on_reward_drag_drop
		)
		_reward_pack_target_buttons[slot_index].pressed.connect(
			_on_reward_pack_target_pressed.bind(slot_index)
		)
		_reward_choice_buttons[slot_index].pressed.connect(
			_on_reward_choice_pressed.bind(slot_index)
		)
		_reward_choice_buttons[slot_index].equipment_drag_started.connect(
			_on_equipment_drag_started
		)
		_reward_choice_buttons[slot_index].equipment_drag_ended.connect(
			_on_equipment_drag_ended
		)
		_district_card_choice_buttons[slot_index].pressed.connect(
			_on_district_card_choice_pressed.bind(slot_index)
		)
		_district_card_choice_buttons[slot_index].district_card_drag_started.connect(
			_on_district_card_drag_started
		)
		_district_card_choice_buttons[slot_index].district_card_drag_ended.connect(
			_on_district_card_drag_ended
		)
	for slot_index: int in range(DISTRICT_ROUTE_SLOT_COUNT):
		_district_route_slot_buttons[slot_index].pressed.connect(
			_on_district_route_slot_pressed.bind(slot_index)
		)
		_district_route_slot_buttons[slot_index].district_card_drop_requested.connect(
			_on_district_card_drop_requested
		)
	inventory_discard_button.pressed.connect(_on_inventory_discard_pressed)
	inventory_confirm_button.pressed.connect(_on_inventory_confirm_pressed)
	inventory_cancel_button.pressed.connect(_clear_inventory_pending_action)
	reward_confirm_button.pressed.connect(_on_reward_confirm_pressed)
	reward_cancel_button.pressed.connect(_clear_reward_selection)
	reward_keep_current_button.pressed.connect(_on_reward_keep_current_pressed)
	district_card_open_button.pressed.connect(_on_district_card_open_pressed)
	district_card_close_button.pressed.connect(_on_district_card_close_pressed)
	district_card_confirm_button.pressed.connect(_on_district_card_confirm_pressed)
	district_card_cancel_button.pressed.connect(_on_district_card_cancel_pressed)
	district_card_skip_button.pressed.connect(_on_district_card_skip_pressed)
	_apply_wp01_visual_language()
	NeonUiTokens.apply_accessibility_defaults(root_control)
	help_panel.visible = true
	summary_panel.visible = false
	boss_trigger_panel.visible = false
	audio_unlock_panel.visible = false
	landscape_panel.visible = false
	build_details_panel.visible = false
	equipment_reward_panel.visible = false
	district_card_panel.visible = false
	shop_decision_panel.visible = false
	$Root/ExtractionPanel.visible = false
	_refresh_hydrant_presentation()
	_refresh_fullscreen_presentation()
	_refresh_district_card_compact_presentation()
	_refresh_safe_area_layout()


func _install_wp01_components() -> void:
	phase_banner = NeonPhaseBanner.new()
	phase_banner.name = "PhaseBanner"
	phase_banner.z_index = 8
	root_control.add_child(phase_banner)

	action_toast = NeonToast.new()
	action_toast.name = "ActionToast"
	action_toast.z_index = 70
	root_control.add_child(action_toast)

	build_callout = NeonBuildCallout.new()
	build_callout.name = "BuildCallout"
	build_callout.z_index = 69
	root_control.add_child(build_callout)

	_health_icon = _new_icon("HealthIcon", ICON_HEALTH)
	crew_panel.add_child(_health_icon)
	_heat_icon = _new_icon("HeatIcon", ICON_HEAT)
	run_status_panel.add_child(_heat_icon)
	_pressure_icon = _new_icon("PressureIcon", ICON_PRESSURE)
	run_status_panel.add_child(_pressure_icon)
	_coins_icon = _new_icon("CoinsIcon", ICON_COINS)
	resources_panel.add_child(_coins_icon)

	focus_placeholder_button = NeonInterventionButton.new()
	focus_placeholder_button.name = "FocusAction"
	focus_placeholder_button.icon = ICON_FOCUS
	focus_placeholder_button.expand_icon = true
	focus_placeholder_button.add_theme_constant_override(&"icon_max_width", 32)
	focus_placeholder_button.tooltip_text = (
		"Focus temporarily prioritizes one named live enemy intent. "
		+ "It never directly moves crew or orders an attack."
	)
	focus_placeholder_button.present(
		"2 FOCUS",
		"PRIORITY",
		"NO TELEGRAPH",
		NeonInterventionButton.VisualState.UNAVAILABLE,
		true
	)
	focus_placeholder_button.pressed.connect(_on_wp05_focus_pressed)
	cards_panel.add_child(focus_placeholder_button)

	shop_decision_panel = Panel.new()
	shop_decision_panel.name = "ShopDecisionPanel"
	shop_decision_panel.z_index = 34
	shop_decision_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_decision_panel.theme_type_variation = &"DecisionPanel"
	root_control.add_child(shop_decision_panel)
	shop_decision_panel.add_child(_new_label(
		"Title",
		"SHOP  /  CONVENIENCE STORE",
		&"EyebrowLabel",
		Rect2(32.0, 24.0, 680.0, 28.0)
	))
	shop_decision_panel.add_child(_new_label(
		"Instruction",
		"One purchase from existing finite stock, or leave for the next route block.",
		&"HeadingLabel",
		Rect2(32.0, 58.0, 968.0, 68.0),
		true
	))
	shop_plan_button = Button.new()
	shop_plan_button.name = "OpenDistrictPlan"
	shop_plan_button.text = "DISTRICT PLAN"
	shop_plan_button.theme_type_variation = &"SecondaryButton"
	shop_decision_panel.add_child(shop_plan_button)
	shop_cooling_choice = NeonChoiceCard.new()
	shop_cooling_choice.name = "CoolDistrict"
	shop_cooling_choice.text = "COOL THE DISTRICT\nFINITE STOCK  /  EXACT COST"
	shop_cooling_choice.icon = ICON_HEAT
	shop_cooling_choice.expand_icon = true
	shop_cooling_choice.add_theme_constant_override(&"icon_max_width", 42)
	shop_decision_panel.add_child(shop_cooling_choice)
	shop_leave_choice = NeonChoiceCard.new()
	shop_leave_choice.name = "LeaveShop"
	shop_leave_choice.text = "LEAVE SHOP\nKEEP COINS  /  CONTINUE ROUTE"
	shop_leave_choice.icon = ICON_PHASE_SHOP
	shop_leave_choice.expand_icon = true
	shop_leave_choice.add_theme_constant_override(&"icon_max_width", 42)
	shop_decision_panel.add_child(shop_leave_choice)
	shop_comparison = NeonStatComparison.new()
	shop_comparison.name = "StatComparison"
	shop_decision_panel.add_child(shop_comparison)
	shop_decision_panel.add_child(_new_label(
		"AuthorityNote",
		"Night Pressure is irreversible. Buying changes Heat only after authority accepts the purchase.",
		&"MutedLabel",
		Rect2(32.0, 490.0, 968.0, 44.0),
		true
	))

	extraction_title = _new_label(
		"Title",
		"EXTRACTION AVAILABLE",
		&"EyebrowLabel",
		Rect2(32.0, 24.0, 680.0, 28.0)
	)
	extraction_panel.add_child(extraction_title)
	extraction_instruction = _new_label(
		"Instruction",
		"Secure the current result or continue the existing route at greater Heat.",
		&"HeadingLabel",
		Rect2(32.0, 58.0, 968.0, 68.0),
		true
	)
	extraction_panel.add_child(extraction_instruction)
	extraction_plan_button = Button.new()
	extraction_plan_button.name = "OpenDistrictPlan"
	extraction_plan_button.text = "DISTRICT PLAN"
	extraction_plan_button.theme_type_variation = &"SecondaryButton"
	extraction_panel.add_child(extraction_plan_button)
	extraction_continue_button = NeonChoiceCard.new()
	extraction_continue_button.name = "ContinueRun"
	extraction_continue_button.text = "PUSH ON  /  CONTINUE RUN\n+6 HEAT  /  NIGHT PRESSURE CONTINUES"
	extraction_continue_button.icon = ICON_PHASE_FIGHT
	extraction_continue_button.expand_icon = true
	extraction_continue_button.add_theme_constant_override(&"icon_max_width", 48)
	extraction_panel.add_child(extraction_continue_button)
	extraction_preview = NeonStatComparison.new()
	extraction_preview.name = "ConsequencePreview"
	extraction_panel.add_child(extraction_preview)


func _apply_wp01_visual_language() -> void:
	_clear_legacy_theme_overrides(root_control)
	minimap_panel.visible = false
	_set_rect(phase_banner, Rect2(20.0, 16.0, 744.0, 92.0))
	_set_rect(run_status_panel, Rect2(776.0, 16.0, 292.0, 92.0))
	_set_rect(resources_panel, Rect2(1080.0, 16.0, 180.0, 92.0))
	_set_rect(crew_panel, Rect2(20.0, 122.0, 270.0, 144.0))
	_set_rect(build_panel, Rect2(990.0, 122.0, 270.0, 144.0))
	_set_rect(cards_panel, Rect2(280.0, 600.0, 980.0, 104.0))
	_set_rect(interventions_panel, Rect2(HYDRANT_PANEL_BASE_POSITION, Vector2(270.0, 226.0)))
	_set_rect(help_panel, Rect2(HELP_PANEL_BASE_POSITION, Vector2(748.0, 188.0)))
	_set_rect(help_button, Rect2(HELP_BUTTON_BASE_POSITION, Vector2(110.0, 52.0)))
	_set_rect(fullscreen_button, Rect2(FULLSCREEN_BUTTON_BASE_POSITION, Vector2(130.0, 52.0)))
	lab_purpose_label.visible = false

	run_status_panel.theme_type_variation = &"SurfacePanel"
	resources_panel.theme_type_variation = &"SurfacePanel"
	crew_panel.theme_type_variation = &"RaisedPanel"
	build_panel.theme_type_variation = &"RaisedPanel"
	cards_panel.theme_type_variation = &"SurfacePanel"
	interventions_panel.theme_type_variation = &"RaisedPanel"
	help_panel.theme_type_variation = &"RaisedPanel"
	build_details_panel.theme_type_variation = &"DecisionPanel"
	equipment_reward_panel.theme_type_variation = &"DecisionPanel"
	district_card_panel.theme_type_variation = &"DecisionPanel"
	extraction_panel.theme_type_variation = &"DecisionPanel"
	extraction_panel.z_index = 34
	extraction_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	summary_panel.theme_type_variation = &"DecisionPanel"
	boss_trigger_panel.theme_type_variation = &"DangerPanel"

	_layout_compact_run_status()
	_layout_compact_crew()
	_layout_compact_build()
	_layout_action_strip()
	_layout_environment_action()
	_layout_focused_modals()

	hydrant_button.icon = ICON_ENVIRONMENT
	backup_button.icon = ICON_BACKUP
	extraction_button.icon = ICON_CONFIRM
	hydrant_button.theme_type_variation = &"InterventionUnavailable"
	backup_button.theme_type_variation = &"InterventionUnavailable"
	primary_action_button.theme_type_variation = &"SecondaryButton"
	subway_reroute_button.theme_type_variation = &"SecondaryButton"
	shop_cooling_button.theme_type_variation = &"SecondaryButton"
	district_card_open_button.theme_type_variation = &"SecondaryButton"
	reward_confirm_button.theme_type_variation = &"PrimaryButton"
	reward_keep_current_button.theme_type_variation = &"SecondaryButton"
	district_card_confirm_button.theme_type_variation = &"PrimaryButton"
	extraction_button.theme_type_variation = &"PrimaryButton"
	extraction_continue_button.theme_type_variation = &"DangerButton"
	help_button.theme_type_variation = &"SecondaryButton"
	fullscreen_button.theme_type_variation = &"SecondaryButton"

	($Root/CrewPanel/Title as Label).theme_type_variation = &"EyebrowLabel"
	($Root/CrewPanel/CrewName as Label).theme_type_variation = &"HeadingLabel"
	crew_state_label.theme_type_variation = &"SafeLabel"
	health_label.theme_type_variation = &"HealthLabel"
	heat_label.theme_type_variation = &"HeatCaption"
	night_pressure_label.theme_type_variation = &"PressureCaption"
	resource_values.theme_type_variation = &"BodyLabel"
	run_actions_title.theme_type_variation = &"EyebrowLabel"
	build_title_button.theme_type_variation = &"SecondaryButton"
	($Root/InterventionsPanel/Title as Label).text = "1  ENVIRONMENT  /  CONTEXT"
	($Root/InterventionsPanel/Title as Label).theme_type_variation = &"EyebrowLabel"
	($Root/EquipmentRewardPanel/Title as Label).theme_type_variation = &"HeadingLabel"
	reward_instruction_label.theme_type_variation = &"BodyLabel"
	reward_confirmation_label.theme_type_variation = &"WarningLabel"
	district_card_title.theme_type_variation = &"HeadingLabel"
	district_card_counts.theme_type_variation = &"EyebrowLabel"
	district_card_instruction.theme_type_variation = &"BodyLabel"
	district_card_route_preview.theme_type_variation = &"MutedLabel"
	district_card_feedback.theme_type_variation = &"WarningLabel"
	for details: Label in _district_card_choice_details:
		details.theme_type_variation = &"CaptionLabel"
	for details: Label in _reward_choice_details:
		details.theme_type_variation = &"CaptionLabel"
	# Re-apply compact bounds after semantic font variations have updated their
	# minimum sizes; this keeps first-frame editor/test instances contained.
	_layout_compact_run_status()
	($Root/HelpPanel/Title as Label).theme_type_variation = &"EyebrowLabel"
	auto_help_label.theme_type_variation = &"BodyLabel"
	($Root/HelpPanel/InterventionHelp as Label).text = (
		"1 ENV • 2 FOCUS • 3 BACKUP.\n"
		+ "3 EQUIPPED + 3 STORED; BACKPACK INACTIVE.\n"
		+ "SUBWAY TRAVEL; INVALID SPENDS NOTHING."
	)
	($Root/HelpPanel/InterventionHelp as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	($Root/HelpPanel/InterventionHelp as Label).clip_text = true
	action_toast.position = Vector2(420.0, 118.0)
	action_toast.size = Vector2(440.0, 56.0)
	build_callout.position = Vector2(420.0, 182.0)
	build_callout.size = Vector2(440.0, 68.0)


func _layout_compact_run_status() -> void:
	var legacy_night_label: Label = $Root/RunStatusPanel/NightLabel as Label
	legacy_night_label.visible = false
	legacy_night_label.text = ""
	legacy_night_label.clip_text = true
	_set_rect(legacy_night_label, Rect2(0.0, 0.0, 292.0, 92.0))
	threshold_label.visible = false
	threshold_label.clip_text = true
	threshold_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_rect(threshold_label, Rect2(0.0, 0.0, 292.0, 92.0))
	_set_rect(_heat_icon, Rect2(12.0, 8.0, 24.0, 24.0))
	heat_label.text = "HEAT 000  /  T0"
	_set_rect(heat_label, Rect2(42.0, 7.0, 160.0, 24.0))
	_set_rect(timer_label, Rect2(204.0, 7.0, 76.0, 24.0))
	timer_label.theme_type_variation = &"EyebrowLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_set_rect(heat_meter, Rect2(42.0, 34.0, 238.0, 10.0))
	_set_rect(_pressure_icon, Rect2(12.0, 52.0, 24.0, 24.0))
	night_pressure_label.text = "NIGHT 0.0  /  IRREVERSIBLE"
	_set_rect(night_pressure_label, Rect2(42.0, 49.0, 238.0, 24.0))
	_set_rect(night_pressure_meter, Rect2(42.0, 76.0, 238.0, 10.0))
	var resources_title: Label = $Root/ResourcesPanel/Title as Label
	resources_title.visible = false
	resources_title.text = ""
	resources_title.clip_text = true
	_set_rect(resources_title, Rect2(0.0, 0.0, 180.0, 92.0))
	_set_rect(_coins_icon, Rect2(12.0, 12.0, 28.0, 28.0))
	resource_values.text = "COINS 000\nSCRAP 00\nMAN —"
	_set_rect(resource_values, Rect2(48.0, 8.0, 120.0, 76.0))
	resource_values.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _layout_compact_crew() -> void:
	_set_rect($Root/CrewPanel/Title as Control, Rect2(12.0, 8.0, 246.0, 24.0))
	_set_rect($Root/CrewPanel/Portrait as Control, Rect2(12.0, 38.0, 52.0, 52.0))
	_set_rect($Root/CrewPanel/Portrait/PortraitGlyph as Control, Rect2(0.0, 0.0, 52.0, 52.0))
	var crew_name: Label = $Root/CrewPanel/CrewName as Label
	crew_name.clip_text = true
	crew_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_rect(crew_name, Rect2(74.0, 35.0, 116.0, 30.0))
	_set_rect(crew_state_label, Rect2(74.0, 66.0, 180.0, 24.0))
	_set_rect(_health_icon, Rect2(12.0, 101.0, 22.0, 22.0))
	_set_rect(health_meter, Rect2(40.0, 100.0, 218.0, 12.0))
	_set_rect(health_label, Rect2(40.0, 113.0, 218.0, 20.0))
	crew_status_label.visible = false
	crew_status_label.clip_text = true
	_set_rect(crew_status_label, Rect2(0.0, 0.0, 270.0, 136.0))
	var autonomy_hint: Label = $Root/CrewPanel/AutonomyHint as Label
	autonomy_hint.visible = false
	autonomy_hint.clip_text = true
	_set_rect(autonomy_hint, Rect2(0.0, 0.0, 270.0, 136.0))


func _layout_compact_build() -> void:
	_set_rect(build_title_button, Rect2(10.0, 8.0, 250.0, 38.0))
	for slot_index: int in range(_build_slot_buttons.size()):
		_build_slot_buttons[slot_index].text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_build_slot_buttons[slot_index].text = "%d  —" % (slot_index + 1)
		_set_rect(_build_slot_buttons[slot_index], Rect2(10.0 + 84.0 * slot_index, 52.0, 78.0, 72.0))


func _layout_action_strip() -> void:
	_set_rect(run_actions_title, Rect2(14.0, 5.0, 300.0, 24.0))
	_set_rect(primary_action_button, Rect2(14.0, 30.0, 172.0, 68.0))
	_set_rect(backup_button, Rect2(196.0, 30.0, 220.0, 68.0))
	_set_rect(subway_reroute_button, Rect2(426.0, 30.0, 172.0, 68.0))
	_set_rect(shop_cooling_button, Rect2(608.0, 30.0, 124.0, 68.0))
	_set_rect(focus_placeholder_button, Rect2(426.0, 30.0, 172.0, 68.0))
	_set_rect(district_card_compact_panel, Rect2(742.0, 5.0, 224.0, 83.0))
	district_card_compact_panel.theme_type_variation = &"RaisedPanel"
	_set_rect(district_card_compact_summary, Rect2(8.0, 5.0, 208.0, 24.0))
	district_card_compact_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	district_card_compact_summary.clip_text = true
	district_card_compact_summary.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	district_card_compact_summary.max_lines_visible = 1
	district_card_compact_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_rect(district_card_open_button, Rect2(8.0, 31.0, 208.0, 46.0))


func _layout_environment_action() -> void:
	_set_rect($Root/InterventionsPanel/Title as Control, Rect2(12.0, 8.0, 246.0, 24.0))
	_set_rect(hydrant_state_label, Rect2(12.0, 34.0, 246.0, 24.0))
	_set_rect(hydrant_button, Rect2(12.0, 62.0, 246.0, 70.0))
	_set_rect(hydrant_cooldown_meter, Rect2(12.0, 138.0, 246.0, 10.0))
	_set_rect(hydrant_cooldown_label, Rect2(12.0, 151.0, 246.0, 22.0))
	_set_rect($Root/InterventionsPanel/EffectLabel as Control, Rect2(12.0, 176.0, 246.0, 42.0))
	hydrant_feedback_label.visible = false
	hydrant_feedback_label.clip_text = true
	hydrant_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_rect(hydrant_feedback_label, Rect2(12.0, 190.0, 246.0, 24.0))


func _layout_focused_modals() -> void:
	_set_rect(equipment_reward_panel, Rect2(60.0, 50.0, 1160.0, 620.0))
	_set_rect(district_card_panel, Rect2(60.0, 50.0, 1160.0, 620.0))
	_set_rect(build_details_panel, Rect2(120.0, 60.0, 1040.0, 620.0))
	_set_rect(shop_decision_panel, Rect2(120.0, 90.0, 1040.0, 540.0))
	_set_rect(shop_plan_button, Rect2(816.0, 22.0, 180.0, 52.0))
	_set_rect(shop_cooling_choice, Rect2(32.0, 140.0, 470.0, 190.0))
	_set_rect(shop_leave_choice, Rect2(526.0, 140.0, 470.0, 190.0))
	_set_rect(shop_comparison, Rect2(32.0, 354.0, 964.0, 120.0))
	_set_rect(extraction_panel, Rect2(120.0, 90.0, 1040.0, 540.0))
	_set_rect(extraction_plan_button, Rect2(816.0, 22.0, 180.0, 52.0))
	_set_rect(extraction_button, Rect2(32.0, 140.0, 470.0, 240.0))
	_set_rect(extraction_continue_button, Rect2(526.0, 140.0, 470.0, 240.0))
	_set_rect(extraction_preview, Rect2(32.0, 404.0, 964.0, 110.0))


func _clear_legacy_theme_overrides(node: Node) -> void:
	if node is Control:
		var control: Control = node as Control
		control.remove_theme_font_size_override(&"font_size")
		for color_name: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_focus_color", &"font_disabled_color", &"font_outline_color",
		]:
			control.remove_theme_color_override(color_name)
	if node is Panel:
		(node as Panel).remove_theme_stylebox_override(&"panel")
	for child: Node in node.get_children():
		_clear_legacy_theme_overrides(child)


func _new_label(
	label_name: String,
	text_value: String,
	variation: StringName,
	rect: Rect2,
	wrap: bool = false
) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.text = text_value
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	_set_rect(label, rect)
	return label


func _new_icon(icon_name: String, texture: Texture2D) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.name = icon_name
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func _process(delta: float) -> void:
	if _onboarding_remaining <= 0.0 or not help_panel.visible:
		return
	_onboarding_remaining = maxf(0.0, _onboarding_remaining - maxf(0.0, delta))
	if _onboarding_remaining <= 0.0:
		_set_help_expanded(false)


func _input(event: InputEvent) -> void:
	if not district_card_panel.visible or not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_RIGHT or not mouse_button.pressed:
		return
	var payload: DistrictCardDragPayload = (
		get_viewport().gui_get_drag_data() as DistrictCardDragPayload
	)
	if payload == null:
		return
	_district_card_drag_cancelled = true
	get_viewport().gui_cancel_drag()
	get_viewport().set_input_as_handled()


func present_lab_elapsed(elapsed_seconds: float) -> void:
	var safe_seconds: int = maxi(0, int(floor(elapsed_seconds)))
	var minutes: int = int(floor(float(safe_seconds) / 60.0))
	var seconds: int = safe_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func present_jax_status(
	current_health: float,
	maximum_health: float,
	state_name: StringName,
	target_name: String
) -> void:
	present_crew_status("JAX", current_health, maximum_health, state_name, target_name)


func present_crew_status(
	display_name: String,
	current_health: float,
	maximum_health: float,
	state_name: StringName,
	target_name: String
) -> void:
	_crew_display_name = display_name.to_upper() if not display_name.is_empty() else "CREW"
	var safe_maximum: float = maxf(1.0, maximum_health)
	var safe_current: float = clampf(current_health, 0.0, safe_maximum)
	health_meter.max_value = safe_maximum
	health_meter.value = safe_current
	health_label.text = "HEALTH %d / %d" % [int(round(safe_current)), int(round(safe_maximum))]
	crew_state_label.text = _compact_state_name(state_name)
	var initials: String = _crew_display_name.left(2)
	($Root/CrewPanel/Title as Label).text = "%s • AUTO FIGHT" % _crew_display_name
	($Root/CrewPanel/Portrait/PortraitGlyph as Label).text = initials
	($Root/CrewPanel/CrewName as Label).text = _crew_display_name
	($Root/BuildDetailsPanel/Title as Label).text = "%s EQUIPMENT • DRAG OR CLICK" % _crew_display_name
	auto_help_label.text = (
		"%s AUTO-FIGHTS.\n" % _crew_display_name
		+ "CLICKS ONLY INSPECT; NEVER DISCARD.\n"
		+ "CARDS: DRAG/CLICK; RIGHT-CLICK = CANCEL."
	)
	crew_status_label.text = "TARGET\n%s\nAUTO FIGHTING" % (
		target_name if not target_name.is_empty() else "NONE"
	)


func present_backup_state(snapshot: Dictionary) -> void:
	_backup_snapshot = snapshot.duplicate(true)
	var active_allies: int = maxi(
		int(snapshot.get("active_ally_count", snapshot.get("active_allies", 0))),
		0
	)
	var charges: int = maxi(int(snapshot.get("charges_remaining", snapshot.get("charges", 0))), 0)
	var cooldown_remaining: float = maxf(float(snapshot.get("cooldown_remaining", 0.0)), 0.0)
	var duration_remaining: float = maxf(
		float(snapshot.get("active_duration_remaining", snapshot.get("duration_remaining", 0.0))),
		0.0
	)
	var can_activate: bool = bool(snapshot.get("can_activate", false))
	var reason: String = str(
		snapshot.get("validity_text", snapshot.get("validity_reason", "NEEDS ACTIVE ENEMY"))
	).replace("_", " ")
	var compact_reason: String = {
		"invalid state": "NEEDS FIGHT",
		"no charges": "EXHAUSTED",
		"already active": "ACTIVE",
		"cooldown": "COOLING DOWN",
		"unconfigured": "UNAVAILABLE",
		"spawn failed": "SPAWN FAILED",
		"registration failed": "REG FAILED",
		"malformed request": "BAD REQUEST",
		"stale request": "STALE CONTEXT",
		"replayed request": "ALREADY USED",
	}.get(reason.to_lower(), reason.to_upper())
	var visual_state: int = NeonInterventionButton.VisualState.UNAVAILABLE
	var status_text: String = compact_reason
	if active_allies > 0:
		visual_state = NeonInterventionButton.VisualState.COOLING
		status_text = "%d ALLIES  /  %ds" % [
			active_allies,
			int(ceil(duration_remaining)),
		]
	elif cooldown_remaining > 0.0:
		visual_state = NeonInterventionButton.VisualState.COOLING
		status_text = "%ds  /  %d LEFT" % [
			int(ceil(cooldown_remaining)),
			charges,
		]
	elif can_activate:
		visual_state = NeonInterventionButton.VisualState.READY
		status_text = "READY  /  %d LEFT" % charges
	(backup_button as NeonInterventionButton).present(
		"3",
		"BACKUP",
		status_text,
		visual_state,
		false
	)
	backup_button.tooltip_text = (
		"Call Backup: two temporary allied NPCs fight for 12 eligible combat seconds. "
		+ "Its two charges cover the whole run and never recharge. "
		+ "State: %s. Invalid requests do not consume a charge or cooldown." % reason
	)


func present_environment_state(snapshot: Dictionary) -> void:
	_environment_snapshot = snapshot.duplicate(true)
	_refresh_hydrant_presentation()


func present_focus_state(snapshot: Dictionary) -> void:
	_focus_snapshot = snapshot.duplicate(true)
	if focus_placeholder_button == null:
		return
	var visual_state: int = NeonInterventionButton.VisualState.UNAVAILABLE
	var status_text: String = String(
		_focus_snapshot.get("validity_reason", "no focus target")
	).replace("_", " ").to_upper()
	if float(_focus_snapshot.get("active_remaining", 0.0)) > 0.0:
		visual_state = NeonInterventionButton.VisualState.COOLING
		status_text = "ACTIVE %.1fs  /  %s" % [
			float(_focus_snapshot.get("active_remaining", 0.0)),
			_compact_wp05_target_name(str(_focus_snapshot.get("target_name", "THREAT"))),
		]
	elif float(_focus_snapshot.get("cooldown_remaining", 0.0)) > 0.0:
		visual_state = NeonInterventionButton.VisualState.COOLING
		status_text = "COOLDOWN %.1fs" % float(_focus_snapshot.get("cooldown_remaining", 0.0))
	elif bool(_focus_snapshot.get("can_activate", false)):
		visual_state = NeonInterventionButton.VisualState.READY
		status_text = "%s  /  %.1fs" % [
			_compact_wp05_target_name(str(_focus_snapshot.get("target_name", "THREAT"))),
			float(_focus_snapshot.get("window_seconds", 0.0)),
		]
	var intent_label: String = str(
		_focus_snapshot.get("intent_label", _focus_snapshot.get("attack_name", "NO INTENT"))
	)
	focus_placeholder_button.present(
		"2 FOCUS",
		_compact_wp05_attack_name(intent_label),
		status_text,
		visual_state,
		false
	)
	focus_placeholder_button.tooltip_text = (
		"Focus: temporarily prioritize %s during %s. Crew movement and attacks remain automatic. "
		+ "State: %s. Invalid requests consume no cooldown."
	) % [
		str(_focus_snapshot.get("target_name", "no current threat")),
		str(_focus_snapshot.get("attack_name", "no current intent")),
		String(_focus_snapshot.get("validity_reason", &"invalid_state")).replace("_", " "),
	]

func present_coin_status(total_coins: int, streak_count: int, status_message: String) -> void:
	var streak_text: String = "x%d" % streak_count if streak_count > 0 else "—"
	var message: String = status_message if not status_message.is_empty() else "AUTO • FULL VALUE"
	resource_values.text = "COINS %03d\nSCRAP %02d\nMAN %s" % [
		maxi(0, total_coins),
		maxi(0, _scrap_total),
		streak_text,
	]
	resource_values.tooltip_text = "%s. Ignored clusters still grant full base value." % message


func present_scrap_total(total_scrap: int) -> void:
	_scrap_total = maxi(total_scrap, 0)
	var current_coins: int = int(_last_run_snapshot.get("coins", 0))
	var streak_count: int = int(_last_run_snapshot.get("streak_count", 0))
	present_coin_status(current_coins, streak_count, "RUN REWARDS SECURED")


func present_flow_snapshot(snapshot: Dictionary) -> void:
	var run: Dictionary = snapshot.get("run", {})
	var patrol: Dictionary = snapshot.get("patrol", {})
	var encounter: Dictionary = snapshot.get("encounter", {})
	var rewards: Dictionary = snapshot.get("rewards", {})
	var cooling: Dictionary = snapshot.get("cooling", {})
	if snapshot.has("environment"):
		present_environment_state(snapshot.get("environment", {}))
	if snapshot.has("focus"):
		present_focus_state(snapshot.get("focus", {}))
	if snapshot.has("backup"):
		present_backup_state(snapshot.get("backup", {}))
	_shop_snapshot = cooling.duplicate(true)
	if not bool(_shop_snapshot.get("shop_visit_active", false)):
		_last_shop_purchase_result.clear()
	elif not _last_shop_purchase_result.is_empty():
		var result_revision: int = int(_last_shop_purchase_result.get(
			"resulting_visit_revision",
			_last_shop_purchase_result.get("visit_revision", -1)
		))
		if (
			result_revision != int(_shop_snapshot.get("shop_visit_revision", -1))
			or StringName(_last_shop_purchase_result.get("source_id", &""))
			!= StringName(_shop_snapshot.get("shop_visit_source_id", &""))
		):
			_last_shop_purchase_result.clear()
	_district_loop_snapshot = run.get("district_loop", {}).duplicate(true)
	_last_run_snapshot = {
		"coins": int(rewards.get("coin_total", 0)),
		"streak_count": int(rewards.get("streak_count", 0)),
	}
	_scrap_total = int(rewards.get("scrap_total", 0))
	present_lab_elapsed(float(run.get("run_elapsed_seconds", 0.0)))
	present_coin_status(
		int(rewards.get("coin_total", 0)),
		int(rewards.get("streak_count", 0)),
		"AUTO • FULL VALUE"
	)

	var heat_value: int = int(run.get("heat", 0))
	var heat_tier: int = int(run.get("heat_tier", 0))
	heat_label.text = "HEAT %03d  /  T%d" % [
		heat_value,
		heat_tier,
	]
	heat_label.tooltip_text = "HEAT TIER %d  /  %s" % [heat_tier, _heat_implication(heat_tier)]
	heat_meter.value = heat_value
	var pressure: float = float(run.get("night_pressure", 0.0))
	var boss_threshold: float = maxf(float(run.get("boss_threshold", 1.0)), 0.001)
	night_pressure_meter.max_value = boss_threshold
	night_pressure_meter.value = pressure
	if bool(_district_loop_snapshot.get("enabled", false)):
		var current_lap: Dictionary = _district_loop_snapshot.get("current_lap", {})
		night_pressure_label.text = "NIGHT %.1f  /  LOCKED  /  x%.2f" % [
			pressure,
			float(current_lap.get("pressure_gain_multiplier", 1.0)),
		]
		night_pressure_label.tooltip_text = (
			"NIGHT PRESSURE IS IRREVERSIBLE  /  CURRENT LAP GAIN x%.2f"
			% float(current_lap.get("pressure_gain_multiplier", 1.0))
		)
		threshold_label.text = "RISK: LAP END  •  BOSS: FINAL COMMIT"
	else:
		night_pressure_label.text = "NIGHT %.1f  /  IRREVERSIBLE" % pressure
		night_pressure_label.tooltip_text = "NIGHT PRESSURE IS IRREVERSIBLE"
		threshold_label.text = "NEXT %.1f  •  BOSS %.1f%s" % [
			float(run.get("next_major_threshold", boss_threshold)),
			boss_threshold,
			"  •  QUEUED" if bool(run.get("boss_queued", false)) else "",
		]

	var state: int = int(run.get("state", RunDirector.RunState.INITIALIZING))
	if state not in [RunDirector.RunState.ENCOUNTER_ACTIVE, RunDirector.RunState.BOSS_ACTIVE]:
		clear_build_callout()
	var reward_modal_context: bool = (
		state == RunDirector.RunState.REWARD_SELECTION
		or (
			state == RunDirector.RunState.PAUSED
			and int(run.get("pause_origin_state", -1))
			== RunDirector.RunState.REWARD_SELECTION
		)
	)
	_district_patrol_snapshot = patrol.duplicate(true)
	_district_card_route_revision = int(patrol.get("route_revision", -1))
	_district_card_planning_allowed = _card_planning_available_for_state(state)
	var management_was_enabled: bool = _inventory_management_enabled
	if state == RunDirector.RunState.INTRO and _last_flow_state != RunDirector.RunState.INTRO:
		build_details_panel.visible = false
		_clear_inventory_selection()
		dismiss_equipment_reward()
		dismiss_district_card_panel()
		_onboarding_remaining = ONBOARDING_EXPANDED_SECONDS
		help_panel.visible = true
	_last_flow_state = state
	_inventory_management_enabled = state in [
		RunDirector.RunState.INTRO,
		RunDirector.RunState.PATROLLING,
		RunDirector.RunState.SHOP,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
	]
	if management_was_enabled and not _inventory_management_enabled:
		_clear_inventory_selection()
	if state in [
		RunDirector.RunState.REWARD_SELECTION,
		RunDirector.RunState.EXTRACTING,
		RunDirector.RunState.BOSS_INTRO,
		RunDirector.RunState.BOSS_ACTIVE,
		RunDirector.RunState.VICTORY,
		RunDirector.RunState.DEFEAT,
		RunDirector.RunState.RUN_SUMMARY,
	]:
		build_details_panel.visible = false
	if (
		_district_card_panel_mode == DistrictCardPanelMode.PLANNING
		and not _district_card_planning_allowed
	):
		dismiss_district_card_panel()
	elif (
		_district_card_panel_mode == DistrictCardPanelMode.REWARD
		and not reward_modal_context
	):
		dismiss_district_card_panel()
	if build_details_panel.visible:
		_refresh_build_details(_build_snapshot.get("slots", []))
		_refresh_inventory_action_presentation()
	route_title.text = (
		"DISTRICT • LAP %d/%d • BLOCK %d/%d"
		% [
			int(_district_loop_snapshot.get("lap_index", 1)),
			int(_district_loop_snapshot.get("lap_count", 3)),
			int(_district_loop_snapshot.get("block_index", 1)),
			int(_district_loop_snapshot.get("blocks_per_lap", 3)),
		]
		if bool(_district_loop_snapshot.get("enabled", false))
		else "ROUTE • %s" % _journey_stage_for_state(state)
	)
	var route_index: int = int(patrol.get("route_index", -1))
	var route_progress: float = float(patrol.get("route_progress", 0.0))
	if bool(_district_loop_snapshot.get("enabled", false)):
		_route_journey_text = "PLAN>BLOCK/FIGHT>REWARD\nLAP DECISION>EXTRACTION/BOSS\n%s • %s" % [
			str(_district_loop_snapshot.get("phase_name", "PLAN")),
			str((_district_loop_snapshot.get("current_lap", {}) as Dictionary).get("modifier_label", "STREET WATCH")),
		]
	else:
		_route_journey_text = "HIDEOUT>PATROL>FIGHT\nGEAR>EXIT/BOSS\nN%d %02d%% L%d > %s" % [
			route_index + 1,
			int(round(route_progress * 100.0)),
			int(patrol.get("loop_count", 0)),
			_journey_next_objective(state),
		]
	_refresh_route_label_with_card_markers()

	if not reward_modal_context:
		dismiss_equipment_reward()
	var encounter_name: String = String(encounter.get("active_encounter_name", "Patrolling"))
	_refresh_run_actions(state, encounter_name, cooling, rewards)
	_present_wp01_phase_banner(state, run, patrol, encounter)
	_refresh_wp01_focused_shells(state, run, cooling, rewards)
	_refresh_district_card_compact_presentation()
	if district_card_panel.visible:
		_refresh_district_card_panel_presentation()
	summary_panel.visible = state == RunDirector.RunState.RUN_SUMMARY
	# Milestone 6 presents the live Viper through VerticalSliceOverlay's
	# dedicated health/phase/telegraph strip. The Milestone 3 placeholder modal
	# must never cover or intercept input from the authored boss encounter.
	boss_trigger_panel.visible = false


func _present_wp01_phase_banner(
	state: int,
	run: Dictionary,
	patrol: Dictionary,
	encounter: Dictionary
) -> void:
	var phase_text: String = _journey_stage_for_state(state)
	var route_index: int = maxi(int(patrol.get("route_index", -1)) + 1, 0)
	var route_progress: float = clampf(float(patrol.get("route_progress", 0.0)), 0.0, 1.0)
	var progress_text: String = "CURRENT ROUTE  /  NODE %d  /  %d%%" % [
		route_index,
		int(round(route_progress * 100.0)),
	]
	var next_event: String = "PATROL CONTINUES"
	var status_title: String = "RUN"
	var status_value: String = _format_time(float(run.get("run_elapsed_seconds", 0.0)))
	var warning: bool = false
	var phase_icon: Texture2D = ICON_PHASE_PLAN
	var district_enabled: bool = bool(_district_loop_snapshot.get("enabled", false))
	if district_enabled:
		progress_text = "LAP %d/%d  •  BLOCK %d/%d  •  %s" % [
			int(_district_loop_snapshot.get("lap_index", 1)),
			int(_district_loop_snapshot.get("lap_count", 3)),
			int(_district_loop_snapshot.get("block_index", 1)),
			int(_district_loop_snapshot.get("blocks_per_lap", 3)),
			str((_district_loop_snapshot.get("current_lap", {}) as Dictionary).get("modifier_label", "STREET WATCH")),
		]

	match state:
		RunDirector.RunState.INITIALIZING, RunDirector.RunState.INTRO:
			phase_text = "RUN INTRO"
			next_event = "CREW ENTERS THE DISTRICT"
			status_title = "NEXT"
			status_value = "PLAN" if district_enabled else "PATROL"
			phase_icon = ICON_PHASE_PLAN
		RunDirector.RunState.PATROLLING:
			phase_text = "PLAN" if district_enabled else "PATROL"
			next_event = "NEXT BLOCK  /  %s" % str(
				patrol.get("route_node_type", "NEXT BLOCK")
			).replace("_", " ").to_upper()
			status_title = "ACTION"
			status_value = "PLAN OR WATCH APPROACH" if district_enabled else "%d%%" % int(round(route_progress * 100.0))
			phase_icon = ICON_PHASE_PLAN
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			phase_text = "FIGHT"
			var encounter_name: String = str(encounter.get("active_encounter_name", "ENCOUNTER"))
			var remaining: int = maxi(int(encounter.get("remaining_to_spawn", 0)), 0)
			var arrival: float = maxf(float(encounter.get("spawn_delay_remaining", 0.0)), 0.0)
			if remaining > 0 and arrival > 0.0:
				next_event = "%s  /  ENEMY ARRIVAL" % encounter_name.to_upper()
				status_title = "ARRIVAL"
				status_value = "%.1fs" % arrival
			else:
				next_event = "%s  /  DEFEAT ACTIVE THREATS" % encounter_name.to_upper()
				status_title = "ACTION"
				status_value = "INTERVENE"
			phase_icon = ICON_PHASE_FIGHT
		RunDirector.RunState.REWARD_SELECTION:
			phase_text = "REWARD"
			next_event = "CHOOSE GEAR OR KEEP THE CURRENT BUILD"
			status_title = "ACTION"
			status_value = "CHOOSE ONE"
			phase_icon = ICON_PHASE_REWARD
		RunDirector.RunState.SHOP:
			phase_text = "SHOP"
			next_event = "BUY FROM FINITE STOCK OR LEAVE  /  THEN COMPLETE BLOCK"
			status_title = "ACTION"
			status_value = "ONE PURCHASE"
			phase_icon = ICON_PHASE_SHOP
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			phase_text = "LAP DECISION" if district_enabled else "EXTRACT OR PUSH"
			var push_preview: Dictionary = _district_loop_snapshot.get("push_preview", {})
			next_event = (
				"EXTRACT OR COMMIT TO FINAL LAP AND THE VIPER"
				if bool(push_preview.get("final_lap_commitment", false))
				else "EXTRACT OR PUSH DEEPER INTO LAP %d" % int(push_preview.get("lap_index", 0))
			) if district_enabled else "SECURE THE RUN OR CONTINUE AT HIGHER HEAT"
			status_title = "DECISION"
			status_value = "FINAL ON CONFIRM"
			warning = true
			phase_icon = ICON_PHASE_EXTRACT
		RunDirector.RunState.EXTRACTING:
			phase_text = "EXTRACTION"
			next_event = "RUN SUMMARY"
			status_title = "TRANSITION"
			status_value = "IN PROGRESS"
			phase_icon = ICON_PHASE_EXTRACT
		RunDirector.RunState.BOSS_INTRO:
			phase_text = "BOSS" if district_enabled else "BOSS INTRO"
			next_event = "THE VIPER ENTERS"
			status_title = "ARRIVAL"
			status_value = "%.1fs" % maxf(float(run.get("boss_intro_remaining", 0.0)), 0.0)
			warning = true
			phase_icon = ICON_PHASE_FIGHT
		RunDirector.RunState.BOSS_ACTIVE:
			phase_text = "BOSS"
			next_event = "DEFEAT THE VIPER"
			status_title = "THREAT"
			status_value = "BOSS ACTIVE"
			warning = true
			phase_icon = ICON_PHASE_FIGHT
		RunDirector.RunState.PAUSED:
			phase_text = "DISTRICT PLAN" if bool(run.get("card_planning_pause_active", false)) else "PAUSED"
			next_event = "CONFIRM A CHOICE OR RESUME"
			status_title = "ACTION"
			status_value = "INPUT NEEDED"
			phase_icon = ICON_PHASE_PLAN
		RunDirector.RunState.VICTORY, RunDirector.RunState.DEFEAT, RunDirector.RunState.RUN_SUMMARY:
			phase_text = "RESULT"
			next_event = "REVIEW THE RUN AND CHOOSE WHAT TO TRY NEXT"
			status_title = "RUN"
			status_value = "COMPLETE"
			phase_icon = ICON_PHASE_RESULT

	phase_banner.present(
		phase_text,
		progress_text,
		next_event,
		status_title,
		status_value,
		warning,
		phase_icon
	)


func _refresh_wp01_focused_shells(
	state: int,
	run: Dictionary,
	cooling: Dictionary,
	rewards: Dictionary
) -> void:
	var planning_overlay_open: bool = district_card_panel.visible
	var equipment_overlay_open: bool = equipment_reward_panel.visible
	shop_decision_panel.visible = (
		state == RunDirector.RunState.SHOP
		and not planning_overlay_open
		and not equipment_overlay_open
	)
	extraction_panel.visible = (
		state == RunDirector.RunState.EXTRACTION_AVAILABLE
		and not planning_overlay_open
		and not equipment_overlay_open
	)
	var hand_count: int = int(_district_card_snapshot.get("hand_count", _district_card_hand.size()))
	var plan_available: bool = _district_card_planning_allowed and hand_count > 0
	shop_plan_button.disabled = not plan_available
	extraction_plan_button.disabled = not plan_available

	if shop_decision_panel.visible:
		shop_decision_panel.move_to_front()
		var preview: Dictionary = cooling.get("shop_purchase_preview", {})
		var current_heat: int = int(preview.get("heat_before", run.get("heat", 0)))
		var next_heat: int = int(preview.get(
			"heat_after",
			maxi(current_heat - int(cooling.get("shop_heat_reduction", 0)), 0)
		))
		var heat_reduction: int = maxi(current_heat - next_heat, 0)
		var current_coins: int = maxi(int(preview.get("coins_before", rewards.get("coin_total", 0))), 0)
		var next_coins: int = maxi(int(preview.get("coins_after", current_coins)), 0)
		var coin_cost: int = maxi(int(cooling.get("shop_coin_cost", 0)), 0)
		var stock: int = maxi(int(preview.get("global_stock_before", cooling.get("shop_purchases_remaining", 0))), 0)
		var stock_after: int = maxi(int(preview.get("global_stock_after", stock)), 0)
		var visit_stock: int = int(preview.get(
			"visit_stock_before",
			cooling.get("shop_visit_purchases_remaining", -1)
		))
		var visit_stock_after: int = int(preview.get("visit_stock_after", visit_stock))
		var can_buy: bool = bool(preview.get(
			"can_purchase",
			stock > 0 and current_coins >= coin_cost and current_heat > 0
		))
		var source_id: StringName = StringName(preview.get(
			"source_id",
			cooling.get("shop_visit_source_id", &"shop_cooling")
		))
		var completed_purchase: bool = (
			bool(_last_shop_purchase_result.get("accepted", false))
			and StringName(_last_shop_purchase_result.get("source_id", &"")) == source_id
		)
		var comparison_preview: Dictionary = (
			_last_shop_purchase_result
			if completed_purchase
			else preview
		)
		(shop_decision_panel.get_node("Title") as Label).text = "SHOP  /  %s" % (
			"CONVENIENCE STORE"
			if source_id == &"convenience_store"
			else "STREET COOLING"
		)
		(shop_decision_panel.get_node("Instruction") as Label).text = (
			"Purchase applied exactly. Review the result, then leave to continue."
			if completed_purchase
			else (
				"One purchase remains in this visit; buy exact finite cooling or leave unchanged."
				if visit_stock == 1
				else "Global stock is finite; buy cooling or leave immediately with no purchase."
			)
		)
		shop_cooling_choice.disabled = not can_buy
		shop_cooling_choice.text = (
			"PURCHASE COMPLETE\n%d COINS -> %d  /  HEAT %d -> %d\nTIER %d -> %d  /  STOCK %d -> %d"
			% [
				int(comparison_preview.get("coins_before", 0)),
				int(comparison_preview.get("coins_after", 0)),
				int(comparison_preview.get("heat_before", 0)),
				int(comparison_preview.get("heat_after", 0)),
				int(comparison_preview.get("heat_tier_before", 0)),
				int(comparison_preview.get("heat_tier_after", 0)),
				int(comparison_preview.get("global_stock_before", 0)),
				int(comparison_preview.get("global_stock_after", 0)),
			]
			if completed_purchase
			else
			"COOL DISTRICT  -%d HEAT\n%d COINS  /  %d -> %d  /  HEAT %d -> %d\nTIER %d -> %d  /  STOCK %d -> %d%s"
			% [
				heat_reduction,
				coin_cost,
				current_coins,
				next_coins,
				current_heat,
				next_heat,
				int(preview.get("heat_tier_before", run.get("heat_tier", 0))),
				int(preview.get("heat_tier_after", run.get("heat_tier", 0))),
				stock,
				stock_after,
				(
					"  /  VISIT %d -> %d" % [visit_stock, visit_stock_after]
					if visit_stock >= 0
					else ""
				),
			]
		)
		var reason: StringName = StringName(preview.get("reason", &"ok"))
		shop_cooling_choice.set_visual_state(
			NeonChoiceCard.VisualState.DEFAULT if can_buy else NeonChoiceCard.VisualState.DISABLED,
			(
				"PURCHASE COMPLETE  /  LEAVE SHOP"
				if completed_purchase
				else ("AVAILABLE" if can_buy else _shop_rejection_label(reason, current_coins, coin_cost))
			)
		)
		var live_coins: int = maxi(int(rewards.get("coin_total", current_coins)), 0)
		var live_stock: int = maxi(int(cooling.get("shop_purchases_remaining", stock)), 0)
		shop_leave_choice.text = "LEAVE SHOP\nBUY NOTHING  /  KEEP %d COINS\nGLOBAL STOCK %d REMAINS" % [
			live_coins,
			live_stock,
		]
		shop_leave_choice.set_visual_state(NeonChoiceCard.VisualState.DEFAULT, "SAFE DECLINE")
		var comparison_heading: String = (
			"PURCHASE COMPLETE"
			if completed_purchase
			else "NEXT-FIGHT CONSEQUENCE"
		)
		shop_comparison.present(
			comparison_heading,
			"HEAT %d  /  TIER %d" % [
				int(comparison_preview.get("heat_before", current_heat)),
				int(comparison_preview.get("heat_tier_before", run.get("heat_tier", 0))),
			],
			"HEAT %d  /  TIER %d" % [
				int(comparison_preview.get("heat_after", next_heat)),
				int(comparison_preview.get("heat_tier_after", run.get("heat_tier", 0))),
			],
			"REWARD QUALITY %d -> %d  /  COIN x%.2f -> x%.2f  /  NIGHT PRESSURE %.1f UNCHANGED" % [
				int(comparison_preview.get("reward_quality_before", 0)),
				int(comparison_preview.get("reward_quality_after", 0)),
				float(comparison_preview.get("reward_multiplier_before", 1.0)),
				float(comparison_preview.get("reward_multiplier_after", 1.0)),
				float(comparison_preview.get("night_pressure", run.get("night_pressure", 0.0))),
			],
			can_buy or completed_purchase
		)

	if extraction_panel.visible:
		extraction_panel.move_to_front()
		var current_heat: int = int(run.get("heat", 0))
		var district_enabled: bool = bool(_district_loop_snapshot.get("enabled", false))
		var push_preview: Dictionary = _district_loop_snapshot.get("push_preview", {})
		var push_heat_delta: int = int(push_preview.get("push_heat_delta", 6))
		var pushed_heat: int = mini(current_heat + push_heat_delta, 100)
		var current_coins: int = maxi(int(rewards.get("coin_total", 0)), 0)
		var current_scrap: int = maxi(int(rewards.get("scrap_total", 0)), 0)
		var reward_multiplier: float = maxf(float(run.get("reward_multiplier", 1.0)), 0.0)
		if district_enabled:
			var completed_lap: int = int(_district_loop_snapshot.get("completed_laps", 0))
			var completed_blocks: int = int(_district_loop_snapshot.get("completed_blocks", 0))
			var next_lap: int = int(push_preview.get("lap_index", completed_lap + 1))
			var final_commitment: bool = bool(push_preview.get("final_lap_commitment", false))
			extraction_title.text = "LAP %d COMPLETE  /  EXTRACT OR %s" % [
				completed_lap,
				"COMMIT TO BOSS" if final_commitment else "PUSH DEEPER",
			]
			extraction_instruction.text = (
				"This confirmation is final. Lap %d has no routine extraction."
				% next_lap
				if final_commitment
				else "This confirmation is final. Preview the next lap before choosing."
			)
			extraction_button.text = (
				"EXTRACT  /  SECURE CURRENT RESULT\n%d LAPS  /  %d BLOCKS  /  %d COINS  /  %d SCRAP"
				% [completed_lap, completed_blocks, current_coins, current_scrap]
			)
			extraction_continue_button.text = (
				"%s\nHEAT %d -> %d  /  %s\nREWARD TIER +%d  /  PRESSURE x%.2f\nNEXT: %s"
				% [
					"COMMIT TO FINAL LAP + BOSS" if final_commitment else "PUSH DEEPER  /  ENTER LAP %d" % next_lap,
					current_heat,
					pushed_heat,
					str(push_preview.get("modifier_label", "HIGHER RISK")),
					int(push_preview.get("reward_quality_tier_bonus", 0)),
					float(push_preview.get("pressure_gain_multiplier", 1.0)),
					str(push_preview.get("next_threat", "UNKNOWN")),
				]
			)
			extraction_preview.present(
				"AUTHORITATIVE CONSEQUENCE",
				"EXTRACT  /  %d LAPS SECURED" % completed_lap,
				"PUSH  /  LAP %d  /  %s" % [next_lap, str(push_preview.get("modifier_label", "HIGHER RISK"))],
				"Night Pressure is unchanged and irreversible. %s" % str(push_preview.get("risk_label", "HIGHER RISK")),
				final_commitment
			)
		else:
			extraction_button.text = (
				"EXTRACT  /  SECURE CURRENT RESULT\n%d COINS  /  %d SCRAP  /  x%.2f"
				% [current_coins, current_scrap, reward_multiplier]
			)
			extraction_continue_button.text = (
				"PUSH ON  /  CONTINUE CURRENT ROUTE\nHEAT %d -> %d  /  NIGHT PRESSURE CONTINUES"
				% [current_heat, pushed_heat]
			)
			extraction_preview.present(
				"DECISION PREVIEW",
				"CURRENT RESULT",
				"EXTRACTED OR CONTINUING",
				"Continue keeps the current route. Night Pressure remains irreversible.",
				false
			)


func present_build_snapshot(snapshot: Dictionary) -> void:
	_build_snapshot = snapshot.duplicate(true)
	_inventory_action_in_flight = false
	_validate_inventory_selection()
	if not is_node_ready():
		return
	_refresh_build_presentation()


func present_equipment_reward(
	encounter_instance_id: int,
	choices: Array[EquipmentDefinition],
	previews_by_choice: Array[Dictionary],
	choice_token: int = -1,
	standard_reward_preview: Dictionary = {}
) -> void:
	dismiss_district_card_panel()
	_reward_encounter_id = encounter_instance_id
	_reward_choice_token = choice_token
	_reward_choices = choices.duplicate()
	_reward_previews_by_choice = previews_by_choice.duplicate(true)
	_standard_reward_preview = standard_reward_preview.duplicate(true)
	_equipment_choice_in_flight = false
	_selected_reward_choice = -1
	_selected_reward_destination = &""
	_selected_reward_slot = _first_empty_build_slot()
	_selected_reward_backpack_slot = -1
	_selected_reward_outgoing_backpack_slot = -1
	_reward_drag_active = false
	_clear_inventory_selection()
	build_details_panel.visible = false
	help_panel.visible = false
	if action_toast != null:
		action_toast.hide()
	clear_build_callout()
	equipment_reward_panel.visible = true
	equipment_reward_panel.move_to_front()
	_refresh_equipment_reward_presentation()


func dismiss_equipment_reward() -> void:
	if not is_node_ready():
		return
	equipment_reward_panel.visible = false
	_reward_encounter_id = -1
	_reward_choice_token = -1
	_reward_choices.clear()
	_reward_previews_by_choice.clear()
	_standard_reward_preview.clear()
	_equipment_choice_in_flight = false
	_selected_reward_choice = -1
	_selected_reward_destination = &""
	_selected_reward_slot = -1
	_selected_reward_backpack_slot = -1
	_selected_reward_outgoing_backpack_slot = -1
	_reward_drag_active = false
	for button: EquipmentDragSlot in _reward_choice_buttons:
		button.disabled = false


func is_equipment_reward_visible() -> bool:
	return equipment_reward_panel.visible if is_node_ready() else false


## Mirrors CardSystem and PatrolController authority into presentation. The HUD
## stores no playable cards or route mutations; every action is revisioned and
## forwarded through the typed signals above.
func present_district_cards(cards: Dictionary, patrol: Dictionary) -> void:
	_district_card_snapshot = cards.duplicate(true)
	_district_patrol_snapshot = patrol.duplicate(true)
	_focused_district_plan = bool(cards.get("district_plan_enabled", false))
	_district_card_hand = _extract_district_card_definitions(
		cards.get("offer", []) if _focused_district_plan else cards.get("hand", [])
	)
	if _district_card_panel_mode != DistrictCardPanelMode.REWARD:
		_district_card_choices = _district_card_hand.duplicate()
	_district_route_slots.clear()
	if not _focused_district_plan:
		_district_route_slots = _extract_district_route_slots(patrol)
	_district_card_hand_revision = int(
		cards.get("offer_revision", -1)
		if _focused_district_plan
		else cards.get("hand_revision", -1)
	)
	_district_card_route_revision = int(patrol.get("route_revision", -1))
	_district_plan_offer_revision = int(cards.get("offer_revision", -1))
	_district_plan_lifecycle_revision = int(
		cards.get("context_lifecycle_revision", -1)
	)
	_district_plan_lap_id = StringName(cards.get("lap_id", &""))
	_district_plan_block_id = StringName(cards.get("block_id", &""))
	_district_card_planning_allowed = bool(cards.get("planning_active", false)) if (
		_focused_district_plan
	) else (
		bool(cards.get("planning_allowed", true))
		and _card_planning_available_for_state(_last_flow_state)
	)
	_validate_district_card_selection()
	var staged_token: int = int(cards.get("staged_confirmation_token", -1))
	if (
		staged_token >= 0
		and StringName(cards.get("staged_card_id", &"")) == _district_selected_card_id
		and (
			_focused_district_plan
			or StringName(cards.get("staged_slot_id", &"")) == _district_selected_slot_id
		)
	):
		_district_confirmation_token = staged_token
		_district_card_stage_in_flight = false
	if not is_node_ready():
		return
	if (
		bool(cards.get("planning_active", false))
		and _district_card_panel_mode == DistrictCardPanelMode.CLOSED
		and _district_card_planning_allowed
	):
		_set_district_card_panel_mode(DistrictCardPanelMode.PLANNING)
	_refresh_district_card_compact_presentation()
	_refresh_route_label_with_card_markers()
	if district_card_panel.visible:
		_refresh_district_card_panel_presentation()


func present_district_card_reward(
	encounter_id: int,
	choice_token: int,
	choices: Array[DistrictCardDefinition],
	hand_revision: int,
	can_skip: bool = true
) -> void:
	if not is_node_ready():
		return
	dismiss_equipment_reward()
	build_details_panel.visible = false
	_set_help_expanded(false)
	_district_card_choices = choices.duplicate()
	_district_card_reward_encounter_id = encounter_id
	_district_card_reward_choice_token = choice_token
	_district_card_reward_can_skip = can_skip
	_district_card_hand_revision = hand_revision
	_district_card_action_in_flight = false
	_clear_district_card_selection(false)
	_set_district_card_panel_mode(DistrictCardPanelMode.REWARD)
	_refresh_district_card_panel_presentation()
	if not _district_card_choices.is_empty():
		_district_card_choice_buttons[0].grab_focus()
	elif can_skip:
		district_card_skip_button.grab_focus()


func present_district_card_placement_result(result: Dictionary) -> void:
	_district_card_stage_in_flight = false
	_district_card_action_in_flight = false
	if not is_node_ready():
		return
	var accepted: bool = bool(result.get("accepted", false))
	var reason: String = str(result.get("reason", &"invalid_placement"))
	var completed: bool = bool(result.get("completed", false))
	if _focused_district_plan:
		if accepted and completed:
			_district_confirmation_token = -1
			_district_selected_card_index = -1
			_district_selected_card_id = &""
			district_card_feedback.text = (
				"NEXT BLOCK LOCKED • %s • HEAT %s%d • WATCH FOR THIS RESULT"
				% [
					str(result.get("block_type", "DISTRICT BLOCK")),
					"+" if int(result.get("heat_delta", 0)) >= 0 else "",
					int(result.get("heat_delta", 0)),
				]
			)
			action_toast.show_message(
				"NEXT BLOCK: %s" % str(result.get("card_name", "PLAN")).to_upper(),
				NeonToast.Tone.SUCCESS
			)
		elif not accepted:
			district_card_feedback.text = "PLAN UNCHANGED • %s" % _humanize_card_result(reason)
			action_toast.show_message("DISTRICT PLAN UNCHANGED", NeonToast.Tone.WARNING)
		_refresh_district_card_panel_presentation()
		return
	if accepted and not completed:
		_district_confirmation_token = int(result.get("confirmation_token", -1))
		if _district_confirmation_token >= 0:
			district_card_feedback.text = (
				"PLACEMENT STAGED • REVIEW HEAT AND ROUTE EFFECT • CONFIRM TO PLAY"
			)
		else:
			accepted = false
			reason = "missing_confirmation_token"
	if accepted and completed:
		_district_confirmation_token = -1
		_district_selected_card_index = -1
		_district_selected_card_id = &""
		_district_selected_slot_id = &""
		district_card_feedback.text = "CARD PLAYED ONCE • HEAT AND ROUTE CHANGE ARE AUTHORITATIVE"
		action_toast.show_message("CARD CONFIRMED  /  ROUTE UPDATED", NeonToast.Tone.SUCCESS)
	elif not accepted:
		_district_confirmation_token = -1
		_district_selected_slot_id = &""
		district_card_feedback.text = "CARD RETURNED • NOTHING CHANGED • %s" % (
			_humanize_card_result(reason)
		)
		action_toast.show_message(
			"CARD RETURNED  /  NOTHING CHANGED",
			NeonToast.Tone.WARNING
		)
	_refresh_district_card_panel_presentation()
	if accepted and not completed and _district_confirmation_token >= 0:
		district_card_confirm_button.grab_focus()


func present_district_card_acquisition_result(
	accepted: bool,
	reason: String = ""
) -> void:
	_district_card_action_in_flight = false
	if not is_node_ready():
		return
	if accepted:
		action_toast.show_message("CARD ADDED TO HAND", NeonToast.Tone.SUCCESS)
		dismiss_district_card_panel()
		return
	district_card_feedback.text = "CARD NOT ADDED • HAND KEPT • %s" % (
		_humanize_card_result(reason if not reason.is_empty() else "request_rejected")
	)
	action_toast.show_message("HAND KEPT  /  CARD NOT ADDED", NeonToast.Tone.WARNING)
	_refresh_district_card_panel_presentation()


func dismiss_district_card_panel() -> void:
	if not is_node_ready():
		_district_card_panel_mode = DistrictCardPanelMode.CLOSED
		return
	if get_viewport().gui_get_drag_data() is DistrictCardDragPayload:
		_district_card_drag_cancelled = true
		get_viewport().gui_cancel_drag()
	_set_district_card_panel_mode(DistrictCardPanelMode.CLOSED)
	_district_card_reward_encounter_id = -1
	_district_card_reward_choice_token = -1
	_district_card_choices = _district_card_hand.duplicate()
	_district_card_action_in_flight = false
	_district_card_stage_in_flight = false
	_clear_district_card_selection(false)
	_refresh_district_card_compact_presentation()


## Mirrors the typed planning-authority lifecycle without echoing player intent.
## Opening remains snapshot-driven; an authority close always removes a stale
## planning modal, even when the destination state normally permits planning.
func present_district_card_planning_state(is_active: bool) -> void:
	if is_active or _district_card_panel_mode != DistrictCardPanelMode.PLANNING:
		return
	dismiss_district_card_panel()


func is_district_card_panel_visible() -> bool:
	return district_card_panel.visible if is_node_ready() else false


func get_district_card_panel_mode() -> int:
	return _district_card_panel_mode


func get_selected_district_card_id() -> StringName:
	return _district_selected_card_id


func get_selected_district_route_slot_id() -> StringName:
	return _district_selected_slot_id


func get_selected_reward_slot() -> int:
	return _selected_reward_slot


func get_selected_reward_choice() -> int:
	return _selected_reward_choice


func get_selected_reward_destination() -> StringName:
	return _selected_reward_destination


func get_selected_reward_backpack_slot() -> int:
	return _selected_reward_backpack_slot


func get_selected_inventory_area() -> StringName:
	return _selected_inventory_area


func get_selected_inventory_slot() -> int:
	return _selected_inventory_slot


func get_pending_inventory_action() -> StringName:
	return _pending_inventory_action


func get_pending_inventory_target() -> int:
	return _pending_inventory_target


func present_inventory_action_result(succeeded: bool) -> void:
	_inventory_action_in_flight = false
	if succeeded:
		action_toast.show_message("INVENTORY UPDATED", NeonToast.Tone.SUCCESS)
		_clear_inventory_selection()
	elif is_node_ready():
		inventory_action_prompt.text = "INVENTORY CHANGED OR ACTION REJECTED. REVIEW AND TRY AGAIN."
		action_toast.show_message("INVENTORY NOT CHANGED", NeonToast.Tone.WARNING)
	_refresh_build_presentation()


func present_inventory_transaction_preview(preview: Dictionary) -> void:
	_pending_inventory_preview = preview.duplicate(true)
	if is_node_ready():
		_refresh_inventory_action_presentation()


func present_equipment_action_result(succeeded: bool) -> void:
	_equipment_choice_in_flight = false
	if succeeded:
		action_toast.show_message("GEAR CHOICE CONFIRMED", NeonToast.Tone.SUCCESS)
	else:
		action_toast.show_message("GEAR NOT CHANGED", NeonToast.Tone.WARNING)
		for button: EquipmentDragSlot in _reward_choice_buttons:
			button.disabled = false
		_refresh_equipment_reward_presentation()


func present_shop_purchase_result(result: Dictionary) -> void:
	_last_shop_purchase_result = result.duplicate(true)
	if not is_node_ready():
		return
	if bool(result.get("accepted", false)):
		(shop_decision_panel.get_node("Instruction") as Label).text = (
			"Purchase applied exactly. Review the result, then leave to continue."
		)
		shop_cooling_choice.disabled = true
		shop_cooling_choice.text = (
			"PURCHASE COMPLETE\n%d COINS -> %d  /  HEAT %d -> %d\nTIER %d -> %d  /  STOCK %d -> %d"
			% [
				int(result.get("coins_before", 0)), int(result.get("coins_after", 0)),
				int(result.get("heat_before", 0)), int(result.get("heat_after", 0)),
				int(result.get("heat_tier_before", 0)), int(result.get("heat_tier_after", 0)),
				int(result.get("global_stock_before", 0)), int(result.get("global_stock_after", 0)),
			]
		)
		shop_cooling_choice.set_visual_state(
			NeonChoiceCard.VisualState.DISABLED,
			"PURCHASE COMPLETE  /  LEAVE SHOP"
		)
		shop_leave_choice.text = "LEAVE SHOP\nPURCHASE COMPLETE  /  KEEP %d COINS\nGLOBAL STOCK %d REMAINS" % [
			int(result.get("coins_after", 0)),
			int(result.get("global_stock_after", 0)),
		]
		shop_comparison.present(
			"PURCHASE COMPLETE",
			"HEAT %d  /  TIER %d" % [
				int(result.get("heat_before", 0)), int(result.get("heat_tier_before", 0)),
			],
			"HEAT %d  /  TIER %d" % [
				int(result.get("heat_after", 0)), int(result.get("heat_tier_after", 0)),
			],
			"REWARD QUALITY %d -> %d  /  COIN x%.2f -> x%.2f  /  NIGHT PRESSURE %.1f UNCHANGED" % [
				int(result.get("reward_quality_before", 0)),
				int(result.get("reward_quality_after", 0)),
				float(result.get("reward_multiplier_before", 1.0)),
				float(result.get("reward_multiplier_after", 1.0)),
				float(result.get("night_pressure", 0.0)),
			],
			true
		)
		action_toast.hide()
	else:
		action_toast.show_message(
			"SHOP UNCHANGED  /  %s" % String(result.get("reason", &"request_rejected")).replace("_", " ").to_upper(),
			NeonToast.Tone.WARNING
		)


func present_run_summary(summary: RunSummaryRecord) -> void:
	if summary == null:
		return
	summary_title.text = "%s  •  RUN COMPLETE" % summary.result_label
	summary_details.text = (
		"TIME %s   SEED %d   SCHEMA %d\n"
		+ "MAX HEAT %d   NIGHT PRESSURE %.1f   ENCOUNTERS %d\n"
		+ "ENEMIES %d   ELITES %d   BOSS %s   COMBO %d\n"
		+ "COINS %d   SCRAP %d   MANUAL %d   STREAK x%d\n"
		+ "EQUIPMENT %s   SYNERGIES %s"
	) % [
		_format_time(summary.duration_seconds),
		summary.run_seed,
		summary.random_schema_version,
		summary.maximum_heat,
		summary.final_night_pressure,
		summary.encounters_completed,
		summary.enemies_defeated,
		summary.elites_defeated,
		summary.boss_result,
		summary.highest_combo,
		summary.coins_collected,
		summary.scrap_secured,
		summary.manual_clusters_collected,
		summary.maximum_manual_streak,
		summary.equipment_build,
		summary.active_synergies,
	]
	summary_panel.visible = true
	boss_trigger_panel.visible = false


func present_action_feedback(message: String) -> void:
	if message.is_empty():
		return
	_hydrant_feedback = message
	hydrant_feedback_label.text = message
	action_toast.show_message(message, NeonToast.Tone.INFO)


func present_build_callout(
	icon: Texture2D,
	heading: String,
	detail: String,
	event_key: StringName,
	at_msec: int = -1
) -> bool:
	if build_callout == null:
		return false
	return build_callout.present(icon, heading, detail, event_key, at_msec)


func clear_build_callout() -> void:
	if build_callout != null:
		build_callout.clear()


## Presents an authoritative Hydrant snapshot. State values use the local
## HydrantPresentationState mapping; the button intentionally remains enabled
## so unavailable attempts reach gameplay authority and receive feedback.
func present_hydrant_state(
	state: int,
	cooldown_remaining: float,
	cooldown_total: float,
	valid_enemy_count: int,
	feedback: String
) -> void:
	_hydrant_state = state
	_hydrant_cooldown_remaining = maxf(0.0, cooldown_remaining)
	_hydrant_cooldown_total = maxf(0.001, cooldown_total)
	_hydrant_valid_enemy_count = maxi(0, valid_enemy_count)
	_hydrant_feedback = feedback.strip_edges()
	if is_node_ready():
		_refresh_hydrant_presentation()


func present_fullscreen_state(is_fullscreen: bool) -> void:
	_fullscreen_active = is_fullscreen
	if is_node_ready():
		_refresh_fullscreen_presentation()


## The prompt is intentionally presentation-only and ignores mouse input. A
## run-level input observer can unlock audio without stealing the same press
## from a coin, Hydrant, or HUD control.
func present_audio_unlock_required(is_required: bool) -> void:
	if not is_node_ready():
		return
	audio_unlock_panel.modulate = Color.WHITE
	audio_unlock_label.text = "CLICK / TAP / PRESS A KEY FOR SOUND"
	audio_unlock_panel.visible = (
		is_required
		and OS.has_feature("web")
		and not _audio_unlock_completed
	)


func present_audio_unlocked() -> void:
	_audio_unlock_completed = true
	if not is_node_ready():
		return
	if not OS.has_feature("web"):
		audio_unlock_panel.visible = false
		return
	audio_unlock_panel.visible = true
	audio_unlock_panel.modulate = Color.WHITE
	audio_unlock_label.text = "SOUND ON"
	var tween: Tween = create_tween()
	tween.tween_interval(0.75)
	tween.tween_property(audio_unlock_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(audio_unlock_panel.hide)


func present_landscape_state(is_landscape: bool) -> void:
	if not is_node_ready():
		return
	landscape_panel.visible = not is_landscape


## Keeps the edge-critical Hydrant, Help, and fullscreen controls inside native
## mobile safe areas. The standard Web shell already avoids notch overlap; its
## fallback display rect is ignored when it does not describe this window.
func apply_safe_area(safe_area: Rect2i, window_size: Vector2i) -> void:
	_pending_safe_area = safe_area
	_pending_window_size = window_size
	if is_node_ready():
		_refresh_safe_area_layout()


func _refresh_safe_area_layout() -> void:
	var left_inset: float = 0.0
	var right_inset: float = 0.0
	var top_inset: float = 0.0
	var bottom_inset: float = 0.0
	if _safe_area_matches_window(_pending_safe_area, _pending_window_size):
		var safe_end_x: int = _pending_safe_area.position.x + _pending_safe_area.size.x
		var safe_end_y: int = _pending_safe_area.position.y + _pending_safe_area.size.y
		var scale_x: float = DESIGN_SIZE.x / float(_pending_window_size.x)
		var scale_y: float = DESIGN_SIZE.y / float(_pending_window_size.y)
		left_inset = clampf(
			float(maxi(0, _pending_safe_area.position.x)) * scale_x,
			0.0,
			MAX_SAFE_INSET.x
		)
		top_inset = clampf(
			float(maxi(0, _pending_safe_area.position.y)) * scale_y,
			0.0,
			MAX_SAFE_INSET.y
		)
		right_inset = clampf(
			float(maxi(0, _pending_window_size.x - safe_end_x)) * scale_x,
			0.0,
			MAX_SAFE_INSET.x
		)
		bottom_inset = clampf(
			float(maxi(0, _pending_window_size.y - safe_end_y)) * scale_y,
			0.0,
			MAX_SAFE_INSET.y
		)

	var phase_x: float = maxf(20.0, left_inset)
	phase_banner.position = Vector2(phase_x, 16.0 + top_inset)
	phase_banner.size = Vector2(744.0 - (phase_x - 20.0), 92.0)
	run_status_panel.position = Vector2(776.0, 16.0 + top_inset)
	resources_panel.position = Vector2(
		maxf(1080.0 - right_inset, 1068.0),
		16.0 + top_inset
	)
	crew_panel.position = Vector2(20.0 + left_inset, 122.0 + top_inset)
	build_panel.position = Vector2(990.0 - right_inset, 122.0 + top_inset)
	var combat_hud: bool = _last_flow_state in [
		RunDirector.RunState.ENCOUNTER_ACTIVE,
		RunDirector.RunState.BOSS_INTRO,
		RunDirector.RunState.BOSS_ACTIVE,
	]
	if combat_hud:
		cards_panel.position = Vector2(360.0, 600.0 - bottom_inset)
		cards_panel.size = Vector2(560.0, 104.0)
	else:
		var action_strip_x: float = 280.0 + left_inset
		var action_strip_right: float = 1260.0 - right_inset
		cards_panel.position = Vector2(action_strip_x, 600.0 - bottom_inset)
		cards_panel.size = Vector2(action_strip_right - action_strip_x, 104.0)
		district_card_compact_panel.position.x = cards_panel.size.x - 238.0
	interventions_panel.position = (
		HYDRANT_PANEL_BASE_POSITION + Vector2(-right_inset, top_inset)
	)
	help_panel.position = HELP_PANEL_BASE_POSITION + Vector2(0.0, -bottom_inset)
	help_button.position = HELP_BUTTON_BASE_POSITION + Vector2(left_inset, -bottom_inset)
	fullscreen_button.position = FULLSCREEN_BUTTON_BASE_POSITION + Vector2(left_inset, -bottom_inset)
	lab_purpose_label.position = LAB_PURPOSE_BASE_POSITION + Vector2(left_inset, -bottom_inset)


func _safe_area_matches_window(safe_area: Rect2i, window_size: Vector2i) -> bool:
	if window_size.x <= 0 or window_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return false
	# Desktop/Web fallbacks often report the full monitor rather than the game
	# window. Only apply insets when the rect plausibly shares window coordinates.
	return (
		safe_area.size.x <= ceili(float(window_size.x) * 1.05)
		and safe_area.size.y <= ceili(float(window_size.y) * 1.05)
		and safe_area.position.x >= 0
		and safe_area.position.y >= 0
		and safe_area.position.x <= float(window_size.x) / 4.0
		and safe_area.position.y <= float(window_size.y) / 4.0
	)


func _refresh_hydrant_presentation() -> void:
	if not _environment_snapshot.is_empty():
		_refresh_production_environment_presentation()
		return
	hydrant_button.disabled = false
	var visual_state: int = NeonInterventionButton.VisualState.UNAVAILABLE
	var action_text: String = "HYDRANT"
	var status_text: String = "NEEDS TARGET"
	match _hydrant_state:
		HydrantPresentationState.AVAILABLE:
			visual_state = NeonInterventionButton.VisualState.READY
			hydrant_state_label.text = "READY • %d IN RANGE" % _hydrant_valid_enemy_count
			status_text = "READY  /  RANGE %d" % _hydrant_valid_enemy_count
			hydrant_cooldown_label.text = "READY NOW"
		HydrantPresentationState.COOLING_DOWN:
			visual_state = NeonInterventionButton.VisualState.COOLING
			hydrant_state_label.text = "COOLING DOWN"
			status_text = "COOLDOWN %.1fs" % _hydrant_cooldown_remaining
			hydrant_cooldown_label.text = "%.1fs REMAINING" % _hydrant_cooldown_remaining
		_:
			hydrant_state_label.text = "NO ENEMY IN RANGE"
			hydrant_cooldown_label.text = "READY • NEEDS TARGET"
	(hydrant_button as NeonInterventionButton).present(
		"1  ENV",
		action_text,
		status_text,
		visual_state,
		false
	)

	var elapsed_cooldown: float = clampf(
		_hydrant_cooldown_total - _hydrant_cooldown_remaining,
		0.0,
		_hydrant_cooldown_total
	)
	hydrant_cooldown_meter.max_value = _hydrant_cooldown_total
	hydrant_cooldown_meter.value = elapsed_cooldown
	hydrant_feedback_label.text = (
		_hydrant_feedback
		if not _hydrant_feedback.is_empty()
		else "READY + ENEMY IN RANGE"
	)

func _refresh_production_environment_presentation() -> void:
	var environment: Dictionary = _environment_snapshot
	var action_id: StringName = StringName(environment.get("action_id", &""))
	var can_activate: bool = bool(environment.get("can_activate", false))
	var cooldown: float = maxf(float(environment.get("cooldown_remaining", 0.0)), 0.0)
	var cooldown_duration: float = maxf(float(environment.get("cooldown_duration", 0.0)), 0.001)
	var target_count: int = maxi(int(environment.get("target_count", 0)), 0)
	var visual_state: int = NeonInterventionButton.VisualState.UNAVAILABLE
	var status_text: String = String(
		environment.get("validity_reason", "no environment context")
	).replace("_", " ").to_upper()
	if cooldown > 0.0:
		visual_state = NeonInterventionButton.VisualState.COOLING
		status_text = "COOLDOWN %.1fs" % cooldown
	elif can_activate:
		visual_state = NeonInterventionButton.VisualState.READY
		status_text = "%d TARGET%s" % [target_count, "" if target_count == 1 else "S"]
	var action_icon: Texture2D = environment.get("icon") as Texture2D
	if action_icon == null:
		action_icon = ICON_ENVIRONMENT
	var compact_verb: String = str(environment.get("verb", "INTERACT")).to_upper()
	if action_id == &"power_box":
		action_icon = ICON_POWER_BOX
		compact_verb = "BREAKER"
	hydrant_button.icon = action_icon
	($Root/InterventionsPanel/Title as Label).text = "1  ENVIRONMENT  /  CONTEXT"
	hydrant_state_label.text = str(environment.get("display_name", "NO CONTEXT")).to_upper()
	(hydrant_button as NeonInterventionButton).present(
		"1 ENV",
		compact_verb,
		status_text,
		visual_state,
		false
	)
	var elapsed_cooldown: float = clampf(cooldown_duration - cooldown, 0.0, cooldown_duration)
	hydrant_cooldown_meter.max_value = cooldown_duration
	hydrant_cooldown_meter.value = elapsed_cooldown
	hydrant_cooldown_label.text = (
		"READY  /  REVISION + TOKEN"
		if can_activate
		else status_text
	)
	var effect_label: Label = $Root/InterventionsPanel/EffectLabel as Label
	if action_id == &"power_box":
		effect_label.text = "4 DAMAGE • INTERRUPT • SHOCK\n96PX MARKED AREA"
	elif action_id == &"fire_hydrant":
		effect_label.text = "18 DAMAGE • WET\nSTRONG LEFT KNOCKBACK"
	else:
		effect_label.text = "NO COMBAT ENVIRONMENT\nWAIT FOR NEXT FIGHT"
	hydrant_feedback_label.text = status_text
	hydrant_button.tooltip_text = "%s State: %s. Invalid/stale requests consume no cooldown." % [
		str(environment.get("description", "Context Environment action.")),
		String(environment.get("validity_reason", &"invalid_state")).replace("_", " "),
	]


func _compact_wp05_attack_name(attack_name: String) -> String:
	var upper: String = attack_name.to_upper()
	if upper.contains("BOTTLE"):
		return "THROW"
	if upper.contains("ARMOURED CHARGE"):
		return "CHARGE"
	if upper.contains("VENOM RING"):
		return "AREA"
	if upper.contains("VIPER RUSH"):
		return "RUSH"
	if upper.contains("THREE-HIT"):
		return "COMBO"
	return upper.left(16)


func _compact_wp05_target_name(target_name: String) -> String:
	var upper: String = target_name.to_upper()
	if upper == "BOTTLE THROWER":
		return "THROWER"
	if upper == "VIPER ENFORCER":
		return "ENFORCER"
	if upper == "THE VIPER":
		return "VIPER"
	return upper.left(12)


func _refresh_fullscreen_presentation() -> void:
	fullscreen_button.text = "EXIT FULL" if _fullscreen_active else "FULLSCREEN"
	fullscreen_button.tooltip_text = (
		"Return to windowed presentation"
		if _fullscreen_active
		else "Fill the display while preserving the 16:9 game view"
	)


func _toggle_help() -> void:
	if district_card_panel.visible:
		return
	_set_help_expanded(not help_panel.visible)


func _set_help_expanded(is_expanded: bool) -> void:
	help_panel.visible = is_expanded
	help_button.text = "CLOSE HELP" if is_expanded else "HELP"
	if is_expanded:
		_onboarding_remaining = -1.0
	_refresh_district_card_compact_presentation()


func _on_hydrant_button_pressed() -> void:
	if not _environment_snapshot.is_empty():
		environment_activation_requested.emit(
			StringName(_environment_snapshot.get("action_id", &"")),
			int(_environment_snapshot.get("context_revision", -1)),
			int(_environment_snapshot.get("request_token", -1))
		)
		return
	hydrant_activation_requested.emit()


func _on_hydrant_preview_entered() -> void:
	if not _environment_snapshot.is_empty():
		environment_preview_requested.emit(true)
		return
	hydrant_preview_requested.emit(true)


func _on_hydrant_preview_exited() -> void:
	if not _environment_snapshot.is_empty():
		environment_preview_requested.emit(false)
		return
	hydrant_preview_requested.emit(false)


func _on_fullscreen_button_pressed() -> void:
	fullscreen_requested.emit()


func _on_primary_action_pressed() -> void:
	primary_action_requested.emit()


func _on_backup_pressed() -> void:
	if _backup_snapshot.has("request_context_revision"):
		backup_activation_context_requested.emit(
			int(_backup_snapshot.get("request_context_revision", -1)),
			int(_backup_snapshot.get("request_token", -1))
		)
		return
	backup_activation_requested.emit()


func _on_wp05_focus_pressed() -> void:
	focus_activation_requested.emit(
		int(_focus_snapshot.get("target_instance_id", -1)),
		StringName(_focus_snapshot.get("attack_id", &"")),
		int(_focus_snapshot.get("context_revision", -1)),
		int(_focus_snapshot.get("request_token", -1))
	)

func _on_subway_reroute_pressed() -> void:
	subway_reroute_requested.emit()


func _on_shop_cooling_pressed() -> void:
	shop_cooling_requested.emit(
		int(_shop_snapshot.get("shop_visit_revision", -1)),
		StringName(_shop_snapshot.get("shop_visit_source_id", &""))
	)


func _on_extraction_pressed() -> void:
	if bool(_district_loop_snapshot.get("enabled", false)):
		lap_extract_requested.emit(int(_district_loop_snapshot.get("decision_token", -1)))
	else:
		extraction_requested.emit()


func _on_extraction_continue_pressed() -> void:
	if bool(_district_loop_snapshot.get("enabled", false)):
		lap_push_requested.emit(int(_district_loop_snapshot.get("decision_token", -1)))
	else:
		primary_action_requested.emit()


func _on_restart_same_seed_pressed() -> void:
	restart_same_seed_requested.emit()


func _on_restart_new_seed_pressed() -> void:
	restart_new_seed_requested.emit()


func _on_district_card_open_pressed() -> void:
	if _focused_district_plan:
		if not bool(_district_card_snapshot.get("planning_active", false)):
			return
		_district_card_choices = _district_card_hand.duplicate()
		_clear_district_card_selection(false)
		_set_district_card_panel_mode(DistrictCardPanelMode.PLANNING)
		_refresh_district_card_panel_presentation()
		if not _district_card_choice_buttons.is_empty():
			_district_card_choice_buttons[0].grab_focus()
		return
	if (
		equipment_reward_panel.visible
		or not _district_card_planning_allowed
		or _district_card_hand.is_empty()
	):
		return
	_district_card_choices = _district_card_hand.duplicate()
	build_details_panel.visible = false
	_set_help_expanded(false)
	_clear_district_card_selection(false)
	district_card_feedback.text = "SELECT OR DRAG A CARD TO A VALID FUTURE ROUTE SLOT"
	_set_district_card_panel_mode(DistrictCardPanelMode.PLANNING)
	_refresh_district_card_panel_presentation()
	district_card_planning_open_requested.emit()
	if not _district_card_choice_buttons.is_empty():
		_district_card_choice_buttons[0].grab_focus()


func _on_district_card_close_pressed() -> void:
	if _district_card_panel_mode != DistrictCardPanelMode.PLANNING:
		return
	if _focused_district_plan:
		district_card_feedback.text = "CHOOSE THE NEXT BLOCK BEFORE CONTINUING"
		return
	if _district_confirmation_token >= 0:
		district_card_placement_cancel_requested.emit(_district_confirmation_token)
	_set_district_card_panel_mode(DistrictCardPanelMode.CLOSED)
	_clear_district_card_selection(false)
	district_card_planning_close_requested.emit()
	_refresh_district_card_compact_presentation()


func _on_district_card_choice_pressed(choice_index: int) -> void:
	if (
		_district_card_action_in_flight
		or choice_index < 0
		or choice_index >= _district_card_choices.size()
	):
		return
	if _district_confirmation_token >= 0:
		district_card_placement_cancel_requested.emit(_district_confirmation_token)
	_district_selected_card_index = choice_index
	_district_selected_card_id = _district_card_choices[choice_index].id
	_district_selected_slot_id = &""
	_district_confirmation_token = -1
	_district_card_stage_in_flight = false
	if _district_card_panel_mode == DistrictCardPanelMode.PLANNING:
		district_card_feedback.text = (
			"SELECTED • PREDICT THE HEAT, BLOCK TYPE, AND PAYOFF • CONFIRM ONCE"
			if _focused_district_plan
			else "CARD SELECTED • CHOOSE A VALID FUTURE SLOT"
		)
	else:
		district_card_feedback.text = "CARD SELECTED • CONFIRM TO ADD IT ONCE"
	_refresh_district_card_panel_presentation()
	if _district_card_panel_mode == DistrictCardPanelMode.PLANNING:
		if _focused_district_plan:
			district_card_confirm_button.grab_focus()
		else:
			_focus_first_valid_district_route_slot()
	else:
		district_card_confirm_button.grab_focus()


func _on_district_card_drag_started(payload: DistrictCardDragPayload) -> void:
	if _focused_district_plan:
		return
	if payload == null or payload.origin != DistrictCardDragPayload.Origin.HAND:
		return
	_district_card_drag_cancelled = false
	if payload.source_index >= 0 and payload.source_index < _district_card_choices.size():
		_district_selected_card_index = payload.source_index
		_district_selected_card_id = payload.card_id
		_district_selected_slot_id = &""
		_district_confirmation_token = -1
	district_card_feedback.text = (
		"DRAGGING %s • VALID SLOTS SAY VALID • RELEASE TO STAGE"
		% payload.display_name.to_upper()
	)
	_refresh_district_card_panel_presentation()


func _on_district_card_drag_ended(
	payload: DistrictCardDragPayload,
	successful: bool
) -> void:
	if payload == null or successful:
		return
	_district_selected_slot_id = &""
	_district_confirmation_token = -1
	_district_card_stage_in_flight = false
	if _district_card_drag_cancelled:
		district_card_feedback.text = "DRAG CANCELLED • CARD RETURNED TO HAND • NOTHING CHANGED"
	else:
		district_card_feedback.text = "OUTSIDE OR INVALID DROP • CARD RETURNED TO HAND • NOTHING CHANGED"
	_district_card_drag_cancelled = false
	_refresh_district_card_panel_presentation()


func _on_district_route_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _district_route_slots.size():
		return
	var slot: Dictionary = _district_route_slots[slot_index]
	var card: DistrictCardDefinition = _selected_district_card()
	if card == null:
		district_card_feedback.text = "SELECT A CARD FIRST • ROUTE STATE IS UNCHANGED"
		return
	if not _district_route_slot_is_valid(slot, card):
		district_card_feedback.text = "PLACEMENT REJECTED • %s • NOTHING CHANGED" % (
			_humanize_card_result(String(_district_route_slot_status(slot, card)))
		)
		_refresh_district_card_panel_presentation()
		return
	_stage_district_card_placement(card, slot)


func _on_district_card_drop_requested(
	payload: DistrictCardDragPayload,
	target_slot_id: StringName
) -> void:
	if (
		payload == null
		or payload.origin != DistrictCardDragPayload.Origin.HAND
		or payload.hand_revision != _district_card_hand_revision
		or payload.route_revision != _district_card_route_revision
		or payload.card_id != _district_selected_card_id
	):
		district_card_feedback.text = "STALE OR INVALID DROP • CARD RETURNED • NOTHING CHANGED"
		return
	var slot_index: int = _district_route_slot_index(target_slot_id)
	if slot_index < 0:
		district_card_feedback.text = "OUTSIDE DROP • CARD RETURNED • NOTHING CHANGED"
		return
	var card: DistrictCardDefinition = _selected_district_card()
	var slot: Dictionary = _district_route_slots[slot_index]
	if card == null or not _district_route_slot_is_valid(slot, card):
		district_card_feedback.text = "INVALID DROP • CARD RETURNED • NOTHING CHANGED"
		return
	_stage_district_card_placement(card, slot)


func _stage_district_card_placement(
	card: DistrictCardDefinition,
	slot: Dictionary
) -> void:
	if (
		card == null
		or _district_card_stage_in_flight
		or _district_card_action_in_flight
		or not _district_route_slot_is_valid(slot, card)
	):
		return
	if _district_confirmation_token >= 0:
		district_card_placement_cancel_requested.emit(_district_confirmation_token)
	_district_selected_slot_id = StringName(slot.get("slot_id", &""))
	_district_confirmation_token = -1
	_district_card_stage_in_flight = true
	district_card_feedback.text = "VALID PLACEMENT REQUESTED • CHECKING CURRENT ROUTE REVISION"
	_refresh_district_card_panel_presentation()
	district_card_placement_staged.emit(
		card.id,
		_district_selected_slot_id,
		_district_card_hand_revision,
		_district_card_route_revision
	)


func _on_district_card_confirm_pressed() -> void:
	if _district_card_action_in_flight:
		return
	if _district_card_panel_mode == DistrictCardPanelMode.PLANNING:
		if _focused_district_plan:
			if _district_selected_card_id == &"":
				return
			_district_card_action_in_flight = true
			_refresh_district_card_panel_presentation()
			district_plan_choice_requested.emit(
				_district_selected_card_id,
				_district_plan_offer_revision,
				_district_plan_lifecycle_revision,
				_district_plan_lap_id,
				_district_plan_block_id
			)
			return
		if _district_confirmation_token < 0:
			return
		_district_card_action_in_flight = true
		_refresh_district_card_panel_presentation()
		district_card_placement_confirm_requested.emit(_district_confirmation_token)
		return
	if (
		_district_card_panel_mode != DistrictCardPanelMode.REWARD
		or _district_selected_card_index < 0
		or _district_selected_card_index >= _district_card_choices.size()
		or _district_card_reward_encounter_id < 0
		or _district_card_reward_choice_token < 0
	):
		return
	_district_card_action_in_flight = true
	_refresh_district_card_panel_presentation()
	district_card_reward_acquisition_requested.emit(
		_district_card_reward_encounter_id,
		_district_card_reward_choice_token,
		_district_selected_card_index,
		_district_card_hand_revision
	)


func _on_district_card_cancel_pressed() -> void:
	if _district_card_action_in_flight:
		return
	if _district_card_panel_mode == DistrictCardPanelMode.PLANNING:
		if _focused_district_plan:
			_district_selected_card_index = -1
			_district_selected_card_id = &""
			district_card_feedback.text = "SELECTION CLEARED • OFFER AND HEAT UNCHANGED"
			_refresh_district_card_panel_presentation()
			if not _district_card_choices.is_empty():
				_district_card_choice_buttons[0].grab_focus()
			return
		if _district_confirmation_token >= 0:
			district_card_placement_cancel_requested.emit(_district_confirmation_token)
		_district_selected_slot_id = &""
		_district_confirmation_token = -1
		_district_card_stage_in_flight = false
		district_card_feedback.text = "PLACEMENT CLEARED • CARD REMAINS IN HAND • NOTHING CHANGED"
	else:
		_district_selected_card_index = -1
		_district_selected_card_id = &""
		district_card_feedback.text = "SELECTION CLEARED • HAND IS UNCHANGED"
	_refresh_district_card_panel_presentation()


func _on_district_card_skip_pressed() -> void:
	if (
		_district_card_panel_mode != DistrictCardPanelMode.REWARD
		or not _district_card_reward_can_skip
		or _district_card_action_in_flight
		or _district_card_reward_encounter_id < 0
		or _district_card_reward_choice_token < 0
	):
		return
	_district_card_action_in_flight = true
	_refresh_district_card_panel_presentation()
	district_card_reward_skip_requested.emit(
		_district_card_reward_encounter_id,
		_district_card_reward_choice_token
	)


func _toggle_build_details() -> void:
	if equipment_reward_panel.visible or district_card_panel.visible:
		return
	build_details_panel.visible = not build_details_panel.visible
	if build_details_panel.visible:
		help_panel.visible = false
		build_details_panel.move_to_front()
		_refresh_build_presentation()
	else:
		_clear_inventory_selection()


func _on_equipment_slot_pressed(slot_index: int) -> void:
	if equipment_reward_panel.visible or district_card_panel.visible:
		return
	build_details_panel.visible = true
	build_details_panel.move_to_front()
	help_panel.visible = false
	_on_inventory_item_pressed(SynergySystem.AREA_EQUIPPED, slot_index)


func _on_inventory_item_pressed(area: StringName, slot_index: int) -> void:
	if _inventory_action_in_flight:
		return
	if (
		_inventory_management_enabled
		and _selected_inventory_id != &""
		and _selected_inventory_area != area
	):
		_stage_inventory_destination(area, slot_index)
		return
	var slot: Dictionary = _inventory_slot(area, slot_index)
	var equipment_id: StringName = StringName(slot.get("id", &""))
	if equipment_id == &"":
		_clear_inventory_selection()
		return
	_selected_inventory_area = area
	_selected_inventory_slot = slot_index
	_selected_inventory_id = equipment_id
	_pending_inventory_action = &""
	_pending_inventory_target = -1
	_refresh_build_presentation()


func toggle_build_details() -> void:
	_toggle_build_details()


func _on_inventory_action_target_pressed(target_slot: int) -> void:
	if (
		_inventory_action_in_flight
		or not _inventory_management_enabled
		or _selected_inventory_id == &""
		or target_slot < 0
		or target_slot >= SynergySystem.SLOT_COUNT
	):
		return
	var target_area: StringName = (
		SynergySystem.AREA_BACKPACK
		if _selected_inventory_area == SynergySystem.AREA_EQUIPPED
		else SynergySystem.AREA_EQUIPPED
	)
	_stage_inventory_destination(target_area, target_slot)


func _stage_inventory_destination(target_area: StringName, target_slot: int) -> void:
	if (
		_inventory_action_in_flight
		or not _inventory_management_enabled
		or _selected_inventory_id == &""
		or target_area == _selected_inventory_area
		or (
			target_area != SynergySystem.AREA_EQUIPPED
			and target_area != SynergySystem.AREA_BACKPACK
		)
		or target_slot < 0
		or target_slot >= SynergySystem.SLOT_COUNT
	):
		return
	_pending_inventory_target = target_slot
	var target: Dictionary = _inventory_slot(target_area, target_slot)
	var target_id: StringName = StringName(target.get("id", &""))
	_pending_inventory_action = &"swap"
	if (
		_selected_inventory_area == SynergySystem.AREA_EQUIPPED
		and target_area == SynergySystem.AREA_BACKPACK
		and target_id == &""
	):
		_pending_inventory_action = &"move_to_backpack"
	_request_inventory_preview()
	_refresh_inventory_action_presentation()


func _on_equipment_drag_started(payload: EquipmentDragPayload) -> void:
	if payload.origin == EquipmentDragPayload.Origin.REWARD:
		_reward_drag_active = true
		_refresh_equipment_reward_presentation()
		reward_instruction_label.text = (
			"DRAGGING %s • HIGHLIGHTED ACTIVE/BACKPACK SLOTS ARE VALID • RELEASE TO STAGE"
			% payload.display_name.to_upper()
		)
		return
	inventory_action_prompt.text = (
		"DRAGGING %s\nDROP IN THE OTHER COLUMN" % payload.display_name.to_upper()
	)


func _on_equipment_drag_ended(
	payload: EquipmentDragPayload,
	successful: bool
) -> void:
	if payload.origin == EquipmentDragPayload.Origin.REWARD:
		_reward_drag_active = false
		if equipment_reward_panel.visible:
			_refresh_equipment_reward_presentation()
		if not successful and equipment_reward_panel.visible:
			reward_instruction_label.text = (
				"INVALID / OUTSIDE DROP • GEAR RETURNED • INVENTORY UNCHANGED"
			)
		return
	if successful:
		return
	if payload.origin == EquipmentDragPayload.Origin.INVENTORY and build_details_panel.visible:
		inventory_action_prompt.text = (
			"INVALID / OUTSIDE DROP • ITEM RETURNED • INVENTORY UNCHANGED"
		)


func _on_inventory_drag_drop(
	payload: EquipmentDragPayload,
	target_area: StringName,
	target_slot: int
) -> void:
	if (
		payload.origin != EquipmentDragPayload.Origin.INVENTORY
		or not _inventory_management_enabled
		or _inventory_action_in_flight
		or target_area == payload.source_area
		or target_slot < 0
		or target_slot >= SynergySystem.SLOT_COUNT
	):
		inventory_action_prompt.text = "DROP REJECTED • INVENTORY UNCHANGED"
		return
	if payload.inventory_revision != int(_build_snapshot.get("inventory_revision", -1)):
		inventory_action_prompt.text = "STALE DROP REJECTED • INVENTORY UNCHANGED"
		return
	var source: Dictionary = _inventory_slot(payload.source_area, payload.source_slot)
	if StringName(source.get("id", &"")) != payload.equipment_id:
		inventory_action_prompt.text = "STALE DROP REJECTED • INVENTORY UNCHANGED"
		return
	_selected_inventory_area = payload.source_area
	_selected_inventory_slot = payload.source_slot
	_selected_inventory_id = payload.equipment_id
	_pending_inventory_action = &""
	_pending_inventory_target = -1
	_stage_inventory_destination(target_area, target_slot)


func _on_reward_drag_drop(
	payload: EquipmentDragPayload,
	target_area: StringName,
	target_slot: int
) -> void:
	if (
		payload.origin != EquipmentDragPayload.Origin.REWARD
		or _equipment_choice_in_flight
		or not equipment_reward_panel.visible
		or payload.encounter_id != _reward_encounter_id
		or (payload.choice_token >= 0 and payload.choice_token != _reward_choice_token)
		or payload.inventory_revision != int(_build_snapshot.get("inventory_revision", -1))
		or payload.choice_index < 0
		or payload.choice_index >= _reward_choices.size()
		or _reward_choices[payload.choice_index].id != payload.equipment_id
	):
		reward_instruction_label.text = "DROP REJECTED • REWARD AND INVENTORY UNCHANGED"
		return
	_on_reward_choice_pressed(payload.choice_index)
	if target_area == SynergySystem.AREA_EQUIPPED:
		_on_reward_target_pressed(target_slot)
	elif target_area == SynergySystem.AREA_BACKPACK:
		_on_reward_store_pressed(target_slot)


func _on_inventory_discard_pressed() -> void:
	if (
		_inventory_action_in_flight
		or not _inventory_management_enabled
		or _selected_inventory_id == &""
	):
		return
	_pending_inventory_action = &"discard"
	_pending_inventory_target = -1
	_request_inventory_preview()
	_refresh_inventory_action_presentation()


func _on_inventory_confirm_pressed() -> void:
	if (
		_inventory_action_in_flight
		or not _inventory_management_enabled
		or _pending_inventory_action == &""
	):
		return
	var revision: int = int(_build_snapshot.get("inventory_revision", -1))
	_inventory_action_in_flight = true
	if _pending_inventory_action == &"swap":
		if _selected_inventory_area == SynergySystem.AREA_EQUIPPED:
			inventory_swap_requested.emit(
				_selected_inventory_slot,
				_pending_inventory_target,
				revision
			)
		else:
			inventory_swap_requested.emit(
				_pending_inventory_target,
				_selected_inventory_slot,
				revision
			)
	elif _pending_inventory_action == &"move_to_backpack":
		inventory_move_requested.emit(
			_selected_inventory_slot,
			_pending_inventory_target,
			false,
			revision
		)
	elif _pending_inventory_action == &"discard":
		inventory_discard_requested.emit(
			_selected_inventory_area,
			_selected_inventory_slot,
			_selected_inventory_id,
			revision
		)
	else:
		_inventory_action_in_flight = false


func _clear_inventory_pending_action() -> void:
	_pending_inventory_action = &""
	_pending_inventory_target = -1
	_pending_inventory_preview.clear()
	if is_node_ready():
		_refresh_inventory_action_presentation()


func _request_inventory_preview() -> void:
	_pending_inventory_preview.clear()
	if _pending_inventory_action == &"" or _selected_inventory_id == &"":
		return
	inventory_preview_requested.emit(
		_pending_inventory_action,
		_selected_inventory_area,
		_selected_inventory_slot,
		_pending_inventory_target,
		_selected_inventory_id,
		int(_build_snapshot.get("inventory_revision", -1))
	)


func _on_reward_target_pressed(slot_index: int) -> void:
	if (
		_equipment_choice_in_flight
		or _selected_reward_choice < 0
		or slot_index < 0
		or slot_index >= SynergySystem.SLOT_COUNT
	):
		return
	_selected_reward_destination = SynergySystem.AREA_EQUIPPED
	_selected_reward_slot = slot_index
	_selected_reward_backpack_slot = -1
	_selected_reward_outgoing_backpack_slot = -1
	var equipped_slot: Dictionary = _inventory_slot(SynergySystem.AREA_EQUIPPED, slot_index)
	if StringName(equipped_slot.get("id", &"")) != &"":
		_selected_reward_outgoing_backpack_slot = _first_empty_backpack_slot()
	_refresh_equipment_reward_presentation()


func _on_reward_store_pressed(slot_index: int) -> void:
	if (
		_equipment_choice_in_flight
		or _selected_reward_choice < 0
		or slot_index < 0
		or slot_index >= SynergySystem.BACKPACK_SLOT_COUNT
	):
		return
	_selected_reward_destination = SynergySystem.AREA_BACKPACK
	_selected_reward_slot = -1
	_selected_reward_backpack_slot = slot_index
	_selected_reward_outgoing_backpack_slot = -1
	_refresh_equipment_reward_presentation()


func _on_reward_pack_target_pressed(slot_index: int) -> void:
	if (
		_equipment_choice_in_flight
		or _selected_reward_destination != SynergySystem.AREA_EQUIPPED
		or slot_index < 0
		or slot_index >= SynergySystem.BACKPACK_SLOT_COUNT
	):
		return
	_selected_reward_outgoing_backpack_slot = slot_index
	_refresh_equipment_reward_presentation()


func _on_reward_choice_pressed(choice_index: int) -> void:
	if (
		_equipment_choice_in_flight
		or _reward_encounter_id < 0
		or choice_index < 0
		or choice_index >= _reward_choices.size()
	):
		return
	_selected_reward_choice = choice_index
	_selected_reward_destination = &""
	_selected_reward_backpack_slot = -1
	_selected_reward_outgoing_backpack_slot = -1
	# Empty active slots are safe defaults. Occupied slots are never selected
	# automatically, so a full build cannot evict an item by accident.
	_selected_reward_slot = _first_empty_build_slot()
	_refresh_equipment_reward_presentation()


func _on_reward_confirm_pressed() -> void:
	if _equipment_choice_in_flight or not _reward_selection_is_complete():
		return
	_equipment_choice_in_flight = true
	for button: EquipmentDragSlot in _reward_choice_buttons:
		button.disabled = true
	var backpack_slot: int = _selected_reward_backpack_slot
	if _selected_reward_destination == SynergySystem.AREA_EQUIPPED:
		backpack_slot = _selected_reward_outgoing_backpack_slot
	equipment_acquisition_requested.emit(
		_reward_encounter_id,
		_reward_choice_token,
		_selected_reward_choice,
		_selected_reward_destination,
		_selected_reward_slot,
		backpack_slot,
		_reward_replaces_stored_item(),
		int(_build_snapshot.get("inventory_revision", -1))
	)


func _on_reward_keep_current_pressed() -> void:
	if _equipment_choice_in_flight or _reward_encounter_id < 0:
		return
	_equipment_choice_in_flight = true
	equipment_reward_decline_requested.emit(_reward_encounter_id, _reward_choice_token)


func _clear_reward_selection() -> void:
	if _equipment_choice_in_flight:
		return
	_selected_reward_choice = -1
	_selected_reward_destination = &""
	_selected_reward_slot = -1
	_selected_reward_backpack_slot = -1
	_selected_reward_outgoing_backpack_slot = -1
	_refresh_equipment_reward_presentation()


func _set_district_card_panel_mode(mode: int) -> void:
	_district_card_panel_mode = mode
	if not is_node_ready():
		return
	district_card_panel.visible = mode != DistrictCardPanelMode.CLOSED
	if not district_card_panel.visible:
		return
	if (
		_focused_district_plan
		and mode == DistrictCardPanelMode.PLANNING
		and action_toast != null
	):
		action_toast.hide()
	build_details_panel.visible = false
	_set_help_expanded(false)
	district_card_panel.move_to_front()
	district_card_close_button.visible = not (
		_focused_district_plan and mode == DistrictCardPanelMode.PLANNING
	)
	district_card_close_button.disabled = (
		mode == DistrictCardPanelMode.REWARD or _focused_district_plan
	)
	district_card_close_button.text = "CLOSE" if mode == DistrictCardPanelMode.PLANNING else "REWARD"
	for button: DistrictCardDragSlot in _district_route_slot_buttons:
		button.visible = (
			mode == DistrictCardPanelMode.PLANNING and not _focused_district_plan
		)
	district_card_skip_button.visible = (
		mode == DistrictCardPanelMode.REWARD and _district_card_reward_can_skip
	)
	district_card_route_preview.visible = true


func _clear_district_card_selection(refresh: bool = true) -> void:
	_district_selected_card_index = -1
	_district_selected_card_id = &""
	_district_selected_slot_id = &""
	_district_confirmation_token = -1
	_district_card_stage_in_flight = false
	if refresh and is_node_ready():
		_refresh_district_card_panel_presentation()


func _validate_district_card_selection() -> void:
	if _district_selected_card_id == &"":
		_district_selected_card_index = -1
		_district_selected_slot_id = &""
		_district_confirmation_token = -1
		return
	var matching_index: int = -1
	for choice_index: int in range(_district_card_choices.size()):
		var card: DistrictCardDefinition = _district_card_choices[choice_index]
		if card != null and card.id == _district_selected_card_id:
			matching_index = choice_index
			break
	if matching_index < 0:
		_clear_district_card_selection(false)
		return
	_district_selected_card_index = matching_index
	if (
		_district_selected_slot_id != &""
		and _district_route_slot_index(_district_selected_slot_id) < 0
	):
		_district_selected_slot_id = &""
		_district_confirmation_token = -1


func _extract_district_card_definitions(value: Variant) -> Array[DistrictCardDefinition]:
	var result: Array[DistrictCardDefinition] = []
	if not (value is Array):
		return result
	for entry: Variant in value as Array:
		var card: DistrictCardDefinition = entry as DistrictCardDefinition
		if card == null and entry is Dictionary:
			var entry_dictionary: Dictionary = entry as Dictionary
			card = entry_dictionary.get("definition") as DistrictCardDefinition
			if card == null:
				card = entry_dictionary.get("card") as DistrictCardDefinition
		if card != null:
			result.append(card)
	return result


func _extract_district_route_slots(patrol: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = patrol.get("future_route_slots", [])
	if not (value is Array):
		return result
	for entry: Variant in value as Array:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
		if result.size() >= DISTRICT_ROUTE_SLOT_COUNT:
			break
	return result


func _card_planning_available_for_state(state: int) -> bool:
	return state in [
		RunDirector.RunState.PATROLLING,
		RunDirector.RunState.SHOP,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		RunDirector.RunState.PAUSED,
	]


func _refresh_district_card_compact_presentation() -> void:
	if not is_node_ready():
		return
	if _focused_district_plan:
		var pending: Dictionary = _district_card_snapshot.get("selected_next_block", {})
		var active: Dictionary = _district_card_snapshot.get("active_block", {})
		var planning_active: bool = bool(
			_district_card_snapshot.get("planning_active", false)
		)
		if planning_active:
			district_card_compact_summary.text = "PLAN • CHOOSE NEXT BLOCK"
		elif not pending.is_empty():
			district_card_compact_summary.text = "NEXT • %s" % str(
				pending.get("card_name", "DISTRICT BLOCK")
			).to_upper()
		elif not active.is_empty():
			district_card_compact_summary.text = "NOW • %s" % str(
				active.get("card_name", "DISTRICT BLOCK")
			).to_upper()
		else:
			district_card_compact_summary.text = "DISTRICT PLAN • HISTORY READY"
		district_card_open_button.disabled = not planning_active or district_card_panel.visible
		district_card_open_button.text = (
			"PLAN OPEN" if district_card_panel.visible
			else ("CHOOSE" if planning_active else "VIEW NEXT")
		)
		district_card_open_button.tooltip_text = (
			"District Plan chooses the immediately next block. The confirmed card is shown until its consequence occurs."
		)
		return
	var hand_count: int = int(
		_district_card_snapshot.get("hand_count", _district_card_hand.size())
	)
	var hand_capacity: int = int(
		_district_card_snapshot.get("hand_capacity", DISTRICT_CARD_HAND_CAPACITY)
	)
	var draw_count: int = _district_card_count("draw_count", "draw_ids")
	var discard_count: int = _district_card_count("discard_count", "discard_ids")
	district_card_compact_summary.text = "H%d/%d  D%d  X%d" % [
		hand_count,
		hand_capacity,
		draw_count,
		discard_count,
	]
	var can_open: bool = (
		_district_card_planning_allowed
		and hand_count > 0
		and not equipment_reward_panel.visible
		and not district_card_panel.visible
		and not help_panel.visible
	)
	district_card_open_button.disabled = not can_open
	if hand_count <= 0:
		district_card_open_button.text = "HAND EMPTY"
	elif not _district_card_planning_allowed:
		district_card_open_button.text = "CARDS LOCKED"
	elif district_card_panel.visible:
		district_card_open_button.text = "CARDS OPEN"
	else:
		district_card_open_button.text = "PLAN CARDS"
	district_card_open_button.tooltip_text = (
		"Open the District Card hand and five fixed future route occurrences. "
		+ "Planning is available only in safe route states outside combat."
	)


func _refresh_district_card_panel_presentation() -> void:
	if not is_node_ready() or _district_card_panel_mode == DistrictCardPanelMode.CLOSED:
		return
	if _focused_district_plan and _district_card_panel_mode == DistrictCardPanelMode.PLANNING:
		_refresh_focused_district_plan_presentation()
		return
	district_card_title.text = (
		"DISTRICT PLAN  /  CARD REWARD  /  CHOOSE ONE OR KEEP HAND"
		if _district_card_panel_mode == DistrictCardPanelMode.REWARD
		else "DISTRICT PLAN  /  CURRENT FIXED ROUTE"
	)
	district_card_counts.text = _district_card_counts_text()
	_refresh_district_card_choice_presentation()
	_refresh_district_route_slot_presentation()
	district_card_route_preview.text = _district_route_preview_text()
	var reward_hand_full: bool = bool(_district_card_snapshot.get("reward_hand_full", false))
	if _district_card_panel_mode == DistrictCardPanelMode.REWARD:
		district_card_instruction.text = (
			"SELECT A REMAINING CARD • CONFIRM ADDS IT ONCE • OR SKIP AND KEEP HAND"
		)
		district_card_skip_button.text = "SKIP / KEEP HAND"
		district_card_skip_button.disabled = (
			not _district_card_reward_can_skip or _district_card_action_in_flight
		)
		district_card_confirm_button.text = "ADD CARD"
		district_card_confirm_button.disabled = (
			_district_selected_card_index < 0
			or reward_hand_full
			or _district_card_action_in_flight
		)
		district_card_cancel_button.text = "CLEAR CHOICE"
		district_card_cancel_button.disabled = (
			_district_selected_card_index < 0 or _district_card_action_in_flight
		)
		if reward_hand_full:
			district_card_feedback.text = "HAND FULL • SKIP / KEEP HAND • NO CARD OR REWARD STATE IS LOST"
		elif _district_card_choices.is_empty():
			district_card_feedback.text = "NO REMAINING VALID CARDS • SKIP / KEEP HAND"
	else:
		district_card_instruction.text = (
			"SELECT OR DRAG A CARD • CHOOSE A FUTURE SLOT • REVIEW • CONFIRM"
		)
		district_card_confirm_button.text = "PLAY CARD"
		district_card_confirm_button.disabled = (
			_district_confirmation_token < 0
			or _district_card_action_in_flight
			or _district_card_stage_in_flight
		)
		district_card_cancel_button.text = "CLEAR SLOT"
		district_card_cancel_button.disabled = (
			_district_selected_slot_id == &""
			and _district_confirmation_token < 0
			and not _district_card_stage_in_flight
		)
	_refresh_district_card_compact_presentation()


func _refresh_focused_district_plan_presentation() -> void:
	var lap_index: int = int(_district_card_snapshot.get("lap_index", 1))
	var block_index: int = int(_district_card_snapshot.get("block_index", 1))
	district_card_title.text = "DISTRICT PLAN • LAP %d / 3 • BLOCK %d / 3" % [
		lap_index,
		block_index,
	]
	district_card_counts.text = _district_card_counts_text()
	district_card_instruction.text = (
		"SELECT ONE LOCATION • PREDICT ITS BLOCK, HEAT, AND PAYOFF • CONFIRM ONCE"
	)
	_refresh_district_card_choice_presentation()
	for button: DistrictCardDragSlot in _district_route_slot_buttons:
		button.visible = false
	district_card_route_preview.visible = true
	district_card_route_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	district_card_route_preview.text = _focused_district_plan_preview_text()
	district_card_skip_button.visible = false
	district_card_close_button.visible = false
	district_card_confirm_button.visible = true
	district_card_confirm_button.text = "CONFIRM NEXT BLOCK"
	district_card_confirm_button.disabled = (
		_district_selected_card_id == &"" or _district_card_action_in_flight
	)
	district_card_cancel_button.visible = true
	district_card_cancel_button.text = "CLEAR SELECTION"
	district_card_cancel_button.disabled = (
		_district_selected_card_id == &"" or _district_card_action_in_flight
	)
	if _district_card_action_in_flight:
		district_card_feedback.text = "CONFIRMING THE EXACT OFFER AND BLOCK REVISION..."
	elif _district_selected_card_id == &"":
		district_card_feedback.text = (
			"WHAT YOU CONFIRM BECOMES THE IMMEDIATELY NEXT BLOCK. NIGHT PRESSURE NEVER COOLS."
		)
	else:
		var selected: DistrictCardDefinition = _selected_district_card()
		if selected != null:
			district_card_feedback.text = (
				"PREDICTION • NEXT: %s • HEAT %s • %s"
				% [
					CardSystem.focused_block_type(selected),
					_signed_integer(selected.heat_delta),
					CardSystem.focused_special_rule(selected),
				]
			)
	_refresh_district_card_compact_presentation()


func _layout_focused_district_choices() -> void:
	if not _focused_district_plan or not is_node_ready():
		return
	_set_rect(district_card_title, Rect2(20.0, 8.0, 690.0, 38.0))
	district_card_title.clip_text = true
	district_card_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_rect(district_card_counts, Rect2(720.0, 10.0, 420.0, 32.0))
	district_card_counts.clip_text = true
	district_card_counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	district_card_counts.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var choice_count: int = _district_card_choices.size()
	if choice_count <= 1:
		_set_rect(district_card_choice_01, Rect2(320.0, 54.0, 500.0, 250.0))
	elif choice_count == 2:
		_set_rect(district_card_choice_01, Rect2(50.0, 54.0, 500.0, 250.0))
		_set_rect(district_card_choice_02, Rect2(590.0, 54.0, 500.0, 250.0))
	else:
		_set_rect(district_card_choice_01, Rect2(20.0, 54.0, 350.0, 250.0))
		_set_rect(district_card_choice_02, Rect2(405.0, 54.0, 350.0, 250.0))
		_set_rect(district_card_choice_03, Rect2(790.0, 54.0, 350.0, 250.0))
	for choice_index: int in range(DISTRICT_CARD_HAND_CAPACITY):
		var button: DistrictCardDragSlot = _district_card_choice_buttons[choice_index]
		var details: Label = _district_card_choice_details[choice_index]
		var detail_width: float = maxf(button.size.x - 122.0, 210.0)
		_set_rect(details, Rect2(112.0, 6.0, detail_width, 238.0))
	_set_rect(district_card_instruction, Rect2(20.0, 314.0, 1120.0, 46.0))
	_set_rect(district_card_route_preview, Rect2(20.0, 366.0, 1120.0, 100.0))
	_set_rect(district_card_feedback, Rect2(20.0, 476.0, 720.0, 126.0))
	_set_rect(district_card_confirm_button, Rect2(760.0, 536.0, 210.0, 58.0))
	_set_rect(district_card_cancel_button, Rect2(986.0, 536.0, 154.0, 58.0))


func _refresh_district_card_choice_presentation() -> void:
	_layout_focused_district_choices()
	for choice_index: int in range(DISTRICT_CARD_HAND_CAPACITY):
		var button: DistrictCardDragSlot = _district_card_choice_buttons[choice_index]
		var icon_rect: TextureRect = _district_card_choice_icons[choice_index]
		var details: Label = _district_card_choice_details[choice_index]
		var has_card: bool = choice_index < _district_card_choices.size()
		var card: DistrictCardDefinition = (
			_district_card_choices[choice_index] if has_card else null
		)
		button.visible = has_card if _focused_district_plan else true
		button.disabled = not has_card or _district_card_action_in_flight
		button.text = ""
		icon_rect.texture = card.icon if card != null else null
		details.text = _district_card_overview(card) if card != null else (
			"NO THIRD CHOICE" if _focused_district_plan else "EMPTY HAND SLOT"
		)
		button.tooltip_text = _district_card_tooltip(card) if card != null else (
			"A third choice appears only when an explicit effect grants it."
			if _focused_district_plan
			else "No card in this slot."
		)
		var selected: bool = card != null and card.id == _district_selected_card_id
		button.self_modulate = Color.WHITE
		button.set_visual_state(
			NeonChoiceCard.VisualState.SELECTED if selected else (
				NeonChoiceCard.VisualState.DISABLED if not has_card else NeonChoiceCard.VisualState.DEFAULT
			),
			"SELECTED" if selected else ""
		)
		var origin: DistrictCardDragPayload.Origin = (
			DistrictCardDragPayload.Origin.REWARD
			if _district_card_panel_mode == DistrictCardPanelMode.REWARD
			else DistrictCardDragPayload.Origin.HAND
		)
		var payload: DistrictCardDragPayload
		if card != null:
			payload = DistrictCardDragPayload.new(
				origin,
				choice_index,
				card.id,
				card.display_name,
				_district_card_hand_revision,
				_district_card_route_revision,
				_district_card_reward_encounter_id,
				_district_card_reward_choice_token,
				card.heat_delta,
				_district_card_effect_summary(card),
				card.icon
			)
		button.configure_drag_source(
			payload,
			card != null
			and not _focused_district_plan
			and _district_card_panel_mode == DistrictCardPanelMode.PLANNING
			and _district_card_planning_allowed
			and not _district_card_action_in_flight
		)


func _refresh_district_route_slot_presentation() -> void:
	var card: DistrictCardDefinition = _selected_district_card()
	for slot_index: int in range(DISTRICT_ROUTE_SLOT_COUNT):
		var button: DistrictCardDragSlot = _district_route_slot_buttons[slot_index]
		var has_slot: bool = slot_index < _district_route_slots.size()
		var slot: Dictionary = _district_route_slots[slot_index] if has_slot else {}
		var is_valid_target: bool = (
			has_slot and card != null and _district_route_slot_is_valid(slot, card)
		)
		button.disabled = (
			not has_slot
			or _district_card_action_in_flight
			or _district_card_stage_in_flight
		)
		button.text = (
			_district_route_slot_text(slot, card)
			if has_slot
			else "NO FUTURE SLOT\nEXPIRED / UNAVAILABLE"
		)
		button.tooltip_text = (
			_district_route_slot_tooltip(slot, card)
			if has_slot
			else "No fixed future route occurrence is available."
		)
		button.configure_route_drop_target(
			StringName(slot.get("slot_id", &"")),
			_district_card_hand_revision,
			_district_card_route_revision,
			is_valid_target,
			has_slot and not _district_card_action_in_flight
		)
		button.self_modulate = (
			Color(1.0, 0.92, 0.62, 1.0)
			if StringName(slot.get("slot_id", &"")) == _district_selected_slot_id
			else Color.WHITE
		)


func _district_card_count(count_key: String, ids_key: String) -> int:
	if _district_card_snapshot.has(count_key):
		return maxi(0, int(_district_card_snapshot.get(count_key, 0)))
	var ids: Variant = _district_card_snapshot.get(ids_key, [])
	return (ids as Array).size() if ids is Array else 0


func _district_card_counts_text() -> String:
	if _focused_district_plan:
		return "OFFER %d / %d • LAP DECK %d • CHOSEN %d" % [
			int(_district_card_snapshot.get("offer_count", _district_card_choices.size())),
			int(
				_district_card_snapshot.get(
					"offer_capacity",
					CardSystem.DISTRICT_PLAN_OFFER_COUNT
				)
			),
			int(_district_card_snapshot.get("lap_deck_remaining", 0)),
			int(_district_card_snapshot.get("lap_selected_count", 0)),
		]
	var hand_count: int = int(
		_district_card_snapshot.get("hand_count", _district_card_hand.size())
	)
	var capacity: int = int(
		_district_card_snapshot.get("hand_capacity", DISTRICT_CARD_HAND_CAPACITY)
	)
	return "HAND %d/%d | DRAW %d | DISC %d" % [
		hand_count,
		capacity,
		_district_card_count("draw_count", "draw_ids"),
		_district_card_count("discard_count", "discard_ids"),
	]


func _selected_district_card() -> DistrictCardDefinition:
	if (
		_district_selected_card_index < 0
		or _district_selected_card_index >= _district_card_choices.size()
	):
		return null
	var card: DistrictCardDefinition = _district_card_choices[_district_selected_card_index]
	return card if card != null and card.id == _district_selected_card_id else null


func _district_route_slot_index(slot_id: StringName) -> int:
	for slot_index: int in range(_district_route_slots.size()):
		if StringName(_district_route_slots[slot_index].get("slot_id", &"")) == slot_id:
			return slot_index
	return -1


func _district_route_slot_status(
	slot: Dictionary,
	card: DistrictCardDefinition
) -> StringName:
	var status: StringName = StringName(slot.get("status", &"invalid"))
	if int(slot.get("route_revision", -1)) != _district_card_route_revision:
		return &"stale"
	if status != &"valid":
		return status
	if card != null and not card.supports_node_type(StringName(slot.get("node_type", &""))):
		return &"wrong_node_type"
	return &"valid"


func _district_route_slot_is_valid(
	slot: Dictionary,
	card: DistrictCardDefinition
) -> bool:
	return (
		_district_card_panel_mode == DistrictCardPanelMode.PLANNING
		and _district_card_planning_allowed
		and card != null
		and StringName(slot.get("slot_id", &"")) != &""
		and _district_route_slot_status(slot, card) == &"valid"
	)


func _district_route_slot_status_label(status: StringName, has_card: bool) -> String:
	match status:
		&"valid":
			return "VALID" if has_card else "AVAILABLE"
		&"occupied":
			return "OCCUPIED"
		&"current":
			return "CURRENT - CLOSED"
		&"past", &"expired":
			return "EXPIRED"
		&"stale":
			return "STALE"
		&"wrong_node_type", &"wrong_node":
			return "WRONG TYPE"
	return "INVALID"


func _district_route_slot_text(
	slot: Dictionary,
	card: DistrictCardDefinition
) -> String:
	var status: StringName = _district_route_slot_status(slot, card)
	var occupied_id: String = str(slot.get("occupied_card_id", &""))
	var occupancy: String = ""
	if not occupied_id.is_empty():
		occupancy = "\n%s" % occupied_id.replace("_", " ").to_upper()
	return "OCC %d | LOOP %d\nNODE %d %s\n%s%s" % [
		int(slot.get("occurrence_index", -1)) + 1,
		int(slot.get("loop_count", 0)),
		int(slot.get("route_index", -1)) + 1,
		str(slot.get("node_type", &"unknown")).to_upper(),
		_district_route_slot_status_label(status, card != null),
		occupancy,
	]


func _district_route_slot_tooltip(
	slot: Dictionary,
	card: DistrictCardDefinition
) -> String:
	return (
		"Stable route slot: %s\nOccurrence: %s\nBaseline node: %s (%s)\nStatus: %s"
		% [
			str(slot.get("slot_id", &"")),
			str(slot.get("occurrence_id", &"")),
			str(slot.get("node_id", &"")),
			str(slot.get("node_type", &"")),
			_district_route_slot_status_label(
				_district_route_slot_status(slot, card),
				card != null
			),
		]
	)


func _focus_first_valid_district_route_slot() -> void:
	var card: DistrictCardDefinition = _selected_district_card()
	if card == null:
		return
	for slot_index: int in range(_district_route_slots.size()):
		if _district_route_slot_is_valid(_district_route_slots[slot_index], card):
			_district_route_slot_buttons[slot_index].grab_focus()
			return


func _district_card_overview(card: DistrictCardDefinition) -> String:
	if card == null:
		return "EMPTY HAND SLOT"
	if _focused_district_plan:
		var focused_lines: PackedStringArray = PackedStringArray()
		focused_lines.append_array(_limited_card_lines(card.display_name.to_upper(), 28, 2))
		focused_lines.append("LOCATION • %s" % card.display_name.to_upper())
		focused_lines.append("BLOCK • %s" % CardSystem.focused_block_type(card))
		focused_lines.append("HEAT • %s" % _signed_integer(card.heat_delta))
		focused_lines.append_array(_limited_card_lines(
			"SPECIAL • %s" % CardSystem.focused_special_rule(card),
			28,
			3
		))
		focused_lines.append_array(_limited_card_lines(
			"REWARD / RISK • %s" % card.progression_implications.to_upper(),
			28,
			3
		))
		return "\n".join(focused_lines)
	var lines: PackedStringArray = PackedStringArray()
	lines.append_array(_limited_card_lines(card.display_name.to_upper(), 22, 2))
	lines.append("%s | %s HEAT" % [card.cost_label(), _signed_integer(card.heat_delta)])
	lines.append_array(_limited_card_lines(_district_card_compact_effect(card), 22, 3))
	lines.append("TAGS %s" % _district_card_tag_text(card))
	lines.append_array(_limited_card_lines(
		"IMPLICATION: %s" % card.progression_implications.to_upper(),
		22,
		3
	))
	return "\n".join(lines)


func _district_card_tooltip(card: DistrictCardDefinition) -> String:
	if card == null:
		return "No card in this slot."
	if _focused_district_plan:
		return "%s\nNext block: %s\nHeat %s\n%s\n%s" % [
			card.display_name,
			CardSystem.focused_block_type(card),
			_signed_integer(card.heat_delta),
			CardSystem.focused_special_rule(card),
			card.progression_implications,
		]
	return "%s\n%s | %s Heat\n%s\nTags: %s\n%s" % [
		card.display_name,
		card.cost_label(),
		_signed_integer(card.heat_delta),
		_district_card_effect_summary(card),
		_district_card_tag_text(card),
		card.progression_implications,
	]


func _district_card_effect_summary(card: DistrictCardDefinition) -> String:
	if card == null or card.effect_definition == null:
		return "No authored route effect"
	return card.effect_definition.summary.strip_edges()


func _district_card_compact_effect(card: DistrictCardDefinition) -> String:
	if card == null or card.effect_definition == null:
		return "NO AUTHORED ROUTE EFFECT"
	match card.effect_definition.kind:
		CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER:
			return "ADD FIGHT; STANDARD REWARD QUALITY +1 AUTHORED TIER (CLAMPED)"
		CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP:
			return "ADD SHOP; ONE PURCHASE FROM EXISTING FINITE COOLING STOCK"
		CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER:
			return "ADD SCALED ELITE PLACEHOLDER; GUARANTEE EQUIPMENT CHOICE"
		CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD:
			return "REROUTE; SKIP EXACTLY ONE UPCOMING STANDARD ENCOUNTER"
	return _district_card_effect_summary(card).to_upper()


func _district_card_tag_text(card: DistrictCardDefinition) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if card != null:
		for tag: StringName in card.sorted_tags():
			parts.append(String(tag))
	return " | ".join(parts) if not parts.is_empty() else "NONE"


func _signed_integer(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


func _limited_card_lines(
	value: String,
	maximum_characters: int,
	maximum_lines: int
) -> PackedStringArray:
	var wrapped: PackedStringArray = _wrap_compact(value.strip_edges(), maximum_characters)
	if wrapped.size() <= maximum_lines:
		return wrapped
	var result: PackedStringArray = PackedStringArray()
	for line_index: int in range(maximum_lines):
		result.append(wrapped[line_index])
	var final_line: String = result[maximum_lines - 1]
	if final_line.length() >= maximum_characters:
		final_line = final_line.substr(0, maxi(1, maximum_characters - 3))
	result[maximum_lines - 1] = "%s..." % final_line
	return result


func _district_route_preview_text() -> String:
	if _focused_district_plan:
		return _focused_district_plan_preview_text()
	var pending: Variant = _district_card_snapshot.get("pending_route_effects", [])
	var resolved: Variant = _district_card_snapshot.get("resolved_route_effects", [])
	var pending_text: String = _district_record_list_marker(pending)
	var resolved_text: String = _district_record_list_marker(resolved)
	return "ROUTE PREVIEW | %s | PENDING %s | RESOLVED %s" % [
		_district_route_history_text(),
		pending_text,
		resolved_text,
	]


func _focused_district_plan_preview_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	var pending: Dictionary = _district_card_snapshot.get("selected_next_block", {})
	var active: Dictionary = _district_card_snapshot.get("active_block", {})
	if not pending.is_empty():
		lines.append("NEXT BLOCK • %s • %s • HEAT %s" % [
			str(pending.get("card_name", "DISTRICT BLOCK")).to_upper(),
			str(pending.get("block_type", "DISTRICT BLOCK")),
			_signed_integer(int(pending.get("heat_delta", 0))),
		])
	elif not active.is_empty():
		lines.append("HAPPENING NOW • %s • %s" % [
			str(active.get("card_name", "DISTRICT BLOCK")).to_upper(),
			str(active.get("special_rule", "AUTHORED EFFECT")),
		])
	else:
		lines.append("NEXT BLOCK • CONFIRM ONE OF THE OFFERED LOCATIONS")
	var history_value: Variant = _district_card_snapshot.get("current_lap_history", [])
	var history_parts: PackedStringArray = PackedStringArray()
	if history_value is Array:
		for entry_value: Variant in history_value as Array:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value as Dictionary
			history_parts.append("B%d %s %s" % [
				int(entry.get("block_index", 0)),
				str(entry.get("card_name", "BLOCK")).to_upper(),
				str(entry.get("status", &"selected")).to_upper(),
			])
	lines.append(
		"THIS LAP • %s"
		% (" > ".join(history_parts) if not history_parts.is_empty() else "NO RESOLVED BLOCKS YET")
	)
	var archived_value: Variant = _district_card_snapshot.get("archived_lap_history", [])
	if archived_value is Array and not (archived_value as Array).is_empty():
		var archived: Dictionary = (archived_value as Array)[-1] as Dictionary
		var archived_history: Variant = archived.get("history", [])
		var archived_names: PackedStringArray = PackedStringArray()
		if archived_history is Array:
			for entry_value: Variant in archived_history as Array:
				if entry_value is Dictionary:
					archived_names.append(str(
						(entry_value as Dictionary).get("card_name", "BLOCK")
					).to_upper())
		lines.append("ARCHIVED LAP %d • %s" % [
			int(archived.get("lap_index", 0)),
			" > ".join(archived_names),
		])
	return "\n".join(lines)


func _district_route_history_text() -> String:
	var value: Variant = _district_patrol_snapshot.get("route_slot_history", [])
	if not (value is Array):
		return "CURRENT - | CLOSED -"
	var current_text: String = "-"
	var closed_text: String = "-"
	for entry: Variant in value as Array:
		if not (entry is Dictionary):
			continue
		var slot: Dictionary = entry as Dictionary
		var occurrence_label: String = "OCC %d" % (
			int(slot.get("occurrence_index", -1)) + 1
		)
		var status: StringName = StringName(slot.get("status", &"invalid"))
		if status == &"current" and current_text == "-":
			current_text = occurrence_label
		elif status == &"expired":
			closed_text = "EXPIRED %s" % occurrence_label
			break
		elif status == &"past" and closed_text == "-":
			closed_text = "PAST %s" % occurrence_label
	return "CURRENT %s | CLOSED %s" % [current_text, closed_text]


func _refresh_route_label_with_card_markers() -> void:
	if not is_node_ready():
		return
	if _focused_district_plan:
		var pending: Dictionary = _district_card_snapshot.get("selected_next_block", {})
		var active: Dictionary = _district_card_snapshot.get("active_block", {})
		var state_text: String = "PLAN REQUIRED"
		if not pending.is_empty():
			state_text = "NEXT %s • %s" % [
				str(pending.get("card_name", "BLOCK")).to_upper(),
				str(pending.get("block_type", "DISTRICT BLOCK")),
			]
		elif not active.is_empty():
			state_text = "NOW %s • %s" % [
				str(active.get("card_name", "BLOCK")).to_upper(),
				str(active.get("block_type", "DISTRICT BLOCK")),
			]
		route_label.text = "%s\n%s" % [_route_journey_text, state_text]
		return
	var pending: Variant = _district_card_snapshot.get("pending_route_effects", [])
	var resolved: Variant = _district_card_snapshot.get("resolved_route_effects", [])
	route_label.text = "%s\nCARDS P:%s R:%s" % [
		_route_journey_text,
		_district_record_list_marker(pending, true),
		_district_record_list_marker(resolved, true),
	]


func _district_record_list_marker(value: Variant, compact: bool = false) -> String:
	if not (value is Array) or (value as Array).is_empty():
		return "-"
	var records: Array = value as Array
	var first: Dictionary = records[0] as Dictionary
	var card_id: String = str(first.get("card_id", &"card"))
	var short_id: String = card_id.to_upper().replace("_", "")
	short_id = short_id.substr(0, mini(4, short_id.length()))
	var occurrence: int = int(first.get("occurrence_index", -1)) + 1
	var marker: String = "%s@%d" % [short_id, occurrence]
	if records.size() > 1:
		marker += "+%d" % (records.size() - 1)
	if compact:
		return marker
	var card_name: String = str(first.get("card_name", card_id.replace("_", " ")))
	return "%s@O%d%s" % [
		card_name.to_upper(),
		occurrence,
		" +%d" % (records.size() - 1) if records.size() > 1 else "",
	]


func _humanize_card_result(reason: String) -> String:
	var normalized: String = reason.strip_edges()
	if normalized.is_empty():
		return "REQUEST REJECTED"
	return normalized.replace("_", " ").to_upper()


func _shop_rejection_label(reason: StringName, coins: int, cost: int) -> String:
	match reason:
		&"sold_out":
			return "SOLD OUT  /  NO MORE THIS RUN"
		&"visit_limit_reached":
			return "PURCHASE USED  /  LEAVE SHOP"
		&"heat_already_zero":
			return "HEAT ALREADY 0  /  NO BENEFIT"
		&"insufficient_coins":
			return "NEED %d MORE COINS" % maxi(cost - coins, 0)
		&"stale_visit", &"wrong_shop_source", &"wrong_source", &"malformed_request", &"malformed_context":
			return "SHOP CHANGED  /  REVIEW AGAIN"
		_:
			return "UNAVAILABLE  /  %s" % String(reason).replace("_", " ").to_upper()


func _refresh_run_actions(
	state: int,
	encounter_name: String,
	cooling: Dictionary,
	rewards: Dictionary
) -> void:
	var combat_hud: bool = state in [
		RunDirector.RunState.ENCOUNTER_ACTIVE,
		RunDirector.RunState.BOSS_INTRO,
		RunDirector.RunState.BOSS_ACTIVE,
	]
	run_actions_title.text = (
		"INTERVENE  /  COMBAT CONTINUES"
		if combat_hud
		else "RUN ACTIONS  /  %s" % RunDirector.state_name(state).replace("_", " ")
	)
	cards_panel.size.x = 560.0 if combat_hud else 980.0
	var primary_disabled: bool = true
	var primary_text: String = "PATROLLING\nAUTOMATIC"
	match state:
		RunDirector.RunState.INTRO:
			primary_text = "RUN STARTING\nSTAND BY"
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			primary_text = "%s\nIN PROGRESS" % encounter_name.to_upper()
		RunDirector.RunState.REWARD_SELECTION:
			primary_text = "CHOOSE EQUIPMENT\nIN REWARD PANEL"
		RunDirector.RunState.SHOP:
			primary_disabled = false
			primary_text = "LEAVE\nSHOP"
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			primary_disabled = false
			primary_text = "CONTINUE\nRUN (+6 HEAT)"
		RunDirector.RunState.BOSS_INTRO:
			primary_text = "THE VIPER\nAPPROACHING"
		RunDirector.RunState.BOSS_ACTIVE:
			primary_text = "THE VIPER\nDEFEAT THE BOSS"
		RunDirector.RunState.PAUSED:
			primary_text = (
				"CARD PLANNING\nCLOSE TO RESUME"
				if bool(_district_card_snapshot.get("planning_active", false))
				else "PAUSED\nSPACE TO RESUME"
			)
		RunDirector.RunState.RUN_SUMMARY:
			primary_text = "RUN\nCOMPLETE"
	_present_action_button(primary_action_button, primary_text, primary_disabled)
	primary_action_button.visible = not combat_hud
	backup_button.visible = combat_hud
	focus_placeholder_button.visible = combat_hud
	interventions_panel.visible = combat_hud
	if combat_hud:
		_set_rect(backup_button, Rect2(14.0, 30.0, 260.0, 68.0))
		_set_rect(focus_placeholder_button, Rect2(286.0, 30.0, 260.0, 68.0))
	else:
		_set_rect(subway_reroute_button, Rect2(196.0, 30.0, 220.0, 68.0))

	var subway_charges: int = int(cooling.get("subway_charges", 0))
	var subway_disabled: bool = (
		state != RunDirector.RunState.PATROLLING or subway_charges <= 0
	)
	var subway_text: String = "SUBWAY\n%dX / -%dH" % [
		subway_charges,
		int(cooling.get("subway_heat_reduction", 0)),
	]
	_present_action_button(subway_reroute_button, subway_text, subway_disabled)
	subway_reroute_button.visible = not combat_hud

	var shop_remaining: int = int(cooling.get("shop_purchases_remaining", 0))
	var shop_cost: int = int(cooling.get("shop_coin_cost", 0))
	var shop_disabled: bool = (
		state != RunDirector.RunState.SHOP
		or shop_remaining <= 0
		or int(rewards.get("coin_total", 0)) < shop_cost
	)
	var shop_text: String = "SHOP COOLING\n%d LEFT  •  %d COINS" % [
		shop_remaining,
		shop_cost,
	]
	_present_action_button(shop_cooling_button, shop_text, shop_disabled)
	# The focused shop shell owns the pointer/touch choice. The preserved Card03
	# node remains for compatibility but no duplicate action is presented below it.
	shop_cooling_button.visible = false

	var extraction_disabled: bool = state != RunDirector.RunState.EXTRACTION_AVAILABLE
	var extraction_text: String = (
		"EXTRACT NOW\nSECURE RUN"
		if state == RunDirector.RunState.EXTRACTION_AVAILABLE
		else "EXTRACTION\nUNAVAILABLE"
	)
	_present_action_button(extraction_button, extraction_text, extraction_disabled)
	district_card_compact_panel.visible = not combat_hud
	_refresh_safe_area_layout()


func _present_action_button(button: Button, text: String, disabled: bool) -> void:
	## Reassigning `disabled` every frame cancels an in-progress mouse press in
	## Godot. Only mutate actual presentation changes so one press/release is
	## always sufficient for reward and route actions.
	if button.text != text:
		button.text = text
	if button.disabled != disabled:
		button.disabled = disabled


func _journey_stage_for_state(state: int) -> String:
	match state:
		RunDirector.RunState.INITIALIZING, RunDirector.RunState.INTRO:
			return "HIDEOUT"
		RunDirector.RunState.PATROLLING:
			return "PATROL"
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			return "FIGHT"
		RunDirector.RunState.REWARD_SELECTION:
			return "GEAR"
		RunDirector.RunState.SHOP:
			return "SHOP"
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			return "EXTRACTION DECISION"
		RunDirector.RunState.BOSS_INTRO, RunDirector.RunState.BOSS_ACTIVE:
			return "BOSS THRESHOLD"
		RunDirector.RunState.PAUSED:
			return "PAUSED"
		RunDirector.RunState.RUN_SUMMARY:
			return "RUN COMPLETE"
	return "DOWNTOWN"


func _journey_next_objective(state: int) -> String:
	match state:
		RunDirector.RunState.INITIALIZING, RunDirector.RunState.INTRO:
			return "PATROL"
		RunDirector.RunState.PATROLLING:
			return "FIGHT / SHOP"
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			return "DEFEAT"
		RunDirector.RunState.REWARD_SELECTION:
			return "CHOOSE GEAR"
		RunDirector.RunState.SHOP:
			return "COOL / LEAVE"
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			return "EXIT / CONTINUE"
		RunDirector.RunState.BOSS_INTRO:
			return "ENTER BOSS"
		RunDirector.RunState.BOSS_ACTIVE:
			return "BOSS"
		RunDirector.RunState.PAUSED:
			return "RESUME"
		RunDirector.RunState.RUN_SUMMARY:
			return "RESTART"
	return "GET READY"


func _heat_implication(tier: int) -> String:
	match tier:
		0:
			return "LOW ALERT"
		1:
			return "MORE ENEMIES"
		2:
			return "AGGRESSIVE"
		3:
			return "ELITE ELIGIBLE"
		4:
			return "MAX STANDARD"
		5:
			return "FULL ALERT"
	return "UNKNOWN"


func _format_time(elapsed_seconds: float) -> String:
	var safe_seconds: int = maxi(0, int(floor(elapsed_seconds)))
	return "%02d:%02d" % [floori(float(safe_seconds) / 60.0), safe_seconds % 60]


func _compact_state_name(state_name: StringName) -> String:
	match state_name:
		&"ACQUIRING_TARGET":
			return "SEEKING"
		&"APPROACHING_TARGET":
			return "APPROACH"
		&"ATTACK_WINDUP":
			return "WINDUP"
		&"ATTACK_ACTIVE":
			return "STRIKING"
		&"ATTACK_RECOVERY":
			return "RECOVERY"
		&"KNOCKED_BACK":
			return "KNOCKBACK"
		&"INCAPACITATED":
			return "DOWN"
		_:
			return String(state_name).replace("_", " ")


func _refresh_build_presentation() -> void:
	var slots: Array = _build_snapshot.get("slots", [])
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		var button: LinkButton = _build_slot_buttons[slot_index]
		var slot: Dictionary = slots[slot_index] if slot_index < slots.size() else {}
		var equipment_id: StringName = StringName(slot.get("id", &""))
		var display_name: String = str(slot.get("display_name", "EMPTY")).to_upper()
		button.disabled = equipment_id == &""
		button.text = (
			"%d  %s" % [slot_index + 1, display_name.left(3)]
			if equipment_id != &""
			else "%d  —" % (slot_index + 1)
		)
		button.tooltip_text = _equipment_slot_tooltip(slot)
	var stored_count: int = 0
	for value: Variant in _build_snapshot.get("backpack_slots", []):
		var stored_slot: Dictionary = value as Dictionary
		if StringName(stored_slot.get("id", &"")) != &"":
			stored_count += 1
	build_title_button.text = "BUILD • BACKPACK %d/%d" % [
		stored_count,
		SynergySystem.BACKPACK_SLOT_COUNT,
	]
	backpack_title_label.text = "BACKPACK • %d/%d STORED • INACTIVE" % [
		stored_count,
		SynergySystem.BACKPACK_SLOT_COUNT,
	]
	_refresh_build_details(slots)


func _refresh_build_details(slots: Array) -> void:
	var backpack_slots: Array = _build_snapshot.get("backpack_slots", [])
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		_present_inventory_slot_button(
			_equipped_inventory_buttons[slot_index],
			SynergySystem.AREA_EQUIPPED,
			slot_index,
			slots[slot_index] if slot_index < slots.size() else {}
		)
		_present_inventory_slot_button(
			_backpack_inventory_buttons[slot_index],
			SynergySystem.AREA_BACKPACK,
			slot_index,
			backpack_slots[slot_index] if slot_index < backpack_slots.size() else {}
		)

	var selected_slot: Dictionary = _inventory_slot(
		_selected_inventory_area,
		_selected_inventory_slot
	)
	if _selected_inventory_id == &"" or selected_slot.is_empty():
			equipment_details_label.text = (
			"SELECT AN ITEM TO INSPECT.\n\n"
			+ "ITEM CLICKS NEVER DROP EQUIPMENT.\n"
			+ "ONLY EQUIPPED ITEMS POWER %s. STORED ITEMS ARE INACTIVE.\n\n" % _crew_display_name
			+ "DRAG BETWEEN COLUMNS OR USE CLICK/TAP. CONFIRM APPLIES."
		)
	else:
		var detail_lines: PackedStringArray = PackedStringArray()
		detail_lines.append(str(selected_slot.get("display_name", "")).to_upper())
		detail_lines.append(
			"%s SLOT %d" % [
				"ACTIVE" if _selected_inventory_area == SynergySystem.AREA_EQUIPPED else "BACKPACK",
				_selected_inventory_slot + 1,
			]
		)
		detail_lines.append("TAGS: %s" % _join_string_names(selected_slot.get("tags", [])))
		detail_lines.append("")
		for effect_text: Variant in selected_slot.get("major_effects", PackedStringArray()):
			detail_lines.append("- %s" % str(effect_text))
		detail_lines.append("")
		detail_lines.append(
			"POWERING CURRENT BUILD"
			if _selected_inventory_area == SynergySystem.AREA_EQUIPPED
			else "STORED SAFELY - NO ACTIVE MODIFIERS OR TAGS"
		)
		equipment_details_label.text = "\n".join(detail_lines)

	var synergy_lines: PackedStringArray = PackedStringArray()
	synergy_lines.append("CURRENT TAG COUNTS")
	var tag_counts: Dictionary = _build_snapshot.get("tag_counts", {})
	var tags: Array[StringName] = []
	for tag_value: Variant in tag_counts.keys():
		tags.append(StringName(tag_value))
	tags.sort_custom(_string_name_before)
	var tag_parts: PackedStringArray = PackedStringArray()
	for tag: StringName in tags:
		tag_parts.append("%s %d" % [tag, int(tag_counts.get(tag, 0))])
	synergy_lines.append("  %s" % (" • ".join(tag_parts) if not tag_parts.is_empty() else "NONE"))
	synergy_lines.append("")
	for badge: TextureRect in _synergy_badges:
		badge.texture = null
		badge.visible = false
	var progress_index: int = 0
	for progress_value: Variant in _build_snapshot.get("synergy_progress", []):
		var progress: Dictionary = progress_value as Dictionary
		var active: bool = bool(progress.get("active", false))
		if progress_index < _synergy_badges.size():
			var badge: TextureRect = _synergy_badges[progress_index]
			badge.texture = progress.get("badge") as Texture2D
			badge.visible = badge.texture != null
			badge.modulate = Color.WHITE if active else Color(0.45, 0.48, 0.62, 0.72)
		progress_index += 1
		synergy_lines.append("%s %d/%d — %s" % [
			str(progress.get("tag", &"")).to_upper(),
			int(progress.get("count", 0)),
			int(progress.get("threshold", 0)),
			"ACTIVE" if active else "INACTIVE",
		])
		for effect_text: Variant in progress.get("major_effects", PackedStringArray()):
			synergy_lines.append("  %s %s" % ["✓" if active else "•", str(effect_text)])
		synergy_lines.append("")
	synergy_details_label.text = "\n".join(synergy_lines)
	_refresh_inventory_action_presentation()


func _refresh_equipment_reward_presentation() -> void:
	var slots: Array = _build_snapshot.get("slots", [])
	var backpack_slots: Array = _build_snapshot.get("backpack_slots", [])
	var has_rewards: bool = not _reward_choices.is_empty()
	var has_choice: bool = (
		_selected_reward_choice >= 0
		and _selected_reward_choice < _reward_choices.size()
	)
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		var slot: Dictionary = slots[slot_index] if slot_index < slots.size() else {}
		var equip_selected: bool = (
			_selected_reward_destination == SynergySystem.AREA_EQUIPPED
			and slot_index == _selected_reward_slot
		)
		_reward_target_buttons[slot_index].text = "%s ACTIVE %d • %s" % [
			">" if equip_selected else " ",
			slot_index + 1,
			str(slot.get("display_name", "EMPTY")).to_upper(),
		]
		_reward_target_buttons[slot_index].visible = has_choice or _reward_drag_active
		_reward_target_buttons[slot_index].disabled = (
			not has_rewards or _equipment_choice_in_flight
		)
		_reward_target_buttons[slot_index].configure_drop_target(
			EquipmentDragPayload.Origin.REWARD,
			SynergySystem.AREA_EQUIPPED,
			slot_index,
			has_rewards and not _equipment_choice_in_flight
		)
		var backpack_slot: Dictionary = (
			backpack_slots[slot_index] if slot_index < backpack_slots.size() else {}
		)
		var store_selected: bool = (
			_selected_reward_destination == SynergySystem.AREA_BACKPACK
			and slot_index == _selected_reward_backpack_slot
		)
		_reward_store_buttons[slot_index].text = "%s BACKPACK [%d] • %s" % [
			">" if store_selected else " ",
			slot_index + 1,
			str(backpack_slot.get("display_name", "EMPTY")).to_upper(),
		]
		_reward_store_buttons[slot_index].visible = has_choice or _reward_drag_active
		_reward_store_buttons[slot_index].disabled = (
			not has_rewards or _equipment_choice_in_flight
		)
		_reward_store_buttons[slot_index].configure_drop_target(
			EquipmentDragPayload.Origin.REWARD,
			SynergySystem.AREA_BACKPACK,
			slot_index,
			has_rewards and not _equipment_choice_in_flight
		)
	for choice_index: int in range(_reward_choice_buttons.size()):
		var button: EquipmentDragSlot = _reward_choice_buttons[choice_index]
		if choice_index >= _reward_choices.size():
			button.visible = false
			button.configure_drag_source(null, false)
			continue
		button.visible = true
		button.disabled = _equipment_choice_in_flight
		var item: EquipmentDefinition = _reward_choices[choice_index]
		var preview: Dictionary = {}
		var choice_text: String = ""
		if (
			choice_index == _selected_reward_choice
			and _selected_reward_destination == SynergySystem.AREA_EQUIPPED
		):
			preview = _preview_for_choice(
				choice_index,
				_selected_reward_slot,
				_selected_reward_outgoing_backpack_slot
			)
			choice_text = _format_equipment_choice(item, preview)
		elif (
			choice_index == _selected_reward_choice
			and _selected_reward_destination == SynergySystem.AREA_BACKPACK
		):
			preview = _storage_preview_for_choice(
				choice_index,
				_selected_reward_backpack_slot
			)
			choice_text = _format_equipment_choice(item, preview)
			if not choice_text.contains("STORE: INACTIVE UNTIL EQUIPPED"):
				choice_text += "\nSTORE: INACTIVE UNTIL EQUIPPED"
		elif choice_index == _selected_reward_choice:
			choice_text = _format_equipment_choice_overview(
				item,
				choice_index,
				_selected_reward_destination == SynergySystem.AREA_BACKPACK
			)
		else:
			choice_text = _format_equipment_choice(item, {"valid": true})
		button.text = ""
		_reward_choice_details[choice_index].text = "%s%s" % [
			"> SELECTED\n" if choice_index == _selected_reward_choice else "",
			choice_text,
		]
		button.icon = null
		_reward_choice_icons[choice_index].texture = item.icon
		button.set_visual_state(
			NeonChoiceCard.VisualState.SELECTED
			if choice_index == _selected_reward_choice
			else NeonChoiceCard.VisualState.DEFAULT,
			"SELECTED" if choice_index == _selected_reward_choice else ""
		)
		# The card already contains the authored item details. A second hover
		# layer obscures the modal instead of adding useful information.
		button.tooltip_text = ""
		button.configure_drag_source(
			EquipmentDragPayload.new(
				EquipmentDragPayload.Origin.REWARD,
				&"",
				-1,
				choice_index,
				item.id,
				item.display_name,
				int(_build_snapshot.get("inventory_revision", -1)),
				_reward_encounter_id,
				item.icon,
				_reward_choice_token
			),
			not _equipment_choice_in_flight
		)

	var full_backpack_choice_required: bool = _reward_needs_full_backpack_choice()
	var reserved_empty_backpack: bool = (
		_selected_reward_destination == SynergySystem.AREA_EQUIPPED
		and _selected_reward_slot >= 0
		and StringName(
			_inventory_slot(
				SynergySystem.AREA_EQUIPPED,
				_selected_reward_slot
			).get("id", &"")
		) != &""
		and _selected_reward_outgoing_backpack_slot >= 0
		and not full_backpack_choice_required
	)
	reward_pack_target_label.visible = (
		full_backpack_choice_required or reserved_empty_backpack
	)
	if full_backpack_choice_required:
		reward_pack_target_label.text = (
			"BACKPACK FULL • CHOOSE A STORED ITEM TO DISCARD, OR SKIP GEAR"
		)
	elif reserved_empty_backpack:
		var outgoing: Dictionary = _inventory_slot(
			SynergySystem.AREA_EQUIPPED,
			_selected_reward_slot
		)
		reward_pack_target_label.text = "%s TO BACKPACK SLOT %d • NO ITEM LOST" % [
			str(outgoing.get("display_name", "ITEM")).to_upper(),
			_selected_reward_outgoing_backpack_slot + 1,
		]
	for slot_index: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
		var button: Button = _reward_pack_target_buttons[slot_index]
		button.visible = full_backpack_choice_required
		button.disabled = _equipment_choice_in_flight
		if not full_backpack_choice_required:
			continue
		var slot: Dictionary = (
			backpack_slots[slot_index] if slot_index < backpack_slots.size() else {}
		)
		button.text = "%s DISCARD SLOT %d • %s" % [
			">" if slot_index == _selected_reward_outgoing_backpack_slot else " ",
			slot_index + 1,
			str(slot.get("display_name", "EMPTY")).to_upper(),
		]

	if not has_choice:
		reward_instruction_label.text = "1. CHOOSE OR DRAG ONE ITEM • OR SKIP"
	elif _selected_reward_destination == &"":
		reward_instruction_label.text = "2. CHOOSE ACTIVE OR BACKPACK SLOT"
	else:
		reward_instruction_label.text = "3. REVIEW THE RESULT • CONFIRM"
	reward_confirmation_label.text = _reward_confirmation_text()
	_set_rect(
		reward_confirmation_label,
		Rect2(
			20.0,
			544.0 if full_backpack_choice_required else 506.0,
			740.0,
			62.0 if full_backpack_choice_required else 100.0
		)
	)
	var inventory_full: bool = int(_build_snapshot.get("owned_count", 0)) >= (
		SynergySystem.SLOT_COUNT + SynergySystem.BACKPACK_SLOT_COUNT
	)
	reward_confirmation_label.visible = has_choice or inventory_full
	reward_confirm_button.visible = has_choice
	reward_cancel_button.visible = has_choice
	reward_confirm_button.disabled = (
		_equipment_choice_in_flight or not _reward_selection_is_complete()
	)
	reward_cancel_button.disabled = _equipment_choice_in_flight or not has_choice
	reward_keep_current_button.disabled = _equipment_choice_in_flight


func _present_inventory_slot_button(
	button: EquipmentDragSlot,
	area: StringName,
	slot_index: int,
	slot: Dictionary
) -> void:
	var equipment_id: StringName = StringName(slot.get("id", &""))
	var selected: bool = (
		area == _selected_inventory_area
		and slot_index == _selected_inventory_slot
		and equipment_id == _selected_inventory_id
	)
	button.text = "%s %s %d - %s" % [
		">" if selected else " ",
		"EQUIPPED" if area == SynergySystem.AREA_EQUIPPED else "SLOT",
		slot_index + 1,
		str(slot.get("display_name", "EMPTY")).to_upper(),
	]
	button.icon = slot.get("icon") as Texture2D
	# Empty cells remain pointer-reachable because they are valid drag/drop and
	# tap destinations. Empty presses simply inspect nothing.
	button.disabled = _inventory_action_in_flight
	button.tooltip_text = _equipment_slot_tooltip(slot)
	var payload: EquipmentDragPayload = null
	if equipment_id != &"":
		payload = EquipmentDragPayload.new(
			EquipmentDragPayload.Origin.INVENTORY,
			area,
			slot_index,
			-1,
			equipment_id,
			str(slot.get("display_name", "ITEM")),
			int(_build_snapshot.get("inventory_revision", -1)),
			-1,
			slot.get("icon") as Texture2D
		)
	button.configure_drag_source(
		payload,
		_inventory_management_enabled
		and not _inventory_action_in_flight
		and equipment_id != &""
	)
	button.configure_drop_target(
		EquipmentDragPayload.Origin.INVENTORY,
		area,
		slot_index,
		_inventory_management_enabled and not _inventory_action_in_flight
	)


func _inventory_slot(area: StringName, slot_index: int) -> Dictionary:
	if slot_index < 0:
		return {}
	var key: String = (
		"slots" if area == SynergySystem.AREA_EQUIPPED else "backpack_slots"
	)
	if area != SynergySystem.AREA_EQUIPPED and area != SynergySystem.AREA_BACKPACK:
		return {}
	var slots: Array = _build_snapshot.get(key, [])
	if slot_index >= slots.size():
		return {}
	return slots[slot_index] as Dictionary


func _validate_inventory_selection() -> void:
	if _selected_inventory_id == &"":
		return
	var slot: Dictionary = _inventory_slot(_selected_inventory_area, _selected_inventory_slot)
	if StringName(slot.get("id", &"")) != _selected_inventory_id:
		_clear_inventory_selection()


func _clear_inventory_selection() -> void:
	_selected_inventory_area = &""
	_selected_inventory_slot = -1
	_selected_inventory_id = &""
	_pending_inventory_action = &""
	_pending_inventory_target = -1
	_pending_inventory_preview.clear()
	_inventory_action_in_flight = false


func _refresh_inventory_action_presentation() -> void:
	var has_selection: bool = _selected_inventory_id != &""
	for target_slot: int in range(_inventory_action_buttons.size()):
		var button: Button = _inventory_action_buttons[target_slot]
		button.disabled = (
			not has_selection
			or _inventory_action_in_flight
			or not _inventory_management_enabled
		)
		if not has_selection:
			button.text = "SELECT AN ITEM"
			continue
		var button_target_area: StringName = (
			SynergySystem.AREA_BACKPACK
			if _selected_inventory_area == SynergySystem.AREA_EQUIPPED
			else SynergySystem.AREA_EQUIPPED
		)
		var button_target: Dictionary = _inventory_slot(button_target_area, target_slot)
		var button_target_id: StringName = StringName(button_target.get("id", &""))
		var action_label: String = "ACTIVE"
		if button_target_area == SynergySystem.AREA_BACKPACK:
			action_label = "SWAP SLOT" if button_target_id != &"" else "STORE SLOT"
		button.text = "%s %s %d • %s" % [
			">" if target_slot == _pending_inventory_target else " ",
			action_label,
			target_slot + 1,
			str(button_target.get("display_name", "EMPTY")).to_upper(),
		]

	inventory_discard_button.disabled = (
		not has_selection
		or _inventory_action_in_flight
		or not _inventory_management_enabled
	)
	inventory_confirm_button.disabled = (
		_inventory_action_in_flight
		or not _inventory_management_enabled
		or _pending_inventory_action == &""
	)
	inventory_cancel_button.disabled = (
		_inventory_action_in_flight or _pending_inventory_action == &""
	)
	if not has_selection:
		inventory_action_prompt.text = "SELECT AN ITEM. INSPECTION NEVER CHANGES THE INVENTORY."
		return
	if not _inventory_management_enabled:
		inventory_action_prompt.text = (
			"INSPECTION ONLY DURING A FIGHT. MANAGE EQUIPMENT BETWEEN ENCOUNTERS."
		)
		return
	var selected: Dictionary = _inventory_slot(
		_selected_inventory_area,
		_selected_inventory_slot
	)
	var selected_name: String = str(selected.get("display_name", "ITEM")).to_upper()
	if _pending_inventory_action == &"":
		inventory_action_prompt.text = (
			"%s SELECTED.\nCHOOSE DESTINATION OR DISCARD." % selected_name
		)
		return
	if _pending_inventory_action == &"discard":
		inventory_action_prompt.text = _with_inventory_preview(
			"DISCARD %s?\nPERMANENT • CONFIRM REQUIRED." % selected_name
		)
		return
	if _pending_inventory_action == &"move_to_backpack":
		inventory_action_prompt.text = _with_inventory_preview(
			"BACKPACK %d: %s\nNO ITEM WILL BE LOST." % [
				_pending_inventory_target + 1,
				selected_name,
			]
		)
		return
	var target_area: StringName = (
		SynergySystem.AREA_BACKPACK
		if _selected_inventory_area == SynergySystem.AREA_EQUIPPED
		else SynergySystem.AREA_EQUIPPED
	)
	var target: Dictionary = _inventory_slot(
		target_area,
		_pending_inventory_target
	)
	var target_id: StringName = StringName(target.get("id", &""))
	if target_id != &"":
		inventory_action_prompt.text = _with_inventory_preview(
			"SWAP %s\nWITH %s • KEEP BOTH." % [
				selected_name,
				str(target.get("display_name", "ITEM")).to_upper(),
			]
		)
		return
	inventory_action_prompt.text = _with_inventory_preview(
		"ACTIVE %d: %s\nBACKPACK %d BECOMES EMPTY." % [
			_pending_inventory_target + 1,
			selected_name,
			_selected_inventory_slot + 1,
		]
	)


func _with_inventory_preview(base_text: String) -> String:
	if not bool(_pending_inventory_preview.get("valid", false)):
		return base_text
	_present_inventory_preview_details()
	return base_text


func _present_inventory_preview_details() -> void:
	var parts: PackedStringArray = PackedStringArray(["TRANSACTION PREVIEW"])
	var activations: Array = _pending_inventory_preview.get("immediate_activations", [])
	var deactivations: Array = _pending_inventory_preview.get("deactivations", [])
	var edges: PackedStringArray = PackedStringArray()
	if not activations.is_empty():
		edges.append("ACTIVATE %s" % _join_synergy_ids(activations))
	if not deactivations.is_empty():
		edges.append("LOSE %s" % _join_synergy_ids(deactivations))
	if not edges.is_empty():
		parts.append("  /  ".join(edges))
	var changes: Array = _pending_inventory_preview.get("exact_changes", [])
	for index: int in range(mini(changes.size(), 4)):
		parts.append(_format_exact_change(changes[index] as Dictionary))
	var post_state: String = _format_post_inventory_state(_pending_inventory_preview)
	if not post_state.is_empty():
		parts.append(post_state)
	var next_fight: String = str(_pending_inventory_preview.get("next_fight_consequence", ""))
	if not next_fight.is_empty():
		parts.append("NEXT FIGHT: %s" % next_fight)
	equipment_details_label.text = "\n".join(parts)


func _first_empty_backpack_slot() -> int:
	var slots: Array = _build_snapshot.get("backpack_slots", [])
	for slot_index: int in range(mini(slots.size(), SynergySystem.BACKPACK_SLOT_COUNT)):
		var slot: Dictionary = slots[slot_index] as Dictionary
		if StringName(slot.get("id", &"")) == &"":
			return slot_index
	return -1


func _reward_needs_full_backpack_choice() -> bool:
	if (
		_selected_reward_destination != SynergySystem.AREA_EQUIPPED
		or _selected_reward_slot < 0
	):
		return false
	var active: Dictionary = _inventory_slot(
		SynergySystem.AREA_EQUIPPED,
		_selected_reward_slot
	)
	return (
		StringName(active.get("id", &"")) != &""
		and _first_empty_backpack_slot() < 0
	)


func _reward_selection_is_complete() -> bool:
	if (
		_selected_reward_choice < 0
		or _selected_reward_choice >= _reward_choices.size()
	):
		return false
	if _selected_reward_destination == SynergySystem.AREA_BACKPACK:
		return (
			_selected_reward_backpack_slot >= 0
			and _selected_reward_backpack_slot < SynergySystem.BACKPACK_SLOT_COUNT
		)
	if _selected_reward_destination != SynergySystem.AREA_EQUIPPED:
		return false
	if _selected_reward_slot < 0 or _selected_reward_slot >= SynergySystem.SLOT_COUNT:
		return false
	var active: Dictionary = _inventory_slot(
		SynergySystem.AREA_EQUIPPED,
		_selected_reward_slot
	)
	if StringName(active.get("id", &"")) == &"":
		return true
	return (
		_selected_reward_outgoing_backpack_slot >= 0
		and _selected_reward_outgoing_backpack_slot < SynergySystem.BACKPACK_SLOT_COUNT
	)


func _reward_replaces_stored_item() -> bool:
	var backpack_slot: int = _selected_reward_backpack_slot
	if _selected_reward_destination == SynergySystem.AREA_EQUIPPED:
		backpack_slot = _selected_reward_outgoing_backpack_slot
	if backpack_slot < 0:
		return false
	return StringName(
		_inventory_slot(SynergySystem.AREA_BACKPACK, backpack_slot).get("id", &"")
	) != &""


func _reward_confirmation_text() -> String:
	var reward_line: String = _standard_reward_line()
	if _selected_reward_choice < 0 or _selected_reward_choice >= _reward_choices.size():
		if int(_build_snapshot.get("owned_count", 0)) >= (
			SynergySystem.SLOT_COUNT + SynergySystem.BACKPACK_SLOT_COUNT
		):
			return "INVENTORY FULL: REPLACE ONE EXACT ITEM OR SKIP GEAR.\n%s" % reward_line
		return "SELECT AN ITEM. NOTHING CHANGES UNTIL CONFIRM.\n%s" % reward_line
	var item: EquipmentDefinition = _reward_choices[_selected_reward_choice]
	if _selected_reward_destination == &"":
		return "%s SELECTED. CHOOSE ACTIVE OR BACKPACK; NOTHING CHANGED.\n%s" % [
			item.display_name.to_upper(),
			reward_line,
		]
	var transaction: String = ""
	var preview: Dictionary = {}
	if _selected_reward_destination == SynergySystem.AREA_BACKPACK:
		var stored: Dictionary = _inventory_slot(
			SynergySystem.AREA_BACKPACK,
			_selected_reward_backpack_slot
		)
		var stored_id: StringName = StringName(stored.get("id", &""))
		transaction = "STORE %s -> BACKPACK SLOT %d • %s" % [
			item.display_name.to_upper(),
			_selected_reward_backpack_slot + 1,
			(
				"DISCARD %s" % str(stored.get("display_name", "")).to_upper()
				if stored_id != &""
				else "NO ITEM LOST"
			),
		]
		preview = _storage_preview_for_choice(
			_selected_reward_choice,
			_selected_reward_backpack_slot
		)
	else:
		var active: Dictionary = _inventory_slot(
			SynergySystem.AREA_EQUIPPED,
			_selected_reward_slot
		)
		var active_id: StringName = StringName(active.get("id", &""))
		if active_id == &"":
			transaction = "EQUIP %s -> ACTIVE %d • NO ITEM LOST" % [
				item.display_name.to_upper(),
				_selected_reward_slot + 1,
			]
		else:
			if _selected_reward_outgoing_backpack_slot < 0:
				return "BACKPACK FULL: CHOOSE THE EXACT STORED ITEM TO DISCARD, OR SKIP.\n%s" % reward_line
			var displaced: Dictionary = _inventory_slot(
				SynergySystem.AREA_BACKPACK,
				_selected_reward_outgoing_backpack_slot
			)
			var displaced_id: StringName = StringName(displaced.get("id", &""))
			transaction = "EQUIP %s -> ACTIVE %d • %s -> PACK %d • %s" % [
				item.display_name.to_upper(),
				_selected_reward_slot + 1,
				str(active.get("display_name", "")).to_upper(),
				_selected_reward_outgoing_backpack_slot + 1,
				(
					"DISCARD %s" % str(displaced.get("display_name", "")).to_upper()
					if displaced_id != &""
					else "NO ITEM LOST"
				),
			]
		preview = _preview_for_choice(
			_selected_reward_choice,
			_selected_reward_slot,
			_selected_reward_outgoing_backpack_slot
		)
	var lines: PackedStringArray = PackedStringArray([transaction])
	var post_state: String = _format_post_inventory_state(preview)
	if not post_state.is_empty() and not _reward_needs_full_backpack_choice():
		lines.append(post_state)
	lines.append(reward_line)
	return "\n".join(lines)


func _standard_reward_line() -> String:
	if _standard_reward_preview.is_empty():
		return "RUN REWARD IS KEPT ON CONFIRM OR SKIP GEAR"
	return "REWARD: %s • +%d COINS • +%d SCRAP • SKIP KEEPS IT" % [
		str(_standard_reward_preview.get("display_name", "REWARD")).to_upper(),
		int(_standard_reward_preview.get("awarded_coins", _standard_reward_preview.get("coins", 0))),
		int(_standard_reward_preview.get("awarded_scrap", _standard_reward_preview.get("scrap", 0))),
	]


func _reward_synergy_edge_line(preview: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var activations: Array = preview.get("immediate_activations", [])
	var deactivations: Array = preview.get("deactivations", [])
	if not activations.is_empty():
		parts.append("ACTIVATE %s" % _join_synergy_ids(activations))
	if not deactivations.is_empty():
		parts.append("LOSE %s" % _join_synergy_ids(deactivations))
	return "  /  ".join(parts)


func _preview_for_choice(
	choice_index: int,
	slot_index: int,
	outgoing_backpack_slot: int = -1
) -> Dictionary:
	if choice_index < 0 or choice_index >= _reward_previews_by_choice.size():
		return {"valid": false}
	if outgoing_backpack_slot >= 0:
		var matrix: Array = _reward_previews_by_choice[choice_index].get(
			"by_slot_and_backpack",
			[]
		)
		if slot_index >= 0 and slot_index < matrix.size():
			var by_backpack: Array = matrix[slot_index] as Array
			if outgoing_backpack_slot < by_backpack.size():
				return by_backpack[outgoing_backpack_slot] as Dictionary
	var by_slot: Array = _reward_previews_by_choice[choice_index].get("by_slot", [])
	if slot_index < 0 or slot_index >= by_slot.size():
		return {"valid": false}
	return by_slot[slot_index] as Dictionary


func _storage_preview_for_choice(choice_index: int, slot_index: int) -> Dictionary:
	if choice_index < 0 or choice_index >= _reward_previews_by_choice.size():
		return {"valid": false}
	var by_slot: Array = _reward_previews_by_choice[choice_index].get(
		"by_backpack_slot",
		[]
	)
	if slot_index < 0 or slot_index >= by_slot.size():
		return {"valid": false}
	return by_slot[slot_index] as Dictionary


func _format_equipment_choice_overview(
	item: EquipmentDefinition,
	choice_index: int,
	stored_destination: bool
) -> String:
	var lines: PackedStringArray = _format_equipment_choice(
		item,
		{"valid": true}
	).split("\n")
	var activation_by_id: Dictionary[StringName, bool] = {}
	var alternative_by_tag: Dictionary[StringName, Dictionary] = {}
	if choice_index >= 0 and choice_index < _reward_previews_by_choice.size():
		var by_slot: Array = _reward_previews_by_choice[choice_index].get("by_slot", [])
		for preview_value: Variant in by_slot:
			var preview: Dictionary = preview_value as Dictionary
			if not bool(preview.get("valid", false)):
				continue
			for activation_value: Variant in preview.get("immediate_activations", []):
				activation_by_id[StringName(activation_value)] = true
			for alternative_value: Variant in preview.get("alternative_progress", []):
				var alternative: Dictionary = alternative_value as Dictionary
				var tag: StringName = StringName(alternative.get("tag", &""))
				if tag == &"":
					continue
				var previous: Dictionary = alternative_by_tag.get(tag, {})
				if (
					previous.is_empty()
					or int(alternative.get("after", 0)) > int(previous.get("after", 0))
				):
					alternative_by_tag[tag] = alternative

	var activation_ids: Array[StringName] = []
	activation_ids.assign(activation_by_id.keys())
	activation_ids.sort_custom(_string_name_before)
	if not activation_ids.is_empty():
		var activation_values: Array = []
		activation_values.assign(activation_ids)
		lines.append("CAN ACTIVATE: %s" % _join_synergy_ids(activation_values))

	var alternative_tags: Array[StringName] = []
	alternative_tags.assign(alternative_by_tag.keys())
	alternative_tags.sort_custom(_string_name_before)
	if not alternative_tags.is_empty():
		var alternative_parts: PackedStringArray = PackedStringArray()
		for tag: StringName in alternative_tags:
			var entry: Dictionary = alternative_by_tag[tag]
			alternative_parts.append("%s %d/%d" % [
				String(tag).to_upper(),
				int(entry.get("after", 0)),
				int(entry.get("threshold", 0)),
			])
		lines.append("CAN OPEN: %s" % " • ".join(alternative_parts))
	if stored_destination:
		lines.append("STORE: INACTIVE UNTIL EQUIPPED")
	return "\n".join(lines)


func _format_equipment_choice(item: EquipmentDefinition, preview: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(item.display_name.to_upper())
	if not item.role_label.strip_edges().is_empty():
		lines.append(item.role_label.to_upper())
	var promise_prefix: String = (
		"NEXT: "
		if not (preview.get("exact_changes", []) as Array).is_empty()
		else "PROMISE: "
	)
	if not item.combat_promise.strip_edges().is_empty():
		lines.append_array(_wrap_compact(
			promise_prefix + item.combat_promise.to_upper(),
			31
		))
	lines.append("[%s]" % _join_string_names(item.sorted_tags()))
	var replaced_name: String = str(preview.get("replaces_name", ""))
	if not replaced_name.is_empty():
		lines.append("REPLACE: %s" % replaced_name.to_upper())
	var activations: Array = preview.get("immediate_activations", [])
	var deactivations: Array = preview.get("deactivations", [])
	var immediate_parts: PackedStringArray = PackedStringArray()
	if not activations.is_empty():
		immediate_parts.append("+%s" % _join_synergy_ids(activations))
	if not deactivations.is_empty():
		immediate_parts.append("-%s" % _join_synergy_ids(deactivations))
	if not immediate_parts.is_empty():
		lines.append("NOW: %s" % " • ".join(immediate_parts))
	var exact_changes: Array = preview.get("exact_changes", [])
	var prioritized_changes: Array[Dictionary] = _prioritize_exact_changes(exact_changes)
	for change_index: int in range(mini(prioritized_changes.size(), 2)):
		lines.append(_format_exact_change(prioritized_changes[change_index]))
	var alternative: Array = preview.get("alternative_progress", [])
	if not alternative.is_empty():
		var alternative_parts: PackedStringArray = PackedStringArray()
		for value: Variant in alternative:
			var entry: Dictionary = value as Dictionary
			alternative_parts.append("%s %d/%d" % [
				str(entry.get("tag", &"")).to_upper(),
				int(entry.get("after", 0)),
				int(entry.get("threshold", 0)),
			])
		lines.append("OTHER PATH: %s" % " • ".join(alternative_parts))
	if bool(preview.get("stored_inactive", false)):
		lines.append("STORE: INACTIVE UNTIL EQUIPPED")
	if not bool(preview.get("valid", false)):
		lines.append("SELECT TO REVIEW BUILD PATHS")
	return "\n".join(lines)


func _equipment_slot_tooltip(slot: Dictionary) -> String:
	if StringName(slot.get("id", &"")) == &"":
		return "Empty generic slot. Drag an item here or use the click/tap destination controls."
	var lines: PackedStringArray = PackedStringArray()
	lines.append(str(slot.get("display_name", "EQUIPMENT")).to_upper())
	lines.append("Tags: %s" % _join_string_names(slot.get("tags", [])))
	for effect_text: Variant in slot.get("major_effects", PackedStringArray()):
		lines.append("• %s" % str(effect_text))
	lines.append("Click to inspect or drag between columns. Dropping never discards an item.")
	return "\n".join(lines)


func _format_exact_change(change: Dictionary) -> String:
	return "%s %s -> %s" % [
		str(change.get("label", "VALUE")).to_upper(),
		BuildConsequenceEvaluator.format_value(change, &"before"),
		BuildConsequenceEvaluator.format_value(change, &"after"),
	]


func _prioritize_exact_changes(values: Array) -> Array[Dictionary]:
	var gains: Array[Dictionary] = []
	var tradeoffs: Array[Dictionary] = []
	for value: Variant in values:
		var change: Dictionary = value as Dictionary
		var before: float = float(change.get("before", 0.0))
		var after: float = float(change.get("after", 0.0))
		var higher_is_better: bool = bool(change.get("higher_is_better", true))
		var improvement: bool = (
			after > before if higher_is_better else after < before
		)
		(gains if improvement else tradeoffs).append(change)
	var result: Array[Dictionary] = []
	if not gains.is_empty():
		result.append(gains.pop_front())
	if not tradeoffs.is_empty():
		result.append(tradeoffs.pop_front())
	result.append_array(gains)
	result.append_array(tradeoffs)
	return result


func _format_post_inventory_state(preview: Dictionary) -> String:
	var active_names: PackedStringArray = _compact_inventory_names(
		preview.get("slots_after", [])
	)
	var backpack_names: PackedStringArray = _compact_inventory_names(
		preview.get("backpack_slots_after", [])
	)
	if active_names.is_empty() and backpack_names.is_empty():
		return ""
	return "AFTER ACTIVE: %s  /  BACKPACK: %s" % [
		" | ".join(active_names),
		" | ".join(backpack_names),
	]


func _compact_inventory_names(values: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if not (values is Array):
		return result
	for value: Variant in values as Array:
		var slot: Dictionary = value as Dictionary
		var name: String = str(slot.get("display_name", "EMPTY")).to_upper()
		result.append(name.substr(0, mini(name.length(), 10)))
	return result


func _first_empty_build_slot() -> int:
	var slots: Array = _build_snapshot.get("slots", [])
	for slot_index: int in range(mini(slots.size(), SynergySystem.SLOT_COUNT)):
		var slot: Dictionary = slots[slot_index] as Dictionary
		if StringName(slot.get("id", &"")) == &"":
			return slot_index
	return -1


func _join_string_names(values: Variant) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for value: Variant in values:
		parts.append(str(value))
	return " • ".join(parts)


func _join_synergy_ids(values: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for value: Variant in values:
		parts.append(str(value).replace("_", " ").to_upper())
	return " + ".join(parts)


func _wrap_compact(value: String, maximum_characters: int) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var words: PackedStringArray = value.split(" ", false)
	var line: String = ""
	for word: String in words:
		var candidate: String = word if line.is_empty() else "%s %s" % [line, word]
		if candidate.length() > maximum_characters and not line.is_empty():
			result.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		result.append(line)
	return result


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
