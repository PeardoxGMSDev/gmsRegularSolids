/// @function create_octahedron
/// @description Create a regular octahedron with UV coordinates and CCW winding.
///              Two square pyramids joined at the equator.
///              Top apex (V4) points toward -Y (up in GM).
///              Bottom apex (V5) points toward +Y (down in GM).
///              Opposite faces sum to 9. Lower face labels are UV-flipped
///              so numbers read right-way up.
/// @param {real} radius Circumradius (centre to vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels

function create_octahedron(radius) {
    // Regular octahedron with circumradius R.
    //   All 6 vertices lie on a sphere of radius R.
    //   Edge length = R * sqrt(2).
    //   4 equatorial vertices at y=0, spaced 90° apart in XZ, each at
    //   distance R from centre.
    //   Top  apex: (0, -R,  0)  →  -Y (up)
    //   Base apex: (0, +R,  0)  →  +Y (down)

    var R = radius;

    var vertices = [
        [ R,  0,  0], // V0 – equatorial, +X
        [ 0,  0,  R], // V1 – equatorial, +Z
        [-R,  0,  0], // V2 – equatorial, -X
        [ 0,  0, -R], // V3 – equatorial, -Z
        [ 0, -R,  0], // V4 – top apex    (-Y / up)
        [ 0,  R,  0], // V5 – bottom apex (+Y / down)
    ];

    // CCW winding from outside.
    // Upper 4 faces contain V4; lower 4 faces contain V5.
    //
    // Opposite-face pairs (normals are antipodal):
    //   F0 (1,-1, 1) ↔ F6 (-1, 1,-1)
    //   F1 (-1,-1, 1) ↔ F7 ( 1, 1,-1)
    //   F2 (-1,-1,-1) ↔ F4 ( 1, 1, 1)
    //   F3 ( 1,-1,-1) ↔ F5 (-1, 1, 1)
    var triangles = [
        [4, 0, 1], // F0 – upper, normal ( 1,-1, 1)
        [4, 1, 2], // F1 – upper, normal (-1,-1, 1)
        [4, 2, 3], // F2 – upper, normal (-1,-1,-1)
        [4, 3, 0], // F3 – upper, normal ( 1,-1,-1)
        [5, 1, 0], // F4 – lower, normal ( 1, 1, 1)  opposite F2
        [5, 2, 1], // F5 – lower, normal (-1, 1, 1)  opposite F3
        [5, 3, 2], // F6 – lower, normal (-1, 1,-1)  opposite F0
        [5, 0, 3], // F7 – lower, normal ( 1, 1,-1)  opposite F1
    ];

    // Opposite pairs sum to 9: (1,8) (2,7) (3,6) (4,5)
    var face_labels = [
        1, // F0
        2, // F1
        3, // F2
        4, // F3
        6, // F4  (opposite F2 = 3,  3+6 = 9)
        5, // F5  (opposite F3 = 4,  4+5 = 9)
        8, // F6  (opposite F0 = 1,  1+8 = 9)
        7, // F7  (opposite F1 = 2,  2+7 = 9)
    ];

    // Upper faces: apex at top of UV cell (triangle points up).
    var upper_tri_uvs = [
        [0.500, 0.050], // apex   (top-centre)
        [0.930, 0.900], // bottom-right
        [0.070, 0.900], // bottom-left
    ];

    // Lower faces: apex at bottom of UV cell (triangle points down).
    // This ensures the number reads right-way up when that face is on top.
    var lower_tri_uvs = [
        [0.500, 0.950], // apex   (bottom-centre)
        [0.070, 0.100], // top-left
        [0.930, 0.100], // top-right
    ];

    var faces        = [];
    var face_normals = [];
    var face_uvs     = [];

    // 4 columns × 2 rows atlas layout.
    // Row 0 = upper faces (F0–F3), Row 1 = lower faces (F4–F7).
    for (var i = 0; i < 8; i++) {
        var tri      = triangles[i];
        var col      = i mod 4;
        var row      = floor(i / 4);
        var cell_u   = col * 0.25;
        var cell_v   = row * 0.5;
        var cell_w   = 0.25;
        var cell_h   = 0.5;
        var tri_uvs  = (i >= 4) ? lower_tri_uvs : upper_tri_uvs;

        // Normal: centroid of face vertices, then normalise.
        // Valid for regular polyhedra (all vertices equidistant from centre).
        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 3; k++) {
            var v = vertices[tri[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx * cx + cy * cy + cz * cz);

        array_push(faces, [tri[0], tri[1], tri[2]]);
        array_push(face_normals, [cx / len, cy / len, cz / len]);
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

/// @function create_octahedron_texture
/// @description Create a texture atlas with one triangle per face in a 4×2 grid.
///              Row 0 = upper faces (apex up), Row 1 = lower faces (apex down).
///              Each cell is labelled with its die face number (1–8).
/// @param {real} size Texture size (power of 2, e.g. 512)
/// @returns {Asset.GMSprite} Generated sprite

function create_octahedron_texture(size = 512) {
    // Must match face_labels in create_octahedron().
    var face_labels = [1, 2, 3, 4, 6, 5, 8, 7];

    var face_colors = [
        make_colour_rgb(220,  60,  60), // F0 red
        make_colour_rgb( 60, 180,  60), // F1 green
        make_colour_rgb( 60,  60, 220), // F2 blue
        make_colour_rgb(220, 200,  40), // F3 yellow
        make_colour_rgb(180,  60, 220), // F4 purple
        make_colour_rgb( 40, 200, 200), // F5 cyan
        make_colour_rgb(220, 130,  40), // F6 orange
        make_colour_rgb(160, 160, 160), // F7 grey
    ];

    // Must match tri_uvs in create_octahedron().
    var upper_tri_uvs = [
        [0.500, 0.050],
        [0.930, 0.900],
        [0.070, 0.900],
    ];
    var lower_tri_uvs = [
        [0.500, 0.950],
        [0.070, 0.100],
        [0.930, 0.100],
    ];

    var cell_w = size * 0.25;
    var cell_h = size * 0.5;

    var surf = surface_create(size, size);
    surface_set_target(surf);
    draw_clear(c_black);

    for (var i = 0; i < 8; i++) {
        var col      = i mod 4;
        var row      = floor(i / 4);
        var ox       = col * cell_w;
        var oy       = row * cell_h;
        var tri_uvs  = (i >= 4) ? lower_tri_uvs : upper_tri_uvs;

        draw_set_color(face_colors[i]);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(ox + tri_uvs[0][0] * cell_w, oy + tri_uvs[0][1] * cell_h);
        draw_vertex(ox + tri_uvs[1][0] * cell_w, oy + tri_uvs[1][1] * cell_h);
        draw_vertex(ox + tri_uvs[2][0] * cell_w, oy + tri_uvs[2][1] * cell_h);
        draw_primitive_end();

        // Die face label at cell centre
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

    // Grid lines
    draw_set_color(c_dkgrey);
    for (var i = 0; i <= 4; i++) {
        draw_line(i * cell_w, 0, i * cell_w, size);
    }
    for (var i = 0; i <= 2; i++) {
        draw_line(0, i * cell_h, size, i * cell_h);
    }

    surface_reset_target();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_left);

    return sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
}

/// @function create_octahedron_vertex_buffer
/// @description Create a vertex buffer for the octahedron with UVs
/// @param {real} radius Circumradius
/// @returns {Id.VertexBuffer} Vertex buffer containing the octahedron

function create_octahedron_vertex_buffer(radius) {
    var octa = create_octahedron(radius);

    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();

    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);

    for (var i = 0; i < array_length(octa.faces); i++) {
        var face    = octa.faces[i];
        var normal  = octa.normals[i];
        var face_uv = octa.uvs[i];

        for (var j = 0; j < 3; j++) {
            var v  = octa.vertices[face[j]];
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

/// @function draw_octahedron
/// @description Draw octahedron using vertex buffer
/// @param {Id.VertexBuffer} vbuff Vertex buffer containing octahedron
/// @param {Id.Texture} texture Texture to apply

function draw_octahedron(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}