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

// TODO, make it actually consume the oxidizer (energy releasing oxidizers already get consumed)
/datum/fuel_burner/proc/burn(delta_time)
	var/datum/reagents/combined = linked_reagents?.resolve()
	if(!combined)
		return 0

	var/list/burn_candidates = list()
	var/burn_total_volume = 0

	var/total_oxygen = 0

	var/burn_rate = combined.total_volume ? clamp(surface_area / combined.total_volume, 0, 1) : 0

	for(var/datum/reagent/to_check in combined.reagent_list)
		if(!to_check.volatile)
			continue
		if(combined.chem_temp >= to_check.volatile.decomposition_temp)
			burn_candidates += to_check
			burn_total_volume += to_check.volume
			total_oxygen += to_check.volatile.oxygen_per_unit * to_check.volume * burn_rate

	var/reaction_energy = 0

	if(!length(burn_candidates))
		return reaction_energy

	var/oxygen_per_reagent = total_oxygen / length(burn_candidates)

	if(!burn_total_volume)
		return reaction_energy

	for(var/datum/reagent/burning in burn_candidates)
		var/amount_burned = clamp(burning.volume * burn_rate * delta_time, 0, burning.volume)
		if(!burning.volatile.oxygen_requirement)
			reaction_energy += burning.volatile.reaction_energy * amount_burned
			combined.remove_reagent(burning.type, amount_burned)
			continue
		var/oxygen_per_this = oxygen_per_reagent * clamp(burning.volume / burn_total_volume, 0, 1) // Technically this leaves unburned oxygen that does not distribute but this proc is already hot enough.
		amount_burned = amount_burned * clamp(oxygen_per_this / burning.volatile.oxygen_requirement, 0, 1)
		reaction_energy += burning.volatile.reaction_energy * amount_burned
		combined.remove_reagent(burning.type, amount_burned)

	return reaction_energy





