class_name PuzzleResource
extends Resource

## Bir bulmacayı tanımlayan statik veri.
## assets/data/puzzles/puzzle_NN.tres dosyalarında saklanır.
## Runtime'da değişmez — oyuncu durumu PuzzleInstance'ta tutulur.

# ---------------------------------------------------------------------------
# Export variables
# ---------------------------------------------------------------------------

@export_group("Identity")

## 1-tabanlı bulmaca sıra numarası. puzzle_01.tres → puzzle_index = 1.
@export var puzzle_index: int = 1

## UI'da görünen başlık. Örn: "Specimen 01-A".
@export var display_title: String = ""

@export_group("Creature")

## Hangi creature arketipi kullanılıyor. CreatureDefinitionSystem'deki creature_id ile eşleşmeli.
@export var creature_type_id: String = ""

@export_group("Configuration")

## Oyunun başladığı hatalı durum.
## Array index = slot_index, değer = organ_type_id.
## Uzunluk ilgili creature'ın organ_slots.size() ile eşit olmalı.
@export var starting_configuration: Array[String] = []

## Hangi slot bozuk olduğuna dair ipucu (-1 = ipucu yok).
@export var hint_slot_index: int = -1

@export_group("Unlock")

## Hangi bulmaca çözülünce bu açılır (0 = başlangıçta açık).
@export var unlock_after_index: int = 0


# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Yükleme zamanı doğrulaması — creature ve registry ile birlikte.
## true döner geçerliyse, false döner ve push_warning çağırır geçersizse.
func is_valid(
	creature_def_system: CreatureDefinitionSystem,
	organ_registry: OrganTypeRegistry
) -> bool:
	if puzzle_index < 1:
		push_warning(
			"PuzzleResource '%s': puzzle_index %d geçersiz — 1 veya üzeri olmalı."
			% [display_title, puzzle_index]
		)
		return false

	if display_title.is_empty():
		push_warning("PuzzleResource index=%d: display_title boş." % puzzle_index)
		return false

	if creature_type_id.is_empty():
		push_warning("PuzzleResource '%s': creature_type_id boş." % display_title)
		return false

	var creature: CreatureTypeResource = creature_def_system.get_creature(creature_type_id)
	if creature == null:
		push_warning(
			"PuzzleResource '%s': creature_type_id '%s' CreatureDefinitionSystem'de bulunamadı."
			% [display_title, creature_type_id]
		)
		return false

	if starting_configuration.size() != creature.organ_slots.size():
		push_warning(
			"PuzzleResource '%s': starting_configuration boyutu %d, creature slot sayısı %d — eşleşmiyor."
			% [display_title, starting_configuration.size(), creature.organ_slots.size()]
		)
		return false

	if not _all_organs_known(organ_registry):
		return false

	var diff_count: int = _count_differences(creature.healthy_configuration)
	if diff_count == 0:
		push_warning(
			"PuzzleResource '%s': starting_configuration == healthy_configuration — bulmaca zaten çözülü başlıyor."
			% display_title
		)
		return false

	if diff_count > 1:
		push_warning(
			"PuzzleResource '%s': starting_configuration ile healthy_configuration arasında %d fark var — MVP garantisi 1 fark."
			% [display_title, diff_count]
		)
		return false

	return true


## starting_configuration ile verilen healthy_configuration arasındaki farklı slot sayısını döner.
func count_differences_with(healthy_configuration: Array[String]) -> int:
	return _count_differences(healthy_configuration)


# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _all_organs_known(organ_registry: OrganTypeRegistry) -> bool:
	for organ_id: String in starting_configuration:
		if organ_registry.get_organ(organ_id) == null:
			push_warning(
				"PuzzleResource '%s': starting_configuration'da bilinmeyen organ_id '%s'."
				% [display_title, organ_id]
			)
			return false
	return true


func _count_differences(healthy_configuration: Array[String]) -> int:
	var count: int = 0
	for i: int in range(starting_configuration.size()):
		if i >= healthy_configuration.size():
			count += 1
			continue
		if starting_configuration[i] != healthy_configuration[i]:
			count += 1
	return count
