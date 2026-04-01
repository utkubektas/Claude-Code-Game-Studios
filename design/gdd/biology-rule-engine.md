# Biology Rule Engine

> **Status**: Designed (pending review)
> **Author**: Design session
> **Last Updated**: 2026-04-01
> **Implements Pillar**: Alien Logic, Learnable Rules; Mastery Is Earned, Not Given

## Overview

Biology Rule Engine, Specimen'in deterministic biyoloji simülasyon motorudur. Run Simulation Controller tarafından tetiklendiğinde, creature'ın mevcut organ konfigürasyonunu alır ve her organın biyoloji kuralını sırayla çalıştırır. Her kural, organın aldığı akış girdilerini inceler ve beklentileri karşılanıyorsa çıktı akışı üretir; karşılanmıyorsa arıza işaretler. Kurallar hibrit mimaride tanımlanır: çoğu kural `BiologyRuleResource` (.tres) veri dosyasıyla, karmaşık kurallar opsiyonel bir GDScript evaluator ile. Sonuç her zaman deterministiktir — aynı girdi her zaman aynı çıktıyı üretir. Failure Cascade System arıza yayılımını, Run Simulation Controller ise görsel sekansı yönetir.

## Player Fantasy

Biology Rule Engine oyuncu tarafından hiç görülmez — ama her şey onun üstünde durur. "Run" butonuna basmadan önceki o gerilim, kurallara olan güven ya da kuşkudan kaynaklanır. Bir organ değiştirdiğinde ve run'a bastığında creature canlandığında, Rule Engine'in tutarlı ve öğrenilebilir kurallar çalıştırdığının kanıtıdır bu. Oyuncu "Sistem adil, ben doğru düşünürsem çözerim" diye hissediyorsa, Rule Engine işini yapmış demektir.

## Detailed Design

### Core Rules

#### BiologyRuleResource Veri Yapısı

Her kural, `assets/data/rules/` altında bir `BiologyRuleResource` (.tres) dosyasıyla tanımlanır:

| Alan | Tip | Açıklama |
|------|-----|---------|
| `id` | String | `OrganTypeResource.biology_rule_id` ile eşleşen benzersiz kimlik |
| `display_name` | String | Debug için okunabilir isim |
| `required_input_types` | `Array[String]` | INPUT slotlarında bulunması gereken flow_type'lar |
| `required_input_count` | int | Aktif sinyal taşıması gereken INPUT slot sayısı (0 = kaynak organ) |
| `forbidden_excess` | bool | `true` ise gerekenden fazla aktif INPUT → EXCESS_INPUT arızası |
| `requires_all_types` | bool | `true` = tüm tipler zorunlu (AND); `false` = herhangi biri yeterli (OR) |
| `output_flow_type` | String | Başarı durumunda OUTPUT slotlarından üretilen flow_type |
| `output_count` | int | Sinyal gönderecek OUTPUT slot sayısı (index sırasıyla) |

#### MVP Organ Tipleri (Röle Biyolojisi Paketi)

**Organ 1: Vordex Emitter** (`biology_rule_id: "rule_vordex_emitter"`)
- Biyoloji kavramı: Bir creature'ın tüm biyoelektrik sinyalinin kaynağı. Girdi almadan çıktı üretir — biyolojik pacemaker.
- Slot düzeni: 0 INPUT, 1 OUTPUT (SOUTH, PULSE)
- `required_input_count: 0` → her zaman başarılı; arıza üretemez
- Kural: `output_flow_type: "PULSE"`, `output_count: 1`

**Organ 2: Valdris Gate** (`biology_rule_id: "rule_valdris_gate"`)
- Biyoloji kavramı: Biyolojik AND kapısı. İki sinyal kanalı aynı anda aktifken geçirir; biri kesilirse çöker.
- Slot düzeni: 2 INPUT (WEST + EAST, PULSE), 1 OUTPUT (SOUTH, PULSE)
- `required_input_count: 2`, `forbidden_excess: true`
- Kural: Her iki INPUT aktifse çıktı üretir; biri eksikse MISSING_INPUT; ikiden fazlası EXCESS_INPUT

**Organ 3: Thrennic Splitter** (`biology_rule_id: "rule_thrennic_splitter"`)
- Biyoloji kavramı: Biyolojik sinyal çoğaltıcısı. Tek bir PULSE girdiyi iki bağımsız çıktıya kopyalar.
- Slot düzeni: 1 INPUT (NORTH, PULSE), 2 OUTPUT (WEST + EAST, PULSE)
- `required_input_count: 1`, `forbidden_excess: true`, `output_count: 2`
- Kural: 1 aktif girdi → 2 çıktı; 0 girdi → MISSING_INPUT; 2+ girdi → EXCESS_INPUT

**Organ 4: Ossuric Terminus** (`biology_rule_id: "rule_ossuric_terminus"`)
- Biyoloji kavramı: Biyolojik sinyal sonlandırıcı. Sinyali "tüketir" ve çıktı üretmez. Her sinyal dalı bir Terminus'ta bitmek zorundadır.
- Slot düzeni: 1 INPUT (NORTH, PULSE), 0 OUTPUT
- `required_input_count: 1`, `forbidden_excess: false`, `output_count: 0`
- Kural: ≥1 aktif PULSE girdi alırsa başarılı (sinyal kaybolur); 0 girdi → MISSING_INPUT

#### Değerlendirme Algoritması (Graph Traversal)

**Giriş**: `EvaluationContext` — her organ örneği için: `organ_type_id`, bağlı slot'lar, kanal sinyal durumları.
**Çıkış**: `EvaluationResult` — her organ için `OrganResult` (`passed: bool`, `failure_code: String`, `output_signals: Dictionary`).

1. **Kuyruk oluşturma**: Organ grafını topolojik sırayla sırala (kaynak organlar önce). Döngü tespit edilirse → `CYCLE_DETECTED` hatası (bulmaca authoring hatası).

2. **Kaynak sinyalleri ekim**: INPUT slotu olmayan veya Vordex Emitter olan organlara başlangıç sinyali ata.

3. **Her organ için sırayla değerlendir**:
   - 3a. INPUT slot'larındaki aktif sinyal sayısını hesapla → `active_inputs`
   - 3b. `active_inputs < required_input_count` → `MISSING_INPUT`, başarısız
   - 3c. `forbidden_excess == true` AND `active_inputs > required_input_count` → `EXCESS_INPUT`, başarısız
   - 3d. `input_types_satisfied` kontrolü → başarısızsa `WRONG_FLOW_TYPE`
   - 3e. Başarılıysa: ilk `output_count` OUTPUT slot'una `signal = true` ata; başarısızsa tüm OUTPUT'lar `false`

4. **Yayılım**: Kuyruktaki sonraki organ, önceki organların OUTPUT sinyallerini INPUT olarak alır.

5. **Sonuç**: `OrganResult` listesini Run Simulation Controller'a döndür.

**Not**: Algoritma O(V+E)'dir. MVP için (≤12 organ, ≤20 bağlantı) tek frame'de tamamlanır.

### States and Transitions

| Durum | Açıklama | Giriş Koşulu | Çıkış Koşulları |
|-------|---------|-------------|----------------|
| `IDLE` | Motor pasif, bağlam yok | Oyun başlangıcı veya önceki değerlendirme tamamlandı | `begin_evaluation(context)` çağrısı → `BUILDING_QUEUE` |
| `BUILDING_QUEUE` | Topolojik sıralama yapılıyor | `begin_evaluation()` alındı | Sıralama başarılı → `EVALUATING`; döngü tespit → `ERROR` |
| `EVALUATING` | Organlar sırayla değerlendiriliyor | Kuyruk hazır | Tüm organlar işlendi → `RETURNING_RESULTS`; null referans → `ERROR` |
| `RETURNING_RESULTS` | `EvaluationResult` çağrıcıya iletiliyor | Tüm organlar işlendi | Run Controller alındı bildirdi → `IDLE` |
| `ERROR` | Yapısal hata (döngü, bilinmeyen kural) | `BUILDING_QUEUE` veya `EVALUATING`'de kritik hata | Hata loglanır, motor `IDLE`'a sıfırlanır — oyuncu ulaşamaz |

Tüm geçişler senkrondur. Async durum yoktur.

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|---------|
| Run Simulation Controller | Controller → Engine | `EvaluationContext`: organ örnekleri, tip ID'leri, slot bağlantıları, kanal sinyal durumları | Her run denemesinde, senkron |
| Organ Type Registry | Engine → Registry | `OrganTypeResource` lookup (`biology_rule_id` için) | `EVALUATING` sırasında, organ başına |
| Run Simulation Controller | Engine → Controller | `EvaluationResult`: tüm `OrganResult` listesi | `RETURNING_RESULTS` sırasında |
| Failure Cascade System | Engine → Cascade | `passed = false` olan `OrganResult`'ların alt kümesi + `failure_code` | `RETURNING_RESULTS` sonrası |
| Discovery Journal (V1) | Engine → Journal | `(organ_type_id, failure_code/PASS)` çiftleri | Her run sonrası |

**Kritik kontrat**: Rule Engine canlı sahne ağacından okuma yapmaz. Anlık görüntü (snapshot) üzerinde çalışır. Bu, deterministik garantinin temelidir: `evaluate(context)` her zaman aynı girdi için aynı çıktıyı üretir.

## Formulas

### F1 — Kural Geçiş Koşulu

```
rule_passes(organ, context) =
  active_inputs(organ, context) >= rule.required_input_count
  AND (NOT rule.forbidden_excess OR active_inputs == rule.required_input_count)
  AND input_types_satisfied(organ, context, rule)
```

| Değişken | Tip | Aralık | Kaynak |
|----------|-----|--------|--------|
| `active_inputs` | int | 0 – (INPUT slot sayısı) | INPUT slotlarından gelen sinyal sayımı |
| `required_input_count` | int | 0 – 4 | `BiologyRuleResource` |
| `forbidden_excess` | bool | true/false | `BiologyRuleResource` |

**Örnek — Valdris Gate, iki girdi aktif**: `2 >= 2 AND (NOT true OR 2 == 2) AND true = true` → PASS
**Örnek — Valdris Gate, bir girdi aktif**: `1 >= 2 = false` → MISSING_INPUT

### F2 — Girdi Tipi Tatmini

```
input_types_satisfied(organ, context, rule) =
  IF rule.requires_all_types:
    ∀ t ∈ rule.required_input_types:
      ∃ slot ∈ INPUT_slots: slot.flow_type == t AND signal[slot] == true
  ELSE:
    ∃ t ∈ rule.required_input_types:
      ∃ slot ∈ INPUT_slots: slot.flow_type == t AND signal[slot] == true
```

**MVP notu**: 4 MVP organının tamamı `requires_all_types = false` ve `required_input_types = ["PULSE"]` (veya boş) kullanır. Çok akış tipli organlar V1'de eklendiğinde bu formül zaten hazırdır.

### F3 — Çıktı Sinyal Ataması

```
output_signal(slot_id, organ, result) =
  IF result.passed:
    slot_id ∈ first(output_count, OUTPUT_slots_by_index) → true
    aksi halde → false
  ELSE:
    false (tüm OUTPUT slotları için)
```

**Örnek — Thrennic Splitter geçti**: `output_count = 2`, her iki OUTPUT slotu → `true`
**Örnek — Thrennic Splitter başarısız**: Her iki OUTPUT slotu → `false`, aşağısı sessiz kalır

### F4 — DAG Geçerlilik Kontrolü

```
valid_dag(graph) =
  derinlik_önce_arama(graph) geri-kenar üretmiyor
```

MVP boyutlarında (≤12 organ, ≤20 bağlantı): O(32) işlem. Tek frame bütçesinin içinde.

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| Organ grafında döngü var | `CYCLE_DETECTED` hatası, değerlendirme durur | Bulmaca authoring hatası; oyuncu hiç ulaşmamalı |
| Bilinmeyen `biology_rule_id` | `ERROR` durumuna geçiş, hata loglanır | Rule Engine kural olmadan değerlendirme yapamaz |
| Null organ örneği grafte | `ERROR` durumuna geçiş | Bozuk bağlam; authoring doğrulaması geçmeli |
| Vordex Emitter olmayan puzzle | `NO_SOURCE` global hatası; `EvaluationResult` boş döner | En az bir sinyal kaynağı zorunludur |
| Tüm organlar başarısız | `EvaluationResult`'da tümü `passed = false`; `Failure Cascade System` tüm grafı işler | Geçerli çıktı; Run Controller dramatik tam arıza sekansı tetikler |
| Ossuric Terminus 2+ girdi alıyor | `forbidden_excess = false` → PASS; ek sinyal "tüketilir" | Terminus hoşgörülüdür — sinyal kayıplarına izin verir |
| Thrennic Splitter 2+ girdi alıyor | `forbidden_excess = true` → EXCESS_INPUT | Splitter çoğaltıcıdır, birleştirici değildir |
| OUTPUT slotu olan organ bir sonraki organa bağlı değil | Kaybolur; sonraki organ `active_inputs`'ta o sinyali görmez | Bağlantısız çıktı sessizce düşer — bulmaca tasarımı sorumluluğu |

## Dependencies

| Sistem | Yön | Bağımlılık Türü | Arayüz |
|--------|-----|----------------|--------|
| Organ Type Registry | Engine → Registry | Sert — `OrganTypeResource` lookup zorunlu | `OrganTypeRegistry.get_organ(id)` |
| Run Simulation Controller | Controller → Engine | Sert — tek genel metot | `evaluate(context) → EvaluationResult` |
| Failure Cascade System | Engine → Cascade | Sert — arıza yayılımı için `failure_code` zorunlu | `EvaluationResult` (filtered, `passed = false`) |
| Creature Definition System | Indirect | Kanal yapısı `EvaluationContext` içinden gelir; engine doğrudan okumaz | `EvaluationContext.channels` |
| Discovery Journal (V1) | Engine → Journal | Yumuşak | `(organ_type_id, failure_code/PASS)` çiftleri |

**Upstream**: Organ Type Registry.
**Downstream**: Failure Cascade System, Run Simulation Controller, Discovery Journal (V1).

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artışın Etkisi | Azalışın Etkisi |
|-----------|-------------|---------------|---------------|----------------|
| `required_input_count` (organ başına) | 0–2 (tipe göre) | 0–4 | Daha kısıtlayıcı kurallar; daha zor bulmacalar | Daha kolay çözüm; daha az deduction |
| `output_count` (organ başına) | 0–2 (tipe göre) | 0–3 | Daha fazla sinyal dallanması; daha karmaşık grapler | Doğrusal zincirler; bulmaca çeşitliliği azalır |
| MVP organ tipi sayısı | 4 | 3–6 | Daha zengin kural kombinasyonları | Çok az çeşitlilik; bulmacalar tekrar eder |
| `forbidden_excess` kuralları | 2/4 oran (Gate + Splitter) | — | Daha katı yerleşim kısıtlamaları | Daha hoşgörülü; yanlış yerleşim fark edilmez |

**Yeni kural ekleme maliyeti**: Yeni `.tres` dosyası + Organ Type Registry'de yeni organ kaydı. Rule Engine kodu değişmez.

## Visual/Audio Requirements

Rule Engine doğrudan görsel çıktı üretmez — Run Sequence VFX sistemi `EvaluationResult`'ı okuyarak animasyonu yönetir. Engine'in ürettiği veriler:
- `passed = true` organlar → aktivasyon sekansı
- `failure_code = MISSING_INPUT` → sessiz sinyal kanalı görseli
- `failure_code = EXCESS_INPUT` → aşırı yüklenme VFX
- `failure_code = WRONG_FLOW_TYPE` → tip uyumsuzluğu VFX

## UI Requirements

Rule Engine doğrudan UI içermiyor. Puzzle HUD, `EvaluationResult`'ı Run Simulation Controller üzerinden alarak hangi organların başarısız olduğunu gösterir.

## Acceptance Criteria

- [ ] `evaluate(context)` aynı context ile iki kez çağrıldığında aynı `EvaluationResult` döndürüyor (determinizm garantisi)
- [ ] Vordex Emitter → Valdris Gate → Ossuric Terminus zinciri, tüm bağlantılar aktifken PASS üretiyor
- [ ] Valdris Gate, 1 aktif girdiyle `MISSING_INPUT` arıza kodu üretiyor
- [ ] Thrennic Splitter, 2 aktif girdiyle `EXCESS_INPUT` arıza kodu üretiyor
- [ ] Ossuric Terminus, 2 aktif girdiyle PASS üretiyor (`forbidden_excess = false`)
- [ ] Döngü içeren graf `CYCLE_DETECTED` hatası üretiyor, engine `IDLE`'a sıfırlanıyor
- [ ] Bilinmeyen `biology_rule_id` `ERROR` hatası üretiyor, oyun çökmüyor
- [ ] Vordex Emitter olmayan puzzle `NO_SOURCE` hatası üretiyor
- [ ] Değerlendirme süresi < 1ms (12 organ, 20 bağlantı için)
- [ ] GUT testi: `TestBiologyRuleEngine.gd` tüm yukarıdaki kriterleri otomatik doğruluyor

## Open Questions

| Soru | Sahibi | Hedef | Çözüm |
|------|--------|-------|-------|
| GDScript override evaluator tam olarak hangi senaryolarda gerekecek? | Programcı | V1 organ tipleri tasarlanırken | İlk 4 MVP organı saf veri-driven; ilk override ihtiyacı ortaya çıkınca arayüz tasarlanacak |
| 4 organ tipiyle kaç farklı benzersiz bulmaca konfigürasyonu üretilebilir? | Tasarımcı | MVP playtesting öncesi | 10 bulmaca hazırlanırken kombinasyon analizi yapılacak |
