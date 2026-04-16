# Puzzle Data System

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given; Alien Logic, Learnable Rules

## Overview

Puzzle Data System, Specimen'deki her bulmacayı tanımlayan ve runtime sırasında oyuncunun bulmaca üzerindeki değişikliklerini takip eden sistemdir. İki katmandan oluşur: **statik veri** (her bulmacayı `.tres` dosyasında tanımlayan `PuzzleResource`) ve **runtime durumu** (oyuncunun slotlara koyduğu organları bellekte tutan `PuzzleInstance`). Çözüm doğruluğu `CreatureTypeResource.healthy_configuration` ile karşılaştırılarak belirlenir — çözüm verisi bulmaca dosyasında tutulmaz, Creature Definition System'den türetilir. Organ Repair Mechanic, Run Simulation Controller ve Puzzle HUD bu sistemin runtime durumunu okur; doğrudan sahne ağacına değil, bu sisteme danışır.

## Player Fantasy

Bu sistem oyuncu tarafından görülmez. Oyuncunun hissettiği şey şudur: her bulmaca önceki bilgiyi kullanarak yeni bir zorluk sunar; başarılı çözümden sonra bir sonraki bulmaca açılır ve oyuncu "bir şey öğrendim, şimdi daha hazırım" hisseder. Sistem arka planda bu kurguyu taşır — oyuncunun yaptığı her organ değişikliği anında kaydedilir, geri alınabilir, ve RUN anında silinmez.

## Detailed Design

### Core Rules

**Statik Veri — `PuzzleResource` (.tres)**

Her bulmaca `assets/data/puzzles/` altında numaralı bir dosyada tanımlanır (`puzzle_01.tres`, `puzzle_02.tres`, …):

| Alan | Tür | Açıklama |
|------|-----|---------|
| `puzzle_index` | int | Sıra numarası (1–10 MVP) |
| `display_title` | String | UI'da görünen başlık (e.g., "Specimen 01-A") |
| `creature_type_id` | String | Hangi creature arketipi kullanılıyor |
| `starting_configuration` | `Dictionary[int, String]` | slot_index → organ_type_id — oyunun başladığı hatalı durum |
| `hint_slot_index` | int | Hangi slot bozuk olduğuna dair ipucu (-1 = ipucu yok) |
| `unlock_after_index` | int | Hangi bulmaca çözülünce bu açılır (0 = başlangıçta açık) |

**Çözüm doğruluğu hesabı**: `starting_configuration` ile `healthy_configuration` (Creature Definition System'den) arasında tam olarak 1 slot farklılığı olması MVP garantisidir. Yükleme sırasında doğrulanır.

**Runtime Durumu — `PuzzleInstance`**

Oyuncu bir bulmacayı açtığında `PuzzleInstance` oluşturulur (`.tres` dosyasından değil, bellekte):

| Alan | Tür | Açıklama |
|------|-----|---------|
| `puzzle_resource` | `PuzzleResource` | Kaynak veri referansı |
| `current_configuration` | `Dictionary[int, String]` | Oyuncunun güncel organ yerleşimi |
| `attempt_count` | int | Bu bulmacada kaç kez RUN'a basıldı |
| `is_solved` | bool | Çözüldü mü? |

**İşlem akışı:**

1. `load_puzzle(index)` → `PuzzleResource` yükle → `current_configuration = starting_configuration.duplicate()`
2. `set_organ(slot_index, organ_type_id)` → `current_configuration[slot_index] = organ_type_id`
3. `get_current_configuration()` → Run Simulation Controller ve Puzzle HUD bu metodu çağırır
4. RUN tetiklendiğinde `attempt_count += 1`
5. `check_solved()` → `current_configuration == healthy_configuration` ise `is_solved = true`
6. `reset()` → `current_configuration = starting_configuration.duplicate()`, attempt_count korunur

**Bulmaca sıralaması**: Lineer. `puzzle_sequence` bir Array — her eleman bir `puzzle_index`. Oyuncu yalnızca en son çözülen bulmacadan bir sonrakini görebilir.

### States and Transitions

| Durum | Açıklama | Giriş Koşulu | Çıkış Koşulları |
|-------|----------|-------------|-----------------|
| `UNLOADED` | Aktif bulmaca yok | Oyun başlangıcı veya bulmaca kapandı | `load_puzzle(index)` → `ACTIVE` |
| `ACTIVE` | Oyuncu bulmacayı çözüyor | `load_puzzle()` çağrıldı | RUN → `EVALUATING`; çıkış → `UNLOADED` |
| `EVALUATING` | RUN basıldı, Biology Rule Engine değerlendiriyor | Run Simulation Controller tetikledi | Sonuç döndü → `ACTIVE` (başarısız) veya `SOLVED` |
| `SOLVED` | Oyuncu bulmacayı doğru çözdü | `check_solved() == true` | Sonraki bulmacaya geç → `UNLOADED` |

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Creature Definition System | CDS → Puzzle | `healthy_configuration`, `organ_slots`, `slot_channels` | `load_puzzle()` sırasında |
| Organ Type Registry | Registry → Puzzle | `get_organ(id)` doğrulaması | Yükleme ve `set_organ()` sırasında |
| Organ Repair Mechanic | Mechanic → Puzzle | `set_organ(slot, id)` çağrısı | Oyuncu organ değiştirdiğinde |
| Run Simulation Controller | Controller → Puzzle | `get_current_configuration()`, `attempt_count += 1` | RUN her tetiklendiğinde |
| Puzzle HUD | HUD → Puzzle | `get_current_configuration()`, `is_solved`, `attempt_count` | Her frame veya değişiklikte |
| Save/Load System | Puzzle → Save | `puzzle_index`, `is_solved`, `attempt_count` | Bulmaca çözülünce veya oyun kapatılınca |

## Formulas

### F1 — Çözüm Kontrolü

```
is_solved(instance) =
  ∀ slot_index ∈ healthy_configuration.keys():
    instance.current_configuration[slot_index] == healthy_configuration[slot_index]
```

### F2 — MVP Bulmaca Geçerlilik Doğrulaması (yükleme zamanı)

```
valid_puzzle(puzzle, creature) =
  puzzle.creature_type_id ∈ CreatureDefinitionSystem
  AND len(puzzle.starting_configuration) == len(creature.organ_slots)
  AND count_differences(puzzle.starting_configuration, creature.healthy_configuration) == 1
  AND ∀ organ_id ∈ puzzle.starting_configuration.values(): organ_id ∈ OrganTypeRegistry
```

`count_differences` = kaç slot değeri farklı. MVP'de her zaman 1 olmalı.

### F3 — Sıradaki Bulmaca

```
next_puzzle(current_index) =
  IF current_index < MAX_PUZZLE_INDEX:
    → current_index + 1
  ELSE:
    → END_OF_SEQUENCE
```

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| `starting_configuration` ile `healthy_configuration` arasında 0 fark | Yükleme hatası — bulmaca zaten çözülü durumda başlar | Puzzle authoring hatası; yükleme zamanı yakalanır |
| `starting_configuration` ile `healthy_configuration` arasında 2+ fark | Yükleme hatası — MVP tek-hata garantisini bozar | F2 doğrulaması durdurur |
| Oyuncu slotan yanlış bir organ koyup RUN'a basar | `attempt_count` artar, `is_solved = false` devam eder | Geçerli oyun akışı |
| `set_organ()` bilinmeyen `organ_type_id` ile çağrılır | Reddedilir, loglam yapılır, `current_configuration` değişmez | Organ Type Registry doğrulaması |
| Oyuncu bulmacayı sıfırlamadan çıkarsa | Save/Load `current_configuration`'ı saklar; geri dönünce kaldığı yerden devam eder | MVP kapsamı dışı — Save/Load GDD'sinde ele alınacak |
| Son bulmaca çözülürse | `next_puzzle()` → `END_OF_SEQUENCE`; oyun krediler veya bitiş ekranını tetikler | Screen Navigation sistemi bu akışı yönetir |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Creature Definition System | CDS → Puzzle | Hard | `get_creature(id) → CreatureTypeResource` |
| Organ Type Registry | Registry → Puzzle | Hard | `get_organ(id) → OrganTypeResource` (doğrulama) |
| Organ Repair Mechanic | Mechanic → Puzzle | Hard | `set_organ(slot_index, organ_type_id)` |
| Run Simulation Controller | Controller → Puzzle | Hard | `get_current_configuration()`, `increment_attempts()` |
| Puzzle HUD | HUD → Puzzle | Hard | `get_current_configuration()`, `is_solved`, `attempt_count` |
| Save/Load System | Puzzle → Save | Soft | Puzzle durumu persist edilir (V1'de tamamlanacak) |

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artınca | Azalınca |
|-----------|-------------|----------------|---------|---------|
| MVP bulmaca sayısı | 10 | 5–20 | Daha uzun ilk deneyim; daha fazla içerik üretim maliyeti | Daha kısa; test için yeterli ama ticari değil |
| Hatalı organ sayısı (per puzzle) | 1 | 1–3 | Daha zor deduction; çok olursa overwhelm | Basit; öğrenme eğrisi yumuşak |
| `hint_slot_index` kullanım oranı | TBD (puzzle authoring kararı) | 0%–100% | Daha kolay; deduction azalır | Daha zor; yeni oyuncular takılabilir |

## Visual/Audio Requirements

Puzzle Data System görsel üretmez. Veri değişikliklerini signal üzerinden iletir:

| Sinyal | Tetikleyici | Alıcı |
|--------|------------|-------|
| `organ_placed(slot_index, organ_id)` | `set_organ()` başarılı | Puzzle HUD, Specimen Viewer |
| `puzzle_solved` | `check_solved() == true` | Run Simulation Controller, Screen Navigation |
| `puzzle_reset` | `reset()` çağrıldı | Puzzle HUD, Specimen Viewer |

## UI Requirements

Puzzle Data System doğrudan UI üretmez. Puzzle HUD bu sistemin verilerini tüketir. Gereksinim detayları Puzzle HUD GDD'sinde tanımlanacaktır.

## Acceptance Criteria

- [ ] `load_puzzle(1)` başarıyla yüklenir, `current_configuration == starting_configuration`
- [ ] `set_organ(2, "valdris_gate")` → `current_configuration[2] == "valdris_gate"`
- [ ] `check_solved()` → `true` yalnızca `current_configuration == healthy_configuration` olduğunda
- [ ] `check_solved()` → `false` tek hatalı organ varken
- [ ] `reset()` → `current_configuration` başlangıç durumuna döner, `attempt_count` sıfırlanmaz
- [ ] `valid_puzzle()` — 0 fark → yükleme hatası; 2+ fark → yükleme hatası; 1 fark → geçerli
- [ ] Bilinmeyen `organ_type_id` ile `set_organ()` → reddedilir, konfigürasyon değişmez
- [ ] 10 bulmacalık sekans lineer yüklenir; puzzle_10 çözününce `END_OF_SEQUENCE` döner
- [ ] `get_current_configuration()` aynı frame içinde iki kez çağrıldığında aynı sonuç döner
- [ ] GUT testi: `TestPuzzleDataSystem.gd` tüm kriterleri otomatik doğrular

## Open Questions

| Soru | Sahip | Hedef | Çözüm |
|------|-------|-------|-------|
| `hint_slot_index` UI'da nasıl gösterilecek — işaret mi, renk mi, metin mi? | UX Designer | Puzzle HUD GDD tasarımında | Puzzle HUD GDD'sinde ele alınacak |
| V1'de çok-hatalı bulmacalar geldiğinde `count_differences == 1` kısıtı nasıl gevşetilecek? | Designer | V1 planlamasında | `valid_puzzle()` formülünde max_faults parametresi eklenir |
