# Organ Repair Mechanic

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given; Discovery Through Deduction

## Overview

Organ Repair Mechanic, oyuncunun bir creature slotundaki yanlış organı tanılayıp doğrusuyla değiştirdiği iki adımlı etkileşimi yönetir: önce bir slot seçilir, ardından envanterdeki bir organ seçilerek o slota yerleştirilir. Sistem Touch Input Handler'dan `slot_tapped` ve `inventory_tapped` sinyallerini alır; seçim durumunu takip eder; geçerli bir yerleştirme kararlaştırıldığında Puzzle Data System'e `set_organ()` çağrısı yapar ve Specimen Viewer'ı günceller. Oyuncu aynı slota iki kez tıklarsa seçimi iptal eder. Hiçbir sürükleme yoktur (MVP); envanterdeki her organ her slota yerleştirilebilir — geçerlilik kontrolü Run Simulation Controller'a aittir.

## Player Fantasy

Oyuncu bozuk slota dokunur — bir amaç doğar. Envanterden doğru organı seçer — yerleşir. Bu iki dokunuş arasındaki gerilim oyunun kalbini oluşturur. Sistem hiçbir zaman "yapamassın" demez; yanlış organı da yerleştirmeye izin verir — asıl ceza RUN anında gelir. Kontrol hafif, niyetli, ve hatasız hissettirmeli.

## Detailed Design

### Core Rules

**İki adımlı seçim modeli:**

1. **Adım 1 — Slot seçimi:**
   - `slot_tapped(index)` gelir
   - `selected_slot == null` → `selected_slot = index`; Specimen Viewer'a `set_slot_selected(index, true)` gönderilir
   - `selected_slot == index` (aynı slot tekrar) → seçim iptal edilir; `selected_slot = null`; `set_slot_selected(index, false)`
   - `selected_slot == other_index` (farklı slot) → eski seçim kaldırılır, yeni slot seçilir

2. **Adım 2 — Organ yerleştirme:**
   - `inventory_tapped(organ_id)` gelir
   - `selected_slot == null` → yutulur (slottan önce envanter seçildi)
   - `selected_slot != null` → `PuzzleDataSystem.set_organ(selected_slot, organ_id)` çağrılır; seçim sıfırlanır

**Envanter seçimi slotu sıfırlar:** Organ yerleştirildikten sonra `selected_slot = null` ve `set_slot_selected(prev_slot, false)` çağrılır. Oyuncu sonraki değişiklik için yeniden slot seçmek zorundadır.

**Geçerlilik kısıtı:** Herhangi bir organ herhangi bir slota yerleştirilebilir. Organ-slot uyumu kontrolü yapılmaz — bu Biology Rule Engine ve Failure Cascade System'in RUN anındaki görevi. Repair Mechanic yalnızca fiziksel yerleştirmeyi yönetir.

### LOCKED (PRE-ATT) — Ossuric Terminus

**Ossuric Terminus (Slot 4 / chartreuse organ)** başlangıçta envanterde kilitlidir. Oyuncu ilk RUN denemesini (ATT 01) tamamlamadan bu organı seçemez.

**Kural:**
- Puzzle yüklendiğinde `ossuric` organ kartı `LOCKED_PRE_ATT` durumunda açılır
- Kart görünür ama etkileşilemez; üzerinde `LOCKED` etiketi gösterilir
- ATT 01 tamamlanınca (RUN butonuna basılıp simulation cycle bitince, sonuçtan bağımsız) kilit kalkar
- Kilit kalktıktan sonra kart normal `IDLE` durumuna girer; `LOCKED_PRE_ATT` durumuna geri dönülmez

**Gerekçe:** Bu tasarım kararı, oyuncuyu önce mevcut 3 organla bir hipotez çalıştırmaya zorlar. Terminus rolünü anlamadan doğrudan doğru organı yerleştirmek mekanik bir kazara başarıyı mümkün kılar — LOCKED kural bunu engeller ve deductive flow'u korur.

**Implementasyon notu:**
- `inventory_tapped("ossuric")` geldiğinde `LOCKED_PRE_ATT` aktifse yutulur
- `attempt_count` (Puzzle Data System'den okunur): `>= 1` ise kilit kaldırılır
- Kilit durumu Run Simulation Controller'dan gelen `on_attempt_completed()` sinyaliyle güncellenir

### States and Transitions

| Durum | Açıklama | Giriş | Çıkış |
|-------|----------|-------|-------|
| `IDLE` | Hiç slot seçili değil | Başlangıç / seçim iptal / organ yerleşti | `slot_tapped(index)` → `SLOT_SELECTED` |
| `SLOT_SELECTED` | Bir slot seçili, organ bekleniyor | `slot_tapped(index)` yeni slot | `inventory_tapped(id)` → yerleştirme → `IDLE`; `slot_tapped(same)` → iptal → `IDLE`; `slot_tapped(other)` → slot değişimi (SLOT_SELECTED kalır) |
| `LOCKED` | RUN animasyonu sırasında etkileşim yok | Run Controller `lock()` | `unlock()` → önceki duruma dön |
| `LOCKED_PRE_ATT` | Ossuric Terminus kart kilidi — yalnızca bu organ için | Puzzle yüklenince (ossuric için) | `on_attempt_completed()` → `IDLE`'a geçer; geri dönüşü yoktur |

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Touch Input Handler | Handler → Mechanic | `slot_tapped(int)`, `inventory_tapped(String)` | Her tap'te |
| Puzzle Data System | Mechanic → PDS | `set_organ(slot_index, organ_id)` | Organ yerleştirilince |
| Specimen Viewer | Mechanic → Viewer | `set_slot_selected(index, bool)` | Seçim değişince |
| Run Simulation Controller | Controller → Mechanic | `lock()` / `unlock()` | RUN başında/sonunda |

## Formulas

### F1 — Seçim Güncelleme

```
on_slot_tapped(index):
  IF selected_slot == null:
    selected_slot = index
    viewer.set_slot_selected(index, true)
  ELSE IF selected_slot == index:
    viewer.set_slot_selected(index, false)
    selected_slot = null
  ELSE:
    viewer.set_slot_selected(selected_slot, false)
    selected_slot = index
    viewer.set_slot_selected(index, true)
```

### F2 — Organ Yerleştirme

```
on_inventory_tapped(organ_id):
  IF selected_slot == null:
    return  // yutulur
  puzzle.set_organ(selected_slot, organ_id)
  viewer.set_slot_selected(selected_slot, false)
  selected_slot = null
  emit_signal("organ_placed", selected_slot, organ_id)
```

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| Envanter seçimi slottan önce | Yutulur; `selected_slot == null` koruması | Akış sırası: önce slot, sonra organ |
| Slot seçiliyken RUN'a basılır | `lock()` gelir; seçim görsel olarak korunur ama etkileşim kapanır; RUN sonrası seçim sıfırlanır | RUN animasyonu sırasında değişiklik yapılmamalı |
| Aynı organı aynı slota yerleştirme | `set_organ()` çağrılır; Puzzle Data System aynı değeri yazar — görsel değişmez | Geçerli işlem; gereksiz ama zararsız |
| `LOCKED` durumda tap | Yutulur; Touch Input Handler zaten `LOCKED` sinyal göndermez | Çift güvenlik katmanı |
| `LOCKED_PRE_ATT` — ossuric tapped | `inventory_tapped("ossuric")` yutulur; kart görsel olarak kilitli gösterilir | Attempt 01 öncesi erişim engeli |
| Attempt 01 tamamlandı, kilit kalktı | `on_attempt_completed()` → `LOCKED_PRE_ATT` → `IDLE`; kart etkileşime açılır | Tek yönlü geçiş; bir kez açıldı mı kapanmaz |
| Oyuncu puzzle'ı yeniden yüklerse | Ossuric yeniden `LOCKED_PRE_ATT`'e mi girer? → **Hayır.** `attempt_count >= 1` ise başlangıçta da açık gelir | Puzzle Data System'deki attempt_count kalıcıdır |
| Organ yerleştirme sırasında `set_organ()` başarısız olursa | Seçim sıfırlanmaz; hata loglanır; oyuncu tekrar deneyebilir | Puzzle Data System reddetti (bilinmeyen organ id vb.) |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Touch Input Handler | Handler → Mechanic | Hard | `slot_tapped(int)`, `inventory_tapped(String)` sinyalleri |
| Puzzle Data System | Mechanic → PDS | Hard | `set_organ(slot_index: int, organ_id: String)` |
| Specimen Viewer | Mechanic → Viewer | Hard | `set_slot_selected(index: int, selected: bool)` |
| Run Simulation Controller | Controller → Mechanic | Hard | `lock()` / `unlock()` / `on_attempt_completed()` |
| Puzzle Data System | Mechanic ← PDS (read) | Hard | `attempt_count: int` — ossuric kilidini açmak için okunur |

## Tuning Knobs

Bu sistem davranışsal olduğundan sayısal parametre yoktur. Tek ayarlanabilir değer:

| Parametre | Mevcut Değer | Etki |
|-----------|-------------|------|
| Seçim sonrası otomatik sıfırlama | `true` (organ yerleşince sıfırlar) | `false` yapılırsa oyuncu aynı slota birden fazla organ deneyebilir; test için kullanışlı |

## Visual/Audio Requirements

| Olay | Görsel | Ses | Sahip |
|------|--------|-----|-------|
| Slot seçildi | Sarı çerçeve — Specimen Viewer yönetir | Tap sesi (V1) | Specimen Viewer |
| Organ yerleşti | Yeni sprite anında — Specimen Viewer yönetir | Yerleştirme sesi (V1) | Specimen Viewer |
| Seçim iptal edildi | Çerçeve kalkar — Specimen Viewer yönetir | — | Specimen Viewer |

Organ Repair Mechanic'in kendi görsel/ses üretimi yoktur.

## UI Requirements

Organ Repair Mechanic doğrudan UI üretmez. Envanter alanının görsel tasarımı Puzzle HUD GDD'sinde tanımlanır. Tek UI kısıtı: `inventory_tapped(organ_id)` sinyalini gönderecek envanter butonlarının Puzzle HUD tarafından kurulmuş olması ve Touch Input Handler'a kayıtlı olması.

## Acceptance Criteria

- [ ] Slot tapped → `selected_slot` güncellenir, Specimen Viewer sarı çerçeve alır
- [ ] Aynı slot tekrar tapped → seçim iptal edilir, çerçeve kalkar
- [ ] Farklı slot tapped → eski çerçeve kalkar, yeni slot seçilir
- [ ] Inventory tapped (slot seçiliyken) → `PuzzleDataSystem.set_organ()` çağrılır, seçim sıfırlanır
- [ ] Inventory tapped (slot seçili değilken) → hiçbir şey olmaz
- [ ] `LOCKED` durumda slot/inventory tap → hiçbir şey olmaz
- [ ] Organ yerleştirme → `organ_placed(slot_index, organ_id)` sinyali emit edilir
- [ ] RUN sonrası `unlock()` → mechanic normal çalışmaya döner
- [ ] GUT testi: `TestOrganRepairMechanic.gd` state machine geçişlerini doğrular
- [ ] Puzzle yüklendiğinde ossuric kart `LOCKED_PRE_ATT` durumunda başlar — `inventory_tapped("ossuric")` yutulur
- [ ] ATT 01 tamamlandıktan sonra ossuric kart aktif olur — `inventory_tapped("ossuric")` işlenir
- [ ] `attempt_count >= 1` ile yüklenen puzzle'da ossuric başlangıçta açıktır
- [ ] `LOCKED_PRE_ATT` durumdan `IDLE`'a geçiş tek yönlüdür; geri dönüşü yoktur

## Agency Design Note — Interaction Model Difference

Tasarım ajansının prototype'ı (Specimen Prototype.html) **ters etkileşim sırasını** kullanır:
1. Önce envanterdeki organ kartına tıklanır (organı seçer)
2. Ardından slota tıklanır (organı yerleştirir)

Bizim GDD'mizdeki model ise:
1. Önce slota tıklanır (hedefi seçer)
2. Ardından envanterden organ seçilir (yerleştirir)

**Mevcut karar:** Slot-first model GDD canonical'dır (bu doküman). Ajans prototype'ındaki inventory-first model, oyuncuya "ne yerleştireceğini" değil "nereye yerleştireceğini" soran yönelim farkından kaynaklanmaktadır. Her iki model UX açısından geçerlidir; V1 playtesting'de her ikisi de test edilebilir.

**Açık ADR:** Eğer playtesting inventory-first'ın daha sezgisel hissettirdiğini gösterirse, `/architecture-decision` ile resmi karar dökümante edilmelidir.

## Open Questions

| Soru | Sahip | Hedef |
|------|-------|-------|
| V1'de birden fazla yanlış organ olduğunda seçim akışı değişecek mi? | Designer | V1 planlamasında — mevcut iki adımlı model yeterli, slot sayısı artar |
| Slot-first mi, inventory-first mi? (Ajans prototype'ından fark) | Designer + Playtesting | V1 playtesting sonrası ADR ile karar verilecek |
