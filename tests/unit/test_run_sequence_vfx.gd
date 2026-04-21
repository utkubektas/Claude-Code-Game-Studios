extends GutTest

## T14 — RunSequenceVFX acceptance criteria

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _vfx: RunSequenceVFX

func before_each() -> void:
	_vfx = null


func after_each() -> void:
	if is_instance_valid(_vfx):
		_vfx.queue_free()
	_vfx = null


func _make_vfx() -> RunSequenceVFX:
	var v := RunSequenceVFX.new()
	add_child(v)
	return v


func _make_result(p_type: FailureCascadeResult.FailureType) -> FailureCascadeResult:
	var r := FailureCascadeResult.new()
	r.failure_type = p_type
	match p_type:
		FailureCascadeResult.FailureType.ORGAN:
			r.failed_organs = ["vordex"]
		FailureCascadeResult.FailureType.STRUCTURAL:
			r.structural_code = "CASCADE_TOTAL"
		_:
			pass
	return r


# ---------------------------------------------------------------------------
# T14 tests
# ---------------------------------------------------------------------------

func test_run_sequence_vfx_handle_play_none_emits_vfx_complete() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.NONE)
	watch_signals(_vfx)

	# Act
	_vfx.handle_play(result)
	_vfx.notify_vfx_complete()

	# Assert
	assert_signal_emitted(_vfx, "vfx_complete")


func test_run_sequence_vfx_handle_play_organ_emits_vfx_complete() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.ORGAN)
	watch_signals(_vfx)

	# Act
	_vfx.handle_play(result)
	_vfx.notify_vfx_complete()

	# Assert
	assert_signal_emitted(_vfx, "vfx_complete")


func test_run_sequence_vfx_handle_play_structural_emits_vfx_complete() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.STRUCTURAL)
	watch_signals(_vfx)

	# Act
	_vfx.handle_play(result)
	_vfx.notify_vfx_complete()

	# Assert
	assert_signal_emitted(_vfx, "vfx_complete")


func test_run_sequence_vfx_second_handle_play_while_playing_is_ignored() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.NONE)
	watch_signals(_vfx)

	# Act — first call puts VFX in PLAYING; second must be swallowed
	_vfx.handle_play(result)
	_vfx.handle_play(result)
	_vfx.notify_vfx_complete()

	# Assert — vfx_complete fires exactly once
	assert_signal_emit_count(_vfx, "vfx_complete", 1)


func test_run_sequence_vfx_notify_vfx_complete_returns_to_idle() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.NONE)
	_vfx.handle_play(result)

	# Act
	_vfx.notify_vfx_complete()

	# Assert — state is back to IDLE; a new handle_play should work
	watch_signals(_vfx)
	_vfx.handle_play(result)
	_vfx.notify_vfx_complete()
	assert_signal_emitted(_vfx, "vfx_complete")


func test_run_sequence_vfx_text_label_visible_after_handle_play() -> void:
	# Arrange
	_vfx = _make_vfx()
	var result := _make_result(FailureCascadeResult.FailureType.ORGAN)

	# Act
	_vfx.handle_play(result)

	# Assert — text label should be visible during animation
	assert_true(_vfx._text_label.visible)
