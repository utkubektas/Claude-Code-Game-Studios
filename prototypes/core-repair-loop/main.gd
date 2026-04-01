# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the inspect → replace → run loop satisfying as a core mechanic?
# Date: 2026-04-01
# Standards intentionally relaxed: hardcoded values, no error handling, no abstraction.

extends Node2D

# ---------------------------------------------------------------------------
# DATA
# ---------------------------------------------------------------------------

const SCREEN_W := 480
const SCREEN_H := 854

const ORGANS := {
	"vordex_emitter":    {"color": Color(0.20, 0.90, 0.50), "label": "Vordex\nEmitter",    "desc": "Signal source"},
	"thrennic_splitter": {"color": Color(0.70, 0.30, 0.90), "label": "Thrennic\nSplitter", "desc": "Splits signal ×2"},
	"valdris_gate":      {"color": Color(0.90, 0.55, 0.10), "label": "Valdris\nGate",      "desc": "Needs 2 inputs"},
	"ossuric_terminus":  {"color": Color(0.20, 0.55, 0.90), "label": "Ossuric\nTerminus",  "desc": "Signal sink"},
}

# Correct solution
const HEALTHY_CONFIG := {
	0: "vordex_emitter",
	1: "thrennic_splitter",
	2: "valdris_gate",
	3: "ossuric_terminus",
}

# Starting state: slot 2 has vordex_emitter (WRONG — should be valdris_gate)
var current_config := {
	0: "vordex_emitter",
	1: "thrennic_splitter",
	2: "vordex_emitter",
	3: "ossuric_terminus",
}

# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

var selected_slot  := -1
var is_animating   := false
var solve_count    := 0
var attempt_count  := 0

# UI node references
var slot_panels   : Array = []
var result_label  : Label
var status_label  : Label
var run_button    : Button

# ---------------------------------------------------------------------------
# BUILD UI
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_background()
	_build_header()
	_build_creature_slots()
	_build_connectors()
	_build_inventory()
	_build_run_button()
	_build_result_area()
	_refresh_slots()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.10)
	bg.size  = Vector2(SCREEN_W, SCREEN_H)
	add_child(bg)

func _build_header() -> void:
	var title := Label.new()
	title.text = "SPECIMEN"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.40, 0.95, 0.60))
	add_child(title)

	var sub := Label.new()
	sub.text = "Xenobiology Repair — Core Loop Prototype"
	sub.position = Vector2(20, 56)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	add_child(sub)

	status_label = Label.new()
	status_label.text = "Tap a slot to inspect it"
	status_label.position = Vector2(20, 80)
	status_label.size = Vector2(440, 30)
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80))
	add_child(status_label)

func _build_creature_slots() -> void:
	var slot_w := 200
	var slot_h := 80
	var start_x := (SCREEN_W - slot_w) / 2
	var start_y := 120
	var gap     := 100

	for i in range(4):
		var panel := _make_slot_panel(i, Vector2(slot_w, slot_h))
		panel.position = Vector2(start_x, start_y + i * gap)
		add_child(panel)
		slot_panels.append(panel)

func _build_connectors() -> void:
	for i in range(3):
		var line := ColorRect.new()
		line.color    = Color(0.25, 0.50, 0.30, 0.60)
		line.size     = Vector2(4, 20)
		line.position = Vector2(SCREEN_W / 2 - 2, 200 + i * 100)
		add_child(line)

func _build_inventory() -> void:
	var inv_title := Label.new()
	inv_title.text = "REPLACEMENT PARTS"
	inv_title.position = Vector2(20, 540)
	inv_title.add_theme_font_size_override("font_size", 13)
	inv_title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.80))
	add_child(inv_title)

	var keys := ORGANS.keys()
	for i in range(keys.size()):
		var organ_id : String = keys[i]
		var col := i % 2
		var row := i / 2
		var btn_panel := _make_inventory_panel(organ_id, Vector2(210, 72))
		btn_panel.position = Vector2(20 + col * 230, 565 + row * 82)
		add_child(btn_panel)

func _build_run_button() -> void:
	run_button = Button.new()
	run_button.text = "▶  RUN SIMULATION"
	run_button.size = Vector2(300, 54)
	run_button.position = Vector2((SCREEN_W - 300) / 2, 740)
	run_button.add_theme_font_size_override("font_size", 18)
	run_button.pressed.connect(_on_run_pressed)
	add_child(run_button)

func _build_result_area() -> void:
	result_label = Label.new()
	result_label.text = ""
	result_label.position = Vector2(20, 800)
	result_label.size = Vector2(440, 50)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	result_label.add_theme_font_size_override("font_size", 13)
	add_child(result_label)

# ---------------------------------------------------------------------------
# WIDGET FACTORIES
# ---------------------------------------------------------------------------

func _make_slot_panel(index: int, sz: Vector2) -> Panel:
	var panel := Panel.new()
	panel.size = sz
	panel.name = "Slot%d" % index

	# Color swatch
	var swatch := ColorRect.new()
	swatch.name     = "Swatch"
	swatch.size     = Vector2(18, sz.y - 20)
	swatch.position = Vector2(10, 10)
	panel.add_child(swatch)

	# Organ name
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.position = Vector2(36, 8)
	name_lbl.size = Vector2(sz.x - 46, 40)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(name_lbl)

	# Slot index + desc
	var desc_lbl := Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.position = Vector2(36, 50)
	desc_lbl.size = Vector2(sz.x - 46, 22)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	panel.add_child(desc_lbl)

	# Invisible button overlay for tap
	var btn := Button.new()
	btn.flat     = true
	btn.size     = sz
	btn.position = Vector2.ZERO
	btn.pressed.connect(_on_slot_pressed.bind(index))
	panel.add_child(btn)

	return panel

func _make_inventory_panel(organ_id: String, sz: Vector2) -> Panel:
	var panel := Panel.new()
	panel.size = sz
	panel.name = "Inv_" + organ_id

	var data := ORGANS[organ_id]

	var swatch := ColorRect.new()
	swatch.color    = data.color
	swatch.size     = Vector2(16, sz.y - 20)
	swatch.position = Vector2(8, 10)
	panel.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text     = data.label
	name_lbl.position = Vector2(32, 6)
	name_lbl.size     = Vector2(sz.x - 42, 40)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	panel.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text     = data.desc
	desc_lbl.position = Vector2(32, 50)
	desc_lbl.size     = Vector2(sz.x - 42, 20)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	panel.add_child(desc_lbl)

	var btn := Button.new()
	btn.flat     = true
	btn.size     = sz
	btn.position = Vector2.ZERO
	btn.pressed.connect(_on_inventory_pressed.bind(organ_id))
	panel.add_child(btn)

	return panel

# ---------------------------------------------------------------------------
# REFRESH
# ---------------------------------------------------------------------------

func _refresh_slots() -> void:
	for i in range(slot_panels.size()):
		var panel    := slot_panels[i] as Panel
		var organ_id : String = current_config[i]
		var data     := ORGANS[organ_id]
		var is_sel   := (selected_slot == i)

		panel.get_node("Swatch").color            = data.color
		panel.get_node("NameLabel").text           = data.label
		panel.get_node("NameLabel").add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		panel.get_node("DescLabel").text           = "Slot %d  •  %s" % [i, data.desc]

		var style := StyleBoxFlat.new()
		style.corner_radius_top_left     = 6
		style.corner_radius_top_right    = 6
		style.corner_radius_bottom_left  = 6
		style.corner_radius_bottom_right = 6

		if is_sel:
			style.bg_color       = Color(0.14, 0.14, 0.28)
			style.border_color   = Color(1.00, 0.95, 0.30)
			style.border_width_top    = 2
			style.border_width_bottom = 2
			style.border_width_left   = 2
			style.border_width_right  = 2
		else:
			style.bg_color       = Color(0.10, 0.10, 0.18)
			style.border_color   = Color(0.28, 0.28, 0.40)
			style.border_width_top    = 1
			style.border_width_bottom = 1
			style.border_width_left   = 1
			style.border_width_right  = 1

		panel.add_theme_stylebox_override("panel", style)

func _flash_slot(index: int, col: Color) -> void:
	var panel := slot_panels[index] as Panel
	var style := StyleBoxFlat.new()
	style.bg_color       = col.darkened(0.4)
	style.border_color   = col
	style.border_width_top    = 3
	style.border_width_bottom = 3
	style.border_width_left   = 3
	style.border_width_right  = 3
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

# ---------------------------------------------------------------------------
# INPUT HANDLERS
# ---------------------------------------------------------------------------

func _on_slot_pressed(index: int) -> void:
	if is_animating:
		return
	result_label.text = ""
	if selected_slot == index:
		selected_slot = -1
		status_label.text = "Tap a slot to inspect it"
	else:
		selected_slot = index
		var organ_id : String = current_config[index]
		status_label.text = "Slot %d selected: %s — pick a replacement below" % [index, ORGANS[organ_id].label.replace("\n", " ")]
	_refresh_slots()

func _on_inventory_pressed(organ_id: String) -> void:
	if is_animating:
		return
	if selected_slot < 0:
		result_label.text = "← Select a slot first"
		result_label.add_theme_color_override("font_color", Color(0.90, 0.75, 0.20))
		return

	var prev_organ : String = current_config[selected_slot]
	if prev_organ == organ_id:
		status_label.text = "Already installed. Pick a different organ."
		return

	current_config[selected_slot] = organ_id
	status_label.text = "Installed %s in slot %d — press RUN when ready" % [ORGANS[organ_id].label.replace("\n", " "), selected_slot]
	selected_slot = -1
	result_label.text = ""
	_refresh_slots()

func _on_run_pressed() -> void:
	if is_animating:
		return
	is_animating  = true
	attempt_count += 1
	selected_slot = -1

	var failed_slot := -1
	for i in range(4):
		if current_config[i] != HEALTHY_CONFIG[i]:
			failed_slot = i
			break

	if failed_slot == -1:
		await _animate_success()
	else:
		await _animate_failure(failed_slot)

	is_animating = false

# ---------------------------------------------------------------------------
# ANIMATIONS
# ---------------------------------------------------------------------------

func _animate_success() -> void:
	solve_count += 1

	# Cascade-activate each slot top to bottom
	for i in range(4):
		_flash_slot(i, Color(0.30, 1.00, 0.55))
		await get_tree().create_timer(0.18).timeout

	result_label.text = "✓  CREATURE ACTIVATED  —  All biology stable."
	result_label.add_theme_color_override("font_color", Color(0.30, 1.00, 0.55))
	status_label.text = "Solved in %d attempt(s) this run. Resetting…" % attempt_count

	await get_tree().create_timer(2.5).timeout
	_reset_puzzle()

func _animate_failure(failed_slot: int) -> void:
	# Brief pause — build tension
	await get_tree().create_timer(0.3).timeout

	# Flash failure slot red
	_flash_slot(failed_slot, Color(1.00, 0.20, 0.20))

	var organ_id : String = current_config[failed_slot]
	result_label.text = "✗  SYSTEM FAILURE  —  Slot %d rejected: %s is incompatible here." % [failed_slot, ORGANS[organ_id].label.replace("\n", " ")]
	result_label.add_theme_color_override("font_color", Color(1.00, 0.30, 0.30))
	status_label.text = "Inspect slot %d — what organ should go here?" % failed_slot

	await get_tree().create_timer(1.8).timeout
	_refresh_slots()

func _reset_puzzle() -> void:
	current_config = {
		0: "vordex_emitter",
		1: "thrennic_splitter",
		2: "vordex_emitter",    # broken
		3: "ossuric_terminus",
	}
	selected_slot  = -1
	attempt_count  = 0
	result_label.text = ""
	status_label.text = "Tap a slot to inspect it"
	_refresh_slots()
