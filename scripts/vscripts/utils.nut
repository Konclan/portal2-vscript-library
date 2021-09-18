//  ------------------------------------------------------------------------
//                                Utilities
//  ------------------------------------------------------------------------

function find_thing(class_name, position)
{
    // HMW:
    // Find an entity with the given class name at the given point.
    // (This is a separate function purely for space saving and clarity.)
    return Entities.FindByClassnameNearest(class_name, position, 1);
}

beat_time <- 0.01;

function schedule_call(code)
{
    // Set an event to start the next operation after beat_time seconds.
    EntFireByHandle(self, "RunScriptCode", code, beat_time, null, null);
}

function callback(code)
{
    // Callback a script function
    EntFireByHandle(self, "RunScriptCode", code, 0, null, null);
}

//  ------------------------------------------------------------------------
//  [TeamSpen210]                  Math is math
//  ------------------------------------------------------------------------

function min(a, b) {
    return (a < b) ? a : b;
}

function max(a, b) {
    return (a > b) ? a : b;
}

function clamp(val, min_, max_) {
	return (val < min_) ? min_ : (val > max_) ? max_ : val;
}

function lerp(x, in_min, in_max, out_min, out_max) {
	return out_min + (((x - in_min) * (out_max - out_min)) / (in_max - in_min))
}

function lerp_clamp(x, in_min, in_max, out_min, out_max) {
	return clamp(lerp(x, in_min, in_max, out_min, out_max), out_min, out_max);
}

function dist(x1, y1, x2, y2) {
    return sqrt(pow(x1-x2, 2) + pow(y1-y2, 2));
}

function round(x) {
    return floor(x + 0.5);
}

//  ------------------------------------------------------------------------
//  [HMW]                  Angle and vector math
//  ------------------------------------------------------------------------

function vector_length(v)
{
    // Return the length of a vector.
    return sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
}


function vector_resize(v, f)
{
    // Return a vector colinear to v with length f.
    local len = vector_length(v);
    return v * (f / len);
}


function vector_dot(a, b)
{
    // Return the dot product of vectors a and b.
    return a.x*b.x + a.y*b.y + a.z*b.z
}


function make_rot_matrix(angles)
{
    // Return a 3x3 rotation matrix for the given pitch-yaw-roll angles.
    // (letters are swapped to get roll-yaw-pitch)
    //
    // format: / a b c \
    //         | d e f |
    //         \ g h k /


    // Determine sine and cosine of each angle.
    // Angles must be converted to radians for use with these functions.

    local sin_x = sin(-angles.z / 180 * PI);
    local cos_x = cos(-angles.z / 180 * PI);
    local sin_y = sin(-angles.x / 180 * PI);
    local cos_y = cos(-angles.x / 180 * PI);
    local sin_z = sin(-angles.y / 180 * PI);
    local cos_z = cos(-angles.y / 180 * PI);

    return {

        a = cos_y * cos_z,
            b = -sin_x * -sin_y * cos_z + cos_x * sin_z,
                c = cos_x * -sin_y * cos_z + sin_x * sin_z,

        d = cos_y * -sin_z,
            e = -sin_x * -sin_y * -sin_z + cos_x * cos_z,
                f = cos_x * -sin_y * -sin_z + sin_x * cos_z,

        g = sin_y,
            h = -sin_x * cos_y,
                k = cos_x * cos_y,
   }
}


function rotate(point, angles)
{
    // Rotate point about the origin by angles and return the result.

    local mx = make_rot_matrix(angles);
    return Vector(point.x * mx.a + point.y * mx.b + point.z * mx.c,
                  point.x * mx.d + point.y * mx.e + point.z * mx.f,
                  point.x * mx.g + point.y * mx.h + point.z * mx.k);
}


function unrotate(point, angles)
{
    // Rotate point about the origin by angles in the opposite direction
    // and return the result.
    //
    // This is very straightforward, as the inverse of the rotation
    // matrix is the original one with the rows and columns swapped.

    local mx = make_rot_matrix(angles);
    return Vector(point.x * mx.a + point.y * mx.d + point.z * mx.g,
                  point.x * mx.b + point.y * mx.e + point.z * mx.h,
                  point.x * mx.c + point.y * mx.f + point.z * mx.k);
}


function vector_to_angles(v)
{
    // Convert a direction vector to Euler angles.
    // (Roll is always 0.)

    local l = vector_length(v);
    if (l == 0) {
        return Vector(0, 0, 0);
    }
    local lz = sqrt(pow(v.x, 2) + pow(v.y, 2));
    if (lz == 0) {
        if (v.z > 0) { return Vector(-90, 0, 0); }
        else         { return Vector(90, 0, 0); }
    }
    local yaw = asin(fabs(v.y) / lz) / PI * 180;
    if (v.x < 0) { yaw = 180 - yaw; }
    if (v.y < 0) { yaw = -yaw; }
    local pitch = asin(fabs(v.z) / l) / PI * 180;
    if (v.z > 0) { pitch = -pitch; } // Note to self: this is correct
    return Vector(pitch, yaw, 0);
}