/datum/fuel_burner
	var/datum/weakref/linked_reagents
	var/surface_area

/datum/fuel_burner/New(reagents, starting_surface_area = 100)
	. = ..()
	linked_reagents = WEAKREF(reagents)
	surface_area = starting_surface_area

/datum/fuel_burner/Destroy(force)
	linked_reagents = null
	. = ..()

// Probably should like, improve this massively, but eh
/datum/fuel_burner/proc/burn(delta_time)
	var/datum/reagents/combined = linked_reagents?.resolve()
	if(!combined)
		return 0

	var/list/datum/reagent/rocket/valid_fuels = list()
	var/valid_volume = 0
	var/volatility = 0
	var/total_oxygen = 0
	var/total_needed_oxygen = 0

	for(var/datum/reagent/rocket/rocket_fuel in combined.reagent_list)
		if(rocket_fuel.decomposition_temp > combined.chem_temp)
			continue // If the fuel does not react at this temp do not bother with it
		volatility += rocket_fuel.volatility * rocket_fuel.volume
		valid_fuels += rocket_fuel
		valid_volume += rocket_fuel.volume
		if(istype(rocket_fuel, /datum/reagent/rocket/rocket_fuel))
			var/datum/reagent/rocket/rocket_fuel/fuel = rocket_fuel
			total_needed_oxygen += fuel.needs_oxidizer ? fuel.oxygen_requirement * fuel.volume : 0
		if(istype(rocket_fuel, /datum/reagent/rocket/oxidizer))
			var/datum/reagent/rocket/oxidizer/oxidizer = rocket_fuel
			total_oxygen += oxidizer.oxygen_per_unit * oxidizer.volume

	var/consumed_portion = valid_volume ? clamp(surface_area / valid_volume, 0, 1) : 0
	consumed_portion = consumed_portion * (total_needed_oxygen ? clamp(total_oxygen / total_needed_oxygen, 0, 1) : 0)

	var/consumed_fuel = 0

	for(var/datum/reagent/rocket/valid_fuel in valid_fuels)
		consumed_fuel += consumed_portion * valid_fuel.volume
		combined.remove_reagent(valid_fuel.type, consumed_portion * valid_fuel.volume * delta_time)

	return consumed_fuel * volatility * delta_time


