# Masaüstü test düzeneği (ekran görüntüsü, duman testi, tanıtım videosu)

Projenin bir KOPYASINI `$MS_SCR/ms_test` içine alır; AnalyticsManager/AdManager stub'lanır (gerçek GA olayı / reklam gitmez),
kullanıcı klasörü `magnet_shift_test` olur, Android eklentileri kapatılır ve `test/Runner.gd` autoload olarak eklenir.

    export MS_SCR=/tmp/magnet_shift_harness   # (varsayılan)
    ./tools/test_harness/sync.sh                       # kopyayı güncelle (her kod değişikliğinden sonra)
    "/Applications/Godot 4.6.app/Contents/MacOS/Godot" --headless --path $MS_SCR/ms_test --import   # ilk sefer
    ./tools/test_harness/shoot.sh menu                 # senaryo → $MS_SCR/shots/*.png
    MS_TIMEOUT=300 ./tools/test_harness/shoot.sh smoke # 50 level + 30 endless stage açılış testi
    MS_WIN=1080x1920 ./tools/test_harness/sync.sh; MS_RES=1080x1920 ./tools/test_harness/shoot.sh store   # mağaza görüntüleri
    MS_WIN=1080x1920 ./tools/test_harness/sync.sh; MS_RES=1080x1920 MS_TIMEOUT=1500 MS_EXTRA="--write-movie $MS_SCR/trailer.avi --fixed-fps 30" ./tools/test_harness/shoot.sh video

Senaryolar `Runner.gd` içinde: menu, menu_new, endless, endless_over, daily, result, skip, gameover, magnets, smoke, store, video, bot.
`bot`: görüş hattı otopilotu (lazer/bekçiye doğru uçmaz, platformların kenarından kayar). Kolay level'leri bitirir, zorlarda ölür.
macOS'ta `timeout` yok: `to <saniye> komut` kullanılır.
