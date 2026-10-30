#define CRUCIBLE_PLASTEEL list(/datum/material/iron = 1, /datum/material/plasma = 1)
#define CRUCIBLE_PLASTITIANIUM list(/datum/material/titanium = 1, /datum/material/plasma = 1)
#define CRUCIBLE_FERROCARBON list(/datum/material/iron = 10, /datum/material/diamond = 1)
#define CRUCIBLE_DUREENIUM list(/datum/material/iron = 5, /datum/material/plasma = 2, /datum/material/diamond = 1, /datum/material/titanium = 2)
#define CRUCIBLE_ALLOYS list("Plasteel" = CRUCIBLE_PLASTEEL, "Plastitianium" = CRUCIBLE_PLASTITIANIUM, "Ferrocarbon" = CRUCIBLE_FERROCARBON, "Dureenium" = CRUCIBLE_DUREENIUM)

/obj/machinery/multitile/hull_stabilizer
	name = "station hull crucible"
	desc = "This device that uses material and nanite canisters to repair and manage the station's hull."

	template = list(\
		list(list("template_type" = "0",  "density" = FALSE), "1", list("template_type" = "3",  "density" = FALSE)),\
		list("4", null, "6"),\
		list(list("template_type" = "7",  "density" = FALSE), "8", list("template_type" = "9",  "density" = FALSE))\
	)

	var/list/obj/structure/hull_nanite_canister/canisters = list()
	var/datum/component/material_container/materials
	var/selected_alloy

/obj/machinery/multitile/hull_stabilizer/Initialize(mapload)
	materials = AddComponent(/datum/component/material_container, list(/datum/material/iron, /datum/material/diamond, /datum/material/titanium, /datum/material/plasma,), 0, MATCONTAINER_EXAMINE, null, null)
	selected_alloy = CRUCIBLE_ALLOYS[1]
	. = ..()

/obj/machinery/multitile/hull_stabilizer/process(delta_time)
	SSsuperstructure.adjust_hull(3)

/// Consume one alloy's worth of materials.
/obj/machinery/multitile/hull_stabilizer/proc/consume_selected_alloy(amount)
	var/alloy_total = 0
	for(var/key in CRUCIBLE_ALLOYS[selected_alloy])
		alloy_total += CRUCIBLE_ALLOYS[selected_alloy][key]
	if(amount < alloy_total || !alloy_total)
		return 0
	if(!materials.has_materials(CRUCIBLE_ALLOYS[selected_alloy], amount / alloy_total))
		return 0
	materials.use_materials(CRUCIBLE_ALLOYS[selected_alloy], amount / alloy_total)

/obj/machinery/multitile/hull_stabilizer/proc/adjust_nanites(amount)
	if(!length(canisters))
		return 0 // Not FALSE since this does not represent a boolean

	var/list/cans_to_nanites = list()
	for(var/obj/structure/hull_nanite_canister/canister in canisters)
		cans_to_nanites[canister] = canister.nanites

	var/amount_removed = 0
	var/remove_per_can = amount / length(canisters)
	for(var/obj/structure/hull_nanite_canister/canister in sortTim(cans_to_nanites, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)) // sorted, since you need to start taking from the least filled canister.
		var/actually_removed = canister.adjust_nanites(remove_per_can)
		amount_removed += actually_removed
		remove_per_can += remove_per_can - actually_removed

	return amount_removed

/obj/machinery/multitile/hull_stabilizer/proc/get_nanites()
	var/total = 0
	for(var/obj/structure/hull_nanite_canister/canister in canisters)
		total += canister.nanites
	return total

/obj/machinery/multitile/hull_stabilizer/proc/add_canister(obj/structure/hull_nanite_canister/canister)
	RegisterSignal(canister, COMSIG_QDELETING, PROC_REF(remove_canister))
	canisters += canister

/obj/machinery/multitile/hull_stabilizer/proc/remove_canister(obj/structure/hull_nanite_canister/canister)
	UnregisterSignal(canister, COMSIG_QDELETING) // TODO - Investigate this
	canisters -= canister

/obj/structure/hull_nanite_canister
	name = "hull-repair nanite canister"
	desc = "A stasis canister for organo-synth nanite clusters meant to be attached to the hull crucible to provide replacement nanites."
	icon = 'icons/obj/machines/hull_stabilizer.dmi'
	icon_state = "nanite_canister"
	var/nanites = 100
	var/datum/weakref/crucible

/obj/structure/hull_nanite_canister/wrench_act(mob/living/user, obj/item/tool)
	if(anchored)
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(FALSE)
		var/obj/machinery/multitile/hull_stabilizer/old_crucible = crucible?.resolve()
		old_crucible?.remove_canister(src)
		return TRUE
	var/obj/machinery/multitile/hull_stabilizer/new_crucible = find_valid_crucible()
	if(crucible)
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(TRUE)
		crucible = WEAKREF(new_crucible)
		new_crucible.add_canister(src)
		return TRUE
	balloon_alert(user, "no connector!")
	return FALSE

/obj/structure/hull_nanite_canister/proc/find_crucible()
	var/list/contents_to_check = list()
	for(var/iter_x = -1, iter_x <= 1, iter_x += 2)
		for(var/iter_y = -1, iter_y <= 1, iter_y += 2)
			var/turf/turf_to_check = locate(x + iter_x, y + iter_y, z)
			contents_to_check += turf_to_check.contents
	for(var/obj/machinery/multitile/hull_stabilizer/crucible in contents_to_check)
		return crucible

/obj/structure/hull_nanite_canister/proc/find_valid_crucible()
	if(!find_crucible())
		return FALSE
	for(var/obj/structure/hull_nanite_canister/other_can in get_turf(src))
		if(other_can != src)
			return FALSE
	return TRUE

/obj/structure/hull_nanite_canister/proc/adjust_nanites(amount)
	var/initial_nanites = nanites
	nanites = clamp(nanites + amount, 0, INFINITY)
	return nanites - initial_nanites
