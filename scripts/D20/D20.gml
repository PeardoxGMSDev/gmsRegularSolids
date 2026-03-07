/// @function create_icosahedron
/// @description Create a regular icosahedron with UV coordinates and CCW winding
/// @param {real} radius Circumradius (centre to vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels

function create_icosahedron(radius) {
    var phi = (1 + sqrt(5)) / 2;
    // Raw vertex circumradius = sqrt(1 + phi^2); scale so result = radius
    var s = radius / sqrt(1 + phi * phi);

    // 12 vertices — three mutually perpendicular golden rectangles
    var vertices = [
        [ 0,        s,    phi*s], // V0
        [ 0,       -s,    phi*s], // V1
        [ 0,        s,   -phi*s], // V2
        [ 0,       -s,   -phi*s], // V3
        [ s,    phi*s,       0 ], // V4
        [-s,    phi*s,       0 ], // V5
        [ s,   -phi*s,       0 ], // V6
        [-s,   -phi*s,       0 ], // V7
        [ phi*s,    0,       s ], // V8
        [-phi*s,    0,       s ], // V9
        [ phi*s,    0,      -s ], // V10
        [-phi*s,    0,      -s ], // V11
    ];

    // 20 triangular faces (CCW winding viewed from outside)
    // Antipodal pairs (opposite faces): sum of indices
    //   F0↔F18, F1↔F17, F2↔F16, F3↔F15, F4↔F19
    //   F5↔F10, F6↔F11, F7↔F12, F8↔F13, F9↔F14
    var triangles = [
        [ 0,  8,  4], // F0
        [ 0,  4,  5], // F1
        [ 0,  5,  9], // F2
        [ 0,  9,  1], // F3
        [ 0,  1,  8], // F4
        [ 1,  6,  8], // F5
        [ 8,  6, 10], // F6
        [ 4,  8, 10], // F7
        [ 4, 10,  2], // F8
        [ 5,  4,  2], // F9
        [ 5,  2, 11], // F10
        [ 9,  5, 11], // F11
        [ 9, 11,  7], // F12
        [ 1,  9,  7], // F13
        [ 1,  7,  6], // F14
        [ 3,  2, 10], // F15
        [ 3, 10,  6], // F16
        [ 3,  6,  7], // F17
        [ 3,  7, 11], // F18
        [ 3, 11,  2], // F19
    ];

    // Die labels 1–20: each antipodal pair sums to 21
    //   F0( 1)↔F18(20)  F1( 2)↔F17(19)  F2( 3)↔F16(18)
    //   F3( 4)↔F15(17)  F4( 5)↔F19(16)  F5( 6)↔F10(15)
    //   F6( 7)↔F11(14)  F7( 8)↔F12(13)  F8( 9)↔F13(12)
    //   F9(10)↔F14(11)
    var face_labels = [
         1,  2,  3,  4,  5,  // F0–F4   top cap
         6,  7,  8,  9, 10,  // F5–F9   upper middle
        15, 14, 13, 12, 11,  // F10–F14 lower middle
        17, 18, 19, 20, 16,  // F15–F19 bottom cap
    ];

    // UV positions for triangle vertices inside a normalised cell
    // Apex top-centre, base bottom-left / bottom-right (with 5 % inset)
    var tri_uvs = [
        [0.50, 0.05], // vertex 0: apex
        [0.95, 0.95], // vertex 1: bottom-right
        [0.05, 0.95], // vertex 2: bottom-left
    ];

    var faces        = [];
    var face_normals = [];
    var face_uvs     = [];

    for (var i = 0; i < 20; i++) {
        var tri    = triangles[i];
        var col    = i mod 5;
        var row    = floor(i / 5);
        var cell_u = col * 0.2;
        var cell_v = row * 0.25;
        var cell_w = 0.2;
        var cell_h = 0.25;

        // Face normal = normalised centroid direction
        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 3; k++) {
            var v = vertices[tri[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx*cx + cy*cy + cz*cz);
        var nx = cx / len;
        var ny = cy / len;
        var nz = cz / len;

        array_push(faces, [tri[0], tri[1], tri[2]]);
        array_push(face_normals, [nx, ny, nz]);
        array_push(face_uvs, [
            [cell_u + tri_uvs[0][0] * cell_w,
             cell_v + tri_uvs[0][1] * cell_h],
            [cell_u + tri_uvs[1][0] * cell_w,
             cell_v + tri_uvs[1][1] * cell_h],
            [cell_u + tri_uvs[2][0] * cell_w,
             cell_v + tri_uvs[2][1] * cell_h],
        ]);
    }

    return {
        vertices    : vertices,
        faces       : faces,
        normals     : face_normals,
        uvs         : face_uvs,
        face_labels : face_labels,
    };
}


/// @function create_icosahedron_texture
/// @description Texture atlas: 20 triangles in a 5-column × 4-row grid.
///              Each cell is labelled with its die face number (1–20).
/// @param {real} size Texture size (power of 2, e.g. 256, 512)
/// @returns {Asset.GMSprite} Generated sprite

function create_icosahedron_texture(size = 256) {
    // Die labels matching the face order from create_icosahedron()
    var face_labels = [
         1,  2,  3,  4,  5,
         6,  7,  8,  9, 10,
        15, 14, 13, 12, 11,
        17, 18, 19, 20, 16,
    ];

    var face_colors = [
        make_colour_rgb(220,  60,  60), // F0   red
        make_colour_rgb( 60, 180,  60), // F1   green
        make_colour_rgb( 60,  60, 220), // F2   blue
        make_colour_rgb(220, 200,  40), // F3   yellow
        make_colour_rgb(180,  60, 180), // F4   purple
        make_colour_rgb(220, 140,  40), // F5   orange
        make_colour_rgb( 40, 200, 200), // F6   cyan
        make_colour_rgb(140, 220,  40), // F7   lime
        make_colour_rgb(200,  80, 120), // F8   pink
        make_colour_rgb( 40, 100, 200), // F9   cornflower
        make_colour_rgb(160,  80,  40), // F10  brown
        make_colour_rgb(100, 160,  80), // F11  sage
        make_colour_rgb(220, 120, 200), // F12  rose
        make_colour_rgb( 80, 200, 160), // F13  seafoam
        make_colour_rgb(200, 180, 100), // F14  tan
        make_colour_rgb(120,  80, 220), // F15  violet
        make_colour_rgb( 60, 160, 220), // F16  sky
        make_colour_rgb(220,  80,  40), // F17  vermilion
        make_colour_rgb(160, 220, 200), // F18  mint
        make_colour_rgb(180, 140,  60), // F19  gold
    ];

    // Triangle vertex positions inside a normalised cell (matches tri_uvs above)
    var tri_uvs = [
        [0.50, 0.05], // apex
        [0.95, 0.95], // bottom-right
        [0.05, 0.95], // bottom-left
    ];

    var cell_w = size * 0.2;
    var cell_h = size * 0.25;

    var surf = surface_create(size, size);
    surface_set_target(surf);
    draw_clear(c_black);

    for (var i = 0; i < 20; i++) {
        var col = i mod 5;
        var row = floor(i / 5);
        var ox  = col * cell_w;
        var oy  = row * cell_h;

        // Filled triangle
        draw_set_color(face_colors[i]);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(ox + tri_uvs[0][0] * cell_w, oy + tri_uvs[0][1] * cell_h);
        draw_vertex(ox + tri_uvs[1][0] * cell_w, oy + tri_uvs[1][1] * cell_h);
        draw_vertex(ox + tri_uvs[2][0] * cell_w, oy + tri_uvs[2][1] * cell_h);
        draw_primitive_end();

        // Die face label (centroid ≈ (0.5, 0.65) in normalised cell)
        draw_set_color(c_white);
        draw_set_font(-1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(
            ox + 0.50 * cell_w,
            oy + 0.60 * cell_h,
            string(face_labels[i])
        );
    }

    // Grid lines
    draw_set_color(c_dkgrey);
    for (var i = 0; i <= 5; i++) {
        draw_line(i * cell_w, 0, i * cell_w, size);
    }
    for (var i = 0; i <= 4; i++) {
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
    
    if(!file_exists("c:\\temp\\d20.png")) {
        sprite_save(spr, 0, "c:\\temp\\d20.png");
    }

    return spr;;
}


/// @function create_icosahedron_vertex_buffer
/// @description Create a vertex buffer for the icosahedron with UVs
/// @param {real} radius Circumradius
/// @returns {Id.VertexBuffer}

function create_icosahedron_vertex_buffer(radius) {
    var ico = create_icosahedron(radius);

    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();

    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);

    for (var i = 0; i < array_length(ico.faces); i++) {
        var face    = ico.faces[i];
        var normal  = ico.normals[i];
        var face_uv = ico.uvs[i];

        for (var j = 0; j < 3; j++) {
            var v  = ico.vertices[face[j]];
            var uv = face_uv[j];

            vertex_position_3d(vbuff, v[0],     v[1],     v[2]);
            vertex_normal     (vbuff, normal[0], normal[1], normal[2]);
            vertex_texcoord   (vbuff, uv[0],     uv[1]);
            vertex_colour     (vbuff, c_white, 1);
        }
    }

    vertex_end(vbuff);
    vertex_freeze(vbuff);

    return vbuff;
}


/// @function draw_icosahedron
/// @description Draw the icosahedron using its vertex buffer
/// @param {Id.VertexBuffer} vbuff
/// @param {Asset.GMSprite}  texture

function draw_icosahedron(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}