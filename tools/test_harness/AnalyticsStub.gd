extends Node
var is_enabled := false
var log: Array = []
func level_start(level: int, hero: String): log.append("start %d" % level)
func level_complete(level: int, hero: String, stars: int, coins: int): log.append("complete %d" % level)
func level_fail(level: int, hero: String, coins: int): log.append("fail %d" % level)
func design_event(event_id: String, value: float = NAN): log.append(event_id); print("[GA] ", event_id, "" if is_nan(value) else " = %s" % value)
func session_end(): pass
