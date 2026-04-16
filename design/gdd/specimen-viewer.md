# Specimen Viewer

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Discovery Through Deduction; The Run Button Moment

## Overview

Specimen Viewer, oyuncunun alien creature'ı incelediği görsel katmandır. Creature Definition System'den gelen anatomik veriyi (silüet, slot pozisyonları, kanal yapısı) ve Puzzle Data System'den gelen güncel organ konfigürasyonunu birleştirerek ekranda bir creature anatomisi render eder. Her organ slotunu dokunulabilir bir alan olarak Touch Input Handler'a kaydeder. Hangi slotun yanlış organa sahip olduğu `sprite_damaged` ile görsel olarak işaretlenir — oyuncu "nerede bozuk" bilgisini görür, "ne takmalı" sorusunu kendisi çözer. Organ Repair Mechanic bir organ değiştirdiğinde Specimen Viewer anlık güncellenir.

## Player Fantasy

Oyuncu ekranda tuhaf bir varlık görür — tanıdık ama yabancı, organik ama hiç görmediği türden. Biyolojik kanallar organlar arasında akar; bir slot diğerlerinden farklı, hasar almış görünümde. O slota parmak değdirmek doğal hissettiriyor — incelemek, dokunmak, ne olduğunu anlamak istiyor. Her organ değişiminde yaratık canlı gibi tepki veriyor: renk değişiyor, kanal güncelleniyor. RUN'a basıldığında bu anatominin tüm ışığı ya birden yanar ya da birden söner.

## Detailed Design

### Core Rules

**Render Bileşenleri:**

1. **Creature Silhouette** — `sprite_silhouette` (CreatureTypeResource), creature'ın vücut şeklini arka plan olarak çizer. Sabit; runtime'da değişmez.

2. **Slot Channel Lines** — `slot_channels` (CreatureTypeResource), organ slotları arasındaki biyolojik kanalları çizer:
   - `PULSE` kanalı: ince, elektrik mavisi çizgi
   - `FLUID` kanalı: kalın, yeşil/sarı organik tüp
   - Çizgiler slot pozisyonları arası düz bağlantı (MVP); eğri/animasyonlu V1

3. **Organ Slots** — Her `OrganSlotDefinition` için bir slot widget'ı:
   - Pozisyon: `organ_slot.world_position` (creature merkezinden offset)
   - Boyut: sabit 80×80px (MVP)
   - İçerik: aktif organ `sprite_normal` veya `sprite_damaged`
   - Seçili durumda: sarı çerçeve (Organ Repair Mechanic tarafından tetiklenir)

4. **Hasar Görseli:** Bir slottaki organ `healthy_configuration`'dan farklıysa → `sprite_damaged` göster. Doğruysa → `sprite_normal` göster. Bu hesap Puzzle Data System'den gelen `current_configuration` ile `healthy_configuration` karşılaştırılarak yapılır.

**Güncelleme akışı:**

1. `load_creature(creature_type_id)` → silüet ve kanalları çiz, slot widget'larını oluştur
2. `refresh_slots(current_configuration)` → her slot için `sprite_normal`/`sprite_damaged` belirle
3. `set_slot_selected(slot_index, bool)` → seçili slot sarı çerçeve alır / kaybeder
4. Puzzle Data System'den `organ_placed` sinyali → `refresh_slots()` çağrılır

**Touch area kaydı:**

Her slot widget'ı oluşturulduğunda Touch Input Handler'a kaydedilir:
```
touch_handler.register_area(
  id = "slot_%d" % slot_index,
  rect = Rect2(world_position - Vector2(40, 40), Vector2(80, 80)),
  type = TouchAreaType.SLOT,
  payload = slot_index
)
```

### States and Transitions

| Durum | Açıklama | Giriş | Çıkış |
|-------|----------|-------|-------|
| `EMPTY` | Creature yüklenmedi | Başlangıç | `load_creature()` → `ACTIVE` |
| `ACTIVE` | Creature görünür, etkileşim açık | `load_creature()` | `lock_interaction()` → `LOCKED`; `unload()` → `EMPTY` |
| `LOCKED` | RUN animasyonu sırasında etkileşim kapalı | Run Controller `lock_interaction()` | `unlock_interaction()` → `ACTIVE` |

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Creature Definition System | CDS → Viewer | `sprite_silhouette`, `organ_slots`, `slot_channels` | `load_creature()` çağrısında |
| Organ Type Registry | Registry → Viewer | `sprite_normal`, `sprite_damaged` | `refresh_slots()` her çağrısında |
| Puzzle Data System | PDS → Viewer | `current_configuration`, `healthy_configuration` | `organ_placed` sinyalinde |
| Touch Input Handler | Viewer → Handler | `register_area(slot_id, rect, SLOT, slot_index)` | Slot widget'ları oluşturulunca |
| Organ Repair Mechanic | Mechanic → Viewer | `set_slot_selected(index, bool)` | Oyuncu slot seçince/bırakınca |
| Run Simulation Controller | Controller → Viewer | `lock_interaction()`, `unlock_interaction()` | RUN başında ve sonunda |
| Run Sequence VFX | VFX → Viewer | Slot widget referansları (VFX efekt pozisyonu için) | RUN animasyonu sırasında |

## Formulas

### F1 — Slot Hasar Durumu

```
slot_is_damaged(slot_index, current_config, healthy_config) =
  current_config[slot_index] != healthy_config[slot_index]
```

`true` → `sprite_damaged` göster; `false` → `sprite_normal` göster.

### F2 — Slot Dünya Pozisyonu

```
slot_screen_position(slot_index) =
  creature_center_screen + organ_slots[slot_index].world_position
```

`creature_center_screen` = ekran merkezine yerleştirilen creature anchor noktası (MVP'de sabit = `Vector2(SCREEN_W/2, SCREEN_H * 0.4)`).

### F3 — Kanal Çizgi Noktaları

```
channel_line(channel) =
  start = slot_screen_position(channel.from_slot_index) + Vector2(40, 40)  // slot merkezi
  end   = slot_screen_position(channel.to_slot_index)   + Vector2(40, 40)
```

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| `sprite_normal` veya `sprite_damaged` null ise | Renkli placeholder rect gösterilir (Organ Type Registry'deki renk) | Asset yüklenmeden önce crash olmaz |
| Slot pozisyonları ekran dışına çıkarsa | Clamp edilir: `clamp(pos, Vector2(40,40), screen_size - Vector2(40,40))` | Küçük ekranlarda slot kaybolmaz |
| `load_creature()` mevcut creature üzerine çağrılırsa | Önce `unload()` çalışır, sonra yeni creature yüklenir | Touch alanları sıfırlanır; eski kayıtlar silinir |
| `refresh_slots()` `LOCKED` durumda çağrılırsa | Görsel güncellenir, etkileşim açılmaz | Görsel tutarlılık; lock yalnızca touch'ı etkiler |
| Kanal kendi üstüne çiziliyorsa (from == to) | Çizgi çizilmez, hata loglanır | Creature Definition System bunu zaten yakalar; savunmacı |
| `healthy_configuration` eksik slot içeriyorsa | Hata loglanır, eksik slot "unknown" sprite gösterir | Creature Definition System'in doğrulaması bunu önler; fallback |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Creature Definition System | CDS → Viewer | Hard | `get_creature(id) → CreatureTypeResource` |
| Organ Type Registry | Registry → Viewer | Hard | `get_organ(id).sprite_normal / sprite_damaged` |
| Puzzle Data System | PDS → Viewer | Hard | `current_configuration`, `healthy_configuration`; sinyal: `organ_placed` |
| Touch Input Handler | Viewer → Handler | Hard | `register_area(id, rect, type, payload)` |
| Organ Repair Mechanic | Mechanic → Viewer | Hard | `set_slot_selected(index, bool)` |
| Run Simulation Controller | Controller → Viewer | Hard | `lock_interaction()` / `unlock_interaction()` |
| Run Sequence VFX | VFX → Viewer | Soft | Slot pozisyonları (VFX spawn noktası) |

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artınca | Azalınca |
|-----------|-------------|----------------|---------|---------|
| Slot boyutu | 80×80px | 64–100px | Daha büyük hedef; anatomy görünümü değişir | Dokunma zorlaşır; MIN_TOUCH_AREA altına düşemez |
| Creature anchor Y | `SCREEN_H * 0.4` | 0.3–0.5 | Creature yukarı kayar; envanter için alan açılır | Creature aşağı kayar; başlık alanı genişler |
| Kanal çizgi kalınlığı PULSE | 2px | 1–4px | Daha belirgin biyoloji görünümü | Daha ince, daha az dikkat çekici |
| Kanal çizgi kalınlığı FLUID | 4px | 2–8px | Daha organik görünüm | PULSE ile ayrım azalır |
| Seçili slot çerçeve rengi | Sarı (#FFD700) | Tasarımcı kararı | — | — |
| Hasar slot tonu | `sprite_damaged` (varlık tasarımcısı belirler) | — | — | — |

## Visual/Audio Requirements

| Olay | Görsel | Ses | Öncelik |
|------|--------|-----|---------|
| Creature yüklendiğinde | Silüet soldan fade-in (0.3s) | Ambient alien sesi (V1) | MVP |
| Slot hasarlı gösterildiğinde | `sprite_damaged`, hafif kırmızı tint overlay | Hasar ambient (V1) | MVP |
| Slot seçildiğinde | Sarı çerçeve anında belirir (no animation, MVP) | Tap sesi (V1) | MVP |
| Organ değiştirildiğinde | Yeni sprite anında güncellenir | Yerleştirme sesi (V1) | MVP |
| RUN başarı | Run Sequence VFX yönetir | Aktivasyon sesi (V1) | MVP |
| RUN başarısız | Başarısız slot(lar) kırmızı flash — Run Sequence VFX yönetir | Hata sesi (V1) | MVP |

## UI Requirements

Specimen Viewer ekranın üst 60%'ını kaplar (MVP layout):
- Creature silüeti ekran genişliğinin %80'i kadar, dikey olarak ortalanmış
- Organ slotları creature anatomisine göre pozisyonlanmış
- Kanal çizgileri slotlar arası görünür
- Alt sınır: envanter alanı ve RUN butonu için `SCREEN_H * 0.6` altı ayrılmış

## Acceptance Criteria

- [ ] `load_creature("vorrkai")` → silüet ve 4 slot ekranda doğru pozisyonlarda görünür
- [ ] `slot_is_damaged()` doğru → slot `sprite_damaged` gösterir
- [ ] `slot_is_damaged()` yanlış → slot `sprite_normal` gösterir
- [ ] `set_slot_selected(2, true)` → slot 2 sarı çerçeve alır
- [ ] `set_slot_selected(2, false)` → çerçeve kalkar
- [ ] `organ_placed` sinyali → `refresh_slots()` tetiklenir, görsel anında güncellenir
- [ ] `LOCKED` durumda tap → Touch Input Handler sinyali gönderilmez; görsel güncelleme çalışır
- [ ] Tüm slotlar `MIN_TOUCH_AREA` (48×48px) standardını karşılar
- [ ] `sprite_normal` null → placeholder rect görünür, crash yok
- [ ] Slot pozisyonu ekran dışında → clamp çalışır, slot görünür kalır
- [ ] GUT testi: `TestSpecimenViewer.gd` sinyal akışını ve hasar hesabını doğrular
