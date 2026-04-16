# Failure Cascade System

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: The Run Button Moment; Discovery Through Deduction

## Overview

Failure Cascade System, Biology Rule Engine'in ürettiği ham `EvaluationResult`'ı oyuncu için anlamlı bir hata paketine dönüştüren transformation katmanıdır. Her RUN denemesinde tek bir kez tetiklenir; başarısız organları tespit eder, hata türünü belirler (organ bazlı `ORGAN` ya da sistem genelini etkileyen `STRUCTURAL`), ve bu bilgiyi Run Simulation Controller'a iletir. Controller bu paketi kullanarak doğru görsel tepkiyi tetikler: organ başarısızlıklarında o organlar kırmızı yanar; `CYCLE_DETECTED` veya `NO_SOURCE` gibi yapısal hatalarda tüm ekran çöküyor. Sistem kendi başına hiçbir şey render etmez — yalnızca sınıflandırır ve iletir.

## Player Fantasy

Oyuncu RUN'a bastığında içinde bir gerilim oluşur: "Doğru mu yaptım?" Bu soruya verilen görsel cevap — kırmızı flash, titreyen ekran ya da yeşil cascade — tamamen Failure Cascade System'in ürettiği pakete dayanır. Sistem doğru çalışırsa oyuncu "o organı değiştirmeliydim" diye tam olarak anlar; yanlış çalışırsa hiçbir şey öğrenmez. Discovery Through Deduction pillar'ının kalbi burada: hata mesajı değil, hata yeri bilgiyi taşır.

## Detailed Design

### Core Rules

**Veri Yapıları:**

`FailureCascadeResult` — sistemin çıktısı:

| Alan | Tür | Açıklama |
|------|-----|---------|
| `failure_type` | `FailureType` enum | `NONE` (hepsi geçti) / `ORGAN` / `STRUCTURAL` |
| `failed_organs` | `Array[OrganFailureRecord]` | Sadece `ORGAN` tipinde dolu |
| `structural_code` | String | Sadece `STRUCTURAL` tipinde dolu (`"CYCLE_DETECTED"`, `"NO_SOURCE"`) |

`OrganFailureRecord`:

| Alan | Tür | Açıklama |
|------|-----|---------|
| `slot_index` | int | Hangi slotta başarısız organ |
| `failure_code` | String | `MISSING_INPUT`, `EXCESS_INPUT`, `WRONG_FLOW_TYPE` |

**İşlem Algoritması** (her RUN'da bir kez çalışır):

1. `EvaluationResult`'ı al
2. Yapısal hata var mı? (`CYCLE_DETECTED`, `NO_SOURCE`) → `STRUCTURAL` döndür, dur
3. `passed = false` olan tüm organları topla → `failed_organs` listesi
4. Liste boşsa → `NONE` (başarı), dur
5. Liste doluysa → `ORGAN` tipinde paket döndür

**Öncelik kuralı**: STRUCTURAL her zaman ORGAN'dan önce gelir — yapısal hata varken organ listesi anlamlı değildir.

### States and Transitions

Sistem durumsuz (stateless) — her çağrıda sıfırdan çalışır, iç state tutmaz. `process(eval_result)` → `FailureCascadeResult` dönüşümü senkron ve saf (pure function).

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Biology Rule Engine | Engine → Cascade | `EvaluationResult` | Her RUN sonrası |
| Organ Type Registry | Cascade → Registry | `get_organ(id)` | Gerekirse slot doğrulaması için |
| Run Simulation Controller | Cascade → Controller | `FailureCascadeResult` | Sınıflandırma tamamlanınca |

## Formulas

### F1 — Failure Type Classification

```
classify(eval_result) =
  IF eval_result.structural_code != "":
    → FailureType.STRUCTURAL
  ELSE IF ∃ organ ∈ eval_result.organ_results: organ.passed == false:
    → FailureType.ORGAN
  ELSE:
    → FailureType.NONE
```

### F2 — Failed Organ Collection

```
collect_failures(eval_result) =
  [OrganFailureRecord(organ.slot_index, organ.failure_code)
   FOR organ IN eval_result.organ_results
   IF organ.passed == false]
```

### F3 — Structural Priority

```
result_priority(failure_type) =
  STRUCTURAL > ORGAN > NONE
```

STRUCTURAL varsa ORGAN listesi hesaplanmaz (erken çıkış).

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| `EvaluationResult` null gelirse | `STRUCTURAL` döner, `structural_code = "NULL_RESULT"`, hata loglanır | Sistemin çökmemesi gerekir |
| Hem yapısal hem organ hatası aynı anda | `STRUCTURAL` önceliklidir, `failed_organs` boş döner | F3 kuralı: STRUCTURAL > ORGAN |
| Tüm organlar başarısız | `ORGAN` tipi, `failed_organs` tüm organları içerir | Geçerli çıktı; Run Controller dramatik tam-çöküş sekansı tetikler |
| Hiçbir organ başarısız değil | `NONE` döner | Başarı — Run Controller success animasyonu başlatır |
| `failed_organs` listesi boş ama `failure_type == ORGAN` | Debug build'de assert hata — üretimde `NONE`'a düşürülür | İmkânsız durum; savunmacı programlama |
| Bilinmeyen `failure_code` string | Olduğu gibi iletilir, loglanır | Yeni failure code eklendiğinde geriye dönük uyumlu |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Biology Rule Engine | Engine → Cascade | Hard | `EvaluationResult` (organ sonuçları + yapısal hata kodu) |
| Organ Type Registry | Cascade → Registry | Soft | `get_organ(id)` — yalnızca slot doğrulaması gerektiğinde |
| Run Simulation Controller | Cascade → Controller | Hard | `FailureCascadeResult` — sınıflandırma tamamlanınca iletilir |

## Tuning Knobs

Bu sistem bir transformation katmanı olduğundan tasarımcı tarafından ayarlanacak parametre yoktur. Görsel tepki süreleri (flash duration, shake intensity) Run Sequence VFX sistemine aittir. Failure code tanımları Biology Rule Engine'e aittir.

## Visual/Audio Requirements

Failure Cascade System görsel veya sesli hiçbir şey üretmez — bu Run Sequence VFX ve Run Simulation Controller'ın sorumluluğundadır. Cascade System yalnızca hangi görsel tepkinin tetikleneceğini belirleyen veriyi üretir:

| `failure_type` | Run Controller'a Sinyal | VFX Beklentisi |
|---------------|------------------------|----------------|
| `NONE` | başarı | Yeşil biolüminesans cascade |
| `ORGAN` | `failed_organs` listesiyle organ hatası | Başarısız slotlar eş zamanlı kırmızı flash |
| `STRUCTURAL` | `structural_code` ile yapısal hata | Tüm ekran titreyip kararır + "STRUCTURAL FAILURE" mesajı |

## UI Requirements

Failure Cascade System doğrudan UI üretmez. `FailureCascadeResult` verisi Puzzle HUD ve Run Sequence VFX tarafından tüketilir. UI gereksinimleri ilgili sistemlerin GDD'sinde tanımlanacaktır.

## Acceptance Criteria

- [ ] `process(eval_result)` aynı girdiyle iki kez çağrıldığında her seferinde aynı `FailureCascadeResult` döner (determinizm)
- [ ] Tüm organlar `passed = true` → `failure_type == NONE`
- [ ] En az bir organ `passed = false` → `failure_type == ORGAN`, `failed_organs` o organı içerir
- [ ] `structural_code == "CYCLE_DETECTED"` → `failure_type == STRUCTURAL`, `failed_organs` boş
- [ ] `structural_code == "NO_SOURCE"` → `failure_type == STRUCTURAL`, `failed_organs` boş
- [ ] Hem yapısal hata hem organ hatası aynı anda → `STRUCTURAL` döner
- [ ] `null` `EvaluationResult` → `STRUCTURAL` döner, oyun çökmez
- [ ] Bilinmeyen `failure_code` string → olduğu gibi `OrganFailureRecord`'a kopyalanır
- [ ] `process()` çalışma süresi < 0.1ms (12 organ, 20 bağlantı)
- [ ] GUT testi: `TestFailureCascadeSystem.gd` tüm kriterleri otomatik doğrular

## Open Questions

| Soru | Sahip | Hedef | Çözüm |
|------|-------|-------|-------|
| Run Sequence VFX, `FailureCascadeResult`'ı doğrudan mı tüketir yoksa Run Simulation Controller aracı mı olur? | Programmer | Run Simulation Controller GDD tasarımında | Controller aracı olması bekleniyor; FCS → Controller → VFX |
| V1'de çok-hatalı bulmacalar geldiğinde (birden fazla yanlış organ) `failed_organs` yeterli mi? | Designer | V1 planlamasında | Mevcut yapı Array olduğundan birden fazla kaydı destekler; ek alan gerekmeyebilir |
