class_name RunSequenceVFX
extends Node

## Animates the result of a RUN attempt on screen.
## Receives a FailureCascadeResult from RunSimulationController.vfx_play_requested
## and plays the matching visual sequence, then emits vfx_complete.
##
## Usage:
##   1. rsc.connect_vfx(vfx_node) — wires vfx_play_requested → handle_play,
##      and vfx_complete → rsc._on_vfx_complete.
##   2. In tests, call notify_vfx_complete() to skip Tween timing.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State { IDLE, PLAYING }

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

## Delay between organ failure cards in ms. Increase for dramatic cascade feel.
@export var cascade_stagger_ms: float = 180.0

## Duration of the success green flash in seconds.
@export var success_duration_sec: float = 1.8

## Duration of the organ failure red flash in seconds.
@export var organ_failure_duration_sec: float = 1.2

## Duration of the structural failure overlay in seconds.
@export var structural_failure_duration_sec: float = 2.2

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the full visual sequence finishes.
## RunSimulationController.connect_vfx() listens to this.
signal vfx_complete

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _state: State = State.IDLE
var _overlay: ColorRect
var _text_label: Label

# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "VFXOverlay"
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_text_label = Label.new()
	_text_label.name = "VFXTextLabel"
	_text_label.anchor_left = 0.5
	_text_label.anchor_right = 0.5
	_text_label.anchor_top = 0.5
	_text_label.anchor_bottom = 0.5
	_text_label.offset_left = -100.0
	_text_label.offset_right = 100.0
	_text_label.offset_top = -20.0
	_text_label.offset_bottom = 20.0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.visible = false
	add_child(_text_label)

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Entry point connected to RunSimulationController.vfx_play_requested.
## Dispatches to the appropriate animation sequence.
## Silently ignored while PLAYING — RunSimulationController guards this via state.
func handle_play(result: FailureCascadeResult) -> void:
	if _state == State.PLAYING:
		return
	_state = State.PLAYING
	match result.failure_type:
		FailureCascadeResult.FailureType.NONE:
			_play_success()
		FailureCascadeResult.FailureType.ORGAN:
			_play_organ_failure(result.failed_organs)
		FailureCascadeResult.FailureType.STRUCTURAL:
			_play_structural_failure(result.structural_code)
		_:
			push_warning("RunSequenceVFX: unknown failure_type %d — defaulting to success." % result.failure_type)
			_play_success()


## Test seam: bypasses Tween timing and fires vfx_complete immediately.
## Equivalent to notify_vfx_complete() on RunSimulationController.
func notify_vfx_complete() -> void:
	_on_sequence_finished()

# ---------------------------------------------------------------------------
# Private — animation sequences
# ---------------------------------------------------------------------------

func _play_success() -> void:
	_text_label.text = "✓ Specimen Repaired"
	_text_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	_text_label.visible = true

	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0.0, 0.6, 0.1, 0.45), success_duration_sec * 0.3)
	tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), success_duration_sec * 0.7)
	tween.finished.connect(_on_sequence_finished)


func _play_organ_failure(p_failed_organs: Array[String]) -> void:
	var organ_list: String = ", ".join(p_failed_organs) if not p_failed_organs.is_empty() else "?"
	_text_label.text = "✗ Organ Failure\n%s" % organ_list
	_text_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_text_label.visible = true

	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0.7, 0.1, 0.0, 0.5), organ_failure_duration_sec * 0.3)
	tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), organ_failure_duration_sec * 0.7)
	tween.finished.connect(_on_sequence_finished)


func _play_structural_failure(p_structural_code: String) -> void:
	var code_display: String = p_structural_code if not p_structural_code.is_empty() else "UNKNOWN"
	_text_label.text = "✗ System Failure\n[%s]" % code_display
	_text_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	_text_label.visible = true

	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0.5, 0.0, 0.0, 0.7), structural_failure_duration_sec * 0.2)
	tween.tween_interval(structural_failure_duration_sec * 0.4)
	tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), structural_failure_duration_sec * 0.4)
	tween.finished.connect(_on_sequence_finished)

# ---------------------------------------------------------------------------
# Private — sequence completion
# ---------------------------------------------------------------------------

func _on_sequence_finished() -> void:
	if _state != State.PLAYING:
		return
	_state = State.IDLE
	_text_label.visible = false
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	vfx_complete.emit()
