extends RefCounted
# Google Play Games Services kimlikleri (Play Console > Play Games Services > Setup and management).
# APP_ID boşken Play Games tamamen kapalıdır; oyun normal çalışır. APP_ID değişince
# tools/build_services.sh yeniden çalıştırılmalı (kimlik AAR'ın içine yazılır).

const APP_ID := "1001577090011"

# Sıralamalar (Leaderboards) — anahtar: oyundaki ad, değer: Play Console'daki kimlik (CgkI...)
const LEADERBOARDS := {
	"run": "CgkI25eWlZMdEAIQAw",      # Best Run (bir koşuda toplanan coin) — büyük daha iyi
	"stars": "CgkI25eWlZMdEAIQBA",    # Total Stars (0-150) — büyük daha iyi
	"endless": "CgkI25eWlZMdEAIQBQ",  # Endless Climb (ulaşılan stage) — büyük daha iyi
	"daily": "CgkI25eWlZMdEAIQBg",    # Daily Challenge (süre, ms) — KÜÇÜK daha iyi, biçim: Time (milliseconds)
}

# Başarımlar — anahtar: Progress.AWARDS id'si
const ACHIEVEMENTS := {
	"first_clear": "CgkI25eWlZMdEAIQBw",
	"lvl5": "CgkI25eWlZMdEAIQCA",
	"lvl10": "CgkI25eWlZMdEAIQCQ",
	"lvl20": "CgkI25eWlZMdEAIQCg",
	"lvl30": "CgkI25eWlZMdEAIQCw",
	"lvl40": "CgkI25eWlZMdEAIQDA",
	"lvl50": "CgkI25eWlZMdEAIQDQ",
	"star3": "CgkI25eWlZMdEAIQDg",
	"star3_10": "CgkI25eWlZMdEAIQDw",
	"star3_30": "CgkI25eWlZMdEAIQEA",
	"coins100": "CgkI25eWlZMdEAIQEQ",
	"coins500": "CgkI25eWlZMdEAIQEg",
	"run50": "CgkI25eWlZMdEAIQEw",
	"clean5": "CgkI25eWlZMdEAIQFA",
	"zap10": "CgkI25eWlZMdEAIQFQ",
	"streak3": "CgkI25eWlZMdEAIQFg",
	"streak7": "CgkI25eWlZMdEAIQFw",
	"collector": "CgkI25eWlZMdEAIQGA",
	"shopper": "CgkI25eWlZMdEAIQGQ",
	"endless10": "CgkI25eWlZMdEAIQGg",
	"daily_clear": "CgkI25eWlZMdEAIQGw",
}
