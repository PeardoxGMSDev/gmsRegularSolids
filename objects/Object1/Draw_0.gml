draw_self();

if(!is_undefined(global.spr) && sprite_exists(global.spr)) {
    draw_sprite(global.spr, 0, 64, 64);
    if(!file_exists("c:\\temp\\surf.png")) {
        sprite_save(global.spr, 0, "c:\\temp\\surf.png");
    }
}

if(dorot) {
    if(rotX > 0) {
        rotX--;    
    } else {
        rotY++;
        if(rotY == 360) {
            rotY = 0;
            rotX = 360;
        }
    }
}

gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
var scale = 1;

if(active[0]) {
    var transform1 = matrix_build(window_get_width() / 2, window_get_height() / 2 + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform1);
    draw_cube(obj1, tex1);
}

if(active[1]) {
    var transform2 = matrix_build(window_get_width() / 2, window_get_height() / 2 - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform2);
    draw_dodecahedron(obj2, tex2);
}

if(active[2]) {
    var transform3 = matrix_build(window_get_width() / 2 - 384, window_get_height() / 2 - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform3);
    draw_icosahedron(obj3, tex3);
}

if(active[3]) {
    var transform4 = matrix_build(window_get_width() / 2 + 384, window_get_height() / 2 - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform4);
    draw_trapezohedron(obj4, tex4);
}

if(active[4]) {
    var transform5 = matrix_build(window_get_width() / 2 + 384, window_get_height() / 2 + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform5);
    draw_tetrahedron(obj5, tex5);
}

if(active[5]) {
    var transform6 = matrix_build(window_get_width() / 2 - 384, window_get_height() / 2 + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform6);
    draw_octahedron(obj6, tex6);
}


var identity = matrix_build_identity();
matrix_set(matrix_world, identity);

// shader_reset();
gpu_set_zwriteenable(false);
gpu_set_ztestenable(false);

