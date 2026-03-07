/// @function _kite_canonical_uvs
/// @description Derive 4 UV positions from the actual projected shape of a
///              kite face, so the UV cell is isometric to the 3D face.
///              Returns [pole, right, wide-tip, left] in [0,1]^2.
/// @param {real} radius
/// @param {real} pole_dist
/// @param {real} margin   Padding inside the cell (default 0.05)
function _kite_canonical_uvs(radius, pole_dist, margin = 0.05) {
    var c36 = cos(degtorad(36));
    var rh  = pole_dist * (1 - c36) / (1 + c36);
    var rr  = sqrt(radius * radius - rh * rh);

    // 3D vertices of face 0 in order: pole, upper[0], lower[0], upper[1]
    var v = [
        [0,                       0,                       pole_dist],
        [rr,                      0,                       rh       ],
        [rr * cos(degtorad(36)),  rr * sin(degtorad(36)), -rh      ],
        [rr * cos(degtorad(72)),  rr * sin(degtorad(72)),  rh      ],
    ];

    // Centroid
    var cx = (v[0][0]+v[1][0]+v[2][0]+v[3][0]) * 0.25;
    var cy = (v[0][1]+v[1][1]+v[2][1]+v[3][1]) * 0.25;
    var cz = (v[0][2]+v[1][2]+v[2][2]+v[3][2]) * 0.25;

    // Face normal (centroid direction, normalised)
    var clen = sqrt(cx*cx + cy*cy + cz*cz);
    var nx = cx/clen, ny = cy/clen, nz = cz/clen;

    // Tangent: centroid → pole, projected onto face plane, normalised.
    // This becomes the UV "up" axis so the pole always sits at the top.
    var dx = v[0][0]-cx, dy = v[0][1]-cy, dz = v[0][2]-cz;
    var d  = dx*nx + dy*ny + dz*nz;
    dx -= d*nx; dy -= d*ny; dz -= d*nz;
    var dl = sqrt(dx*dx + dy*dy + dz*dz);
    var tx = dx/dl, ty = dy/dl, tz = dz/dl;

    // Bitangent: n × tangent  ("right" axis in face plane)
    var bx = ny*tz - nz*ty;
    var by = nz*tx - nx*tz;
    var bz = nx*ty - ny*tx;

    // Project each vertex to 2D local face coordinates
    var pts = array_create(4);
    for (var k = 0; k < 4; k++) {
        var ex = v[k][0]-cx, ey = v[k][1]-cy, ez = v[k][2]-cz;
        pts[k] = [
            ex*tx + ey*ty + ez*tz,   // s: along tangent (toward pole = positive)
            ex*bx + ey*by + ez*bz,   // t: along bitangent (rightward = positive)
        ];
    }

    // Bounding box of projected points
    var min_s = pts[0][0], max_s = pts[0][0];
    var min_t = pts[0][1], max_t = pts[0][1];
    for (var k = 1; k < 4; k++) {
        min_s = min(min_s, pts[k][0]); max_s = max(max_s, pts[k][0]);
        min_t = min(min_t, pts[k][1]); max_t = max(max_t, pts[k][1]);
    }

    // Fit in [margin, 1-margin]^2, preserving aspect ratio
    var span  = max(max_s - min_s, max_t - min_t);
    var scale = (1.0 - 2.0 * margin) / span;
    var mid_s = (min_s + max_s) * 0.5;
    var mid_t = (min_t + max_t) * 0.5;

    // Map to UV: u = bitangent (right), v = -tangent (pole at top = low v)
    var uvs = array_create(4);
    for (var k = 0; k < 4; k++) {
        uvs[k] = [
            0.5 + (pts[k][1] - mid_t) * scale,   // u
            0.5 - (pts[k][0] - mid_s) * scale,   // v  (flip so pole → v=top)
        ];
    }
    return uvs;
}

/// @function create_trapezohedron
/// @description Create a regular pentagonal trapezohedron with UV coords and CCW winding
/// @param {real} radius Circumradius (center to pole vertex)
/// @returns {struct} Struct containing vertices, faces, normals, uvs, face_labels
function create_trapezohedron(radius, pole_dist = radius) {
    var c36 = cos(degtorad(36));
    var rh  = pole_dist * (1 - c36) / (1 + c36);
    var rr  = sqrt(radius * radius - rh * rh);

    var vertices = array_create(12);
    vertices[0]  = [0, 0,  pole_dist];
    vertices[11] = [0, 0, -pole_dist];

    for (var k = 0; k < 5; k++) {
        var a_upper = degtorad(k * 72);
        var a_lower = degtorad(k * 72 + 36);
        vertices[1 + k] = [rr * cos(a_upper), rr * sin(a_upper),  rh];
        vertices[6 + k] = [rr * cos(a_lower), rr * sin(a_lower), -rh];
    }

    var pentagons = array_create(10);
    for (var k = 0; k < 5; k++) {
        var u0 = 1 + k;
        var u1 = 1 + (k + 1) mod 5;
        var l0 = 6 + k;
        var l1 = 6 + (k + 1) mod 5;
        pentagons[k]     = [0,  u0, l0, u1];
        pentagons[k + 5] = [11, l0, u1, l1];
    }

    var face_labels = [1,2,3,4,5,10,9,8,7,6];

    // Geometry-derived UV template: same shape as the actual 3D kite face.
    // Index order matches kite vertex order: [0]=pole [1]=right [2]=wide-tip [3]=left
    var kite_uvs = _kite_canonical_uvs(radius, pole_dist);

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
    
        var cx = 0, cy = 0, cz = 0;
        for (var k = 0; k < 4; k++) {
            var v = vertices[kite[k]];
            cx += v[0]; cy += v[1]; cz += v[2];
        }
        var len = sqrt(cx*cx + cy*cy + cz*cz);
        var nx = cx/len, ny = cy/len, nz = cz/len;
    
        var tris;
        if (i < 5) {
            tris = [[0,1,2],[0,2,3]];
        } else {
            tris = [[0,2,1],[0,3,2]];
        }
    
        // Bottom faces: flip V so the pole vertex maps to the bottom of the
        // cell, matching the texture which was painted the same way for all faces.
        var v_flip = (i >= 5);
    
        for (var t = 0; t < 2; t++) {
            var i0 = tris[t][0];
            var i1 = tris[t][1];
            var i2 = tris[t][2];
    
            array_push(faces, [kite[i0], kite[i1], kite[i2]]);
            array_push(face_normals, [nx, ny, nz]);
    
            var uvs_for_tri = [];
            for (var j = 0; j < 3; j++) {
                var idx  = [i0, i1, i2][j];
                var ku   = kite_uvs[idx][0];
                var kv   = v_flip ? (1.0 - kite_uvs[idx][1]) : kite_uvs[idx][1];
                array_push(uvs_for_tri, [
                    cell_u + ku * cell_w,
                    cell_v + kv * cell_h,
                ]);
            }
            array_push(face_uvs, uvs_for_tri);
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

// radius / pole_dist must match what you pass to create_trapezohedron_vertex_buffer
function create_trapezohedron_texture(size = 256, radius = 1, pole_dist = 1) {
    var face_labels = [1,2,3,4,5,10,9,8,7,6];

    var face_colors = [
        make_colour_rgb(220,  60,  60),
        make_colour_rgb( 60, 180,  60),
        make_colour_rgb( 60,  60, 220),
        make_colour_rgb(220, 200,  40),
        make_colour_rgb(180,  60, 180),
        make_colour_rgb(220, 140,  40),
        make_colour_rgb( 40, 200, 200),
        make_colour_rgb(140, 220,  40),
        make_colour_rgb(200,  80, 120),
        make_colour_rgb( 40, 100, 200),
    ];

    var kite_uvs = _kite_canonical_uvs(radius, pole_dist);

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
    
        // Fill the entire cell — no kite outline needed.
        // Bleeding UVs will sample the same colour, so seams vanish.
        draw_set_color(face_colors[i]);
        draw_rectangle(ox, oy, ox + cell_w, oy + cell_h, false);
    
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
    for (var i = 0; i <= atlas_cols; i++) draw_line(i*cell_w, 0, i*cell_w, size);
    for (var i = 0; i <= atlas_rows; i++) draw_line(0, i*cell_h, size, i*cell_h);

    surface_reset_target();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_left);

    var spr = sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
    
    sprite_save(spr, 0, "c:\\temp\\d10.png");

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