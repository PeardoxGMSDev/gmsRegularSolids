port = 0;
global.spr = undefined;

active = [1, 1, 1, 1, 1, 1];
var spr;  

if(active[0]) {
    obj1 = create_cube_vertex_buffer(100);
    spr = create_simple_cube_texture();
    tex1 = sprite_get_texture(spr, 0);
}

if(active[1]) {
    obj2 = create_dodecahedron_vertex_buffer(100);
    spr = create_dodecahedron_texture();
    tex2 = sprite_get_texture(spr, 0);
}

if(active[2]) {
    obj3 = create_icosahedron_vertex_buffer(100);
    spr = create_icosahedron_texture();
    tex3 = sprite_get_texture(spr, 0);
}

if(active[3]) {
    obj4 = create_trapezohedron_vertex_buffer(85, 100);
    spr = create_trapezohedron_texture();
    tex4 = sprite_get_texture(spr, 0);
}

if(active[4]) {
    obj5 = create_tetrahedron_vertex_buffer(100);
    spr = create_tetrahedron_texture();
    tex5 = sprite_get_texture(spr, 0);
}

if(active[5]) {
    obj6 = create_octahedron_vertex_buffer(100);
    spr = create_octahedron_texture();
    tex6 = sprite_get_texture(spr, 0);
}



dorot = true;
rotX = 0;
rotY = 0;
rotZ = 0;
/*
rotX = -45;
rotY = 45;
rotZ =  0;
*/

gpu_set_cullmode(cull_counterclockwise);

// show_debug_overlay(true);