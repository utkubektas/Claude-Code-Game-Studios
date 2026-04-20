class_name PuzzleDataSystem
extends Node

## Tüm bulmaca verisini yönetir: yükleme, aktif instance yönetimi, sekans kontrolü.
## Organ Repair Mechanic, Run Simulation Controller ve Puzzle HUD bu sisteme danışır.
##
## Kullanım:
##   1. @export ile creature_definition_system ve organ_type_registry ata.
##   2. load_puzzle(1) ile ilk bulmacayı yükle.
##   3. active_instance üzerinden set_organ / check_solved / reset çağır.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Son bulmaca çözülünce next_puzzle_index() bu değeri döner.
const END_OF_SEQUENCE: int = -1

## MVP'de toplam bulmaca sayısı (varsayılan). Gerçek sınır max_puzzle_index export'undan gelir.
const MAX_PUZZLE_INDEX: int = 10

## Puzzle .tres dosyalarının bulunduğu dizin.
const PUZZLE_DATA_PATH: String = "res://assets/data/puzzles/"

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Oyuncu bir slota organ yerleştirdiğinde (PuzzleInstance'tan iletilir).
signal organ_placed(slot_index: int, organ_id: String)

## Aktif bulmaca doğru çözüldüğünde (PuzzleInstance'tan iletilir).
signal puzzle_solved

## Aktif bulmaca sıfırlandığında (PuzzleInstance'tan iletilir).
signal puzzle_reset

# ---------------------------------------------------------------------------
# Export variables (dependency injection)
# ---------------------------------------------------------------------------

@export_group("Puzzle Config")

## Geçerli bulmaca sayısı. Sahneye atanarak farklı içerik setleri desteklenebilir.
@export var max_puzzle_index: int = MAX_PUZZLE_INDEX

@export_group("Dependencies")

## Creature arketiplerini sağlar. Atanmadan load_puzzle() çağrılamaz.
@export var creature_definition_system: CreatureDefinitionSystem

## Organ geçerliliğini doğrular. Atanmadan load_puzzle() çağrılamaz.
@export var organ_type_registry: OrganTypeRegistry

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

## Şu an aktif olan PuzzleInstance. Bulmaca yüklü değilse null.
var active_instance: PuzzleInstance = null

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	assert(
		creature_definition_system != null,
		"PuzzleDataSystem: creature_definition_system atanmamış."
	)
	assert(
		organ_type_registry != null,
		"PuzzleDataSystem: organ_type_registry atanmamış."
	)

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Belirtilen 1-tabanlı indekse sahip bulmacayı yükler.
## Başarılıysa PuzzleInstance döner; başarısızsa null döner.
## Örn: load_puzzle(1) → "res://assets/data/puzzles/puzzle_01.tres"
func load_puzzle(puzzle_index: int) -> PuzzleInstance:
	if puzzle_index < 1 or puzzle_index > max_puzzle_index:
		push_warning(
			"PuzzleDataSystem: puzzle_index %d geçersiz (1..%d aralığında olmalı)."
			% [puzzle_index, max_puzzle_index]
		)
		return null

	var path: String = PUZZLE_DATA_PATH + "puzzle_%02d.tres" % puzzle_index
	if not ResourceLoader.exists(path):
		push_warning("PuzzleDataSystem: '%s' bulunamadı." % path)
		return null

	var resource: PuzzleResource = ResourceLoader.load(path) as PuzzleResource
	if resource == null:
		push_warning("PuzzleDataSystem: '%s' PuzzleResource olarak yüklenemedi." % path)
		return null

	if not resource.is_valid(creature_definition_system, organ_type_registry):
		push_warning(
			"PuzzleDataSystem: puzzle_%02d geçerliliği başarısız — yükleme iptal edildi."
			% puzzle_index
		)
		return null

	var creature: CreatureTypeResource = creature_definition_system.get_creature(
		resource.creature_type_id
	)

	_disconnect_active_instance()

	var instance := PuzzleInstance.new()
	instance.setup(resource, creature.healthy_configuration, organ_type_registry)
	_connect_instance(instance)

	active_instance = instance
	return active_instance


## Şu anki puzzle_index'ten bir sonraki indeksi döner.
## Son bulmaca çözülmüşse END_OF_SEQUENCE (-1) döner.
func next_puzzle_index() -> int:
	if active_instance == null:
		return END_OF_SEQUENCE
	var current_index: int = active_instance.puzzle_resource.puzzle_index
	if current_index >= max_puzzle_index:
		return END_OF_SEQUENCE
	return current_index + 1


## Aktif instance'ın çözüm durumunu kontrol eder ve puzzle_solved sinyali yayar.
## Run Simulation Controller tarafından başarılı RUN sonrası çağrılır.
func mark_solved() -> void:
	if active_instance == null:
		push_warning("PuzzleDataSystem: mark_solved() çağrıldı ama active_instance null.")
		return
	active_instance.check_solved()


## Aktif instance'ın deneme sayısını artırır.
## Run Simulation Controller her RUN denemesinde çağırır.
func increment_attempts() -> void:
	if active_instance == null:
		push_warning("PuzzleDataSystem: increment_attempts() çağrıldı ama active_instance null.")
		return
	active_instance.increment_attempts()


## Aktif instance'ı kaldırır. Sahne kapatılırken veya sekans bitişinde çağrılır.
func unload_puzzle() -> void:
	_disconnect_active_instance()
	active_instance = null

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _connect_instance(instance: PuzzleInstance) -> void:
	instance.organ_placed.connect(_on_organ_placed)
	instance.puzzle_solved.connect(_on_puzzle_solved)
	instance.puzzle_reset.connect(_on_puzzle_reset)


func _disconnect_active_instance() -> void:
	if active_instance == null:
		return
	if active_instance.organ_placed.is_connected(_on_organ_placed):
		active_instance.organ_placed.disconnect(_on_organ_placed)
	if active_instance.puzzle_solved.is_connected(_on_puzzle_solved):
		active_instance.puzzle_solved.disconnect(_on_puzzle_solved)
	if active_instance.puzzle_reset.is_connected(_on_puzzle_reset):
		active_instance.puzzle_reset.disconnect(_on_puzzle_reset)

# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

func _on_organ_placed(slot_index: int, organ_id: String) -> void:
	organ_placed.emit(slot_index, organ_id)


func _on_puzzle_solved() -> void:
	puzzle_solved.emit()


func _on_puzzle_reset() -> void:
	puzzle_reset.emit()
