# Organ Type Registry

> **Status**: Designed (pending review)
> **Author**: Design session
> **Last Updated**: 2026-04-01
> **Implements Pillar**: Alien Logic, Learnable Rules

## Overview

Organ Type Registry, Specimen'deki tüm alien organ tiplerini tanımlayan statik veri kataloğudur. Her organ tipi, `OrganTypeResource` adlı özel bir Godot Resource dosyasıyla temsil edilir. Registry oyun başladığında bir kez yüklenir ve runtime'da değişmez. Her organ tipinin kaydı şunları içerir: görsel kimlik, bağlantı noktası yapılandırması, biology rule referansı ve arıza görsel durumu. Biology Rule Engine, Failure Cascade System ve Puzzle Data System, davranışlarını bu kayıtlara dayanarak uygular. Registry olmadan oyunun hiçbir biyoloji sistemi çalışamaz.

## Player Fantasy

Oyuncu her organ tipini ilk gördüğünde onu tanımaz — sadece tuhaf, biyolüminesans bir şekil görür. Ama zamanla her tipin görünümü, bağlantı yapısı ve arıza davranışı tanıdık hale gelir. "Bu mavi halkalı organ — geçen specimen'de de vardı, sağ tarafa bağlı olması lazım" hissi tam olarak bu sistemin vaat ettiği duygudur. Organ tipleri, oyuncunun alien biyoloji hakkında edindiği *kelime dağarcığıdır* — her yeni tip yeni bir kelime, her tanıma anı bir mastery click'tir.

## Detailed Design

### Core Rules

1. Her organ tipi, `assets/data/organs/` dizininde ayrı bir `OrganTypeResource` (.tres) dosyasıyla tanımlanır.
2. Registry başlatıldığında tüm organ Resource dosyaları yüklenir ve `id → OrganTypeResource` eşlemesiyle bir Dictionary'de saklanır.
3. Registry runtime'da salt okunurdur — oyun sırasında hiçbir organ tipi eklenemez, değiştirilemez veya silinemez.
4. Her `OrganTypeResource` şu alanları içerir:

| Alan | Tip | Açıklama |
|------|-----|---------|
| `id` | String | Benzersiz kimlik (ör: `"pulsator_a"`) |
| `display_name` | String | UI'da görünen isim |
| `sprite_normal` | Texture2D | Sağlıklı görünüm |
| `sprite_damaged` | Texture2D | Arızalı görünüm |
| `connection_slots` | `Array[SlotDefinition]` | Yönlü + tipli bağlantı noktaları |
| `biology_rule_id` | String | Bu organın çalıştırdığı kural ID'si |
| `failure_vfx_scene` | PackedScene | Arıza animasyon sahnesi |
| `creature_type_ids` | `Array[String]` | Kullanıldığı creature arketipleri |

5. Her `SlotDefinition` şunları içerir: `direction` (NORTH / SOUTH / EAST / WEST) + `flow_type` (PULSE veya FLUID) + `role` (INPUT veya OUTPUT). `role` alanı Biology Rule Engine tarafından hangi slotların sinyal aldığını, hangilerinin gönderdiğini belirlemek için kullanılır.
6. Bir slot yalnızca aynı `flow_type`'a sahip başka bir slotla bağlanabilir.
7. Geçerli akış tipleri (MVP): `PULSE` (biyoelektrik sinyal) ve `FLUID` (organik sıvı akışı). Yeni tipler versiyonlar arasında eklenebilir.

### States and Transitions

Registry'nin kendisi runtime state'i yoktur — tamamen statik veri. Organ *örneklerinin* durumu (sağlıklı / arızalı / değiştirilmiş) Puzzle Data System tarafından ayrıca yönetilir; Registry bu durumları bilmez.

### Interactions with Other Systems

| Sistem | Yön | Veri Akışı |
|--------|-----|-----------|
| Biology Rule Engine | Registry → Engine | `biology_rule_id` — hangi kuralın uygulanacağını sorgular |
| Failure Cascade System | Registry → Cascade | `connection_slots` — arızanın hangi yönlere yayılabileceğini belirler |
| Puzzle Data System | Registry → Puzzle | Tüm alanlar — bulmaca layoutu oluşturur ve envanter listesi üretir |
| Specimen Viewer | Registry → Viewer | `sprite_normal`, `sprite_damaged`, `failure_vfx_scene` — görsel render için |
| Discovery Journal | Registry → Journal | `display_name`, `creature_type_ids` — journal girişleri için |

## Formulas

### Slot Uyumluluk Kontrolü

```
slot_compatible(slot_a, slot_b) =
  slot_a.flow_type == slot_b.flow_type
  AND slot_a.direction == OPPOSITE(slot_b.direction)
```

| Değişken | Tip | Değerler | Kaynak |
|----------|-----|---------|--------|
| `slot_a.flow_type` | Enum | PULSE, FLUID | OrganTypeResource |
| `slot_b.flow_type` | Enum | PULSE, FLUID | OrganTypeResource |
| `slot_a.direction` | Enum | NORTH, SOUTH, EAST, WEST | OrganTypeResource |
| `OPPOSITE()` | Fonksiyon | NORTH↔SOUTH, EAST↔WEST | Sabit |

**Beklenen çıktı**: `true` (bağlanabilir) veya `false` (bağlanamaz)
**Edge case**: Aynı organ iki slotunu birbirine bağlamaya çalışırsa her zaman `false` döner.

### Registry Geçerlilik Doğrulama

```
valid_registry() =
  ∀ organ: organ.id unique
  AND organ.biology_rule_id ∈ known_rule_ids
  AND len(organ.connection_slots) ≥ 1
  AND len(organ.creature_type_ids) ≥ 1
```

Başlatma sırasında bu koşullardan herhangi biri sağlanmazsa oyun hata fırlatır ve yükleme durur. Üretimde bu kontrol geçerli bir veri seti garantisi sağlar.

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| İki PULSE slotu aynı yöne sahip | `slot_compatible` → `false`; bağlantı reddedilir | Yönlü slotlar karşıt olmalı |
| Bir organ sıfır slotla tanımlanmış | Registry yüklemede `valid_registry()` başarısız, hata fırlatılır | Slot olmayan organ bağlanamaz — bulmacada kullanılamaz |
| `biology_rule_id` bilinmiyor | Registry yüklemede hata fırlatılır | Bilinmeyen kural çalıştırılamaz; Rule Engine tutarlılığı korunur |
| Aynı `id` iki ayrı organda | Registry yüklemede hata fırlatılır | ID benzersizliği Dictionary lookup için zorunlu |
| Organ hiçbir creature'a atanmamış | Registry yüklemede hata fırlatılır | Kullanılmayan organ varlığı veri hatasıdır |
| Oyuncu bir organı kendisiyle bağlamaya çalışır | Bağlantı reddedilir, görsel geri bildirim gösterilir | Aynı organ kendi slotlarıyla döngü oluşturamaz |

## Dependencies

| Sistem | Yön | Bağımlılık Türü | Arayüz |
|--------|-----|----------------|--------|
| Biology Rule Engine | Registry'ye bağlı | Sert — Rule Engine organ tanımları olmadan çalışamaz | `get_organ(id) → OrganTypeResource` |
| Failure Cascade System | Registry'ye bağlı | Sert — slot yapısı olmadan yayılma hesaplanamaz | `get_organ(id).connection_slots` |
| Puzzle Data System | Registry'ye bağlı | Sert — puzzle layout organ tanımlarına dayanır | `get_all_organs() → Array[OrganTypeResource]` |
| Specimen Viewer | Registry'ye bağlı | Sert — sprite olmadan render edilemez | `get_organ(id).sprite_normal / sprite_damaged` |
| Discovery Journal | Registry'ye bağlı | Yumuşak — journal çalışır ama isimler eksik | `get_organ(id).display_name` |

**Upstream bağımlılıklar**: Yok — Foundation layer sistemi.
**Downstream bağımlılar**: Biology Rule Engine, Failure Cascade System, Puzzle Data System, Specimen Viewer, Discovery Journal.

## Tuning Knobs

Registry statik veri olduğundan runtime tuning knob'ları yoktur. Tasarım zamanında ayarlanabilir değerler:

| Parametre | Mevcut Değer | Güvenli Aralık | Artışın Etkisi | Azalışın Etkisi |
|-----------|-------------|---------------|---------------|----------------|
| MVP organ tipi sayısı | 4 | 3–6 | Daha zengin bulmaca çeşitliliği, daha fazla içerik üretimi | Bulmaca kısıtlamaları azalır, yeterli çeşitlilik olmayabilir |
| Akış tipi sayısı (MVP) | 2 (PULSE, FLUID) | 2–4 | Daha sofistike bağlantı kısıtlamaları | Daha kolay öğrenme eğrisi |
| Slot sayısı (organ başına) | 2–4 (tipe göre) | 1–6 | Daha karmaşık bağlantı grafları | Daha basit bulmacalar; 1 slotlu organlar mümkün |

**Yeni organ tipi ekleme maliyeti**: Yeni `.tres` dosyası + 2 sprite + 1 VFX sahne + Biology Rule Engine'de kural tanımı. Kod değişikliği gerekmez.

## Visual/Audio Requirements

| Olay | Görsel Geri Bildirim | Ses Geri Bildirimi | Öncelik |
|------|---------------------|-------------------|---------|
| Organ sağlıklı | `sprite_normal` gösterilir | — | MVP |
| Organ arızalı | `sprite_damaged` + `failure_vfx_scene` oynatılır | Arıza ses imzası (Audio System'e devredilir) | MVP |
| Organ seçildi | Hafif parlama / outline efekti | Yumuşak seçim sesi | MVP |
| Slot uyumsuzluğu | Slot kırmızıya döner, bağlantı reddedilir | Kısa red sesi | MVP |

## UI Requirements

Registry doğrudan UI içermiyor — veri kataloğu. UI gereksinimleri Specimen Viewer ve Puzzle HUD GDD'lerinde tanımlanır. Registry'nin sağladığı veriler: `display_name` (organ isim etiketi için) ve `connection_slots` (slot göstergesi konumları için).

## Acceptance Criteria

- [ ] 4 MVP organ tipi tanımlı ve `valid_registry()` geçiyor
- [ ] Her organ tipi için `sprite_normal` ve `sprite_damaged` yükleniyor
- [ ] `get_organ(id)` geçerli ID için doğru `OrganTypeResource` döndürüyor
- [ ] `get_organ(id)` bilinmeyen ID için `null` döndürüyor ve hata fırlatmıyor
- [ ] `slot_compatible()` — 4 NORTH/PULSE↔SOUTH/PULSE kombinasyonu → `true`; 4 NORTH/PULSE↔NORTH/PULSE → `false`
- [ ] Duplicate `id` içeren `.tres` dosyası yüklemede hata fırlatıyor
- [ ] `biology_rule_id` bilinmeyen organ yüklemede hata fırlatıyor
- [ ] Registry yükleme süresi < 16ms (60fps frame budget'ını geçmemeli)
- [ ] Hiçbir organ verisi hardcoded değil — tüm değerler `.tres` dosyalarından geliyor
- [ ] GUT testi: `TestOrganTypeRegistry.gd` tüm yukarıdaki kriterleri otomatik doğruluyor

## Open Questions

| Soru | Sahibi | Hedef | Çözüm |
|------|--------|-------|-------|
| MVP'deki 4 organ tipi hangileri olacak? | Tasarımcı | Prototype başlamadan | Creature Definition System GDD'si ile birlikte tanımlanacak |
| PULSE ve FLUID dışında yeni akış tipi eklenecek mi? | Tasarımcı | V1 planlaması sırasında | Biology Rule Engine'in esnekliğine bağlı |
