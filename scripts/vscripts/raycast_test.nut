IncludeScript("raycast_beam.nut");
IncludeScript("raycast_traceline.nut");

function init_rcb() {
    raycast_beam_init()
}

function init_rctl() {
    raycast_traceline_init()
}

function DebugRaycastBeam() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    raycast_beam_trace(start_vec, angles, true, "TestBeamDoStuff()", false);
}

function DebugRaycastTraceLine() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    raycast_traceline_trace(start_vec, angles, true, "TestTraceLineDoStuff()", false);
}

function TestBeamDoStuff() {
    for (local i = 0; i<RCB_TRACE.len(); i++) {
        DebugDrawLine(RCB_TRACE[i].origin, RCB_TRACE[i].trace_hit, 255, 255, 255, false, 3)
    }
}
function TestTraceLineDoStuff() {
    for (local i = 0; i<RCTL_TRACE.len(); i++) {
        DebugDrawLine(RCTL_TRACE[i].origin, RCTL_TRACE[i].trace_hit, 255, 255, 255, false, 3)
    }
}