#define TEMPLATE_PART_DUMMY 1

/obj/machinery/multitile
	abstract_type = /obj/machinery/multitile
	density = TRUE

	/// -------------------
	/// Templates are like as follows:
	/// [
	///		["icon_state", /type],
	///		[TEMPLATE_PART_DUMMY, null]
	/// ]
	/// Types will be generated with src as a parameter.
	/// Dummies will be invisible objects, just to block movement.
	/// Icon States will be visible dummies, with the icon being inherited from src. They also will call parent UI_interact and UI_act
	/// Null will be nothing, allowing for gaps in the template.
	/// using a list() as a template part allows you to define density and layer. IE: list(template_type = <type>, layer = <layer>, density = TRUE/FALSE)
	/// -------------------

	var/list/template = null
	var/template_offset_x = 0
	var/template_offset_y = 0

	var/list/obj/attached_parts = list()
	/// What ui should open upon interacting with any dummy or the main part? (Exists because tgui checks for adjacency on the mob level,
	/// rather then the machine hosting the ui :/)
	var/ui = null

/obj/machinery/multitile/Initialize(mapload)
	. = ..()
	template = reverseList(template)
	build_from_template()

/obj/machinery/multitile/Destroy()
	for(var/obj/attached in attached_parts)
		if(QDELETED(attached))
			continue
		UnregisterSignal(attached, COMSIG_QDELETING) // TODO - look at this
		qdel(attached)
	. = ..()

/obj/machinery/multitile/proc/child_destroyed()
	SIGNAL_HANDLER
	qdel(src) // TODO - delete loop?

/obj/machinery/multitile/proc/build_from_template()
	if(isnull(template))
		return
	var/iter_y = template_offset_y
	for(var/list/row in template)
		var/iter_x = template_offset_x
		for(var/item in row)
			if(isnull(item))
				iter_x ++
				continue
			if(x == iter_x && y == iter_y)
				stack_trace("Something is overlapping the main multitile machine! Fix it's template!")
			var/obj/to_attach = null
			if(islist(item))
				to_attach = get_obj_from_template(item["template_type"], iter_x, iter_y)
				if(!isnull(item["layer"]))
					to_attach.layer = item["layer"]
				if(!isnull(item["density"]))
					to_attach.density = item["density"]
			else
				to_attach = get_obj_from_template(item, iter_x, iter_y)
			if(isnull(to_attach))
				stack_trace("Unable to get object from multitile template segment. Please review the multitile template!")
				continue
			attached_parts += to_attach
			iter_x ++
		iter_y ++
	for(var/obj/attached in attached_parts)
		RegisterSignal(attached, COMSIG_QDELETING, PROC_REF(child_destroyed))

/obj/machinery/multitile/proc/get_obj_from_template(item, x_offset, y_offset)
	if(ispath(item))
		return build_type(item, locate(x + x_offset, y + y_offset, z))
	if(istext(item))
		return build_icon_dummy(item, locate(x + x_offset, y + y_offset, z))
	if(isnum(item) && item == TEMPLATE_PART_DUMMY)
		return build_dummy(locate(x + x_offset, y + y_offset, z))

/obj/machinery/multitile/proc/build_dummy(location)
	var/obj/structure/dummy/new_dummy = new(location, src)
	new_dummy.resistance_flags = resistance_flags // TODO - fix this, move it into init?
	new_dummy.move_resist = move_resist
	return new_dummy

/obj/machinery/multitile/proc/build_icon_dummy(icon_state, location)
	var/obj/structure/dummy_visible/new_dummy = new(location, src, icon_state)
	new_dummy.resistance_flags = resistance_flags
	new_dummy.move_resist = move_resist
	return new_dummy

/obj/machinery/multitile/proc/build_type(type, location)
	return new type(location, src)

/// Call this when relaying a ui_act
/obj/machinery/multitile/proc/ui_act_base(action, params)
	return

/obj/machinery/multitile/ui_act(action, params)
	if(..())
		return
	ui_act_base(action, params)

/obj/machinery/multitile/ui_interact(mob/user, datum/tgui/incoming_ui)
	if(!ui)
		return
	incoming_ui = SStgui.try_update_ui(user, src, incoming_ui)
	if(!incoming_ui)
		incoming_ui = new(user, src, ui, name)
		incoming_ui.open()
		incoming_ui.set_autoupdate(TRUE)

/obj/structure/dummy
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/datum/weakref/parent

/obj/structure/dummy/Initialize(mapload, new_parent)
	. = ..()
	parent = WEAKREF(new_parent)

/obj/structure/dummy_visible
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	var/datum/weakref/parent

/obj/structure/dummy_visible/Initialize(mapload, obj/new_parent, new_icon_state)
	. = ..()
	name = new_parent.name
	desc = new_parent.desc
	icon = new_parent.icon
	icon_state = new_icon_state
	parent = WEAKREF(new_parent)

/obj/structure/dummy_visible/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.item_interaction(user, tool, modifiers) || NONE // TODO - is none needed?

/obj/structure/dummy_visible/item_interaction_secondary(mob/living/user, obj/item/tool, list/modifiers)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.item_interaction_secondary(user, tool, modifiers) || NONE

/obj/structure/dummy_visible/attackby(obj/item/attacking_item, mob/user, list/modifiers)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.attackby(attacking_item, user, modifiers) || NONE

/obj/structure/dummy_visible/attackby_secondary(obj/item/weapon, mob/user, list/modifiers)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.attackby_secondary(weapon, user, modifiers) || NONE

/obj/structure/dummy_visible/ui_interact(mob/user, datum/tgui/incoming_ui)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	var/ui = multi_parent?.ui
	if(!ui)
		return
	incoming_ui = SStgui.try_update_ui(user, src, incoming_ui)
	if(!incoming_ui)
		incoming_ui = new(user, src, ui, name)
		incoming_ui.open()
		incoming_ui.set_autoupdate(TRUE)

/obj/structure/dummy_visible/ui_act(action, params)
	if(..())
		return
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	multi_parent?.ui_act_base(action, params)

/obj/structure/dummy_visible/ui_data(mob/user)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.ui_data() // TODO - "|| list()" here

/obj/structure/dummy_visible/ui_static_data(mob/user)
	var/obj/machinery/multitile/multi_parent = parent.resolve()
	return multi_parent?.ui_static_data()

#undef TEMPLATE_PART_DUMMY
