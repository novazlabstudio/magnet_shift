extends Node
var shown := 0
func is_rewarded_ad_ready() -> bool: return true
func show_rewarded_ad(on_result: Callable) -> void:
	shown += 1
	print("[AD] rewarded shown")
	on_result.call_deferred(true)
