//==============================================
// waygate amulet
//==============================================

/obj/item/clothing/neck/roguetown/psicross/dendor/grove
	name = "greater amulet of nature"
	desc = "An enhanced amulet of nature that allows its wielder to create mystical pathways through the trees. Click any tree while holding this amulet to create druidic waygates to various locations."
	icon_state = "dendor"
	var/channeling = FALSE
	var/last_used = 0
	var/cooldown_time = 300

/obj/item/clothing/neck/roguetown/psicross/dendor/grove/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return

	var/is_valid_target = FALSE
	if(istype(target, /obj/structure/flora/roguetree) || istype(target, /obj/structure/flora/wildtree) || istype(target, /obj/structure/flora/newtree))
		is_valid_target = TRUE
	else
		to_chat(user, "<span class='warning'>You must target a valid tree to create a waygate.</span>")
		return

	if(!is_valid_target)
		return

	if(world.time < last_used + cooldown_time)
		to_chat(user, "<span class='warning'>The amulet's power hasn't yet recovered. Please wait a moment.</span>")
		return

	if(channeling)
		to_chat(user, "<span class='warning'>You are already channeling a waygate!</span>")
		return

	var/list/destinations = list()
	var/list/sorted_names = list()
	for(var/obj/effect/landmark/waygate_destination/L in GLOB.landmarks_list)
		destinations[L.name] = L
		sorted_names += L.name
	sorted_names = sortList(sorted_names)

	var/destination_name = input(user, "Where would you like to create a waygate to?", "Waygate Destination") as null|anything in sorted_names
	if(!destination_name)
		return

	channeling = TRUE
	user.visible_message("<span class='green'>[user] begins channeling energy through their amulet into the [target]...</span>", \
						"<span class='green'>You begin channeling the power of nature to create a waygate to [destination_name]...</span>")

	if(do_after(user, 60, target = target))
		last_used = world.time
		var/obj/effect/portal/waygate/P = new(get_turf(target))
		P.name = "nature's waygate"
		P.desc = "A mystical portal formed through the power of nature, leading to [destination_name]."
		P.icon = 'icons/effects/effects.dmi'
		P.icon_state = "anom"
		P.color = "#45b726"
		P.linked_destination = destinations[destination_name]

		var/old_density = target.density
		target.density = FALSE
		addtimer(CALLBACK(src, PROC_REF(restore_density), target, old_density), 10 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE)

		playsound(target, 'sound/misc/treefall.ogg', 50, TRUE)
		new /obj/effect/temp_visual/grove_portal_transit(get_turf(target))
		user.visible_message("<span class='green'>A mystical portal springs forth from the [target]!</span>", \
							"<span class='green'>You successfully create a waygate to [destination_name]!</span>")
	else
		to_chat(user, "<span class='warning'>Your channeling was interrupted!</span>")

	channeling = FALSE

/obj/item/clothing/neck/roguetown/psicross/dendor/grove/proc/restore_density(atom/target, old_density)
	if(target)
		target.density = old_density

/obj/effect/portal/waygate
	name = "nature's waygate"
	desc = "A mystical portal formed through the power of nature."
	var/obj/effect/landmark/waygate_destination/linked_destination
	var/turf/linked_turf
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/id

/obj/effect/portal/waygate/Initialize()
	. = ..()
	GLOB.portals += src
	QDEL_IN(src, 10 SECONDS)

/obj/effect/portal/waygate/Destroy()
	GLOB.portals -= src
	linked_destination = null
	linked_turf = null
	return ..()

/obj/effect/portal/waygate/Crossed(atom/movable/AM)
	if(!linked_destination && !linked_turf)
		return
	if(AM.anchored || !ismob(AM))
		return
	var/turf/T
	if(linked_destination)
		T = get_turf(linked_destination)
	else
		T = linked_turf
	if(!T)
		return

	AM.forceMove(T)

	if(ismob(AM))
		var/mob/M = AM
		var/atom/movable/pulled = M.pulling
		if(pulled && !pulled.anchored)
			pulled.forceMove(T)

	playsound(src, 'sound/misc/treefall.ogg', 50, TRUE)
	playsound(T, 'sound/misc/treefall.ogg', 50, TRUE)
	new /obj/effect/temp_visual/grove_portal_transit(get_turf(src))
	new /obj/effect/temp_visual/grove_portal_transit(T)
	for(var/mob/M in view(7, T))
		to_chat(M, "<span class='green'>[AM] emerges from a druidic waygate!</span>")


//landmarks to add new waygates

/obj/effect/landmark/waygate_destination
	name = "waygate destination"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT

/obj/effect/landmark/waygate_destination/Initialize(mapload)
	. = ..()
	GLOB.landmarks_list += src

/obj/effect/landmark/waygate_destination/advguild
	name = "Adventurer's Guild"

/obj/effect/landmark/waygate_destination/greattree
	name = "Great Tree"

/obj/effect/landmark/waygate_destination/grove
	name = "Grove"

/obj/effect/landmark/waygate_destination/northgate
	name = "North Gate"

/obj/effect/landmark/waygate_destination/northeastgate
	name = "North-East Gate"

/obj/effect/landmark/waygate_destination/prison
	name = "Prison"

/obj/effect/landmark/waygate_destination/academy
	name = "Ravenloft Academy"

/obj/effect/landmark/waygate_destination/southgate
	name = "South Gate"

/obj/effect/landmark/waygate_destination/inn
	name = "Sylver Dragonne Inn"

//==============================================
// grove shrine
//==============================================
/obj/structure/grove_shrine
	name = "ancient grove shrine"
	desc = "A mystical stone shrine covered in druidic runes and overgrown with sacred vines. It seems to pulse with an ethereal energy. Used for summoning the Hedge Guard in times of emergency."
	icon = 'icons/roguetown/topadd/statue1.dmi'
	icon_state = "baldguy"
	anchored = TRUE
	density = TRUE
	var/cooldown_time = 300
	var/last_used = 0

/obj/structure/grove_shrine/Initialize()
	. = ..()
	add_overlay("vines")

/obj/structure/grove_shrine/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(world.time < last_used + cooldown_time)
		to_chat(user, "<span class='warning'>The shrine's energy hasn't yet recovered. Please wait a moment.</span>")
		return

	var/choice = alert(user, "Do you wish to summon the Hedge Guard?", "Grove Shrine", "Yes", "No")
	if(choice != "Yes")
		return

	last_used = world.time

	var/message = "<span class='boldannounce'>GROVE SHRINE ALERT: [user.name] seeks assistance! (<a href='?src=[REF(src)];alert_response=1;caller=[user.name]'>Create Emergency Waygate</a>)</span>"

	for(var/mob/M in GLOB.player_list)
		if(M.mind && (M.mind.assigned_role in list("Great Druid", "Druid", "Hedge Warden", "Hedge Knight")))
			to_chat(M, message)
			SEND_SOUND(M, sound('sound/misc/treefall.ogg'))

	to_chat(user, "<span class='notice'>You place your hand on the shrine, and feel its ancient magic ripple outward...</span>")
	playsound(src, 'sound/misc/treefall.ogg', 50, TRUE)

	var/obj/effect/temp_visual/shrine_activation/effect = new(get_turf(src))
	effect.color = "#4ca64c"

/obj/structure/grove_shrine/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(!href_list["alert_response"])
		return

	var/mob/living/responder = usr
	if(!responder?.mind || !(responder.mind.assigned_role in list("Great Druid", "Druid", "Hedge Warden", "Hedge Knight")))
		return

	var/caller = href_list["caller"]

	var/obj/structure/flora/target_tree = null
	for(var/obj/structure/flora/T in view(1, responder))
		if(istype(T, /obj/structure/flora/roguetree) || istype(T, /obj/structure/flora/wildtree) || istype(T, /obj/structure/flora/newtree))
			target_tree = T
			break

	if(!target_tree)
		to_chat(responder, "<span class='warning'>You need to be next to a tree to create a waygate!</span>")
		return

	responder.visible_message("<span class='green'>Ancient roots burst from the ground around [target_tree] as [responder] channels nature's call!</span>", \
							"<span class='green'>You begin channeling druidic energy to create a quick waygate to aid [caller]!</span>")

	if(do_after(responder, 100, target = target_tree))
		var/obj/effect/portal/waygate/P = new(get_turf(target_tree))
		P.name = "emergency waygate"
		P.desc = "A hastily formed portal of twisted roots and natural energy."
		P.icon = 'icons/effects/effects.dmi'
		P.icon_state = "anom"
		P.color = "#45b726"
		P.linked_turf = get_turf(src)

		var/old_density = target_tree.density
		target_tree.density = FALSE
		addtimer(CALLBACK(src, PROC_REF(restore_tree_density), target_tree, old_density), 10 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE)

		playsound(target_tree, 'sound/misc/treefall.ogg', 50, TRUE)
		new /obj/effect/temp_visual/grove_portal_transit(get_turf(target_tree))
		responder.visible_message("<span class='green'>A mystical portal springs forth from the twisted roots!</span>", \
								"<span class='green'>You successfully create an emergency waygate!</span>")
	else
		to_chat(responder, "<span class='warning'>Your druidic channeling was interrupted!</span>")

/obj/structure/grove_shrine/proc/restore_tree_density(atom/target, old_density)
	if(target)
		target.density = old_density


//==============================================
// speaking stone
//==============================================

/obj/structure/grove_speaker
	name = "ancient speaking stone"
	desc = "A massive, ancient stone circle adorned with glowing runes and wrapped in ethereal vines. The Great Druid uses this to make important announcements to the town."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "basalt"
	anchored = TRUE
	density = TRUE
	var/cooldown_time = 600
	var/last_used = 0

/obj/structure/grove_speaker/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(!user.mind || user.mind.assigned_role != "Great Druid")
		to_chat(user, "<span class='warning'>The ancient stone only responds to the Great Druid's touch.</span>")
		return

	if(world.time < last_used + cooldown_time)
		to_chat(user, "<span class='warning'>The speaking stone's energy hasn't yet recovered. Please wait a moment.</span>")
		return

	var/message = stripped_input(user, "What message do you wish to convey to the town?", "Druidic Announcement", "")
	if(!message)
		return

	last_used = world.time

	priority_announce("[message]", "Voice of the Great Druid", 'sound/misc/notice.ogg')

	playsound(src, 'sound/misc/notice.ogg', 100, TRUE)
	var/obj/effect/temp_visual/shrine_activation/effect = new(get_turf(src))
	effect.color = "#45b726"

	to_chat(user, "<span class='notice'>Your words echo through the ancient stone, carrying to all corners of the Town...</span>")

/obj/effect/temp_visual/shrine_activation
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-flash"
	duration = 10

/obj/effect/temp_visual/grove_portal_transit
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-flash"
	duration = 15
	color = "#45b726"