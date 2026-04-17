# Run Sequence VFX

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: The Run Button Moment

## Overview

Run Sequence VFX, Run Simulation Controller'ın komutlarını alarak RUN sonrası görsel ve zamansal sekansı yönetir. Üç farklı animasyon sekansı sunar: başarı (yeşil biolüminesans cascade, slottan slota yayılır), organ başarısızlığı (başarısız slotlarda eş zamanlı kırmızı flash), ve yapısal başarısızlık (tüm ekran karardı + "STRUCTURAL FAILURE" metni). Her sekans tamamlandığında `vfx_complete` sinyali gönderilir. MVP'de animasyonlar GDScript ile elde edilir (Tween); V1'de Godot ParticleSystem2D ve shader geçişleri eklenir.

## Player Fantasy

RUN'a basıldıktan sonra creature cevap verir. Başarıda organlar sırayla uyanır — biolüminesans bir dalga yaratık boyunca akar. Başarısızlıkta aynı anda tüm hatalı organlar kırmızı yanar — hangisinin sorunlu olduğu görsel olarak netleşir. Yapısal çöküşte ekran titreyip kararır. Bu görüntüler oyuncunun "Neden?" sorusunu sormadan anlayabileceği kadar okunabilir ve keyifli izlenebilecek kadar tatmin edicidir.

## Detailed Design

### Core Rules

**Sekans 1: Başarı (`play_success`)**

1. Creature center'dan başlayan yumuşak beyaz pulse (0.1s)
2. Her slot sırayla (topological order, 180ms aralık) yeşil glow alır
3. Son slot yandıktan 0.3s sonra tüm creature soluk yeşil tonda kalır
4. `vfx_complete` emit edilir (~2.0s toplam)

**Sekans 2: Organ Başarısızlığı (`play_organ_failure`)**

1. Tüm başarısız slotlar aynı anda kırmızı flash alır (0.0s gecikme)
2. Kırmızı flash 3 kez titrer (150ms periyot)
3. Hatalı slotlar soluk kırmızı tonda kalır (0.5s)
4. `vfx_complete` emit edilir (~1.5s toplam)

**Sekans 3: Yapısal Başarısızlık (`play_structural_failure`)**

1. Ekran 0.2s içinde %60 kararır (overlay)
2. Tüm slotlar mor/turuncu flash (yapısal hata rengi — organ hatasından ayırt edici)
3. "STRUCTURAL FAILURE" metni ekran ortasında belirir (fade-in 0.3s)
4. 1.0s beklenir
5. Overlay ve metin yavaşça solar (0.5s)
6. `vfx_complete` emit edilir (~2.5s toplam)

**MVP uygulama notu:** Tüm animasyonlar Godot `Tween` ile; `sprite_normal`/`sprite_damaged` modülasyon yerine `ColorRect` modulation kullanılır. Gerçek sprite entegrasyonu V1.

### States and Transitions

| Durum | Açıklama |
|-------|----------|
| `IDLE` | Animasyon yok |
| `PLAYING` | Sekans çalışıyor; `play_*()` çağrıları yutulur |
| `COMPLETE` | `vfx_complete` emit edildi, `IDLE`'a dönüldü |

### Interactions with Other Systems

| Sistem | Yön | Veri |
|--------|-----|------|
| Run Simulation Controller | Controller → VFX | `play_success(positions)`, `play_organ_failure(slots)`, `play_structural_failure(code)` |
| Run Simulation Controller | VFX → Controller | `vfx_complete` sinyali |
| Specimen Viewer | VFX → Viewer | Slot widget referansları (pozisyon ve renk modifikasyonu için) |

## Formulas

### F1 — Başarı Cascade Zamanlaması

```
slot_glow_delay(slot_index, topological_order) =
  topological_order.index_of(slot_index) × CASCADE_STAGGER_MS (180)
```

### F2 — Flash Titreme

```
flash_cycle(n, period_ms) =
  FOR i IN range(n):
    tween.set_color(RED).wait(period_ms / 2)
    tween.set_color(DARK_RED).wait(period_ms / 2)
```

## Edge Cases

| Senaryo | Beklenen Davranış |
|---------|------------------|
| `play_*()` `PLAYING` durumunda çağrılır | Yutulur — mevcut sekans tamamlanır |
| Slot pozisyonu null | O slot atlanır; sekans devam eder |
| Tween kesilirse (scene değişimi vb.) | `vfx_complete` zorla emit edilir |

## Dependencies

| Sistem | Yön | Tür |
|--------|-----|-----|
| Run Simulation Controller | Controller → VFX | Hard |
| Specimen Viewer | VFX → Viewer | Hard |

## Tuning Knobs

| Parametre | Değer | Aralık |
|-----------|-------|--------|
| `CASCADE_STAGGER_MS` | 180ms | 100–300ms |
| Başarı toplam süre | ~2.0s | 1.5–3.0s |
| Başarısızlık flash sayısı | 3 | 2–5 |
| Yapısal failure toplam süre | ~2.5s | 2.0–4.0s |

## Visual/Audio Requirements

| Olay | Renk | Ses (V1) |
|------|------|---------|
| Başarı glow | `#00FF88` (biolüminesans yeşil) | Aktivasyon sesi |
| Organ failure flash | `#FF3333` (kırmızı) | Hata sesi |
| Yapısal failure | `#AA44FF` (mor) + ekran kararması | Sistem çöküş sesi |

## Acceptance Criteria

- [ ] `play_success()` → tüm slotlar yeşil cascade ile yanar, ~2.0s sonra `vfx_complete`
- [ ] `play_organ_failure([2])` → yalnızca slot 2 kırmızı flash alır, ~1.5s sonra `vfx_complete`
- [ ] `play_structural_failure("CYCLE_DETECTED")` → ekran kararır, metin belirir, ~2.5s sonra `vfx_complete`
- [ ] `PLAYING` durumunda ikinci `play_*()` çağrısı → yutulur
- [ ] 60fps'de animasyon frame drop olmadan çalışır
- [ ] GUT testi: `TestRunSequenceVFX.gd` `vfx_complete` zamanlamasını doğrular
