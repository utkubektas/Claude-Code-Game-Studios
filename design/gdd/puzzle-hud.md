# Puzzle HUD

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given

## Overview

Puzzle HUD, oyuncunun bulmaca sırasında gördüğü tüm arayüz elemanlarını barındırır: başlık, envanter (organ inventory), RUN butonu ve sonuç mesajı alanı. Puzzle Data System'den güncel konfigürasyonu okur; Organ Repair Mechanic'e envanter tap'lerini iletmek için Touch Input Handler'a envanter alanlarını kaydeder; Run Simulation Controller'a RUN butonunu bağlar. Specimen Viewer ile birlikte ekranın tamamını oluşturur: Viewer üst %60'ı, HUD alt %40'ı kaplar.

## Player Fantasy

Arayüz sessizdir. Oyuncu neyi nereye koyacağını düşünürken ekranda dikkatini dağıtacak hiçbir şey yoktur. Envanter her zaman görünürdedir; RUN butonu her zaman basılabilir durumdadır (hazır olup olmadığına sistem karar verir, UI değil). Bulmaca numarası ve deneme sayısı varsa, oyuncuya ne kadar ilerlediğini sessizce hatırlatır.

## Detailed Design

### Core Rules

**HUD Bileşenleri (MVP):**

| Bileşen | Pozisyon | İçerik |
|---------|----------|--------|
| Başlık | Üst sol | `puzzle_resource.display_title` + bulmaca numarası |
| Deneme sayacı | Üst sağ | `attempt_count` — "Deneme: N" |
| Envanter grid | Alt bölge, `SCREEN_H * 0.62` — `SCREEN_H * 0.82` | 4 organ kartı (2×2 grid, MVP) |
| RUN butonu | Alt merkez, `SCREEN_H * 0.85` | "▶ RUN SIMULATION" |
| Sonuç alanı | RUN butonunun altı | Başarı/başarısızlık mesajı (Run Controller tetikler) |

**Envanter kartları:**

Her kart bir `OrganTypeResource` için:
- Renk swatchi (placeholder sprite yoksa)
- `display_name`
- Kısa açıklama (organ tipi hint — MVP'de sabit string)
- Dokunma alanı: Touch Input Handler'a `inventory_tapped(organ_id)` olarak kaydedilir

**RUN butonu:**

- Touch Input Handler'a `run_tapped()` olarak kaydedilir
- `LOCKED` durumda görsel olarak soluklaşır (alpha 0.5) — ama `lock()` Touch Input Handler'dan gelir, HUD yalnızca görseli günceller

**Güncelleme akışı:**

- `load_puzzle(puzzle_resource)` → başlık ve sayaç güncellenir
- `PuzzleDataSystem.organ_placed` sinyali → deneme sayacı güncellenmez (yalnızca RUN'da güncellenir)
- `RunSimulationController.attempt_incremented` sinyali → deneme sayacı güncellenir
- `RunSimulationController.puzzle_solved` → başarı mesajı gösterilir

### States and Transitions

| Durum | Açıklama |
|-------|----------|
| `ACTIVE` | Normal bulmaca — tüm butonlar aktif |
| `LOCKED` | RUN animasyonu — butonlar görsel olarak pasif |
| `SOLVED` | Başarı mesajı görünür, "Devam Et" butonu belirir |

### Interactions with Other Systems

| Sistem | Yön | Veri |
|--------|-----|------|
| Puzzle Data System | PDS → HUD | `display_title`, `attempt_count`, `organ_placed` sinyali |
| Organ Type Registry | Registry → HUD | `display_name`, renk (envanter kartları için) |
| Touch Input Handler | HUD → Handler | `register_area(inventory_N, rect, INVENTORY, organ_id)`, `register_area("run_btn", rect, RUN_BUTTON, null)` |
| Run Simulation Controller | Controller → HUD | `lock()` / `unlock()`, başarı/başarısızlık sinyalleri |
| Screen Navigation | HUD → Nav | "Devam Et" butonuna basınca `go_to_next_puzzle()` |

## Formulas

Matematik içermez — layout sabittir. Tek hesap: envanter kartı pozisyonları.

```
inventory_card_position(index) =
  base = Vector2(SCREEN_W * 0.05, SCREEN_H * 0.62)
  col  = index % 2
  row  = index / 2
  base + Vector2(col × CARD_W + col × GAP, row × CARD_H + row × GAP)
```

`CARD_W = SCREEN_W * 0.44`, `CARD_H = 70px`, `GAP = 8px` (MVP değerleri).

## Edge Cases

| Senaryo | Beklenen Davranış |
|---------|------------------|
| 4'ten fazla organ tipi varsa | Scroll veya sayfalama — MVP'de yok; 4 kart sabit |
| `display_title` çok uzunsa | Tek satıra sığdırılır, taşarsa kısaltılır (`…`) |
| `LOCKED` durumda RUN tapped | Touch Input Handler zaten yutacak; HUD ek kontrol yapmaz |
| Deneme sayacı 99'u geçerse | "99+" gösterilir |

## Dependencies

| Sistem | Yön | Tür |
|--------|-----|-----|
| Puzzle Data System | PDS → HUD | Hard |
| Organ Type Registry | Registry → HUD | Hard |
| Touch Input Handler | HUD → Handler | Hard |
| Run Simulation Controller | Controller → HUD | Hard |
| Screen Navigation | HUD → Nav | Hard |

## Tuning Knobs

| Parametre | Değer | Etki |
|-----------|-------|------|
| Envanter grid başlangıç Y | `SCREEN_H * 0.62` | HUD/Viewer sınırı |
| Kart boyutu | `SCREEN_W * 0.44 × 70px` | Büyütünce dokunma kolaylaşır; küçültünce Viewer alanı artar |
| RUN buton Y | `SCREEN_H * 0.85` | Başparmakla rahat ulaşım — alt bölge |

## Visual/Audio Requirements

| Eleman | Normal | Locked | Solved |
|--------|--------|--------|--------|
| RUN butonu | Beyaz metin, koyu bg | Alpha 0.5 | Gizlenir |
| Envanter kartı | Normal | Alpha 0.5 | Normal |
| Sonuç alanı | Boş | Boş | "✓ Specimen repaired" veya "✗ System failure" |
| Devam Et butonu | Gizli | Gizli | Görünür |

## Acceptance Criteria

- [ ] `load_puzzle()` → başlık ve bulmaca numarası doğru gösterilir
- [ ] RUN tapped → `run_tapped()` sinyali gönderilir
- [ ] Envanter kartı tapped → `inventory_tapped(correct_organ_id)` sinyali gönderilir
- [ ] `lock()` → RUN ve envanter kartları alpha 0.5
- [ ] `unlock()` → alpha normale döner
- [ ] `puzzle_solved` → başarı mesajı ve "Devam Et" butonu belirir
- [ ] Tüm dokunma alanları MIN_TOUCH_AREA (48×48px) standardını karşılar
- [ ] GUT testi: `TestPuzzleHUD.gd` sinyal akışlarını doğrular
