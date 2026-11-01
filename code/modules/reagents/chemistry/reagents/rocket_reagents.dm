/datum/reagent/rocket
	abstract_type = /datum/reagent/rocket
	var/volatility = 0
	var/decomposition_temp = 400

/datum/reagent/rocket/rocket_fuel
	abstract_type = /datum/reagent/rocket/rocket_fuel
	var/oxygen_requirement = 0
	var/needs_oxidizer = TRUE

/datum/reagent/rocket/oxidizer
	abstract_type = /datum/reagent/rocket/oxidizer
	var/oxygen_per_unit = 0

/datum/reagent/rocket/rocket_fuel/hydrazine
	name = "Hydrazine"
	description = "N2H4. A highly volatile fuel."
	reagent_state = LIQUID
	color = "#be5050"
	chemical_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "fishy ammonia"
	process_flags = ORGANIC
	volatility = 2
	oxygen_requirement = 2

/datum/reagent/rocket/rocket_fuel/plasmatic_nitrolymine
	name = "Plasmatic Nitrolymine"
	description = "Pl6N2H2. Flaming death."
	reagent_state = SOLID
	color = "#992d7e"
	chemical_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "firey death"
	process_flags = ORGANIC
	volatility = 10
	oxygen_requirement = 10

/datum/reagent/rocket/rocket_fuel/Dimethylhydrazine
	name = "Dimethylhydrazine"
	description = "C2H8N2. Better then hydrazine."
	reagent_state = SOLID
	color = "#992d7e"
	chemical_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "firey death"
	process_flags = ORGANIC
	volatility = 5
	oxygen_requirement = 10

/datum/reagent/rocket/oxidizer/ammonium_perchlorate
	name = "Ammonium Perchlorate"
	description = "NH4CLO4. Gives the needed oxygen for rocket fuel burning."
	reagent_state = SOLID
	color = "#be5050"
	chemical_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "burning ammonia"
	process_flags = ORGANIC
	volatility = 0.5
	oxygen_per_unit = 4
