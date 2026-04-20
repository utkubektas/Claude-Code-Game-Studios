# Specimen — Design Agency Brief

> **Version**: 1.0
> **Tarih**: 2026-04-16
> **Hazırlayan**: Specimen Development Team
> **Hedef Kitle**: Tasarım Ajansı

---

## Hızlı Özet

**Specimen**, mobil bir mantık bulmaca oyunudur. Oyuncu, organları bozulmuş yabancı bir canlıyı inceler, arızalı organı tespit eder ve doğrusunu takarak "Çalıştır" butonuna basar. Canlı ya canlanır ya da spektaküler bir şekilde çöker.

**Platform**: Android + iOS (portrait / dikey)
**Motor**: Godot 4.6
**Render**: 2D, Compatibility renderer (mobil optimized)
**Hedef framerate**: 60fps

---

## 1. Oyun Konsepti ve Ton

### Temel Deneyim
Oyuncu bir xenobiyolog rolündedir. Elimine getirilen alien canlılar bozuk, hasar görmüş veya inaktif haldedir. Hiçbir kural kitabı yoktur — oyuncu, yabancı biyolojiyi tamamen gözlem ve deneme yoluyla keşfeder. Doğru organı doğru yere koyduğunda canlı uyanır.

### Ton: Alien Bilim Laboratuvarı + Anatomik İllüstrasyon
Görsel dil şu iki referansın kesişiminde durmalı:
- **Anatomik illüstrasyon** (Da Vinci anatomik çizimler, 17. yüzyıl bilim kitapları) — formalist, metodolojik, tuhaf tuhaf güzel
- **Biolüminesans** — organizmalar ışık saçıyor; sağlıklı = parlak, hasarlı = sönük/bozuk

> Oyun **karikatür değil**, **pixel art değil**, **gerçekçi 3D değil**.
> 2D stilize illüstrasyon — tuhaf ama okunabilir.

### Referans Oyunlar
| Oyun | Aldığımız | Almadığımız |
|------|----------|------------|
| **Opus Magnum** | Bir makinenin çalışması izlendiğindeki görsel tatmin; "izle ve hisset" anı | Mekanik estetik |
| **Strange Horticulture** | Yabancı sistem üzerinden çıkarım; mobil uyumlu görsellik | Bitki estetiği |
| **Baba Is You** | Oyuncunun kuralları gözlemleyerek öğrendiği görsel tasarım | Sembolik/minimalist grafik |

### Edebi / Kavramsal Referanslar
- **Annihilation** (Jeff VanderMeer) — insan sezgisiyle açıklanamayan biyo-estetik
- **Roadside Picnic** (Strugatsky) — yabancı mantık, keşif yoluyla anlama
- **Tıbbi teşhis** — "belirtilere bak, nedeni bul" yapısı

---

## 2. Görsel Yönelim

### Renk Paleti

**Tanımlı renkler (değiştirilemez):**

| Renk Adı | Hex | Kullanım |
|----------|-----|---------|
| Biolüminesans Yeşil | `#00FF88` | Başarı cascade animasyonu, canlı aktivasyon |
| Organ Hata Kırmızısı | `#FF3333` | Başarısız organ flash, hasar geri bildirimi |
| Yapısal Hata Moru | `#AA44FF` | Yapısal çöküş animasyonu (organ hatasından ayrı) |
| Seçili Slot Sarısı | `#FFD700` | Seçilen organ yuvası çerçevesi |
| Ekran Karartma | Siyah %60 alpha | Yapısal hata overlay'i |

**Ajans tarafından tanımlanacak renkler:**

| Renk Adı | Yönelim | Not |
|----------|---------|-----|
| Genel ekran arka planı | Koyu, organik, nötr | Neon değil; derin uzay + biyoloji laboratuvarı hissi |
| PULSE kanal çizgisi | Elektrik mavisi | İnce, bioelektrik, 2px |
| FLUID kanal çizgisi | Yeşil/sarı organik | Kalın, organik sıvı, 4px |
| 4 organ tipi kimlik renkleri | Her organ için ayrı biolüminesans renk | Oyuncunun organ tiplerini rengiyle tanıyacağı palette |
| Canlı (creature) renk paleti | Ilk arketip için özgün | Diğer arketiplerden görsel olarak ayırt edilebilmeli |
| Koyu kırmızı (flash döngüsü düşük durumu) | `#FF3333`'ın karanlık eşi | Flash titreme döngüsünde kullanılır |

### Tipografi
- Genel yönelim: **bilim terminali**, alien-otantik ama okunabilir
- Başlık / sistem adları için: teknik sans-serif veya stilize monospace
- Gövde metin: maksimum okunabilirlik; mobilde minimum 13px

> Ajansın önerisine açığız — font seçimi net değil.

---

## 3. Asset Listesi

### 3A — Creature Silüetleri

**MVP: 1 silüet gerekli**

| Alan | Spec |
|------|------|
| Canlı Adı (dev) | "Vorrkai" — bu bir placeholder; ajans nihai isim ve form için öneri sunabilir |
| Format | PNG, şeffaf arka plan |
| Boyut | Ekranın %80 genişliğinde render edilecek şekilde tasarlanmalı |
| Katmanlar | Kaynak dosya katmanlı teslim edilmeli (Photoshop / Affinity Designer) |
| Animasyon | Statik; yalnızca fade-in gerekli (0.3s, motor seviyesinde yapılacak) |
| Ton | Anatomik silüet; tanıdık ama hiç görülmemiş bir varlık |
| Naming | `char_vorrkai_silhouette_01.png` |

**Full Vision kapsamı**: 6 creature silüeti (şimdilik tasarım gerekli değil)

---

### 3B — Organ Sprite'ları

**MVP: 4 organ tipi × 2 durum = 8 sprite**

Her organ tipi için iki durum:
- `sprite_normal` — sağlıklı, biolüminesans, parlak
- `sprite_damaged` — arızalı; metin olmadan "yanlış" hissettirmeli

**4 MVP Organ Tipi ve Biyoloji Konsepti:**

| # | Organ Adı | Biyoloji Konsepti | Slot Boyutu |
|---|-----------|------------------|-------------|
| 1 | **Vordex Emitter** | Tüm bioelektrik sinyallerin kaynağı. Biyolojik pacemaker — giriş almadan çıkış üretir | 80×80px |
| 2 | **Valdris Gate** | Biyolojik AND kapısı. İki sinyal kanalı aynı anda aktif olduğunda iletir | 80×80px |
| 3 | **Thrennic Splitter** | Biyolojik sinyal çoğaltıcı. Tek bir PULSE girişini iki bağımsız çıkışa kopyalar | 80×80px |
| 4 | **Ossuric Terminus** | Biyolojik sinyal sonlandırıcı. Sinyali "tüketir", çıkış üretmez. Her sinyal dalı Terminus ile bitmeli | 80×80px |

**Görsel yönelim — her organ için:**
- Biolüminesans, organik form; mekanik değil
- Fonksiyonu görsel olarak okutmalı (Vordex parlak ve yayıcı; Terminus sönük ve absorbe edici vb.)
- Her organın bir kimlik rengi var (ajans belirleyecek)
- Damaged sprite: parlaklık azalmış, form bozulmuş veya renk bozulmuş; ama hâlâ tanınabilir

**Naming convention:**
```
organ_vordex_emitter_normal.png
organ_vordex_emitter_damaged.png
organ_valdris_gate_normal.png
organ_valdris_gate_damaged.png
...
```

---

### 3C — UI Elemanları

**Puzzle HUD bileşenleri:**

| Eleman | Durum Varyantları | Not |
|--------|------------------|-----|
| RUN Butonu | Normal, Locked (alpha 0.5), Solved (gizli) | "▶ RUN SIMULATION" etiketi |
| Envanter kartı (×4) | Normal, Locked (alpha 0.5) | Her kart: renk swatchi + organ adı + kısa açıklama |
| Sonuç alanı | Boş, Başarı, Başarısızlık | "✓ Specimen repaired" / "✗ System failure" |
| Devam Et butonu | Gizli (default), Görünür (bulmaca çözüldüğünde) | — |
| Bulmaca başlığı | Metin alanı (üst sol) | — |
| Deneme sayacı | Metin alanı (üst sağ) | "Deneme: N", max "99+" |

**Specimen Viewer overlay'leri:**

| Eleman | Açıklama |
|--------|---------|
| Slot seçim çerçevesi | `#FFD700` sarı kenarlık, 80×80px |
| Slot placeholder rect | Sprite null iken gösterilen renkli dikdörtgen (organ kimlik rengi) |
| Hasar tint overlay | Hasarlı slot üzerine kırmızı tint |

---

### 3D — VFX / Animasyon Sekansları

Motor Godot Tween ile uygulayacak; ajans renk ve zamanlama rehberlik belgesi sağlamalı. V1'de Particle System ile upgrade edilecek.

**Sekans 1: Başarı (~2.0s)**

| Adım | Açıklama | Süre |
|------|---------|------|
| 1 | Creature merkezinden yumuşak beyaz pulse | 0.1s |
| 2 | Her slot sırayla yeşil glow alır (180ms aralık) | ~0.72s (4 slot) |
| 3 | Tüm creature soluk yeşil tonda kalır | Sabit |

Toplam: ~2.0s — tatmin edici, ama çok uzun değil.

**Sekans 2: Organ Başarısızlığı (~1.5s)**

| Adım | Açıklama | Süre |
|------|---------|------|
| 1 | Tüm başarısız slotlar aynı anda kırmızı flash | 0ms gecikme |
| 2 | 3× titreme (150ms periyot) | ~0.45s |
| 3 | Soluk kırmızı tint devam eder | 0.5s |

Toplam: ~1.5s — acı verici ama eğitici.

**Sekans 3: Yapısal Çöküş (~2.5s)**

| Adım | Açıklama | Süre |
|------|---------|------|
| 1 | Ekran %60 kararır | 0.2s |
| 2 | Tüm slotlar mor/turuncu flash | Eş zamanlı |
| 3 | "STRUCTURAL FAILURE" metni fade-in | 0.3s |
| 4 | Metin durur | 1.0s |
| 5 | Overlay ve metin solar | 0.5s |

Toplam: ~2.5s — dramatik, tüm sistemi etkiliyor hissi.

---

## 4. Ekran Düzeni (Screen Layout)

Tüm ekranlar **portrait** (dikey) düzeninde, 480×854px tasarım boyutunda:

```
+------------------------------------------+
| [Bulmaca Başlığı]        [Deneme: N]      |  ← Üst şerit
|                                           |
|                                           |
|      [Creature Silüeti — %80 genişlik]    |  ← SPECIMEN VIEWER
|      [Organ Slotları + Kanal Çizgileri]   |    Ekran yüksekliğinin %60'ı
|                                           |    Creature merkezi: SCREEN_H × 0.4
|                                           |
+------------------------------------------+  ← SCREEN_H × 0.60 sınırı
|  [Organ 1]          [Organ 2]             |  ← PUZZLE HUD
|  (SCREEN_W×0.44)    (SCREEN_W×0.44)       |    Ekranın alt %40'ı
|  [Organ 3]          [Organ 4]             |    Kart yüksekliği: 70px
|                                           |    Aralık: 8px, sol boşluk: %5
|                                           |
|         [▶ RUN SIMULATION]                |  ← SCREEN_H × 0.85
|         [Sonuç Alanı]                     |  ← RUN butonunun altı
+------------------------------------------+
```

**Ölçüler:**

| Eleman | Değer |
|--------|-------|
| Tasarım boyutu | 480×854px (portrait) |
| Specimen Viewer / HUD sınırı | Ekran yüksekliğinin %60'ı |
| Creature anchor Y | Ekran yüksekliğinin %40'ı |
| Organ slot boyutu | 80×80px (64–100px aralığı) |
| Minimum dokunma alanı | 48×48px (tüm interaktif elemanlar) |
| Slotlar arası minimum mesafe | 64px |
| Envanter kart genişliği | Ekran genişliğinin %44'ü |
| Envanter kart yüksekliği | 70px |
| Envanter sol boşluk | Ekran genişliğinin %5'i |
| RUN butonu Y | Ekran yüksekliğinin %85'i |

---

## 5. Kanal Görsel Dili

Organ slotları arasındaki biyolojik kanallar farklı tiplerde çizilir:

| Tip | Görsel | Kalınlık |
|-----|--------|---------|
| **PULSE** — Bioelektrik sinyal | İnce elektrik mavisi çizgi | 2px (aralık 1–4px) |
| **FLUID** — Organik sıvı akışı | Kalın yeşil/sarı organik tüp | 4px (aralık 2–8px) |

MVP'de kanallar düz çizgilerdir. V1'de eğri ve animasyonlu olacak.

---

## 6. Teknik Gereksinimler

| Kısıt | Değer |
|-------|-------|
| Motor | Godot 4.6 |
| Render | Compatibility (mobil, 2D) |
| Hedef FPS | 60fps (min 30fps) |
| Texture format | PNG, şeffaf arka plan |
| Maksimum texture boyutu | 2048×2048px (mobil limit) |
| Asset dizini | `assets/data/organs/`, `assets/data/creatures/` |
| Dosya isimlendirme | `[kategori]_[isim]_[varyant].[uzantı]` |
| Registry yükleme süresi | Tüm asset'ler < 16ms yüklenmeli (1 frame budget) |
| Kaynak dosya formatı | Katmanlı teslim (.psd / .afdesign / .ai) |
| Export formatı | PNG-32 (şeffaf), her asset ayrı dosya |
| Retina desteği | 1x ve 2x boyutlar (opsiyonel — ajans önerisine açık) |

---

## 7. MVP Kapsamı — Ne İstendiği

Tasarım ajansının MVP için teslim etmesi beklenen asset'ler:

### Sprint Deliverables

**Paket 1 — Görsel Kimlik (Önce gelecek)**
- [ ] Renk paleti (tüm tanımsız renkler dahil)
- [ ] Tipografi seçimi (başlık + gövde)
- [ ] Genel ekran arka planı ve UI tonu

**Paket 2 — Creature ve Organlar**
- [ ] 1 creature silüeti — Vorrkai (veya ajansın önerdiği isim) normal + fade-in uyumlu
- [ ] 4 organ tipi × 2 durum = 8 sprite (normal + damaged)
- [ ] Her organ için kimlik rengi

**Paket 3 — UI Bileşenleri**
- [ ] RUN butonu (3 durum)
- [ ] 4 envanter kartı tasarımı
- [ ] Sonuç alanı (başarı / başarısızlık / boş)
- [ ] Devam Et butonu
- [ ] Slot seçim çerçevesi
- [ ] Başlık ve sayaç metin alanları

**Paket 4 — Animasyon Rehberi**
- [ ] Başarı sekansı için renk ve zamanlama rehberi
- [ ] Organ başarısızlığı sekansı için renk ve zamanlama rehberi
- [ ] Yapısal çöküş sekansı için renk ve zamanlama rehberi
- [ ] "STRUCTURAL FAILURE" tipografi + stil

---

## 8. Açık Sorular / Ajansın Yanıtlaması Gereken

1. **Creature adı ve kimliği** — "Vorrkai" placeholder; ajans isim ve görsel önerisi sunabilir
2. **4 organ tipinin görsel dili** — fonksiyonel kimlik (yayıcı, kapı, bölücü, sonlandırıcı) görsele nasıl yansıyacak?
3. **PULSE / FLUID kanal kesin renkleri** — niteliksel tanım var, hex değer ajansa bırakılıyor
4. **Genel arka plan rengi** — dokümanlarda belirtilmemiş
5. **Organ tipine özel 4 biolüminesans renk** — palette içinde ayırt edici olmalı
6. **"STRUCTURAL FAILURE" metin tasarımı** — boyut, font, konum, stil
7. **UI font tercihi** — henüz karar verilmedi
8. **Retina / HiDPI desteği** — ajans önerisine açık

---

## 9. Teslim Formatı Beklentisi

| Format | İçerik |
|--------|--------|
| Kaynak dosyalar | Katmanlı (.psd / .afdesign / .ai) — her asset için |
| Export | PNG-32, şeffaf arka plan, dosya başına tek asset |
| Stil rehberi | PDF — renk paleti, tipografi, ikon dili, kullanım örnekleri |
| Animasyon rehberi | PDF veya After Effects referansı — zamanlama ve renk |
| Asset listesi | Teslim edilen tüm dosyaların listesi (spreadsheet) |

---

## 10. Notlar

- Oyun **Türkçe + İngilizce** piyasaya çıkacak; UI metinleri her iki dilde mevcutsa ajans bilgilendirilecek
- Tüm alien adlar (Vordex, Valdris, Thrennic, Ossuric) telaffuz edilebilir ama gerçek dil değil — görsel tasarımda bu özgünlük korunmalı
- "Karikatür veya şirin" değil; "tuhaf ve bilimsel" — yabancı biyoloji ders kitabı hissi
- Oyun premium (reklamsız); marka tonu buna göre

---

*Bu brief, tasarım ajansıyla ilk görüşme için hazırlanmıştır. Sorular için geliştirici ile iletişime geçin.*
