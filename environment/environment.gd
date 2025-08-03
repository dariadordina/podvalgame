extends Node3D

# NODES
@onready var sun = $WorldEnvironment/Sun
@onready var moon = $WorldEnvironment/Moon
@onready var env = $WorldEnvironment.environment

# SETTINGS
var day_length := 600.0 # 600 sec = 24 h
var time_of_day := 0.0  

func _process(delta: float) -> void:

	time_of_day += delta
	if time_of_day > day_length:
		time_of_day = 0.0

	var day_percent = time_of_day / day_length # 0.0 - 1.0

	var sun_angle = lerp(-180.0, 180.0, day_percent) # -90 = Sonnenaufgang
	sun.rotation.x = deg_to_rad(sun_angle)

	var sun_strength
	if day_percent > 0.52 and day_percent < 0.98: #cutoff
		sun_strength = 0
		sun.light_energy = 0
	else:
		sun_strength = clamp(sin(day_percent * TAU), 0.0, 1.0)
		sun.light_energy = 0.6 + sun_strength

	var warm_sun_color = Color8(255, 193, 105)
	var midday_sun_color = Color8(255, 255, 255)
	sun.light_color = warm_sun_color.lerp(midday_sun_color, sun_strength)

	
	moon.rotation.x = deg_to_rad(sun_angle + 180.0)
	var moon_strength
	
	if day_percent <= 0.52 and day_percent > 0.95:  #cutoff
		moon_strength = 0
		moon.light_energy = 0
	else:
		moon_strength = 0.4 * clamp(sin(day_percent * TAU), 0.0, 1.0)
		moon.light_energy = 1 + moon_strength

	
	moon.light_color = Color8(137, 163, 183) 

	# 5) Ambient Light: Nacht dunkler, Tag heller
	#env.ambient_light_energy = clamp(0.1 + sun_strength * 3, 0.1, 1.0)
	
	var sky = env.sky
	var sky_material = sky.sky_material
	var sky_top : Color
	var sky_horizon : Color
	
	# Sky Colors
	var night_color = Color8(52, 54, 97)
	var dawn_color  = Color8(246, 207, 157)
	var day_color   = Color8(0, 126, 255)
	var dusk_color  = Color8(231, 85, 46)


	if day_percent < 0.05:
		# Dawn: Nacht → Dawn-Farbe
		var t = clamp(day_percent / 0.05, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		sky_top = night_color.lerp(dawn_color, t)

	elif day_percent < 0.3:
		# Dawn → Day
		var t = clamp((day_percent - 0.05) / 0.25, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		sky_top = dawn_color.lerp(day_color, t)

	elif day_percent < 0.5:
		# Day → Dusk
		var t = clamp((day_percent - 0.3) / 0.2, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		sky_top = day_color.lerp(dusk_color, t)

	elif day_percent < 0.55:
		# Dusk → Night
		var t = clamp((day_percent - 0.5) / 0.05, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		sky_top = dusk_color.lerp(night_color, t)

	else:
		# Nacht
		sky_top = night_color

	# Horizon: heller, wärmer
	sky_horizon = sky_top.lerp(Color.FLORAL_WHITE, 0.75)

	sky_material.sky_top_color = sky_top
	sky_material.sky_horizon_color = sky_horizon

	# DEBUG OUTPUT
	#print("Time:", day_percent, " Sun:", sun_strength, " Sun energy", sun.light_energy, " Moon:", moon_strength, " Moon energy", moon.light_energy )
