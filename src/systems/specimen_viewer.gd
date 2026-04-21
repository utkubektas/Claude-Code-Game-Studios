class_name SpecimenViewer
extends Node2D

## Creature specimen display node.
## Renders organ slots as coloured placeholders, draws channel lines between
## slots, and responds to selection/placement signals from OrganRepairMechanic
## and PuzzleInstance.
##
## Usage:
##   1. setup() — inject dependencies.
##   2. load_creature(healthy_config) — build slot state and register touch areas.
##   3. Connect OrganRepairMechanic.slot_selected / slot_deselected → set_slot_selected().
##   4. Connect RunSimulationController.locked / unlocked → lock_interaction() / unlock_interaction().

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const CHANNEL_COLOR_PULSE: Color = Color(0.2, 0.6, 1.0)   ## Electric blue
const CHANNEL_COLOR_FLUID: Color = Color(0.2, 0.8, 0.3)   ## Organic green
const CHANNEL_WIDTH_PULSE: float = 2.0
const CHANNEL_WIDTH_FLUID: float = 4.0
const SLOT_COLOR_NORMAL: Color   = Color(0.3, 0.3, 0.4)   ## Dark grey placeholder
const SLOT_COLOR_DAMAGED: Color  = Color(0.7, 0.2, 0.2)   ## Red tint
const SLOT_SELECTED_COLOR: Color = Color(1.0, 0.85, 0.0)  ## Yellow border
const SLOT_SELECTED_WIDTH: float = 3.0
const SILHOUETTE_COLOR: Color    = Color(0.15, 0.15, 0.2) ## Very dark creature bg
## Font size for the organ ID label drawn inside each slot (pixels).
const SLOT_LABEL_FONT_SIZE: int = 11
## Offset from the slot centre to the top-left of the organ ID label.
const SLOT_LABEL_OFFSET: Vector2 = Vector2(-30.0, 4.0)

# ---------------------------------------------------------------------------
# Enums — R6: PascalCase, no leading underscore
# ---------------------------------------------------------------------------

enum State { EMPTY, ACTIVE, LOCKED }

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

## Side length of each organ slot widget in pixels.
@export var slot_size: float = 80.0

## Screen-space anchor point for the creature centre (MVP: fixed position).
@export var creature_anchor: Vector2 = Vector2(240.0, 300.0)

## Half-width of the creature silhouette placeholder rect. R1.
@export var silhouette_half_width: float = 80.0

## Half-height of the creature silhouette placeholder rect. R1.
@export var silhouette_half_height: float = 120.0

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _state: State = State.EMPTY
var _creature: CreatureTypeResource
var _registry: OrganTypeRegistry
var _handler: TouchInputHandler
var _puzzle_instance: PuzzleInstance
## Per-slot state: { damaged: bool, selected: bool }
var _slot_states: Array[Dictionary] = []
var _healthy_config: Array[String] = []

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Wires all external dependencies. Must be called before load_creature().
func setup(
	p_creature: CreatureTypeResource,
	p_registry: OrganTypeRegistry,
	p_handler: TouchInputHandler,
	p_puzzle_instance: PuzzleInstance
) -> void:
	assert(p_creature != null, "SpecimenViewer.setup: p_creature must not be null")       ## R3
	assert(p_puzzle_instance != null, "SpecimenViewer.setup: p_puzzle_instance must not be null") ## R3
	_creature = p_creature
	_registry = p_registry
	_handler = p_handler
	_puzzle_instance = p_puzzle_instance
	_puzzle_instance.organ_placed.connect(_on_organ_placed)


## Loads the creature layout: clears old touch areas, builds slot state,
## registers new touch areas, and transitions to ACTIVE.
func load_creature(p_healthy_config: Array[String]) -> void:
	assert(_creature != null, "SpecimenViewer.load_creature: call setup() first")
	_clear_touch_areas()
	_healthy_config = p_healthy_config
	_build_slot_states()
	_register_touch_areas()
	_state = State.ACTIVE
	refresh_slots()
	queue_redraw()


## Recomputes the damaged flag for every slot from the current puzzle configuration.
## No-op if the viewer has not yet loaded a creature.
func refresh_slots() -> void:
	if _state == State.EMPTY:
		return
	for i: int in range(_slot_states.size()):
		_slot_states[i].damaged = (
			_puzzle_instance.current_configuration[i] != _healthy_config[i]
		)
	queue_redraw()


## Sets or clears the selected highlight on a single slot.
## Silently ignores out-of-range indices.
func set_slot_selected(slot_index: int, selected: bool) -> void:
	if _state == State.EMPTY:
		return
	if slot_index < 0 or slot_index >= _slot_states.size():
		return
	_slot_states[slot_index].selected = selected
	queue_redraw()


## Enters LOCKED state: draws a dark overlay and blocks visual feedback.
## Pair with RunSimulationController.locked signal.
func lock_interaction() -> void:
	_state = State.LOCKED
	queue_redraw()


## Returns to ACTIVE state.
## Pair with RunSimulationController.unlocked signal.
func unlock_interaction() -> void:
	_state = State.ACTIVE
	queue_redraw()

# ---------------------------------------------------------------------------
# Godot callbacks
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _state == State.EMPTY or _creature == null:
		return
	_draw_silhouette()
	_draw_channels()
	_draw_slots()
	if _state == State.LOCKED:
		## R2: transform viewport rect into this node's local draw space via
		## the canvas transform, which accounts for all parent transforms and Camera2D.
		var vp_rect: Rect2 = get_viewport_rect()
		var local_rect: Rect2 = get_canvas_transform().affine_inverse() * vp_rect
		draw_rect(local_rect, Color(0.0, 0.0, 0.0, 0.3))

# ---------------------------------------------------------------------------
# Private — draw helpers
# ---------------------------------------------------------------------------

func _draw_silhouette() -> void:
	## R1: dimensions driven by exported tuning knobs.
	draw_rect(
		Rect2(
			creature_anchor - Vector2(silhouette_half_width, silhouette_half_height),
			Vector2(silhouette_half_width * 2.0, silhouette_half_height * 2.0)
		),
		SILHOUETTE_COLOR
	)


func _draw_channels() -> void:
	if _creature.slot_channels.is_empty():
		return
	for ch: SlotChannel in _creature.slot_channels:
		if ch.from_slot_index >= _creature.organ_slots.size():
			continue
		if ch.to_slot_index >= _creature.organ_slots.size():
			continue
		if ch.from_slot_index == ch.to_slot_index:
			push_warning("SpecimenViewer: SlotChannel from == to (%d) — skipped." % ch.from_slot_index)
			continue
		var from_center: Vector2 = _slot_world_pos(ch.from_slot_index)
		var to_center: Vector2 = _slot_world_pos(ch.to_slot_index)
		var color: Color
		var width: float
		match ch.flow_type:
			OrganTypeResource.FlowType.PULSE:
				color = CHANNEL_COLOR_PULSE
				width = CHANNEL_WIDTH_PULSE
			OrganTypeResource.FlowType.FLUID:
				color = CHANNEL_COLOR_FLUID
				width = CHANNEL_WIDTH_FLUID
			_:
				color = CHANNEL_COLOR_PULSE
				width = CHANNEL_WIDTH_PULSE
		draw_line(from_center, to_center, color, width)


func _draw_slots() -> void:
	## R4: guard against stale _slot_states after a partial reload.
	if _slot_states.size() != _creature.organ_slots.size():
		return
	for i: int in range(_creature.organ_slots.size()):
		var slot: OrganSlotDefinition = _creature.organ_slots[i]
		var center: Vector2 = creature_anchor + slot.world_position
		var half: float = slot_size * 0.5
		var rect: Rect2 = Rect2(center - Vector2(half, half), Vector2(slot_size, slot_size))
		var slot_state: Dictionary = _slot_states[i]
		var fill_color: Color = SLOT_COLOR_DAMAGED if slot_state.damaged else SLOT_COLOR_NORMAL
		draw_rect(rect, fill_color)
		if slot_state.selected:
			draw_rect(rect, SLOT_SELECTED_COLOR, false, SLOT_SELECTED_WIDTH)
		var organ_id: String = _puzzle_instance.current_configuration[i]
		var short_id: String = organ_id.left(6) if organ_id.length() > 6 else organ_id
		draw_string(
			ThemeDB.fallback_font,
			center + SLOT_LABEL_OFFSET,
			short_id,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			SLOT_LABEL_FONT_SIZE,
			Color.WHITE
		)

# ---------------------------------------------------------------------------
# Private — setup helpers
# ---------------------------------------------------------------------------

## Unregisters all slot touch areas from the previous creature load.
func _clear_touch_areas() -> void:
	if _handler == null:
		return
	for i: int in range(_slot_states.size()):
		_handler.unregister_area("slot_%d" % i)


## Rebuilds _slot_states to match the current creature's slot count.
func _build_slot_states() -> void:
	_slot_states.clear()
	for _i: int in range(_creature.organ_slots.size()):
		_slot_states.append({ "damaged": false, "selected": false })


## Registers each slot as a SLOT touch area on the TouchInputHandler.
func _register_touch_areas() -> void:
	if _handler == null:
		return
	for i: int in range(_creature.organ_slots.size()):
		var center: Vector2 = _slot_world_pos(i)
		var half: float = slot_size * 0.5
		var rect: Rect2 = Rect2(center - Vector2(half, half), Vector2(slot_size, slot_size))
		_handler.register_area(
			"slot_%d" % i,
			rect,
			TouchInputHandler.TouchAreaType.SLOT,
			i
		)


func _slot_world_pos(slot_index: int) -> Vector2:
	return creature_anchor + _creature.organ_slots[slot_index].world_position

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_organ_placed(_slot_index: int, _organ_id: String) -> void:
	refresh_slots()
