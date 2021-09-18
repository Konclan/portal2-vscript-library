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

// List of open portals and portal IDs.
::rcb_portal_list <- null;
::rcb_portal_ids <- null;

function raycast_beam_init() {

    local beam = Entities.FindByName(null, "@rcb_beam");
    local target = Entities.FindByName(null, "@rcb_target");
    local sprite = find_thing("env_sprite", target.GetOrigin());

    sprite.__KeyValueFromString("targetname", "@rcb_sprite");

    BEAM = {beam = beam, target = target, sprite = sprite, extent = -1, trace_hit = Vector(0, 0, 0)};

    // Set up the enveloping func_portal_detector(s)
    // to keep track of the open-ness of portals.
    // Detectors with name "@sendtor_portal_detect0" detect ID 0 (SP),
    // ones with name "@sendtor_portal_detect1" detect ID 1 (Atlas),
    // "@sendtor_portal_detect2" detect ID 2 (P-Body) etc.
    local ent = Entities.FindByName(null, "@rcb_portal_detect*");
    while(ent != null) {

        local id = ent.GetName().slice(18);
        // printl("Ent: " + ent.GetName());
        // printl("Id: " + id)
        if(id == "") { id = "0"; }

        EntFireByHandle(ent, "AddOutput", 
            "OnStartTouchPortal !activator:RunScriptCode:" + "rcb_active <- " + id, 
            0, null, null);
        EntFireByHandle(ent, "AddOutput", 
            "OnEndTouchPortal !activator:RunScriptCode:"+ "rcb_active <- -1", 
            0, null, null);
        EntFireByHandle(ent, "AddOutput", "OnStartTouchPortal " 
        + self.GetName() + ":RunScriptCode:"+ "portal_updated", 
        0, null, null);
        EntFireByHandle(ent, "AddOutput", "OnEndTouchPortal " 
        + self.GetName() + ":RunScriptCode:" + "portal_updated", 
        0, null, null);

        ent = Entities.FindByName(ent, "@rcb_portal_detect*");
    }
}

function raycast_beam_trace(start_vec, angle, portals) {
    raycast_beam_position_emitter(start_vec, angle);
    schedule_call("raycast_beam_continue("+portals+")");
}

function raycast_beam_continue(portals) {
    BEAM.trace_hit = BEAM.sprite.GetOrigin();
    // DebugDrawLine(BEAM.beam.GetOrigin(), BEAM.trace_hit, 255, 255, 255, false, 10)
    printl(portals)
    if (portals) {
        schedule_call("trace_portals()");
    }
}

function raycast_beam_position_emitter(origin, angle) {
    local end_vec = origin + rotate(Vector(FAR, 0, 0), angle)
    BEAM.beam.SetOrigin(origin);
    BEAM.target.SetOrigin(end_vec);
}

//  ------------------------------------------------------------------------
//  [HMW]                          Portals
//  ------------------------------------------------------------------------

function portal_updated() {
    ::rcb_portal_list <- null
}

function portal_extent(portal_in, portal_out)
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

function get_portal_id(portal)
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

function find_open_portals()
{
    // Find all active portals in the map and fill portal_list and portal_ids.

    ::rcb_portal_list <- [];
    ::rcb_portal_ids <- [];

    local portal = Entities.FindByClassname(null, "prop_portal");
    while(portal != null) {
        local id = get_portal_id(portal);
        if(id >= 0) {
            // Only add active portals, not closed ones.
            ::rcb_portal_list.append(portal);
            ::rcb_portal_ids.append(id);
        }
        printl("Portal: " + portal.GetClassname() + "[" + id + "]")
        portal = Entities.FindByClassname(portal, "prop_portal");
    }
}


function find_portal_partner(portal)
{
    // Find the other end of a portal.

    local this_id = get_portal_id(portal)
    foreach(k, v in ::rcb_portal_list) {
        if(v != portal && ::rcb_portal_ids[k] == this_id) {
            return v;
        }
    }
    return null;
}

function trace_portals()
{
    // Check if the tracing beam hits a portal.
    BEAM.trace_hit = BEAM.sprite.GetOrigin();

    printl("Tracing from: " + BEAM.beam.GetOrigin() + "to" + BEAM.trace_hit);
    DebugDrawLine(BEAM.beam.GetOrigin(), BEAM.trace_hit, 255, 255, 255, false, 10);
    
    if(::rcb_portal_list == null) {
        find_open_portals();
    }

    foreach(k, v in ::rcb_portal_list) {
        printl("Tracing Portals")
        local angles = v.GetAngles();
        local offset = unrotate(BEAM.trace_hit - v.GetOrigin(), angles);
        if(fabs(offset.y) < 32 && fabs(offset.z) < 54 &&
                offset.x < 1 && offset.x > -12) {

            // Position is close to (or past) portal surface.
            // Find other portal end and check incoming direction.

            local current_dir = vector_resize(BEAM.trace_hit - self.GetOrigin(), 1);
            local local_dir = unrotate(current_dir, angles);
            local other = find_portal_partner(v);
            if(other != null && local_dir.x < 0) {
                // Calculate the next beam.
                portal_extent(v, other);
                schedule_call("trace_portals()");
                return;
            }
        }
    }
}