if(keyboard_check(vk_escape)) {
    game_end();
}
if(keyboard_check_pressed(vk_space)) {
    /*
    if(view_enabled) {
        view_set_visible(port, false);
        view_enabled = false;
    } else {
        view_set_visible(port, true);
        view_enabled = true;
    }
     */
    dorot = !dorot;
}

if(keyboard_check_pressed(vk_f10)) {
    if(ox == window_get_x()) {
        window_set_position(ox + 2160, oy - 160);
    } else {
        window_set_position(ox, oy);
    }
}

