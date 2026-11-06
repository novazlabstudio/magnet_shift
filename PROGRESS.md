# Magnet Shift — Durum ve Devam Notu

Son güncelleme: 2026-11-06 (Mac oturumu)

Bu dosya başka bir bilgisayarda devam edecek Claude oturumu için yazıldı. Önce bunu, sonra teknik kurallar için [CLAUDE.md](CLAUDE.md)'yi oku. Kullanıcıyla Türkçe konuş; oyun içi metinler her zaman İngilizce.

## 2026-11-06 — 1.1.0 (code 4) geliştirmeleri (Mac oturumu)
1. **Ölüm animasyonu yeniden tasarlandı:** eski "iki dikdörtgen" + kare parçacıklar kaldırıldı. Lazer: elektrik arkları, mavi titreşim, kömürleşme, alev, kül; bekçi: darbe, savrulma, sersemleme yıldızları, dişli parçaları. Kamera kahramana yakınlaşır, sarsılır, vinyet; "Ahh!" + zap/darbe sesi senkron (sesler `tools/gen_sfx.py` ile sentezlendi).
2. **6. kahraman POLARIS** (at nalı mıknatıs omuzlar, pusula göğüs, süzülen gövde) 3 reklamla açılıyor; menü 4+2 düzen; reklam kilidi genelleştirildi (Blaze ilerlemesi korunur).
3. **Arka planlar:** binalar kaldırıldı; 8 tema, parallax katmanlar, parçacıklar, level başına farklı yerleşim; pişirme ile eskisinden daha az çizim çağrısı.
4. **Çıkış kapısı:** kamera odağı, spiral çekilme, ışık sütunu, patlama + başarı zili; yeni level'de "LEVEL N / TEMA" başlığı ve ışınlanma.
5. **BOARD hatası:** kök neden kaydın yalnızca game over/Level 50'de yazılmasıydı. Artık her koşu tek satır, her level bitişinde güncelleniyor; eski kayıtlar taşındı.
- Masaüstünde (Godot 4.6.3, 480x854 / 480x1040) test edildi: 50 level hatasız açılıyor, akışlar (level geçişi, retry, game over, board, Polaris kilidi) çalışıyor. **Telefonda henüz denenmedi**; sesler sentetik, cihazda dinlenmeli.
- 1.1.0 (code 4) 2026-11-06'da **bu Mac'ten** derlenip Production'a gönderildi (isim/açıklamalar/7 ekran görüntüsü aynı incelemede). Managed publishing kapalı: onaylanınca kendiliğinden yayına girer. Sonraki yükleme `version/code=5` olmalı.

## 2026-11-06 (3) — Kapanış çökmesi düzeltildi (sonraki sürüme, code 5)
- Play Console'da 1.0.2'de 2 adet `SIGABRT recursive_mutex::lock` (1'er kullanıcı). Godot 4.6.3 resmi sembolleriyle çözüldü: `Main::cleanup -> GDScriptLanguage::finish -> GDScript::clear -> ... GDScript::UpdatableFuncPtr::~UpdatableFuncPtr`. Yani oyun kapanırken, AdMob eklentisinin static değişkenlerinde kalan AdManager lambda'ları silinirken çöküyor (oyuncu fark etmez ama oranı etkiler).
- Düzeltme `AdManager._release_plugin_callbacks()` (commit 66d6f2b): 1.1.0 (code 4) incelemedeyken yapıldı, o AAB'de YOK. Bir sonraki sürümle gider.
- Semboller: `godotengine/godot-builds` release 4.6.3-stable → `Godot_native_debug_symbols.4.6.3.stable.template_release.android.zip` (arm64 `libgodot_android.so`). NDK yok; ELF .symtab'tan Python ile adres → fonksiyon çözüldü.

## 2026-11-06 (2) — Ana sayfa, geri getirme, değerlendirme, mağaza metni
- Ana sayfa: Orbitron başlık, sade dekor, üst çubuk (BOARD/AWARDS/ses/LEVELS), CONTINUE + NEW GAME, günlük seri rozeti.
- Geri getirme: 18 yerel ödül + bildirimler, günlük seri (Progress.gd). Google Play Games yok → ücret/form yok.
- Oyun içi değerlendirme: kendi Godot Android eklentimiz (Play In-App Review). İzinler değişmedi.
- Mağaza metni `docs/STORE_LISTING.md`; yeni ekran görüntüleri `~/Desktop/MagnetShift_Store_1.1.0/`.
- 14 günlük test yeniden GEREKMEZ (bir kerelikti); güncelleme doğrudan production incelemesine gider.

## 1. Kısa özet

- **Oyun:** Magnet Shift. Godot 4.6, dikey mobil oyun, 50 level. Dokunduğun noktaya en yakın mıknatıs, parmak basılı kaldıkça oyuncuyu çeker. Coin topla, lazer ve bekçiden kaç, çıkış kapısına ulaş.
- **Mağazada yayında:** https://play.google.com/store/apps/details?id=com.novazlabstudio.magnetshift
- **Paket:** `com.novazlabstudio.magnetshift`. Geliştirici hesabı: novazlabstudio@gmail.com (Play Console, AdMob, GameAnalytics, GitHub aynı marka altında).
- **Repo:** https://github.com/novazlabstudio/magnet_shift (dal `main`).
- **Şu an:** 1.0.1 production'da. **1.0.2 (version code 3)** 2026-11-02'de Production'a yüklendi ve **incelemeye gönderildi** (Publishing overview → "Changes in review" altında görüldü). Managed publishing kapalı; onaylanınca otomatik yayınlanır. Yeni oturumda ilk iş: yayınlanıp yayınlanmadığını kontrol et.

## 2. Sürüm geçmişi

| Sürüm | Code | Nerede | İçerik |
|---|---|---|---|
| 1.0.0 | 1 | Closed testing (Alpha) | İlk sürüm. 12+ tester ile 14 gün kapalı test bu sürümle yapıldı. |
| 1.0.1 | 2 | Production (2026-10-29'da gönderildi, onaylandı) | Mac oturumunda yapılan düzeltmeler: Level 20→21 zinciri, platform x yorumu, bekçilerin düşmesi, zemin altına düşen mıknatıslar, MECH seçiminin kaybolması, kapı animasyonu; uzun ekran desteği (`keep_width`, çentik payı); Game Over'da "CONTINUE +3 ❤️"; ZAPPED/CAUGHT mesajı; müzik döngüsü; 5. kahraman BLAZE (3 ödüllü reklamla açılır). INTERNET ve ACCESS_NETWORK_STATE izinleri açıkça etkinleştirildi. |
| 1.0.2 | 3 | Production incelemesinde (2026-11-02 gönderildi) | Kullanıcı geri bildirimine göre: Level 1 eğitimi, ekran dışı mıknatıs okları, pause butonu (ayrıntı bölüm 3). |
| sonraki | **4** | — | Bir sonraki yüklemede `export_presets.cfg` → `version/code=4`. |

## 3. 1.0.2'de ne yapıldı (2026-11-02)

Oyuncu geri bildirimi: (a) mıknatısa dokunmaları gerektiğini anlamıyorlar, (b) ileri level'lerde üstteki mıknatıslar ekranda görünmüyor (sol/sağ üste dokununca çalışıyor ama kimse bilmiyor), (c) oyun sırasında menüye dönülemiyor.

- **Level 1 eğitimi** (`scripts/TutorialOverlay.gd`, yönetimi `GameManager._update_tutorial`): Sıradaki mıknatısın üstünde sarı halka + 👆, altta adım adım metin ("TAP & HOLD the magnet to fly to it" → "KEEP HOLDING... let go to drop" → "Now TAP & HOLD the next magnet" → "Now HOLD THIS ONE to reach the EXIT 🚪"; hedef ekran dışındaysa "Magnet above! TAP THE ARROW"). `user://tutorial_done.dat` yoksa gösterilir; Level 1 ilk kez bitince yazılır.
- **Ekran dışı mıknatıs okları** (`scripts/MagnetIndicators.gd`): Ekranın üstünde/altında kalan mıknatıslar için kenarda, sol ve sağ yarı için birer ok + mıknatıs ikonu. Oka dokunmak o mıknatısı seçer. Dokunuş görünür bir mıknatısa oktan daha yakınsa görünür olan seçilir (`GameManager._pick_magnet`). Level ≤5'te okun altında "TAP". Not: 854 yüksekliğindeki ekranlarda Level 1'in üstteki iki mıknatısı bile başta ekran dışındaydı.
- **Pause:** HUD sol üstte ❚❚ butonu. Panel: RESUME / MAIN MENU (MAIN MENU koşu skorunu ve canları sıfırlar, sonuç ekranındaki menü butonuyla aynı `_go_to_main_menu`). Uygulama arka plana atılınca otomatik pause. HUD yeniden dizildi (pause 6..50, skor, ses 160..204, LVL 212..330).
- **Analitik:** yeni GA design olayları `Level:Quit:LevelNN`, `Tutorial:Complete`.
- **Test:** Masaüstünde 480x1040 ve 480x854 ekran görüntüsüyle (ok seçimi, görünür mıknatısla karışmama, pause/resume). Kullanıcıya telefonda denemesi için debug APK verildi (`C:\dgn\MagnetShift_1.0.2_test.apk`); kullanıcı ardından production'a yüklemeye karar verdi.

## 4. Açık işler

1. 1.0.2'nin onaylanıp yayınlandığını kontrol et (incelemeye gönderildiği teyit edildi). Bir tester'da Ayarlar → Uygulamalar → Magnet Shift sürümü 1.0.2 görünmeli.
2. Yayından sonra kullanıcı geri bildirimini topla. Özellikle eğitimin ve okların anlaşılıp anlaşılmadığına GA'dan bak: `Tutorial:Complete` ve Level 1-5 Fail/Complete oranları, `Level:Quit:*`.
3. Closed testing - Alpha track'i isteğe bağlı olarak "Pause track" ile durdurulabilir (zorunlu değil). Testerlar Play Store'da "(Beta)" etiketi görüyor ama en yüksek version code kuralı gereği zaten production sürümünü alıyorlar (Alpha'da code 1 var). Etiketi kaldırmak isteyen tester opt-in linkinden ya da Play Store sayfasındaki "Leave" ile programdan çıkabilir; uygulama silinmez.
4. Kullanıcı ayrı bir **İHA oyunu** yaptı ve kapalı teste açacak. O oyun için **yeni bir Google Group** açılmalı (`magnet-shift-testers` kullanılmamalı). Play Console'da her uygulamanın track'leri ve 12 tester / 14 gün şartı ayrı, birbirine karışmaz. Paket adı `com.novazlabstudio.<oyunadi>` olmalı; AdMob'da ayrı app kaydı açılmalı (CLAUDE.md).
5. Keystore yedeği: bölüm 5'e bak.

## 5. Bilgisayarlar ve derleme

**Yayın derlemesi 2026-11-06'dan beri Mac'te (`./tools/build_aab.sh`).** Keystore: `~/MagnetShift-imza/release.keystore` (alias `magnetshift`, dosya SHA-256 `387e9a00…fc08dbc`); parola `~/MagnetShift-imza/imza_bilgileri.txt` içinde (repo dışında, chmod 600; içeriğini okuma/yazdırma). Betik Godot 4.6.3 (`/Applications/Godot 4.6.app`) ile `~/Desktop/MagnetShift_<ad>_code<kod>.aab` üretir, imzayı ve 16 KB hizalamayı doğrular. Windows PC'de artık AAB derlenmez (sürüm kodu çakışmasın). Keystore kaybolursa güncelleme yüklenemez (upload key sıfırlama zahmetli); kullanıcıya bulut/harici disk yedeğini hatırlat. Upload sertifikası SHA-256: `6C:C3:CF:F6:3A:7D:B7:5B:89:0E:50:73:0F:AE:E1:9B:4D:78:25:2D:E0:C6:9B:97:B9:19:FC:ED:D3:84:13:3B`.

**Windows PC ortamı (eski, artık yayın derlemesi yapılmıyor):**
- Proje: `C:\dgn\magnet_shift`. Godot 4.6.3 + aynı sürüm export şablonları: `C:\dgn\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`. Android build şablonu `android/build` (4.6.3.stable, Git'te yok). Android Studio + SDK kurulu; `keytool`: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.
- Çıktılar `C:\dgn\` altında: `Magnet Shift.aab` (en son sürüm, şu an 1.0.2), `Magnet Shift 1.0.0.aab`, `Magnet Shift 1.0.1.aab`, `MagnetShift_1.0.2_test.apk` (debug).
- Mac'te iki Godot var: 4.6.3 (`/Applications/Godot 4.6.app`, bu proje) ve 4.4.1 (`/Applications/Godot.app`, diğer oyunlar; bu projeyi onunla açma).

**Derleme komutları (Git Bash, proje klasöründe):**
- Import: `"$G" --headless --path . --import`
- Release AAB: `"$G" --headless --path . --export-release "Android" "../Magnet Shift.aab"` (önce eski dosyayı sürüm adıyla yeniden adlandır).
- Telefonda denemek için debug APK: `export_presets.cfg`'de geçici olarak `gradle_build/export_format=0` yap, `--export-debug "Android" "C:/dgn/....apk"`, sonra `export_format=1`'e geri al. Debug build otomatik **test reklamı** kullanır (AdMob riski yok). Debug APK, Play sürümünden farklı imzalı olduğu için telefondaki Play sürümü önce kaldırılmalı.
- Bilinen tuhaflıklar: Godot export bittikten sonra ("[ DONE ] export") bazen kapanmayıp asılı kalıyor; dosya yine de tamam, `timeout` ile çalıştır. Godot `project.godot`'ta `default_clear_color` satırının yerini değiştiriyor; içerik aynı, commit'e katmadan `git checkout -- project.godot` ile geri al.
- İmza kontrolü: AAB için `keytool -printcert -jarfile "Magnet Shift.aab"` (SHA-256 yukarıdakiyle aynı olmalı); APK için Android SDK `build-tools/*/apksigner.bat verify --print-certs`.
- Masaüstünde oyunu çalıştırmak GameAnalytics'e gerçek olay gönderir; test runner'da kapatma yöntemi CLAUDE.md "Masaüstünde Test" bölümünde.

## 6. Git / GitHub

- Bu Windows PC'nin varsayılan GitHub hesabı **`doganciraci`**; novazlabstudio reposuna push 403 veriyor. Push için kullanıcı novazlabstudio hesabından classic PAT (`repo` scope) oluşturup Git Bash'te kendisi çalıştırıyor: `git push "https://<TOKEN>@github.com/novazlabstudio/magnet_shift.git" main`. Token'ı remote URL'ye kaydetme; iş bitince token'ı revoke et. Claude token içeren komutu çalıştıramıyor (güvenlik engeli), push'u kullanıcı yapar.
- Repo public; kodda para harcatacak API anahtarı yok (GameAnalytics anahtarları ve AdMob ID'leri istemci tarafında zaten açık olan türden).
- Privacy policy ayrı repoda: https://novazlabstudio.github.io/magnet_shift_policy/ (`novazlabstudio/magnet_shift_policy`, tek `index.html`; yerel kopya `C:\dgn\magnet_shift_policy\index.html`). İletişim: novazlabstudio@gmail.com. Veri toplama değişirse (yeni SDK vb.) bu sayfa ve Data safety formu birlikte güncellenmeli.

## 7. Play Console

- **Track'ler:** Production (178 ülke + rest of world, full rollout), Closed testing - Alpha (1.0.0, tester = Google Group `magnet-shift-testers@googlegroups.com`, opt-in: https://play.google.com/apps/testing/com.novazlabstudio.magnetshift, grup: https://groups.google.com/g/magnet-shift-testers, feedback = novazlabstudio@gmail.com). Internal testing kullanılmadı.
- **Managed publishing kapalı** (kullanıcı tercihi): onay gelince otomatik yayınlanır.
- **Dersler:**
  - Sürüm yüklemek: Track → Create new release → `.aab` → release notes → Next → Save → **Publishing overview → Submit changes for review**. Save'den sonra gönderilmezse release "Draft" kalır. 1.0.1'de sadece ülke ayarı incelemeye gitmişti, release taslakta kalmıştı; Publishing overview'da Production altında sürüm satırının ("3 (1.0.2) – Start full rollout") olduğunu her zaman kontrol et.
  - İncelemede bir şey varken yeni gönderim "Restart review" uyarısı verir; yeniden başlatmak süreyi uzatır.
  - Gönderimden önce birkaç dakikalık "quick checks" çalışır; kırmızı "View issue" çıkarsa düzeltmeden gönderilmez (ilk seferde "Advertising ID declaration" eksikti).
  - Uyarı (warning) yayını engellemez; sadece Error engeller.
- **Kişisel geliştirici hesabı kuralı:** yeni her uygulama production'dan önce en az 12 opted-in tester ile 14 gün kapalı test istiyor (İHA oyunu için de geçerli). Testerların gerçekten açıp kullanması ve 1-2 geri bildirim önemli; production başvurusunda "testten ne öğrendin" soruluyor.
- **Store listing:** Kısa/uzun açıklama İngilizce. Görseller `C:\dgn\magnet_shift_store\` (icon_512.png, feature_graphic_1024x500.png; `icon.svg`'den headless Chrome ile üretildi). AI asset etiketi: ikon + feature graphic AI olarak işaretli. Kategori Game/Arcade.

## 8. Doldurulan formlar (yeni oyunda da şablon olarak kullanılabilir)

- Financial features: "My app doesn't provide any financial features". Health: yok. Government app: No. Sign in details (App access): No. Ads: Yes. Advertising ID: Yes (Advertising).
- Content rating (IARC): Category Game, tüm sorulara No (şiddet, korku, cinsellik, dil, madde, bodily humor, satın alma/kripto, kullanıcı etkileşimi, konum paylaşımı, suç).
- Target audience: **13-15, 16-17, 18+**. 13 yaş altı bilinçli olarak seçilmedi ("Designed for Families" → kişiselleştirilmiş reklam yasağı, AdMob geliri düşer).
- Data safety: veri toplanıyor; aktarımda şifreli; hesap oluşturma yok. Toplanan: **App activity → App interactions** (GameAnalytics; collected + shared; ephemeral değil; zorunlu; amaç Analytics) ve **App info and performance → Diagnostics** (AdMob; collected + shared; ephemeral değil; zorunlu; amaç Analytics). Konum, dosya vb. yok (manifest'te konum izni yok).

## 9. Önemli hatırlatmalar

- Release build gerçek reklam gösterir; kullanıcı kendi reklamına tıklamamalı. Telefonda release test edilecekse önce AdMob → Settings → Test devices'a telefon eklenmeli. Debug build otomatik test reklamı kullanır.
- Her yüklemede `version/code` artır (sıradaki: 4).
- Yeni HUD butonu eklenirse `_is_on_hud_button` listesine ekle (CLAUDE.md).
