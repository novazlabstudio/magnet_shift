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
		_preload_rewarded_ad()
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(on_init_listener)

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
	var state := {"earned": false}
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		state["earned"] = true
	var content_callbacks := FullScreenContentCallback.new()
	content_callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_preload_rewarded_ad()
		on_result.call(state["earned"])
	content_callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_preload_rewarded_ad()
		on_result.call(false)
	ad.full_screen_content_callback = content_callbacks
	ad.show(reward_listener)
