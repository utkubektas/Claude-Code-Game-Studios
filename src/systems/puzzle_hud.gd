class_name PuzzleHUD
extends CanvasLayer

## UI overlay for the puzzle screen.
## Shows organ inventory cards, RUN button, puzzle title, attempt counter,
## and result message. Registers touch areas with TouchInputHandler so
## inventory taps and RUN taps emit the correct signals.
##
## Usage:
##   1. setup(registry, handler, puzzle_instance) — inject deps and build nodes.
##   2. load_puzzle(puzzle_resource) — update title and attempt labels.
##   3. lock() / unlock() — dim UI during simulation.
##   4. update_attempts() — refresh attempt counter after attempt_completed.
##   5. show_result(is_success) — display end-of-run result and Devam Et label.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const RUN_COLOR: Color = Color(0.1, 0.1, 0.15)
## Card background colours, one per inventory slot (index matches registry order).
const CARD_COLORS: Array = [
	Color(0.4, 0.2, 0.5),   ## vordex — purple
	Color(0.2, 0.4, 0.5),   ## valdris — teal
	Color(0.2, 0.5, 0.3),   ## thrennic — green
	Color(0.5, 0.3, 0.1),   ## ossuric — amber
]
const _MAX_ORGANS: int = 4
const _GRID_COLS: int = 2

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State { ACTIVE, LOCKED, SOLVED }

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

@export var screen_width: float = 480.0
@export var screen_height: float = 800.0
## Top of inventory grid as a fraction of screen height.
@export_range(0.0, 1.0, 0.01) var inventory_start_y_ratio: float = 0.62
## Centre Y of RUN button as a fraction of screen height.
@export_range(0.0, 1.0, 0.01) var run_button_y_ratio: float = 0.85
@export var card_height: float = 70.0
@export var card_gap: float = 8.0
@export var run_button_width: float = 200.0
@export var run_button_height: float = 60.0

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _registry: OrganTypeRegistry
var _handler: TouchInputHandler
var _puzzle_instance: PuzzleInstance
var _state: State = State.ACTIVE
var _organ_ids: Array[String] = []

var _title_label: Label
var _attempt_label: Label
var _card_labels: Array[Label] = []
var _card_rects: Array[ColorRect] = []
var _run_label: Label
var _run_rect: ColorRect
var _result_label: Label
var _continue_label: Label

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Injects dependencies, builds all child nodes, and registers touch areas.
## Must be called before load_puzzle().
func setup(
	p_registry: OrganTypeRegistry,
	p_handler: TouchInputHandler,
	p_puzzle_instance: PuzzleInstance
) -> void:
	_registry = p_registry
	_handler = p_handler
	_puzzle_instance = p_puzzle_instance
	_build_organ_ids()
	_create_nodes()
	_register_touch_areas()


## Updates the title and attempt labels from the given PuzzleResource.
func load_puzzle(p_puzzle_resource: PuzzleResource) -> void:
	_title_label.text = "%s  #%d" % [p_puzzle_resource.display_title, p_puzzle_resource.puzzle_index]
	_attempt_label.text = "Deneme: %d" % _puzzle_instance.attempt_count


## Refreshes the attempt counter label from the current PuzzleInstance state.
## Connect to RunSimulationController.attempt_completed.
func update_attempts() -> void:
	_attempt_label.text = "Deneme: %d" % _puzzle_instance.attempt_count


## Enters LOCKED state: dims all interactive elements to alpha 0.5.
func lock() -> void:
	_state = State.LOCKED
	_set_interactive_modulate(Color(1.0, 1.0, 1.0, 0.5))


## Returns to ACTIVE state: restores full opacity on all interactive elements.
func unlock() -> void:
	_state = State.ACTIVE
	_set_interactive_modulate(Color.WHITE)


## Displays the result message and a Devam Et prompt.
## Transitions to SOLVED state and registers the continue_btn touch area.
func show_result(is_success: bool) -> void:
	_state = State.SOLVED
	_result_label.text = "✓ Specimen repaired" if is_success else "✗ System failure"
	_result_label.visible = true
	_continue_label.visible = true
	_register_continue_area()

# ---------------------------------------------------------------------------
# Private — node creation
# ---------------------------------------------------------------------------

func _build_organ_ids() -> void:
	_organ_ids.clear()
	var limit: int = mini(_registry.organs.size(), _MAX_ORGANS)
	for i: int in range(limit):
		_organ_ids.append(_registry.organs[i].organ_id)


func _create_nodes() -> void:
	_create_header_labels()
	_create_inventory_cards()
	_create_run_button()
	_create_overlay_labels()


func _create_header_labels() -> void:
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(8.0, screen_height * 0.58)
	add_child(_title_label)

	_attempt_label = Label.new()
	_attempt_label.name = "AttemptLabel"
	_attempt_label.position = Vector2(screen_width * 0.6, screen_height * 0.58)
	add_child(_attempt_label)


func _create_inventory_cards() -> void:
	var card_width: float = _card_width()
	for i: int in range(_organ_ids.size()):
		var col: int = i % _GRID_COLS
		var row: int = i / _GRID_COLS
		var cx: float = _card_x(col, card_width)
		var cy: float = _card_y(row)
		var organ: OrganTypeResource = _registry.get_organ(_organ_ids[i])
		var display: String = organ.display_name if organ != null else _organ_ids[i]

		var rect := ColorRect.new()
		rect.name = "CardRect%d" % i
		rect.position = Vector2(cx, cy)
		rect.size = Vector2(card_width, card_height)
		rect.color = CARD_COLORS[i] if i < CARD_COLORS.size() else Color.GRAY
		add_child(rect)
		_card_rects.append(rect)

		var lbl := Label.new()
		lbl.name = "CardLabel%d" % i
		lbl.text = display
		lbl.position = Vector2(cx + 4.0, cy + (card_height - 16.0) * 0.5)
		add_child(lbl)
		_card_labels.append(lbl)


func _create_run_button() -> void:
	var run_x: float = (screen_width - run_button_width) / 2.0
	var run_y: float = screen_height * run_button_y_ratio - run_button_height / 2.0

	_run_rect = ColorRect.new()
	_run_rect.name = "RunRect"
	_run_rect.position = Vector2(run_x, run_y)
	_run_rect.size = Vector2(run_button_width, run_button_height)
	_run_rect.color = RUN_COLOR
	add_child(_run_rect)

	_run_label = Label.new()
	_run_label.name = "RunLabel"
	_run_label.text = "RUN"
	_run_label.position = Vector2(run_x + run_button_width * 0.5 - 16.0, run_y + run_button_height * 0.5 - 8.0)
	add_child(_run_label)


func _create_overlay_labels() -> void:
	_result_label = Label.new()
	_result_label.name = "ResultLabel"
	_result_label.position = Vector2(screen_width * 0.5 - 80.0, screen_height * 0.5)
	_result_label.visible = false
	add_child(_result_label)

	_continue_label = Label.new()
	_continue_label.name = "ContinueLabel"
	_continue_label.text = "Devam Et"
	_continue_label.position = Vector2(screen_width * 0.5 - 40.0, screen_height * 0.5 + 40.0)
	_continue_label.visible = false
	add_child(_continue_label)

# ---------------------------------------------------------------------------
# Private — touch area registration
# ---------------------------------------------------------------------------

func _register_touch_areas() -> void:
	var card_width: float = _card_width()
	for i: int in range(_organ_ids.size()):
		var col: int = i % _GRID_COLS
		var row: int = i / _GRID_COLS
		_handler.register_area(
			"inv_%s" % _organ_ids[i],
			Rect2(_card_x(col, card_width), _card_y(row), card_width, card_height),
			TouchInputHandler.TouchAreaType.INVENTORY,
			_organ_ids[i]
		)

	var run_x: float = (screen_width - run_button_width) / 2.0
	var run_y: float = screen_height * run_button_y_ratio - run_button_height / 2.0
	_handler.register_area(
		"run_btn",
		Rect2(run_x, run_y, run_button_width, run_button_height),
		TouchInputHandler.TouchAreaType.RUN_BUTTON,
		null
	)


func _register_continue_area() -> void:
	_handler.register_area(
		"continue_btn",
		Rect2(screen_width * 0.5 - 60.0, screen_height * 0.5 + 32.0, 120.0, 48.0),
		TouchInputHandler.TouchAreaType.GENERIC,
		null
	)

# ---------------------------------------------------------------------------
# Private — layout helpers
# ---------------------------------------------------------------------------

func _card_width() -> float:
	return (screen_width - (_GRID_COLS + 1) * card_gap) / float(_GRID_COLS)


func _card_x(p_col: int, p_card_width: float) -> float:
	return card_gap + p_col * (p_card_width + card_gap)


func _card_y(p_row: int) -> float:
	return screen_height * inventory_start_y_ratio + p_row * (card_height + card_gap)


func _set_interactive_modulate(p_color: Color) -> void:
	for rect: ColorRect in _card_rects:
		rect.modulate = p_color
	for lbl: Label in _card_labels:
		lbl.modulate = p_color
	_run_rect.modulate = p_color
	_run_label.modulate = p_color
