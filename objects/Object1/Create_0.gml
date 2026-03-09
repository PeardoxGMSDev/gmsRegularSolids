port = 0;
vi = new view_info(port);
global.spr = undefined;

active = [1, 1, 1, 1, 1, 1];
var spr;  

if(active[0]) {
    /*
    obj1 = create_cube_vertex_buffer(100);
    spr = create_simple_cube_texture();
    tex1 = sprite_get_texture(spr, 0);
    */
    obj1 = new d6();
    obj1.create(100);
    obj1.createDefaultTexture();
    obj1.setTranslation(vi.get_center_x(), vi.get_center_y() + 256);
    show_debug_message(obj1.bounds());
}


if(active[1]) {
    /*
    obj2 = create_dodecahedron_vertex_buffer(100);
    spr = create_dodecahedron_texture();
    tex2 = sprite_get_texture(spr, 0);
    */
    obj2 = new d12();
    obj2.create(100);
    obj2.createDefaultTexture();
    obj2.setTranslation(vi.get_center_x(), vi.get_center_y() - 256);
    show_debug_message(obj2.bounds());
}

if(active[2]) {
    /*
    obj3 = create_icosahedron_vertex_buffer(100);
    spr = create_icosahedron_texture();
    tex3 = sprite_get_texture(spr, 0);
    */
    obj3 = new d20();
    obj3.create(100);
    obj3.createDefaultTexture();
    obj3.setTranslation(vi.get_center_x(), vi.get_center_y() + 256);
    show_debug_message(obj3.bounds());}

if(active[3]) {
    /*
    obj4 = create_trapezohedron_vertex_buffer(85, 100);
    spr = create_trapezohedron_texture();
    tex4 = sprite_get_texture(spr, 0);
    */
    obj4 = obj2.addChild( new d10() );
    obj4.create(85, 100);
    obj4.createDefaultTexture();
    obj4.setTranslation(384, -256);
    show_debug_message(obj4.bounds());
}

if(active[4]) {
    /*
    obj5 = create_tetrahedron_vertex_buffer(100);
    spr = create_tetrahedron_texture();
    tex5 = sprite_get_texture(spr, 0);
    */
    obj5 = new d4();
    obj5.create(100);
    obj5.createDefaultTexture();
    show_debug_message(obj5.bounds());
}


if(active[5]) {
    /*
    obj6 = create_octahedron_vertex_buffer(100);
    spr = create_octahedron_texture();
    tex6 = sprite_get_texture(spr, 0);
    */
    obj6 = new d8();
    obj6.create(100);
    obj6.createDefaultTexture();
    show_debug_message(obj6.bounds());
}



dorot = true;
rotX = 240;
rotY = 0;
rotZ = 0;
/*
rotX = 0;
rotY = 45;
rotZ = 45;
*/

gpu_set_cullmode(cull_counterclockwise);

// show_debug_overlay(true);