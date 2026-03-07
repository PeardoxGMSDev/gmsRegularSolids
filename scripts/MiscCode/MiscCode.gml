function string_format_blank(v , t, d, b = false) {
    if(b && (v == 0)) {
        return string_repeat(" ", t + d + 1);
    } else { 
        return string_format(v, t, d);
    }
}
function draw_string_matrix4(x, y, t, m, b = false) {
    if(!is_array(m) || (array_length(m) != 16)) {
        return "Not an array(16)";
    }
    draw_text(x, y, t);
    draw_text(x, y + 20, "x : { " +
        string_format_blank(m[ 0], 5, 8, b) + ", " +
        string_format_blank(m[ 4], 5, 8, b) + ", " +
        string_format_blank(m[ 8], 5, 8, b) + ", " +
        string_format_blank(m[12], 5, 8, b) + "}");
    draw_text(x, y + 40, "y : { " +
        string_format_blank(m[ 1], 5, 8, b) + ", " +
        string_format_blank(m[ 5], 5, 8, b) + ", " +
        string_format_blank(m[ 9], 5, 8, b) + ", " +
        string_format_blank(m[13], 5, 8, b) + "}");
    draw_text(x, y + 60, "z : { " +
        string_format_blank(m[ 2], 5, 8, b) + ", " +
        string_format_blank(m[ 6], 5, 8, b) + ", " +
        string_format_blank(m[10], 5, 8, b) + ", " +
        string_format_blank(m[14], 5, 8, b) + "}");
    draw_text(x, y + 80, "w : { " +
        string_format_blank(m[ 3], 5, 8, b) + ", " +
        string_format_blank(m[ 7], 5, 8, b) + ", " +
        string_format_blank(m[11], 5, 8, b) + ", " +
        string_format_blank(m[15], 5, 8, b) + "}");
    
}

function matrix4_subtract(m1, m2) {
    if(!is_array(m1) || !is_array(m2)) {
        return false;
    }
    if(array_length(m1) != array_length(m2)) {
        return false;
    }
    var res = array_create(array_length(m1));
    for(var i=0, c = array_length(m1); i<c; i++) {
        res[i] = m2[i] - m1[i];
    }
    
    return res;
}

function string_bool(v) {
    if(!is_numeric(v) && !is_bool(v)) {
        return "N/A : " + typeof(v);
    }
    if(v) {
        return "True";
    } else {
        return "False";
    }
}

function view_info(port = 0, znear = 1, zfar = 32000) constructor {
    self.width = 0;
    self.height = 0;
    self.left = 0;
    self.top = 0;
    self.right = 0;
    self.bottom = 0;
    self.znear = 0;
    self.zfar = 0;
    self.depth = 0;

    self.update(port, znear, zfar);
    
    static update = function(port = 0, znear = 1, zfar = 32000) {
        if(view_enabled && view_visible[port]) {
            self.width = view_get_wport(port);
            self.height = view_get_hport(port);
            self.left = view_get_xport(port);
            self.top = view_get_yport(port);
            self.right = self.left + self.width;
            self.bottom = self.top + self.height;
            self.znear = 0;
            self.zfar = zfar;
            self.depth = self.zfar / 2;
        } else {
            if((self.width != 0) && (self.width != window_get_width())) {
                surface_resize(application_surface, window_get_width(), window_get_height());
            }
            self.width = window_get_width();
            self.height = window_get_height();
            self.left = 0;// -self.width / 2;
            self.top = 0;//-self.height / 2;
            self.right = self.left + self.width;
            self.bottom = self.top + self.height;
            self.znear = znear;
            self.zfar = zfar;
            self.depth = self.zfar / 2;
        }
    }
        
    static get_center_x = function() {
        return self.left + (self.width / 2);
    }
    
    static get_center_y = function() {
        return self.top + (self.height / 2);
    }
    
    static get_center_z = function() {
        return (self.depth / 2);
    }
    
    static get_width = function() {
        return self.width;        
    }
    
    static get_height = function() {
        return self.height;
    }

    static get_left = function() {
        return self.left;
    }

    static get_top = function() {
        return self.top;
    }

    static get_right = function() {
        return self.right;
    }

    static get_bottom = function() {
        return self.bottom;
    }

    static get_znear = function() {
        return self.znear;
    }
    
    static get_zfar = function() {
        return self.zfar;
    }

}

/// @func cavalier_matrix_build(angle_deg, width, height, znear, zfar)
/// @desc Builds a cavalier oblique projection matrix.
/// @param {real} angle_deg   Receding axis angle in degrees (typically 45)
/// @param {real} width       View width
/// @param {real} height      View height
/// @param {real} znear       Near clip plane
/// @param {real} zfar        Far clip plane
/// @return {array<real>}     Row-major 4x4 matrix
function cavalier_matrix_build(angle_deg, left, right, bottom, top, znear, zfar) {
    var a  = degtorad(angle_deg);
    var ca = cos(a);
    var sa = sin(a);

    var sx = 2  / (right - left);
    var sy = -2 / (top   - bottom);
    var sz = 1  / (zfar  - znear);

    var tx = -(right + left)   / (right - left);
    var ty =  (top   + bottom) / (top   - bottom); // sign flipped to match negated sy
    var tz = -znear            / (zfar  - znear);

    return [
        sx,       0,        0,   0,
        0,        sy,       0,   0,
        sx * ca,  sy * sa,  sz,  0,
        tx,       ty,       tz,  1,
    ];
}

/// @func cavalier_view_build(ex, ey, ez, tx, ty, tz, ux, uy, uz)
/// @desc Builds a look-at view matrix suitable for cavalier projection.
/// @param {real} ex  Eye X
/// @param {real} ey  Eye Y
/// @param {real} ez  Eye Z
/// @param {real} tx  Target X
/// @param {real} ty  Target Y
/// @param {real} tz  Target Z
/// @param {real} ux  World up X (typically 0)
/// @param {real} uy  World up Y (typically 1)
/// @param {real} uz  World up Z (typically 0)
/// @return {array<real>} Row-major 4x4 view matrix
function cavalier_view_build(ex, ey, ez, tx, ty, tz, ux, uy, uz) {

    // --- Forward vector (into the screen) ---
    var fx = tx - ex, fy = ty - ey, fz = tz - ez;
    var fl = sqrt(fx*fx + fy*fy + fz*fz);
    fx /= fl; fy /= fl; fz /= fl;

    // --- Right vector: cross(up_hint, forward) ---
    var rx = uy*fz - uz*fy;
    var ry = uz*fx - ux*fz;
    var rz = ux*fy - uy*fx;
    var rl = sqrt(rx*rx + ry*ry + rz*rz);
    rx /= rl; ry /= rl; rz /= rl;

    // --- Corrected up: cross(forward, right) ---
    var cx = fy*rz - fz*ry;
    var cy = fz*rx - fx*rz;
    var cz = fx*ry - fy*rx;
    // (already unit length, no normalize needed)

    // --- Translation terms ---
    var tx_ = -(rx*ex + ry*ey + rz*ez);
    var ty_ = -(cx*ex + cy*ey + cz*ez);
    var tz_ = -(fx*ex + fy*ey + fz*ez);

    // Row-major layout (GameMaker row-vector convention)
    return [
        rx,  cx,  fx,  0,
        ry,  cy,  fy,  0,
        rz,  cz,  fz,  0,
        tx_, ty_, tz_, 1,
    ];
}

/// @func ortho_matrix_build(left, right, bottom, top, znear, zfar)
/// @desc Builds a full orthographic projection matrix.
/// @param {real} left    Left clip plane
/// @param {real} right   Right clip plane
/// @param {real} bottom  Bottom clip plane
/// @param {real} top     Top clip plane
/// @param {real} znear   Near clip plane
/// @param {real} zfar    Far clip plane
/// @return {array<real>} Row-major 4x4 matrix
function ortho_matrix_build(left, right, bottom, top, znear, zfar) {

    var sx = 2  / (right - left);
    var sy = -2 / (top   - bottom); // negated for GameMaker's Y-down convention
    var sz = 1  / (zfar  - znear);

    var tx = 0;
    var ty = 0;
    var tz = -znear / (zfar - znear);

    return [
        sx,  0,   0,   0,
        0,   sy,  0,   0,
        0,   0,   sz,  0,
        tx,  ty,  tz,  1,
    ];
}
