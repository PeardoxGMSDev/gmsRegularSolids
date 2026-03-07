/// @function create_tetrahedron
/// @description Create a regular tetrahedron with UV coordinates and CCW winding.
///              F3 (label 1) is the flat base, sitting at maximum +Y (GM down axis).
///              Apex (label 4) points toward -Y (up).
/// @param {real} radius Circumradius (center to vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels

function create_tetrahedron(radius) {
    // Flat-base orientation for GameMaker (+Y = down).
    //
    // For a regular tetrahedron with circumradius R:
    //   inradius        = R / 3
    //   base y          = +R / 3          (flat face sits at max +Y)
    //   apex y          = -R              (points up, toward -Y)
    //   base XZ radius  = R * 2*sqrt(2)/3 (circumradius of base triangle in XZ)
    //
    // s = R / sqrt(3) is kept as the cube-corner scale used everywhere else.
    var s     = radius / sqrt(3);
    var yBase =  radius / 3;
    var yApex = -radius;
    var rXZ   =  radius * 2 * sqrt(2) / 3;

    // Base triangle wound CCW when viewed from below (+Y looking up).
    // Apex at the top (-Y).
    var vertices = [
        [ rXZ,        yBase,  0             ], // V0 – base
        [-rXZ / 2,    yBase,  rXZ * sqrt(3) / 2], // V1 – base
        [-rXZ / 2,    yBase, -rXZ * sqrt(3) / 2], // V2 – base
        [ 0,          yApex,  0             ], // V3 – apex
    ];

    // Face winding is CCW when viewed from outside (normals point outward).
    // Face label = excluded vertex index + 1  →  antipodal pairs sum to 5.
    var triangles = [
        [3, 2, 1], // F0 – opposite V0, label 1  (top-left lateral)
        [3, 0, 2], // F1 – opposite V1, label 2  (top-right lateral)
        [3, 1, 0], // F2 – opposite V2, label 3  (back lateral)
        [0, 1, 2], // F3 – opposite V3, label 4  (flat base, +Y)
    ];

    var face_labels = [
        1,  // F0 – V0 excluded  (0+1)
        2,  // F1 – V1 excluded  (1+1)
        3,  // F2 – V2 excluded  (2+1)
        4,  // F3 – V3 excluded  (3+1) – flat base
    ];

    // Equilateral triangle UVs within a unit cell (small margin).
    var tri_uvs = [
        [0.500, 0.050], // apex of triangle
        [0.930, 0.900], // bottom-right
        [0.070, 0.900], // bottom-left
    ];

    var faces        = [];
    var face_normals = [];
    var face_uvs     = [];

    // 2 columns × 2 rows atlas layout
    for (var i = 0; i < 4; i++) {
        var tri    = triangles[i];
        var col    = i mod 2;
        var row    = floor(i / 2);
        var cell_u = col * 0.5;
        var cell_v = row * 0.5;
        var cell_w = 0.5;
        var cell_h = 0.5;

        // Normal: average vertex positions then normalise (all equidistant).
        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 3; k++) {
            var v = vertices[tri[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx * cx + cy * cy + cz * cz);
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

/// @function create_tetrahedron_texture
/// @description Create a texture atlas with one triangle per face in a 2×2 grid.
///              Each cell is labelled with its die face number (1–4).
/// @param {real} size Texture size (power of 2, e.g. 256, 512)
/// @returns {Asset.GMSprite} Generated sprite

function create_tetrahedron_texture(size = 256) {
    // Must match face_labels in create_tetrahedron().
    var face_labels = [4, 3, 2, 1];

    var face_colors = [
        make_colour_rgb(220,  60,  60), // F0  red
        make_colour_rgb( 60, 180,  60), // F1  green
        make_colour_rgb( 60,  60, 220), // F2  blue
        make_colour_rgb(220, 200,  40), // F3  yellow
    ];

    // Must match tri_uvs in create_tetrahedron().
    var tri_uvs = [
        [0.500, 0.050],
        [0.930, 0.900],
        [0.070, 0.900],
    ];

    var cell_w = size * 0.5;
    var cell_h = size * 0.5;

    var surf = surface_create(size, size);
    surface_set_target(surf);
    draw_clear(c_black);

    for (var i = 0; i < 4; i++) {
        var col = i mod 2;
        var row = floor(i / 2);
        var ox  = col * cell_w;
        var oy  = row * cell_h;

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
    for (var i = 0; i <= 2; i++) {
        draw_line(i * cell_w, 0, i * cell_w, size);
        draw_line(0, i * cell_h, size, i * cell_h);
    }

    // Reset defaults
    surface_reset_target();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_left);

    var spr = sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
    
    if(!file_exists("c:\\temp\\d4.png")) {
        sprite_save(spr, 0, "c:\\temp\\d4.png");
    }

    return spr;
}



/// @function create_tetrahedron_vertex_buffer
/// @description Create a vertex buffer for the tetrahedron with UVs
/// @param {real} radius Circumradius
/// @returns {Id.VertexBuffer} Vertex buffer containing the tetrahedron

function create_tetrahedron_vertex_buffer(radius) {
    var tetra = create_tetrahedron(radius);

    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();

    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);

    for (var i = 0; i < array_length(tetra.faces); i++) {
        var face    = tetra.faces[i];
        var normal  = tetra.normals[i];
        var face_uv = tetra.uvs[i];

        for (var j = 0; j < 3; j++) {
            var v  = tetra.vertices[face[j]];
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

/// @function draw_tetrahedron
/// @description Draw tetrahedron using vertex buffer
/// @param {Id.VertexBuffer} vbuff Vertex buffer containing tetrahedron
/// @param {Id.Texture} texture Texture to apply

function draw_tetrahedron(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}