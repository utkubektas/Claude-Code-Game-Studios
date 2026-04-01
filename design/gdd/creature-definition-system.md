# Creature Definition System

> **Status**: Designed (pending review)
> **Author**: Design session
> **Last Updated**: 2026-04-01
> **Implements Pillar**: Alien Logic, Learnable Rules; Discovery Through Deduction

## Overview

Creature Definition System, Specimen'deki her alien creature arketipini tanımlayan statik veri kataloğudur. Her arketip, `CreatureTypeResource` adlı bir Godot Resource dosyasıyla temsil edilir ve şunları içerir: görsel kimlik (creature silueti), organ slot layoutu (her slotun ekran pozisyonu ve kabul ettiği organ tipleri), sağlıklı referans konfigürasyonu ve bu creature arketipini açan progression koşulu. Puzzle Data System bulmaca oluşturmak için bu blueprint'i kullanır; Specimen Viewer anatomik görünümü buradan render eder. Her yeni creature arketipi, oyuncunun keşfedip öğreneceği yeni bir biyoloji dalını temsil eder.

## Player Fantasy

Her yeni creature arketipini ilk gördüğünde oyuncu bir yabancı anatomiye bakar — tanıdık ama tuhaf. Organların nerede olduğunu, hangi şekillerin hangi işlevi gördüğünü bilmez. Bu sistem, o "yabancı beden"in tutarlı ve keşfedilebilir olmasını garantiler. Creature arketipleri oyuncunun ilerledikçe "tanıdığı" karakterlere dönüşür — "Bu Vorrkai tipi, bunların pulsator'ları her zaman kuzey slotta." Anatomy blueprint'in tutarlılığı, mastery hissinin temel taşıdır.

## Detailed Design

### Core Rules

1. Her creature arketipi, `assets/data/creatures/` altında ayrı bir `CreatureTypeResource` (.tres) dosyasıyla tanımlanır.
2. MVP: 1 creature arketipi, 4 organ slotu; her slot için 1 kabul edilen organ tipi.
3. Her bulmaca, `healthy_configuration`'dan tam 1 organ değiştirilerek üretilir (MVP kısıtı — çoklu arıza V1'e ertelendi).
4. Kanallar (`slot_channels`) creature tanımında sabittir; runtime'da kopmaz veya değişmez.
5. `healthy_configuration` her zaman tam dolu olmalı — tüm slotlar için doğru organ_type_id içerir.

**`CreatureTypeResource` alanları:**

| Alan | Tip | Açıklama |
|------|-----|---------|
| `id` | String | Benzersiz kimlik (ör: `"vorrkai"`) |
| `display_name` | String | UI'da görünen isim |
| `lore_hint` | String | Kısa flavor text — Discovery Journal için |
| `sprite_silhouette` | Texture2D | Creature vücut silueti (anatominin arka planı) |
| `organ_slots` | `Array[OrganSlotDefinition]` | 4 slot (MVP) |
| `slot_channels` | `Array[SlotChannel]` | Slotlar arası sabit biyoloji kanalları |
| `healthy_configuration` | `Dictionary[int, String]` | slot_index → organ_type_id (doğru çözüm) |
| `unlock_condition` | String | `"start"` (ilk arketip) veya `"complete:{creature_id}"` |

**`OrganSlotDefinition` alanları:**

| Alan | Tip | Açıklama |
|------|-----|---------|
| `slot_index` | int | 0–3 (MVP) |
| `world_position` | Vector2 | Creature merkezi göre piksel pozisyonu |
| `accepted_organ_type_ids` | `Array[String]` | Boşsa tüm organ tipleri geçerli |

**`SlotChannel` alanları:**

| Alan | Tip | Açıklama |
|------|-----|---------|
| `from_slot_index` | int | Kanalın başladığı slot |
| `to_slot_index` | int | Kanalın bittiği slot |
| `flow_type` | FlowType | PULSE veya FLUID |

### States and Transitions

Creature Definition System'in runtime state'i yoktur — tamamen statik veri. Bir creature *örneğinin* mevcut durumu (hangi organlarda ne var, hangi slot bozuk) Puzzle Data System tarafından yönetilir.

### Interactions with Other Systems

| Sistem | Yön | Veri Akışı |
|--------|-----|-----------|
| Organ Type Registry | Registry → Creature | `accepted_organ_type_ids` ve `healthy_configuration` içindeki ID'ler Registry'de doğrulanır |
| Puzzle Data System | Creature → Puzzle | `organ_slots`, `slot_channels`, `healthy_configuration` — bulmaca oluşturma için |
| Specimen Viewer | Creature → Viewer | `sprite_silhouette`, `organ_slots[].world_position` — anatomik render |
| Creature Type Unlock System | Creature → Unlock | `unlock_condition` — progression koşulu |
| Discovery Journal | Creature → Journal | `display_name`, `lore_hint` — journal girişleri |

## Formulas

### Registry Geçerlilik Doğrulama

```
valid_creature(creature) =
  creature.id unique
  AND len(creature.organ_slots) >= 1
  AND len(creature.healthy_configuration) == len(creature.organ_slots)
  AND ∀ slot_index ∈ healthy_configuration: slot_index ∈ [0, len(organ_slots)-1]
  AND ∀ organ_id ∈ healthy_configuration.values(): organ_id ∈ OrganTypeRegistry
  AND ∀ channel ∈ slot_channels: channel.from_slot_index != channel.to_slot_index
```

Başlatma sırasında herhangi bir koşul sağlanmazsa hata fırlatılır.

### Slot Pozisyonu Mesafe Kontrolü (opsiyonel)

```
slots_overlap(slot_a, slot_b) =
  distance(slot_a.world_position, slot_b.world_position) < MIN_SLOT_DISTANCE
```

`MIN_SLOT_DISTANCE` = 64px (tasarım zamanı sabiti). İki slotun çakışmasını önler.

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| `healthy_configuration` eksik slot içeriyor | Yüklemede hata fırlatılır | Puzzle Data System tüm slotların doğru konfigürasyonunu bilmeli |
| `healthy_configuration`'daki organ_type_id Registry'de yok | Yüklemede hata fırlatılır | Geçersiz organ referansı bulmaca oluşturmayı bozar |
| İki slot çok yakın pozisyonda (< MIN_SLOT_DISTANCE) | Yüklemede uyarı fırlatılır | Üst üste gelen slotlar dokunma hassasiyetini bozar |
| `slot_channels`'da var olmayan slot_index referansı | Yüklemede hata fırlatılır | Geçersiz kanal Biology Rule Engine'i çökertir |
| Kanal kendi kendine döngü yapıyor (`from == to`) | Yüklemede hata fırlatılır | Öz-döngülü kanal simülasyonu sonsuz döngüye sokar |
| `unlock_condition`'daki creature_id mevcut değil | Yüklemede uyarı (hata değil) | Bağımlı creature henüz eklenmemiş olabilir; oyun çalışır ama creature açılmaz |

## Dependencies

| Sistem | Yön | Bağımlılık Türü | Arayüz |
|--------|-----|----------------|--------|
| Organ Type Registry | Creature → Registry | Sert — `healthy_configuration` ID'leri Registry'de doğrulanır | `OrganTypeRegistry.get_organ(id)` |
| Puzzle Data System | Puzzle → Creature | Sert — bulmaca oluşturmak için anatomy blueprint gerekli | `get_creature(id) → CreatureTypeResource` |
| Specimen Viewer | Viewer → Creature | Sert — render için silüet ve slot pozisyonları gerekli | `get_creature(id).sprite_silhouette`, `.organ_slots` |
| Creature Type Unlock System | Unlock → Creature | Sert — unlock koşulunu değerlendirmek için | `get_creature(id).unlock_condition` |
| Discovery Journal | Journal → Creature | Yumuşak — journal çalışır ama isim/lore eksik | `get_creature(id).display_name`, `.lore_hint` |

**Upstream bağımlılıklar**: Organ Type Registry (ID doğrulama için).
**Downstream bağımlılar**: Puzzle Data System, Specimen Viewer, Creature Type Unlock System, Discovery Journal.

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artışın Etkisi | Azalışın Etkisi |
|-----------|-------------|---------------|---------------|----------------|
| MVP slot sayısı (creature başına) | 4 | 3–8 | Daha karmaşık bulmacalar; daha fazla çizim/tasarım maliyeti | Bulmacalar çok basit; çeşitlilik azalır |
| MVP creature arketipi sayısı | 1 | 1–2 | Daha fazla içerik, retention artışı | Tek tip geri bildirim riski yüksek |
| `MIN_SLOT_DISTANCE` | 64px | 48–96px | Slotlar daha ayrık; büyük anatomiler | Slotlar birbirine yakın; dokunma hatası riski |
| Kanal sayısı (creature başına) | 3–5 (anatomy karmaşıklığına göre) | 2–8 | Daha karmaşık biyoloji akışı; bulmaca derinliği artar | Fazla basit biyoloji; deduction zorluğu azalır |

**Yeni creature arketipi ekleme maliyeti**: Yeni `.tres` + siluet sprite + slot pozisyonlarının elle ayarlanması + `healthy_configuration` tanımı. Yeni organ tipleri gerektirmeyebilir.

## Visual/Audio Requirements

| Olay | Görsel Geri Bildirim | Ses | Öncelik |
|------|---------------------|-----|---------|
| Creature ilk göründüğünde | Siluet fade-in animasyonu; organ slotları boş görünür | Alien ambient ses | MVP |
| Creature "canlı" (run başarılı) | Biyolüminesant aktivasyon sekansı (`Run Sequence VFX` yönetir) | Aktivasyon ses imzası | MVP |
| Creature arızalı göründüğünde | Arızalı slotlar `sprite_damaged` görüntüler | Arıza ambient sesi | MVP |

Creature siluet stili: 2D stylized, biyolüminesant alien paleti. Her arketip görsel olarak diğerinden belirgin biçimde ayrılmalı (renk paleti veya anatomik şekil).

## UI Requirements

Creature Definition System doğrudan UI içermiyor — veri kataloğu. UI gereksinimleri Specimen Viewer GDD'sinde tanımlanır. Bu sistemin sağladığı veriler: `display_name` (başlık için), `organ_slots[].world_position` (slot göstergeleri için), `sprite_silhouette` (arka plan render için).

## Acceptance Criteria

- [ ] 1 MVP creature arketipi tanımlı, `valid_creature()` kontrolü geçiyor
- [ ] `get_creature(id)` geçerli ID için `CreatureTypeResource` döndürüyor
- [ ] `get_creature(id)` bilinmeyen ID için `null` döndürüyor, hata fırlatmıyor
- [ ] `healthy_configuration` 4 slot için eksiksiz dolu, tüm organ_type_id'ler Registry'de mevcut
- [ ] Öz-döngülü kanal (`from == to`) yüklemede hata fırlatıyor
- [ ] `MIN_SLOT_DISTANCE` ihlali yüklemede uyarı üretiyor
- [ ] Specimen Viewer creature siluetini ve 4 organ slot pozisyonunu doğru konumda render ediyor
- [ ] Yükleme süresi < 16ms (tüm creature arketipleri için toplamda)
- [ ] Hiçbir değer hardcoded değil — tüm veriler `.tres` dosyalarından geliyor
- [ ] GUT testi: `TestCreatureDefinitionSystem.gd` tüm kriterleri otomatik doğruluyor

## Open Questions

| Soru | Sahibi | Hedef | Çözüm |
|------|--------|-------|-------|
| MVP creature arketipinin ismi ne olacak? | Tasarımcı | Prototype öncesi | Lore ve görsel tasarımla birlikte kararlaştırılacak |
| MVP'deki 4 organ tipinin `healthy_configuration` içindeki sırası ne olacak? | Tasarımcı | Organ Type Registry ve Biology Rule Engine GDD'leri tamamlandıktan sonra | 4 organ tipi belirlendikten sonra tanımlanacak |
| Slot pozisyonları (Vector2) nasıl kalibre edilecek? | Programcı | Specimen Viewer prototipi sırasında | Elle ayarlama + Godot Editor ile görsel doğrulama |
