SUBSYSTEM_DEF(orbital_reentry_erosion)
	name = "Orbital Reentry Erosion"

	wait = 2 SECONDS
	dependencies = list(
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/atoms,
		/datum/controller/subsystem/orbital_altitude,
	)
	// Only allowed to use small portions of tick
	priority = FIRE_PRIORITY_ORBITAL_STUFF
	runlevels = RUNLEVEL_GAME
	/// Station levels
	var/list/station_levels
	/// Record our current work position
	var/work_z
	var/work_coord
	/// Direction flames come from (based on map config)
	var/reentry_direction = EAST
	var/list/created_fires = list()
	/// Is the subsystem currently active (altitude-based)?
	var/erosion_active = FALSE

/datum/controller/subsystem/orbital_reentry_erosion/Initialize()
	// Disable for planetary stations
	if(SSmapping.current_map.planetary_station)
		can_fire = FALSE
		return SS_INIT_SUCCESS

	// Get reentry direction from map config
	reentry_direction = SSmapping.current_map.reentry_direction

	// What are the station z-levels?
	station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)

	return SS_INIT_SUCCESS

/datum/controller/subsystem/orbital_reentry_erosion/fire(resumed)
	if(SSorbital_altitude.orbital_altitude >= ORBITAL_ALTITUDE_LOW)
		return
	SSsuperstructure.damage_structure(SSorbital_altitude.resistance * ORBITAL_SUPERSTUCTURE_DAM_MAX) // TODO - move elsewhere?? Probably SSorbital_altitude with a cooldown

/obj/effect/reentry_fire
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/fire.dmi'
	icon_state = "light"
	layer = GASFIRE_LAYER
	blend_mode = BLEND_ADD
	light_system = MOVABLE_LIGHT
	light_range = LIGHT_RANGE_FIRE
	light_power = 1
	light_color = LIGHT_COLOR_FIRE
