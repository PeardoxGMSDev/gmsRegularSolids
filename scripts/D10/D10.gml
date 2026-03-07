/// @function create_trapezohedron
/// @description Create a regular pentagonal trapezohedron with UV coords and CCW winding
/// @param {real} radius Circumradius (center to pole vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels

function create_trapezohedron(radius, pole_dist = radius) {
    // pole_dist: z-coordinate of each pole (half the inter-pole distance).
    // Defaults to radius, giving the regular trapezohedron.
    //
    // Coplanarity constraint (derived from det[AB,AC,AD] = 0 on kite verts):
    //   h = pole_dist * (1 - cos36°) / (1 + cos36°)
    //   R = sqrt(radius² - h²)  — ring verts stay on the circumsphere
    //
    // Valid range: pole_dist < radius / ((1 - cos36°) / (1 + cos36°))
    // i.e. h must remain < radius, or R becomes imaginary.
    var c36 = cos(degtorad(36));
    var rh  = pole_dist * (1 - c36) / (1 + c36);
    var rr  = sqrt(radius * radius - rh * rh);

    var vertices = array_create(12);
    vertices[0]  = [0, 0,  pole_dist];   // top pole
    vertices[11] = [0, 0, -pole_dist];   // bottom pole

    for (var k = 0; k < 5; k++) {
        var a_upper = degtorad(k * 72);
        var a_lower = degtorad(k * 72 + 36);
        vertices[1 + k] = [rr * cos(a_upper), rr * sin(a_upper),  rh];
        vertices[6 + k] = [rr * cos(a_lower), rr * sin(a_lower), -rh];
    } 
    
    // Each kite face: 4 vertices listed in CCW order viewed from outside.
    //
    //   Top faces    F0..F4 :  top-pole , upper[i], lower[i] , upper[(i+1)%5]
    //   Bottom faces F5..F9 :  bot-pole , lower[i], upper[(i+1)%5], lower[(i+1)%5]
    //
    // Opposing pairs (sum = 11):
    //   F0(1) ↔ F5(10)   F1(2) ↔ F6(9)   F2(3) ↔ F7(8)
    //   F3(4) ↔ F8(7)    F4(5) ↔ F9(6)
    var pentagons = array_create(10); // "pentagons" reused name — actually kites (4-gons)
    for (var k = 0; k < 5; k++) {
        var u0 = 1 + k;
        var u1 = 1 + (k + 1) mod 5;
        var l0 = 6 + k;
        var l1 = 6 + (k + 1) mod 5;
        pentagons[k]     = [0,  u0, l0, u1]; // top face
        pentagons[k + 5] = [11, l0, u1, l1]; // bottom face
    }

    var face_labels = [
         1,  // F0  ↔ F5 (10)
         2,  // F1  ↔ F6  (9)
         3,  // F2  ↔ F7  (8)
         4,  // F3  ↔ F8  (7)
         5,  // F4  ↔ F9  (6)
        10,  // F5  ↔ F0  (1)
         9,  // F6  ↔ F1  (2)
         8,  // F7  ↔ F2  (3)
         7,  // F8  ↔ F3  (4)
         6,  // F9  ↔ F4  (5)
    ];

    // Kite UV template (diamond orientation, within unit square)
    //   [0] top tip   [1] right   [2] bottom tip   [3] left
    var kite_uvs = [
        [0.50, 0.05],  // apex (pole vertex)
        [0.95, 0.42],  // right equatorial vertex
        [0.50, 0.95],  // wide tip (far equatorial vertex)
        [0.05, 0.42],  // left equatorial vertex
    ];

    // Texture atlas: 5 columns × 2 rows
    var atlas_cols = 5;
    var atlas_rows = 2;
    var cell_w = 1.0 / atlas_cols;
    var cell_h = 1.0 / atlas_rows;

    var faces        = [];
    var face_normals = [];
    var face_uvs     = [];

    for (var i = 0; i < 10; i++) {
        var kite   = pentagons[i];
        var col    = i mod atlas_cols;
        var row    = floor(i / atlas_cols);
        var cell_u = col * cell_w;
        var cell_v = row * cell_h;

        // Face normal: centroid direction
        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 4; k++) {
            var v = vertices[kite[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx*cx + cy*cy + cz*cz);
        var nx = cx / len;
        var ny = cy / len;
        var nz = cz / len;

        // Triangulate kite as two triangles: (0,1,2) and (0,2,3)
        // Triangulate kite as two triangles.
        // Top faces (i < 5): pole is at +z, CCW as (0,1,2) / (0,2,3)
        // Bottom faces (i >= 5): pole is at -z, winding must be reversed
        var tris;
        if (i < 5) {
            tris = [
                [0, 1, 2],
                [0, 2, 3],
            ];
        } else {
            tris = [
                [0, 2, 1],
                [0, 3, 2],
            ];
        }

        for (var t = 0; t < 2; t++) {
            var i0 = tris[t][0];
            var i1 = tris[t][1];
            var i2 = tris[t][2];

            array_push(faces, [kite[i0], kite[i1], kite[i2]]);
            array_push(face_normals, [nx, ny, nz]);
            array_push(face_uvs, [
                [cell_u + kite_uvs[i0][0] * cell_w,
                 cell_v + kite_uvs[i0][1] * cell_h],
                [cell_u + kite_uvs[i1][0] * cell_w,
                 cell_v + kite_uvs[i1][1] * cell_h],
                [cell_u + kite_uvs[i2][0] * cell_w,
                 cell_v + kite_uvs[i2][1] * cell_h],
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


/// @function create_trapezohedron_texture
/// @description Texture atlas with one kite per face in a 5×2 grid.
///              Each cell labelled with its die face number (1–10).
/// @param {real} size Texture size (power of 2, e.g. 256, 512)
/// @returns {Asset.GMSprite} Generated sprite

function create_trapezohedron_texture(size = 256) {
    // Row 0: faces 0-4 (labels 1-5), Row 1: faces 5-9 (labels 10-6)
    var face_labels = [
         1,  2,  3,  4,  5,
        10,  9,  8,  7,  6,
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
    ];

    var kite_uvs = [
        [0.50, 0.05],
        [0.95, 0.42],
        [0.50, 0.95],
        [0.05, 0.42],
    ];

    var atlas_cols = 5;
    var atlas_rows = 2;
    var cell_w = size / atlas_cols;
    var cell_h = size / atlas_rows;

    var surf = surface_create(size, size);
    surface_set_target(surf);
    draw_clear(c_black);

    for (var i = 0; i < 10; i++) {
        var col = i mod atlas_cols;
        var row = floor(i / atlas_cols);
        var ox  = col * cell_w;
        var oy  = row * cell_h;

        // Draw kite as triangle fan from centroid
        draw_set_color(face_colors[i]);
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(ox + 0.5 * cell_w, oy + 0.5 * cell_h);
        for (var k = 0; k < 4; k++) {
            draw_vertex(
                ox + kite_uvs[k][0] * cell_w,
                oy + kite_uvs[k][1] * cell_h
            );
        }
        // Close the fan
        draw_vertex(
            ox + kite_uvs[0][0] * cell_w,
            oy + kite_uvs[0][1] * cell_h
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

    // Grid lines
    draw_set_color(c_dkgrey);
    for (var i = 0; i <= atlas_cols; i++) {
        draw_line(i * cell_w, 0, i * cell_w, size);
    }
    for (var i = 0; i <= atlas_rows; i++) {
        draw_line(0, i * cell_h, size, i * cell_h);
    }

    surface_reset_target();
    draw_set_color(c_white);

    var spr = sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
    
    // sprite_save(spr, 0, "c:\\temp\\d10.png");
    
    return spr;
}


/// @function create_trapezohedron_vertex_buffer
/// @description Create a vertex buffer for the pentagonal trapezohedron with UVs
/// @param {real} radius Circumradius (center to pole)
/// @returns {Id.VertexBuffer} Vertex buffer

function create_trapezohedron_vertex_buffer(radius, pole_dist = radius) {
    var trap = create_trapezohedron(radius, pole_dist);

    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();

    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);

    for (var i = 0; i < array_length(trap.faces); i++) {
        var face    = trap.faces[i];
        var normal  = trap.normals[i];
        var face_uv = trap.uvs[i];

        for (var j = 0; j < 3; j++) {
            var v  = trap.vertices[face[j]];
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


/// @function draw_trapezohedron
/// @description Draw trapezohedron using vertex buffer
/// @param {Id.VertexBuffer} vbuff Vertex buffer
/// @param {Id.Texture} texture Texture to apply

function draw_trapezohedron(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}