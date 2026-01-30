SUBSYSTEM_DEF(orbital_altitude)
	name = "Orbital Altitude"
	can_fire = TRUE
	wait = 1 SECONDS
	flags = SS_NO_INIT | SS_KEEP_TIMING

	/// Current orbital altitude in meters
	var/orbital_altitude = ORBITAL_ALTITUDE_DEFAULT

	/// Velocity index for display purposes
	var/velocity_index = 0

	/// The orbital velocity of the station
	var/orbital_velocity = CALCULATED_ORBITAL_VELOCITY

	/// Current thrust applied to the station (from engines)
	var/thrust = 0
	/// Atmospheric resistance coefficient
	var/resistance = 0.1

	/// List of all orbital thrusters
	var/list/orbital_thrusters = list()

	/// World time when critical orbit was entered
	var/critical_orbit_start_time = 0
	/// State of orbiting. Used for announments, mostly.
	var/orbital_stage = ORBITAL_NORM
	/// Whether the final 60-second countdown has started
	var/final_countdown_active = FALSE
	/// Security level before switching to delta
	var/previous_alert_level = SEC_LEVEL_GREEN

	/// Cached station boundaries for each Z-level
	var/list/station_bounds_cache
	/// Whether station bounds have been calculated
	var/bounds_calculated = FALSE

	COOLDOWN_DECLARE(orbital_report_cooldown)
	COOLDOWN_DECLARE(orbital_report_critical)
	COOLDOWN_DECLARE(heavy_atmospheric_drag_cooldown)

/datum/controller/subsystem/orbital_altitude/fire(resumed = FALSE)
	// Disable for planetary stations (they don't orbit)
	if(SSmapping.current_map.planetary_station)
		can_fire = FALSE
		return

	// Calculate station boundaries once at startup
	if(!bounds_calculated)
		calculate_all_station_bounds()
		bounds_calculated = TRUE

	// Update thrust from all orbital thrusters
	update_thrust_from_thrusters()

	// Update orbital altitude based on physics
	orbital_altitude_change()

	// Check for critical orbit conditions and warnings
	check_critical_orbit()

	process_countdown()

	// Spawn atmospheric drag damage effects when critical
	if(orbital_stage == ORBITAL_LOW_CRIT)
		spawn_atmospheric_drag()

/datum/controller/subsystem/orbital_altitude/proc/get_altitude_from_orbital_velocity()
	var/gravmass = CINIS_MASS * GRAVITATION_CONSTANT
	var/radius = gravmass / (orbital_velocity**2)
	return radius - CINIS_RADIUS

/datum/controller/subsystem/orbital_altitude/proc/update_thrust_from_thrusters()
	// Calculate total thrust from all thrusters
	var/summed_thrust = 0

	for(var/obj/machinery/atmospherics/components/unary/orbital_thruster/T in orbital_thrusters)
		if(QDELETED(T))
			continue
		summed_thrust += T.thrust_strength

	thrust = summed_thrust

/datum/controller/subsystem/orbital_altitude/proc/orbital_altitude_change()
	resistance = clamp(1 - (orbital_altitude - ORBITAL_ALTITUDE_LOW_BOUND) / (ORBITAL_ALTITUDE_HIGH_BOUND - ORBITAL_ALTITUDE_LOW_BOUND), ORBITAL_MINIMUM_DRAG, 1)
	var/negative_velocity_factor = -(ORBITAL_DRAG_COEFF * resistance) / (STATION_MASS * 1000)


	orbital_velocity += (thrust) / (STATION_MASS * 1000)
	orbital_velocity += negative_velocity_factor

	velocity_index = orbital_velocity
	// Apply the change
	orbital_altitude = get_altitude_from_orbital_velocity()

	// Enforce hard altitude limits
	orbital_altitude = clamp(orbital_altitude, ORBITAL_ALTITUDE_LOW_BOUND, ORBITAL_ALTITUDE_HIGH_BOUND)

/datum/controller/subsystem/orbital_altitude/proc/set_orbital_state(new_state)
	if(new_state == orbital_stage)
		return
	if((new_state != ORBITAL_LOW_DEST) && final_countdown_active)
		end_final_countdown()
	switch(new_state)
		if(ORBITAL_HIGH_CRIT)
			priority_announce("DANGER: Station orbital altitude has exceeded critical upper threshold. \
			Current altitude: [round(orbital_altitude/1000, 0.1)]km. \
			Station entering the Osei-Hollund radiation band. Critical radiative exposure likely. \
			Immediate corrective action required.", \
			"CRITICAL ALTITUDE WARNING",
			sound = 'sound/misc/notice1.ogg',
			has_important_message = TRUE)
		if(ORBITAL_HIGH_ALT)
			priority_announce("Advisory: Station orbital altitude has entered a high altitude orbit. \
			Current altitude: [round(orbital_altitude/1000, 0.1)]km. \
			Entering radiative zone at this altitude. Further monitoring is advised.", \
			"High Altitude Advisory",
			sound = 'sound/misc/notice2.ogg')
		if(ORBITAL_LOW_ALT)
			priority_announce("Advisory: Station orbital altitude has entered a low altitude orbit. \
			Current altitude: [round(orbital_altitude/1000, 0.1)]km. \
			Further monitoring is advised.", \
			"Orbital Altitude Advisory",
			sound = 'sound/misc/notice2.ogg')
		if(ORBITAL_LOW_CRIT)
			priority_announce("WARNING: Station orbital altitude has entered a critically low orbit. Structural damage detected.\nRestore orbital parameters immediately.",
			"CRITICAL ORBITAL FAILURE",
			sound = 'sound/misc/notice1.ogg',
			has_important_message = TRUE)
		if(ORBITAL_LOW_DEST)
			priority_announce("ALERT: The Station is experiencing stress above its survivable limit. The Station super-structure will fall apart in 1 minute.\nEvacuate now.",
			"COMPLETE ORBITAL FAILURE",
			sound = 'sound/misc/notice1.ogg',
			has_important_message = TRUE)
			start_final_countdown()
	orbital_stage = new_state

/datum/controller/subsystem/orbital_altitude/proc/check_critical_orbit()
	// High altitude critical warning
	if(orbital_altitude > ORBITAL_ALTITUDE_HIGH_CRITICAL)
		set_orbital_state(ORBITAL_HIGH_CRIT)
		return

	// High altitude warning
	if(orbital_altitude > ORBITAL_ALTITUDE_HIGH)
		set_orbital_state(ORBITAL_HIGH_ALT)
		return

	if((ORBITAL_ALTITUDE_LOW < orbital_altitude) && (orbital_altitude < ORBITAL_ALTITUDE_HIGH))
		set_orbital_state(ORBITAL_NORM)
		return

	// Ordered this way to ensure it returns on the right if
	// Critical altitude warning and countdown start
	if(orbital_altitude < ORBITAL_ALTITUDE_ABSOLUTE_MIN)
		set_orbital_state(ORBITAL_LOW_DEST)
		return

	// Critical altitude warning
	if(orbital_altitude < ORBITAL_ALTITUDE_LOW_CRITICAL)
		set_orbital_state(ORBITAL_LOW_CRIT)
		return

	// Low altitude warning
	if(orbital_altitude < ORBITAL_ALTITUDE_LOW)
		set_orbital_state(ORBITAL_LOW_ALT)
		return

/datum/controller/subsystem/orbital_altitude/proc/process_countdown()
	if(!final_countdown_active)
		return

	var/time_remaining = ORBITAL_TIME_TO_DEST - (world.time - critical_orbit_start_time)
	if(time_remaining <= 0)
		initiate_destruction()
		end_final_countdown()

/datum/controller/subsystem/orbital_altitude/proc/start_final_countdown()
	previous_alert_level = SSsecurity_level.get_current_level_as_text()
	SSsecurity_level.set_level(SEC_LEVEL_DELTA)
	critical_orbit_start_time = world.time
	final_countdown_active = TRUE

/datum/controller/subsystem/orbital_altitude/proc/end_final_countdown()
	// Restore previous security level if we escalated to delta
	SSsecurity_level.set_level(previous_alert_level)
	final_countdown_active = FALSE

/datum/controller/subsystem/orbital_altitude/proc/initiate_destruction()
	Cinematic(CINEMATIC_SELFDESTRUCT, world, CALLBACK(src, PROC_REF(complete_destruction)))

/datum/controller/subsystem/orbital_altitude/proc/complete_destruction()
	// Kill all living mobs on station levels
	for(var/mob/living/L in GLOB.mob_living_list)
		var/turf/T = get_turf(L)
		if(T && is_station_level(T.z))
			L.investigate_log("has died from orbital decay.", INVESTIGATE_DEATHS)
			L.gib()

	// Force round end
	SSticker.force_ending = FORCE_END_ROUND

/datum/controller/subsystem/orbital_altitude/proc/spawn_atmospheric_drag()
	var/list/station_z_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_z_levels))
		return

	var/target_z = pick(station_z_levels)
	var/list/bounds = station_bounds_cache["[target_z]"]
	if(!bounds)
		return

	// Pick a random edge to spawn from
	var/edge = rand(1, 4)
	var/turf/start_turf
	var/turf/target_turf

	switch(edge)
		if(1) // Top edge
			start_turf = locate(rand(bounds["min_x"], bounds["max_x"]), bounds["max_y"] + 10, target_z)
			target_turf = locate(rand(bounds["min_x"], bounds["max_x"]), bounds["min_y"], target_z)
		if(2) // Bottom edge
			start_turf = locate(rand(bounds["min_x"], bounds["max_x"]), bounds["min_y"] - 10, target_z)
			target_turf = locate(rand(bounds["min_x"], bounds["max_x"]), bounds["max_y"], target_z)
		if(3) // Right edge
			start_turf = locate(bounds["max_x"] + 10, rand(bounds["min_y"], bounds["max_y"]), target_z)
			target_turf = locate(bounds["min_x"], rand(bounds["min_y"], bounds["max_y"]), target_z)
		if(4) // Left edge
			start_turf = locate(bounds["min_x"] - 10, rand(bounds["min_y"], bounds["max_y"]), target_z)
			target_turf = locate(bounds["max_x"], rand(bounds["min_y"], bounds["max_y"]), target_z)

	if(!start_turf || !target_turf)
		return

	// Spawn heavy drag occasionally, light drag otherwise
	if(COOLDOWN_FINISHED(src, heavy_atmospheric_drag_cooldown))
		COOLDOWN_START(src, heavy_atmospheric_drag_cooldown, 60 SECONDS)
		new /obj/effect/meteor/atmospheric_drag/heavy(start_turf, target_turf)
	else
		new /obj/effect/meteor/atmospheric_drag(start_turf, target_turf)

/datum/controller/subsystem/orbital_altitude/proc/calculate_all_station_bounds()
	station_bounds_cache = list()

	var/list/station_z_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_z_levels))
		return

	// Calculate bounding box and cache space turfs for each station Z-level
	for(var/z_level in station_z_levels)
		var/min_x = world.maxx
		var/max_x = 1
		var/min_y = world.maxy
		var/max_y = 1
		var/found_station = FALSE

		// Iterate through all non-space areas
		for(var/area/A in GLOB.areas)
			if(A.type == /area/space || istype(A, /area/space))
				continue

			var/list/area_turfs = A.get_contained_turfs()
			if(!length(area_turfs))
				continue

			// Find the bounding box of station turfs on this Z-level
			for(var/turf/T in area_turfs)
				if(T.z != z_level)
					continue
				if(!is_station_level(T.z))
					continue

				found_station = TRUE
				min_x = min(min_x, T.x)
				max_x = max(max_x, T.x)
				min_y = min(min_y, T.y)
				max_y = max(max_y, T.y)

		// Cache the bounds for this Z-level
		if(found_station && max_x >= min_x && max_y >= min_y)
			var/key = "[z_level]"
			station_bounds_cache[key] = list("min_x" = min_x, "max_x" = max_x, "min_y" = min_y, "max_y" = max_y)

// Invisible atmospheric drag effect that damages station structures
// Simulates heating and structural stress from atmospheric re-entry
/obj/effect/meteor/atmospheric_drag
	name = "atmospheric drag"
	desc = "You shouldn't be seeing this."
	icon_state = "dust"
	alpha = 0
	hits = 1
	hitpwr = EXPLODE_LIGHT
	meteorsound = null
	meteordrop = list()
	dropamt = 0
	threat = 0
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB | PASSDOORS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	movement_type = FLYING

	/// Damage dealt to structures on impact
	var/erosionpower = 20

/obj/effect/meteor/atmospheric_drag/Initialize(mapload, target)
	. = ..()
	// Remove from global meteor list (this isn't a real meteor event)
	GLOB.meteor_list -= src
	SSaugury.unregister_doom(src)

/obj/effect/meteor/atmospheric_drag/chase_target(atom/chasing, delay, home)
	. = ..()

/obj/effect/meteor/atmospheric_drag/Bump(atom/A)
	// Pass through mobs harmlessly
	if(isliving(A) || ismob(A))
		return

	if(isturf(A))
		return ..()

	// Damage structures and machinery
	if(A.density)
		if(istype(A, /obj/structure) || istype(A, /obj/machinery))
			var/obj/O = A
			O.take_damage(erosionpower, BRUTE, "melee", 0)
		else if(istype(A, /turf/closed))
			return ..()

	return

/obj/effect/meteor/atmospheric_drag/ram_turf(turf/T)
	// Don't damage turfs with mobs on them
	for(var/mob/M in T)
		return

	if(isspaceturf(T))
		return

	// Queue minor explosion on this turf
	SSexplosions.lowturf += T

	get_hit()

/obj/effect/meteor/atmospheric_drag/get_hit()
	hits--
	if(hits <= 0)
		// Play creaking sound for atmosphere
		playsound(src.loc, pick('sound/effects/creak1.ogg', 'sound/effects/creak2.ogg'), 80, TRUE, 300, falloff_distance = 300)
		qdel(src)

/obj/effect/meteor/atmospheric_drag/examine(mob/user)
	return // Cannot be examined

/obj/effect/meteor/atmospheric_drag/attackby(obj/item/I, mob/user, params)
	return // Cannot be interacted with

/obj/effect/meteor/atmospheric_drag/CanPass(atom/movable/mover, border_dir)
	// Always let mobs pass through
	if(isliving(mover) || ismob(mover))
		return TRUE
	return ..()

/obj/effect/meteor/atmospheric_drag/CanPassThrough(atom/blocker, turf/target, blocker_dir)
	// Always pass through mobs
	if(isliving(blocker) || ismob(blocker))
		return TRUE
	return ..()

// Heavy variant for more intense damage
/obj/effect/meteor/atmospheric_drag/heavy
	name = "heavy atmospheric drag"
	hitpwr = EXPLODE_HEAVY
	hits = 50
	erosionpower = 100

/obj/effect/meteor/atmospheric_drag/heavy/ram_turf(turf/T)
	// Don't damage turfs with mobs on them
	for(var/mob/M in T)
		return

	if(isspaceturf(T))
		return

	// Queue major explosion on this turf
	SSexplosions.highturf += T

	get_hit()
