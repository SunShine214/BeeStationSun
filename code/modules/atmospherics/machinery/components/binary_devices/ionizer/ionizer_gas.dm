/proc/init_ionizer_gas()
	var/list/gas_to_ionizer = list()
	for(var/path in subtypesof(/datum/ionizer_gas))
		var/datum/ionizer_gas/ionizer_gas = new path
		gas_to_ionizer[ionizer_gas.gas_path] = ionizer_gas
	return gas_to_ionizer

/datum/ionizer_gas
	abstract_type = /datum/ionizer_gas
	/// Path of the [/datum/gas] involved with this interaction.
	var/gas_path
	/// List of ionizer gases (if this gas is functioning as a reaction gas) Null if it cannot be a reaction gas.
	var/list/ionizers
	/// Efficiency of this gas. (affects ionizer speed and power requirement) >1 for better speed ect
	var/efficiency = 1

/datum/ionizer_gas/nitrogen
	gas_path = /datum/gas/nitrogen
	ionizers = list(/datum/gas/oxygen, /datum/gas/plasma, /datum/gas/protoplasma)

/datum/ionizer_gas/oxygen
	gas_path = /datum/gas/oxygen
	ionizers = list(/datum/gas/nitrous_oxide)
	efficiency = 1

/datum/ionizer_gas/nitrous_oxide
	gas_path = /datum/gas/nitrous_oxide
	efficiency = 3

/datum/ionizer_gas/plasma
	gas_path = /datum/gas/plasma
	ionizers = list(/datum/gas/tritium, /datum/gas/protoplasma)
	efficiency = 4

/datum/ionizer_gas/tritium
	gas_path = /datum/gas/tritium
	efficiency = 6

/datum/ionizer_gas/hypernoblium
	gas_path = /datum/gas/hypernoblium
	ionizers = list(/datum/gas/protoplasma)
	efficiency = 10

/datum/ionizer_gas/protoplasma
	gas_path = /datum/gas/protoplasma
	efficiency = 10

GLOBAL_LIST_INIT(ionizer_gases, init_ionizer_gas())
