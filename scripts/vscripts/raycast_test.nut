IncludeScript("raycast_beam.nut");

BEAMS <- [];

function init() {
    raycast_beam_init()
}

function DebugRaycastBeam() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    printl("Angle: " + angles)

    raycast_beam_trace(start_vec, angles, true);
    // We need to wait for the sprite to update..
    EntFireByHandle(self, "CallScriptFunction", "DrawBeamLine", 0.02, null, null);
}

function DrawBeamLine() {
    for (local i = 0; i<self.GetScriptScope().BEAMS.len(); i++) {
        local start_vec = self.GetScriptScope().BEAMS[i].beam.GetOrigin()
        local end_vec = self.GetScriptScope().BEAMS[i].sprite.GetOrigin()
        local target = self.GetScriptScope().BEAMS[i].target.GetOrigin()
        DebugDrawLine(start_vec, end_vec, 255, 255, 255, false, 10)  
        // printl("Origin: " + start_vec)
        // printl("Target: " + target)
        // printl("Sprite: " + end_vec)
    }
}