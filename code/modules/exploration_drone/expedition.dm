/proc/generate_expedition_eventline()
	return

/datum/expedition
	var/obj/item/exploration_drone/drone
	var/list/obj/haul = list()



/datum/expedition_eventline
	var/internal_name = "generic eventline"
	var/list/datum/expedition_event/events = list()

/datum/expedition_eventline/New(list/datum/expedition_event/to_events)
	if(to_events)
		events = to_events


/datum/expedition_eventline/asteriod
	internal_name = "asteriod_exploration"
	events = list(new /datum/expedition_event("Asteriod Spotted!", "This asteriod is rich in materials, would you like to mine it?", list(new /datum/expedition_event_option/get_obj("Mine it", list(/obj/item/stack/ore/uranium/five = 1, /obj/item/stack/ore/iron/five = 5)), new /datum/expedition_event_option("Move On"))))

/datum/expedition_eventline/asteriod/New()
	..(null)


/datum/expedition_event
	var/name = "generic event"
	var/desc = "generic desc"
	var/list/options = list(new /datum/expedition_event_option/get_obj())



/datum/expedition_event/New(to_name, to_desc, list/to_options)
	if(to_name)
		name = to_name
	if(to_desc)
		desc = to_desc
	if(to_options)
		options = to_options

/datum/expedition_event/should_fire()
	return TRUE

/datum/expedition_event/proc/fire(datum/expedition/expedition, datum/expedition_event_option/option)
	if(should_fire())
		option.fire(expedition)
		return TRUE
	return FALSE

/datum/expedition_event_option
	var/name = "generic option"

/datum/expedition_event_option/New(to_name)
	name = to_name

/datum/expedition_event_option/proc/fire(datum/expedition/expedition)
	return

/datum/expedition_event_option/get_obj
	var/list/obj/item/reward

/datum/expedition_event_option/get_obj/New(to_name, to_reward)
	..(to_name)
	reward = to_reward

/datum/expedition_event_option/get_obj/fire(datum/expedition/expedition)
	expedition.haul += new pick_weight(reward)
