IncludeScript("raycast_beam.nut");

function init() {
    raycast_beam_init()
}

function DebugRaycastBeam() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    raycast_beam_trace_new(start_vec, angles, true, "DoStuff()");
}

function DoStuff() {
    for (local i = 0; i<TRACE.len(); i++) {
        DebugDrawLine(TRACE[i].origin, TRACE[i].trace_hit, 255, 255, 255, false, 3)
    }
}