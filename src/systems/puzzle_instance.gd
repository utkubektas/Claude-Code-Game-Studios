class_name PuzzleInstance
extends RefCounted

## Oyuncunun aktif bulmacadaki runtime durumunu tutar.
## PuzzleResource'tan yüklenerek oluşturulur; .tres dosyasına yazılmaz.
## PuzzleDataSystem tarafından oluşturulur ve yönetilir.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Oyuncu bir slota organ yerleştirdiğinde (veya değiştirdiğinde) yayınlanır.
signal organ_placed(slot_index: int, organ_id: String)

## Bulmaca doğru çözüldüğünde yayınlanır.
signal puzzle_solved

## Bulmaca başlangıç durumuna sıfırlandığında yayınlanır.
signal puzzle_reset

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

## Kaynak veri referansı — salt okunur.
var puzzle_resource: PuzzleResource

## Oyuncunun güncel organ yerleşimi.
## Array index = slot_index, değer = organ_type_id.
var current_configuration: Array[String] = []

## Bu bulmacada kaç kez RUN'a basıldı.
var attempt_count: int = 0

## Bulmaca çözüldü mü?
var is_solved: bool = false

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _organ_registry: OrganTypeRegistry
var _healthy_configuration: Array[String] = []

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## PuzzleInstance'ı başlatır.
## healthy_configuration: ilgili creature'ın CreatureTypeResource.healthy_configuration'ı.
func setup(
	p_puzzle_resource: PuzzleResource,
	p_healthy_configuration: Array[String],
	p_organ_registry: OrganTypeRegistry
) -> void:
	puzzle_resource = p_puzzle_resource
	_healthy_configuration = p_healthy_configuration
	_organ_registry = p_organ_registry
	current_configuration = puzzle_resource.starting_configuration.duplicate()
	attempt_count = 0
	is_solved = false

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Belirtilen slota organ yerleştirir.
## Bilinmeyen organ_type_id → reddedilir, current_configuration değişmez.
## Başarılıysa organ_placed sinyali yayınlanır.
func set_organ(slot_index: int, organ_type_id: String) -> void:
	if _organ_registry.get_organ(organ_type_id) == null:
		push_warning(
			"PuzzleInstance '%s': bilinmeyen organ_type_id '%s' — set_organ reddedildi."
			% [puzzle_resource.display_title, organ_type_id]
		)
		return

	if slot_index < 0 or slot_index >= current_configuration.size():
		push_warning(
			"PuzzleInstance '%s': slot_index %d geçersiz (0..%d aralığında olmalı)."
			% [puzzle_resource.display_title, slot_index, current_configuration.size() - 1]
		)
		return

	current_configuration[slot_index] = organ_type_id
	organ_placed.emit(slot_index, organ_type_id)


## Güncel konfigürasyonu döner. Her çağrıda tutarlı sonuç üretir.
## Kopya döner — dış mutasyon iç durumu bozmaz.
func get_current_configuration() -> Array[String]:
	return current_configuration.duplicate()


## RUN tetiklendiğinde çağrılır — attempt_count'u artırır.
func increment_attempts() -> void:
	attempt_count += 1


## Çözüm kontrolü.
## current_configuration == healthy_configuration ise is_solved = true,
## puzzle_solved sinyali yayınlanır. Zaten çözülmüşse sinyal tekrar yayınlanmaz.
func check_solved() -> bool:
	if is_solved:
		return true
	if current_configuration == _healthy_configuration:
		is_solved = true
		puzzle_solved.emit()
	else:
		is_solved = false
	return is_solved


## Bulmacayı başlangıç durumuna sıfırlar.
## attempt_count korunur (GDD F3: attempt_count sıfırlanmaz).
func reset() -> void:
	current_configuration = puzzle_resource.starting_configuration.duplicate()
	is_solved = false
	puzzle_reset.emit()
