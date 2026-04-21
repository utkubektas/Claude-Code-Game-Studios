class_name ScreenNavigation
extends Node

## Coordinates screen transitions between the game's top-level screens.
## MVP: signal-only — emits scene_change_requested(screen_id, params) instead
## of calling SceneTree directly, keeping it unit-testable.
##
## Usage:
##   1. Add as a child of the root scene.
##   2. Connect RunSimulationController.puzzle_solved → go_to_puzzle(next).
##   3. Connect scene_change_requested to the scene loader that calls
##      get_tree().change_scene_to_file() in the real game.

# ---------------------------------------------------------------------------
# Screen ID constants
# ---------------------------------------------------------------------------

const SCREEN_MAIN_MENU: String = "main_menu"
const SCREEN_PUZZLE: String = "puzzle"
const SCREEN_END: String = "end_screen"

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State { IDLE, TRANSITIONING }

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

## Fade duration placeholder (not used in MVP; reserved for Sprint 04 transition).
@export var fade_duration_sec: float = 0.2

## Total number of puzzles in the game. Used by go_to_next_puzzle().
@export var total_puzzle_count: int = 10

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a screen change is requested.
## screen_id: one of the SCREEN_* constants, or a custom string.
## params: optional data forwarded to the target screen (e.g., {"puzzle_index": 3}).
signal scene_change_requested(screen_id: String, params: Dictionary)

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _state: State = State.IDLE
var _current_puzzle_index: int = 0

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Transitions to a specific puzzle by index.
## Silently ignored while TRANSITIONING.
func go_to_puzzle(puzzle_index: int) -> void:
	if _state == State.TRANSITIONING:
		return
	_current_puzzle_index = puzzle_index
	go_to(SCREEN_PUZZLE, { "puzzle_index": puzzle_index })


## Advances to the next puzzle; goes to end_screen if the last puzzle was solved.
## Silently ignored while TRANSITIONING.
func go_to_next_puzzle() -> void:
	if _state == State.TRANSITIONING:
		return
	var next_index: int = _current_puzzle_index + 1
	if next_index > total_puzzle_count:
		go_to(SCREEN_END, {})
	else:
		go_to_puzzle(next_index)


## General-purpose transition. Validates screen_id; falls back to main_menu
## on unknown IDs. Silently ignored while TRANSITIONING.
func go_to(screen_id: String, params: Dictionary = {}) -> void:
	if _state == State.TRANSITIONING:
		return

	var resolved_id: String = screen_id
	if not _is_known_screen(screen_id):
		push_warning(
			"ScreenNavigation: unknown screen_id '%s' — falling back to '%s'." % [
				screen_id, SCREEN_MAIN_MENU
			]
		)
		resolved_id = SCREEN_MAIN_MENU

	_state = State.TRANSITIONING
	scene_change_requested.emit(resolved_id, params)
	# MVP: no async fade — return to IDLE immediately after emitting.
	_state = State.IDLE

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _is_known_screen(screen_id: String) -> bool:
	return screen_id == SCREEN_MAIN_MENU \
		or screen_id == SCREEN_PUZZLE \
		or screen_id == SCREEN_END
