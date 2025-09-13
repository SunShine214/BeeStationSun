#define MAX_GLASS_COEFF 50

/obj/machinery/photonic_condenser
	name = "photonic condenser"
	icon = 'icons/obj/power.dmi'
	icon_state = "condenser"
	desc = "A machine that, when operated and fitted with glass, will create Photonic Prisms by compressing raw electrical charge until it stabilizes as a portable mass power cell."
	use_power = IDLE_POWER_USE
	idle_power_usage = 10 KILOWATT
	active_power_usage = 300 WATT // This is overriden while giving power
	circuit = /obj/item/circuitboard/machine/photonic_condenser
	var/open = TRUE
	var/max_glass = MAX_GLASS_COEFF
	var/glass_amount
	var/obj/item/stock_parts/cell/photonic_prism/prism
	var/ready = FALSE
	var/recharge_coeff = 1
	var/datum/looping_sound/microwave/soundloop


/obj/machinery/photonic_condenser/Initialize(mapload)
	. = ..()
	soundloop = new(src, FALSE)
	update_appearance()

/obj/machinery/photonic_condenser/Destroy()
	QDEL_NULL(soundloop)
	. = ..()

/obj/machinery/photonic_condenser/RefreshParts()
	for(var/obj/item/stock_parts/capacitor/cap in component_parts)
		recharge_coeff = cap.rating
	for(var/obj/item/stock_parts/matter_bin/bin  in component_parts)
		max_glass = MAX_GLASS_COEFF * bin.rating

/obj/machinery/photonic_condenser/examine(mob/user)
	. = ..()
	if((machine_stat & (BROKEN)))
		return
	. += span_notice("- Current recharge coefficient: <b>[recharge_coeff]</b>.")
	. += "Current glass amount stored: [glass_amount ? glass_amount : 0]"
	if(prism)
		. += "Energy Required: [display_power_persec(prism.chargerate)]"
	if(ready)
		. += "Photonic Prism ready for release."

/obj/machinery/photonic_condenser/attackby(obj/item/object, mob/user, params)
	if(!anchored)
		return
	if(istype(object, /obj/item/stack/sheet/glass))
		if(glass_amount >= max_glass)
			balloon_alert(user, "Glass Storage Full!")
			playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
			return
		var/obj/item/stack/sheet/glass/glass_sheet = object
		var/amount = max(glass_sheet.get_amount() + glass_amount, max_glass)
		if(amount)
			to_chat(user, span_notice("You start adding [src]..."))
			if(!do_after(user, 20, target = src))
				return
			glass_sheet.use(amount)
			glass_amount += amount
			balloon_alert(user, "Glass inserted!")
			playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
			update_appearance()


/obj/machinery/photonic_condenser/AltClick(mob/user)
	. = ..()
	if(open)
		close()
	else
		open()

/obj/machinery/photonic_condenser/process(delta_time)
	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		soundloop.stop()
		return
	if(glass_amount < 10 && !prism)
		return
	if(!open)
		if(!prism)
			fabricate_new_prism()
			return
		if(!soundloop.loop_started)
			soundloop.start()
		if(prism.charge >= prism.maxcharge)
			prism.forceMove(drop_location())
			soundloop.stop()
			prism = null
		else
			prism.give(prism.chargerate * recharge_coeff)
			active_power_usage = (prism.chargerate * recharge_coeff / POWER_TRANSFER_LOSS)
			update_appearance()
	else
		if(soundloop.loop_started)
			soundloop.stop()
///obj/machinery/photonic_condenser/emp_act(severity)	//todo

/obj/machinery/photonic_condenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PhotonicCondenser")
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/machinery/photonic_condenser/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/photonic_condenser/ui_data(mob/user)
	var/list/data = list()
	return data

/obj/machinery/photonic_condenser/ui_static_data(mob/user)
	var/list/data = list()
	return data

/obj/machinery/photonic_condenser/ui_act(action, params)
	. = ..()

/obj/machinery/photonic_condenser/proc/open()
	open = TRUE
	if(soundloop.loop_started)
		soundloop.stop()
	update_use_power(IDLE_POWER_USE)
	playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
	update_appearance()

/obj/machinery/photonic_condenser/proc/close()
	open = FALSE
	update_use_power(ACTIVE_POWER_USE)
	playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
	update_appearance()

/obj/machinery/photonic_condenser/proc/fabricate_new_prism()
	if(glass_amount >= 5)
		prism = new /obj/item/stock_parts/cell/photonic_prism/empty(src)
		glass_amount -= 5
		return
	say("Out of glass!")
	open()

/obj/machinery/photonic_condenser/update_overlays() //todo
	. = ..()
	if(machine_stat & (BROKEN) || !anchored)
		return

	if(!open)
		. += mutable_appearance(icon, "cond-door")
		if(prism && prism.charge < prism.maxcharge)
			. += mutable_appearance(icon, "cond-light")
		else
			. += mutable_appearance(icon, "cond-green")
		return
	if(glass_amount >= 10)
		. += mutable_appearance(icon, "cond-glass")

	if(prism && prism.charge < prism.maxcharge)
		. += mutable_appearance(icon, "cond-light")
	else
		. += mutable_appearance(icon, "cond-green")

/obj/item/stock_parts/cell/photonic_prism
	name = "photonic prism"
	icon_state = "hcell"
	maxcharge = 5 MEGAWATT
	custom_materials = list(/datum/material/glass=1000)
	chargerate_divide = 100
	rating = 4

/obj/item/stock_parts/cell/photonic_prism/empty/Initialize(mapload)
	. = ..()
	charge = 0
	update_appearance()

#undef MAX_GLASS_COEFF
