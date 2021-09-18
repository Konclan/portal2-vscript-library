//  ________________________________________________________________________
//
//                               raycast_beam.nut
//
//  Script code for raycast beam method.
//  For use with raycast_beam* instances.
//  
//  ________________________________________________________________________

IncludeScript("utils.nut");

// Beam ents
BEAM <- {};
TRACE <- [];

FAR <- 32768
LIMIT <- 16

// List of open portals and portal IDs.
::rcb_portal_list <- null;
::rcb_portal_ids <- null;
::rcb_triggers <- false;

// How many beams are in our map
::rcb_beamcount <- 0;

// What function do we run after finishing tracing
callback_function <- "";

function raycast_beam_init() {
    // Set up the enveloping func_portal_detector(s)
    // to keep track of the open-ness of portals.
    // Detectors with name "@sendtor_portal_detect0" detect ID 0 (SP),
    // ones with name "@sendtor_portal_detect1" detect ID 1 (Atlas),
    // "@sendtor_portal_detect2" detect ID 2 (P-Body) etc.
    local ent = Entities.FindByName(null, "@rcb_portal_detect*");
    while(ent != null) {

        local id = ent.GetName().slice(18);
        if(id == "") { id = "0"; }
        // printl("Ent: " + ent.GetName());
        // printl("Id: " + id)

        // printl("triggers: " + ::rcb_triggers)
        if (::rcb_triggers == false) {
            EntFireByHandle(ent, "AddOutput", 
                "OnStartTouchPortal !activator:RunScriptCode:" + "rcb_active <- " + id, 
                0, null, null);
            EntFireByHandle(ent, "AddOutput", 
                "OnEndTouchPortal !activator:RunScriptCode:"+ "rcb_active <- -1", 
                0, null, null);
        }
        EntFireByHandle(ent, "AddOutput", "OnStartTouchPortal " 
        + self.GetName() + ":RunScriptCode:" + "raycast_beam_portal_updated", 
        0, null, null);
        EntFireByHandle(ent, "AddOutput", "OnEndTouchPortal " 
        + self.GetName() + ":RunScriptCode:" + "raycast_beam_portal_updated", 
        0, null, null);

        ent = Entities.FindByName(ent, "@rcb_portal_detect*");
    }
    ::rcb_triggers = true
}

function raycast_beam_init_beams() {

    // Find our maker ent and set position variables
    local maker = Entities.FindByName(null, "@rcb_maker");
    local beam_pos = maker.GetOrigin() + (maker.GetLeftVector() * -16);
    local target_pos = maker.GetOrigin() + (maker.GetLeftVector() * -32);

    // printl("maker_pos: " + maker.GetOrigin())
    // printl("beam_pos: " + beam_pos)
    // printl("target_pos: " + target_pos)

    // Would love to just spawn in the ents in the script
    // but env_laser destroys itself without keyvalues sadly.
    maker.SpawnEntity();

    local beam = find_thing("env_laser", beam_pos);
    local target = find_thing("info_target", target_pos);
    local sprite = find_thing("env_sprite", target_pos);

    // Debug code, ignore
    // if (beam) { printl( "Beam: " + beam.GetName()); } else { printl( "No Beam :(" ); }
    // if (target) { printl( "Target: " + target.GetName()); } else { printl( "No Target :(" ); }
    // if (sprite) { printl( "Sprite: " + sprite.GetName()); } else { printl( "No Sprite :(" ); }
    
    // printl("Maker Pos: " + maker.GetOrigin());
    // printl("Beam Pos: " + beam_pos);

    // Rename our ents
    beam.__KeyValueFromString("targetname", beam.GetName() + ::rcb_beamcount);
    target.__KeyValueFromString("targetname", target.GetName() + ::rcb_beamcount);
    sprite.__KeyValueFromString("targetname", target.GetName() + "_sprite" + ::rcb_beamcount);

    beam.__KeyValueFromString("LaserTarget", target.GetName());

    // Move our ents out of the way
    beam.SetOrigin(beam.GetOrigin() + beam.GetUpVector() * -16);
    target.SetOrigin(target.GetOrigin() + target.GetUpVector() * -16);
    sprite.SetOrigin(target.GetOrigin() + sprite.GetUpVector() * -16);

    BEAM = {beam = beam, target = target, sprite = sprite, extent = -1, trace_hit = Vector(0, 0, 0)};

    ::rcb_beamcount++
}

function raycast_beam_trace_new(start_vec, angle, portals, callback) {
    callback_function = callback;

    if (BEAM.len() == 0) {
        raycast_beam_init_beams()
    }

    BEAM.extent = -1
    TRACE <- []
    raycast_beam_position_emitter(start_vec, angle);
    schedule_call("raycast_beam_step("+portals+")");
}

function raycast_beam_trace_continue(start_vec, angle, portals, callback) {
    raycast_beam_position_emitter(start_vec, angle);
    schedule_call("raycast_beam_step("+portals+")");
}

function raycast_beam_step(portals) {
    BEAM.trace_hit = BEAM.sprite.GetOrigin();
    // DebugDrawLine(BEAM.beam.GetOrigin(), BEAM.trace_hit, 255, 255, 255, false, 10)
    raycast_beam_store(BEAM.beam.GetOrigin(), BEAM.trace_hit);
    
    // Do we trace through portals
    if (portals) {
        schedule_call("raycast_beam_portal_trace()");
        return;
    }

    callback(callback_function)
}

function raycast_beam_position_emitter(origin, angle) {
    local end_vec = origin + rotate(Vector(FAR, 0, 0), angle)
    BEAM.beam.SetOrigin(origin);
    BEAM.target.SetOrigin(end_vec);
}

function raycast_beam_store(start_vec, end_vec) {
    // DebugDrawLine(start_vec, end_vec, 255, 255, 255, false, 10);
    TRACE.append({origin = start_vec, trace_hit = end_vec, index = TRACE.len()})
}

//  ------------------------------------------------------------------------
//  [HMW]                          Portals
//  ------------------------------------------------------------------------

function raycast_beam_portal_updated() {
    ::rcb_portal_list <- null
}

function raycast_beam_portal_extent(portal_in, portal_out)
{
    // Extend the beam through a portal.
    local offset_from = portal_in.GetOrigin();
    local offset_to = portal_out.GetOrigin();
    local angles_from = portal_in.GetAngles();
    local angles_to = portal_out.GetAngles();

    local dir = vector_resize(BEAM.target.GetOrigin() -
                              self.GetOrigin(), 2);
    dir = unrotate(dir, angles_from);
    dir.x *= -1;
    dir.y *= -1;
    dir = rotate(dir, angles_to);
    local dir_far = dir * FAR;

    local pos = BEAM.sprite.GetOrigin();
    pos = unrotate(pos - offset_from, angles_from);
    pos.x *= -1;
    pos.y *= -1;
    pos = rotate(pos, angles_to) + offset_to;
    BEAM.beam.SetOrigin(pos + dir);
    BEAM.target.SetOrigin(pos + dir_far);
}

function raycast_beam_portal_get_id(portal)
{
    // For active portals, return the linkage ID.
    // For inactive portals, return -1.
    // (A portal's rcb_active attribute is set by the
    // @rcb_portal_detect portal detectors in the map.)

    portal.ValidateScriptScope();
    local portal_ss = portal.GetScriptScope();
    if("rcb_active" in portal_ss) {
        return portal_ss.rcb_active;
    }
    else {
        return -1;
    }
}

function raycast_beam_portal_find_open()
{
    // Find all active portals in the map and fill portal_list and portal_ids.

    ::rcb_portal_list <- [];
    ::rcb_portal_ids <- [];

    local portal = Entities.FindByClassname(null, "prop_portal");
    // printl(portal.GetOrigin());
    while(portal != null) {
        local id = raycast_beam_portal_get_id(portal);
        if(id >= 0) {
            // Only add active portals, not closed ones.
            ::rcb_portal_list.append(portal);
            ::rcb_portal_ids.append(id);
        }
        // printl("Portal: " + portal.GetClassname() + "[" + id + "]")
        portal = Entities.FindByClassname(portal, "prop_portal");
    }
}


function raycast_beam_portal_find_partner(portal)
{
    // Find the other end of a portal.

    local this_id = raycast_beam_portal_get_id(portal)
    foreach(k, v in ::rcb_portal_list) {
        if(v != portal && ::rcb_portal_ids[k] == this_id) {
            return v;
        }
    }
    return null;
}

function raycast_beam_portal_trace()
{
    if (BEAM.extent < LIMIT) {
        BEAM.extent++
    }
    else {
        return;
    }

    // printl("Extent: " + BEAM.extent)

    // Check if the tracing beam hits a portal.
    BEAM.trace_hit = BEAM.sprite.GetOrigin();

    // printl("Tracing from: " + BEAM.beam.GetOrigin() + "to" + BEAM.trace_hit);
    // if (BEAM.extent > 0 ) {DebugDrawLine(BEAM.beam.GetOrigin(), BEAM.trace_hit, 255, 255, 255, false, 10);}
    if (BEAM.extent > 0 ) {
        raycast_beam_store(BEAM.beam.GetOrigin(), BEAM.trace_hit);
    }
    
    if(::rcb_portal_list == null) {
        raycast_beam_portal_find_open();
    }

    foreach(k, v in ::rcb_portal_list) {
        // printl("Tracing Portals")
        local angles = v.GetAngles();
        local offset = unrotate(BEAM.trace_hit - v.GetOrigin(), angles);
        if(fabs(offset.y) < 32 && fabs(offset.z) < 54 &&
                offset.x < 1 && offset.x > -12) {

            // Position is close to (or past) portal surface.
            // Find other portal end and check incoming direction.

            local current_dir = vector_resize(BEAM.trace_hit - self.GetOrigin(), 1);
            local local_dir = unrotate(current_dir, angles);
            local other = raycast_beam_portal_find_partner(v);
            if(other != null && local_dir.x < 0) {
                // Calculate the next beam.
                raycast_beam_portal_extent(v, other);
                schedule_call("raycast_beam_portal_trace()");
                return;
            }
        }
    }

    callback(callback_function)
}