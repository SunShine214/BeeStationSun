#define CRUCIBLE_ALLOY_MATS 1
#define CRUCIBLE_ALLOY_MULT 2

#define CRUCIBLE_PLASTEEL list(list(/datum/material/iron = 1, /datum/material/plasma = 1), 0.05)
#define CRUCIBLE_PLASTITIANIUM list(list(/datum/material/titanium = 1, /datum/material/plasma = 1), 0.1)
#define CRUCIBLE_FERROCARBON list(list(/datum/material/iron = 10, /datum/material/diamond = 1), 0.5)
#define CRUCIBLE_DUREENIUM list(list(/datum/material/iron = 5, /datum/material/plasma = 2, /datum/material/diamond = 1, /datum/material/titanium = 2), 1)

#define PLASTEEL "Plasteel"
#define PLASTITIANIUM "Plastitianium"
#define FERROCARBON "Ferrocarbon"
#define DUREENIUM "Dureenium"

#define CRUCIBLE_DEFAULT_NANITE_USE 1
#define CRUCIBLE_DEFAULT_MAT_USE 100
// TODO - Make it relinkable with DEFINE_BUFFER_HANDLER ect...
/obj/machinery/multitile/hull_crucible
	name = "station hull crucible"
	desc = "This device uses material and nanite canisters to repair and manage the station's hull."
	icon = 'icons/obj/machines/hull_crucible.dmi'
	icon_state = "5"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	move_resist = INFINITY

	template = list(\
		list(list("template_type" = "1",  "density" = FALSE), "2", list("template_type" = "3",  "density" = FALSE)),\
		list("4", null, "6"),\
		list(list("template_type" = "7",  "density" = FALSE), "8", list("template_type" = "9",  "density" = FALSE))\
	)

	template_offset_x = -1
	template_offset_y = -1

	ui = "HullCrucible"

	var/list/obj/structure/hull_nanite_canister/canisters = list()
	var/datum/component/remote_materials/materials

	var/list/crucible_alloys = list(PLASTEEL = CRUCIBLE_PLASTEEL, PLASTITIANIUM = CRUCIBLE_PLASTITIANIUM, FERROCARBON = CRUCIBLE_FERROCARBON, DUREENIUM = CRUCIBLE_DUREENIUM)
	// TODO - alloy names to defines?
	var/selected_alloy
	var/throttle = 1
	var/nanite_consumption = CRUCIBLE_DEFAULT_NANITE_USE
	var/material_consumption = CRUCIBLE_DEFAULT_MAT_USE

/obj/machinery/multitile/hull_crucible/Initialize(mapload)
	materials = AddComponent(/datum/component/remote_materials, "crucible", mapload)
	selected_alloy = crucible_alloys[PLASTEEL]
	. = ..()

/obj/machinery/multitile/hull_crucible/Destroy()
	canisters = null
	. = ..()

/obj/machinery/multitile/hull_crucible/process(delta_time)
	if(throttle <= 0) // TODO - EMAG interaction?
		return
	var/nanite_mult = -adjust_nanites(-nanite_consumption * throttle * delta_time) / (nanite_consumption * throttle * delta_time)
	SSsuperstructure.repair_structure(consume_selected_alloy(material_consumption * throttle * delta_time) * selected_alloy[CRUCIBLE_ALLOY_MULT] * nanite_mult)

/obj/machinery/multitile/hull_crucible/ui_data(mob/user)
	var/list/data = list()

	var/list/nanite_cans = list()
	for(var/obj/structure/hull_nanite_canister/can in canisters)
		nanite_cans += list(list("nanites" = can.nanites))
	data["nanite_cans"] = nanite_cans
	data["materials"] = materials.mat_container.ui_data()
	data["selected_alloy"] = assoc_key_for_value(crucible_alloys, selected_alloy) || PLASTEEL
	data["throttle"] = throttle

	return data

/obj/machinery/multitile/hull_crucible/ui_static_data(mob/user)
	var/list/data = list()

	data["alloy_types"] = assoc_to_keys(crucible_alloys)

	return data

/obj/machinery/multitile/hull_crucible/ui_act_base(action, params)
	switch(action)
		if("throttle")
			throttle = clamp(text2num(params["throttle"]), 0, 1)
		if("select_alloy")
			selected_alloy = crucible_alloys[params["alloy"]] || crucible_alloys[1]

/// Consume one alloy's worth of materials.
/obj/machinery/multitile/hull_crucible/proc/consume_selected_alloy(amount)
	var/alloy_total = 0
	for(var/key, iter_amount in selected_alloy[CRUCIBLE_ALLOY_MATS])
		alloy_total += iter_amount
	if(!alloy_total)
		return 0
	if(!materials.mat_container.has_materials(selected_alloy[CRUCIBLE_ALLOY_MATS], amount / alloy_total))
		return 0
	materials.mat_container.use_materials(selected_alloy[CRUCIBLE_ALLOY_MATS], amount / alloy_total)
	return amount

/obj/machinery/multitile/hull_crucible/proc/adjust_nanites(amount)
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

/obj/machinery/multitile/hull_crucible/proc/get_nanites()
	var/total = 0
	for(var/obj/structure/hull_nanite_canister/canister in canisters)
		total += canister.nanites
	return total

/obj/machinery/multitile/hull_crucible/proc/add_canister(obj/structure/hull_nanite_canister/canister)
	RegisterSignal(canister, COMSIG_QDELETING, PROC_REF(remove_canister))
	canisters += canister

/obj/machinery/multitile/hull_crucible/proc/remove_canister(obj/structure/hull_nanite_canister/canister)
	UnregisterSignal(canister, COMSIG_QDELETING) // TODO - Investigate this
	canisters -= canister

/obj/structure/hull_nanite_canister
	name = "hull-repair nanite canister"
	desc = "A stasis canister for organo-synth nanite clusters meant to be attached to the hull crucible to provide replacement nanites."
	icon = 'icons/obj/machines/hull_crucible.dmi'
	icon_state = "nanite_canister"
	var/nanites = 500
	var/datum/weakref/crucible

/obj/structure/hull_nanite_canister/wrench_act(mob/living/user, obj/item/tool)
	if(anchored)
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(FALSE)
		var/obj/machinery/multitile/hull_crucible/old_crucible = crucible?.resolve()
		old_crucible?.remove_canister(src)
		return TRUE
	var/obj/machinery/multitile/hull_crucible/new_crucible = find_valid_crucible()
	if(new_crucible)
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(TRUE)
		crucible = WEAKREF(new_crucible)
		new_crucible.add_canister(src)
		return TRUE
	balloon_alert(user, "no connector!")
	return TRUE

/obj/structure/hull_nanite_canister/proc/find_crucible()
	var/list/contents_to_check = list()
	for(var/iter_x = -1, iter_x <= 1, iter_x += 2)
		for(var/iter_y = -1, iter_y <= 1, iter_y += 2)
			var/turf/turf_to_check = locate(x + iter_x, y + iter_y, z)
			contents_to_check += turf_to_check.contents // TODO - look at, this is O(4 * length(contents) + n) always
	for(var/obj/machinery/multitile/hull_crucible/crucible in contents_to_check)
		return crucible

/obj/structure/hull_nanite_canister/proc/find_valid_crucible()
	var/obj/machinery/multitile/hull_crucible/crucible = find_crucible()
	if(!crucible)
		return
	for(var/obj/structure/hull_nanite_canister/other_can in get_turf(src))
		if(other_can != src)
			return
	return crucible

/obj/structure/hull_nanite_canister/proc/adjust_nanites(amount)
	var/initial_nanites = nanites
	nanites = clamp(nanites + amount, 0, INFINITY)
	return nanites - initial_nanites
