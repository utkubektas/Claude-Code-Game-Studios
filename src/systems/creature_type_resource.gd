class_name CreatureTypeResource
extends Resource

## Bir alien creature arketipinin tüm statik verisini tutar.
## Bulmaca oluşturma için Puzzle Data System, render için Specimen Viewer kullanır.
## healthy_configuration[i] = slot i'nin doğru organ_id'si.

@export var creature_id: String = ""
@export var display_name: String = ""
@export var lore_hint: String = ""

@export var organ_slots: Array[OrganSlotDefinition] = []
@export var slot_channels: Array[SlotChannel] = []

## Slot index → organ_id: doğru çözümü tanımlar.
## Array index = slot_index, değer = organ_type_id.
## Uzunluk organ_slots.size() ile eşit olmalı.
@export var healthy_configuration: Array[String] = []

## "start" → oyunun başından itibaren erişilebilir.
## "complete:{creature_id}" → ilgili creature tüm bulmacaları çözülünce açılır.
@export var unlock_condition: String = "start"

## Görsel kaynak — Sprint 02'de doldurulacak.
@export var sprite_silhouette: Texture2D


func get_slot_count() -> int:
	return organ_slots.size()


func get_healthy_configuration() -> Array[String]:
	return healthy_configuration


func is_valid() -> bool:
	if creature_id.is_empty():
		return false
	if display_name.is_empty():
		return false
	if organ_slots.is_empty():
		return false
	if healthy_configuration.size() != organ_slots.size():
		return false
	return true
