//  ________________________________________________________________________
//
//                               raycast_traceline.nut
//
//  Script code for raycast beam method.
//  For use with raycast_traceline* instances.
//  
//  ________________________________________________________________________

IncludeScript("utils.nut");

// Beam ents
RCTL_TRACE <- [];

RCTL_FAR <- 32768;
RCTL_TRACE_LIMIT <- 16;

RCTL_PORTAL_HALF_WIDTH <- 32;
RCTL_PORTAL_HALF_HEIGHT <- 54;
RCTL_PORTAL_PLANE_MARGIN_OUTER <- 1;
RCTL_PORTAL_PLANE_MARGIN_INNER <- -32;

::rctl_triggers <- false;

function raycast_traceline_init() {
    // Initialise map entities.
    // Called 1 second after the map loads.

    // Set up the enveloping func_portal_detector(s),
    // to keep track of the open-ness of portals.
    // Detectors with name "@rctl_portal_detect0" detect ID 0 (SP),
    // ones with name "@rctl_portal_detect1" detect ID 1 (Atlas),
    // "@rctl_portal_detect2" detect ID 2 (P-Body) etc.

    if(!::rctl_triggers) {
        local ent = Entities.FindByName(null, "@rctl_portal_detect*");
        while (ent != null) {

            local id = ent.GetName().slice(19);
            if (id == "") {
                id = "0";
            }
            
            EntFireByHandle(ent, "AddOutput",
                    "OnStartTouchPortal !activator:RunScriptCode:" +
                    "rctl_active <- " + id, 0, null, null);
            EntFireByHandle(ent, "AddOutput",
                    "OnEndTouchPortal !activator:RunScriptCode:" +
                    "rctl_active <- -1", 0, null, null);

            ent = Entities.FindByName(ent, "@rctl_portal_detect*");
        }
    }
    ::rctl_triggers = true
}

function raycast_traceline_trace(start_vec, angle, portals, call, cont) {

    if (!cont) {
        RCTL_TRACE <- [];
    }
    
    local state = raycast_traceline_trace_prepare(start_vec, angle);

    while (state.step < RCTL_TRACE_LIMIT) {
        // printl(state.step)
        ++state.step;
        local endpoint = raycast_traceline_trace_beam(state);
        raycast_traceline_store(state.pos, endpoint, angle)
        state.pos = endpoint;
        if (! raycast_traceline_portal_trace(state)) {
            break;
        }
    }

    callback(call)
}

function raycast_traceline_store(start_vec, end_vec, direction) {
    // DebugDrawLine(start_vec, end_vec, 255, 255, 255, false, 10);
    local index = RCTL_TRACE.len();
    RCTL_TRACE.append({index = index, origin = start_vec, trace_hit = end_vec, dir = direction});
}

//  ------------------------------------------------------------------------
//  [HMW]                          TraceLine
//  ------------------------------------------------------------------------

function raycast_traceline_trace_prepare(origin, dir)
{
    // Create an object for containing the tracing state
    local state = {};
    state.step <- 0;  // Tracing step counter
    state.portals <- raycast_traceline_portal_find_open();
    // printl("Num Portals: " + state.portals.len());
    state.pos <- origin;
    state.dir <- dir;

    return state;
}

function raycast_traceline_trace_beam(state)
{
    // Trace along a beam to see what it hits.
    // Return the position of the endpoint,
    // or null if nothing was hit within the required range.

    local endpoint = state.pos + state.dir * RCTL_FAR;
    local f = TraceLine(state.pos, endpoint, null);
    return state.pos + state.dir * f * RCTL_FAR;
}

//  ------------------------------------------------------------------------
//  [HMW]                          Portals
//  ------------------------------------------------------------------------


function raycast_traceline_portal_trace(state)
{
    // Find out if we are hitting a portal and move state.pos
    // and state.dir to the other side.
    // Return true if a portal was hit, false if not.

    foreach (k, portal_info in state.portals) {
        local portal = portal_info.portal;
        local other_portal = raycast_traceline_portal_find_partner(state.portals, portal);
        if (other_portal == null) {
            // This should never happen, but...
            // printl("other_portal null")
            continue;
        }

        local angles = portal.GetAngles();
        local offset = unrotate(state.pos - portal.GetOrigin(), angles);

        // Test if position is on (or past) the portal surface
        if (fabs(offset.y) > RCTL_PORTAL_HALF_WIDTH ||
            fabs(offset.z) > RCTL_PORTAL_HALF_HEIGHT ||
            offset.x > RCTL_PORTAL_PLANE_MARGIN_OUTER ||
            offset.x < RCTL_PORTAL_PLANE_MARGIN_INNER)
        {
            // printl("not in portal")
            continue;
        }

        local local_dir = unrotate(state.dir, angles);

        // Check if the direction is towards the portal
        if (local_dir.x > 0) {
            // printl("not towards portal")
            continue;
        }

        // Calculate the next beam

        // Cross the portal plane if not already on the other side
        if (offset.x > -1) {
            offset += vector_resize(local_dir, offset.x + 1);
        }
        // Rotate 180dg around the Z axis
        offset.x *= -1;
        offset.y *= -1;
        local_dir.x *= -1;
        local_dir.y *= -1;
        // Add position and angles of other portal
        angles = other_portal.GetAngles();
        state.pos = other_portal.GetOrigin() + rotate(offset, angles);
        state.dir = rotate(local_dir, angles);

        // state.beam_interrupted = false;

        // Test if a cube is inside the portal
        // trace_cubes(state);

        return true;
    }
    // else
    return false;
}

function raycast_traceline_portal_get_id(portal)
{
    // For active portals, return the linkage ID.
    // For inactive portals, return -1.
    // (A portal's rctl_active attribute is set by the
    // @rctl_portal_detect portal detectors in the map.)

    portal.ValidateScriptScope();
    local portal_ss = portal.GetScriptScope();
    if ("rctl_active" in portal_ss) {
        return portal_ss.rctl_active;
    }
    else {
        return -1;
    }
}


function raycast_traceline_portal_find_open()
{
    // Find all active portals in the map and
    // return a list of portal + portal ID pairs.

    local portal_list = [];
    local next_portal = Entities.FindByClassname(null, "prop_portal");
    while (next_portal != null) {
        local portal = next_portal;
        next_portal = Entities.FindByClassname(portal, "prop_portal");

        local id = raycast_traceline_portal_get_id(portal);
        if (id < 0) {
            // Only add active portals, not closed ones.
            continue;
        }
        local p = {};
        p.portal <- portal;
        p.id <- id;
        portal_list.append(p);
    }
    return portal_list;
}


function raycast_traceline_portal_find_partner(portal_list, portal)
{
    // Find the other end of a portal.

    local this_id = raycast_traceline_portal_get_id(portal)
    foreach (k, v in portal_list) {
        if (v.portal != portal && v.id == this_id) {
            return v.portal;
        }
    }
    return null;
}