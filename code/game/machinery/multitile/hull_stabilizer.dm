/obj/machinery/multitile/hull_stabilizer
	name = "station hull crucible"
	desc = "This device that uses material and nanite canisters to repair and manage the station's hull."

	template = list(\
		list(list("template_type" = "0",  "density" = FALSE), "1", list("template_type" = "3",  "density" = FALSE)),\
		list("4", null, "6"),\
		list(list("template_type" = "7",  "density" = FALSE), "8", list("template_type" = "9",  "density" = FALSE))\
	)

	var/list/obj/structure/hull_nanite_canister/canisters = list()

/obj/structure/hull_nanite_canister
	name = "hull-repair nanite canister"
	desc = "A stasis canister for organo-synth nanite clusters meant to be attached to the hull crucible to provide replacement nanites."
	icon = 'icons/obj/machines/hull_stabilizer.dmi'
	icon_state = "nanite_canister"
	var/nanites = 100

/obj/structure/hull_nanite_canister/wrench_act(mob/living/user, obj/item/tool)
	if(anchored)
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(FALSE)
		return TRUE
	else if(is_valid_canister_location())
		playsound(src, 'sound/machines/gas_attach.ogg', 50)
		set_anchored(TRUE)
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

/obj/structure/hull_nanite_canister/proc/is_valid_canister_location()
	if(!find_crucible())
		return FALSE
	for(var/obj/structure/hull_nanite_canister/other_can in get_turf(src))
		if(other_can != src)
			return FALSE
	return TRUE
