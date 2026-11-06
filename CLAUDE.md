# Magnet Shift — Proje Notları

## Genel Kurallar
- Oyun içi/UI metinleri (buton, label, mesaj) **her zaman İngilizce** yazılır, sohbet Türkçe olsa bile. Mevcut kod bu şekilde: "GAME OVER", "MAIN MENU", "TRY AGAIN" vb.
- Android paket adı: `com.novazlabstudio.magnetshift` (kişisel isim yerine stüdyo markası "novazlabstudio" kullanılıyor — Gmail hesabıyla tutarlı). İleride yazılacak diğer oyunlarda da aynı prefix: `com.novazlabstudio.<oyunadi>`.

## AdMob Entegrasyonu (2026-09-28 tamamlandı)
Canlar bitince rewarded (ödüllü) reklam gösteriliyor.

- AdMob hesabı: aynı Gmail (novazlabstudio) üzerinden yönetiliyor; ileride yazılacak her oyun için AdMob'da ayrı bir "app" kaydı açılacak.
- AdMob App ID: `ca-app-pub-5920018930695278~4393848565`
- Rewarded Ad unit ID (ExtraLife): `ca-app-pub-5920018930695278/5551017561`
- Plugin: Godot AssetLib → **poing.studios "AdMob" v5.1.0** (Godot 4.2 uyumlu), `addons/admob/`.
  - Bu plugin'in kendi Claude Code skill dosyaları var: `addons/admob/skills/*/SKILL.md`. Ama bu örnekler kurulu sürümün gerçek API'siyle tam örtüşmüyor (ör. `ConsentInformation` static değil, instance metod adları farklı). Yeni bir reklam formatı (interstitial, banner vb.) eklerken SKILL.md'yi rehber olarak oku ama örnek kodu kurulu `addons/admob/gdscript/src/**/*.gd` dosyalarındaki gerçek API ile karşılaştırıp doğrula.
- `scripts/AdManager.gd` (autoload): SDK init + UMP/GDPR consent akışı + rewarded reklamı sürekli arka planda önceden yükleyip hazır tutuyor. `OS.is_debug_build()` true iken otomatik Google'ın resmi test ID'sini kullanıyor, release build'de gerçek ID'ye geçiyor — reklamına kendin tıklayıp AdMob politikasını ihlal etme riskini önlemek için.
- `scripts/GameManager.gd::_show_game_over()` içinde en üstteki "CONTINUE +3 ❤️" butonu (altında "keep your N coins") var; ödül kazanılırsa can 3'e resetlenip aynı level (skor sıfırlanmadan) yeniden yükleniyor.
- Release'e geçmeden önce Play Console → App content → Ads kısmında "Yes, my app contains ads" işaretlenmeli.

## Bilinen GDScript Tuzağı
GDScript'te (Godot 4) aynı fonksiyon içindeki iki ayrı lambda, dışarıdaki bir `bool`/`int`/`String` gibi value-type değişkeni **kopya olarak** yakalar — biri değiştirse diğeri görmez. Bu yüzden `AdManager.gd`'de ödül bilgisini paylaşmak için bare `bool` yerine `Dictionary` (`{"earned": false}`) kullanıldı. Birden fazla async callback/signal'ın state paylaştığı her yerde (AdMob, HTTP request, çoklu tween completion vb.) aynı desene dikkat et.

## Level Verisi Kuralları (`GameManager.gd::get_level_data`)
- Tasarım koordinatı 480x854. Level 4'ten itibaren level yüksekliği `854 + (n-3)*120`; y değerleri `scale_y = lh/854` ile ölçeklenir.
- **Platform `Vector4(x, y, w, h)`: x SOL kenar, y merkez.** Kod merkeze çevirir (`x + w/2`). Sağ platformlarda `x + w = 455` (sağ duvarın iç kenarı), soldakiler x=25'ten başlar. Coin ve guard'lar platform ortasına göre yazılmıştır.
- `extra_magnets`: x=50/430 olanlar (duvar mıknatısları) 854'lük tasarım koordinatında → ölçeklenir. **x=80/400 olan dizi zaten mutlak level koordinatında → ölçeklenmez.** Birbirine 56px'den yakın mıknatıslar tekilleştirilir.
- Level 21–50 sahneleri `CreateLevels.gd` ile Level20'den üretildi; yeni level eklerken `next_level_path` zincirini kontrol et (Level 20'de bir ara boş kalmıştı).
- Guard'lar platform kenarını ray ile algılar ve `patrol_distance` sınırında döner.

## Ekran / UI Yerleşimi
- `stretch/aspect = keep_width`: genişlik hep 480, uzun telefonlarda viewport dikeyde uzar (siyah bant yok). Geniş ekranda (tablet) yanlarda bant olur.
- Sabit koordinatlı paneller 854'e göre çizilir, sonra `ScreenUtil.shift_children(..., ScreenUtil.center_offset(self))` ile ortalanır. Üst çubuktaki öğeler (HUD, BOARD/LVL, SKIP) ise `ScreenUtil.safe_top(self)` kadar aşağı itilir (çentik). Yeni ekran/panel eklerken aynı deseni kullan.
- Müzikler import ayarında `loop_mode=2` (Forward) ile kesintisiz döner.
- HUD soldan sağa: pause butonu (6..50), skor, ses butonu (160..204), LVL rozeti (212..330), sağda toplam skor + canlar. Dokunuş `_input`'ta işlendiği için HUD'a yeni buton eklenirse `_is_on_hud_button` listesine de eklenmeli, yoksa butona basmak mıknatısı da tetikler.

## Kontrol, Göstergeler, Pause
- Dokunulan noktaya **en yakın mıknatıs** (dünya koordinatında) basılı tutulduğu sürece oyuncuyu çeker; birden çok parmakta son basılan geçerli.
- `MagnetIndicators.gd` (UILayer): ekranın üstünde/altında kalan mıknatıslar için kenarda ok; her kenarın sol/sağ yarısında en yakın olan gösterilir, Level ≤5'te altında "TAP" yazar. Oka dokunmak o mıknatısı seçer (`_pick_magnet`), ama dokunuş görünür bir mıknatısa oktan daha yakınsa görünür olan seçilir.
- `TutorialOverlay.gd`: Level 1'de, `user://tutorial_done.dat` yoksa gösterilir (Level 1 ilk kez bitince yazılır). Hedef seçimi `GameManager._tutorial_target`: oyuncunun üstündeki en yakın mıknatıs, çıkış mıknatısı her zaman aday. Hedef ekran dışındaysa el oku gösterir.
- Pause: `get_tree().paused`; `PausePanel` `PROCESS_MODE_ALWAYS`. MAIN MENU sonuç ekranındakiyle aynı `_go_to_main_menu` (koşu skoru/canlar sıfırlanır). Uygulama arka plana atılınca (`NOTIFICATION_APPLICATION_PAUSED`) otomatik duraklar; `FOCUS_OUT` bilerek kullanılmıyor. Sahne değiştirmeden önce `paused` false yapılmalı.
- GA Design olayları: `Level:Quit:LevelNN` (pause'dan menüye çıkış), `Tutorial:Complete`.

## Masaüstünde Test
- Mac: `"/Applications/Godot 4.6.app/Contents/MacOS/Godot"`. Projeyi doğrudan değil, kopyasında (AnalyticsManager/AdManager stub'lı, `config/custom_user_dir_name` ayrı) çalıştır; gerçek GA olayı ve reklam gitmesin.
- Godot 4.6.3 (Windows): `C:\dgn\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`. Görsel test için geçici bir runner sahnesi `--resolution 480x1040` / `480x854` ile çalıştırılıp `get_viewport().get_texture().get_image()` ile ekran görüntüsü alınabilir.
- Masaüstünde çalıştırınca `AnalyticsManager` gerçek GA'ya istek atar: runner'da `is_enabled=false`, `http_init/http_events.cancel_request()` ve `_on_init_completed` bağlantısını koparmak gerekir.

## Sürüm
- Proje Godot 4.6 ile kaydedilmiş (`config/features` 4.6, sahnelerde `unique_id`). Mac'te `/Applications/Godot 4.6.app` (4.6.3 + şablonlar) var; `/Applications/Godot.app` 4.4.1 diğer oyunlar için, Magnet Shift'i onunla açma.
- Play Console'a her yüklemede `export_presets.cfg` → `version/code` artırılmalı (1.0.0=1, 1.0.1=2, 1.0.2=3, 1.1.0=4; sıradaki 5).
- Release keystore ve export parolaları sadece Windows PC'de; ayrıntı ve derleme komutları PROGRESS.md bölüm 5.

## Analitik
- `AnalyticsManager` Complete/Fail olaylarında gerçek `attempt_num` gönderir (`user://ga_attempts.json`, Complete'te sıfırlanır); `os_version` cihazdan okunur.
- Testlerde GameAnalytics'e gerçek olay gitmemesi için autoload'u stub ile değiştir.

## Kahramanlar
- 0=Cyborg, 1=Pink, 2=Shadow (Lvl 5), 3=Mech (Lvl 10), 4=Blaze, 5=Polaris. Çizimler `PlayerVisual.gd`; menüdeki 0–3 önizlemeleri `MainMenu.gd::_get_hero_preview_script` içinde ayrı kopya, reklamla açılanlar (4, 5) doğrudan `PlayerVisual` (`preview_hero`) kullanıyor. Adlar tek yerde: `HeroManager.HERO_NAMES`.
- Menü: üstte 4, altta 2 kart (reklamla açılanlar), `per_row = [4, 2]`.
- **Blaze ve Polaris 3'er ödüllü reklamla açılır** (`HeroManager.AD_HEROES`; ilerleme `user://blaze_ads.dat`, `user://polaris_ads.dat`). Her reklam oyuncunun ayrı dokunuşuyla başlar, ödül her izlemede kaydedilir (AdMob kurallarına uygun: isteğe bağlı, ödül önceden açıkça yazılı). Pencere: `MainMenu.gd::_show_ad_unlock(ui, hero_id, renk)`.
- Polaris (`_draw_polaris`) bacaksız süzülür; kahraman çizimlerinde `draw_set_transform` KULLANMA: ölüm animasyonu tüm çizime `draw_set_transform_matrix` uyguluyor, iç çağrı onu bozar (elips için nokta listesi kullan).
- Şimdilik ExtraLife ile aynı rewarded ad unit kullanılıyor; AdMob'da ayrı bir "HeroUnlock" unit'i açılırsa raporlar ayrışır.
- GA Design olayları: `HeroUnlock:<Blaze|Polaris>:Ad1..Ad3`, `HeroUnlock:<ad>:Unlocked` — kaç kişinin hangi adımda bıraktığı görülebilir.
- Yeni kahraman eklerken: `HeroManager.HERO_COUNT/HERO_NAMES` (+ reklamlıysa `AD_HEROES`), `PlayerVisual._draw_hero` + `HERO_ACCENTS`, `Player.VOICE_PITCH`, menüdeki `hero_names/hero_colors/hero_locked/per_row` birlikte güncellenmeli.

## Ölüm, Çıkış ve Level Girişi Animasyonları
- Ölüm (`Player.die(cause)` → "laser" | "guard"): `PlayerVisual.play_death` kahramanı kendi çiziminde tutar (titreme/kömürleşme/devrilme veya fırlayıp dönme), `DeathFX.gd` çevredeki efektleri çizer (şimşek arkları, kıvılcım, alev, duman, kül / darbe halkası, yıldız, dişli). `GameManager.on_player_death_started` kamerayı kahramana kilitler (zoom 1.9, sarsıntı, vinyet, renkli flaş). Süre `Player.DEATH_TIME`; bitince `player_died` → sonuç ekranı.
- Çıkış (`ExitDoor._play_enter_animation`): kahraman 0.55 sn spiral çizip parlayarak girdaba çekilir, `ExitVisual.play_enter` ışık sütunu/içe akan çizgiler/patlama/şok halkası çizer, `GameManager.on_exit_started` kamerayı kapıya kilitler; `level_complete` 0.5 sn sonra.
- Odak sırasında kamera oyuncudan ayrılıp level köküne taşınır (`_focus_camera`), alt sınırı gevşetilir; zemin ve duvarlar bu yüzden aşağıda 600 px uzatıldı.
- Level girişi (`_play_level_intro`): "LEVEL N" + tema adı başlığı ve `SpawnFX.gd` ışınlanma.
- Ses efektleri `audio/sfx/*.wav` — `tools/gen_sfx.py` ile sıfırdan sentezlenir (lisanslı ses yok; macOS `say` sesleri ticari kullanımda yasak olduğu için kullanılmadı). Çalma: `SoundManager.play_sfx(ad, db, pitch)`; ses kapalıysa çalmaz. "Ahh!" perdesi kahramana göre `Player.VOICE_PITCH`.

## Arka Planlar (`LevelBackdrop.gd`)
- Tema level'in `bg` renginin tonundan seçilir: sky (açık), ocean, nebula, aurora, crystal, inferno, desert, void (gri/siyah). Yerleşim `level*7919` tohumuyla değişir; renkler level paletinden.
- Katmanlar: ekrana sabit degrade (CanvasLayer -20), far/mid/near parallax (0.12/0.32/0.6), `anim` (yıldız parıltısı, kuzey ışığı, lav nabzı — her kare çizilir), ekrana sabit parçacıklar (CanvasLayer -5).
- far/mid/near level açılırken SubViewport'ta bir kez resme pişirilir (1.0/0.75/0.5 çözünürlük), `BLEND_MODE_PREMULT_ALPHA` ile çizilir. Pişirmeden önce L50'de 1779 çizim çağrısıydı; sonra 313 (eski bina arka planlı sürüm 417).

## Skor Tablosu (BOARD, `Leaderboard.gd`)
- Her koşu (Level 1'den ya da sıfırlanan skorla başlayan oyun) tek satır; `user://current_run.txt` koşu kimliği. Satır her level bitişinde ve game over'da `Leaderboard.record` ile güncellenir; skor sıfırlayan her yer `GameManager._reset_run()` kullanır (yeni koşu açar).
- Eski hata: kayıt yalnızca game over'da ve Level 50 bitince yazılıyordu; MAIN MENU / RESTART / PLAY / uygulamayı kapatma skoru kaydetmeden siliyordu → tablo neredeyse hiç dolmuyordu.
- Dosya `user://leaderboard.json`; eski ikili `leaderboard.dat` ilk okumada taşınır (silinmez). En iyi 5, 0 puan yazılmaz.

## Ana Sayfa (1.1.0)
- Üst çubuk: BOARD (skor tablosu), AWARDS (ödüller), ses simgesi, LEVELS. Ses eskiden PLAY altında büyük butondu.
- Başlık ve butonlar Orbitron (`fonts/Orbitron-Bold.ttf`, SIL OFL) — `UIFont.title(harf_aralığı)`. Başlıktaki tarayıcı çizgi/kesikli ayraç/köşe parantezleri kaldırıldı.
- `max_level > 1` ise ana buton "CONTINUE" (en yüksek açık level'den başlar) + küçük "NEW GAME" (Level 1). Değilse "PLAY".

## Oyuncuyu Geri Getirme (`Progress.gd`, autoload) — tamamen yerel
- Google Play Games kullanılmadı (ek kurulum/form istemesin diye). Veriler `user://progress.json`.
- AWARDS: 18 yerel ödül (`Progress.AWARDS`), açılınca üstten bildirim + `trophy` sesi; GA olayı `Award:<id>`. Ödüller oyun içi avantaj vermez (reklam gelirini azaltmasın diye).
- Günlük seri: o gün en az bir level bitirilince sayılır; ana sayfada "🔥 N-DAY STREAK" rozeti.
- Kancalar: `GameManager._on_coin_collected` → `on_coin`, `_on_level_complete` → `on_level_complete`, `_on_player_died` → `on_death`, menüde reklamla kahraman açılınca `on_hero_unlocked`.

## Oyun İçi Değerlendirme (Google Play In-App Review, ücretsiz)
- Godot Android eklentisi (v2): kaynak `android_plugins/inapp_review/` (Java), derleme `tools/build_inapp_review.sh` → `addons/inapp_review/bin/InAppReview-release.aar` (commit'li). Export eklentisi `addons/inapp_review/export_plugin.gd` AAR'ı ve `com.google.android.play:review:2.0.2` bağımlılığını ekler; `project.godot` editor_plugins'te etkin olmalı.
- GDScript: `Progress.maybe_request_review(level, stars)` — Level ≥5 ve ≥2 yıldızda, en fazla 3 kez, aralarında ≥21 gün; sonuç ekranından 1.8 sn sonra. "Beğendin mi?" ara sorusu YOK (Google politikası). Pencereyi göstermeye Google karar verir; yalnızca Play'den kurulan sürümde çalışır.
- Doğrulandı: APK'da eklenti sınıfı + kayıt var, izin listesi önceki sürümle birebir aynı (Data safety değişmez).

## Mağaza Sayfası
- Metinler `docs/STORE_LISTING.md` (başlık/kısa/uzun açıklama, karakter sınırları kontrollü). Ekran görüntüleri 1080x1920 (Play 2:1 oran sınırı: 720x1560 kabul edilmez).
