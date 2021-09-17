IncludeScript("raycast_beam.nut");

BEAMS <- [];

function init() {
    raycast_beam_init()
}

function DebugRaycastBeam() {
    local start_vec = EntityGroup[0].GetOrigin()
    local angles = EntityGroup[0].GetAngles()

    printl("Angle: " + angles)

    raycast_beam_trace(start_vec, angles, false);
    // We need to wait for the sprite to update..
    EntFireByHandle(self, "CallScriptFunction", "DrawBeamLine", 0.01, null, null);
}

function DrawBeamLine() {
    local start_vec = EntityGroup[0].GetOrigin()
    local end_vec = self.GetScriptScope().BEAMS[0].sprite.GetOrigin()
    local target = self.GetScriptScope().BEAMS[0].target.GetOrigin()
    DebugDrawLine(start_vec, end_vec, 255, 255, 255, false, 3)  
    // printl("Origin: " + start_vec)
    // printl("Target: " + target)
    // printl("Sprite: " + end_vec)
}