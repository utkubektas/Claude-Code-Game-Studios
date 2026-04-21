extends GutTest

## T13 — PuzzleHUD acceptance criteria

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _hud: PuzzleHUD

func before_each() -> void:
	_hud = null


func after_each() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null


func _make_organ(p_id: String) -> OrganTypeResource:
	var o := OrganTypeResource.new()
	o.organ_id = p_id
	o.display_name = p_id.capitalize()
	o.role = OrganTypeResource.Role.EMITTER
	o.output_channels = ["PULSE"]
	o.biology_rule_id = "rule_test"
	o.creature_type_ids = ["xenith_01"]
	return o


func _make_registry() -> OrganTypeRegistry:
	var r := OrganTypeRegistry.new()
	r.organs = [
		_make_organ("vordex"),
		_make_organ("valdris"),
		_make_organ("thrennic"),
		_make_organ("ossuric"),
	]
	return r


func _make_puzzle_resource() -> PuzzleResource:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Test Puzzle"
	pr.creature_type_id = "xenith_01"
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.starting_configuration = config
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	return pr


func _make_puzzle_instance() -> PuzzleInstance:
	var pr := _make_puzzle_resource()
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, _make_registry())
	return inst


## Creates a fully wired PuzzleHUD with setup() and load_puzzle() already called.
func _make_hud() -> PuzzleHUD:
	var registry := _make_registry()
	var handler := TouchInputHandler.new()
	add_child(handler)
	var inst := _make_puzzle_instance()
	var hud := PuzzleHUD.new()
	hud.setup(registry, handler, inst)
	add_child(hud)
	hud.load_puzzle(_make_puzzle_resource())
	return hud


# ---------------------------------------------------------------------------
# T13 tests
# ---------------------------------------------------------------------------

func test_puzzle_hud_setup_registers_inventory_touch_areas() -> void:
	# Arrange
	var registry := _make_registry()
	var handler := TouchInputHandler.new()
	add_child(handler)
	var inst := _make_puzzle_instance()
	_hud = PuzzleHUD.new()

	# Act
	_hud.setup(registry, handler, inst)
	add_child(_hud)

	# Assert
	assert_true(handler._areas.has("inv_vordex"))
	assert_true(handler._areas.has("inv_valdris"))
	assert_true(handler._areas.has("inv_thrennic"))
	assert_true(handler._areas.has("inv_ossuric"))


func test_puzzle_hud_setup_registers_run_button_touch_area() -> void:
	# Arrange
	var registry := _make_registry()
	var handler := TouchInputHandler.new()
	add_child(handler)
	var inst := _make_puzzle_instance()
	_hud = PuzzleHUD.new()

	# Act
	_hud.setup(registry, handler, inst)
	add_child(_hud)

	# Assert
	assert_true(handler._areas.has("run_btn"))


func test_puzzle_hud_load_puzzle_updates_title() -> void:
	# Arrange
	_hud = _make_hud()
	var pr := _make_puzzle_resource()

	# Act
	_hud.load_puzzle(pr)

	# Assert
	assert_true(_hud._title_label.text.contains("Test Puzzle"))


func test_puzzle_hud_lock_sets_locked_state() -> void:
	# Arrange
	_hud = _make_hud()

	# Act
	_hud.lock()

	# Assert
	assert_eq(_hud._state, PuzzleHUD.State.LOCKED)


func test_puzzle_hud_unlock_sets_active_state() -> void:
	# Arrange
	_hud = _make_hud()
	_hud.lock()

	# Act
	_hud.unlock()

	# Assert
	assert_eq(_hud._state, PuzzleHUD.State.ACTIVE)


func test_puzzle_hud_show_result_success_shows_message() -> void:
	# Arrange
	_hud = _make_hud()

	# Act
	_hud.show_result(true)

	# Assert
	assert_true(_hud._result_label.visible)
	assert_true(_hud._result_label.text.contains("repaired"))


func test_puzzle_hud_show_result_failure_shows_message() -> void:
	# Arrange
	_hud = _make_hud()

	# Act
	_hud.show_result(false)

	# Assert
	assert_true(_hud._result_label.visible)
	assert_true(_hud._result_label.text.contains("failure"))


func test_puzzle_hud_update_attempts_reflects_count() -> void:
	# Arrange
	_hud = _make_hud()
	_hud._puzzle_instance.increment_attempts()

	# Act
	_hud.update_attempts()

	# Assert
	assert_true(_hud._attempt_label.text.contains("1"))
