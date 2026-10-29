# Magnet Shift — Yayına Hazırlık İlerleme Notu

## 2026-10-26 — Test, hata düzeltme ve görsel iyileştirme (`fix/bugs-and-polish` dalı)
- Level 20 → 21 zinciri kopuktu (NEXT çıkmıyordu); platform x yorumu, düşen guard'lar, zemin altına düşen mıknatıslar, MECH seçiminin kaybolması, kapı animasyonu, ses butonu dokunma hatası düzeltildi.
- Uzun ekranlarda siyah bantlar kaldırıldı (`keep_width` + ortalama + çentik payı).
- Game Over: reklam butonu ana eylem ("CONTINUE +3 ❤️", "keep your N coins"); "TRY AGAIN" → "START OVER".
- Ölüm nedeni mesajı (ZAPPED / CAUGHT), müzik döngüsü kesintisiz, analitikte gerçek attempt_num.
- 5. kahraman BLAZE: 3 ödüllü reklamla açılıyor.
- Yeni `.aab` için `version/code=2`, `version/name=1.0.1`. Telefonda test edilip Alpha'ya yeni sürüm olarak yüklenmeli.

Son güncelleme: 2026-10-29

## Tamamlananlar
- [x] AdMob rewarded ad entegrasyonu (canlar bitince "CONTINUE +3 ❤️") — detay: [CLAUDE.md](CLAUDE.md)
- [x] GameAnalytics (metrik) entegrasyonu — `scripts/AnalyticsManager.gd` (daha önceden yapılmıştı)
- [x] Android paket adı: `com.novazlabstudio.magnetshift`
- [x] `version/name` = `1.0.0` (export_presets.cfg) — 2026-10-26: depoda boş görünüyordu; `1.0.1` / `version/code=2` yapıldı (ilk yükleme code 1)
- [x] Release keystore oluşturuldu: `keystore/release.keystore` (alias: `magnetshift`, parola: sadece kullanıcının kendi not/parola yöneticisinde — bu dosyaya yazılmadı, `.gitignore` ile hariç tutuluyor)
- [x] İlk release `.aab` başarıyla export edildi (`Magnet Shift.aab`)
- [x] Google Group oluşturuldu: **`magnet-shift-testers@googlegroups.com`** — "anyone on the web can join/search", "who can view members" → group managers (üye mailleri birbirine görünmesin diye)
- [x] **Android Developer Verification**: paket adı zaten "Registered" durumda (3 key — cihaza kurulan debug/release build'lerden otomatik algılanmış), ekstra işlem gerekmedi
- [x] Play Console'da **"Magnet Shift"** app kaydı oluşturuldu (Create app → Game, Free)
- [x] Closed testing → **Alpha** track zaten mevcuttu, **Create new release** ile `Magnet Shift.aab` yüklendi (Play App Signing kabul edildi)
- [x] **App content** formlarının çoğu tamamlandı:
  - Financial features → "My app doesn't provide any financial features"
  - Sign in details (eski adı "App access") → "No" (kısıtlı bölüm yok)
  - Ads → "Yes, my app contains ads"
  - Health declaration → "No"
  - Content ratings (IARC) → Category: Game; questionnaire'deki tüm sorulara "No" (şiddet/cinsellik/dil/madde/vücut fonksiyonu/satın alma-kripto/sohbet/konum-paylaşımı/suç tekniği yok)
  - Target audience → **13-15, 16-17, 18 and over** işaretlendi (13 yaş altı bilinçli olarak seçilmedi — "Designed for Families" politikasına girmemek için, aksi halde kişiselleştirilmiş reklam gösterilemez ve AdMob geliri ciddi düşer)
  - **Data safety** formu dolduruldu:
    - Veri topluyor mu → Yes
    - Encrypted in transit → Yes
    - Account creation → yok ("does not allow users to create an account"), dışarıdan login da yok
    - Location (approximate/precise) → toplanmıyor (manifest'te konum izni yok, doğrulandı)
    - Files and docs → toplanmıyor
    - App activity → sadece **App interactions** işaretlendi (GameAnalytics), In-app search/Installed apps/Other → hayır
      - Ephemeral değil, collection required, amaç: sadece **Analytics** (hem collected hem shared tarafında)
      - Collected + Shared ikisi de işaretli (GameAnalytics 3. taraf servis)
    - App info and performance → sadece **Diagnostics** işaretlendi (AdMob), Crash logs işaretlenmedi (ayrı bir crash reporting servisi yok)
      - Ephemeral değil, collection required
      - Collected + Shared ikisi de işaretli (AdMob/Google 3. taraf)
    - Security practices → "Data is encrypted in transit" otomatik göründü
    - **Privacy policy linki eksik — formu submit etmek için hâlâ gerekiyor (aşağıya bak)**

- [x] Kod public repoya pushlandı: https://github.com/novazlabstudio/magnet_shift (kodda para/token harcatacak API key yok; keystore `.gitignore` ile hariç). Push'ta kullanılan PAT'ler revoke edildi, remote URL'den token temizlendi.
- [x] **Privacy Policy yayında**: https://novazlabstudio.github.io/magnet_shift_policy/ (ayrı public repo `novazlabstudio/magnet_shift_policy`, tek `index.html`, iletişim: novazlabstudio@gmail.com). Yerel kopya: `C:\dgn\magnet_shift_policy\index.html`.
- [x] Tüm App content formları, store settings (Game/Arcade, iletişim e-postası), store listing (açıklamalar, ikon, feature graphic, 7 ekran görüntüsü, AI asset etiketi: ikon + feature graphic) ve Advertising ID declaration tamamlandı. Görseller: `C:\dgn\magnet_shift_store\`.
- [x] Closed testing - Alpha: release 1 (1.0.0), 178 ülke, tester = Google Group (opt-in: https://play.google.com/apps/testing/com.novazlabstudio.magnetshift, grup: https://groups.google.com/g/magnet-shift-testers), feedback = novazlabstudio@gmail.com. 2026-10-12 onaylandı; 12+ tester ile 14 gün tamamlandı.
- [x] **Production access verildi** (Google maili, 2026-10-29 civarı).
- [x] 2026-10-29 (Windows PC): Mac commit'leri çekildi (`6dd4c45`). `export_presets.cfg`'de `permissions/internet` ve `access_network_state` true yapıldı (commit edilmedi). Godot 4.6.3 headless import + kısa çalıştırma hatasız. Eski 1.0.0 dosyası `C:\dgn\Magnet Shift 1.0.0.aab` olarak saklandı; 1.0.1 release `.aab` export'u `C:\dgn\Magnet Shift.aab`.

## Şu An Kaldığımız Yer
2026-10-29: **1.0.1 (version code 2) Production'a yüklendi ve Google incelemesine gönderildi** (178 ülke, full rollout). Managed publishing **kapalı** (kullanıcı tercihi): onay gelince otomatik yayına çıkar. İlk gönderimde sadece ülke ayarı incelemeye gitmişti ve aynı gün onaylanıp yayınlandı (178 ülke, sürümsüz); 1.0.1 release'i ayrıca "Submit 1 change for review" ile gönderildi ve "Changes in review"da. 1.0.1 telefonda henüz test edilmedi.

Mağaza linki (onaydan sonra): https://play.google.com/store/apps/details?id=com.novazlabstudio.magnetshift

## Sıradaki Adımlar
1. Google onayını bekle (e-posta gelir). Publishing overview'da kırmızı "View issue" çıkarsa düzelt.
2. Telefonda 1.0.1 testi (Internal testing'e aynı .aab yüklenerek ya da yayından sonra): uzun ekran/çentik, 5 kahraman kartı ve seçimin korunması, level 1-3, level 20 → NEXT → 21, ZAPPED/CAUGHT, CONTINUE +3 reklamı, BLAZE 3 reklamla açılıyor, müzik döngüsü. Önce AdMob → Settings → Test devices'a telefonu ekle; kendi reklamına tıklama.
3. Yerelde commit edilmemiş: `export_presets.cfg` (INTERNET + ACCESS_NETWORK_STATE izinleri true), `PROGRESS.md`, `project.godot` (Godot'nun satır sırası değişikliği). Commit/push kullanıcı kararı.
4. Sonraki sürümlerde version code 3'ten başlamalı.

## Önemli Hatırlatmalar
- Release keystore'u (`keystore/release.keystore`) proje klasörü dışında ayrıca yedekle (bulut, harici disk). Kaybedilirse bu paket adıyla bir daha güncelleme yüklenemez.
- Reklam kodu debug build'de otomatik test ID kullanıyor, release'de gerçek ID — kendi reklamına gerçek build'de tıklama (AdMob politika ihlali riski).
- Target audience'a 13 yaş altını **bilerek** dahil etmedik — "Designed for Families" kısıtlamalarına girmemek için (kişiselleştirilmiş reklam geliri korunuyor).
- Daha fazla teknik/kod detayı için [CLAUDE.md](CLAUDE.md)'ye bak.
