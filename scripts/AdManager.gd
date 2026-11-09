extends Node

# Global singleton - autoload olarak eklenecek
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const PROD_REWARDED_ID := "ca-app-pub-5920018930695278/5551017561"

var _rewarded_ad: RewardedAd = null
var _loader := RewardedAdLoader.new()
var _is_loading: bool = false

func _ready() -> void:
	_request_consent()

func _get_rewarded_ad_unit_id() -> String:
	return TEST_REWARDED_ID if OS.is_debug_build() else PROD_REWARDED_ID

func _request_consent() -> void:
	var params := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(
		params,
		func() -> void:
			if UserMessagingPlatform.consent_information.get_is_consent_form_available():
				_load_and_show_consent_form()
			else:
				_init_sdk(),
		func(_error: FormError) -> void:
			_init_sdk()
	)

func _load_and_show_consent_form() -> void:
	UserMessagingPlatform.load_consent_form(
		func(consent_form: ConsentForm) -> void:
			consent_form.show(func(_error: FormError) -> void:
				_init_sdk()
			),
		func(_error: FormError) -> void:
			_init_sdk()
	)

func _init_sdk() -> void:
	var on_init_listener := OnInitializationCompleteListener.new()
	on_init_listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_release_plugin_callbacks.call_deferred()
		_preload_rewarded_ad()
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(on_init_listener)

# Kapanış çökmesinin önlemi (Play Console: SIGABRT recursive_mutex::lock, 1.0.2).
# AdMob eklentisi bu dosyadaki lambda'ları kendi STATIC değişkenlerinde saklıyor
# (MobileAds init dinleyicisi, UserMessagingPlatform.consent_information ve form geri çağrıları).
# Uygulama kapanırken Godot (Main::cleanup -> GDScript::clear) bu static'leri temizlerken
# AdManager.gd betiği bazen önce silinmiş oluyor; lambda yok edilirken silinmiş betiğin
# mutex'i kilitlenip uygulama çöküyor. Geri çağrılar işini bitirince ve en geç ağaçtan
# çıkarken bu referansları bırakıyoruz; böylece kapanışta static'lerde lambda kalmıyor.
func _release_plugin_callbacks() -> void:
	MobileAds._current_on_initialization_complete_listener = null
	UserMessagingPlatform._on_consent_form_load_success_listener_callback = null
	UserMessagingPlatform._on_consent_form_load_failure_listener_callback = null
	UserMessagingPlatform._on_privacy_options_form_dismissed_callback = null
	var ci = UserMessagingPlatform.consent_information
	if ci:
		ci._on_consent_info_updated_success_callback = null
		ci._on_consent_info_updated_failure_callback = null

func _exit_tree() -> void:
	_release_plugin_callbacks()

func _preload_rewarded_ad() -> void:
	if _is_loading or _rewarded_ad:
		return
	_is_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_is_loading = false
		_rewarded_ad = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_is_loading = false
	_loader.load(_get_rewarded_ad_unit_id(), AdRequest.new(), callback)

func is_rewarded_ad_ready() -> bool:
	return _rewarded_ad != null

# on_result(earned: bool) çağrılır - reklam kapatıldığında ya da gösterilemediğinde.
func show_rewarded_ad(on_result: Callable) -> void:
	if not _rewarded_ad:
		on_result.call(false)
		_preload_rewarded_ad()
		return
	var ad := _rewarded_ad
	_rewarded_ad = null
	# Dictionary kullanılıyor çünkü GDScript'te bool gibi value type'lar
	# lambda'lara referans değil KOPYA olarak yakalanır; iki ayrı callback
	# aynı "earned" değerini paylaşamaz. Dictionary reference type olduğu
	# için paylaşılabiliyor.
	# "done": sonuç bu gösterim için yalnızca BİR kez bildirilir.
	var state := {"earned": false, "done": false}
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		if not state["done"]:
			state["earned"] = true
	var content_callbacks := FullScreenContentCallback.new()
	content_callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_rewarded(ad, state, on_result, state["earned"])
	content_callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		_finish_rewarded(ad, state, on_result, false)
	ad.full_screen_content_callback = content_callbacks
	ad.show(reward_listener)

# ÖNEMLİ: Eklentide tüm reklamlar tek RewardedAdLoader'dan yüklendiği için aynı uid'yi taşır.
# Biten reklam nesnesi eklentinin sinyallerine bağlı kalırsa (lambda'daki `ad` yakalaması onu
# canlı da tutuyordu) SONRAKİ reklam kapanınca eskisinin geri çağrısı da tetikleniyordu:
# 2. reklamda 1. reklamın ödülü tekrar sayılıyor, kahraman 3 yerine 2 reklamda açılıyordu.
# Bu yüzden: sonuç tek sefer bildirilir, nesnenin sinyalleri koparılır, döngü kırılır.
func _finish_rewarded(ad: RewardedAd, state: Dictionary, on_result: Callable, earned: bool) -> void:
	if state["done"]:
		return
	state["done"] = true
	_detach_rewarded(ad)
	ad.destroy()
	_preload_rewarded_ad()
	on_result.call(earned)

func _detach_rewarded(ad: RewardedAd) -> void:
	var pl = RewardedAd._plugin
	if pl == null:
		return
	var pairs = [
		["on_rewarded_ad_clicked", ad._on_rewarded_ad_clicked],
		["on_rewarded_ad_dismissed_full_screen_content", ad._on_rewarded_ad_dismissed_full_screen_content],
		["on_rewarded_ad_failed_to_show_full_screen_content", ad._on_rewarded_ad_failed_to_show_full_screen_content],
		["on_rewarded_ad_impression", ad._on_rewarded_ad_impression],
		["on_rewarded_ad_showed_full_screen_content", ad._on_rewarded_ad_showed_full_screen_content],
		["on_rewarded_ad_paid", ad._on_rewarded_ad_paid],
		["on_rewarded_ad_user_earned_reward", ad._on_rewarded_ad_user_earned_reward],
	]
	for pair in pairs:
		if pl.has_signal(pair[0]) and pl.is_connected(pair[0], pair[1]):
			pl.disconnect(pair[0], pair[1])
	# ad -> callback -> lambda -> ad döngüsünü kır (nesne serbest kalsın)
	ad.full_screen_content_callback = FullScreenContentCallback.new()
	ad._on_user_earned_reward_listener = OnUserEarnedRewardListener.new()
