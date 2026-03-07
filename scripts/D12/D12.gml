/// @function create_dodecahedron
/// @description Create a regular dodecahedron with UV coordinates and CCW winding
/// @param {real} radius Circumradius (center to vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels

function create_dodecahedron(radius) {
    var phi     = (1 + sqrt(5)) / 2;
    var inv_phi = 1 / phi;
    var s       = radius / sqrt(3);

    var vertices = [
        [ s,       s,       s      ], // V0
        [ s,       s,      -s      ], // V1
        [ s,      -s,       s      ], // V2
        [ s,      -s,      -s      ], // V3
        [-s,       s,       s      ], // V4
        [-s,       s,      -s      ], // V5
        [-s,      -s,       s      ], // V6
        [-s,      -s,      -s      ], // V7
        [ 0,       phi*s,   inv_phi*s], // V8
        [ 0,       phi*s,  -inv_phi*s], // V9
        [ 0,      -phi*s,   inv_phi*s], // V10
        [ 0,      -phi*s,  -inv_phi*s], // V11
        [ inv_phi*s,  0,    phi*s  ], // V12
        [-inv_phi*s,  0,    phi*s  ], // V13
        [ inv_phi*s,  0,   -phi*s  ], // V14
        [-inv_phi*s,  0,   -phi*s  ], // V15
        [ phi*s,   inv_phi*s,  0   ], // V16
        [ phi*s,  -inv_phi*s,  0   ], // V17
        [-phi*s,   inv_phi*s,  0   ], // V18
        [-phi*s,  -inv_phi*s,  0   ], // V19
    ];

    var pentagons = [
        [ 0,  8,  4, 13, 12], // F0
        [ 0, 12,  2, 17, 16], // F1
        [ 0, 16,  1,  9,  8], // F2
        [ 4,  8,  9,  5, 18], // F3
        [ 2, 12, 13,  6, 10], // F4
        [ 1, 16, 17,  3, 14], // F5
        [ 4, 18, 19,  6, 13], // F6
        [ 2, 10, 11,  3, 17], // F7
        [ 1, 14, 15,  5,  9], // F8
        [ 5, 15,  7, 19, 18], // F9
        [ 3, 11,  7, 15, 14], // F10
        [ 6, 19,  7, 11, 10], // F11
    ];

    // Die labels 1–12: each antipodal pair sums to 13
    //   F0( 1)↔F10(12)   F1( 2)↔F9 (11)   F2( 3)↔F11(10)
    //   F3( 4)↔F7 ( 9)   F4( 5)↔F8 ( 8)   F5( 6)↔F6 ( 7)
    var face_labels = [
         1,  // F0  ↔ F10
         2,  // F1  ↔ F9
         3,  // F2  ↔ F11
         4,  // F3  ↔ F7
         5,  // F4  ↔ F8
         6,  // F5  ↔ F6
         7,  // F6  ↔ F5
         9,  // F7  ↔ F3
         8,  // F8  ↔ F4
        11,  // F9  ↔ F1
        12,  // F10 ↔ F0
        10,  // F11 ↔ F2
    ];

    var pent_uvs = [
        [0.5000, 0.0300],
        [0.9470, 0.3550],
        [0.7760, 0.8800],
        [0.2240, 0.8800],
        [0.0530, 0.3550],
    ];

    var faces        = [];
    var face_normals = [];
    var face_uvs     = [];

    for (var i = 0; i < 12; i++) {
        var pent   = pentagons[i];
        var col    = i mod 4;
        var row    = floor(i / 4);
        var cell_u = col * 0.25;
        var cell_v = row / 3.0;
        var cell_w = 0.25;
        var cell_h = 1.0 / 3.0;

        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 5; k++) {
            var v = vertices[pent[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx*cx + cy*cy + cz*cz);
        var nx = cx / len;
        var ny = cy / len;
        var nz = cz / len;

        for (var t = 0; t < 3; t++) {
            var i0 = 0, i1 = t + 1, i2 = t + 2;

            array_push(faces, [pent[i0], pent[i1], pent[i2]]);
            array_push(face_normals, [nx, ny, nz]);
            array_push(face_uvs, [
                [cell_u + pent_uvs[i0][0] * cell_w,
                 cell_v + pent_uvs[i0][1] * cell_h],
                [cell_u + pent_uvs[i1][0] * cell_w,
                 cell_v + pent_uvs[i1][1] * cell_h],
                [cell_u + pent_uvs[i2][0] * cell_w,
                 cell_v + pent_uvs[i2][1] * cell_h],
            ]);
        }
    }

    return {
        vertices    : vertices,
        faces       : faces,
        normals     : face_normals,
        uvs         : face_uvs,
        face_labels : face_labels,
    };
}


/// @function create_dodecahedron_texture
/// @description Create a texture atlas with one pentagon per face in a 4x3 grid.
///              Each cell is labelled with its die face number (1–12).
/// @param {real} size Texture size (power of 2, e.g. 256, 512)
/// @returns {Asset.GMSprite} Generated sprite

function create_dodecahedron_texture(size = 256) {
    // Must match face_labels in create_dodecahedron()
    var face_labels = [
         1,  2,  3,  4,
         5,  6,  7,  9,
         8, 11, 12, 10,
    ];

    var face_colors = [
        make_colour_rgb(220,  60,  60), // F0  red
        make_colour_rgb( 60, 180,  60), // F1  green
        make_colour_rgb( 60,  60, 220), // F2  blue
        make_colour_rgb(220, 200,  40), // F3  yellow
        make_colour_rgb(180,  60, 180), // F4  purple
        make_colour_rgb(220, 140,  40), // F5  orange
        make_colour_rgb( 40, 200, 200), // F6  cyan
        make_colour_rgb(140, 220,  40), // F7  lime
        make_colour_rgb(200,  80, 120), // F8  pink
        make_colour_rgb( 40, 100, 200), // F9  cornflower
        make_colour_rgb(160,  80,  40), // F10 brown
        make_colour_rgb(100, 160,  80), // F11 sage
    ];

    var pent_uvs = [
        [0.5000, 0.0300],
        [0.9470, 0.3550],
        [0.7760, 0.8800],
        [0.2240, 0.8800],
        [0.0530, 0.3550],
    ];

    var cell_w = size * 0.25;
    var cell_h = size / 3.0;

    var surf = surface_create(size, size);
    surface_set_target(surf);
    draw_clear(c_black);

    for (var i = 0; i < 12; i++) {
        var col = i mod 4;
        var row = floor(i / 4);
        var ox  = col * cell_w;
        var oy  = row * cell_h;

        draw_set_color(face_colors[i]);
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(ox + 0.5 * cell_w, oy + 0.5 * cell_h);
        for (var k = 0; k < 5; k++) {
            draw_vertex(
                ox + pent_uvs[k][0] * cell_w,
                oy + pent_uvs[k][1] * cell_h
            );
        }
        draw_vertex(
            ox + pent_uvs[0][0] * cell_w,
            oy + pent_uvs[0][1] * cell_h
        );
        draw_primitive_end();

        // Die face label
        draw_set_color(c_white);
        draw_set_font(-1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(
            ox + 0.5 * cell_w,
            oy + 0.5 * cell_h,
            string(face_labels[i])
        );
    }

    draw_set_color(c_dkgrey);
    for (var i = 0; i <= 4; i++) {
        draw_line(i * cell_w, 0, i * cell_w, size);
    }
    for (var i = 0; i <= 3; i++) {
        draw_line(0, i * cell_h, size, i * cell_h);
    }

    // Reset all defaults
    surface_reset_target();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_left);

    var spr = sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
    
    if(!file_exists("c:\\temp\\d12.png")) {
        sprite_save(spr, 0, "c:\\temp\\d12.png");
    }

    return spr;
}

/// @function create_dodecahedron_vertex_buffer
/// @description Create a vertex buffer for the dodecahedron with UVs
/// @param {real} radius Circumradius
/// @returns {Id.VertexBuffer} Vertex buffer containing the dodecahedron
function create_dodecahedron_vertex_buffer(radius) {
    var dodec = create_dodecahedron(radius);

    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();

    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);

    for (var i = 0; i < array_length(dodec.faces); i++) {
        var face     = dodec.faces[i];
        var normal   = dodec.normals[i];
        var face_uv  = dodec.uvs[i];

        for (var j = 0; j < 3; j++) {
            var v  = dodec.vertices[face[j]];
            var uv = face_uv[j];

            vertex_position_3d(vbuff, v[0],      v[1],      v[2]);
            vertex_normal     (vbuff, normal[0],  normal[1], normal[2]);
            vertex_texcoord   (vbuff, uv[0],      uv[1]);
            vertex_colour     (vbuff, c_white, 1);
        }
    }

    vertex_end(vbuff);
    vertex_freeze(vbuff);

    return vbuff;
}

/// @function draw_dodecahedron
/// @description Draw dodecahedron using vertex buffer
/// @param {Id.VertexBuffer} vbuff Vertex buffer containing dodecahedron
/// @param {Id.Texture} texture Texture to apply

function draw_dodecahedron(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}