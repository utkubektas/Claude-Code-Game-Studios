class_name RunSimulationController
extends Node

## RUN butonuna basılınca tüm akışı koordine eden orkestratör.
## Kendi başına biyoloji kuralı değerlendirmez — BiologyRuleEngine ve
## FailureCascadeSystem'e delege eder.
##
## Kullanım:
##   1. setup() ile bağımlılıkları ata.
##   2. connect_input() ile TouchInputHandler'ı bağla.
##   3. connect_vfx() ile RunSequenceVFX stub/node'unu bağla.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum _State { IDLE, EVALUATING, ANIMATING, SOLVED }

# ---------------------------------------------------------------------------
# Exported tuning knobs
# ---------------------------------------------------------------------------

## VFX'in vfx_complete göndermesi için bekleme süresi (saniye).
## Prodüksiyonda Inspector'dan ayarlanabilir; VFX süresinden uzun tutulmalı.
@export var vfx_timeout_sec: float = 5.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## VFX sistemi bu signal'i dinler ve animasyonu başlatır.
signal vfx_play_requested(cascade_result: FailureCascadeResult)

## Bulmaca başarıyla çözüldüğünde. Screen Navigation bağlanır.
signal puzzle_solved(next_puzzle_index: int)

## Her RUN denemesi tamamlanınca. OrganRepairMechanic ossuric kilidini açmak için dinler.
signal attempt_completed()

## Tüm sistemler kilitlenmeli. TouchInputHandler ve OrganRepairMechanic bağlanır.
signal locked()

## Kilit açıldı. TouchInputHandler ve OrganRepairMechanic bağlanır.
signal unlocked()

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _puzzle_instance: PuzzleInstance
var _creature: CreatureTypeResource
var _registry: OrganTypeRegistry
var _state: _State = _State.IDLE
var _vfx_timer: SceneTreeTimer = null

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Bağımlılıkları atar. load_puzzle() yapıldıktan sonra çağrılır.
func setup(
	p_puzzle_instance: PuzzleInstance,
	p_creature: CreatureTypeResource,
	p_registry: OrganTypeRegistry
) -> void:
	_puzzle_instance = p_puzzle_instance
	_creature = p_creature
	_registry = p_registry
	_state = _State.IDLE


## TouchInputHandler'ın run_tapped sinyalini bu kontrolcüye bağlar.
func connect_input(p_handler: TouchInputHandler) -> void:
	p_handler.run_tapped.connect(_on_run_tapped)


## VFX node'unu bağlar.
## p_vfx: `handle_play(result: FailureCascadeResult)` metodu ve
##        `vfx_complete` sinyali olan herhangi bir Node.
func connect_vfx(p_vfx: Node) -> void:
	vfx_play_requested.connect(p_vfx.handle_play)
	p_vfx.vfx_complete.connect(_on_vfx_complete)


## VFX'siz test ortamları için vfx_complete'i doğrudan tetikler.
## Sadece ANIMATING durumunda etkilidir.
func notify_vfx_complete() -> void:
	_on_vfx_complete()

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _on_run_tapped() -> void:
	if _state != _State.IDLE:
		return

	_state = _State.EVALUATING
	locked.emit()

	_puzzle_instance.increment_attempts()
	attempt_completed.emit()

	var config := _puzzle_instance.get_current_configuration()
	var ctx := BiologyContext.new(config, _creature, _registry)
	var eval := BiologyRuleEngine.new().evaluate(ctx)
	var cascade_result := FailureCascadeSystem.new().resolve(eval)

	_state = _State.ANIMATING
	_start_vfx_timeout()
	vfx_play_requested.emit(cascade_result)


func _on_vfx_complete() -> void:
	if _state != _State.ANIMATING:
		return
	_cancel_vfx_timeout()

	_puzzle_instance.check_solved()

	if _puzzle_instance.is_solved:
		_state = _State.SOLVED
		var next_index: int = _puzzle_instance.puzzle_resource.puzzle_index + 1
		puzzle_solved.emit(next_index)
	else:
		_state = _State.IDLE

	unlocked.emit()


func _start_vfx_timeout() -> void:
	if not is_inside_tree():
		return
	_vfx_timer = get_tree().create_timer(vfx_timeout_sec)
	_vfx_timer.timeout.connect(_on_vfx_timeout)


func _cancel_vfx_timeout() -> void:
	if _vfx_timer == null:
		return
	if _vfx_timer.timeout.is_connected(_on_vfx_timeout):
		_vfx_timer.timeout.disconnect(_on_vfx_timeout)
	_vfx_timer = null


func _on_vfx_timeout() -> void:
	push_warning("RunSimulationController: VFX timeout — vfx_complete %.1f saniye içinde gelmedi. Zorla IDLE'a dönülüyor." % vfx_timeout_sec)
	_vfx_timer = null
	_state = _State.IDLE
	unlocked.emit()
