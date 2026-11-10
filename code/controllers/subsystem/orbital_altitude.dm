SUBSYSTEM_DEF(orbital_altitude)
	name = "Orbital Altitude"
	can_fire = TRUE
	wait = 0.25 SECONDS
	ss_flags = SS_NO_INIT | SS_KEEP_TIMING

	/// Current orbital altitude in meters
	var/orbital_altitude = ORBITAL_ALTITUDE_DEFAULT

	// ---------------------------------------
	// TRUE ORBIT VARS
	// ---------------------------------------

	var/semi_major_axis = ORBITAL_ALTITUDE_DEFAULT
	var/eccentricity = 0
	var/arg_of_periapsis = 0
	var/orbital_epoch = 0

	var/cached_eccentric_anomaly

	var/cached_station_pos
	var/cached_station_velocity

	var/target_angle = 0
	var/actual_angle = 0

	var/orbital_angle = 0

	// ---------------------------------------
	// ORBIT-KEEPING VARS
	// ---------------------------------------

	/// Should we counteract atmospheric resistance (only if we are facing prograde) at all times to keep our orbit?
	var/orbit_keeping = TRUE
	/// The gain of the PID
	var/keeping_gain = 0.01
	/// The derivitive time of the PID
	var/keeping_derivitive = 0.1
	/// The integral time of the PID
	var/keeping_integral = 4
	/// Last error from the previous cycle of the PID
	var/keeping_last_error = 0
	/// Accumulated error of the PID
	var/keeping_accumulated_error = 0
	/// List of error over time for display purposes.
	var/list/error_over_time = list()

	// ---------------------------------------

	/// Global throttle
	var/throttle = 1
	/// Current thrust applied to the station (from engines)
	var/thrust = 0
	/// Atmospheric resistance coefficient
	var/resistance = 0
	/// Bitflag of current orbital errors
	var/errors = NONE

	/// List of all orbital thrusters
	var/list/orbital_thrusters = list()

	COOLDOWN_DECLARE(orbital_report_cooldown)
	COOLDOWN_DECLARE(orbital_report_critical)
	COOLDOWN_DECLARE(heavy_atmospheric_drag_cooldown)

/datum/controller/subsystem/orbital_altitude/fire(resumed = FALSE)
	// Disable for planetary stations (they don't orbit)
	if(SSmapping.current_map.planetary_station)
		can_fire = FALSE
		return

	check_values()
	adjust_angle()
	calculate_eccentric_anomaly()
	calculate_pos_from_epoch()
	calculate_velo_from_epoch()
	orbital_altitude_change()
	manage_orbit_keeping()
	update_thrust_from_thrusters()
	orbital_epoch += 0.5

	reentry_effects()

/datum/controller/subsystem/orbital_altitude/proc/check_values()
	if(semi_major_axis <= 0)
		stack_trace("Semi Major Axis is below or equal to 0; math will break! Resetting orbit to a more suitable number")
		//TODO - actually reset orbit

/datum/controller/subsystem/orbital_altitude/proc/adjust_angle()
	if(actual_angle == target_angle)
		return
	actual_angle += clamp(target_angle - actual_angle, -5, 5) //TODO - fix it allowing it to turn both ways

/datum/controller/subsystem/orbital_altitude/proc/get_station_pos()
	if(!cached_station_pos)
		calculate_pos_from_epoch()
	return cached_station_pos

/datum/controller/subsystem/orbital_altitude/proc/get_station_altitude()
	return sqrt(cached_station_pos[1]**2 + cached_station_pos[2]**2)

/datum/controller/subsystem/orbital_altitude/proc/calculate_velo_from_epoch()
	if(eccentricity > 0)
		var/r = semi_major_axis * (1 - eccentricity * cos(cached_eccentric_anomaly))
		var/per_velo_x = -(sqrt(CINIS_MASS * GRAVITATION_CONSTANT * semi_major_axis) / r) * sin(cached_eccentric_anomaly)
		var/per_velo_y = (sqrt(CINIS_MASS * GRAVITATION_CONSTANT * semi_major_axis * (1 - eccentricity ** 2)) / r) * cos(cached_eccentric_anomaly)

		var/real_velo_x = per_velo_x * cos(arg_of_periapsis) - per_velo_y * sin(arg_of_periapsis)
		var/real_velo_y = per_velo_x * sin(arg_of_periapsis) + per_velo_y * cos(arg_of_periapsis)

		cached_station_velocity = list(real_velo_x, real_velo_y)
		return
	var/mean_anomaly = calculate_mean_anomaly()
	var/circular_velo = sqrt((CINIS_MASS * GRAVITATION_CONSTANT) / semi_major_axis)
	cached_station_velocity = list(-circular_velo * sin(mean_anomaly + arg_of_periapsis), circular_velo * cos(mean_anomaly + arg_of_periapsis))

/datum/controller/subsystem/orbital_altitude/proc/calculate_pos_from_epoch()
	if(eccentricity > 0)
		var/per_x = semi_major_axis * (cos(cached_eccentric_anomaly) - eccentricity)
		var/per_y = semi_major_axis * sqrt(1 - eccentricity**2) * sin(cached_eccentric_anomaly)

		var/real_x = per_x * cos(arg_of_periapsis) - per_y * sin(arg_of_periapsis)
		var/real_y = per_x * sin(arg_of_periapsis) + per_y * cos(arg_of_periapsis)

		cached_station_pos = list(real_x, real_y)
		return
	var/mean_anomaly = calculate_mean_anomaly()
	cached_station_pos = list(semi_major_axis * cos(mean_anomaly + arg_of_periapsis), semi_major_axis * sin(mean_anomaly + arg_of_periapsis))

/datum/controller/subsystem/orbital_altitude/proc/calculate_eccentric_anomaly()
	var/mean_anomaly = calculate_mean_anomaly()
	var/eccentric_anomaly = eccentricity <= 0.8 ? mean_anomaly : 180
	for(var/i in 1 to ECCEN_ANOM_ITER)
		var/anomaly_error = eccentric_anomaly - eccentricity * (180 / PI) * sin(eccentric_anomaly) - mean_anomaly
		var/anomaly_derivitive = 1 - eccentricity * cos(eccentric_anomaly)

		if(abs(anomaly_derivitive) < 1e-6)
			break

		var/anomaly_correction = anomaly_error / anomaly_derivitive
		eccentric_anomaly -= anomaly_correction

		if(abs(anomaly_correction) < 1e-6)
			break

	cached_eccentric_anomaly = eccentric_anomaly

/datum/controller/subsystem/orbital_altitude/proc/calculate_mean_anomaly()
	return ((calculate_mean_motion() * orbital_epoch) * (180 / PI)) %% 360

/datum/controller/subsystem/orbital_altitude/proc/calculate_mean_motion()
	return sqrt((CINIS_MASS * GRAVITATION_CONSTANT) / semi_major_axis ** 3)

/datum/controller/subsystem/orbital_altitude/proc/calculate_adjusted_epoch()
	var/relative_x = cached_station_pos[1] * cos(arg_of_periapsis) + cached_station_pos[2] * sin(arg_of_periapsis)
	var/relative_y = -cached_station_pos[1] * sin(arg_of_periapsis) + cached_station_pos[2] * cos(arg_of_periapsis)

	var/ecc_anom_x = relative_x / semi_major_axis + eccentricity
	var/ecc_anom_y = relative_y / (semi_major_axis * sqrt(1 - eccentricity**2))

	var/ecc_anom = ATAN2(ecc_anom_x, ecc_anom_y)
	cached_eccentric_anomaly = ecc_anom %% 360

	var/mean_motion = calculate_mean_motion()
	var/mean_anomaly = cached_eccentric_anomaly - eccentricity * (180 / PI) * sin(cached_eccentric_anomaly)

	orbital_epoch = (mean_anomaly * (PI / 180)) / mean_motion

/datum/controller/subsystem/orbital_altitude/proc/update_thrust_from_thrusters()
	var/summed_thrust = 0
	for(var/datum/orbital_thruster/thruster in orbital_thrusters)
		summed_thrust += thruster.get_thrust()
	thrust = summed_thrust

/datum/controller/subsystem/orbital_altitude/proc/set_all_throttle(to_set)
	throttle = clamp(to_set, 0, 1)
	sync_all_thrusters()

/datum/controller/subsystem/orbital_altitude/proc/adjust_all_throttle(amount)
	set_all_throttle(throttle + amount)

/datum/controller/subsystem/orbital_altitude/proc/sync_all_thrusters()
	for(var/datum/orbital_thruster/thruster in SSorbital_altitude.orbital_thrusters)
		thruster.set_throttle(throttle)

/datum/controller/subsystem/orbital_altitude/proc/orbital_altitude_change()
	resistance = NUM_E ** (-orbital_altitude / CINIS_CALCULATED_DRAG_SCALE)

	var/negative_velocity_magnitude = (ORBITAL_DRAG_COEFF * resistance) / STATION_MASS
	var/magnitude = thrust / STATION_MASS

	orbital_angle = ATAN2(cached_station_velocity[1], cached_station_velocity[2])

	if(abs(orbital_angle - actual_angle) < 0.1)
		if(abs(magnitude - negative_velocity_magnitude) < 0.001)
			return // Early return when the thrust vector is near equal to resistance- thus meaning no force is actually being applied.
			//TODO - think about this and fix it

	var/new_velo_x = cached_station_velocity[1] + (magnitude * cos(orbital_angle + actual_angle)) + (negative_velocity_magnitude * -cos(orbital_angle))
	var/new_velo_y = cached_station_velocity[2] + (magnitude * sin(orbital_angle + actual_angle)) + (negative_velocity_magnitude * -sin(orbital_angle))

	var/pos_magnitude = get_station_altitude()

	orbital_altitude = pos_magnitude //TODO - find a better place for this.

	var/velo_magnitude_sqrd = new_velo_x**2 + new_velo_y**2
	var/radial_dot = cached_station_pos[1] * new_velo_x + cached_station_pos[2] * new_velo_y

	var/orbital_energy = velo_magnitude_sqrd / 2 - (CINIS_MASS * GRAVITATION_CONSTANT) / pos_magnitude

	if(orbital_energy >= 0)
		return

	var/new_sma = 1 / (2 / pos_magnitude - velo_magnitude_sqrd / (CINIS_MASS * GRAVITATION_CONSTANT))

	if(new_sma * (1 + eccentricity) > ORBITAL_ALTITUDE_HIGH_BOUND)
		set_error(TRUE, ORBITAL_ERROR_TOO_HIGH)
		return
	if(new_sma * (1 - eccentricity) < ORBITAL_ALTITUDE_ABSOLUTE_MIN)
		set_error(TRUE, ORBITAL_ERROR_TOO_LOW)
		return

	set_error(FALSE, ORBITAL_ERROR_TOO_HIGH)
	set_error(FALSE, ORBITAL_ERROR_TOO_LOW)

	semi_major_axis = new_sma

	var/eccentricity_x = calculate_eccentricity_vector_comp(cached_station_pos[1], new_velo_x, pos_magnitude, radial_dot, velo_magnitude_sqrd)
	var/eccentricity_y = calculate_eccentricity_vector_comp(cached_station_pos[2], new_velo_y, pos_magnitude, radial_dot, velo_magnitude_sqrd)

	eccentricity = sqrt(eccentricity_x**2 + eccentricity_y**2)
	arg_of_periapsis = eccentricity > 0 ? ATAN2(eccentricity_x, eccentricity_y) : 0

	calculate_adjusted_epoch()

/datum/controller/subsystem/orbital_altitude/proc/calculate_eccentricity_vector_comp(pos_component, velo_component, pos_magnitude, radial_dot, velo_magnitude_sqrd)
	return ((velo_magnitude_sqrd - (CINIS_MASS * GRAVITATION_CONSTANT) / pos_magnitude) * pos_component - radial_dot * velo_component) / (CINIS_MASS * GRAVITATION_CONSTANT)

/datum/controller/subsystem/orbital_altitude/proc/manage_orbit_keeping()
	if(!orbit_keeping)
		return

	if(abs(actual_angle - PROGRADE) > 1) // TODO - make this respect 360 degree wraparound
		set_error(TRUE, ORBITAL_ERROR_KEEPING_FACING)
		return
	set_error(FALSE, ORBITAL_ERROR_KEEPING_FACING)

	if(resistance < 0.001)
		set_all_throttle(0)
		return

	var/error = (resistance * ORBITAL_DRAG_COEFF - thrust) / (resistance * ORBITAL_DRAG_COEFF)

	if(length(error_over_time) >= 50)
		popleft(error_over_time)
	error_over_time += error
	// TODO - redundant clamping?
	var/output = clamp(keeping_gain * (error + (1 / keeping_integral) * keeping_accumulated_error + keeping_derivitive * (error - keeping_last_error)), 0, 1)

	keeping_accumulated_error += error
	keeping_last_error = error

	set_all_throttle(output)

/datum/controller/subsystem/orbital_altitude/proc/set_error(state, flag) // TODO - think about if this is even needed. Vars better probable
	if(state && !(errors & flag))
		errors |= flag
		return TRUE
	else if(!state && (errors & flag))
		errors &= ~flag
		return TRUE
	return FALSE

/datum/controller/subsystem/orbital_altitude/proc/reentry_effects()
	if(orbital_altitude >= ORBITAL_ALTITUDE_LOW)
		return
	SSsuperstructure.damage_structure(resistance * ORBITAL_SUPERSTUCTURE_DAM_MAX)
