extends Node
const AD_BONUS_COINS := 10
var shown := 0
func is_rewarded_ad_ready() -> bool: return true
func show_rewarded_ad(on_result: Callable) -> void:
	shown += 1
	print("[AD] rewarded shown")
	Progress.add_coins(AD_BONUS_COINS, "AdBonus")
	on_result.call_deferred(true)
