extends GutTest

## T07 — TouchInputHandler acceptance criteria

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _handler: TouchInputHandler

func before_each() -> void:
	_handler = TouchInputHandler.new()
	add_child(_handler)


func after_each() -> void:
	_handler.queue_free()
	_handler = null


func _make_tap_event(p_pos: Vector2, p_pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.position = p_pos
	ev.pressed = p_pressed
	return ev


func _simulate_tap(p_pos: Vector2, p_duration_ms: int = 50, p_delta: Vector2 = Vector2.ZERO) -> void:
	_handler._process_touch_event(_make_tap_event(p_pos, true))
	# Zaman simülasyonu için touch_start_time'ı geri götürüyoruz
	_handler._touch_start_time = Time.get_ticks_msec() - p_duration_ms
	var release_pos := p_pos + p_delta
	_handler._process_touch_event(_make_tap_event(release_pos, false))


# ---------------------------------------------------------------------------
# register_area testleri
# ---------------------------------------------------------------------------

func test_touch_input_handler_register_area_records_slot_area() -> void:
	# Arrange
	var rect := Rect2(0, 0, 80, 80)

	# Act
	_handler.register_area("slot_0", rect, TouchInputHandler.TouchAreaType.SLOT, 0)

	# Assert
	assert_true(_handler._areas.has("slot_0"))


func test_touch_input_handler_register_area_overwrites_same_id() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)

	# Act — aynı id, farklı payload
	_handler.register_area("slot_0", Rect2(10, 10, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 99)

	# Assert
	assert_eq(_handler._areas["slot_0"].payload, 99)


func test_touch_input_handler_register_area_enforces_minimum_size() -> void:
	# Arrange — 40×40 → MIN altında (48×48)
	var small_rect := Rect2(0, 0, 40, 40)

	# Act
	_handler.register_area("tiny", small_rect, TouchInputHandler.TouchAreaType.SLOT, 0)

	# Assert — kaydedilen alan min boyuta büyütülmüş olmalı
	var stored: Rect2 = _handler._areas["tiny"].rect
	assert_gte(stored.size.x, TouchInputHandler.MIN_TOUCH_AREA)
	assert_gte(stored.size.y, TouchInputHandler.MIN_TOUCH_AREA)


func test_touch_input_handler_unregister_area_removes_area() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)

	# Act
	_handler.unregister_area("slot_0")

	# Assert
	assert_false(_handler._areas.has("slot_0"))


# ---------------------------------------------------------------------------
# Tap tanıma testleri
# ---------------------------------------------------------------------------

func test_touch_input_handler_slot_tap_emits_slot_tapped() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	watch_signals(_handler)

	# Act
	_simulate_tap(Vector2(40, 40))

	# Assert
	assert_signal_emitted_with_parameters(_handler, "slot_tapped", [0])


func test_touch_input_handler_inventory_tap_emits_inventory_tapped() -> void:
	# Arrange
	_handler.register_area("inv_vordex", Rect2(0, 100, 80, 80), TouchInputHandler.TouchAreaType.INVENTORY, "vordex")
	watch_signals(_handler)

	# Act
	_simulate_tap(Vector2(40, 140))

	# Assert
	assert_signal_emitted_with_parameters(_handler, "inventory_tapped", ["vordex"])


func test_touch_input_handler_run_button_tap_emits_run_tapped() -> void:
	# Arrange
	_handler.register_area("run", Rect2(100, 100, 80, 80), TouchInputHandler.TouchAreaType.RUN_BUTTON, null)
	watch_signals(_handler)

	# Act
	_simulate_tap(Vector2(140, 140))

	# Assert
	assert_signal_emitted(_handler, "run_tapped")


func test_touch_input_handler_tap_outside_area_emits_no_signal() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	watch_signals(_handler)

	# Act — (200, 200) alanın dışında
	_simulate_tap(Vector2(200, 200))

	# Assert
	assert_signal_not_emitted(_handler, "slot_tapped")


func test_touch_input_handler_long_press_is_not_a_tap() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	watch_signals(_handler)

	# Act — 300ms > TAP_MAX_DURATION_MS (200)
	_simulate_tap(Vector2(40, 40), 300)

	# Assert
	assert_signal_not_emitted(_handler, "slot_tapped")


func test_touch_input_handler_drag_is_not_a_tap() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	watch_signals(_handler)

	# Act — 15px > TAP_MAX_DELTA_PX (10)
	_simulate_tap(Vector2(40, 40), 50, Vector2(15, 0))

	# Assert
	assert_signal_not_emitted(_handler, "slot_tapped")


# ---------------------------------------------------------------------------
# LOCKED durum testleri
# ---------------------------------------------------------------------------

func test_touch_input_handler_locked_tap_emits_no_signal() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	_handler.lock_input()
	watch_signals(_handler)

	# Act
	_simulate_tap(Vector2(40, 40))

	# Assert
	assert_signal_not_emitted(_handler, "slot_tapped")


func test_touch_input_handler_unlock_restores_tap_handling() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	_handler.lock_input()
	_handler.unlock_input()
	watch_signals(_handler)

	# Act
	_simulate_tap(Vector2(40, 40))

	# Assert
	assert_signal_emitted(_handler, "slot_tapped")


# ---------------------------------------------------------------------------
# Z-index hit-test (RC-1 — GDD F2)
# ---------------------------------------------------------------------------

func test_touch_input_handler_overlapping_areas_higher_z_index_wins() -> void:
	# Arrange — iki alan çakışıyor; slot_1 daha yüksek z-index
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0, 0)
	_handler.register_area("slot_1", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 1, 10)
	watch_signals(_handler)

	# Act — çakışma noktasına tap
	_simulate_tap(Vector2(40, 40))

	# Assert — z_index=10 olan slot_1 kazanmalı
	assert_signal_emitted_with_parameters(_handler, "slot_tapped", [1])


# ---------------------------------------------------------------------------
# Multi-touch guard (RC-2)
# ---------------------------------------------------------------------------

func test_touch_input_handler_second_finger_tap_is_ignored() -> void:
	# Arrange
	_handler.register_area("slot_0", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.SLOT, 0)
	watch_signals(_handler)

	# Act — index=1 (ikinci parmak) press + release
	var press := InputEventScreenTouch.new()
	press.position = Vector2(40, 40)
	press.pressed = true
	press.index = 1
	_handler._process_touch_event(press)

	var release := InputEventScreenTouch.new()
	release.position = Vector2(40, 40)
	release.pressed = false
	release.index = 1
	_handler._process_touch_event(release)

	# Assert — ikinci parmak yutulmalı
	assert_signal_not_emitted(_handler, "slot_tapped")
