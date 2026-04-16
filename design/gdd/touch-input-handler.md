# Touch Input Handler

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given (doğru organ doğru yere gider — kontrol hata yaratmamalı)

## Overview

Touch Input Handler, oyuncunun ekrana dokunma eylemlerini oyun mantığına dönüştüren katmandır. Ham `InputEventScreenTouch` ve `InputEventScreenDrag` olaylarını alır; hangi UI elemanına (organ slotu, envanter öğesi, RUN butonu) dokunulduğunu belirler ve ilgili sisteme tip-güvenli bir event gönderir. Sistem Godot'un input event pipeline'ını sarmalar — üst sistemler ham koordinat hesabı yapmaz, yalnızca `slot_tapped(index)`, `inventory_tapped(organ_id)`, `run_tapped()` gibi anlamlı sinyaller alır. MVP'de yalnızca tek parmak dokunma (tap) desteklenir; sürükleme (drag) V1'de kanal yeniden bağlama için eklenir.

## Player Fantasy

Oyuncu ekranın herhangi bir köşesini düşünmeden dokunur ve oyun niyetini anlar. Yanlış slota yanlışlıkla dokunmaz; geniş dokunma alanları güvende hissettirir. Parmak kaldırıldığı an aksiyon gerçekleşir — gecikme yok, titreme yok. Kontrol sistemi oyuncunun zihninde yer kaplamaz; sadece "istediğimi yaptı" hissi kalır.

## Detailed Design

### Core Rules

**Desteklenen Dokunma Tipleri (MVP):**

| Tip | Gesture | Tetikler | Alıcı |
|-----|---------|---------|-------|
| Slot tap | Parmak basıp kaldır (≤ 200ms) | `slot_tapped(slot_index: int)` | Organ Repair Mechanic |
| Inventory tap | Parmak basıp kaldır (≤ 200ms) | `inventory_tapped(organ_id: String)` | Organ Repair Mechanic |
| RUN tap | Parmak basıp kaldır (≤ 200ms) | `run_tapped()` | Run Simulation Controller |
| Uzun basma | Parmak ≥ 500ms basılı | `long_press(position: Vector2)` | (MVP'de kullanılmaz — V1 inspect için rezerve) |

**Dokunma alanı hesabı:**

Her UI elemanının `Rect2` alanı (position + size) kayıt edilir. Dokunma noktası bu alanlara karşı test edilir. Çakışma varsa en üstteki (z-index yüksek) eleman kazanır.

**Tap eşiği:**

- Maksimum süre: 200ms (`press` → `release` arası)
- Maksimum hareket: 10px (bu aşılırsa tap değil, drag olarak işaretlenir — V1)
- Parmak hareketi 10px'i geçer ve ≥ 200ms sürerse → bu MVP'de yutulur (işlemsiz bırakılır)

**Input işleme akışı:**

1. `_input(event)` → `InputEventScreenTouch` yakala
2. `pressed == true` → `_touch_start_time = Time.get_ticks_msec()`, `_touch_start_pos = event.position`
3. `pressed == false` → `_duration = now - _touch_start_time`, `_delta = distance(pos, start_pos)`
4. `_duration ≤ 200ms AND _delta ≤ 10px` → tap olarak kabul et
5. Tap pozisyonunu kayıtlı alanlara karşı test et → ilgili signal gönder
6. Hiçbir alana isabet etmezse → yutulur (işlemsiz)

**Kayıt sistemi:**

Üst sistemler (Specimen Viewer, Puzzle HUD) kendi dokunma alanlarını şu metodla kaydeder:
```
register_area(id: String, rect: Rect2, type: TouchAreaType, payload: Variant)
```
`TouchAreaType`: `SLOT`, `INVENTORY`, `RUN_BUTTON`, `GENERIC`

### States and Transitions

| Durum | Açıklama | Giriş | Çıkış |
|-------|----------|-------|-------|
| `IDLE` | Dokunma bekleniyor | Başlangıç / önceki dokunma tamamlandı | `pressed == true` → `TOUCHING` |
| `TOUCHING` | Parmak ekranda | `pressed == true` alındı | `pressed == false` → tap/drag ayrımı → `IDLE` |
| `LOCKED` | Input devre dışı (RUN animasyonu sırasında) | Run Simulation Controller `lock_input()` çağırdı | `unlock_input()` → `IDLE` |

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Organ Repair Mechanic | Handler → Mechanic | `slot_tapped(index)`, `inventory_tapped(id)` | Tap tanınca |
| Run Simulation Controller | Handler → Controller | `run_tapped()` | RUN butonu tap'inde |
| Run Simulation Controller | Controller → Handler | `lock_input()` / `unlock_input()` | RUN animasyonu başında/sonunda |
| Specimen Viewer | Viewer → Handler | `register_area(...)` | Viewer kurulumda alanları kaydeder |
| Puzzle HUD | HUD → Handler | `register_area(...)` | HUD kurulumda alanları kaydeder |

## Formulas

### F1 — Tap Tanıma

```
is_tap(event_start, event_end) =
  (event_end.time - event_start.time) ≤ TAP_MAX_DURATION_MS (200)
  AND distance(event_end.position, event_start.position) ≤ TAP_MAX_DELTA_PX (10)
```

### F2 — Alan İsabeti (Hit Test)

```
hit_test(tap_position, areas) =
  areas
    .filter(area → area.rect.has_point(tap_position))
    .sort_by(area → area.z_index, descending)
    .first()  // En üstteki alan; yoksa null
```

### F3 — Minimum Dokunma Alanı (Mobil Güvenliği)

```
MIN_TOUCH_AREA = 48px × 48px  // Apple HIG ve Material Design standardı
```

Hiçbir kayıtlı alan bu boyuttan küçük olamaz. Küçük alanlar yükleme sırasında uyarıyla büyütülür.

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| İki parmak aynı anda | İlk parmak işlenir, ikincisi yutulur | MVP tek parmak; çok dokunuşlu engel |
| `LOCKED` durumda tap | Yutulur, sinyal gönderilmez | RUN animasyonu sırasında yanlışlıkla input önlenir |
| Kayıtlı alan 48×48px altında | Yükleme uyarısı, alan MIN_TOUCH_AREA'ya büyütülür | Mobil dokunma güvenliği |
| Tap iki alanın sınırında (overlap) | En yüksek z-index kazanır | F2 kuralı |
| `register_area()` aynı id ile iki kez | İkinci çağrı birincinin üzerine yazar | UI yeniden çizildiğinde alanların güncellenmesi |
| Parmak alan dışına sürüklenip bırakılır | Tap kabul edilmez (delta > 10px) | Sürükleme niyeti; istem dışı seçimi önler |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Organ Repair Mechanic | Handler → Mechanic | Hard | `slot_tapped(int)`, `inventory_tapped(String)` sinyalleri |
| Run Simulation Controller | Handler → Controller | Hard | `run_tapped()` sinyali; `lock_input()` / `unlock_input()` metotları |
| Specimen Viewer | Viewer → Handler | Hard | `register_area(id, rect, type, payload)` |
| Puzzle HUD | HUD → Handler | Hard | `register_area(id, rect, type, payload)` |

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artınca | Azalınca |
|-----------|-------------|----------------|---------|---------|
| `TAP_MAX_DURATION_MS` | 200ms | 150–300ms | Uzun basışlar tap sayılır; istem dışı tetikleme artar | Hızlı dokunuşlar kaçar; oyuncular "neden seçmedi" der |
| `TAP_MAX_DELTA_PX` | 10px | 5–20px | Kısa sürüklemeler tap sayılır; seçim hassasiyeti azalır | Küçük titremeler tap'i iptal eder; frustration artar |
| `MIN_TOUCH_AREA` | 48×48px | 44–64px | Daha kolay dokunma; alan çakışması artar | Daha zor dokunma; hata oranı yükselir |
| `LONG_PRESS_THRESHOLD_MS` | 500ms | 400–700ms | Uzun basma daha az tetiklenir | İstem dışı long-press artar |

## Visual/Audio Requirements

Touch Input Handler görsel üretmez. Ancak tap onayı için Puzzle HUD veya Specimen Viewer'dan beklenen görsel geri bildirimler:

| Olay | Beklenen Görsel | Sahip Sistem |
|------|----------------|-------------|
| Slot tapped | Slot çerçevesi sarı yanar (seçili) | Specimen Viewer |
| Inventory tapped | Envanter öğesi hafif pulse | Puzzle HUD |
| RUN tapped | Buton basılı görünümü (press state) | Puzzle HUD |

Dokunma sesini Audio System yönetir (V1).

## UI Requirements

Touch Input Handler'ın doğrudan UI gereksinimi yoktur. Dokunma alanlarının görsel boyutları Specimen Viewer ve Puzzle HUD GDD'lerinde tanımlanır. Tek kısıt: her kayıtlı alanın `MIN_TOUCH_AREA` (48×48px) standardını karşılaması.

## Acceptance Criteria

- [ ] Slot'a tap → `slot_tapped(correct_index)` sinyali gönderilir
- [ ] Envanter öğesine tap → `inventory_tapped(correct_organ_id)` sinyali gönderilir
- [ ] RUN butonuna tap → `run_tapped()` sinyali gönderilir
- [ ] `LOCKED` durumda herhangi bir tap → hiçbir sinyal gönderilmez
- [ ] 200ms üzeri basma → tap tanınmaz
- [ ] 10px üzeri hareketle bırakma → tap tanınmaz
- [ ] İki parmak aynı anda → yalnızca biri işlenir, crash yok
- [ ] 40×40px alan (min altı) → yükleme uyarısı, alan 48×48'e büyütülür
- [ ] `register_area()` aynı id → güncelleme, hata yok
- [ ] Fiziksel Android cihazda tap hata oranı < %2 (20 tap / 18+ doğru isabet)
- [ ] GUT testi: `TestTouchInputHandler.gd` sinyal akışlarını simüle ederek doğrular
