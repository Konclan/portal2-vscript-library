IncludeScript("raycast_beam.nut");

function init() {
    raycast_beam_init()
}

function DebugRaycastBeam() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    raycast_beam_trace(start_vec, angles, true);
}