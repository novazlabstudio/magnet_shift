extends Node

func _get_game_key() -> String:
	var p = ["278ef5f5", "a94a40c1", "092d6848", "2e04f9d0"]
	return "".join(p)

func _get_secret_key() -> String:
	var p = ["4d4d3655", "9ec56de8", "ce47bc84", "a3ccf8b3", "022ffd75"]
	return "".join(p)

const API_BASE = "https://api.gameanalytics.com/v2/%s"

var session_id: String = ""
var session_num: int = 0
var user_id: String = ""
var event_queue: Array = []
var http_init: HTTPRequest = null
var http_events: HTTPRequest = null
var is_sending: bool = false
var is_enabled: bool = false
var server_ts_offset: int = 0
var session_start_ts: int = 0

func _ready():
	_init_user()
	_init_session()
	http_init = HTTPRequest.new()
	add_child(http_init)
	http_init.request_completed.connect(_on_init_completed)
	http_events = HTTPRequest.new()
	add_child(http_events)
	http_events.request_completed.connect(_on_events_completed)
	_do_init()

func _init_user():
	if FileAccess.file_exists("user://ga_uid.dat"):
		var f = FileAccess.open("user://ga_uid.dat", FileAccess.READ)
		if f:
			user_id = f.get_line().strip_edges()
			session_num = f.get_32()
			f.close()
	if user_id.length() < 8:
		user_id = _generate_uuid()
		session_num = 0
	session_num += 1
	var f = FileAccess.open("user://ga_uid.dat", FileAccess.WRITE)
	if f:
		f.store_line(user_id)
		f.store_32(session_num)
		f.close()

func _init_session():
	session_id = _generate_uuid()
	session_start_ts = _get_ts()

func _generate_uuid() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return "%08x-%04x-%04x-%04x-%04x%04x%04x" % [
		rng.randi(), rng.randi() % 0xFFFF,
		(rng.randi() % 0x0FFF) | 0x4000,
		(rng.randi() % 0x3FFF) | 0x8000,
		rng.randi() % 0xFFFF, rng.randi() % 0xFFFF, rng.randi() % 0xFFFF
	]

func _get_ts() -> int:
	return int(Time.get_unix_time_from_system()) + server_ts_offset

func _do_init():
	var payload = JSON.stringify({
		"platform": "android",
		"os_version": "android 10",
		"sdk_version": "rest api v2",
		"user_id": user_id
	})
	var url = (API_BASE % _get_game_key()) + "/init"
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + _hmac_sha256(_get_secret_key(), payload)
	]
	http_init.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_init_completed(_result, response_code, _headers, body):
	if response_code == 200 or response_code == 201:
		is_enabled = true
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data.has("server_ts"):
				server_ts_offset = int(data["server_ts"]) - int(Time.get_unix_time_from_system())
		print("[GA] Init OK, enabled=", is_enabled)
		_send_session_start()
	else:
		print("[GA] Init failed: ", response_code, " - ", body.get_string_from_utf8())

func _send_session_start():
	var e = _base_event("user")
	event_queue.append(e)
	_flush()

func _base_event(category: String) -> Dictionary:
	return {
		"category": category,
		"session_id": session_id,
		"session_num": session_num,
		"user_id": user_id,
		"client_ts": _get_ts(),
		"sdk_version": "rest api v2",
		"os_version": "android 10",
		"manufacturer": OS.get_model_name(),
		"device": OS.get_model_name(),
		"platform": "android",
		"build": "1.0.0",
		"v": 2
	}

# ── PUBLIC API ────────────────────────────────────────────────────────────────

func level_start(level: int, hero: String):
	if not is_enabled: return
	var e = _base_event("progression")
	e["event_id"] = "Start:Level%02d" % level
	e["attempt_num"] = 1
	e["custom_01"] = hero
	event_queue.append(e)
	_flush()

func level_complete(level: int, hero: String, stars: int, coins: int):
	if not is_enabled: return
	var e = _base_event("progression")
	e["event_id"] = "Complete:Level%02d" % level
	e["attempt_num"] = 1
	e["score"] = coins
	e["custom_01"] = hero
	e["custom_02"] = "%d_stars" % stars
	event_queue.append(e)
	_flush()

func level_fail(level: int, hero: String, coins: int):
	if not is_enabled: return
	var e = _base_event("progression")
	e["event_id"] = "Fail:Level%02d" % level
	e["attempt_num"] = 1
	e["score"] = coins
	e["custom_01"] = hero
	event_queue.append(e)
	_flush()

func session_end():
	if not is_enabled: return
	var e = _base_event("session_end")
	e["length"] = _get_ts() - session_start_ts
	event_queue.append(e)
	_flush()

# ── GÖNDERME ─────────────────────────────────────────────────────────────────

func _flush():
	if is_sending or event_queue.is_empty() or not is_enabled:
		return
	is_sending = true
	var payload = JSON.stringify(event_queue)
	event_queue.clear()
	var url = (API_BASE % _get_game_key()) + "/events"
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + _hmac_sha256(_get_secret_key(), payload)
	]
	http_events.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_events_completed(_result, response_code, _headers, body):
	is_sending = false
	if response_code != 200:
		print("[GA] Event error %d: %s" % [response_code, body.get_string_from_utf8()])
	else:
		print("[GA] Events OK")
	if not event_queue.is_empty():
		_flush()

func _hmac_sha256(key: String, data: String) -> String:
	var key_bytes = key.to_utf8_buffer()
	var data_bytes = data.to_utf8_buffer()
	var block_size = 64
	if key_bytes.size() > block_size:
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(key_bytes)
		key_bytes = ctx.finish()
	while key_bytes.size() < block_size:
		key_bytes.append(0x00)
	var o_pad = PackedByteArray()
	var i_pad = PackedByteArray()
	for i in block_size:
		o_pad.append(key_bytes[i] ^ 0x5C)
		i_pad.append(key_bytes[i] ^ 0x36)
	var inner_ctx = HashingContext.new()
	inner_ctx.start(HashingContext.HASH_SHA256)
	inner_ctx.update(i_pad)
	inner_ctx.update(data_bytes)
	var inner_hash = inner_ctx.finish()
	var outer_ctx = HashingContext.new()
	outer_ctx.start(HashingContext.HASH_SHA256)
	outer_ctx.update(o_pad)
	outer_ctx.update(inner_hash)
	return Marshalls.raw_to_base64(outer_ctx.finish())

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		session_end()
