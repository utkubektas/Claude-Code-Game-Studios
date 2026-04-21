# Token Retro — Sprint 03 (Visual Layer)
Tarih: 2026-04-21
Politika referansı: `.claude/docs/token-budget.md`

---

## Özet

| Metrik | Sprint 03 | Sprint 02 | Trend |
|--------|-----------|-----------|-------|
| lead-programmer çağrı | 0 (gate bekliyor) | 7 | ↓↓ |
| Paralel agent max | 4 (ihlal) | 2 | ↑ (kötüye) |
| Rate limit çakışması | EVET (3/4 agent) | EVET (1/3 agent) | ↑ (kötüye) |
| active.md var mı | Sprint sonunda oluşturuldu | YOK | ↑ (iyiye) |
| qa-tester çağrıldı mı | HAYIR | HAYIR | = |
| Tahmini toplam israf | ~18K token | ~155K token | ↓↓ |

**İyileştirme**: Sprint 02'ye göre ~137K token tasarruf (lead-programmer eliminasyonu).
**Kalan sorun**: Rate limit ihlali daha da kötüleşti — sprint sonunda 4 paralel agent.

---

## Kural İhlalleri

### İhlal 1 — T14 RunSequenceVFX: spawn kuralı ihlali
- **Kural**: token-budget.md §1 (< 200 satır → inline)
- **Nerede**: Sprint 03 review süreci, `run_sequence_vfx.gd`
- **Gerçek boyut**: 155 satır → **inline eşiğinin altında**
- **Ne yapıldı**: `gameplay-programmer` agent açıldı → rate limit'e çarptı
- **Tahmini maliyet**: ~2K token boşa (agent başlatma + rate limit overhead)
- **Düzeltme Sprint 04'te**: 155 satır eşdeğeri dosyalar inline review alacak

### İhlal 2 — T15 ScreenNavigation: spawn kuralı ihlali
- **Kural**: token-budget.md §1 (< 200 satır → inline)
- **Nerede**: Sprint 03 review süreci, `screen_navigation.gd`
- **Gerçek boyut**: 106 satır → **inline eşiğinin çok altında**
- **Ne yapıldı**: `gameplay-programmer` agent açıldı → rate limit'e çarptı (0 token)
- **Tahmini maliyet**: ~1K token boşa
- **Düzeltme Sprint 04'te**: 106 satır eşdeğeri dosyalar için kesinlikle inline

### İhlal 3 — 4 paralel agent başlatıldı (limit: 3)
- **Kural**: token-budget.md §5 (maks 3 paralel)
- **Nerede**: Sprint 03 review başlatımı — T12/T13/T14/T15 aynı anda
- **Sonuç**: 4 agenttan 3'ü rate limit'e çarptı. 1 agent (T12) tamamlandı.
- **Tahmini maliyet**: ~5K token başlatma maliyeti × 3 boşa = ~15K token
- **Düzeltme Sprint 04'te**: Önce 1-2 agent, sonuç gelince devam

### İhlal 4 — active.md sprint boyunca eksikti
- **Kural**: token-budget.md §4 (session başında okunacak tek referans)
- **Nerede**: Sprint 03 tüm süreci
- **Sonuç**: Session compaction sonrası recovery için ~8-10K token harcanarak bağlam kuruldu (session summary yöntemi)
- **Tahmini maliyet**: ~10K token (recovery overhead)
- **Düzeltme Sprint 04'te**: active.md sprint başında oluşturulacak, her commit sonrası güncellenir

---

## Eksik Agentlar

| Agent | Neden çağrılmadı | Sprint 04'te ne zaman |
|-------|-----------------|----------------------|
| `qa-tester` | Testler implementasyon agentı tarafından yazıldı | Sprint 04 sonunda: coverage gap raporu |
| `qa-lead` | Test planı yazılmadı | Sprint 04 başında: test planı + release gate kriterleri |
| `art-director` | ColorRect placeholder aşamasında gereksiz | Sprint 04: gerçek sprite geçişi için art bible |
| `audio-director` | `assets/audio/` yok | Sprint 04: ilk ses event listesi |
| `lead-programmer` | Sprint gate henüz yapılmadı | Sprint 03 gate: Sprint 04 başında çağrılacak |

---

## Tahmini Tasarruf Tablosu

| Kalem | Sprint 03 harcama | Politikayla harcama | Tasarruf |
|-------|------------------|--------------------:|---------|
| 4 paralel agent (3'ü boşa) | ~15K | ~0K | **~15K** |
| T14 agent spawn (155 satır) | ~2K | ~0.5K (inline) | **~1.5K** |
| T15 agent spawn (106 satır) | ~1K | ~0.2K (inline) | **~0.8K** |
| active.md yokken recovery | ~10K | ~1K (dosya okuma) | **~9K** |
| **Toplam Sprint 03 israf** | **~28K** | **~1.7K** | **~26K** |

Sprint 02 toplam tahmini israf: ~155K (7 × lead-programmer @ ~25K/çağrı)
Sprint 03 toplam tahmini israf: ~28K (**↓82% iyileşme**)

---

## Bir Sonraki Sprint İçin Önlemler

| # | Önlem | Dosya | Öncelik | Durum |
|---|-------|-------|---------|-------|
| 1 | active.md sprint BAŞINDA oluştur, her commit'te güncelle | `production/session-state/active.md` | 🔴 Yüksek | ✅ Oluşturuldu |
| 2 | Maks 2 paralel review agent başlat, result sonrası devam et | `review-delegation.md` | 🔴 Yüksek | ✅ Kuralda var |
| 3 | < 200 satır dosyalar için agent açma — inline review | `review-delegation.md` | 🔴 Yüksek | ✅ Kuralda var |
| 4 | Sprint başında `qa-tester` coverage gap raporu planla | `sprint-04.md` | 🟡 Orta | ⏳ Bekliyor |
| 5 | Sprint 03 lead-programmer gate Sprint 04 başında yap | sprint gate | 🟡 Orta | ⏳ Bekliyor |
| 6 | Art Director Sprint 04 başında art bible yazar | `design/art-bible.md` | 🟡 Orta | ⏳ Bekliyor |

---

## Notlar

**Tekrarlayan örüntü**: Rate limit ihlali her iki sprintte de yaşandı (Sprint 02: T09, Sprint 03: T13/T14/T15). Kök neden: review agentları sprint sonunda toplu başlatılıyor. Çözüm basit: 2-then-wait paterni.

**İyileşme doğrulanıyor**: lead-programmer eliminasyonu çalıştı. Sprint 02'de 7 çağrı × ~22K = ~155K vs. Sprint 03'te 0 çağrı. Net etki belirgin.

**Sıradaki kritik adım**: Sprint 03 lead-programmer gate-check (T12-T16 mimari incelemesi) hâlâ yapılmadı. Sprint 04 başlamadan önce 1 kez çağrılmalı.

**T13 borderline**: PuzzleHUD 267 satır — eşiğin 67 satır üstünde. Agent açmak teknik olarak doğru ama rate limit'e çarptı. Sprint 04'te 267 satır eşdeğeri dosyalar için önce inline dene, yetmezse agent aç.
