extends Node2D

const ScreenUtil = preload("res://scripts/ScreenUtil.gd")

@export var next_level_path: String = ""
@export var level_number: int = 1

var active_touches: Dictionary = {}
var player: RigidBody2D = null
var magnets: Array = []
var music_player: AudioStreamPlayer = null
var score: int = 0
var total_coins: int = 0
var coins_collected: int = 0
var level_active: bool = true
var total_score: int = 0
var _bg_time: float = 0.0
var lives: int = 3
var lives_label: Label = null
var coins_since_last_life: int = 0

var score_label: Label
var total_score_label: Label
var status_label: Label
var retry_button: Button
var next_button: Button
var tap_hint: Label
var sound_button: Button
# Çentik payı (HUD'u aşağı iter) ve uzun ekranlarda panelleri ortalamak için dikey kayma
var hud_top: float = 0.0
var ui_dy: float = 0.0

func get_level_data() -> Dictionary:
	var levels = {
		1: {"bg":Color(0.55,0.78,0.9),"pc":Color(0.25,0.55,0.75),"platforms":[Vector4(25,750,200,18), Vector4(255,130,200,18)],"extra_magnets":[Vector2(430,427)],"coins":[Vector2(125,710), Vector2(355,90)],"lasers":[],"guards":[],"exit":Vector2(60,75)},
		2: {"bg":Color(0.1,0.15,0.35),"pc":Color(0.2,0.45,0.65),"platforms":[Vector4(25,750,180,18), Vector4(275,440,180,18), Vector4(25,130,180,18)],"extra_magnets":[Vector2(50,427)],"coins":[Vector2(115,710), Vector2(365,400), Vector2(115,90)],"lasers":[],"guards":[],"exit":Vector2(420,75)},
		3: {"bg":Color(0.08,0.12,0.25),"pc":Color(0.2,0.4,0.6),"platforms":[Vector4(25,750,170,18), Vector4(285,543,170,18), Vector4(25,336,170,18), Vector4(285,130,170,18)],"extra_magnets":[Vector2(430,427)],"coins":[Vector2(110,710), Vector2(370,503), Vector2(110,296), Vector2(370,90)],"lasers":[],"guards":[],"exit":Vector2(60,75)},
		4: {"bg":Color(0.05,0.15,0.1),"pc":Color(0.15,0.5,0.25),"platforms":[Vector4(295,750,160,18), Vector4(25,543,160,18), Vector4(295,336,160,18), Vector4(25,130,160,18)],"extra_magnets":[Vector2(50,427)],"coins":[Vector2(375,710), Vector2(105,503), Vector2(375,296), Vector2(105,90)],"lasers":[{"pos":Vector2(240,681),"size":Vector2(148,10),"blink":false}],"guards":[],"exit":Vector2(420,75)},
		5: {"bg":Color(0.1,0.1,0.04),"pc":Color(0.45,0.38,0.1),"platforms":[Vector4(25,750,155,18), Vector4(300,595,155,18), Vector4(25,440,155,18), Vector4(300,285,155,18), Vector4(25,130,155,18)],"extra_magnets":[Vector2(50,427)],"coins":[Vector2(102,710), Vector2(377,555), Vector2(102,400), Vector2(377,245), Vector2(102,90)],"lasers":[{"pos":Vector2(240,699),"size":Vector2(151,10),"blink":false}],"guards":[],"exit":Vector2(420,75)},
		6: {"bg":Color(0.1,0.04,0.12),"pc":Color(0.4,0.1,0.45),"platforms":[Vector4(25,750,150,18), Vector4(305,595,150,18), Vector4(25,440,150,18), Vector4(305,285,150,18), Vector4(25,130,150,18)],"extra_magnets":[Vector2(50,318), Vector2(430,535)],"coins":[Vector2(100,710), Vector2(380,555), Vector2(100,400), Vector2(380,245)],"lasers":[{"pos":Vector2(240,699),"size":Vector2(154,10),"blink":false}, {"pos":Vector2(240,544),"size":Vector2(154,10),"blink":true}],"guards":[{"pos":Vector2(380,595),"patrol":105.0}],"exit":Vector2(420,75)},
		7: {"bg":Color(0.03,0.08,0.14),"pc":Color(0.1,0.32,0.52),"platforms":[Vector4(25,750,145,18), Vector4(310,626,145,18), Vector4(25,502,145,18), Vector4(310,378,145,18), Vector4(25,254,145,18), Vector4(310,130,145,18)],"extra_magnets":[Vector2(430,318), Vector2(50,535)],"coins":[Vector2(97,710), Vector2(382,586), Vector2(97,462), Vector2(382,338), Vector2(97,214)],"lasers":[{"pos":Vector2(240,709),"size":Vector2(156,10),"blink":false}, {"pos":Vector2(240,585),"size":Vector2(156,10),"blink":true}],"guards":[{"pos":Vector2(382,626),"patrol":101.0}],"exit":Vector2(60,75)},
		8: {"bg":Color(0.13,0.03,0.05),"pc":Color(0.52,0.13,0.16),"platforms":[Vector4(315,750,140,18), Vector4(25,626,140,18), Vector4(315,502,140,18), Vector4(25,378,140,18), Vector4(315,254,140,18), Vector4(25,130,140,18)],"extra_magnets":[Vector2(50,318), Vector2(430,535), Vector2(80,476), Vector2(400,905)],"coins":[Vector2(385,710), Vector2(95,586), Vector2(385,462), Vector2(95,338), Vector2(385,214)],"lasers":[{"pos":Vector2(240,709),"size":Vector2(159,10),"blink":false}, {"pos":Vector2(240,585),"size":Vector2(159,10),"blink":true}, {"pos":Vector2(240,461),"size":Vector2(159,10),"blink":false}],"guards":[{"pos":Vector2(95,626),"patrol":98.0}, {"pos":Vector2(95,378),"patrol":98.0}],"exit":Vector2(420,75)},
		9: {"bg":Color(0.04,0.1,0.12),"pc":Color(0.1,0.44,0.42),"platforms":[Vector4(25,750,135,18), Vector4(320,626,135,18), Vector4(25,502,135,18), Vector4(320,378,135,18), Vector4(25,254,135,18), Vector4(320,130,135,18)],"extra_magnets":[Vector2(430,318), Vector2(50,535), Vector2(400,523), Vector2(80,988)],"coins":[Vector2(92,710), Vector2(387,586), Vector2(92,462), Vector2(387,338), Vector2(92,214)],"lasers":[{"pos":Vector2(240,709),"size":Vector2(162,10),"blink":false}, {"pos":Vector2(240,585),"size":Vector2(162,10),"blink":true}, {"pos":Vector2(240,461),"size":Vector2(162,10),"blink":false}],"guards":[{"pos":Vector2(387,626),"patrol":94.0}, {"pos":Vector2(387,378),"patrol":94.0}],"exit":Vector2(60,75)},
		10: {"bg":Color(0.07,0.0,0.14),"pc":Color(0.44,0.0,0.65),"platforms":[Vector4(25,750,130,18), Vector4(325,626,130,18), Vector4(25,502,130,18), Vector4(325,378,130,18), Vector4(25,254,130,18), Vector4(325,130,130,18)],"extra_magnets":[Vector2(430,318), Vector2(50,535), Vector2(400,570), Vector2(80,1072)],"coins":[Vector2(90,710), Vector2(390,586), Vector2(90,462), Vector2(390,338), Vector2(90,214)],"lasers":[{"pos":Vector2(240,709),"size":Vector2(165,10),"blink":false}, {"pos":Vector2(240,585),"size":Vector2(165,10),"blink":true}, {"pos":Vector2(240,461),"size":Vector2(165,10),"blink":false}, {"pos":Vector2(240,337),"size":Vector2(165,10),"blink":true}],"guards":[{"pos":Vector2(390,626),"patrol":91.0}, {"pos":Vector2(390,378),"patrol":91.0}],"exit":Vector2(60,75)},
		11: {"bg":Color(0.0,0.06,0.14),"pc":Color(0.06,0.37,0.62),"platforms":[Vector4(25,750,125,18), Vector4(330,646,125,18), Vector4(25,543,125,18), Vector4(330,440,125,18), Vector4(25,336,125,18), Vector4(330,233,125,18), Vector4(25,130,125,18)],"extra_magnets":[Vector2(50,318), Vector2(430,535), Vector2(80,617), Vector2(400,1155)],"coins":[Vector2(87,710), Vector2(392,606), Vector2(87,503), Vector2(392,400), Vector2(87,296), Vector2(392,193)],"lasers":[{"pos":Vector2(240,716),"size":Vector2(167,10),"blink":false}, {"pos":Vector2(240,612),"size":Vector2(167,10),"blink":true}, {"pos":Vector2(240,509),"size":Vector2(167,10),"blink":false}, {"pos":Vector2(240,406),"size":Vector2(167,10),"blink":true}],"guards":[{"pos":Vector2(392,646),"patrol":87.0}, {"pos":Vector2(392,440),"patrol":87.0}, {"pos":Vector2(392,233),"patrol":87.0}],"exit":Vector2(420,75)},
		12: {"bg":Color(0.1,0.07,0.0),"pc":Color(0.54,0.3,0.06),"platforms":[Vector4(335,750,120,18), Vector4(25,646,120,18), Vector4(335,543,120,18), Vector4(25,440,120,18), Vector4(335,336,120,18), Vector4(25,233,120,18), Vector4(335,130,120,18)],"extra_magnets":[Vector2(430,318), Vector2(50,535), Vector2(400,664), Vector2(80,1239)],"coins":[Vector2(395,710), Vector2(85,606), Vector2(395,503), Vector2(85,400), Vector2(395,296), Vector2(85,193)],"lasers":[{"pos":Vector2(240,716),"size":Vector2(170,10),"blink":false}, {"pos":Vector2(240,612),"size":Vector2(170,10),"blink":true}, {"pos":Vector2(240,509),"size":Vector2(170,10),"blink":false}, {"pos":Vector2(240,406),"size":Vector2(170,10),"blink":true}],"guards":[{"pos":Vector2(85,646),"patrol":84.0}, {"pos":Vector2(85,440),"patrol":84.0}, {"pos":Vector2(85,233),"patrol":84.0}],"exit":Vector2(60,75)},
		13: {"bg":Color(0.0,0.1,0.06),"pc":Color(0.06,0.5,0.24),"platforms":[Vector4(25,750,115,18), Vector4(340,646,115,18), Vector4(25,543,115,18), Vector4(340,440,115,18), Vector4(25,336,115,18), Vector4(340,233,115,18), Vector4(25,130,115,18)],"extra_magnets":[Vector2(50,318), Vector2(430,535), Vector2(80,711), Vector2(400,1322)],"coins":[Vector2(82,710), Vector2(397,606), Vector2(82,503), Vector2(397,400), Vector2(82,296), Vector2(397,193)],"lasers":[{"pos":Vector2(240,716),"size":Vector2(173,10),"blink":false}, {"pos":Vector2(240,612),"size":Vector2(173,10),"blink":true}, {"pos":Vector2(240,509),"size":Vector2(173,10),"blink":false}, {"pos":Vector2(240,406),"size":Vector2(173,10),"blink":true}, {"pos":Vector2(240,302),"size":Vector2(173,10),"blink":false}],"guards":[{"pos":Vector2(397,646),"patrol":80.0}, {"pos":Vector2(397,440),"patrol":80.0}, {"pos":Vector2(397,233),"patrol":80.0}],"exit":Vector2(420,75)},
		14: {"bg":Color(0.09,0.0,0.09),"pc":Color(0.44,0.06,0.44),"platforms":[Vector4(25,750,110,18), Vector4(345,646,110,18), Vector4(25,543,110,18), Vector4(345,440,110,18), Vector4(25,336,110,18), Vector4(345,233,110,18), Vector4(25,130,110,18)],"extra_magnets":[Vector2(50,318), Vector2(430,535), Vector2(80,758), Vector2(400,1406)],"coins":[Vector2(80,710), Vector2(400,606), Vector2(80,503), Vector2(400,400), Vector2(80,296), Vector2(400,193)],"lasers":[{"pos":Vector2(240,716),"size":Vector2(176,10),"blink":false}, {"pos":Vector2(240,612),"size":Vector2(176,10),"blink":true}, {"pos":Vector2(240,509),"size":Vector2(176,10),"blink":false}, {"pos":Vector2(240,406),"size":Vector2(176,10),"blink":true}, {"pos":Vector2(240,302),"size":Vector2(176,10),"blink":false}],"guards":[{"pos":Vector2(400,646),"patrol":77.0}, {"pos":Vector2(400,440),"patrol":77.0}, {"pos":Vector2(400,233),"patrol":77.0}],"exit":Vector2(420,75)},
		15: {"bg":Color(0.0,0.0,0.15),"pc":Color(0.13,0.13,0.57),"platforms":[Vector4(25,750,105,18), Vector4(350,661,105,18), Vector4(25,572,105,18), Vector4(350,484,105,18), Vector4(25,395,105,18), Vector4(350,307,105,18), Vector4(25,218,105,18), Vector4(350,130,105,18)],"extra_magnets":[Vector2(430,318), Vector2(50,535), Vector2(400,531), Vector2(80,942), Vector2(400,1352), Vector2(80,1763)],"coins":[Vector2(77,710), Vector2(402,621), Vector2(77,532), Vector2(402,444), Vector2(77,355), Vector2(402,267), Vector2(77,178)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(178,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(178,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(178,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(178,10),"blink":true}, {"pos":Vector2(240,366),"size":Vector2(178,10),"blink":false}],"guards":[{"pos":Vector2(402,661),"patrol":73.0}, {"pos":Vector2(402,484),"patrol":73.0}, {"pos":Vector2(402,307),"patrol":73.0}, {"pos":Vector2(402,130),"patrol":73.0}],"exit":Vector2(60,75)},
		16: {"bg":Color(0.07,0.0,0.0),"pc":Color(0.5,0.11,0.11),"platforms":[Vector4(353,750,102,18), Vector4(25,661,102,18), Vector4(353,572,102,18), Vector4(25,484,102,18), Vector4(353,395,102,18), Vector4(25,307,102,18), Vector4(353,218,102,18), Vector4(25,130,102,18)],"extra_magnets":[Vector2(50,264), Vector2(430,427), Vector2(50,589), Vector2(80,564), Vector2(400,996), Vector2(80,1429), Vector2(400,1861)],"coins":[Vector2(404,710), Vector2(76,621), Vector2(404,532), Vector2(76,444), Vector2(404,355), Vector2(76,267), Vector2(404,178)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(180,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(180,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(180,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(180,10),"blink":true}, {"pos":Vector2(240,366),"size":Vector2(180,10),"blink":false}],"guards":[{"pos":Vector2(76,661),"patrol":71.0}, {"pos":Vector2(76,484),"patrol":71.0}, {"pos":Vector2(76,307),"patrol":71.0}, {"pos":Vector2(76,130),"patrol":71.0}],"exit":Vector2(420,75)},
		17: {"bg":Color(0.0,0.09,0.07),"pc":Color(0.07,0.42,0.32),"platforms":[Vector4(25,750,98,18), Vector4(357,661,98,18), Vector4(25,572,98,18), Vector4(357,484,98,18), Vector4(25,395,98,18), Vector4(357,307,98,18), Vector4(25,218,98,18), Vector4(357,130,98,18)],"extra_magnets":[Vector2(430,264), Vector2(50,427), Vector2(430,589), Vector2(400,596), Vector2(80,1051), Vector2(400,1505), Vector2(80,1959)],"coins":[Vector2(74,710), Vector2(406,621), Vector2(74,532), Vector2(406,444), Vector2(74,355), Vector2(406,267), Vector2(74,178)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(182,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(182,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(182,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(182,10),"blink":true}, {"pos":Vector2(240,366),"size":Vector2(182,10),"blink":false}, {"pos":Vector2(240,278),"size":Vector2(182,10),"blink":true}],"guards":[{"pos":Vector2(406,661),"patrol":68.0}, {"pos":Vector2(406,484),"patrol":68.0}, {"pos":Vector2(406,307),"patrol":68.0}, {"pos":Vector2(406,130),"patrol":68.0}],"exit":Vector2(60,75)},
		18: {"bg":Color(0.11,0.06,0.11),"pc":Color(0.47,0.11,0.47),"platforms":[Vector4(25,750,94,18), Vector4(361,661,94,18), Vector4(25,572,94,18), Vector4(361,484,94,18), Vector4(25,395,94,18), Vector4(361,307,94,18), Vector4(25,218,94,18), Vector4(361,130,94,18)],"extra_magnets":[Vector2(430,264), Vector2(50,427), Vector2(430,589), Vector2(400,417), Vector2(80,682), Vector2(400,946), Vector2(80,1211), Vector2(400,1475), Vector2(80,1740), Vector2(400,2004), Vector2(80,2269)],"coins":[Vector2(72,710), Vector2(408,621), Vector2(72,532), Vector2(408,444), Vector2(72,355), Vector2(408,267), Vector2(72,178)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(184,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(184,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(184,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(184,10),"blink":true}],"guards":[{"pos":Vector2(408,661),"patrol":65.0}, {"pos":Vector2(408,484),"patrol":65.0}, {"pos":Vector2(408,307),"patrol":65.0}],"exit":Vector2(60,75)},
		19: {"bg":Color(0.02,0.02,0.05),"pc":Color(0.33,0.33,0.36),"platforms":[Vector4(25,750,90,18), Vector4(365,661,90,18), Vector4(25,572,90,18), Vector4(365,484,90,18), Vector4(25,395,90,18), Vector4(365,307,90,18), Vector4(25,218,90,18), Vector4(365,130,90,18)],"extra_magnets":[Vector2(430,264), Vector2(50,427), Vector2(430,589), Vector2(400,440), Vector2(80,717), Vector2(400,993), Vector2(80,1270), Vector2(400,1547), Vector2(80,1823), Vector2(400,2100), Vector2(80,2377)],"coins":[Vector2(70,710), Vector2(410,621), Vector2(70,532), Vector2(410,444), Vector2(70,355), Vector2(410,267), Vector2(70,178)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(187,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(187,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(187,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(187,10),"blink":true}, {"pos":Vector2(240,366),"size":Vector2(187,10),"blink":false}, {"pos":Vector2(240,278),"size":Vector2(187,10),"blink":true}],"guards":[{"pos":Vector2(410,661),"patrol":62.0}, {"pos":Vector2(410,484),"patrol":62.0}, {"pos":Vector2(410,307),"patrol":62.0}, {"pos":Vector2(410,130),"patrol":62.0}],"exit":Vector2(60,75)},
		20: {"bg":Color(0.0,0.0,0.0),"pc":Color(0.65,0.55,0.0),"platforms":[Vector4(369,750,86,18), Vector4(25,661,86,18), Vector4(369,572,86,18), Vector4(25,484,86,18), Vector4(369,395,86,18), Vector4(25,307,86,18), Vector4(369,218,86,18), Vector4(25,130,86,18)],"extra_magnets":[Vector2(50,264), Vector2(430,427), Vector2(50,589), Vector2(80,463), Vector2(400,751), Vector2(80,1040), Vector2(400,1329), Vector2(80,1618), Vector2(400,1907), Vector2(80,2196), Vector2(400,2485)],"coins":[Vector2(412,710), Vector2(68,621), Vector2(412,532), Vector2(68,444), Vector2(412,355), Vector2(68,267), Vector2(412,178), Vector2(68,90)],"lasers":[{"pos":Vector2(240,721),"size":Vector2(189,10),"blink":false}, {"pos":Vector2(240,632),"size":Vector2(189,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(189,10),"blink":false}, {"pos":Vector2(240,455),"size":Vector2(189,10),"blink":true}, {"pos":Vector2(240,366),"size":Vector2(189,10),"blink":false}, {"pos":Vector2(240,278),"size":Vector2(189,10),"blink":true}, {"pos":Vector2(240,189),"size":Vector2(189,10),"blink":false}],"guards":[{"pos":Vector2(68,661),"patrol":60.0}, {"pos":Vector2(68,484),"patrol":60.0}, {"pos":Vector2(68,307),"patrol":60.0}, {"pos":Vector2(68,130),"patrol":60.0}],"exit":Vector2(420,75)},
		21: {"bg":Color(0.0,0.04,0.1),"pc":Color(0.08,0.28,0.55),"platforms":[Vector4(25,750,84,18), Vector4(371,672,84,18), Vector4(25,595,84,18), Vector4(371,517,84,18), Vector4(25,440,84,18), Vector4(371,362,84,18), Vector4(25,285,84,18), Vector4(371,207,84,18), Vector4(25,130,84,18)],"extra_magnets":[Vector2(50,264), Vector2(430,427), Vector2(50,589), Vector2(80,485), Vector2(400,786), Vector2(80,1087), Vector2(400,1388), Vector2(80,1689), Vector2(400,1990), Vector2(80,2291), Vector2(400,2592)],"coins":[Vector2(67,710), Vector2(413,632), Vector2(67,555), Vector2(413,477), Vector2(67,400), Vector2(413,322), Vector2(67,245), Vector2(413,167)],"lasers":[{"pos":Vector2(240,724),"size":Vector2(190,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(190,10),"blink":true}, {"pos":Vector2(240,569),"size":Vector2(190,10),"blink":false}, {"pos":Vector2(240,492),"size":Vector2(190,10),"blink":true}, {"pos":Vector2(240,414),"size":Vector2(190,10),"blink":false}, {"pos":Vector2(240,337),"size":Vector2(190,10),"blink":true}],"guards":[{"pos":Vector2(413,672),"patrol":58.0}, {"pos":Vector2(413,517),"patrol":58.0}, {"pos":Vector2(413,362),"patrol":58.0}, {"pos":Vector2(413,207),"patrol":58.0}],"exit":Vector2(420,75)},
		22: {"bg":Color(0.05,0.0,0.1),"pc":Color(0.35,0.05,0.55),"platforms":[Vector4(25,750,82,18), Vector4(373,672,82,18), Vector4(25,595,82,18), Vector4(373,517,82,18), Vector4(25,440,82,18), Vector4(373,362,82,18), Vector4(25,285,82,18), Vector4(373,207,82,18), Vector4(25,130,82,18)],"extra_magnets":[Vector2(50,264), Vector2(430,427), Vector2(50,589), Vector2(80,451), Vector2(400,707), Vector2(80,963), Vector2(400,1220), Vector2(80,1476), Vector2(400,1732), Vector2(80,1988), Vector2(400,2245), Vector2(80,2501), Vector2(400,2757)],"coins":[Vector2(66,710), Vector2(414,632), Vector2(66,555), Vector2(414,477), Vector2(66,400), Vector2(414,322), Vector2(66,245), Vector2(414,167)],"lasers":[{"pos":Vector2(240,724),"size":Vector2(191,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(191,10),"blink":true}, {"pos":Vector2(240,569),"size":Vector2(191,10),"blink":false}, {"pos":Vector2(240,492),"size":Vector2(191,10),"blink":true}, {"pos":Vector2(240,414),"size":Vector2(191,10),"blink":false}, {"pos":Vector2(240,337),"size":Vector2(191,10),"blink":true}],"guards":[{"pos":Vector2(414,672),"patrol":57.0}, {"pos":Vector2(414,517),"patrol":57.0}, {"pos":Vector2(414,362),"patrol":57.0}, {"pos":Vector2(414,207),"patrol":57.0}],"exit":Vector2(420,75)},
		23: {"bg":Color(0.08,0.0,0.05),"pc":Color(0.55,0.0,0.25),"platforms":[Vector4(25,750,80,18), Vector4(375,672,80,18), Vector4(25,595,80,18), Vector4(375,517,80,18), Vector4(25,440,80,18), Vector4(375,362,80,18), Vector4(25,285,80,18), Vector4(375,207,80,18), Vector4(25,130,80,18)],"extra_magnets":[Vector2(50,264), Vector2(430,427), Vector2(50,589), Vector2(80,471), Vector2(400,738), Vector2(80,1004), Vector2(400,1270), Vector2(80,1536), Vector2(400,1802), Vector2(80,2069), Vector2(400,2335), Vector2(80,2601), Vector2(400,2867)],"coins":[Vector2(65,710), Vector2(415,632), Vector2(65,555), Vector2(415,477), Vector2(65,400), Vector2(415,322), Vector2(65,245), Vector2(415,167)],"lasers":[{"pos":Vector2(240,724),"size":Vector2(192,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(192,10),"blink":true}, {"pos":Vector2(240,569),"size":Vector2(192,10),"blink":false}, {"pos":Vector2(240,492),"size":Vector2(192,10),"blink":true}, {"pos":Vector2(240,414),"size":Vector2(192,10),"blink":false}, {"pos":Vector2(240,337),"size":Vector2(192,10),"blink":true}, {"pos":Vector2(240,259),"size":Vector2(192,10),"blink":false}],"guards":[{"pos":Vector2(415,672),"patrol":56.0}, {"pos":Vector2(415,517),"patrol":56.0}, {"pos":Vector2(415,362),"patrol":56.0}, {"pos":Vector2(415,207),"patrol":56.0}],"exit":Vector2(420,75)},
		24: {"bg":Color(0.0,0.06,0.04),"pc":Color(0.05,0.45,0.2),"platforms":[Vector4(377,750,78,18), Vector4(25,672,78,18), Vector4(377,595,78,18), Vector4(25,517,78,18), Vector4(377,440,78,18), Vector4(25,362,78,18), Vector4(377,285,78,18), Vector4(25,207,78,18), Vector4(377,130,78,18)],"extra_magnets":[Vector2(430,264), Vector2(50,427), Vector2(430,589), Vector2(400,492), Vector2(80,768), Vector2(400,1044), Vector2(80,1320), Vector2(400,1597), Vector2(80,1873), Vector2(400,2149), Vector2(80,2425), Vector2(400,2701), Vector2(80,2977)],"coins":[Vector2(416,710), Vector2(64,632), Vector2(416,555), Vector2(64,477), Vector2(416,400), Vector2(64,322), Vector2(416,245), Vector2(64,167)],"lasers":[{"pos":Vector2(240,724),"size":Vector2(193,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(193,10),"blink":true}, {"pos":Vector2(240,569),"size":Vector2(193,10),"blink":false}, {"pos":Vector2(240,492),"size":Vector2(193,10),"blink":true}, {"pos":Vector2(240,414),"size":Vector2(193,10),"blink":false}, {"pos":Vector2(240,337),"size":Vector2(193,10),"blink":true}, {"pos":Vector2(240,259),"size":Vector2(193,10),"blink":false}],"guards":[{"pos":Vector2(64,672),"patrol":54.0}, {"pos":Vector2(64,517),"patrol":54.0}, {"pos":Vector2(64,362),"patrol":54.0}, {"pos":Vector2(64,207),"patrol":54.0}],"exit":Vector2(60,75)},
		25: {"bg":Color(0.0,0.0,0.08),"pc":Color(0.55,0.55,0.0),"platforms":[Vector4(25,750,76,18), Vector4(379,681,76,18), Vector4(25,612,76,18), Vector4(379,543,76,18), Vector4(25,474,76,18), Vector4(379,405,76,18), Vector4(25,336,76,18), Vector4(379,267,76,18), Vector4(25,198,76,18), Vector4(379,130,76,18)],"extra_magnets":[Vector2(430,264), Vector2(50,427), Vector2(430,589), Vector2(400,512), Vector2(80,799), Vector2(400,1085), Vector2(80,1371), Vector2(400,1657), Vector2(80,1943), Vector2(400,2229), Vector2(80,2515), Vector2(400,2801), Vector2(80,3087)],"coins":[Vector2(63,710), Vector2(417,641), Vector2(63,572), Vector2(417,503), Vector2(63,434), Vector2(417,365), Vector2(63,296), Vector2(417,227), Vector2(63,158)],"lasers":[{"pos":Vector2(240,727),"size":Vector2(194,10),"blink":false}, {"pos":Vector2(240,589),"size":Vector2(194,10),"blink":false}, {"pos":Vector2(240,451),"size":Vector2(194,10),"blink":false}, {"pos":Vector2(240,313),"size":Vector2(194,10),"blink":false}],"guards":[{"pos":Vector2(417,681),"patrol":53.0}, {"pos":Vector2(417,543),"patrol":53.0}, {"pos":Vector2(417,405),"patrol":53.0}, {"pos":Vector2(417,267),"patrol":53.0}, {"pos":Vector2(417,130),"patrol":53.0}],"exit":Vector2(60,75)},
		26: {"bg":Color(0.04,0.0,0.08),"pc":Color(0.3,0.0,0.6),"platforms":[Vector4(25,750,74,18), Vector4(381,681,74,18), Vector4(25,612,74,18), Vector4(381,543,74,18), Vector4(25,474,74,18), Vector4(381,405,74,18), Vector4(25,336,74,18), Vector4(381,267,74,18), Vector4(25,198,74,18), Vector4(381,130,74,18)],"extra_magnets":[Vector2(430,232), Vector2(50,362), Vector2(430,491), Vector2(50,621), Vector2(400,454), Vector2(80,671), Vector2(400,888), Vector2(80,1105), Vector2(400,1322), Vector2(80,1540), Vector2(400,1757), Vector2(80,1974), Vector2(400,2191), Vector2(80,2408), Vector2(400,2625), Vector2(80,2842), Vector2(400,3059), Vector2(80,3276)],"coins":[Vector2(62,710), Vector2(418,641), Vector2(62,572), Vector2(418,503), Vector2(62,434), Vector2(418,365), Vector2(62,296), Vector2(418,227), Vector2(62,158)],"lasers":[{"pos":Vector2(240,727),"size":Vector2(195,10),"blink":false}, {"pos":Vector2(240,589),"size":Vector2(195,10),"blink":false}, {"pos":Vector2(240,451),"size":Vector2(195,10),"blink":false}, {"pos":Vector2(240,313),"size":Vector2(195,10),"blink":false}],"guards":[{"pos":Vector2(418,681),"patrol":51.0}, {"pos":Vector2(418,543),"patrol":51.0}, {"pos":Vector2(418,405),"patrol":51.0}, {"pos":Vector2(418,267),"patrol":51.0}, {"pos":Vector2(418,130),"patrol":51.0}],"exit":Vector2(60,75)},
		27: {"bg":Color(0.0,0.05,0.08),"pc":Color(0.0,0.4,0.55),"platforms":[Vector4(25,750,72,18), Vector4(383,681,72,18), Vector4(25,612,72,18), Vector4(383,543,72,18), Vector4(25,474,72,18), Vector4(383,405,72,18), Vector4(25,336,72,18), Vector4(383,267,72,18), Vector4(25,198,72,18), Vector4(383,130,72,18)],"extra_magnets":[Vector2(430,232), Vector2(50,362), Vector2(430,491), Vector2(50,621), Vector2(400,472), Vector2(80,696), Vector2(400,921), Vector2(80,1145), Vector2(400,1369), Vector2(80,1594), Vector2(400,1818), Vector2(80,2043), Vector2(400,2267), Vector2(80,2491), Vector2(400,2716), Vector2(80,2940), Vector2(400,3165), Vector2(80,3389)],"coins":[Vector2(61,710), Vector2(419,641), Vector2(61,572), Vector2(419,503), Vector2(61,434), Vector2(419,365), Vector2(61,296), Vector2(419,227), Vector2(61,158)],"lasers":[{"pos":Vector2(240,727),"size":Vector2(196,10),"blink":false}, {"pos":Vector2(240,589),"size":Vector2(196,10),"blink":false}, {"pos":Vector2(240,451),"size":Vector2(196,10),"blink":false}, {"pos":Vector2(240,313),"size":Vector2(196,10),"blink":false}],"guards":[{"pos":Vector2(419,681),"patrol":50.0}, {"pos":Vector2(419,543),"patrol":50.0}, {"pos":Vector2(419,405),"patrol":50.0}, {"pos":Vector2(419,267),"patrol":50.0}, {"pos":Vector2(419,130),"patrol":50.0}],"exit":Vector2(60,75)},
		28: {"bg":Color(0.06,0.04,0.0),"pc":Color(0.55,0.35,0.0),"platforms":[Vector4(385,750,70,18), Vector4(25,681,70,18), Vector4(385,612,70,18), Vector4(25,543,70,18), Vector4(385,474,70,18), Vector4(25,405,70,18), Vector4(385,336,70,18), Vector4(25,267,70,18), Vector4(385,198,70,18), Vector4(25,130,70,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,490), Vector2(400,721), Vector2(80,953), Vector2(400,1185), Vector2(80,1416), Vector2(400,1648), Vector2(80,1880), Vector2(400,2112), Vector2(80,2343), Vector2(400,2575), Vector2(80,2807), Vector2(400,3038), Vector2(80,3270), Vector2(400,3502)],"coins":[Vector2(420,710), Vector2(60,641), Vector2(420,572), Vector2(60,503), Vector2(420,434), Vector2(60,365), Vector2(420,296), Vector2(60,227), Vector2(420,158)],"lasers":[{"pos":Vector2(240,727),"size":Vector2(198,10),"blink":false}, {"pos":Vector2(240,589),"size":Vector2(198,10),"blink":false}, {"pos":Vector2(240,451),"size":Vector2(198,10),"blink":false}, {"pos":Vector2(240,313),"size":Vector2(198,10),"blink":false}],"guards":[{"pos":Vector2(60,681),"patrol":50.0}, {"pos":Vector2(60,543),"patrol":50.0}, {"pos":Vector2(60,405),"patrol":50.0}, {"pos":Vector2(60,267),"patrol":50.0}, {"pos":Vector2(60,130),"patrol":50.0}],"exit":Vector2(420,75)},
		29: {"bg":Color(0.0,0.03,0.06),"pc":Color(0.0,0.25,0.5),"platforms":[Vector4(25,750,68,18), Vector4(387,688,68,18), Vector4(25,626,68,18), Vector4(387,564,68,18), Vector4(25,502,68,18), Vector4(387,440,68,18), Vector4(25,378,68,18), Vector4(387,316,68,18), Vector4(25,254,68,18), Vector4(387,192,68,18), Vector4(25,130,68,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,479), Vector2(400,690), Vector2(80,901), Vector2(400,1112), Vector2(80,1323), Vector2(400,1534), Vector2(80,1745), Vector2(400,1956), Vector2(80,2166), Vector2(400,2377), Vector2(80,2588), Vector2(400,2799), Vector2(80,3010), Vector2(400,3221), Vector2(80,3432), Vector2(400,3643)],"coins":[Vector2(59,710), Vector2(421,648), Vector2(59,586), Vector2(421,524), Vector2(59,462), Vector2(421,400), Vector2(59,338), Vector2(421,276), Vector2(59,214), Vector2(59,90)],"lasers":[{"pos":Vector2(240,730),"size":Vector2(199,10),"blink":false}, {"pos":Vector2(240,606),"size":Vector2(199,10),"blink":false}, {"pos":Vector2(240,482),"size":Vector2(199,10),"blink":false}, {"pos":Vector2(240,358),"size":Vector2(199,10),"blink":false}],"guards":[{"pos":Vector2(421,688),"patrol":50.0}, {"pos":Vector2(421,564),"patrol":50.0}, {"pos":Vector2(421,440),"patrol":50.0}, {"pos":Vector2(421,316),"patrol":50.0}, {"pos":Vector2(421,192),"patrol":50.0}],"exit":Vector2(420,75)},
		30: {"bg":Color(0.0,0.0,0.0),"pc":Color(1.0,0.75,0.0),"platforms":[Vector4(25,750,66,18), Vector4(389,688,66,18), Vector4(25,626,66,18), Vector4(389,564,66,18), Vector4(25,502,66,18), Vector4(389,440,66,18), Vector4(25,378,66,18), Vector4(389,316,66,18), Vector4(25,254,66,18), Vector4(389,192,66,18), Vector4(25,130,66,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,496), Vector2(400,714), Vector2(80,931), Vector2(400,1148), Vector2(80,1366), Vector2(400,1583), Vector2(80,1800), Vector2(400,2018), Vector2(80,2235), Vector2(400,2452), Vector2(80,2670), Vector2(400,2887), Vector2(80,3104), Vector2(400,3322), Vector2(80,3539), Vector2(400,3756)],"coins":[Vector2(58,710), Vector2(422,648), Vector2(58,586), Vector2(422,524), Vector2(58,462), Vector2(422,400), Vector2(58,338), Vector2(422,276), Vector2(58,214), Vector2(58,90)],"lasers":[{"pos":Vector2(240,730),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,606),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,482),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,358),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(422,688),"patrol":50.0}, {"pos":Vector2(422,564),"patrol":50.0}, {"pos":Vector2(422,440),"patrol":50.0}, {"pos":Vector2(422,316),"patrol":50.0}, {"pos":Vector2(422,192),"patrol":50.0}],"exit":Vector2(420,75)},
		31: {"bg":Color(0.02,0.0,0.05),"pc":Color(0.6,0.0,0.8),"platforms":[Vector4(25,750,64,18), Vector4(391,688,64,18), Vector4(25,626,64,18), Vector4(391,564,64,18), Vector4(25,502,64,18), Vector4(391,440,64,18), Vector4(25,378,64,18), Vector4(391,316,64,18), Vector4(25,254,64,18), Vector4(391,192,64,18), Vector4(25,130,64,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,513), Vector2(400,737), Vector2(80,961), Vector2(400,1185), Vector2(80,1408), Vector2(400,1632), Vector2(80,1856), Vector2(400,2080), Vector2(80,2303), Vector2(400,2527), Vector2(80,2751), Vector2(400,2975), Vector2(80,3198), Vector2(400,3422), Vector2(80,3646), Vector2(400,3870)],"coins":[Vector2(57,710), Vector2(423,648), Vector2(57,586), Vector2(423,524), Vector2(57,462), Vector2(423,400), Vector2(57,338), Vector2(423,276), Vector2(57,214), Vector2(57,90)],"lasers":[{"pos":Vector2(240,730),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,606),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,482),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,358),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(423,688),"patrol":50.0}, {"pos":Vector2(423,564),"patrol":50.0}, {"pos":Vector2(423,440),"patrol":50.0}, {"pos":Vector2(423,316),"patrol":50.0}, {"pos":Vector2(423,192),"patrol":50.0}],"exit":Vector2(420,75)},
		32: {"bg":Color(0.0,0.04,0.02),"pc":Color(0.0,0.55,0.28),"platforms":[Vector4(393,750,62,18), Vector4(25,693,62,18), Vector4(393,637,62,18), Vector4(25,580,62,18), Vector4(393,524,62,18), Vector4(25,468,62,18), Vector4(393,411,62,18), Vector4(25,355,62,18), Vector4(393,299,62,18), Vector4(25,242,62,18), Vector4(393,186,62,18), Vector4(25,130,62,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,486), Vector2(400,673), Vector2(80,859), Vector2(400,1046), Vector2(80,1232), Vector2(400,1418), Vector2(80,1605), Vector2(400,1791), Vector2(80,1977), Vector2(400,2164), Vector2(80,2350), Vector2(400,2536), Vector2(80,2723), Vector2(400,2909), Vector2(80,3095), Vector2(400,3282), Vector2(80,3468), Vector2(400,3654), Vector2(80,3841), Vector2(400,4027)],"coins":[Vector2(424,710), Vector2(56,653), Vector2(424,597), Vector2(56,540), Vector2(424,484), Vector2(56,428), Vector2(424,371), Vector2(56,315), Vector2(424,259), Vector2(56,202)],"lasers":[{"pos":Vector2(240,731),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,618),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,506),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,393),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(56,693),"patrol":50.0}, {"pos":Vector2(56,580),"patrol":50.0}, {"pos":Vector2(56,468),"patrol":50.0}, {"pos":Vector2(56,355),"patrol":50.0}, {"pos":Vector2(56,242),"patrol":50.0}, {"pos":Vector2(56,130),"patrol":50.0}],"exit":Vector2(420,75)},
		33: {"bg":Color(0.05,0.03,0.0),"pc":Color(0.6,0.28,0.0),"platforms":[Vector4(25,750,60,18), Vector4(395,693,60,18), Vector4(25,637,60,18), Vector4(395,580,60,18), Vector4(25,524,60,18), Vector4(395,468,60,18), Vector4(25,411,60,18), Vector4(395,355,60,18), Vector4(25,299,60,18), Vector4(395,242,60,18), Vector4(25,186,60,18), Vector4(395,130,60,18)],"extra_magnets":[Vector2(430,232), Vector2(50,362), Vector2(430,491), Vector2(50,621), Vector2(400,502), Vector2(80,694), Vector2(400,885), Vector2(80,1077), Vector2(400,1268), Vector2(80,1460), Vector2(400,1652), Vector2(80,1843), Vector2(400,2035), Vector2(80,2226), Vector2(400,2418), Vector2(80,2609), Vector2(400,2801), Vector2(80,2993), Vector2(400,3184), Vector2(80,3376), Vector2(400,3567), Vector2(80,3759), Vector2(400,3950), Vector2(80,4142)],"coins":[Vector2(55,710), Vector2(425,653), Vector2(55,597), Vector2(425,540), Vector2(55,484), Vector2(425,428), Vector2(55,371), Vector2(425,315), Vector2(55,259), Vector2(425,202), Vector2(425,90)],"lasers":[{"pos":Vector2(240,731),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,618),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,506),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,393),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(425,693),"patrol":50.0}, {"pos":Vector2(425,580),"patrol":50.0}, {"pos":Vector2(425,468),"patrol":50.0}, {"pos":Vector2(425,355),"patrol":50.0}, {"pos":Vector2(425,242),"patrol":50.0}, {"pos":Vector2(425,130),"patrol":50.0}],"exit":Vector2(60,75)},
		34: {"bg":Color(0.0,0.0,0.06),"pc":Color(0.1,0.1,0.65),"platforms":[Vector4(25,750,58,18), Vector4(397,693,58,18), Vector4(25,637,58,18), Vector4(397,580,58,18), Vector4(25,524,58,18), Vector4(397,468,58,18), Vector4(25,411,58,18), Vector4(397,355,58,18), Vector4(25,299,58,18), Vector4(397,242,58,18), Vector4(25,186,58,18), Vector4(397,130,58,18)],"extra_magnets":[Vector2(430,232), Vector2(50,362), Vector2(430,491), Vector2(50,621), Vector2(400,518), Vector2(80,715), Vector2(400,912), Vector2(80,1108), Vector2(400,1305), Vector2(80,1502), Vector2(400,1699), Vector2(80,1895), Vector2(400,2092), Vector2(80,2289), Vector2(400,2486), Vector2(80,2683), Vector2(400,2879), Vector2(80,3076), Vector2(400,3273), Vector2(80,3470), Vector2(400,3666), Vector2(80,3863), Vector2(400,4060), Vector2(80,4257)],"coins":[Vector2(54,710), Vector2(426,653), Vector2(54,597), Vector2(426,540), Vector2(54,484), Vector2(426,428), Vector2(54,371), Vector2(426,315), Vector2(54,259), Vector2(426,202), Vector2(426,90)],"lasers":[{"pos":Vector2(240,731),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,618),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,506),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,393),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(426,693),"patrol":50.0}, {"pos":Vector2(426,580),"patrol":50.0}, {"pos":Vector2(426,468),"patrol":50.0}, {"pos":Vector2(426,355),"patrol":50.0}, {"pos":Vector2(426,242),"patrol":50.0}, {"pos":Vector2(426,130),"patrol":50.0}],"exit":Vector2(60,75)},
		35: {"bg":Color(0.0,0.05,0.05),"pc":Color(0.0,0.5,0.5),"platforms":[Vector4(25,750,56,18), Vector4(399,698,56,18), Vector4(25,646,56,18), Vector4(399,595,56,18), Vector4(25,543,56,18), Vector4(399,491,56,18), Vector4(25,440,56,18), Vector4(399,388,56,18), Vector4(25,336,56,18), Vector4(399,285,56,18), Vector4(25,233,56,18), Vector4(399,181,56,18), Vector4(25,130,56,18)],"extra_magnets":[Vector2(50,232), Vector2(430,362), Vector2(50,491), Vector2(430,621), Vector2(80,534), Vector2(400,736), Vector2(80,938), Vector2(400,1140), Vector2(80,1342), Vector2(400,1544), Vector2(80,1746), Vector2(400,1948), Vector2(80,2150), Vector2(400,2352), Vector2(80,2554), Vector2(400,2756), Vector2(80,2958), Vector2(400,3160), Vector2(80,3362), Vector2(400,3564), Vector2(80,3766), Vector2(400,3968), Vector2(80,4170), Vector2(400,4372)],"coins":[Vector2(53,710), Vector2(427,658), Vector2(53,606), Vector2(427,555), Vector2(53,503), Vector2(427,451), Vector2(53,400), Vector2(427,348), Vector2(53,296), Vector2(427,245), Vector2(53,193), Vector2(53,90)],"lasers":[{"pos":Vector2(240,733),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,629),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,526),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,423),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(427,698),"patrol":50.0}, {"pos":Vector2(427,595),"patrol":50.0}, {"pos":Vector2(427,491),"patrol":50.0}, {"pos":Vector2(427,388),"patrol":50.0}, {"pos":Vector2(427,285),"patrol":50.0}, {"pos":Vector2(427,181),"patrol":50.0}],"exit":Vector2(420,75)},
		36: {"bg":Color(0.04,0.0,0.06),"pc":Color(0.5,0.0,0.45),"platforms":[Vector4(399,750,56,18), Vector4(25,698,56,18), Vector4(399,646,56,18), Vector4(25,595,56,18), Vector4(399,543,56,18), Vector4(25,491,56,18), Vector4(399,440,56,18), Vector4(25,388,56,18), Vector4(399,336,56,18), Vector4(25,285,56,18), Vector4(399,233,56,18), Vector4(25,181,56,18), Vector4(399,130,56,18)],"extra_magnets":[Vector2(430,210), Vector2(50,318), Vector2(430,427), Vector2(50,535), Vector2(430,643), Vector2(400,531), Vector2(80,721), Vector2(400,910), Vector2(80,1099), Vector2(400,1288), Vector2(80,1477), Vector2(400,1667), Vector2(80,1856), Vector2(400,2045), Vector2(80,2234), Vector2(400,2423), Vector2(80,2612), Vector2(400,2802), Vector2(80,2991), Vector2(400,3180), Vector2(80,3369), Vector2(400,3558), Vector2(80,3748), Vector2(400,3937), Vector2(80,4126), Vector2(400,4315), Vector2(80,4504)],"coins":[Vector2(427,710), Vector2(53,658), Vector2(427,606), Vector2(53,555), Vector2(427,503), Vector2(53,451), Vector2(427,400), Vector2(53,348), Vector2(427,296), Vector2(53,245), Vector2(427,193), Vector2(427,90)],"lasers":[{"pos":Vector2(240,733),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,629),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,526),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,423),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(53,698),"patrol":50.0}, {"pos":Vector2(53,595),"patrol":50.0}, {"pos":Vector2(53,491),"patrol":50.0}, {"pos":Vector2(53,388),"patrol":50.0}, {"pos":Vector2(53,285),"patrol":50.0}, {"pos":Vector2(53,181),"patrol":50.0}],"exit":Vector2(60,75)},
		37: {"bg":Color(0.0,0.04,0.0),"pc":Color(0.1,0.5,0.1),"platforms":[Vector4(25,750,55,18), Vector4(400,698,55,18), Vector4(25,646,55,18), Vector4(400,595,55,18), Vector4(25,543,55,18), Vector4(400,491,55,18), Vector4(25,440,55,18), Vector4(400,388,55,18), Vector4(25,336,55,18), Vector4(400,285,55,18), Vector4(25,233,55,18), Vector4(400,181,55,18), Vector4(25,130,55,18)],"extra_magnets":[Vector2(50,210), Vector2(430,318), Vector2(50,427), Vector2(430,535), Vector2(50,643), Vector2(80,547), Vector2(400,741), Vector2(80,935), Vector2(400,1129), Vector2(80,1323), Vector2(400,1516), Vector2(80,1710), Vector2(400,1904), Vector2(80,2098), Vector2(400,2292), Vector2(80,2486), Vector2(400,2680), Vector2(80,2874), Vector2(400,3068), Vector2(80,3262), Vector2(400,3456), Vector2(80,3650), Vector2(400,3844), Vector2(80,4038), Vector2(400,4232), Vector2(80,4426), Vector2(400,4620)],"coins":[Vector2(52,710), Vector2(427,658), Vector2(52,606), Vector2(427,555), Vector2(52,503), Vector2(427,451), Vector2(52,400), Vector2(427,348), Vector2(52,296), Vector2(427,245), Vector2(52,193), Vector2(52,90)],"lasers":[{"pos":Vector2(240,733),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,629),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,526),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,423),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(427,698),"patrol":50.0}, {"pos":Vector2(427,595),"patrol":50.0}, {"pos":Vector2(427,491),"patrol":50.0}, {"pos":Vector2(427,388),"patrol":50.0}, {"pos":Vector2(427,285),"patrol":50.0}, {"pos":Vector2(427,181),"patrol":50.0}],"exit":Vector2(420,75)},
		38: {"bg":Color(0.06,0.02,0.0),"pc":Color(0.65,0.2,0.0),"platforms":[Vector4(25,750,54,18), Vector4(401,702,54,18), Vector4(25,654,54,18), Vector4(401,606,54,18), Vector4(25,559,54,18), Vector4(401,511,54,18), Vector4(25,463,54,18), Vector4(401,416,54,18), Vector4(25,368,54,18), Vector4(401,320,54,18), Vector4(25,273,54,18), Vector4(401,225,54,18), Vector4(25,177,54,18), Vector4(401,130,54,18)],"extra_magnets":[Vector2(430,210), Vector2(50,318), Vector2(430,427), Vector2(50,535), Vector2(430,643), Vector2(400,562), Vector2(80,761), Vector2(400,959), Vector2(80,1158), Vector2(400,1357), Vector2(80,1556), Vector2(400,1754), Vector2(80,1953), Vector2(400,2152), Vector2(80,2350), Vector2(400,2549), Vector2(80,2748), Vector2(400,2946), Vector2(80,3145), Vector2(400,3344), Vector2(80,3543), Vector2(400,3741), Vector2(80,3940), Vector2(400,4139), Vector2(80,4337), Vector2(400,4536), Vector2(80,4735)],"coins":[Vector2(52,710), Vector2(428,662), Vector2(52,614), Vector2(428,566), Vector2(52,519), Vector2(428,471), Vector2(52,423), Vector2(428,376), Vector2(52,328), Vector2(428,280), Vector2(52,233), Vector2(428,185), Vector2(428,90)],"lasers":[{"pos":Vector2(240,734),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,638),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,543),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,448),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(428,702),"patrol":50.0}, {"pos":Vector2(428,606),"patrol":50.0}, {"pos":Vector2(428,511),"patrol":50.0}, {"pos":Vector2(428,416),"patrol":50.0}, {"pos":Vector2(428,320),"patrol":50.0}, {"pos":Vector2(428,225),"patrol":50.0}],"exit":Vector2(60,75)},
		39: {"bg":Color(0.0,0.0,0.04),"pc":Color(0.3,0.3,0.6),"platforms":[Vector4(25,750,53,18), Vector4(402,702,53,18), Vector4(25,654,53,18), Vector4(402,606,53,18), Vector4(25,559,53,18), Vector4(402,511,53,18), Vector4(25,463,53,18), Vector4(402,416,53,18), Vector4(25,368,53,18), Vector4(402,320,53,18), Vector4(25,273,53,18), Vector4(402,225,53,18), Vector4(25,177,53,18), Vector4(402,130,53,18)],"extra_magnets":[Vector2(430,210), Vector2(50,318), Vector2(430,427), Vector2(50,535), Vector2(430,643), Vector2(400,577), Vector2(80,781), Vector2(400,984), Vector2(80,1188), Vector2(400,1391), Vector2(80,1595), Vector2(400,1798), Vector2(80,2002), Vector2(400,2205), Vector2(80,2409), Vector2(400,2612), Vector2(80,2815), Vector2(400,3019), Vector2(80,3222), Vector2(400,3426), Vector2(80,3629), Vector2(400,3833), Vector2(80,4036), Vector2(400,4240), Vector2(80,4443), Vector2(400,4647), Vector2(80,4850)],"coins":[Vector2(51,710), Vector2(428,662), Vector2(51,614), Vector2(428,566), Vector2(51,519), Vector2(428,471), Vector2(51,423), Vector2(428,376), Vector2(51,328), Vector2(428,280), Vector2(51,233), Vector2(428,185), Vector2(428,90)],"lasers":[{"pos":Vector2(240,734),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,638),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,543),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,448),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(428,702),"patrol":50.0}, {"pos":Vector2(428,606),"patrol":50.0}, {"pos":Vector2(428,511),"patrol":50.0}, {"pos":Vector2(428,416),"patrol":50.0}, {"pos":Vector2(428,320),"patrol":50.0}, {"pos":Vector2(428,225),"patrol":50.0}],"exit":Vector2(60,75)},
		40: {"bg":Color(0.0,0.0,0.0),"pc":Color(0.8,0.6,0.0),"platforms":[Vector4(403,750,52,18), Vector4(25,705,52,18), Vector4(403,661,52,18), Vector4(25,617,52,18), Vector4(403,572,52,18), Vector4(25,528,52,18), Vector4(403,484,52,18), Vector4(25,440,52,18), Vector4(403,395,52,18), Vector4(25,351,52,18), Vector4(403,307,52,18), Vector4(25,262,52,18), Vector4(403,218,52,18), Vector4(25,174,52,18), Vector4(403,130,52,18)],"extra_magnets":[Vector2(430,210), Vector2(50,318), Vector2(430,427), Vector2(50,535), Vector2(430,643), Vector2(400,593), Vector2(80,801), Vector2(400,1009), Vector2(80,1217), Vector2(400,1426), Vector2(80,1634), Vector2(400,1842), Vector2(80,2050), Vector2(400,2258), Vector2(80,2467), Vector2(400,2675), Vector2(80,2883), Vector2(400,3091), Vector2(80,3300), Vector2(400,3508), Vector2(80,3716), Vector2(400,3924), Vector2(80,4132), Vector2(400,4341), Vector2(80,4549), Vector2(400,4757), Vector2(80,4965)],"coins":[Vector2(429,710), Vector2(51,665), Vector2(429,621), Vector2(51,577), Vector2(429,532), Vector2(51,488), Vector2(429,444), Vector2(51,400), Vector2(429,355), Vector2(51,311), Vector2(429,267), Vector2(51,222), Vector2(429,178), Vector2(429,90)],"lasers":[{"pos":Vector2(240,735),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,558),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,470),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(51,705),"patrol":50.0}, {"pos":Vector2(51,617),"patrol":50.0}, {"pos":Vector2(51,528),"patrol":50.0}, {"pos":Vector2(51,440),"patrol":50.0}, {"pos":Vector2(51,351),"patrol":50.0}, {"pos":Vector2(51,262),"patrol":50.0}],"exit":Vector2(60,75)},
		41: {"bg":Color(0.03,0.0,0.06),"pc":Color(0.55,0.0,0.7),"platforms":[Vector4(25,750,51,18), Vector4(404,705,51,18), Vector4(25,661,51,18), Vector4(404,617,51,18), Vector4(25,572,51,18), Vector4(404,528,51,18), Vector4(25,484,51,18), Vector4(404,440,51,18), Vector4(25,395,51,18), Vector4(404,351,51,18), Vector4(25,307,51,18), Vector4(404,262,51,18), Vector4(25,218,51,18), Vector4(404,174,51,18), Vector4(25,130,51,18)],"extra_magnets":[Vector2(50,210), Vector2(430,318), Vector2(50,427), Vector2(430,535), Vector2(50,643), Vector2(80,608), Vector2(400,821), Vector2(80,1034), Vector2(400,1247), Vector2(80,1460), Vector2(400,1673), Vector2(80,1886), Vector2(400,2099), Vector2(80,2312), Vector2(400,2525), Vector2(80,2738), Vector2(400,2951), Vector2(80,3164), Vector2(400,3377), Vector2(80,3590), Vector2(400,3803), Vector2(80,4016), Vector2(400,4229), Vector2(80,4442), Vector2(400,4655), Vector2(80,4868), Vector2(400,5081)],"coins":[Vector2(50,710), Vector2(429,665), Vector2(50,621), Vector2(429,577), Vector2(50,532), Vector2(429,488), Vector2(50,444), Vector2(429,400), Vector2(50,355), Vector2(429,311), Vector2(50,267), Vector2(429,222), Vector2(50,178), Vector2(50,90)],"lasers":[{"pos":Vector2(240,735),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,558),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,470),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(429,705),"patrol":50.0}, {"pos":Vector2(429,617),"patrol":50.0}, {"pos":Vector2(429,528),"patrol":50.0}, {"pos":Vector2(429,440),"patrol":50.0}, {"pos":Vector2(429,351),"patrol":50.0}, {"pos":Vector2(429,262),"patrol":50.0}],"exit":Vector2(420,75)},
		42: {"bg":Color(0.0,0.04,0.03),"pc":Color(0.0,0.5,0.4),"platforms":[Vector4(25,750,50,18), Vector4(405,708,50,18), Vector4(25,667,50,18), Vector4(405,626,50,18), Vector4(25,584,50,18), Vector4(405,543,50,18), Vector4(25,502,50,18), Vector4(405,460,50,18), Vector4(25,419,50,18), Vector4(405,378,50,18), Vector4(25,336,50,18), Vector4(405,295,50,18), Vector4(25,254,50,18), Vector4(405,212,50,18), Vector4(25,171,50,18), Vector4(405,130,50,18)],"extra_magnets":[Vector2(430,210), Vector2(50,318), Vector2(430,427), Vector2(50,535), Vector2(430,643), Vector2(400,623), Vector2(80,841), Vector2(400,1059), Vector2(80,1276), Vector2(400,1494), Vector2(80,1712), Vector2(400,1930), Vector2(80,2147), Vector2(400,2365), Vector2(80,2583), Vector2(400,2801), Vector2(80,3018), Vector2(400,3236), Vector2(80,3454), Vector2(400,3672), Vector2(80,3889), Vector2(400,4107), Vector2(80,4325), Vector2(400,4543), Vector2(80,4760), Vector2(400,4978), Vector2(80,5196)],"coins":[Vector2(50,710), Vector2(430,668), Vector2(50,627), Vector2(430,586), Vector2(50,544), Vector2(430,503), Vector2(50,462), Vector2(430,420), Vector2(50,379), Vector2(430,338), Vector2(50,296), Vector2(430,255), Vector2(50,214), Vector2(430,172), Vector2(430,90)],"lasers":[{"pos":Vector2(240,736),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,654),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,571),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,488),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,708),"patrol":50.0}, {"pos":Vector2(430,626),"patrol":50.0}, {"pos":Vector2(430,543),"patrol":50.0}, {"pos":Vector2(430,460),"patrol":50.0}, {"pos":Vector2(430,378),"patrol":50.0}, {"pos":Vector2(430,295),"patrol":50.0}],"exit":Vector2(60,75)},
		43: {"bg":Color(0.05,0.0,0.0),"pc":Color(0.7,0.1,0.1),"platforms":[Vector4(25,750,50,18), Vector4(405,711,50,18), Vector4(25,672,50,18), Vector4(405,633,50,18), Vector4(25,595,50,18), Vector4(405,556,50,18), Vector4(25,517,50,18), Vector4(405,478,50,18), Vector4(25,440,50,18), Vector4(405,401,50,18), Vector4(25,362,50,18), Vector4(405,323,50,18), Vector4(25,285,50,18), Vector4(405,246,50,18), Vector4(25,207,50,18), Vector4(405,168,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,210), Vector2(430,318), Vector2(50,427), Vector2(430,535), Vector2(50,643), Vector2(80,621), Vector2(400,825), Vector2(80,1030), Vector2(400,1235), Vector2(80,1440), Vector2(400,1644), Vector2(80,1849), Vector2(400,2054), Vector2(80,2258), Vector2(400,2463), Vector2(80,2668), Vector2(400,2872), Vector2(80,3077), Vector2(400,3282), Vector2(80,3487), Vector2(400,3691), Vector2(80,3896), Vector2(400,4101), Vector2(80,4305), Vector2(400,4510), Vector2(80,4715), Vector2(400,4919), Vector2(80,5124), Vector2(400,5329)],"coins":[Vector2(50,710), Vector2(430,671), Vector2(50,632), Vector2(430,593), Vector2(50,555), Vector2(430,516), Vector2(50,477), Vector2(430,438), Vector2(50,400), Vector2(430,361), Vector2(50,322), Vector2(430,283), Vector2(50,245), Vector2(430,206), Vector2(50,167), Vector2(50,90)],"lasers":[{"pos":Vector2(240,737),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,659),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,582),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,504),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,711),"patrol":50.0}, {"pos":Vector2(430,556),"patrol":50.0}, {"pos":Vector2(430,401),"patrol":50.0}, {"pos":Vector2(430,246),"patrol":50.0}],"exit":Vector2(420,75)},
		44: {"bg":Color(0.0,0.03,0.06),"pc":Color(0.05,0.2,0.6),"platforms":[Vector4(405,750,50,18), Vector4(25,713,50,18), Vector4(405,677,50,18), Vector4(25,640,50,18), Vector4(405,604,50,18), Vector4(25,567,50,18), Vector4(405,531,50,18), Vector4(25,494,50,18), Vector4(405,458,50,18), Vector4(25,421,50,18), Vector4(405,385,50,18), Vector4(25,348,50,18), Vector4(405,312,50,18), Vector4(25,275,50,18), Vector4(405,239,50,18), Vector4(25,202,50,18), Vector4(405,166,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,210), Vector2(430,318), Vector2(50,427), Vector2(430,535), Vector2(50,643), Vector2(80,636), Vector2(400,845), Vector2(80,1054), Vector2(400,1263), Vector2(80,1472), Vector2(400,1681), Vector2(80,1890), Vector2(400,2099), Vector2(80,2308), Vector2(400,2517), Vector2(80,2726), Vector2(400,2936), Vector2(80,3145), Vector2(400,3354), Vector2(80,3563), Vector2(400,3772), Vector2(80,3981), Vector2(400,4190), Vector2(80,4399), Vector2(400,4608), Vector2(80,4817), Vector2(400,5026), Vector2(80,5235), Vector2(400,5444)],"coins":[Vector2(430,710), Vector2(50,673), Vector2(430,637), Vector2(50,600), Vector2(430,564), Vector2(50,527), Vector2(430,491), Vector2(50,454), Vector2(430,418), Vector2(50,381), Vector2(430,345), Vector2(50,308), Vector2(430,272), Vector2(50,235), Vector2(430,199), Vector2(50,162), Vector2(50,90)],"lasers":[{"pos":Vector2(240,738),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,665),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,592),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,519),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(50,713),"patrol":50.0}, {"pos":Vector2(50,567),"patrol":50.0}, {"pos":Vector2(50,421),"patrol":50.0}, {"pos":Vector2(50,275),"patrol":50.0}, {"pos":Vector2(50,130),"patrol":50.0}],"exit":Vector2(420,75)},
		45: {"bg":Color(0.0,0.0,0.0),"pc":Color(0.0,0.8,0.8),"platforms":[Vector4(25,750,50,18), Vector4(405,715,50,18), Vector4(25,681,50,18), Vector4(405,646,50,18), Vector4(25,612,50,18), Vector4(405,577,50,18), Vector4(25,543,50,18), Vector4(405,508,50,18), Vector4(25,474,50,18), Vector4(405,440,50,18), Vector4(25,405,50,18), Vector4(405,371,50,18), Vector4(25,336,50,18), Vector4(405,302,50,18), Vector4(25,267,50,18), Vector4(405,233,50,18), Vector4(25,198,50,18), Vector4(405,164,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,210), Vector2(430,318), Vector2(50,427), Vector2(430,535), Vector2(50,643), Vector2(80,651), Vector2(400,864), Vector2(80,1077), Vector2(400,1291), Vector2(80,1504), Vector2(400,1718), Vector2(80,1931), Vector2(400,2145), Vector2(80,2358), Vector2(400,2572), Vector2(80,2785), Vector2(400,2999), Vector2(80,3212), Vector2(400,3425), Vector2(80,3639), Vector2(400,3852), Vector2(80,4066), Vector2(400,4279), Vector2(80,4493), Vector2(400,4706), Vector2(80,4920), Vector2(400,5133), Vector2(80,5347), Vector2(400,5560)],"coins":[Vector2(50,710), Vector2(430,675), Vector2(50,641), Vector2(430,606), Vector2(50,572), Vector2(430,537), Vector2(50,503), Vector2(430,468), Vector2(50,434), Vector2(430,400), Vector2(50,365), Vector2(430,331), Vector2(50,296), Vector2(430,262), Vector2(50,227), Vector2(430,193), Vector2(50,158), Vector2(50,90)],"lasers":[{"pos":Vector2(240,739),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,635),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,532),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,715),"patrol":50.0}, {"pos":Vector2(430,577),"patrol":50.0}, {"pos":Vector2(430,440),"patrol":50.0}, {"pos":Vector2(430,302),"patrol":50.0}, {"pos":Vector2(430,164),"patrol":50.0}],"exit":Vector2(420,75)},
		46: {"bg":Color(0.04,0.0,0.04),"pc":Color(0.6,0.0,0.6),"platforms":[Vector4(25,750,50,18), Vector4(405,717,50,18), Vector4(25,684,50,18), Vector4(405,652,50,18), Vector4(25,619,50,18), Vector4(405,586,50,18), Vector4(25,554,50,18), Vector4(405,521,50,18), Vector4(25,488,50,18), Vector4(405,456,50,18), Vector4(25,423,50,18), Vector4(405,391,50,18), Vector4(25,358,50,18), Vector4(405,325,50,18), Vector4(25,293,50,18), Vector4(405,260,50,18), Vector4(25,227,50,18), Vector4(405,195,50,18), Vector4(25,162,50,18), Vector4(405,130,50,18)],"extra_magnets":[Vector2(430,195), Vector2(50,287), Vector2(430,380), Vector2(50,473), Vector2(430,566), Vector2(50,658), Vector2(400,635), Vector2(80,823), Vector2(400,1011), Vector2(80,1199), Vector2(400,1387), Vector2(80,1574), Vector2(400,1762), Vector2(80,1950), Vector2(400,2138), Vector2(80,2326), Vector2(400,2513), Vector2(80,2701), Vector2(400,2889), Vector2(80,3077), Vector2(400,3264), Vector2(80,3452), Vector2(400,3640), Vector2(80,3828), Vector2(400,4016), Vector2(80,4203), Vector2(400,4391), Vector2(80,4579), Vector2(400,4767), Vector2(80,4955), Vector2(400,5142), Vector2(80,5330), Vector2(400,5518), Vector2(80,5706)],"coins":[Vector2(50,710), Vector2(430,677), Vector2(50,644), Vector2(430,546), Vector2(50,514), Vector2(50,448), Vector2(430,416), Vector2(50,318), Vector2(430,285), Vector2(50,187), Vector2(430,155)],"lasers":[{"pos":Vector2(240,739),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,641),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,543),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,717),"patrol":50.0}, {"pos":Vector2(430,586),"patrol":50.0}, {"pos":Vector2(430,456),"patrol":50.0}, {"pos":Vector2(430,325),"patrol":50.0}, {"pos":Vector2(430,195),"patrol":50.0}],"exit":Vector2(60,75)},
		47: {"bg":Color(0.0,0.04,0.06),"pc":Color(0.0,0.35,0.6),"platforms":[Vector4(25,750,50,18), Vector4(405,719,50,18), Vector4(25,688,50,18), Vector4(405,657,50,18), Vector4(25,626,50,18), Vector4(405,595,50,18), Vector4(25,564,50,18), Vector4(405,533,50,18), Vector4(25,502,50,18), Vector4(405,471,50,18), Vector4(25,440,50,18), Vector4(405,409,50,18), Vector4(25,378,50,18), Vector4(405,347,50,18), Vector4(25,316,50,18), Vector4(405,285,50,18), Vector4(25,254,50,18), Vector4(405,223,50,18), Vector4(25,192,50,18), Vector4(405,161,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,195), Vector2(430,287), Vector2(50,380), Vector2(430,473), Vector2(50,566), Vector2(430,658), Vector2(80,650), Vector2(400,841), Vector2(80,1033), Vector2(400,1224), Vector2(80,1416), Vector2(400,1608), Vector2(80,1799), Vector2(400,1991), Vector2(80,2182), Vector2(400,2374), Vector2(80,2565), Vector2(400,2757), Vector2(80,2949), Vector2(400,3140), Vector2(80,3332), Vector2(400,3523), Vector2(80,3715), Vector2(400,3906), Vector2(80,4098), Vector2(400,4289), Vector2(80,4481), Vector2(400,4673), Vector2(80,4864), Vector2(400,5056), Vector2(80,5247), Vector2(400,5439), Vector2(80,5630), Vector2(400,5822)],"coins":[Vector2(50,710), Vector2(430,679), Vector2(50,586), Vector2(430,555), Vector2(50,462), Vector2(430,431), Vector2(50,338), Vector2(430,307), Vector2(50,214), Vector2(430,183), Vector2(50,90)],"lasers":[{"pos":Vector2(240,740),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,647),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,554),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,719),"patrol":50.0}, {"pos":Vector2(430,595),"patrol":50.0}, {"pos":Vector2(430,471),"patrol":50.0}, {"pos":Vector2(430,347),"patrol":50.0}, {"pos":Vector2(430,223),"patrol":50.0}],"exit":Vector2(420,75)},
		48: {"bg":Color(0.06,0.0,0.02),"pc":Color(0.7,0.05,0.2),"platforms":[Vector4(405,750,50,18), Vector4(25,720,50,18), Vector4(405,690,50,18), Vector4(25,661,50,18), Vector4(405,631,50,18), Vector4(25,602,50,18), Vector4(405,572,50,18), Vector4(25,543,50,18), Vector4(405,513,50,18), Vector4(25,484,50,18), Vector4(405,454,50,18), Vector4(25,425,50,18), Vector4(405,395,50,18), Vector4(25,366,50,18), Vector4(405,336,50,18), Vector4(25,307,50,18), Vector4(405,277,50,18), Vector4(25,248,50,18), Vector4(405,218,50,18), Vector4(25,189,50,18), Vector4(405,159,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,195), Vector2(430,287), Vector2(50,380), Vector2(430,473), Vector2(50,566), Vector2(430,658), Vector2(80,664), Vector2(400,859), Vector2(80,1055), Vector2(400,1250), Vector2(80,1445), Vector2(400,1641), Vector2(80,1836), Vector2(400,2031), Vector2(80,2227), Vector2(400,2422), Vector2(80,2617), Vector2(400,2813), Vector2(80,3008), Vector2(400,3203), Vector2(80,3399), Vector2(400,3594), Vector2(80,3789), Vector2(400,3985), Vector2(80,4180), Vector2(400,4375), Vector2(80,4571), Vector2(400,4766), Vector2(80,4961), Vector2(400,5157), Vector2(80,5352), Vector2(400,5547), Vector2(80,5743), Vector2(400,5938)],"coins":[Vector2(430,710), Vector2(50,680), Vector2(430,591), Vector2(50,562), Vector2(430,473), Vector2(50,444), Vector2(430,355), Vector2(50,326), Vector2(430,237), Vector2(50,208), Vector2(50,90), Vector2(410,174)],"lasers":[{"pos":Vector2(240,740),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,651),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,563),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(50,720),"patrol":50.0}, {"pos":Vector2(50,602),"patrol":50.0}, {"pos":Vector2(50,484),"patrol":50.0}, {"pos":Vector2(50,366),"patrol":50.0}, {"pos":Vector2(50,248),"patrol":50.0}, {"pos":Vector2(50,130),"patrol":50.0}],"exit":Vector2(420,75)},
		49: {"bg":Color(0.02,0.02,0.02),"pc":Color(0.4,0.4,0.4),"platforms":[Vector4(25,750,50,18), Vector4(405,721,50,18), Vector4(25,693,50,18), Vector4(405,665,50,18), Vector4(25,637,50,18), Vector4(405,609,50,18), Vector4(25,580,50,18), Vector4(405,552,50,18), Vector4(25,524,50,18), Vector4(405,496,50,18), Vector4(25,468,50,18), Vector4(405,440,50,18), Vector4(25,411,50,18), Vector4(405,383,50,18), Vector4(25,355,50,18), Vector4(405,327,50,18), Vector4(25,299,50,18), Vector4(405,270,50,18), Vector4(25,242,50,18), Vector4(405,214,50,18), Vector4(25,186,50,18), Vector4(405,158,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,195), Vector2(430,287), Vector2(50,380), Vector2(430,473), Vector2(50,566), Vector2(430,658), Vector2(80,678), Vector2(400,877), Vector2(80,1077), Vector2(400,1276), Vector2(80,1475), Vector2(400,1674), Vector2(80,1873), Vector2(400,2072), Vector2(80,2271), Vector2(400,2470), Vector2(80,2669), Vector2(400,2869), Vector2(80,3068), Vector2(400,3267), Vector2(80,3466), Vector2(400,3665), Vector2(80,3864), Vector2(400,4063), Vector2(80,4262), Vector2(400,4461), Vector2(80,4661), Vector2(400,4860), Vector2(80,5059), Vector2(400,5258), Vector2(80,5457), Vector2(400,5656), Vector2(80,5855), Vector2(400,6054)],"coins":[Vector2(50,710), Vector2(430,681), Vector2(50,597), Vector2(430,569), Vector2(50,484), Vector2(430,456), Vector2(50,371), Vector2(430,343), Vector2(50,259), Vector2(430,230), Vector2(50,146)],"lasers":[{"pos":Vector2(240,741),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,656),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,571),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,721),"patrol":50.0}, {"pos":Vector2(430,609),"patrol":50.0}, {"pos":Vector2(430,496),"patrol":50.0}, {"pos":Vector2(430,383),"patrol":50.0}, {"pos":Vector2(430,270),"patrol":50.0}, {"pos":Vector2(430,158),"patrol":50.0}],"exit":Vector2(420,75)},
		50: {"bg":Color(0.0,0.0,0.0),"pc":Color(1.0,0.85,0.0),"platforms":[Vector4(25,750,50,18), Vector4(405,724,50,18), Vector4(25,698,50,18), Vector4(405,672,50,18), Vector4(25,646,50,18), Vector4(405,620,50,18), Vector4(25,595,50,18), Vector4(405,569,50,18), Vector4(25,543,50,18), Vector4(405,517,50,18), Vector4(25,491,50,18), Vector4(405,465,50,18), Vector4(25,440,50,18), Vector4(405,414,50,18), Vector4(25,388,50,18), Vector4(405,362,50,18), Vector4(25,336,50,18), Vector4(405,310,50,18), Vector4(25,285,50,18), Vector4(405,259,50,18), Vector4(25,233,50,18), Vector4(405,207,50,18), Vector4(25,181,50,18), Vector4(405,155,50,18), Vector4(25,130,50,18)],"extra_magnets":[Vector2(50,195), Vector2(430,287), Vector2(50,380), Vector2(430,473), Vector2(50,566), Vector2(430,658), Vector2(80,680), Vector2(400,869), Vector2(80,1059), Vector2(400,1249), Vector2(80,1439), Vector2(400,1629), Vector2(80,1818), Vector2(400,2008), Vector2(80,2198), Vector2(400,2388), Vector2(80,2578), Vector2(400,2767), Vector2(80,2957), Vector2(400,3147), Vector2(80,3337), Vector2(400,3527), Vector2(80,3716), Vector2(400,3906), Vector2(80,4096), Vector2(400,4286), Vector2(80,4476), Vector2(400,4665), Vector2(80,4855), Vector2(400,5045), Vector2(80,5235), Vector2(400,5425), Vector2(80,5614), Vector2(400,5804), Vector2(80,5994), Vector2(400,6184)],"coins":[Vector2(50,710), Vector2(430,684), Vector2(50,606), Vector2(430,580), Vector2(50,503), Vector2(430,477), Vector2(50,400), Vector2(430,374), Vector2(50,296), Vector2(430,270), Vector2(50,193), Vector2(430,167), Vector2(50,90)],"lasers":[{"pos":Vector2(240,742),"size":Vector2(200,10),"blink":false}, {"pos":Vector2(240,664),"size":Vector2(200,10),"blink":true}, {"pos":Vector2(240,587),"size":Vector2(200,10),"blink":false}],"guards":[{"pos":Vector2(430,724),"patrol":50.0}, {"pos":Vector2(430,620),"patrol":50.0}, {"pos":Vector2(430,517),"patrol":50.0}, {"pos":Vector2(430,414),"patrol":50.0}, {"pos":Vector2(430,310),"patrol":50.0}, {"pos":Vector2(430,207),"patrol":50.0}],"exit":Vector2(420,75)},
	}
	return levels.get(level_number, levels[1])

func _ready():
	if level_number == 1:
		_save_total_score(0)
		_save_lives(3)
	total_score = _load_total_score()
	lives = _load_lives()
	_build_level()
	_setup_ui()
	LevelTransition.fade_in()
	_play_music()

func _process(delta):
	_bg_time += delta
	queue_redraw()
	if player and is_instance_valid(player):
		var cam = player.get_node_or_null("Camera")
		if cam:
			var lh = _get_level_height()
			var progress = 1.0 - clamp(player.position.y / lh, 0.0, 1.0)
			var target_offset = -250.0 * progress
			cam.offset.y = lerp(cam.offset.y, target_offset, delta * 3.0)

func _play_music():
	var music_num = ((level_number - 1) % 20) + 1
	var path = "res://audio/music_%02d.wav" % music_num
	var stream = load(path)
	if stream:
		music_player = AudioStreamPlayer.new()
		music_player.stream = stream
		music_player.volume_db = -8.0
		music_player.bus = "Master"
		add_child(music_player)
		if SoundManager.is_on():
			music_player.play()
		music_player.finished.connect(func():
			if SoundManager.is_on():
				music_player.play()
		)

# ─── PERSISTENT SCORE & LIVES ─────────────────────────────────────────────────

func _save_total_score(val: int):
	var f = FileAccess.open("user://total_score.dat", FileAccess.WRITE)
	if f:
		f.store_32(val)
		f.close()

func _load_total_score() -> int:
	if not FileAccess.file_exists("user://total_score.dat"):
		return 0
	var f = FileAccess.open("user://total_score.dat", FileAccess.READ)
	if f:
		var val = f.get_32()
		f.close()
		return val
	return 0

func _save_lives(val: int):
	var f = FileAccess.open("user://lives.dat", FileAccess.WRITE)
	if f:
		f.store_8(val)
		f.store_8(coins_since_last_life)
		f.close()

func _load_lives() -> int:
	if not FileAccess.file_exists("user://lives.dat"):
		return 3
	var f = FileAccess.open("user://lives.dat", FileAccess.READ)
	if f:
		var val = f.get_8()
		coins_since_last_life = f.get_8()
		f.close()
		return clamp(val, 1, 5)
	return 3

func _save_max_level(val: int):
	var f = FileAccess.open("user://max_level.dat", FileAccess.WRITE)
	if f:
		f.store_8(val)
		f.close()

func _load_max_level() -> int:
	if not FileAccess.file_exists("user://max_level.dat"):
		return 1
	var f = FileAccess.open("user://max_level.dat", FileAccess.READ)
	if f:
		var val = f.get_8()
		f.close()
		return clamp(val, 1, 50)
	return 1

func _save_stars(level: int, stars: int):
	var all_stars = _load_all_stars()
	all_stars[level - 1] = max(all_stars[level - 1], stars)
	var f = FileAccess.open("user://stars.dat", FileAccess.WRITE)
	if f:
		for s in all_stars:
			f.store_8(s)
		f.close()

func _load_all_stars() -> Array:
	var result = []
	for i in 50:
		result.append(0)
	if not FileAccess.file_exists("user://stars.dat"):
		return result
	var f = FileAccess.open("user://stars.dat", FileAccess.READ)
	if f:
		for i in 50:
			result[i] = f.get_8()
		f.close()
	return result

func _calculate_stars() -> int:
	if total_coins == 0:
		return 1
	var ratio = float(coins_collected) / float(total_coins)
	if ratio >= 1.0:
		return 3
	elif ratio >= 0.5:
		return 2
	else:
		return 1

func _save_leaderboard(entries: Array):
	var f = FileAccess.open("user://leaderboard.dat", FileAccess.WRITE)
	if f:
		f.store_8(entries.size())
		for e in entries:
			f.store_32(e["score"])
			f.store_8(e["level"])
			var date = e["date"]
			f.store_8(date.length())
			for c in date:
				f.store_8(c.unicode_at(0))
		f.close()

func _load_leaderboard() -> Array:
	if not FileAccess.file_exists("user://leaderboard.dat"):
		return []
	var f = FileAccess.open("user://leaderboard.dat", FileAccess.READ)
	if not f:
		return []
	var entries = []
	var count = f.get_8()
	for i in count:
		var score = f.get_32()
		var level = f.get_8()
		var date_len = f.get_8()
		var date = ""
		for j in date_len:
			date += char(f.get_8())
		entries.append({"score": score, "level": level, "date": date})
	f.close()
	return entries

func _add_score_to_leaderboard(score: int, reached_level: int):
	var entries = _load_leaderboard()
	var now = Time.get_date_string_from_system()
	entries.append({"score": score, "level": reached_level, "date": now})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.size() > 5:
		entries = entries.slice(0, 5)
	_save_leaderboard(entries)
	return entries

# ─── LEVEL BUILDER ───────────────────────────────────────────────────────────

func _get_level_height() -> float:
	if level_number <= 3:
		return 854.0
	return 854.0 + (level_number - 3) * 120.0

func _build_level():
	var d = get_level_data()
	var lh = _get_level_height()
	var scale_y = lh / 854.0
	_add_background(d["bg"])
	_add_walls()
	var scaled_platforms = []
	for p in d["platforms"]:
		# Level verisinde platform x'i SOL kenar (coin/guard'lar ortasına göre yerleştirilmiş);
		# fizik ve çizim merkez beklediği için yarım genişlik ekleniyor
		scaled_platforms.append(Vector4(p.x + p.z / 2.0, p.y * scale_y, p.z, p.w))
	_add_platforms(scaled_platforms, d["pc"])
	_add_player(Vector2(60, lh - 80))
	var scaled_exit = Vector2(d["exit"].x, d["exit"].y * scale_y)
	var scaled_obstacles = _build_obstacle_list(scaled_platforms, scaled_exit)
	var scaled_magnets = []
	for m in d["extra_magnets"]:
		# x=80/400'deki mıknatıs dizisi zaten level yüksekliğine göre (mutlak) yazılmış;
		# tekrar ölçeklenirse zeminin altına düşüyor. Duvar mıknatısları (x=50/430) 854'lük tasarım koordinatında.
		var is_absolute = m.x == 80.0 or m.x == 400.0
		scaled_magnets.append(Vector2(m.x, m.y if is_absolute else m.y * scale_y))
	_add_magnets(scaled_magnets, scaled_obstacles)
	var scaled_coins = []
	for c in d["coins"]:
		scaled_coins.append(Vector2(c.x, c.y * scale_y))
	_add_coins(scaled_coins, scaled_obstacles)
	var scaled_lasers = []
	for l in d["lasers"]:
		scaled_lasers.append({"pos": Vector2(l["pos"].x, l["pos"].y * scale_y), "size": l["size"], "blink": l["blink"]})
	_add_lasers(scaled_lasers)

	# 2 sabit magnet: exit üstü + karşı duvar aynı hizada
	var exit_top = Vector2(scaled_exit.x, scaled_exit.y - 80)
	exit_top = _resolve_position(exit_top, scaled_obstacles, 24.0)
	_make_magnet(exit_top)

	var opp_x = 400.0 if scaled_exit.x < 240 else 80.0
	var opp_mag = Vector2(opp_x, scaled_exit.y - 80)
	opp_mag = _resolve_position(opp_mag, scaled_obstacles, 24.0)
	_make_magnet(opp_mag)

	_add_exit(scaled_exit)
	var scaled_guards = []
	for g in d["guards"]:
		scaled_guards.append({"pos": Vector2(g["pos"].x, g["pos"].y * scale_y - 20), "patrol": g["patrol"]})
	_add_guards(scaled_guards)
	var hero_names = ["Cyborg", "Pink", "Shadow", "Mech", "Blaze"]
	AnalyticsManager.level_start(level_number, hero_names[HeroManager.get_hero()])

func _build_obstacle_list(platforms: Array, exit_pos: Vector2) -> Array:
	var obstacles = []
	for p in platforms:
		obstacles.append({"center": Vector2(p.x, p.y), "half_size": Vector2(p.z / 2.0, p.w / 2.0)})
	obstacles.append({"center": exit_pos, "radius": 40.0})
	return obstacles

func _resolve_position(pos: Vector2, obstacles: Array, item_radius: float) -> Vector2:
	var p = pos
	for iteration in 6:
		var moved = false
		for obs in obstacles:
			if obs.has("half_size"):
				var hs = obs["half_size"] + Vector2(item_radius, item_radius)
				var diff = p - obs["center"]
				if abs(diff.x) < hs.x and abs(diff.y) < hs.y:
					var overlap_x = hs.x - abs(diff.x)
					var overlap_y = hs.y - abs(diff.y)
					if overlap_x < overlap_y:
						p.x += overlap_x if diff.x >= 0 else -overlap_x
					else:
						p.y += overlap_y if diff.y >= 0 else -overlap_y
					moved = true
			elif obs.has("radius"):
				var min_dist = obs["radius"] + item_radius
				var diff2 = p - obs["center"]
				var dist = diff2.length()
				if dist < min_dist:
					if dist < 0.001:
						p += Vector2(min_dist, 0)
					else:
						p = obs["center"] + diff2.normalized() * min_dist
					moved = true
		if not moved:
			break
	return p

var _bg_color: Color = Color(0.05, 0.05, 0.15)

func _add_background(color: Color):
	_bg_color = color
	queue_redraw()

func _draw():
	var W = 480.0
	var H = _get_level_height()
	draw_rect(Rect2(0, -2000, W, H + 2000), _bg_color)
	var star_positions = [
		Vector2(45,80), Vector2(120,45), Vector2(200,90), Vector2(310,55),
		Vector2(380,100), Vector2(430,70), Vector2(60,180), Vector2(160,150),
		Vector2(280,130), Vector2(400,160), Vector2(90,250), Vector2(340,220),
		Vector2(460,240), Vector2(50,340), Vector2(180,310), Vector2(390,290),
		Vector2(240,380), Vector2(70,430), Vector2(420,400), Vector2(150,480),
		Vector2(350,460), Vector2(30,550), Vector2(280,520), Vector2(440,540),
	]
	var scale_y = H / 854.0
	for i in star_positions.size():
		var sp = Vector2(star_positions[i].x, star_positions[i].y * scale_y)
		var twinkle = 0.4 + sin(_bg_time * (1.2 + i * 0.15) + i) * 0.35
		var sz = 1.0 + sin(_bg_time * 0.8 + i * 0.7) * 0.5
		draw_circle(sp, sz, Color(0.9, 0.95, 1.0, twinkle))
		if scale_y > 1.5:
			for rep in range(1, int(scale_y)):
				var sp2 = Vector2(star_positions[i].x, star_positions[i].y + rep * 854.0)
				if sp2.y < H:
					draw_circle(sp2, sz * 0.8, Color(0.9, 0.95, 1.0, twinkle * 0.7))
	var sil_color = Color(_bg_color.r*1.4+0.04, _bg_color.g*1.4+0.04, _bg_color.b*1.4+0.06, 0.35)
	var ground_y = H - 174.0
	var buildings_right = [
		Rect2(340, ground_y, 35, 120), Rect2(375, ground_y+20, 25, 100),
		Rect2(400, ground_y-20, 45, 140), Rect2(445, ground_y+10, 30, 110)
	]
	for b in buildings_right:
		draw_rect(b, sil_color)
		for row in 3:
			for col in 2:
				var wx = b.position.x + 5 + col * 12
				var wy = b.position.y + 15 + row * 28
				if wx+6 < b.position.x+b.size.x and wy+8 < b.position.y+b.size.y:
					var wt = 0.3 + sin(_bg_time*0.5+row*1.3+col*0.7)*0.2
					draw_rect(Rect2(wx,wy,6,8), Color(1.0,0.9,0.5,wt*0.6))
	var buildings_left = [
		Rect2(20, ground_y, 30, 100), Rect2(50, ground_y-30, 40, 130),
		Rect2(90, ground_y+10, 25, 90), Rect2(115, ground_y-10, 35, 110)
	]
	for b in buildings_left:
		draw_rect(b, sil_color)
		for row in 3:
			for col in 2:
				var wx = b.position.x + 4 + col * 11
				var wy = b.position.y + 12 + row * 26
				if wx+5 < b.position.x+b.size.x and wy+7 < b.position.y+b.size.y:
					var wt = 0.3 + sin(_bg_time*0.4+row*1.1+col*0.9)*0.2
					draw_rect(Rect2(wx,wy,5,7), Color(1.0,0.9,0.5,wt*0.5))
	var mid_color = Color(_bg_color.r*1.2+0.02, _bg_color.g*1.2+0.02, _bg_color.b*1.2+0.04, 0.18)
	for b in [Rect2(130,ground_y+50,50,70), Rect2(180,ground_y+30,35,90),
			  Rect2(260,ground_y+60,40,60), Rect2(300,ground_y+40,55,80)]:
		draw_rect(b, mid_color)
	draw_rect(Rect2(0,ground_y+95,W,4), Color(_bg_color.r*2+0.1,_bg_color.g*2+0.1,_bg_color.b*2+0.15,0.15))

func _add_walls():
	var lh = _get_level_height()
	_make_brick_wall(Vector2(240, lh + 20), Vector2(480, 40), "bottom")
	_make_brick_wall(Vector2(10, lh / 2.0 - 1000), Vector2(30, lh + 2040), "left")
	_make_brick_wall(Vector2(470, lh / 2.0 - 1000), Vector2(30, lh + 2040), "right")

func _make_brick_wall(pos: Vector2, size: Vector2, side: String):
	var sb = StaticBody2D.new()
	sb.position = pos
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)
	var vis = Node2D.new()
	vis.set_script(_get_brick_script(size, side))
	sb.add_child(vis)
	add_child(sb)

func _get_brick_script(size: Vector2, side: String) -> GDScript:
	var s = GDScript.new()
	var w = size.x
	var h = size.y
	var sd = side
	s.source_code = """
extends Node2D
func _draw():
	var w = %f
	var h = %f
	var side = "%s"
	var base_color = Color(0.22, 0.18, 0.14)
	var brick_color = Color(0.32, 0.24, 0.18)
	var brick_light = Color(0.42, 0.32, 0.22)
	var edge_glow = Color(0.9, 0.6, 0.2, 0.5)
	draw_rect(Rect2(-w/2, -h/2, w, h), base_color)
	var bw = 36.0
	var bh = 14.0
	var mortar = 3.0
	var rows = int(h / (bh + mortar)) + 2
	var cols = int(w / (bw + mortar)) + 2
	for row in rows:
		var y = -h/2 + row * (bh + mortar)
		var offset = bw/2 if row %% 2 == 1 else 0.0
		for col in cols:
			var x = -w/2 + col * (bw + mortar) - offset
			if x + bw < -w/2 or x > w/2: continue
			if y + bh < -h/2 or y > h/2: continue
			var cx = clamp(x, -w/2, w/2)
			var cy = clamp(y, -h/2, h/2)
			var cw = clamp(x + bw, -w/2, w/2) - cx
			var ch = clamp(y + bh, -h/2, h/2) - cy
			if cw > 0 and ch > 0:
				draw_rect(Rect2(cx, cy, cw, ch), brick_color)
				draw_rect(Rect2(cx, cy, cw, 2), brick_light)
				draw_rect(Rect2(cx + cw - 2, cy, 2, ch), Color(0.18, 0.14, 0.10))
	if side == "left":
		draw_rect(Rect2(w/2-6,-h/2,6,h), Color(0,0,0,0.5))
		draw_rect(Rect2(w/2-2,-h/2,2,h), edge_glow)
	elif side == "right":
		draw_rect(Rect2(-w/2,-h/2,6,h), Color(0,0,0,0.5))
		draw_rect(Rect2(-w/2,-h/2,2,h), edge_glow)
	elif side == "top":
		draw_rect(Rect2(-w/2,h/2-6,w,6), Color(0,0,0,0.5))
		draw_rect(Rect2(-w/2,h/2-2,w,2), edge_glow)
	elif side == "bottom":
		draw_rect(Rect2(-w/2,-h/2,w,6), Color(0,0,0,0.5))
		draw_rect(Rect2(-w/2,-h/2,w,2), edge_glow)
""" % [w, h, sd]
	s.reload()
	return s

func _add_platforms(platform_data: Array, color: Color):
	for p in platform_data:
		_make_solid_platform(Vector2(p.x, p.y), Vector2(p.z, p.w), color)

func _make_solid_platform(pos: Vector2, size: Vector2, color: Color):
	var sb = StaticBody2D.new()
	sb.position = pos
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)
	var vis = Node2D.new()
	vis.set_script(_get_platform_script(size, color))
	sb.add_child(vis)
	add_child(sb)

func _get_platform_script(size: Vector2, color: Color) -> GDScript:
	var s = GDScript.new()
	var w = size.x
	var h = size.y
	var r = color.r
	var g = color.g
	var b = color.b
	s.source_code = """
extends Node2D
func _draw():
	var w = %f
	var h = %f
	var base = Color(%f, %f, %f, 1.0)
	var light = Color(min(%f+0.2,1), min(%f+0.2,1), min(%f+0.3,1), 1.0)
	var dark = Color(%f*0.6, %f*0.6, %f*0.6, 1.0)
	draw_rect(Rect2(-w/2, -h/2, w, h), base)
	draw_rect(Rect2(-w/2, -h/2, w, 3), light)
	draw_rect(Rect2(-w/2, h/2-2, w, 2), dark)
	draw_rect(Rect2(-w/2, -h/2, 2, h), Color(1,1,1,0.08))
	var stripe_count = int(w / 28)
	for i in stripe_count:
		var x = -w/2 + 14 + i * 28
		draw_line(Vector2(x,-h/2+3), Vector2(x,h/2-2), Color(1,1,1,0.05), 1.0)
	if h >= 14:
		for i in [0.15, 0.85]:
			var px = -w/2 + w * i
			draw_circle(Vector2(px, 0), 2.5, dark)
			draw_circle(Vector2(px, 0), 1.5, light)
""" % [w, h, r, g, b, r, g, b, r, g, b]
	s.reload()
	return s

func _add_player(pos: Vector2):
	player = RigidBody2D.new()
	player.name = "Player"
	player.position = pos
	player.gravity_scale = 1.0
	player.linear_damp = 0.3
	player.angular_damp = 5.0
	player.lock_rotation = true
	player.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var pm = PhysicsMaterial.new()
	pm.friction = 0.0
	pm.bounce = 0.05
	player.physics_material_override = pm
	player.max_contacts_reported = 4
	player.contact_monitor = true
	player.collision_layer = 2
	player.collision_mask = 1
	player.z_index = 2
	player.add_to_group("player")
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 22.0
	col.shape = shape
	player.add_child(col)
	var pvis = Node2D.new()
	pvis.set_script(load("res://scripts/PlayerVisual.gd"))
	pvis.name = "Visual"
	player.add_child(pvis)
	player.set_script(load("res://scripts/Player.gd"))
	var cam = Camera2D.new()
	cam.name = "Camera"
	# Oyuncuyu takip et, sadece dikey kayma
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	# Yatayda kilitli kal (480px sabit), dikeyde serbest
	cam.limit_left = 0
	cam.limit_right = 480
	cam.limit_top = -99999
	cam.limit_bottom = int(_get_level_height()) + 40
	player.add_child(cam)
	add_child(player)
	player.player_died.connect(_on_player_died)

func _add_magnets(extra: Array, obstacles: Array):
	for pos in extra:
		_make_magnet(_resolve_position(pos, obstacles, 24.0))

func _make_magnet(pos: Vector2):
	# Veride bazı mıknatıslar neredeyse üst üste düşüyor; yakındaki varsa ikincisini ekleme
	for existing in magnets:
		if existing.position.distance_to(pos) < 56.0:
			return
	var m = Node2D.new()
	m.position = pos
	m.add_to_group("magnet")
	var d = get_level_data()
	m.set_meta("level_color", d["pc"])
	var visual = Node2D.new()
	visual.set_script(load("res://scripts/MagnetVisual.gd"))
	visual.name = "Visual"
	m.add_child(visual)
	m.set_script(load("res://scripts/Magnet.gd"))
	add_child(m)
	magnets.append(m)

func _add_coins(coin_positions: Array, obstacles: Array):
	total_coins = coin_positions.size()
	for pos in coin_positions:
		_make_coin(_resolve_position(pos, obstacles, 14.0))

func _make_coin(pos: Vector2):
	var c = Area2D.new()
	c.position = pos
	c.add_to_group("coin")
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	c.add_child(col)
	var visual = Node2D.new()
	visual.set_script(load("res://scripts/CoinVisual.gd"))
	c.add_child(visual)
	c.set_script(load("res://scripts/Coin.gd"))
	add_child(c)
	c.coin_collected.connect(_on_coin_collected)

func _add_lasers(laser_data: Array):
	for l in laser_data:
		_make_laser(l["pos"], l["size"], l["blink"])

func _make_laser(pos: Vector2, size: Vector2, blink: bool):
	var l = Area2D.new()
	l.position = pos
	l.add_to_group("laser")
	l.set_meta("blink_on_ready", blink)
	l.set_meta("laser_size", size)
	l.set_script(load("res://scripts/Laser.gd"))
	add_child(l)

func _add_exit(pos: Vector2):
	# Duvarlardan ve üst/alt kenarden güvenli mesafe
	var safe_pos = Vector2(
		clamp(pos.x, 45, 435),
		clamp(pos.y, 55, 790)
	)
	var door = Area2D.new()
	door.name = "ExitDoor"
	door.position = safe_pos
	door.add_to_group("exit_door")
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 70)
	col.shape = shape
	door.add_child(col)
	var visual = Node2D.new()
	visual.name = "Visual"
	visual.set_script(load("res://scripts/ExitVisual.gd"))
	visual.z_index = 1
	door.add_child(visual)
	door.set_script(load("res://scripts/ExitDoor.gd"))
	add_child(door)
	door.level_complete.connect(_on_level_complete)

func _add_guards(guard_data: Array):
	for i in guard_data.size():
		_add_guard(guard_data[i]["pos"], guard_data[i]["patrol"], i)

func _add_guard(pos: Vector2, patrol: float, guard_index: int = 0):
	var g = CharacterBody2D.new()
	g.position = pos
	g.collision_layer = 1
	g.collision_mask = 1
	g.add_to_group("guard")
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 24.0
	col.shape = shape
	g.add_child(col)
	var gvis = Node2D.new()
	gvis.set_script(load("res://scripts/GuardVisual.gd"))
	gvis.name = "Visual"
	g.add_child(gvis)
	var det = Area2D.new()
	det.name = "DetectionArea"
	var dcol = CollisionShape2D.new()
	var dshape = CapsuleShape2D.new()
	dshape.radius = 14.0
	dshape.height = 28.0
	dcol.shape = dshape
	det.add_child(dcol)
	g.add_child(det)
	g.set_script(load("res://scripts/Guard.gd"))
	g.set_meta("patrol_distance", patrol)
	add_child(g)
	# Tip ata: çift index=0 (kırmızı), tek index=1 (mavi)
	if gvis.has_method("set_type"):
		gvis.set_type(guard_index % 2)

# ─── UI ──────────────────────────────────────────────────────────────────────

func _setup_ui():
	var ui = CanvasLayer.new()
	ui.name = "UILayer"
	add_child(ui)

	# HUD arkasına üstten aşağı kararan bant: açık renkli level'lerde okunurluk ve
	# HUD'un altına denk gelen kapı/platformlarla karışmaması için
	var hud_grad = Gradient.new()
	hud_grad.set_color(0, Color(0.0, 0.0, 0.02, 0.6))
	hud_grad.set_color(1, Color(0.0, 0.0, 0.02, 0.0))
	var hud_tex = GradientTexture2D.new()
	hud_tex.gradient = hud_grad
	hud_tex.fill_from = Vector2(0, 0)
	hud_tex.fill_to = Vector2(0, 1)
	hud_tex.width = 4
	hud_tex.height = 64
	var hud_bg = TextureRect.new()
	hud_bg.texture = hud_tex
	hud_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_bg.stretch_mode = TextureRect.STRETCH_SCALE
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud_bg.offset_bottom = 84
	ui.add_child(hud_bg)

	score_label = Label.new()
	score_label.position = Vector2(12, 14)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	ui.add_child(score_label)

	var sound_vis = Node2D.new()
	sound_vis.set_script(load("res://scripts/SoundButtonVisual.gd"))
	sound_vis.name = "SoundVis"
	sound_vis.position = Vector2(170, 37)
	if sound_vis.has_method("setup"):
		sound_vis.setup(SoundManager.is_on())

	var sound_btn = Button.new()
	sound_btn.name = "SoundBtn"
	sound_btn.size = Vector2(44, 44)
	sound_btn.position = Vector2(148, 14)
	sound_btn.flat = true
	sound_btn.text = ""
	sound_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	sound_btn.pressed.connect(func():
		SoundManager.toggle()
		if sound_vis.has_method("setup"):
			sound_vis.setup(SoundManager.is_on())
		if music_player:
			if SoundManager.is_on():
				music_player.play()
			else:
				music_player.stop()
	)
	ui.add_child(sound_btn)
	ui.add_child(sound_vis)
	sound_button = sound_btn

	total_score_label = Label.new()
	total_score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	total_score_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	total_score_label.position = Vector2(-180, 14)
	total_score_label.size = Vector2(168, 40)
	total_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_score_label.add_theme_font_size_override("font_size", 22)
	total_score_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	ui.add_child(total_score_label)

	lives_label = Label.new()
	lives_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lives_label.position = Vector2(-180, 40)
	lives_label.size = Vector2(168, 28)
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lives_label.add_theme_font_size_override("font_size", 18)
	ui.add_child(lives_label)

	var d = get_level_data()
	var bg = d["bg"]
	var lum = bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114
	var lvl_color = Color(1.0, 0.9, 0.2, 1.0) if lum < 0.4 else Color(0.05, 0.05, 0.2, 1.0)
	var lvl_shadow = Color(0.0, 0.0, 0.0, 0.8) if lum < 0.4 else Color(1.0, 1.0, 1.0, 0.6)

	# Ses butonu x=148..192 aralığında; rozet onun sağından başlıyor
	var lvl_badge = ColorRect.new()
	lvl_badge.size = Vector2(130, 34)
	lvl_badge.position = Vector2(200, 10)
	lvl_badge.color = Color(lvl_color.r, lvl_color.g, lvl_color.b, 0.18)
	ui.add_child(lvl_badge)

	var lvl_lbl = Label.new()
	var level_emojis = ["🔰","⚡","🔥","💎","🌊","🌙","🎯","🚀","👾","🏆","💥","🎮","🌀","☄️","🔮","💀","🌟","⚔️","🧨","🎖️"]
	var emoji = level_emojis[level_number - 1] if level_number <= 20 else "🎮"
	lvl_lbl.text = "%s LVL %d" % [emoji, level_number]
	lvl_lbl.size = Vector2(130, 34)
	lvl_lbl.position = Vector2(200, 10)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 19)
	lvl_lbl.add_theme_color_override("font_color", lvl_color)
	lvl_lbl.add_theme_color_override("font_shadow_color", lvl_shadow)
	lvl_lbl.add_theme_constant_override("shadow_outline_size", 3)
	ui.add_child(lvl_lbl)

	# Çentikli ekranlarda HUD'u güvenli alana indir
	hud_top = ScreenUtil.safe_top(self)
	for n in [score_label, sound_btn, sound_vis, total_score_label, lives_label, lvl_badge, lvl_lbl]:
		n.position.y += hud_top
	hud_bg.offset_bottom += hud_top

	tap_hint = Label.new()
	tap_hint.text = "TAP & HOLD to attract"
	tap_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.position.y = -50
	tap_hint.add_theme_font_size_override("font_size", 18)
	tap_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.95))
	tap_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.1, 0.85))
	tap_hint.add_theme_constant_override("outline_size", 5)
	ui.add_child(tap_hint)

	var result_panel = ColorRect.new()
	result_panel.name = "ResultPanel"
	result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_panel.color = Color(0.0, 0.0, 0.0, 0.0)
	result_panel.visible = false
	ui.add_child(result_panel)

	var panel_box = ColorRect.new()
	panel_box.name = "PanelBox"
	panel_box.size = Vector2(360, 420)
	panel_box.position = Vector2(60, 210)
	panel_box.color = Color(0.04, 0.05, 0.1, 0.95)
	result_panel.add_child(panel_box)

	for cx in [64.0, 416.0]:
		for cy in [214.0, 626.0]:
			var pin = ColorRect.new()
			pin.size = Vector2(3, 3)
			pin.position = Vector2(cx, cy)
			pin.color = Color(0.0, 0.85, 1.0, 0.8)
			result_panel.add_child(pin)

	var top_line = ColorRect.new()
	top_line.name = "TopLine"
	top_line.size = Vector2(360, 3)
	top_line.position = Vector2(60, 210)
	top_line.color = Color(0.0, 0.85, 1.0, 1.0)
	result_panel.add_child(top_line)

	var bot_line = ColorRect.new()
	bot_line.size = Vector2(360, 3)
	bot_line.position = Vector2(60, 627)
	bot_line.color = Color(0.0, 0.85, 1.0, 0.5)
	result_panel.add_child(bot_line)

	var icon_vis = Node2D.new()
	icon_vis.name = "IconVis"
	icon_vis.set_script(_get_result_icon_script())
	icon_vis.position = Vector2(240, 258)
	result_panel.add_child(icon_vis)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.size = Vector2(340, 60)
	status_label.position = Vector2(70, 298)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 32)
	status_label.add_theme_constant_override("shadow_outline_size", 8)
	result_panel.add_child(status_label)

	var sub_lbl = Label.new()
	sub_lbl.name = "SubLabel"
	sub_lbl.size = Vector2(340, 32)
	sub_lbl.position = Vector2(70, 364)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 19)
	sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 0.9))
	result_panel.add_child(sub_lbl)

	var total_sub = Label.new()
	total_sub.name = "TotalSub"
	total_sub.size = Vector2(340, 28)
	total_sub.position = Vector2(70, 396)
	total_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_sub.add_theme_font_size_override("font_size", 15)
	total_sub.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 0.85))
	result_panel.add_child(total_sub)

	var retry_panel = Node2D.new()
	retry_panel.name = "RetryPanel"
	retry_panel.set_script(_get_sci_panel_script(Color(0.0, 0.7, 1.0), 160, 54))
	retry_panel.position = Vector2(76, 436)
	result_panel.add_child(retry_panel)

	retry_button = Button.new()
	retry_button.name = "RetryBtn"
	retry_button.text = "↩  RETRY"
	retry_button.size = Vector2(160, 54)
	retry_button.position = Vector2(76, 436)
	retry_button.flat = true
	retry_button.add_theme_font_size_override("font_size", 19)
	retry_button.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	retry_button.add_theme_color_override("font_hover_color", Color(0.6, 0.95, 1.0))
	retry_button.visible = false
	retry_button.pressed.connect(_on_retry)
	result_panel.add_child(retry_button)

	var next_panel = Node2D.new()
	next_panel.name = "NextPanel"
	next_panel.set_script(_get_sci_panel_script(Color(0.2, 1.0, 0.45), 160, 54))
	next_panel.position = Vector2(244, 436)
	result_panel.add_child(next_panel)

	next_button = Button.new()
	next_button.name = "NextBtn"
	next_button.text = "NEXT  ▶"
	next_button.size = Vector2(160, 54)
	next_button.position = Vector2(244, 436)
	next_button.flat = true
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	next_button.add_theme_color_override("font_hover_color", Color(0.6, 1.0, 0.7))
	next_button.visible = false
	next_button.pressed.connect(_on_next_level)
	result_panel.add_child(next_button)

	var restart_panel = Node2D.new()
	restart_panel.name = "RestartPanel"
	restart_panel.set_script(_get_sci_panel_script(Color(0.65, 0.4, 1.0), 324, 48))
	restart_panel.position = Vector2(78, 500)
	result_panel.add_child(restart_panel)

	var restart_btn = Button.new()
	restart_btn.name = "RestartBtn"
	restart_btn.text = "🔁  RESTART FROM LEVEL 1"
	restart_btn.size = Vector2(324, 48)
	restart_btn.position = Vector2(78, 500)
	restart_btn.flat = true
	restart_btn.add_theme_font_size_override("font_size", 14)
	restart_btn.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0, 1.0))
	restart_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.75, 1.0))
	restart_btn.pressed.connect(_on_restart_from_beginning)
	result_panel.add_child(restart_btn)

	var menu_panel = Node2D.new()
	menu_panel.name = "MenuPanel"
	menu_panel.set_script(_get_sci_panel_script(Color(1.0, 0.35, 0.35), 324, 48))
	menu_panel.position = Vector2(78, 556)
	result_panel.add_child(menu_panel)

	var menu_btn = Button.new()
	menu_btn.name = "MenuBtn"
	menu_btn.text = "🏠  MAIN MENU"
	menu_btn.size = Vector2(324, 48)
	menu_btn.position = Vector2(78, 556)
	menu_btn.flat = true
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55, 1.0))
	menu_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.75, 0.75))
	menu_btn.pressed.connect(func():
		_save_total_score(0)
		coins_since_last_life = 0
		_save_lives(3)
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	result_panel.add_child(menu_btn)

	# Panel 854'lük tasarıma göre yerleşik; uzun ekranlarda ortaya al
	ui_dy = ScreenUtil.center_offset(self)
	ScreenUtil.shift_children(result_panel, ui_dy)

	_update_score_ui()

func _get_sci_panel_script(accent: Color, w: float, h: float) -> GDScript:
	var s = GDScript.new()
	var r = accent.r
	var g = accent.g
	var b = accent.b
	s.source_code = """
extends Node2D
var time: float = 0.0
func _process(delta):
	time += delta
	queue_redraw()
func _draw():
	var accent = Color(%f, %f, %f, 1.0)
	var w = %f
	var h = %f
	var pulse = 0.6 + sin(time * 2.0) * 0.25
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.1, 0.92))
	draw_rect(Rect2(0, 0, w, h), Color(accent.r, accent.g, accent.b, 0.07))
	for cx in [3.0, w - 3.0]:
		for cy in [3.0, h - 3.0]:
			draw_circle(Vector2(cx, cy), 1.4, Color(accent.r, accent.g, accent.b, 0.7))
	draw_rect(Rect2(0, 0, w, 2), Color(accent.r, accent.g, accent.b, 0.5 + pulse * 0.3))
	draw_rect(Rect2(0, h - 2, w, 2), Color(accent.r, accent.g, accent.b, 0.25))
	draw_rect(Rect2(0, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.4))
	draw_rect(Rect2(w - 2, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.4))
""" % [r, g, b, w, h]
	s.reload()
	return s

func _get_result_icon_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends Node2D
var time: float = 0.0
var success: bool = true
func _process(delta):
	time += delta
	queue_redraw()
func set_success(s: bool):
	success = s
	queue_redraw()
func _draw():
	var pulse = 0.6 + sin(time * 2.5) * 0.3
	if success:
		var accent = Color(0.2, 1.0, 0.5)
		draw_circle(Vector2(0, 0), 38, Color(accent.r, accent.g, accent.b, 0.08 + pulse * 0.06))
		draw_arc(Vector2(0, 0), 30, time * 1.5, time * 1.5 + TAU * 0.7, 24, Color(accent.r, accent.g, accent.b, 0.5), 2.0)
		draw_arc(Vector2(0, 0), 30, time * 1.5 + PI, time * 1.5 + PI + TAU * 0.7, 24, Color(1, 1, 1, 0.3), 1.2)
		for i in 8:
			var ang = TAU * i / 8.0
			draw_circle(Vector2(cos(ang) * 30, sin(ang) * 30), 1.6, Color(accent.r, accent.g, accent.b, 0.7))
		draw_circle(Vector2(0, 0), 22, Color(accent.r, accent.g, accent.b, 0.18 + pulse * 0.12))
		draw_line(Vector2(-10, -1), Vector2(-3, 9), Color(accent.r, accent.g, accent.b, 1.0), 4.0)
		draw_line(Vector2(-3, 9), Vector2(12, -10), Color(accent.r, accent.g, accent.b, 1.0), 4.0)
		draw_line(Vector2(-10, -1), Vector2(-3, 9), Color(1, 1, 1, 0.5), 1.4)
		draw_line(Vector2(-3, 9), Vector2(12, -10), Color(1, 1, 1, 0.5), 1.4)
	else:
		var accent = Color(1.0, 0.25, 0.25)
		draw_circle(Vector2(0, 0), 38, Color(accent.r, accent.g, accent.b, 0.08 + pulse * 0.06))
		draw_arc(Vector2(0, 0), 30, time * 1.0, time * 1.0 + TAU * 0.6, 24, Color(accent.r, accent.g, accent.b, 0.5), 2.0)
		for i in 6:
			var ang2 = time * -1.5 + TAU * i / 6.0
			var rr = 32.0 + sin(time * 4 + i) * 3.0
			draw_circle(Vector2(cos(ang2) * rr, sin(ang2) * rr), 1.4, Color(accent.r, accent.g, accent.b, 0.6))
		draw_circle(Vector2(0, 0), 22, Color(accent.r, accent.g, accent.b, 0.18 + pulse * 0.12))
		draw_line(Vector2(-9, -9), Vector2(9, 9), Color(accent.r, accent.g, accent.b, 1.0), 4.0)
		draw_line(Vector2(9, -9), Vector2(-9, 9), Color(accent.r, accent.g, accent.b, 1.0), 4.0)
		draw_line(Vector2(-9, -9), Vector2(9, 9), Color(1, 1, 1, 0.4), 1.4)
		draw_line(Vector2(9, -9), Vector2(-9, 9), Color(1, 1, 1, 0.4), 1.4)
"""
	s.reload()
	return s

# ─── INPUT ───────────────────────────────────────────────────────────────────

func _input(event):
	if not level_active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_on_sound_button(event.position):
				return
			var m = _find_nearest_magnet(event.position)
			if m:
				active_touches[event.index] = m
				m.activate(player)
			if tap_hint:
				tap_hint.visible = false
		else:
			if _is_on_sound_button(event.position):
				return
			active_touches.erase(event.index)
			if active_touches.is_empty():
				_deactivate_all_magnets()
			else:
				var last_magnet = active_touches.values().back()
				if is_instance_valid(last_magnet):
					last_magnet.activate(player)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_on_sound_button(event.position):
				return
			_activate_nearest_magnet_at(event.position)
			if tap_hint:
				tap_hint.visible = false
		else:
			if _is_on_sound_button(event.position):
				return
			_deactivate_all_magnets()

func _is_on_sound_button(screen_pos: Vector2) -> bool:
	return sound_button != null and sound_button.get_global_rect().has_point(screen_pos)

func _find_nearest_magnet(screen_pos: Vector2) -> Node2D:
	if not player or player.is_dead:
		return null
	var world_pos = get_canvas_transform().affine_inverse() * screen_pos
	var nearest = null
	var nearest_dist = INF
	for m in magnets:
		if not is_instance_valid(m):
			continue
		var d = world_pos.distance_to(m.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = m
	return nearest

func _activate_nearest_magnet_at(screen_pos: Vector2):
	var m = _find_nearest_magnet(screen_pos)
	if m:
		m.activate(player)

func _deactivate_all_magnets():
	for m in magnets:
		if is_instance_valid(m):
			m.deactivate()

# ─── SIGNALS ─────────────────────────────────────────────────────────────────

func _update_lives_ui():
	if not lives_label:
		return
	var hearts = ""
	for i in 5:
		# 🖤 koyu zeminde neredeyse görünmüyordu
		hearts += "❤️" if i < lives else "🤍"
	lives_label.text = hearts

func _show_life_gained():
	var ui = get_node_or_null("UILayer")
	if not ui:
		return
	var lbl = Label.new()
	lbl.text = "+❤️"
	lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lbl.position = Vector2(-180, 40 + hud_top)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	lbl.add_theme_constant_override("shadow_outline_size", 6)
	ui.add_child(lbl)
	var tween = lbl.create_tween()
	tween.tween_property(lbl, "scale", Vector2(1.8, 1.8), 0.15)
	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(lbl, "position:y", lbl.position.y - 60, 0.6)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)
	if lives_label:
		var flash = lives_label.create_tween()
		flash.tween_property(lives_label, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.1)
		flash.tween_property(lives_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _update_score_ui():
	if score_label:
		score_label.text = "💰 %d/%d" % [coins_collected, total_coins]
	if total_score_label:
		total_score_label.text = "🏆 %d" % total_score
	_update_lives_ui()

func _on_coin_collected(_value: int):
	score += 1
	coins_collected += 1
	total_score += 1
	coins_since_last_life += 1
	_vibrate(30)
	if coins_since_last_life >= 5:
		coins_since_last_life = 0
		if lives < 5:
			lives = lives + 1
			_vibrate(80)
			_show_life_gained()
	_update_score_ui()

func _on_player_died():
	if not level_active:
		return
	level_active = false
	var hero_names = ["Cyborg", "Pink", "Shadow", "Mech", "Blaze"]
	AnalyticsManager.level_fail(level_number, hero_names[HeroManager.get_hero()], coins_collected)
	_deactivate_all_magnets()
	LevelTransition.flash_death()
	_vibrate(400)
	lives -= 1
	if lives <= 0:
		lives = 0
		_save_lives(3)
		# 0 puanlık oyunlar tabloyu doldurmasın
		var entries = _add_score_to_leaderboard(total_score, level_number) if total_score > 0 else _load_leaderboard()
		var is_new_record = entries.size() > 0 and entries[0]["score"] == total_score and total_score > 0
		await get_tree().create_timer(0.6).timeout
		_show_game_over(is_new_record)
	else:
		_save_lives(lives)
		_show_result(false)

func _on_level_complete():
	if not level_active:
		return
	level_active = false
	var hero_names = ["Cyborg", "Pink", "Shadow", "Mech", "Blaze"]
	var hero_name = hero_names[HeroManager.get_hero()]
	AnalyticsManager.level_complete(level_number, hero_name, _calculate_stars(), coins_collected)
	_deactivate_all_magnets()
	_vibrate(150)
	_save_total_score(total_score)
	_save_lives(lives)
	var max_lvl = _load_max_level()
	if level_number + 1 > max_lvl:
		_save_max_level(min(level_number + 1, 50))
	var stars = _calculate_stars()
	_save_stars(level_number, stars)
	if next_level_path == "":
		var entries = _add_score_to_leaderboard(total_score, level_number)
		var is_new_record = entries.size() > 0 and entries[0]["score"] == total_score
		_show_result(true, is_new_record, stars)
	else:
		_show_result(true, false, stars)

func _show_result(success: bool, is_new_record: bool = false, stars: int = 0):
	await get_tree().create_timer(0.5).timeout
	var ui = get_node_or_null("UILayer")
	if not ui:
		return
	var panel = ui.get_node_or_null("ResultPanel")
	if not panel:
		return
	# Arkadaki oyun alanını karart, panel öne çıksın
	panel.color = Color(0.0, 0.0, 0.03, 0.6)
	var top_line = panel.get_node_or_null("TopLine")
	if top_line:
		top_line.color = Color(0.0, 0.85, 1.0) if success else Color(1.0, 0.3, 0.3)
	var icon_vis = panel.get_node_or_null("IconVis")
	if icon_vis and icon_vis.has_method("set_success"):
		icon_vis.set_success(success)
	if status_label:
		var fail_text = "ZAPPED" if player and player.death_cause == "laser" else "CAUGHT"
		status_label.text = "LEVEL COMPLETE" if success else fail_text
		status_label.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.6) if success else Color(1.0, 0.4, 0.4))
	var sub_lbl = panel.get_node_or_null("SubLabel")
	if sub_lbl:
		if success:
			sub_lbl.text = "💰 %d / %d coins" % [coins_collected, total_coins]
		else:
			sub_lbl.text = "better luck next time... (%d ❤️)" % lives
			sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4, 0.8))
	var total_sub = panel.get_node_or_null("TotalSub")
	if total_sub:
		total_sub.text = "🏆 Total: %d coins" % total_score
	if is_new_record:
		var record_lbl = Label.new()
		record_lbl.text = "🥇 NEW RECORD!"
		record_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
		record_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		record_lbl.position.y = 428 + ui_dy
		record_lbl.add_theme_font_size_override("font_size", 22)
		record_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		record_lbl.add_theme_color_override("font_shadow_color", Color(0.8, 0.4, 0.0, 0.8))
		record_lbl.add_theme_constant_override("shadow_outline_size", 6)
		panel.add_child(record_lbl)
		record_lbl.scale = Vector2(0.3, 0.3)
		record_lbl.pivot_offset = Vector2(240, 11)
		var rtween = record_lbl.create_tween()
		rtween.tween_property(record_lbl, "scale", Vector2(1.3, 1.3), 0.2)
		rtween.tween_property(record_lbl, "scale", Vector2(1.0, 1.0), 0.1)
	panel.visible = true
	if retry_button:
		retry_button.visible = true
	var retry_panel_node = panel.get_node_or_null("RetryPanel")
	if retry_panel_node:
		retry_panel_node.visible = true
	if next_button:
		next_button.visible = success and next_level_path != ""
	var next_panel_node = panel.get_node_or_null("NextPanel")
	if next_panel_node:
		next_panel_node.visible = success and next_level_path != ""
	if success and stars > 0:
		_show_stars_animation(ui, stars)

func _show_stars_animation(ui: CanvasLayer, stars: int):
	var panel = ui.get_node_or_null("ResultPanel")
	var star_x = [150.0, 240.0, 330.0]
	var star_y = [175.0, 160.0, 175.0]
	var delays = [0.3, 0.6, 0.9]
	for i in 3:
		var lbl = Label.new()
		lbl.text = "⭐"
		lbl.size = Vector2(48, 52)
		lbl.position = Vector2(star_x[i] - 24, star_y[i] + ui_dy)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 48)
		if i >= stars:
			lbl.modulate = Color(1.0, 1.0, 1.0, 0.2)
		else:
			lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
		if panel:
			panel.add_child(lbl)
		else:
			ui.add_child(lbl)
		if i < stars:
			var tween = lbl.create_tween()
			tween.tween_interval(delays[i])
			lbl.scale = Vector2(0.1, 0.1)
			lbl.pivot_offset = Vector2(24, 26)
			tween.tween_property(lbl, "scale", Vector2(1.4, 1.4), 0.2)
			tween.tween_property(lbl, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.08)
			tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.06)
			tween.parallel().tween_property(lbl, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
			if stars == 3 and i == 2:
				tween.tween_callback(func(): _spawn_star_particles(ui))

func _spawn_star_particles(ui: CanvasLayer):
	for i in 20:
		var p = Label.new()
		p.text = "✨"
		p.add_theme_font_size_override("font_size", randi_range(14, 28))
		p.position = Vector2(randf_range(80, 400), randf_range(140, 220) + ui_dy)
		p.modulate = Color(1.0, randf_range(0.7, 1.0), 0.0, 1.0)
		ui.add_child(p)
		var tween = p.create_tween()
		var target_y = p.position.y - randf_range(60, 140)
		var target_x = p.position.x + randf_range(-60, 60)
		tween.tween_property(p, "position", Vector2(target_x, target_y), randf_range(0.5, 1.0))
		tween.parallel().tween_property(p, "modulate:a", 0.0, randf_range(0.5, 1.0))
		tween.tween_callback(p.queue_free)

func _on_retry():
	LevelTransition.flash_and_load(get_tree().current_scene.scene_file_path)

func _on_next_level():
	if next_level_path != "":
		LevelTransition.flash_and_load(next_level_path)

func _on_restart_from_beginning():
	_save_total_score(0)
	_save_lives(3)
	LevelTransition.flash_and_load("res://scenes/Level1.tscn")

func _show_game_over(is_new_record: bool = false):
	var ui = get_node_or_null("UILayer")
	if not ui:
		return
	var panel = ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0.0, 0.0, 0.0, 0.92)
	ui.add_child(panel)

	var icon = Label.new()
	icon.text = "💀"
	icon.set_anchors_preset(Control.PRESET_TOP_WIDE)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.position.y = 55
	icon.add_theme_font_size_override("font_size", 64)
	panel.add_child(icon)

	var title = Label.new()
	title.text = "GAME OVER"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 128
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.0, 0.8))
	title.add_theme_constant_override("shadow_outline_size", 10)
	panel.add_child(title)

	if is_new_record:
		var rec_lbl = Label.new()
		rec_lbl.text = "🥇 NEW RECORD!"
		rec_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
		rec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rec_lbl.position.y = 178
		rec_lbl.add_theme_font_size_override("font_size", 22)
		rec_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		rec_lbl.add_theme_constant_override("shadow_outline_size", 6)
		panel.add_child(rec_lbl)
		rec_lbl.scale = Vector2(0.3, 0.3)
		rec_lbl.pivot_offset = Vector2(240, 11)
		var rtween = rec_lbl.create_tween()
		rtween.tween_property(rec_lbl, "scale", Vector2(1.3, 1.3), 0.25)
		rtween.tween_property(rec_lbl, "scale", Vector2(1.0, 1.0), 0.1)

	var sub = Label.new()
	sub.text = "🏆 Score: %d coins  |  Level %d" % [total_score, level_number]
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position.y = 210
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	panel.add_child(sub)

	var lb_title = Label.new()
	lb_title.text = "🏅 TOP 5 SCORES"
	lb_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb_title.position.y = 244
	lb_title.add_theme_font_size_override("font_size", 15)
	lb_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9, 0.9))
	panel.add_child(lb_title)

	# Kutu kayıt sayısı kadar uzar; tek kayıtta koca boş alan kalmasın
	var entries = _load_leaderboard()
	var lb_h = max(1, min(entries.size(), 5)) * 34 + 10
	var lb_bg = ColorRect.new()
	lb_bg.size = Vector2(360, lb_h)
	lb_bg.position = Vector2(60, 264)
	lb_bg.color = Color(0.04, 0.04, 0.16, 0.95)
	panel.add_child(lb_bg)

	var lb_top = ColorRect.new()
	lb_top.size = Vector2(360, 2)
	lb_top.position = Vector2(60, 264)
	lb_top.color = Color(1.0, 0.8, 0.0, 0.6)
	panel.add_child(lb_top)

	var medals = ["🥇", "🥈", "🥉", "4.", "5."]
	for i in min(entries.size(), 5):
		var e = entries[i]
		var row_y = 270 + i * 34
		var is_current = e["score"] == total_score and e["level"] == level_number
		var row_color = Color(1.0, 0.85, 0.0, 1.0) if is_current else Color(0.7, 0.7, 0.9, 0.85)
		var medal_lbl = Label.new()
		medal_lbl.text = medals[i]
		medal_lbl.position = Vector2(68, row_y)
		medal_lbl.add_theme_font_size_override("font_size", 16)
		panel.add_child(medal_lbl)
		var score_lbl = Label.new()
		score_lbl.text = "%d coins" % e["score"]
		score_lbl.position = Vector2(100, row_y)
		score_lbl.size = Vector2(140, 28)
		score_lbl.add_theme_font_size_override("font_size", 16)
		score_lbl.add_theme_color_override("font_color", row_color)
		panel.add_child(score_lbl)
		var lvl_lbl2 = Label.new()
		lvl_lbl2.text = "Lvl %d" % e["level"]
		lvl_lbl2.position = Vector2(248, row_y)
		lvl_lbl2.size = Vector2(60, 28)
		lvl_lbl2.add_theme_font_size_override("font_size", 14)
		lvl_lbl2.add_theme_color_override("font_color", Color(row_color.r, row_color.g, row_color.b, 0.7))
		panel.add_child(lvl_lbl2)
		var date_lbl = Label.new()
		date_lbl.text = e["date"].substr(5, 5)
		date_lbl.position = Vector2(310, row_y)
		date_lbl.size = Vector2(100, 28)
		date_lbl.add_theme_font_size_override("font_size", 13)
		date_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.6, 0.7))
		panel.add_child(date_lbl)

	# Ödüllü reklam ana eylem: en üstte, büyük ve nabız gibi atan.
	# Level seçimiyle 3 canla zaten devam edilebildiği için reklamın asıl değeri
	# puanı (coin) korumak; bunu butonun altında açıkça söylüyoruz.
	var btn_y = 264.0 + lb_h + 24.0
	var ad_bg = ColorRect.new()
	ad_bg.size = Vector2(300, 68)
	ad_bg.position = Vector2(90, btn_y)
	ad_bg.color = Color(0.1, 0.45, 0.08, 1.0)
	panel.add_child(ad_bg)
	var ad_pulse = ad_bg.create_tween().set_loops()
	ad_pulse.tween_property(ad_bg, "color", Color(0.16, 0.6, 0.12, 1.0), 0.6)
	ad_pulse.tween_property(ad_bg, "color", Color(0.1, 0.45, 0.08, 1.0), 0.6)
	var ad_btn = Button.new()
	ad_btn.text = "🎬  CONTINUE  +3 ❤️"
	ad_btn.size = Vector2(300, 68)
	ad_btn.position = Vector2(90, btn_y)
	ad_btn.flat = true
	ad_btn.add_theme_font_size_override("font_size", 24)
	ad_btn.add_theme_color_override("font_color", Color(0.75, 1.0, 0.65))
	ad_btn.pressed.connect(func():
		ad_btn.disabled = true
		AdManager.show_rewarded_ad(func(earned: bool):
			if earned:
				coins_since_last_life = 0
				lives = 3
				_save_lives(3)
				get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)
			else:
				ad_btn.disabled = false
				ad_btn.add_theme_font_size_override("font_size", 16)
				ad_btn.text = "Ad not ready, retry"
		)
	)
	panel.add_child(ad_btn)

	var ad_hint = Label.new()
	if total_score > 0:
		ad_hint.text = "Watch an ad · keep your %d coins" % total_score
	else:
		ad_hint.text = "Watch an ad · continue from Lvl %d" % level_number
	ad_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ad_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_hint.position.y = btn_y + 72
	ad_hint.add_theme_font_size_override("font_size", 14)
	ad_hint.add_theme_color_override("font_color", Color(0.6, 0.9, 0.55, 0.85))
	panel.add_child(ad_hint)

	var retry_bg2 = ColorRect.new()
	retry_bg2.size = Vector2(280, 54)
	retry_bg2.position = Vector2(100, btn_y + 104)
	retry_bg2.color = Color(0.05, 0.15, 0.45, 1.0)
	panel.add_child(retry_bg2)
	var retry2 = Button.new()
	# Bu buton Level 1'den başlatıyor; "TRY AGAIN" aynı level'i tekrar deniyormuş gibi okunuyordu
	retry2.text = "🔁  START OVER"
	retry2.size = Vector2(280, 54)
	retry2.position = Vector2(100, btn_y + 104)
	retry2.flat = true
	retry2.add_theme_font_size_override("font_size", 20)
	retry2.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	retry2.pressed.connect(func():
		_save_total_score(0)
		coins_since_last_life = 0
		_save_lives(3)
		get_tree().change_scene_to_file("res://scenes/Level1.tscn")
	)
	panel.add_child(retry2)

	var btn_bg = ColorRect.new()
	btn_bg.size = Vector2(280, 54)
	btn_bg.position = Vector2(100, btn_y + 168)
	btn_bg.color = Color(0.4, 0.05, 0.05, 1.0)
	panel.add_child(btn_bg)
	var btn = Button.new()
	btn.text = "🏠  MAIN MENU"
	btn.size = Vector2(280, 54)
	btn.position = Vector2(100, btn_y + 168)
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	btn.pressed.connect(func():
		_save_total_score(0)
		coins_since_last_life = 0
		_save_lives(3)
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	panel.add_child(btn)

	ScreenUtil.shift_children(panel, ui_dy)

func _vibrate(ms: int):
	if OS.get_name() != "Android":
		return
	Input.vibrate_handheld(ms)
