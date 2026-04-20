extends GutTest

## T02 — Creature Definition System test suite

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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


func _make_channel(p_from: int, p_to: int, p_flow: OrganTypeResource.FlowType) -> SlotChannel:
	var c := SlotChannel.new()
	c.from_slot_index = p_from
	c.to_slot_index = p_to
	c.flow_type = p_flow
	return c


func _make_xenith() -> CreatureTypeResource:
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
	c.slot_channels = [
		_make_channel(0, 1, OrganTypeResource.FlowType.PULSE),
		_make_channel(1, 2, OrganTypeResource.FlowType.PULSE),
		_make_channel(0, 2, OrganTypeResource.FlowType.FLUID),
		_make_channel(2, 3, OrganTypeResource.FlowType.FLUID),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_system() -> CreatureDefinitionSystem:
	var s := CreatureDefinitionSystem.new()
	s.creatures = [_make_xenith()]
	return s


# ---------------------------------------------------------------------------
# get_creature
# ---------------------------------------------------------------------------

func test_get_creature_returns_xenith() -> void:
	var sys := _make_system()
	var c := sys.get_creature("xenith_01")
	assert_not_null(c)
	assert_eq(c.creature_id, "xenith_01")


func test_get_creature_unknown_id_returns_null() -> void:
	var sys := _make_system()
	assert_null(sys.get_creature("does_not_exist"))


func test_get_creature_empty_string_returns_null() -> void:
	var sys := _make_system()
	assert_null(sys.get_creature(""))


# ---------------------------------------------------------------------------
# healthy_configuration
# ---------------------------------------------------------------------------

func test_healthy_configuration_has_four_entries() -> void:
	var c := _make_xenith()
	assert_eq(c.healthy_configuration.size(), 4)


func test_healthy_configuration_slot0_is_vordex() -> void:
	var c := _make_xenith()
	assert_eq(c.healthy_configuration[0], "vordex")


func test_healthy_configuration_slot3_is_ossuric() -> void:
	var c := _make_xenith()
	assert_eq(c.healthy_configuration[3], "ossuric")


func test_get_healthy_configuration_returns_array() -> void:
	var c := _make_xenith()
	var cfg := c.get_healthy_configuration()
	assert_eq(cfg.size(), 4)


# ---------------------------------------------------------------------------
# valid_creatures — without registry
# ---------------------------------------------------------------------------

func test_valid_creatures_passes_with_full_data() -> void:
	var sys := _make_system()
	assert_true(sys.valid_creatures())


func test_valid_creatures_fails_on_empty_creature_id() -> void:
	var sys := CreatureDefinitionSystem.new()
	var bad := _make_xenith()
	bad.creature_id = ""
	sys.creatures = [bad]
	assert_false(sys.valid_creatures())


func test_valid_creatures_fails_when_healthy_config_wrong_size() -> void:
	var sys := CreatureDefinitionSystem.new()
	var bad := _make_xenith()
	bad.healthy_configuration = ["vordex", "valdris"]  # only 2, should be 4
	sys.creatures = [bad]
	assert_false(sys.valid_creatures())


func test_valid_creatures_fails_on_self_loop_channel() -> void:
	var sys := CreatureDefinitionSystem.new()
	var bad := _make_xenith()
	var loop_channel := _make_channel(2, 2, OrganTypeResource.FlowType.PULSE)
	bad.slot_channels.append(loop_channel)
	sys.creatures = [bad]
	assert_false(sys.valid_creatures())


func test_valid_creatures_fails_on_duplicate_id() -> void:
	var sys := CreatureDefinitionSystem.new()
	var a := _make_xenith()
	var b := _make_xenith()
	sys.creatures = [a, b]
	assert_false(sys.valid_creatures())


# ---------------------------------------------------------------------------
# valid_creatures — with registry
# ---------------------------------------------------------------------------

func test_valid_creatures_with_registry_passes() -> void:
	var sys := _make_system()
	var registry := _make_registry()
	assert_true(sys.valid_creatures(registry))


func test_valid_creatures_with_registry_fails_on_unknown_organ_id() -> void:
	var sys := CreatureDefinitionSystem.new()
	var bad := _make_xenith()
	bad.healthy_configuration = ["vordex", "valdris", "thrennic", "UNKNOWN_ORGAN"]
	sys.creatures = [bad]
	var registry := _make_registry()
	assert_false(sys.valid_creatures(registry))


# ---------------------------------------------------------------------------
# OrganSlotDefinition
# ---------------------------------------------------------------------------

func test_slot_accepts_all_when_accepted_list_is_empty() -> void:
	var slot := _make_slot(0, Vector2.ZERO)
	assert_true(slot.accepts_organ("vordex"))
	assert_true(slot.accepts_organ("anything"))


func test_slot_rejects_unlisted_organ_when_list_is_set() -> void:
	var slot := _make_slot(0, Vector2.ZERO)
	slot.accepted_organ_type_ids = ["vordex"]
	assert_true(slot.accepts_organ("vordex"))
	assert_false(slot.accepts_organ("valdris"))


# ---------------------------------------------------------------------------
# SlotChannel
# ---------------------------------------------------------------------------

func test_channel_is_invalid_when_from_equals_to() -> void:
	var c := _make_channel(1, 1, OrganTypeResource.FlowType.PULSE)
	assert_false(c.is_valid())


func test_channel_is_valid_when_from_differs_from_to() -> void:
	var c := _make_channel(0, 3, OrganTypeResource.FlowType.FLUID)
	assert_true(c.is_valid())


# ---------------------------------------------------------------------------
# get_slot_count
# ---------------------------------------------------------------------------

func test_xenith_has_four_slots() -> void:
	var c := _make_xenith()
	assert_eq(c.get_slot_count(), 4)
