class_name OrganTypeResource
extends Resource

## Organ rolü — Biology Rule Engine bu enum üzerinden kural uygular.
## Sprint 02'de connection_slots (SlotDefinition) bu enum'u tamamlar.
enum Role {
	EMITTER,   ## Sinyali üretir — her puzzleın başlangıç noktası
	GATE,      ## Sinyal akışını kontrol eder — açık/kapalı mantığı
	SPLITTER,  ## Sinyali birden fazla çıkışa böler
	TERMINUS,  ## Sinyali bitirir — çıkış üretmez
}

@export var organ_id: String = ""
@export var display_name: String = ""
@export var role: Role = Role.EMITTER

## Sprint 01: hangi kanal tiplerinde çıkış ürettiği (örn. ["PULSE"], ["FLUID"]).
## Sprint 02'de bunu SlotDefinition array'i ile değiştireceğiz.
@export var output_channels: Array[String] = []

## Biology Rule Engine'e bağlayan kural ID'si.
## Sprint 04'te rule engine bu ID'yi doğrular; şimdilik non-empty kontrolü yeterli.
@export var biology_rule_id: String = ""

## Bu organı kullanan creature arketiplerinin ID listesi.
@export var creature_type_ids: Array[String] = []

## Görsel kaynaklar — Sprint 01'de null, Sprint 02'de doldurulacak.
@export var sprite_normal: Texture2D
@export var sprite_damaged: Texture2D


func is_valid() -> bool:
	if organ_id.is_empty():
		return false
	if display_name.is_empty():
		return false
	if biology_rule_id.is_empty():
		return false
	if creature_type_ids.is_empty():
		return false
	return true
