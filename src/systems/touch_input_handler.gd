class_name TouchInputHandler
extends Node

## Ham dokunma olaylarını oyun sinyallerine dönüştürür.
## Üst sistemler koordinat hesabı yapmaz; yalnızca slot_tapped / inventory_tapped /
## run_tapped sinyallerini dinler.
## MVP: yalnızca tek parmak tap. Drag V1'de eklenir.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum TouchAreaType { SLOT, INVENTORY, RUN_BUTTON, GENERIC }

enum _State { IDLE, TOUCHING, LOCKED }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Tap olarak tanımlanacak maksimum süre (ms).
const TAP_MAX_DURATION_MS: int = 200

## Tap olarak tanımlanacak maksimum parmak hareketi (px).
const TAP_MAX_DELTA_PX: float = 10.0

## Kayıtlı herhangi bir alanın minimum boyutu. Küçük alanlar bu değere büyütülür.
const MIN_TOUCH_AREA: float = 48.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## SLOT alanına tap yapıldığında. slot_index = area payload.
signal slot_tapped(slot_index: int)

## INVENTORY alanına tap yapıldığında. organ_id = area payload.
signal inventory_tapped(organ_id: String)

## RUN_BUTTON alanına tap yapıldığında.
signal run_tapped()

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _state: _State = _State.IDLE
var _areas: Dictionary = {}  # id:String → TouchAreaEntry Dictionary

var _touch_start_time: int = 0
var _touch_start_pos: Vector2 = Vector2.ZERO

# ---------------------------------------------------------------------------
# Inner type
# ---------------------------------------------------------------------------

## Kayıtlı dokunma alanını temsil eder.
class TouchAreaEntry:
	var id: String
	var rect: Rect2
	var type: TouchAreaType
	var payload: Variant
	## Çakışan alanlarda öncelik belirler. Yüksek değer kazanır (F2).
	var z_index: int

	func _init(
		p_id: String,
		p_rect: Rect2,
		p_type: TouchAreaType,
		p_payload: Variant,
		p_z_index: int = 0
	) -> void:
		id = p_id
		rect = p_rect
		type = p_type
		payload = p_payload
		z_index = p_z_index

# ---------------------------------------------------------------------------
# Godot callbacks
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_process_touch_event(event as InputEventScreenTouch)

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Dokunma alanı kaydeder. Aynı id ile tekrar çağrılırsa üzerine yazar.
## Rect boyutu MIN_TOUCH_AREA altındaysa uyarı verilir ve büyütülür.
## p_z_index: çakışmalarda öncelik (F2 — yüksek değer kazanır).
func register_area(
	p_id: String,
	p_rect: Rect2,
	p_type: TouchAreaType,
	p_payload: Variant,
	p_z_index: int = 0
) -> void:
	var safe_rect := _enforce_min_size(p_id, p_rect)
	var entry := TouchAreaEntry.new(p_id, safe_rect, p_type, p_payload, p_z_index)
	_areas[p_id] = entry


## Kaydedilmiş alanı kaldırır. Bilinmeyen id → sessiz.
func unregister_area(p_id: String) -> void:
	_areas.erase(p_id)


## Input'u kilitler. RUN animasyonu sırasında çağrılır.
func lock_input() -> void:
	_state = _State.LOCKED


## Input kilidini açar.
func unlock_input() -> void:
	_state = _State.IDLE


## InputEventScreenTouch'u doğrudan işler. Testlerde _input() atlanarak çağrılabilir.
## Yalnızca ilk parmak (index == 0) işlenir; eş zamanlı ikinci parmak yutulur.
func _process_touch_event(event: InputEventScreenTouch) -> void:
	if event.index != 0:
		return

	if _state == _State.LOCKED:
		return

	if event.pressed:
		_touch_start_time = Time.get_ticks_msec()
		_touch_start_pos = event.position
		_state = _State.TOUCHING
		return

	if _state != _State.TOUCHING:
		return

	_state = _State.IDLE

	var duration: int = Time.get_ticks_msec() - _touch_start_time
	var delta: float = event.position.distance_to(_touch_start_pos)

	if duration > TAP_MAX_DURATION_MS or delta > TAP_MAX_DELTA_PX:
		return

	_dispatch_tap(event.position)

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _dispatch_tap(p_pos: Vector2) -> void:
	var hit := _hit_test(p_pos)
	if hit == null:
		return

	match hit.type:
		TouchAreaType.SLOT:
			slot_tapped.emit(hit.payload as int)
		TouchAreaType.INVENTORY:
			inventory_tapped.emit(hit.payload as String)
		TouchAreaType.RUN_BUTTON:
			run_tapped.emit()
		# GENERIC: geçerli hit-test hedefi ama sinyal emit etmez — gelecek kullanım için rezerve.


func _hit_test(p_pos: Vector2) -> TouchAreaEntry:
	# GDD F2: çakışan alanlarda en yüksek z_index kazanır.
	var result: TouchAreaEntry = null
	for entry: TouchAreaEntry in _areas.values():
		if not entry.rect.has_point(p_pos):
			continue
		if result == null or entry.z_index > result.z_index:
			result = entry
	return result


func _enforce_min_size(p_id: String, p_rect: Rect2) -> Rect2:
	var w: float = maxf(p_rect.size.x, MIN_TOUCH_AREA)
	var h: float = maxf(p_rect.size.y, MIN_TOUCH_AREA)
	if w != p_rect.size.x or h != p_rect.size.y:
		push_warning(
			"TouchInputHandler: '%s' alanı minimum dokunma boyutunu karşılamıyor (%s) — %s×%s'e büyütüldü."
			% [p_id, p_rect.size, w, h]
		)
	return Rect2(p_rect.position, Vector2(w, h))
