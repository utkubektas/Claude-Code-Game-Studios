extends GutTest

## T01 — Organ Type Registry test suite
## Gereksinim: GUT eklentisi addons/gut/ altında kurulu olmalı.
## Çalıştırma: gut -gtest=tests/unit/test_organ_type_registry.gd

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_organ(
	p_id: String,
	p_name: String,
	p_role: OrganTypeResource.Role,
	p_channels: Array[String],
	p_rule: String = "rule_test",
	p_creatures: Array[String] = ["xenith_01"]
) -> OrganTypeResource:
	var o := OrganTypeResource.new()
	o.organ_id = p_id
	o.display_name = p_name
	o.role = p_role
	o.output_channels = p_channels
	o.biology_rule_id = p_rule
	o.creature_type_ids = p_creatures
	return o


func _make_full_registry() -> OrganTypeRegistry:
	var r := OrganTypeRegistry.new()
	r.organs = [
		_make_organ("vordex",   "Vordex Emitter",   OrganTypeResource.Role.EMITTER,  ["PULSE"]),
		_make_organ("valdris",  "Valdris Gate",     OrganTypeResource.Role.GATE,     ["PULSE", "FLUID"]),
		_make_organ("thrennic", "Thrennic Splitter",OrganTypeResource.Role.SPLITTER, ["PULSE", "FLUID"]),
		_make_organ("ossuric",  "Ossuric Terminus", OrganTypeResource.Role.TERMINUS, []),
	]
	return r


# ---------------------------------------------------------------------------
# get_organ
# ---------------------------------------------------------------------------

func test_get_organ_vordex_returns_correct_resource() -> void:
	var registry := _make_full_registry()
	var organ := registry.get_organ("vordex")
	assert_not_null(organ)
	assert_eq(organ.organ_id, "vordex")


func test_get_organ_vordex_role_is_emitter() -> void:
	var registry := _make_full_registry()
	var organ := registry.get_organ("vordex")
	assert_eq(organ.role, OrganTypeResource.Role.EMITTER)


func test_get_organ_valdris_role_is_gate() -> void:
	var registry := _make_full_registry()
	assert_eq(registry.get_organ("valdris").role, OrganTypeResource.Role.GATE)


func test_get_organ_thrennic_role_is_splitter() -> void:
	var registry := _make_full_registry()
	assert_eq(registry.get_organ("thrennic").role, OrganTypeResource.Role.SPLITTER)


func test_get_organ_ossuric_role_is_terminus() -> void:
	var registry := _make_full_registry()
	assert_eq(registry.get_organ("ossuric").role, OrganTypeResource.Role.TERMINUS)


func test_get_organ_unknown_id_returns_null() -> void:
	var registry := _make_full_registry()
	var result := registry.get_organ("does_not_exist")
	assert_null(result)


func test_get_organ_empty_string_returns_null() -> void:
	var registry := _make_full_registry()
	assert_null(registry.get_organ(""))


# ---------------------------------------------------------------------------
# get_all_organs
# ---------------------------------------------------------------------------

func test_get_all_organs_returns_four_organs() -> void:
	var registry := _make_full_registry()
	assert_eq(registry.get_all_organs().size(), 4)


func test_get_all_organs_contains_all_four_ids() -> void:
	var registry := _make_full_registry()
	var ids: Array[String] = []
	for organ: OrganTypeResource in registry.get_all_organs():
		ids.append(organ.organ_id)
	assert_has(ids, "vordex")
	assert_has(ids, "valdris")
	assert_has(ids, "thrennic")
	assert_has(ids, "ossuric")


# ---------------------------------------------------------------------------
# valid_registry
# ---------------------------------------------------------------------------

func test_valid_registry_passes_with_full_data() -> void:
	var registry := _make_full_registry()
	assert_true(registry.valid_registry())


func test_valid_registry_fails_on_empty_organ_id() -> void:
	var registry := OrganTypeRegistry.new()
	var bad := _make_organ("", "Bad Organ", OrganTypeResource.Role.EMITTER, ["PULSE"])
	registry.organs = [bad]
	assert_false(registry.valid_registry())


func test_valid_registry_fails_on_duplicate_id() -> void:
	var registry := OrganTypeRegistry.new()
	var a := _make_organ("vordex", "Vordex A", OrganTypeResource.Role.EMITTER, ["PULSE"])
	var b := _make_organ("vordex", "Vordex B", OrganTypeResource.Role.GATE,    ["PULSE"])
	registry.organs = [a, b]
	assert_false(registry.valid_registry())


func test_valid_registry_fails_on_empty_biology_rule_id() -> void:
	var registry := OrganTypeRegistry.new()
	var bad := _make_organ("vordex", "Vordex", OrganTypeResource.Role.EMITTER, ["PULSE"], "")
	registry.organs = [bad]
	assert_false(registry.valid_registry())


func test_valid_registry_fails_on_empty_creature_type_ids() -> void:
	var registry := OrganTypeRegistry.new()
	var bad := _make_organ("vordex", "Vordex", OrganTypeResource.Role.EMITTER, ["PULSE"], "rule_test", [])
	registry.organs = [bad]
	assert_false(registry.valid_registry())


# ---------------------------------------------------------------------------
# index rebuild (lazy)
# ---------------------------------------------------------------------------

func test_index_rebuilt_after_organs_replaced() -> void:
	var registry := _make_full_registry()
	var _first := registry.get_organ("vordex")  # triggers index build

	# Yeni bir registry ile organs array'ini değiştiriyoruz
	var new_registry := OrganTypeRegistry.new()
	new_registry.organs = [
		_make_organ("custom_a", "Custom A", OrganTypeResource.Role.EMITTER, ["PULSE"]),
	]
	assert_not_null(new_registry.get_organ("custom_a"))
	assert_null(new_registry.get_organ("vordex"))


# ---------------------------------------------------------------------------
# ossuric output_channels
# ---------------------------------------------------------------------------

func test_ossuric_has_no_output_channels() -> void:
	var registry := _make_full_registry()
	var ossuric := registry.get_organ("ossuric")
	assert_eq(ossuric.output_channels.size(), 0)


func test_vordex_output_is_pulse_only() -> void:
	var registry := _make_full_registry()
	var vordex := registry.get_organ("vordex")
	assert_eq(vordex.output_channels, ["PULSE"])
