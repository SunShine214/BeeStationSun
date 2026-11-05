/datum/volatile
	/// How much energy this produces when reacting.
	var/reaction_energy
	/// Minimum temperature needed to decompose this reagent
	var/decomposition_temp
	/// How much oxygen is needed per unit to produce its reaction energy.
	var/oxygen_requirement
	/// How much oxygen this produces when decomposing.
	var/oxygen_per_unit

/datum/volatile/New(reaction_energy = 0,
		decomposition_temp = 400,
		oxygen_requirement = 0,
		oxygen_per_unit = 0
		)
	. = ..()
	src.reaction_energy = reaction_energy
	src.decomposition_temp = decomposition_temp
	src.oxygen_requirement = oxygen_requirement
	src.oxygen_per_unit = oxygen_per_unit
