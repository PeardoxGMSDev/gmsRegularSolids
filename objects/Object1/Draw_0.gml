draw_self();

draw_sprite(Sprite1, 1, vi.get_center_x(), vi.get_center_y());

if(dorot) {
    if(rotZ < 360) {
        rotZ++;
    } else if(rotX < 360) {
        rotX++;    
    } else {
        rotY++;
        if(rotY == 360) {
            rotY = 0;
            rotX = 0;
            rotZ = 0;
        }
    }
}

gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
var scale = 1;

if(active[0]) {
    var transform1 = matrix_build(vi.get_center_x(), vi.get_center_y() + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform1);
    //draw_cube(obj1, tex1);
    obj1.draw();
}

if(active[1]) {
    var transform2 = matrix_build(vi.get_center_x(), vi.get_center_y() - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform2);
    // draw_dodecahedron(obj2, tex2);
    obj2.setTranslation(vi.get_center_x(), vi.get_center_y() - 256);
    obj2.setRotation(rotX, rotY, rotZ);
    obj2.draw();
}

if(active[2]) {
    var transform3 = matrix_build(vi.get_center_x() - 384, vi.get_center_y() - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform3);
    obj3.draw();
}

if(active[3]) {
    /*
    var transform4 = matrix_build(vi.get_center_x() + 384, vi.get_center_y() - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform4);
    // draw_trapezohedron(obj4, tex4);
    */
    var transform4 = matrix_build(vi.get_center_x() + 384, vi.get_center_y() - 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform4);
    obj4.setRotation(rotX, rotY, rotZ);
    obj4.draw();
}

if(active[4]) {
    
    var transform5 = matrix_build(vi.get_center_x() + 384, vi.get_center_y() + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform5);
    //draw_tetrahedron(obj5, tex5);
    obj5.draw();
}

if(active[5]) {
    var transform6 = matrix_build(vi.get_center_x() - 384, vi.get_center_y() + 256, 0, rotX, rotY, rotZ, scale,scale,scale);
    matrix_set(matrix_world, transform6);
    // draw_octahedron(obj6, tex6);
    obj6.draw();
}


var identity = matrix_build_identity();
matrix_set(matrix_world, identity);

// shader_reset();
gpu_set_zwriteenable(false);
gpu_set_ztestenable(false);

