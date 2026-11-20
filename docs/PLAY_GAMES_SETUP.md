# Google Play Games Services kurulumu (Magnet Shift 1.3.0)

Ücretsiz, sunucusuz: sıralamaları ve başarımları Google saklar. Oyun kodu hazır (`scripts/PlayGames.gd`, `android_plugins/novaz_services`); eksik olan yalnızca Play Console'daki kimlikler. Kimlikler gelince `scripts/PlayGamesIds.gd` doldurulur, `tools/build_services.sh` + `tools/build_aab.sh` çalıştırılır.

Görseller: `~/Desktop/MagnetShift_PlayGames/` (oyun ikonu 512, tanıtım görseli 1024x500, `achievements/*.png`, `leaderboards/*.png`; hepsi 512x512). Emoji çizimleri Noto Color Emoji (SIL OFL 1.1).

## 1. Projeyi oluştur
1. Play Console → Magnet Shift → **Grow users → Play Games Services → Setup and management → Configuration**.
2. "Does your game use Google APIs?" → **No, my game doesn't use Google APIs** → oyun adı `Magnet Shift` → **Create**. (Bir Google Cloud projesi kendiliğinden açılır.)
3. **Edit properties**: Display name `Magnet Shift`, Description (mağaza kısa açıklaması), Category **Arcade**, ikon `game_icon_512.png`, feature graphic `feature_graphic_1024x500.png` → **Save**.

## 2. OAuth onay ekranı (consent screen)
1. Configuration sayfasında **Credentials** bölümündeki uyarıda **Configure** → açılan Google Cloud linkine git.
2. User type **External**, uygulama adı `Magnet Shift`, destek ve geliştirici maili `novazlabstudio@gmail.com`, gizlilik politikası `https://novazlabstudio.github.io/magnet_shift_policy/`.
3. Kapsamlar (scopes): `games`, `games_lite`, `drive.appdata` (hiçbiri Google doğrulaması istemez).
4. **Publish app** (yayına al: "In production"). Yayına alınmazsa oyuncular giriş yapamaz.
5. Play Console'a dönüp **Done**.

## 3. Android kimlik bilgisi (credential)
1. Play Console → **Test and release → App integrity → App signing** → **App signing key certificate** altındaki **SHA-1** değerini kopyala (upload key değil!).
2. Play Games Configuration → **Add credential** → **Android** → Name `Magnet Shift` → **Create OAuth client** (Google Cloud açılır).
3. Google Cloud: Application type **Android**, Package name `com.novazlabstudio.magnetshift`, SHA-1 = 1. adımdaki değer → **Create**.
4. Play Console'a dön → **Done** → listeden yeni OAuth client'ı seç → **Save changes**.
5. Configuration sayfasının üstünde oyun adının altında yazan **Project ID** (yalnızca rakamlar) → bana gönder (= `APP_ID`).

## 4. Sıralamalar (Leaderboards)
**Setup and management → Leaderboards → Create leaderboard**; her biri için **Save as draft**. Tamper protection açık kalsın.

| Ad | Oyun anahtarı | Score format | Ordering | Limit (lower – upper) | İkon | Ne ölçer |
|---|---|---|---|---|---|---|
| Best Run | `run` | Numeric (0 ondalık) | Larger is better | 0 – 1000 | `best_run.png` | Bir koşuda (Level 1'den game over'a) toplanan coin |
| Total Stars | `stars` | Numeric | Larger is better | 0 – 150 | `total_stars.png` | 50 level'deki yıldız toplamı |
| Endless Climb | `endless` | Numeric | Larger is better | 0 – 999 | `endless.png` | Endless'ta geçilen stage |
| Daily Challenge | `daily` | **Time** (milisaniye) | **Smaller is better** | 3000 – 600000 | `daily.png` | Günün level'inin süresi; Daily/Weekly sekmeleri otomatik |

Kaydettikten sonra her sıralamanın **ID**'sini (CgkI… ile başlar) kopyala.

## 5. Başarımlar (Achievements)
**Setup and management → Achievements → Create achievement**; tür Standard, **Save as draft**. Puanlar 5'in katı (toplam 720 / 2000).

| # | Oyun anahtarı | Name | Description | Points | İkon |
|---|---|---|---|---|---|
| 1 | `first_clear` | First Escape | Complete Level 1 | 5 | `achievements/01_first_clear.png` |
| 2 | `lvl5` | Warming Up | Reach Level 5 | 10 | `achievements/02_lvl5.png` |
| 3 | `lvl10` | Magnetized | Reach Level 10 | 15 | `achievements/03_lvl10.png` |
| 4 | `lvl20` | Gravity Defier | Reach Level 20 | 25 | `achievements/04_lvl20.png` |
| 5 | `lvl30` | Sky Climber | Reach Level 30 | 35 | `achievements/05_lvl30.png` |
| 6 | `lvl40` | Polar Master | Reach Level 40 | 50 | `achievements/06_lvl40.png` |
| 7 | `lvl50` | Event Horizon | Complete all 50 levels | 100 | `achievements/07_lvl50.png` |
| 8 | `star3` | Perfectionist | Get 3 stars on a level | 10 | `achievements/08_star3.png` |
| 9 | `star3_10` | Star Collector | Get 3 stars on 10 levels | 40 | `achievements/09_star3_10.png` |
| 10 | `star3_30` | Constellation | Get 3 stars on 30 levels | 100 | `achievements/10_star3_30.png` |
| 11 | `coins100` | Coin Hunter | Collect 100 coins in total | 15 | `achievements/11_coins100.png` |
| 12 | `coins500` | Treasure Magnet | Collect 500 coins in total | 50 | `achievements/12_coins500.png` |
| 13 | `run50` | Big Run | Score 50 coins in a single run | 40 | `achievements/13_run50.png` |
| 14 | `clean5` | Untouchable | Clear 5 levels in a row without dying | 30 | `achievements/14_clean5.png` |
| 15 | `zap10` | Shock Absorber | Get zapped 10 times | 10 | `achievements/15_zap10.png` |
| 16 | `streak3` | Regular | Play 3 days in a row | 15 | `achievements/16_streak3.png` |
| 17 | `streak7` | Dedicated | Play 7 days in a row | 50 | `achievements/17_streak7.png` |
| 18 | `collector` | Collector | Unlock an ad-reward hero | 25 | `achievements/18_collector.png` |
| 19 | `shopper` | Style Points | Buy something in the shop | 15 | `achievements/19_shopper.png` |
| 20 | `endless10` | Endless Climber | Reach stage 10 in Endless | 60 | `achievements/20_endless10.png` |
| 21 | `daily_clear` | Daily Runner | Clear a Daily Challenge | 20 | `achievements/21_daily_clear.png` |

## 6. Kimlikleri gönder
Bana şu listeyi gönder (kopyala-yapıştır yeter):
```
APP_ID: 123456789012
run: CgkI...
stars: CgkI...
endless: CgkI...
daily: CgkI...
first_clear: CgkI...   (21 başarımın hepsi, anahtar: ID)
```
Ben `scripts/PlayGamesIds.gd`'yi doldurup AAB'yi derlerim.

## 7. Test ve yayın
1. **Setup and management → Testers → Add testers** → kendi Google hesabın (Play Games testleri için).
2. Yeni AAB'yi Production'a gönder. İnceleme sürerken Play Games tarafını **Setup and management → Publishing → Review and publish** ile yayınla (yayına geçmesi ~2 saat; oyunun mağaza görünürlüğünü etkilemez).
3. Telefonda: oyunu aç → BOARD → **🌍 GLOBAL**; AWARDS → **🎮 PLAY GAMES**.

## Data safety (Play Games eklenince)
Google'ın PGS veri sayfası: Games hesabı (oyuncu adı/avatar), analitik ve teşhis verisi, başarım/skor verisi toplanır ([kaynak](https://developer.android.com/games/pgs/data-collection)). Form güncellemesi: App content → Data safety → mevcut "App interactions" ve "Diagnostics" zaten var; ek olarak **Personal info → User IDs** (Play Games oyuncu kimliği; collected, ephemeral değil, amaç: App functionality) işaretle. Gizlilik politikasına Google Play Games satırı ekle.
