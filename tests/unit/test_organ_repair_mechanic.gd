extends GutTest

## T08 — OrganRepairMechanic acceptance criteria

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _mechanic: OrganRepairMechanic

func before_each() -> void:
	_mechanic = OrganRepairMechanic.new()
	_mechanic.setup(_make_puzzle_instance())
	add_child(_mechanic)


func after_each() -> void:
	_mechanic.queue_free()
	_mechanic = null


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


func _make_slot(p_index: int, p_pos: Vector2) -> OrganSlotDefinition:
	var s := OrganSlotDefinition.new()
	s.slot_index = p_index
	s.world_position = p_pos
	return s


func _make_creature() -> CreatureTypeResource:
	var c := CreatureTypeResource.new()
	c.creature_id = "xenith_01"
	c.display_name = "Xenith"
	c.lore_hint = "Test creature."
	c.organ_slots = [
		_make_slot(0, Vector2(-80, -70)),
		_make_slot(1, Vector2(80, -70)),
		_make_slot(2, Vector2(-80, 70)),
		_make_slot(3, Vector2(0, 90)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


## Creates a PuzzleInstance with starting_config ["ossuric", "valdris", "thrennic", "ossuric"]
## (slot 0 is wrong — one difference from healthy). attempt_count starts at 0.
func _make_puzzle_instance() -> PuzzleInstance:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Specimen 01-A"
	pr.creature_type_id = "xenith_01"
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.starting_configuration = config
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0

	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, _make_registry())
	return inst


## Creates an OrganRepairMechanic already set up with a fresh PuzzleInstance.
func _make_mechanic() -> OrganRepairMechanic:
	var m := OrganRepairMechanic.new()
	m.setup(_make_puzzle_instance())
	return m


# ---------------------------------------------------------------------------
# Slot selection tests
# ---------------------------------------------------------------------------

func test_organ_repair_mechanic_slot_tapped_emits_slot_selected() -> void:
	# Arrange
	watch_signals(_mechanic)

	# Act
	_mechanic._on_slot_tapped(0)

	# Assert
	assert_signal_emitted_with_parameters(_mechanic, "slot_selected", [0])


func test_organ_repair_mechanic_same_slot_tapped_twice_emits_slot_deselected() -> void:
	# Arrange
	_mechanic._on_slot_tapped(0)
	watch_signals(_mechanic)

	# Act
	_mechanic._on_slot_tapped(0)

	# Assert
	assert_signal_emitted_with_parameters(_mechanic, "slot_deselected", [0])


func test_organ_repair_mechanic_different_slot_tapped_changes_selection() -> void:
	# Arrange
	_mechanic._on_slot_tapped(0)
	watch_signals(_mechanic)

	# Act
	_mechanic._on_slot_tapped(1)

	# Assert — old slot deselected, new slot selected
	assert_signal_emitted_with_parameters(_mechanic, "slot_deselected", [0])
	assert_signal_emitted_with_parameters(_mechanic, "slot_selected", [1])


# ---------------------------------------------------------------------------
# Organ placement tests
# ---------------------------------------------------------------------------

func test_organ_repair_mechanic_inventory_tapped_with_slot_selected_places_organ() -> void:
	# Arrange
	_mechanic._on_slot_tapped(1)

	# Act
	_mechanic._on_inventory_tapped("valdris")

	# Assert
	assert_eq(_mechanic._puzzle_instance.current_configuration[1], "valdris")


func test_organ_repair_mechanic_inventory_tapped_without_slot_selected_is_ignored() -> void:
	# Arrange — no slot selected; _selected_slot is -1
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("valdris")

	# Assert
	assert_signal_not_emitted(_mechanic, "organ_placed")


func test_organ_repair_mechanic_organ_placed_signal_emitted_with_correct_params() -> void:
	# Arrange
	_mechanic._on_slot_tapped(2)
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("thrennic")

	# Assert
	assert_signal_emitted_with_parameters(_mechanic, "organ_placed", [2, "thrennic"])


func test_organ_repair_mechanic_slot_deselected_emitted_after_organ_placed() -> void:
	# Arrange
	_mechanic._on_slot_tapped(0)
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("vordex")

	# Assert — slot_deselected must accompany the organ_placed
	assert_signal_emitted_with_parameters(_mechanic, "slot_deselected", [0])


# ---------------------------------------------------------------------------
# LOCKED state tests
# ---------------------------------------------------------------------------

func test_organ_repair_mechanic_lock_prevents_slot_tapped() -> void:
	# Arrange
	_mechanic.lock()
	watch_signals(_mechanic)

	# Act
	_mechanic._on_slot_tapped(0)

	# Assert
	assert_signal_not_emitted(_mechanic, "slot_selected")


func test_organ_repair_mechanic_lock_prevents_inventory_tapped() -> void:
	# Arrange
	_mechanic._on_slot_tapped(0)
	_mechanic.lock()
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("valdris")

	# Assert
	assert_signal_not_emitted(_mechanic, "organ_placed")


func test_organ_repair_mechanic_unlock_restores_slot_tapped() -> void:
	# Arrange
	_mechanic.lock()
	_mechanic.unlock()
	watch_signals(_mechanic)

	# Act
	_mechanic._on_slot_tapped(0)

	# Assert
	assert_signal_emitted_with_parameters(_mechanic, "slot_selected", [0])


# ---------------------------------------------------------------------------
# LOCKED_PRE_ATT / ossuric guard tests
# ---------------------------------------------------------------------------

func test_organ_repair_mechanic_ossuric_locked_before_first_attempt() -> void:
	# Arrange — fresh mechanic, attempt_count == 0 → _ossuric_locked == true
	_mechanic._on_slot_tapped(0)
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("ossuric")

	# Assert — silently ignored; no organ_placed signal
	assert_signal_not_emitted(_mechanic, "organ_placed")


func test_organ_repair_mechanic_ossuric_unlocked_after_on_attempt_completed() -> void:
	# Arrange
	_mechanic._on_slot_tapped(0)
	_mechanic.on_attempt_completed()
	watch_signals(_mechanic)

	# Act
	_mechanic._on_inventory_tapped("ossuric")

	# Assert — ossuric is now allowed
	assert_signal_emitted_with_parameters(_mechanic, "organ_placed", [0, "ossuric"])


func test_organ_repair_mechanic_ossuric_open_when_attempt_count_already_1() -> void:
	# Arrange — simulate a puzzle that was already attempted once before setup
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Specimen 01-A"
	pr.creature_type_id = "xenith_01"
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.starting_configuration = config
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0

	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, _make_registry())
	inst.increment_attempts()  # attempt_count == 1

	var m := OrganRepairMechanic.new()
	m.setup(inst)
	add_child(m)

	m._on_slot_tapped(0)
	watch_signals(m)

	# Act
	m._on_inventory_tapped("ossuric")

	# Assert — ossuric already unlocked because attempt_count >= 1 at setup
	assert_signal_emitted_with_parameters(m, "organ_placed", [0, "ossuric"])

	m.queue_free()
