class_name CreatureDefinitionSystem
extends Resource

## Tüm CreatureTypeResource tanımlarını tutan statik katalog.
## Runtime'da salt okunur. OrganTypeRegistry ile çapraz doğrulama yapabilir.

@export var creatures: Array[CreatureTypeResource] = []

var _index: Dictionary = {}


## Verilen id'ye sahip creature'ı döner; bilinmeyen id → null (hata atmaz).
func get_creature(id: String) -> CreatureTypeResource:
	_ensure_index()
	return _index.get(id, null)


func get_all_creatures() -> Array[CreatureTypeResource]:
	return creatures


## Veri bütünlüğünü doğrular. OrganTypeRegistry parametre olarak opsiyoneldir;
## verilmezse organ ID'lerinin Registry'de varlığı atlanır.
func valid_creatures(registry: OrganTypeRegistry = null) -> bool:
	var seen_ids: Dictionary = {}

	for creature: CreatureTypeResource in creatures:
		if not creature.is_valid():
			push_error(
				"CreatureDefinitionSystem: '%s' geçersiz — zorunlu alan boş veya healthy_configuration yanlış." % creature.creature_id
			)
			return false

		if seen_ids.has(creature.creature_id):
			push_error(
				"CreatureDefinitionSystem: '%s' ID'si birden fazla creature'da." % creature.creature_id
			)
			return false
		seen_ids[creature.creature_id] = true

		# healthy_configuration slot sayısı kontrolü (is_valid() içinde de var ama burada net mesaj)
		if creature.healthy_configuration.size() != creature.organ_slots.size():
			push_error(
				"CreatureDefinitionSystem: '%s' healthy_configuration uzunluğu (%d) organ_slots uzunluğundan (%d) farklı." \
				% [creature.creature_id, creature.healthy_configuration.size(), creature.organ_slots.size()]
			)
			return false

		# Registry verilmişse organ ID'lerini doğrula
		if registry != null:
			for organ_id: String in creature.healthy_configuration:
				if registry.get_organ(organ_id) == null:
					push_error(
						"CreatureDefinitionSystem: '%s' healthy_configuration'da bilinmeyen organ_id '%s'." \
						% [creature.creature_id, organ_id]
					)
					return false

		# Kanal öz-döngü kontrolü
		for channel: SlotChannel in creature.slot_channels:
			if not channel.is_valid():
				push_error(
					"CreatureDefinitionSystem: '%s' kanalında öz-döngü — from_slot == to_slot == %d." \
					% [creature.creature_id, channel.from_slot_index]
				)
				return false

		# Slot yakınlık uyarısı (hata değil)
		_check_slot_distances(creature)

	return true


func _check_slot_distances(creature: CreatureTypeResource) -> void:
	const MIN_SLOT_DISTANCE: float = 64.0
	var slots := creature.organ_slots
	for i in range(slots.size()):
		for j in range(i + 1, slots.size()):
			var dist := slots[i].world_position.distance_to(slots[j].world_position)
			if dist < MIN_SLOT_DISTANCE:
				push_warning(
					"CreatureDefinitionSystem: '%s' slot %d ve slot %d çok yakın (%.1fpx < %.0fpx)." \
					% [creature.creature_id, i, j, dist, MIN_SLOT_DISTANCE]
				)


func _ensure_index() -> void:
	if _index.is_empty() and not creatures.is_empty():
		_build_index()


func _build_index() -> void:
	_index.clear()
	for creature: CreatureTypeResource in creatures:
		_index[creature.creature_id] = creature
