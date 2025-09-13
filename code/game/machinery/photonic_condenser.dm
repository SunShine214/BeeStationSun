/obj/machinery/photonic_condenser
	name = "photonic condenser"
	icon = 'icons/obj/power.dmi'
	icon_state = "condenser"
	desc = "A machine that, when operated and fitted with glass, will create Photonic Prisms by compressing raw electrical charge until it stabilizes as a portable mass power cells."
	use_power = IDLE_POWER_USE
	idle_power_usage = 10 KILOWATT
	active_power_usage = 300 WATT // This is overriden while giving power
	circuit = /obj/item/circuitboard/machine/recharger //to do
	var/open = TRUE
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
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		recharge_coeff = C.rating

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
		if(glass_amount >= 50)
			balloon_alert(user, "Glass Storage Full!")
			playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
			return
		var/obj/item/stack/sheet/glass/glass_sheet = object
		var/amount = max(glass_sheet.get_amount() + glass_amount, 50)
		if(amount)
			to_chat(user, span_notice("You start fixing [src]..."))
			if(!do_after(user, 20, target = src))
				return
			glass_sheet.use(amount)
			glass_amount += amount
			balloon_alert(user, "Glass inserted!")
			playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
			update_appearance()


/obj/machinery/photonic_condenser/attack_hand(mob/living/user, list/modifier)
	if(prism?.percent() == 100)
		open = TRUE
		prism.forceMove(drop_location())
		prism = null
		playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
	else if(prism)
		balloon_alert(user, "MACHINE IN USE!")
		//some spark damage here
		playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
	else
		open = !open
		playsound(src, 'sound/misc/box_deploy.ogg', 50, TRUE)
		if(open)
			balloon_alert(user, "Open")
		else
			balloon_alert(user, "Closed")

	update_appearance()

/obj/machinery/photonic_condenser/process(delta_time)
	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		soundloop.stop()
		return
	if(prism)
		return
	if(glass_amount < 10)
		return
	if(!open)
		if(!prism)
			prism = new /obj/item/stock_parts/cell/photonic_prism/empty(src)
			glass_amount -= 50
		if(prism.charge >= prism.maxcharge)
			soundloop.stop()
			update_use_power(IDLE_POWER_USE)
			update_appearance()
		else
			soundloop.start()
			prism.give(prism.chargerate * recharge_coeff)
			active_power_usage = (prism.chargerate * recharge_coeff / POWER_TRANSFER_LOSS)
			update_use_power(ACTIVE_POWER_USE)
			update_appearance()

///obj/machinery/photonic_condenser/emp_act(severity)	//todo

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
