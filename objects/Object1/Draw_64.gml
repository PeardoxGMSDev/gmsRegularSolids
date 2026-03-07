var v, p, w, cv, cp, vc, dc, angle, up;

vi.update();

vc = view_get_camera(port);
dc = camera_get_default();
angle = 0;

display_set_gui_size(vi.get_width(), vi.get_height());

if(view_enabled) {
    v = camera_get_view_mat(vc);
    p = camera_get_proj_mat(vc);
} else {
    v = matrix_get(matrix_view);
    p = matrix_get(matrix_projection);
}

up = {x: dsin(angle), y: dcos(angle), z: 0 };

cv = matrix_build_lookat(vi.get_center_x(), vi.get_center_y(), -vi.get_zfar() / 2,
                         vi.get_center_x(), vi.get_center_y(), 0,
                         up.x, up.y, up.z);
                         

cv = cavalier_view_build(vi.get_center_x(), vi.get_center_y(), -vi.get_zfar() / 2,
                         vi.get_center_x(), vi.get_center_y(), 0,
                         up.x, up.y, up.z);

cp = matrix_build_projection_ortho(vi.get_width(), vi.get_height(), vi.get_znear(), vi.get_zfar());
cp = ortho_matrix_build(vi.get_left(), vi.get_right(), vi.get_bottom(), vi.get_top(), vi.get_znear(), vi.get_zfar()); 
cp = cavalier_matrix_build(45, vi.get_left(), vi.get_right(), vi.get_bottom(), vi.get_top(), vi.get_znear(), vi.get_zfar()); 

// cp = matrix_build_projection_ortho(vi.get_width(), vi.get_height(), 0, vi.get_zfar());
// cp = matrix_build_projection_perspective(vi.get_width(), vi.get_height(), vi.get_znear(), vi.get_zfar());
// cp = matrix_build_projection_perspective_fov(-60, vi.get_width() / vi.get_height(), vi.get_znear(), vi.get_zfar());

if(view_enabled) {
//   camera_set_view_mat(vc, cv);
//   camera_set_proj_mat(vc, cp);
}

draw_text(20, 20, "View : " + string(vi));
draw_text(20, 40, "ViewsEnabled : " + string_bool(view_enabled) + ", Default Camera : " + string(dc) + ", Camera for VP #" + string(port) + " : " + string(vc) + ", Up : " + string(up)); 
draw_text(20, 60, "FPS : " + string(fps) + ", rotX : " + string_format(rotX, 3, 0) + ", rotY : " + string_format(rotY, 3, 0) + ", rotZ : " + string_format(rotZ, 3, 0) + ", centerX : " + string_format(vi.get_center_x(), 3, 0) + ", centerY : " + string_format(vi.get_center_y(), 3, 0)); 

draw_string_matrix4(20, 100, "Actual View", v);
draw_string_matrix4(window_get_width() / 2, 100, "Actual Proj", p);

draw_string_matrix4(20, 220, "Constructed View : " + string(vi.get_center_x()) + ", " + string(vi.get_center_y()) + ", " + string(vi.get_center_z()), cv);
draw_string_matrix4(window_get_width() / 2, 220, "Constructed Proj : " + string(vi.get_width()) + ", " + string(-vi.get_height()), cp);

draw_string_matrix4(20, 440, "Diff View", matrix4_subtract(v, cv), true);
draw_string_matrix4(window_get_width() / 2, 440, "Diff Proj", matrix4_subtract(p, cp), true);
