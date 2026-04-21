class_name OrganRepairMechanic
extends Node

## Slot selection and organ placement mechanic for the Organ Repair interaction layer.
##
## Manages a four-state machine (IDLE, SLOT_SELECTED, LOCKED, LOCKED_PRE_ATT) that
## mediates between TouchInputHandler tap signals and PuzzleInstance mutations.
## Callers (RunSimulationController) drive LOCKED/unlock transitions.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Organ ID that is locked until the player's first attempt completes (ossuric guard).
## Matches OrganTypeResource.organ_id — change here if the organ ID ever changes.
const LOCKED_PRE_ATT_ORGAN_ID: String = "ossuric"

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum _State {
	IDLE,           ## No slot selected; waiting for player input.
	SLOT_SELECTED,  ## A slot is active; waiting for organ choice from inventory.
	LOCKED,         ## RUN animation in progress; all input silently ignored.
	LOCKED_PRE_ATT, ## Ossuric card locked until the first attempt completes.
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player selects a slot.
signal slot_selected(slot_index: int)

## Emitted when a slot is deselected (same slot tapped again, different slot chosen,
## or an organ is successfully placed).
signal slot_deselected(slot_index: int)

## Emitted when an organ is successfully written into PuzzleInstance.
signal organ_placed(slot_index: int, organ_id: String)

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _puzzle_instance: PuzzleInstance
var _selected_slot: int = -1
var _ossuric_locked: bool = true
var _state: _State = _State.IDLE

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Binds this mechanic to a PuzzleInstance.
## If attempt_count >= 1 the ossuric card is considered already unlocked.
func setup(p_puzzle_instance: PuzzleInstance) -> void:
	_puzzle_instance = p_puzzle_instance
	_selected_slot = -1
	_state = _State.IDLE
	_ossuric_locked = p_puzzle_instance.attempt_count < 1


## Connects slot_tapped and inventory_tapped signals from a TouchInputHandler.
func connect_input(p_handler: TouchInputHandler) -> void:
	p_handler.slot_tapped.connect(_on_slot_tapped)
	p_handler.inventory_tapped.connect(_on_inventory_tapped)


## Enters LOCKED state; all input is silently ignored until unlock() is called.
func lock() -> void:
	_state = _State.LOCKED


## Returns to IDLE state and clears any active slot selection.
func unlock() -> void:
	_selected_slot = -1
	_state = _State.IDLE


## Called by RunSimulationController when the first attempt animation completes.
## Permanently clears the LOCKED_PRE_ATT guard on the ossuric organ card.
func on_attempt_completed() -> void:
	_ossuric_locked = false
	if _state == _State.LOCKED_PRE_ATT:
		_state = _State.IDLE

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _on_slot_tapped(index: int) -> void:
	if _state == _State.LOCKED:
		return

	if _selected_slot == -1:
		_selected_slot = index
		_state = _State.SLOT_SELECTED
		slot_selected.emit(index)

	elif _selected_slot == index:
		slot_deselected.emit(index)
		_selected_slot = -1
		_state = _State.IDLE

	else:
		slot_deselected.emit(_selected_slot)
		_selected_slot = index
		slot_selected.emit(index)


func _on_inventory_tapped(organ_id: String) -> void:
	if _state == _State.LOCKED:
		return

	if organ_id == LOCKED_PRE_ATT_ORGAN_ID and _ossuric_locked:
		return

	if _selected_slot == -1:
		return

	# Only clear selection if the placement was accepted.
	# GDD edge case: if set_organ() fails, selection is preserved so the player can retry.
	var placed: bool = _puzzle_instance.set_organ(_selected_slot, organ_id)
	if not placed:
		return
	organ_placed.emit(_selected_slot, organ_id)
	slot_deselected.emit(_selected_slot)
	_selected_slot = -1
	_state = _State.IDLE
