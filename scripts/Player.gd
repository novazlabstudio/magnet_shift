extends RigidBody2D

var active_magnet: Node2D = null
var is_dead: bool = false
var is_level_complete: bool = false
# Sonuç ekranındaki mesaj için: "laser" ya da "guard"
var death_cause: String = ""

signal player_died

func _ready():
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	gravity_scale = 1.0
	linear_damp = 0.3
	angular_damp = 5.0
	lock_rotation = true
	max_contacts_reported = 4
	contact_monitor = true

func set_active_magnet(magnet: Node2D):
	active_magnet = magnet

func clear_active_magnet():
	active_magnet = null

# Ölüm animasyonunun süresi (PlayerVisual + DeathFX + kamera odağı bununla eşzamanlı).
# Bitince player_died yayınlanır ve sonuç ekranı açılır.
const DEATH_TIME := {"laser": 1.2, "guard": 1.05}
# Kahramana göre "Ahh!" perdesi: 0 Cyborg, 1 Pink, 2 Shadow, 3 Mech, 4 Blaze, 5 Polaris
const VOICE_PITCH := [1.0, 1.28, 0.86, 0.8, 0.95, 1.12]

func die(cause: String = ""):
	# Kapıya çekilirken lazer/bekçi değse de ölmez (iki animasyon çakışmasın)
	if is_dead or is_level_complete:
		return
	is_dead = true
	death_cause = cause if cause in ["laser", "guard"] else "guard"
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)

	var vis = get_node_or_null("Visual")
	var accent = Color(0.0, 0.85, 1.0)
	if vis and vis.has_method("play_death"):
		vis.play_death(death_cause)
		accent = vis.accent_color()
	var fx = Node2D.new()
	fx.name = "DeathFX"
	fx.set_script(load("res://scripts/DeathFX.gd"))
	add_child(fx)
	fx.setup(death_cause, accent)

	var gm = get_tree().current_scene
	if gm and gm.has_method("on_player_death_started"):
		gm.on_player_death_started(self, death_cause)

	# Darbe sesi ile çığlık aynı anda; çığlık kahramana göre perdelenir
	SoundManager.play_sfx("zap" if death_cause == "laser" else "hit", -2.0)
	var hero = HeroManager.get_hero()
	SoundManager.play_sfx("hero_ahh", 0.0, VOICE_PITCH[clamp(hero, 0, VOICE_PITCH.size() - 1)])

	await get_tree().create_timer(DEATH_TIME[death_cause]).timeout
	emit_signal("player_died")

func complete_level():
	if is_level_complete:
		return
	is_level_complete = true
