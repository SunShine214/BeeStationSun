/obj/machinery/computer/orbital_height_control
	name = "orbital height control console"
	desc = "A console used to monitor and control the station's orbital height and positioning systems."
	icon_screen = "comm_logs"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/orbital_height_control
	light_color = LIGHT_COLOR_BLUE

	var/altitude_hold_enabled = TRUE
	var/altitude_hold_target = 110000  // in meters

	var/set_throttle = 0

/obj/machinery/computer/orbital_height_control/Initialize(mapload)
	. = ..()

/obj/machinery/computer/orbital_height_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OrbitalHeightControl", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/orbital_height_control/ui_static_data(mob/user)
	var/list/data = list()
	data["orbital_bodies"] = list(list("Dummy", 1000, 5000, 5000)) //TODO - expand on this
	data["cinus_radius"] = CINIS_RADIUS
	data["cinus_grav_mass"] = CINIS_MASS * GRAVITATION_CONSTANT
	data["cinus_name"] = "Cinis"
	return data

/obj/machinery/computer/orbital_height_control/ui_data(mob/user)
	var/list/data = list()

	// Fetch data from the orbital altitude subsystem
	data["current_altitude"] = SSorbital_altitude.get_station_altitude()
	data["orbital_velocity"] = SSorbital_altitude.cached_station_velocity
	data["station_pos"] = SSorbital_altitude.get_station_pos()
	data["station_target_angle"] = SSorbital_altitude.target_angle
	data["station_actual_angle"] = SSorbital_altitude.actual_angle
	data["semi_major_axis"] = SSorbital_altitude.semi_major_axis
	data["eccentricity"] = SSorbital_altitude.eccentricity
	data["arg_of_periapsis"] = SSorbital_altitude.arg_of_periapsis
	data["orbital_angle"] = SSorbital_altitude.orbital_angle
	data["orbit_keeping"] = SSorbital_altitude.orbit_keeping

	data["thrust_level"] = SSorbital_altitude.throttle
	data["actual_thrust"] = SSorbital_altitude.thrust

	data["atmosphere_height"] = CINIS_ATMOSPHERE + CINIS_RADIUS
	data["atmosphere_normal"] = ORBITAL_ALTITUDE_DEFAULT
	data["atmosphere_low"] = ORBITAL_ALTITUDE_LOW
	data["atmosphere_destruction"] = ORBITAL_ALTITUDE_ABSOLUTE_MIN

	return data

/obj/machinery/computer/orbital_height_control/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("increase_thrust")
			SSorbital_altitude.adjust_all_throttle(0.2)
		if("decrease_thrust")
			SSorbital_altitude.adjust_all_throttle(-0.2)
		if("toggle_orbit_keeping")
			// Toggle altitude hold system on/off
			SSorbital_altitude.orbit_keeping = !SSorbital_altitude.orbit_keeping
		if("adjust_angle")
			var/angle = text2num(params["angle"])
			if(isnull(angle))
				return FALSE
			SSorbital_altitude.target_angle = angle
	return TRUE

/obj/machinery/computer/orbital_height_control/ui_state(mob/user)
	return GLOB.default_state
