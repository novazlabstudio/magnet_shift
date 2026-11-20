extends RefCounted
# Google Play Games Services kimlikleri (Play Console > Play Games Services > Setup and management).
# APP_ID boşken Play Games tamamen kapalıdır; oyun normal çalışır. APP_ID değişince
# tools/build_services.sh yeniden çalıştırılmalı (kimlik AAR'ın içine yazılır).

const APP_ID := ""

# Sıralamalar (Leaderboards) — anahtar: oyundaki ad, değer: Play Console'daki kimlik (CgkI...)
const LEADERBOARDS := {
	"run": "",      # Best Run (bir koşuda toplanan coin) — büyük daha iyi
	"stars": "",    # Total Stars (0-150) — büyük daha iyi
	"endless": "",  # Endless Climb (ulaşılan stage) — büyük daha iyi
	"daily": "",    # Daily Challenge (süre, ms) — KÜÇÜK daha iyi, biçim: Time (milliseconds)
}

# Başarımlar — anahtar: Progress.AWARDS id'si
const ACHIEVEMENTS := {
	"first_clear": "", "lvl5": "", "lvl10": "", "lvl20": "", "lvl30": "", "lvl40": "", "lvl50": "",
	"star3": "", "star3_10": "", "star3_30": "", "coins100": "", "coins500": "", "run50": "",
	"clean5": "", "zap10": "", "streak3": "", "streak7": "", "collector": "",
	"shopper": "", "endless10": "", "daily_clear": "",
}
