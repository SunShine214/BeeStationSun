/obj/machinery/multitile/icafr
	name = "Inertially Confined Antimatter-Fusion Reactor"
	desc = "Using exotic gases and high power lasers it generates an anti-proton fusion reaction that can produce more energy then it consumes."
	var/laser_recievers = list()

/obj/machinery/multitile/icafr/Initialize(mapload)
	. = ..()

/obj/machinery/multitile/icafr/setup_objects()
	components = list(new /datum/multitile_component(new /obj/structure/icafr_laser_lens(get_step(get_turf(src), NORTH), src)))

/obj/machinery/multitile/icafr/proc/laser_hit(obj/structure/icafr_laser_lens/reciever, laser_strength)
	if(!laser_recievers[reciever])
		CRASH("ICAFR recieving laser from unrecognized laser lens")
	laser_recievers[reciever] += laser_strength



/obj/structure/icafr_laser_lens
	name = "ICAFR laser focus"
	desc = "A highly advanced lens for focusing anything from a Gigawatt laser to a Petawatt laser, or maybe even beyond."
	var/obj/machinery/multitile/icafr/parent
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"

/obj/structure/icafr_laser_lens/Initialize(mapload, obj/machinery/multitile/icafr/new_parent)
	. = ..()
	parent = new_parent


/obj/structure/icafr_laser_lens/bullet_act(obj/projectile/P)
	if(!istype(P, /obj/projectile/beam/emitter/gigalaser))
		return ..()
	var/obj/projectile/beam/emitter/gigalaser/lazer = P
	parent.laser_hit(src, lazer.laser_strength)
