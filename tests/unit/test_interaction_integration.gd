extends GutTest

## T11 — Interaction Integration Tests
## Sprint 02 tam sinyal zincirini doğrular:
## TouchInputHandler → OrganRepairMechanic + RunSimulationController

# ---------------------------------------------------------------------------
# VFX stub — anında vfx_complete emit eder
# ---------------------------------------------------------------------------

class _VFXStub extends Node:
	signal vfx_complete
	func handle_play(_result: FailureCascadeResult) -> void:
		vfx_complete.emit()


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


func _make_puzzle_instance(p_start: Array[String]) -> PuzzleInstance:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Integration Test Puzzle"
	pr.creature_type_id = "xenith_01"
	pr.starting_configuration = p_start
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	var inst := PuzzleInstance.new()
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	inst.setup(pr, healthy, _make_registry())
	return inst


## Tüm Sprint 02 sistemlerini oluşturup birbirine bağlar.
## Döndürülen sözlük: { handler, mechanic, controller, inst, stub }
##
## Touch area haritası (test koordinatları):
##   slot_0   Rect2(0, 0, 80, 80)        → merkez (40, 40)
##   slot_1   Rect2(100, 0, 80, 80)      → merkez (140, 40)
##   slot_2   Rect2(200, 0, 80, 80)      → merkez (240, 40)
##   slot_3   Rect2(300, 0, 80, 80)      → merkez (340, 40)
##   inv_vordex   Rect2(0, 200, 80, 80)  → merkez (40, 240)
##   inv_valdris  Rect2(100, 200, 80, 80)→ merkez (140, 240)
##   inv_thrennic Rect2(200, 200, 80, 80)→ merkez (240, 240)
##   inv_ossuric  Rect2(300, 200, 80, 80)→ merkez (340, 240)
##   run      Rect2(150, 400, 100, 80)   → merkez (200, 440)
func _make_wired_system(p_start: Array[String]) -> Dictionary:
	var creature := _make_creature()
	var registry := _make_registry()
	var inst := _make_puzzle_instance(p_start)

	var handler := TouchInputHandler.new()
	add_child(handler)

	var mechanic := OrganRepairMechanic.new()
	mechanic.setup(inst)
	add_child(mechanic)

	var stub := _VFXStub.new()
	add_child(stub)

	var controller := RunSimulationController.new()
	add_child(controller)
	controller.setup(inst, creature, registry)
	controller.connect_vfx(stub)

	# Controller → Mechanic sinyal köprüleri
	controller.locked.connect(mechanic.lock)
	controller.unlocked.connect(mechanic.unlock)
	controller.attempt_completed.connect(mechanic.on_attempt_completed)

	# Input bağlantıları
	mechanic.connect_input(handler)
	controller.connect_input(handler)

	# Touch alanları
	handler.register_area("slot_0",      Rect2(0,   0,   80, 80), TouchInputHandler.TouchAreaType.SLOT,      0)
	handler.register_area("slot_1",      Rect2(100, 0,   80, 80), TouchInputHandler.TouchAreaType.SLOT,      1)
	handler.register_area("slot_2",      Rect2(200, 0,   80, 80), TouchInputHandler.TouchAreaType.SLOT,      2)
	handler.register_area("slot_3",      Rect2(300, 0,   80, 80), TouchInputHandler.TouchAreaType.SLOT,      3)
	handler.register_area("inv_vordex",  Rect2(0,   200, 80, 80), TouchInputHandler.TouchAreaType.INVENTORY, "vordex")
	handler.register_area("inv_valdris", Rect2(100, 200, 80, 80), TouchInputHandler.TouchAreaType.INVENTORY, "valdris")
	handler.register_area("inv_thrennic",Rect2(200, 200, 80, 80), TouchInputHandler.TouchAreaType.INVENTORY, "thrennic")
	handler.register_area("inv_ossuric", Rect2(300, 200, 80, 80), TouchInputHandler.TouchAreaType.INVENTORY, "ossuric")
	handler.register_area("run",         Rect2(150, 400, 100,80), TouchInputHandler.TouchAreaType.RUN_BUTTON, null)

	return { "handler": handler, "mechanic": mechanic, "controller": controller, "inst": inst, "stub": stub }


## Senkron tap simülasyonu (press + release aynı tick'te → 0ms süre, 0px delta).
func _tap(p_handler: TouchInputHandler, p_pos: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.position = p_pos
	press.pressed = true
	p_handler._process_touch_event(press)

	var release := InputEventScreenTouch.new()
	release.position = p_pos
	release.pressed = false
	p_handler._process_touch_event(release)


# ---------------------------------------------------------------------------
# T11 tests
# ---------------------------------------------------------------------------

func test_interaction_slot_tap_selects_slot_via_handler() -> void:
	# Arrange
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var mechanic: OrganRepairMechanic = sys.mechanic
	var handler: TouchInputHandler = sys.handler
	watch_signals(mechanic)

	# Act — slot_0 merkezi (40, 40)
	_tap(handler, Vector2(40, 40))

	# Assert
	assert_signal_emitted_with_parameters(mechanic, "slot_selected", [0])


func test_interaction_full_chain_slot_to_organ_place() -> void:
	# Arrange — slot 0 yanlış (ossuric); vordex yerleştir
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var inst: PuzzleInstance = sys.inst
	var handler: TouchInputHandler = sys.handler
	var mechanic: OrganRepairMechanic = sys.mechanic
	watch_signals(mechanic)

	# Act — slot_0 seç, sonra inv_vordex tap
	_tap(handler, Vector2(40, 40))    # slot_0
	_tap(handler, Vector2(40, 240))   # inv_vordex

	# Assert
	assert_eq(inst.current_configuration[0], "vordex")
	assert_signal_emitted_with_parameters(mechanic, "organ_placed", [0, "vordex"])


func test_interaction_run_tapped_produces_cascade_result() -> void:
	# Arrange — yanlış config → NONE olmayan bir cascade bekleniyor
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var controller: RunSimulationController = sys.controller
	var handler: TouchInputHandler = sys.handler
	watch_signals(controller)

	# Act — run button (200, 440)
	_tap(handler, Vector2(200, 440))

	# Assert
	assert_signal_emitted(controller, "vfx_play_requested")
	var params: Array = get_signal_parameters(controller, "vfx_play_requested")
	var result: FailureCascadeResult = params[0]
	assert_ne(result.failure_type, FailureCascadeResult.FailureType.NONE)


func test_interaction_run_increments_attempt_and_emits_unlocked() -> void:
	# Arrange
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var inst: PuzzleInstance = sys.inst
	var handler: TouchInputHandler = sys.handler
	var controller: RunSimulationController = sys.controller
	watch_signals(controller)

	# Act — VFX stub vfx_complete'i anında emit eder
	_tap(handler, Vector2(200, 440))

	# Assert
	assert_eq(inst.attempt_count, 1)
	assert_signal_emitted(controller, "attempt_completed")
	assert_signal_emitted(controller, "unlocked")


func test_interaction_ossuric_locked_before_first_run() -> void:
	# Arrange — slot_1 (başlangıç: "valdris"); ossuric yerleştirmeye çalış
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var inst: PuzzleInstance = sys.inst
	var handler: TouchInputHandler = sys.handler
	var mechanic: OrganRepairMechanic = sys.mechanic

	_tap(handler, Vector2(140, 40))    # slot_1 seç
	watch_signals(mechanic)
	_tap(handler, Vector2(340, 240))   # inv_ossuric — reddedilmeli

	# Assert — placement yok; config[1] değişmedi
	assert_signal_not_emitted(mechanic, "organ_placed")
	assert_eq(inst.current_configuration[1], "valdris")


func test_interaction_ossuric_unlocked_after_first_run() -> void:
	# Arrange — bir RUN yap (ossuric kilidi açılır), sonra ossuric yerleştir
	var sys := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var inst: PuzzleInstance = sys.inst
	var handler: TouchInputHandler = sys.handler
	var mechanic: OrganRepairMechanic = sys.mechanic

	# RUN → attempt_completed → on_attempt_completed → ossuric kilidi kalkar
	_tap(handler, Vector2(200, 440))

	# slot_1 seç, ossuric yerleştir
	_tap(handler, Vector2(140, 40))    # slot_1
	watch_signals(mechanic)
	_tap(handler, Vector2(340, 240))   # inv_ossuric — artık izinli

	# Assert
	assert_signal_emitted_with_parameters(mechanic, "organ_placed", [1, "ossuric"])
	assert_eq(inst.current_configuration[1], "ossuric")


func test_interaction_second_run_during_animation_is_ignored() -> void:
	# Arrange — VFX stub YOK; controller ANIMATING'de kalır
	var creature := _make_creature()
	var registry := _make_registry()
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var inst := _make_puzzle_instance(start)

	var handler := TouchInputHandler.new()
	add_child(handler)
	var controller := RunSimulationController.new()
	add_child(controller)
	controller.setup(inst, creature, registry)
	controller.connect_input(handler)
	handler.register_area("run", Rect2(0, 0, 80, 80), TouchInputHandler.TouchAreaType.RUN_BUTTON, null)

	# İlk RUN → ANIMATING
	_tap(handler, Vector2(40, 40))
	assert_eq(controller._state, RunSimulationController._State.ANIMATING)

	# İkinci RUN — yutulmalı
	_tap(handler, Vector2(40, 40))

	# Assert — attempt_count hâlâ 1
	assert_eq(inst.attempt_count, 1)


func test_interaction_correct_config_emits_puzzle_solved() -> void:
	# Arrange — başlangıç konfigürasyonu zaten doğru
	var sys := _make_wired_system(["vordex", "valdris", "thrennic", "ossuric"])
	var controller: RunSimulationController = sys.controller
	var handler: TouchInputHandler = sys.handler
	watch_signals(controller)

	# Act
	_tap(handler, Vector2(200, 440))

	# Assert
	assert_signal_emitted(controller, "puzzle_solved")


func test_interaction_full_chain_is_deterministic() -> void:
	# Arrange — aynı konfigürasyonla iki bağımsız sistem
	var sys1 := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var ctrl1: RunSimulationController = sys1.controller
	var handler1: TouchInputHandler = sys1.handler
	watch_signals(ctrl1)
	_tap(handler1, Vector2(200, 440))
	var params1: Array = get_signal_parameters(ctrl1, "vfx_play_requested")

	var sys2 := _make_wired_system(["ossuric", "valdris", "thrennic", "ossuric"])
	var ctrl2: RunSimulationController = sys2.controller
	var handler2: TouchInputHandler = sys2.handler
	watch_signals(ctrl2)
	_tap(handler2, Vector2(200, 440))
	var params2: Array = get_signal_parameters(ctrl2, "vfx_play_requested")

	# Assert — aynı girdi → aynı cascade türü
	var result1: FailureCascadeResult = params1[0]
	var result2: FailureCascadeResult = params2[0]
	assert_eq(result1.failure_type, result2.failure_type)
