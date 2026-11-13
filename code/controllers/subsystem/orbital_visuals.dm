SUBSYSTEM_DEF(orbital_visuals)
	name = "Orbital Visuals"
	can_fire = TRUE
	wait = 0.25 SECONDS
	ss_flags = SS_KEEP_TIMING
	dependencies = list(
		/datum/controller/subsystem/mapping,
	)

	/// Whether atmospheric fire visual effects are active
	var/atmospheric_fire_effect_active = FALSE
	/// Original starlight color before fire effects
	var/original_starlight_colour = COLOR_STARLIGHT
	/// List of fire colors for atmospheric re-entry effects
	var/list/fire_colors = list(LIGHT_COLOR_FIRE, LIGHT_COLOR_LAVA, LIGHT_COLOR_ORANGE, "#FF4500", "#FF6B00", "#FFA500")

	var/list/station_z_levels
	var/matrix/scrolling_direction = matrix(1, 0, 0, 0, 1, 480)
	COOLDOWN_DECLARE(parallax_update_cooldown)

/datum/controller/subsystem/orbital_visuals/Initialize()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_LOGGED_IN, PROC_REF(on_mob_login))
	station_z_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	switch(SSmapping.current_map.reentry_direction)
		if(NORTH)
			scrolling_direction = matrix(1, 0, 0, 0, 1, 480)
		if(SOUTH)
			scrolling_direction = matrix(1, 0, 0, 0, 1,-480)
		if(EAST)
			scrolling_direction = matrix(1, 0, 480, 0, 1, 0)
		if(WEST)
			scrolling_direction = matrix(1, 0,-480, 0, 1, 0)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/orbital_visuals/fire(resumed = FALSE)
	// Disable for planetary stations (they don't orbit)
	if(SSmapping.current_map.planetary_station)
		can_fire = FALSE
		return

	// Get current orbital altitude
	var/orbital_altitude = SSorbital_altitude.orbital_altitude

	if(COOLDOWN_FINISHED(src, parallax_update_cooldown))
		for(var/level in station_z_levels)
			for (var/mob/mob as anything in SSmobs.clients_by_zlevel[level])
				update_background(mob)
		COOLDOWN_START(src, parallax_update_cooldown, 2 SECONDS)

	// Start atmospheric fire effects at 95km (LOW threshold) for early warning
	if(orbital_altitude < ORBITAL_ALTITUDE_LOW && !atmospheric_fire_effect_active)
		start_atmospheric_fire_effect()

	// Update visual atmospheric fire effects
	if(atmospheric_fire_effect_active)
		flicker_atmospheric_fire_effect()

	// Stop fire effects when safely above 95km
	if(orbital_altitude >= ORBITAL_ALTITUDE_LOW && atmospheric_fire_effect_active)
		stop_atmospheric_fire_effect()

/datum/controller/subsystem/orbital_visuals/proc/on_mob_login(datum/source, mob/new_login)
	SIGNAL_HANDLER
	//Register the required signals
	RegisterSignal(new_login, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_mob_changed_z_level))
	RegisterSignal(new_login, COMSIG_MOB_LOGOUT, PROC_REF(on_mob_logout))

/datum/controller/subsystem/orbital_visuals/proc/on_mob_logout(mob/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_Z_CHANGED)
	UnregisterSignal(source, COMSIG_MOB_LOGOUT)

/datum/controller/subsystem/orbital_visuals/proc/on_mob_changed_z_level(mob/source, old_z, new_z)
	SIGNAL_HANDLER
	update_background(source)

/datum/controller/subsystem/orbital_visuals/proc/update_background(mob/source) // TODO - auto expand the amount of atmos tiles depending on view size?
	var/client/to_update = source.client
	if(!to_update || !to_update?.atmosphere_background)
		return
	animate(to_update.atmosphere_background, alpha = get_alpha_from_orbit(), 2 SECONDS)
	for(var/atom/movable/screen/atmosphere_background/background in to_update.atmosphere_background.vis_contents)
		animate(background, transform = scrolling_direction, 2 SECONDS, loop = -1)
		animate(transform = matrix(), 0, loop = -1)


/datum/controller/subsystem/orbital_visuals/proc/start_atmospheric_fire_effect()
	if(atmospheric_fire_effect_active)
		return

	atmospheric_fire_effect_active = TRUE
	original_starlight_colour = GLOB.starlight_colour // Do we need to do this?

	// Start with a subtle transition to a fire color
	var/initial_color = pick(fire_colors)
	var/brightened = brighten_color(initial_color, 1.15) // 15% brighter for subtle effect
	set_starlight_colour(brightened, 2 SECONDS) // Slow fade-in

/datum/controller/subsystem/orbital_visuals/proc/flicker_atmospheric_fire_effect()
	if(!atmospheric_fire_effect_active)
		return

	// Get current orbital altitude from the orbital_altitude subsystem
	var/orbital_altitude = SSorbital_altitude.orbital_altitude

	// Calculate atmospheric depth relative to the LOW threshold (95km)
	// depth_ratio scales from:
	//   0.0 at 95km (just entered LOW threshold - subtle effect)
	//   0.5 at 90km (critical threshold - noticeable)
	//   1.0 at 85km (extreme atmospheric drag - intense)
	//   1.5 at 80km (hard minimum - overwhelming)
	var/atmospheric_depth = 95000 - orbital_altitude
	var/depth_ratio = clamp(atmospheric_depth / 10000, 0, 1.5)

	// Progressive intensity scaling based on atmospheric depth
	// Transition speed decreases as we descend (slower = more frequent changes)
	var/transition_time = max(0.1, (1.5 - depth_ratio)) // 1.5s → 0.1s

	var/flicker_intensity = rand(60, 100)
	var/picked_color = pick(fire_colors)

	// Brightness multiplier increases with depth
	var/base_brightness = 1.0 + (depth_ratio * 0.5) // 1.0x → 1.75x
	var/brightened_color = brighten_color(picked_color, base_brightness + (flicker_intensity / 300))
	set_starlight_colour(brightened_color, transition_time)

/datum/controller/subsystem/orbital_visuals/proc/get_alpha_from_orbit()
	return (clamp(2 - (2 * SSorbital_altitude.orbital_altitude - 2 * CINIS_RADIUS) / CINIS_ATMOSPHERE, 0, 1)) * 255

/datum/controller/subsystem/orbital_visuals/proc/brighten_color(color_input, multiplier)
	// Extract RGB components from hex color
	var/r = hex2num(copytext(color_input, 2, 4))
	var/g = hex2num(copytext(color_input, 4, 6))
	var/b = hex2num(copytext(color_input, 6, 8))

	// Apply brightness multiplier and clamp to valid range
	r = min(255, r * multiplier)
	g = min(255, g * multiplier)
	b = min(255, b * multiplier)

	// Convert back to hex color
	return rgb(r, g, b)

/datum/controller/subsystem/orbital_visuals/proc/stop_atmospheric_fire_effect()
	if(!atmospheric_fire_effect_active)
		return

	atmospheric_fire_effect_active = FALSE

	// Slowly restore original starlight color over 5 seconds
	set_starlight_colour(original_starlight_colour, 5 SECONDS)
