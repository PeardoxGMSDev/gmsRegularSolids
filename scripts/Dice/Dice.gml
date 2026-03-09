
function d4() : Model() constructor {

    /// @description Create a tetrahedron whose tight AABB is (-1,-1,-1) to (1,1,1).
    ///              Flat base (F3, label 4) sits at +Y = 1 (GM down).
    ///              Apex (V3, label 4-side) points toward -Y = -1 (GM up).
    ///              Winding is CCW viewed from outside (LH, outward normals via e2×e1).
    static __createShape = function(radius) {

        // Derived from a regular tetrahedron (circumradius R=1, inradius=R/3)
        // centred at its own centroid then per-axis scaled to fill [-1, 1]:
        //   V0..V2 form the equilateral base at y = +1
        //   V3     is the apex              at y = -1
        self.vertices = [
            new pdxVec3( radius,        radius,  0      ),  // V0
            new pdxVec3(-radius,        radius,  radius ),  // V1
            new pdxVec3(-radius,        radius, -radius ),  // V2
            new pdxVec3(-radius / 3,   -radius,  0      ),  // V3 – apex
        ];
    
        // CCW winding viewed from outside; label = excluded vertex index + 1.
        var triangles = [
            [3, 2, 1],  // F0 – opposite V0, label 1
            [3, 0, 2],  // F1 – opposite V1, label 2
            [3, 1, 0],  // F2 – opposite V2, label 3
            [0, 1, 2],  // F3 – opposite V3, label 4 (flat base, +Y)
        ];

        self.labels = [1, 2, 3, 4];

        // Equilateral-triangle UVs within a unit cell.
        var tri_uvs = [
            new pdxUV(0.500, 0.050),  // apex of UV triangle
            new pdxUV(0.930, 0.900),  // bottom-right
            new pdxUV(0.070, 0.900),  // bottom-left
        ];

        for (var i = 0; i < 4; i++) {
            var tri = triangles[i];
            var cu  = (i mod 2)    * 0.5;   // atlas cell origin U
            var cv  = floor(i / 2) * 0.5;   // atlas cell origin V
            var cw  = 0.5;
            var ch  = 0.5;

            // Per-face flat normal: e2 × e1 gives outward direction for LH+CCW.
            var va = self.vertices[tri[0]];
            var vb = self.vertices[tri[1]];
            var vc = self.vertices[tri[2]];

            var e1x = vb.x - va.x;
            var e1y = vb.y - va.y;
            var e1z = vb.z - va.z;
            var e2x = vc.x - va.x;
            var e2y = vc.y - va.y;
            var e2z = vc.z - va.z;

            var nx = e2y * e1z - e2z * e1y;
            var ny = e2z * e1x - e2x * e1z;
            var nz = e2x * e1y - e2y * e1x;
            var nl = sqrt(nx * nx + ny * ny + nz * nz);

            array_push(self.faces,   [tri[0], tri[1], tri[2]]);
            array_push(self.normals, new pdxVec3(nx / nl, ny / nl, nz / nl));
            array_push(self.uvs, [
                new pdxUV(cu + tri_uvs[0].u * cw, cv + tri_uvs[0].v * ch),
                new pdxUV(cu + tri_uvs[1].u * cw, cv + tri_uvs[1].v * ch),
                new pdxUV(cu + tri_uvs[2].u * cw, cv + tri_uvs[2].v * ch),
            ]);
        }
    }

    
    /// @description Create a 2×2 atlas texture; one coloured, labelled triangle per face.
    /// @param {real} size Texture size (power-of-2, e.g. 256)
    static createDefaultTexture = function(size = 256) {
        var face_colors = [
            make_colour_rgb(220,  60,  60),  // F0  red
            make_colour_rgb( 60, 180,  60),  // F1  green
            make_colour_rgb( 60,  60, 220),  // F2  blue
            make_colour_rgb(220,  40, 200),  // F3  cyan
        ];
    
        // Must match tri_uvs in __createShape().
        // [u, v, text_rotation]
        // Rotation chosen so the number reads upright when that corner
        // is the physical apex (top) of the die.
        var tri_uvs = [
            [0.500, 0.050,   0],   // apex  – 0° rotation
            [0.930, 0.900, 240],   // BR    – 240° rotation
            [0.070, 0.900, 120],   // BL    – 120° rotation
        ];
    
        // Centroid of the UV triangle (used for label offset).
        var uv_cx = (tri_uvs[0][0] + tri_uvs[1][0] + tri_uvs[2][0]) / 3;
        var uv_cy = (tri_uvs[0][1] + tri_uvs[1][1] + tri_uvs[2][1]) / 3;
    
        // How far from each corner toward the centroid to place the text.
        var label_t = 0.28;
    
        // For each face, which label (from self.labels) appears at each
        // UV corner position [apex, BR, BL].
        //
        // Derivation: when face F_j is on the bottom, vertex V_j is the
        // highest point.  V_j sits at the following UV position in each
        // visible face:
        //
        //   F0 vertices: [V3, V2, V1]  → V3@pos0, V2@pos1, V1@pos2
        //   F1 vertices: [V3, V0, V2]  → V3@pos0, V0@pos1, V2@pos2
        //   F2 vertices: [V3, V1, V0]  → V3@pos0, V1@pos1, V0@pos2
        //   F3 vertices: [V0, V1, V2]  → V0@pos0, V1@pos1, V2@pos2
        //
        // When F_j is bottom, its excluded vertex V_j is the apex, so
        // its label goes at whichever position V_j occupies:
        //
        //   F0: pos0=label[3]=4, pos1=label[2]=3, pos2=label[1]=2
        //   F1: pos0=label[3]=4, pos1=label[0]=1, pos2=label[2]=3
        //   F2: pos0=label[3]=4, pos1=label[1]=2, pos2=label[0]=1
        //   F3: pos0=label[0]=1, pos1=label[1]=2, pos2=label[2]=3
        var corner_labels = [
            [4, 3, 2],  // F0
            [4, 1, 3],  // F1
            [4, 2, 1],  // F2
            [1, 2, 3],  // F3
        ];
    
        var cell_w = size * 0.5;
        var cell_h = size * 0.5;
    
        var surf = surface_create(size, size);
        surface_set_target(surf);
        draw_clear(c_black);
    
        for (var i = 0; i < 4; i++) {
            var ox = (i mod 2)    * cell_w;
            var oy = floor(i / 2) * cell_h;
    
            // ── Filled triangle ───────────────────────────────────────────
            draw_set_color(face_colors[i]);
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(ox + tri_uvs[0][0] * cell_w, oy + tri_uvs[0][1] * cell_h);
            draw_vertex(ox + tri_uvs[1][0] * cell_w, oy + tri_uvs[1][1] * cell_h);
            draw_vertex(ox + tri_uvs[2][0] * cell_w, oy + tri_uvs[2][1] * cell_h);
            draw_primitive_end();
    
            // ── Three corner labels ───────────────────────────────────────
            draw_set_color(c_black);
            draw_set_font(-1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
    
            for (var k = 0; k < 3; k++) {
                // Interpolate between corner and centroid.
                var lx = ox + (tri_uvs[k][0] + label_t * (uv_cx - tri_uvs[k][0]))
                             * cell_w;
                var ly = oy + (tri_uvs[k][1] + label_t * (uv_cy - tri_uvs[k][1]))
                             * cell_h;
                var rot = tri_uvs[k][2];
    
                draw_text_transformed(
                    lx, ly,
                    string(corner_labels[i][k]),
                    1, 1, rot
                );
            }
        }
    
        // ── Atlas grid lines ─────────────────────────────────────────────
        draw_set_color(c_dkgrey);
        for (var i = 0; i <= 2; i++) {
            draw_line(i * cell_w, 0,    i * cell_w, size);
            draw_line(0,    i * cell_h, size,        i * cell_h);
        }
    
        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_left);
    
        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }    
    
    /// @description Build the vertex buffer. Vertices are unit-scaled; the
    ///              radius parameter is accepted for API compatibility only.
    /// @param {real} radius Unused – shape always fills (-1,-1,-1) to (1,1,1).
    static create = function(radius = 1) {
        self.__createShape(radius);

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vfmt = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vfmt);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face    = self.faces[i];
            var normal  = self.normals[i];   // pdxVec3
            var face_uv = self.uvs[i];       // array of pdxUV

            for (var j = 0; j < 3; j++) {
                var v  = self.vertices[face[j]];  // pdxVec3
                var uv = face_uv[j];              // pdxUV

                vertex_position_3d(self.vertexBuffer, v.x,      v.y,      v.z);
                vertex_normal     (self.vertexBuffer, normal.x,  normal.y, normal.z);
                vertex_texcoord   (self.vertexBuffer, uv.u,      uv.v);
                vertex_colour     (self.vertexBuffer, c_white,   1);
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);
    }
}

function d6() : Model() constructor {

    function __createShape(radius) {
        var r = radius;

        // 8 corner vertices using pdxVec3
        self.vertices = [
            new pdxVec3(-r,  r,  r),  // V0: bottom-left-back
            new pdxVec3( r,  r,  r),  // V1: bottom-right-back
            new pdxVec3( r, -r,  r),  // V2: top-right-back
            new pdxVec3(-r, -r,  r),  // V3: top-left-back
            new pdxVec3(-r,  r, -r),  // V4: bottom-left-front
            new pdxVec3( r,  r, -r),  // V5: bottom-right-front
            new pdxVec3( r, -r, -r),  // V6: top-right-front
            new pdxVec3(-r, -r, -r)   // V7: top-left-front
        ];

        // 2 triangles per face, 12 triangles total (CCW winding)
        self.faces = [
            // Bottom face (Y+)
            [0, 4, 5], [0, 5, 1],
            // Top face (Y-)
            [3, 6, 7], [3, 2, 6],
            // Front face (Z-)
            [4, 6, 5], [4, 7, 6],
            // Back face (Z+)
            [1, 3, 0], [1, 2, 3],
            // Right face (X-)
            [5, 2, 1], [5, 6, 2],
            // Left face (X+)
            [0, 7, 4], [0, 3, 7]
        ];

        self.labels = ["3", "4", "6", "1", "5", "2"];

        // Per-triangle UV sets using pdxUV
        self.uvs = [
            // Bottom face
            [new pdxUV(0.2575, 0.9925), new pdxUV(0.2575, 0.7575), new pdxUV(0.4925, 0.7575)],
            [new pdxUV(0.2575, 0.9925), new pdxUV(0.4925, 0.7575), new pdxUV(0.4925, 0.9925)],
            // Top face
            [new pdxUV(0.2575, 0.0075), new pdxUV(0.4925, 0.2425), new pdxUV(0.2575, 0.2425)],
            [new pdxUV(0.2575, 0.0075), new pdxUV(0.4925, 0.0075), new pdxUV(0.4925, 0.2425)],
            // Front face
            [new pdxUV(0.2575, 0.4925), new pdxUV(0.4925, 0.2575), new pdxUV(0.4925, 0.4925)],
            [new pdxUV(0.2575, 0.4925), new pdxUV(0.2575, 0.2575), new pdxUV(0.4925, 0.2575)],
            // Back face
            [new pdxUV(0.7575, 0.4925), new pdxUV(0.9925, 0.2575), new pdxUV(0.9925, 0.4925)],
            [new pdxUV(0.7575, 0.4925), new pdxUV(0.7575, 0.2575), new pdxUV(0.9925, 0.2575)],
            // Right face
            [new pdxUV(0.5075, 0.4925), new pdxUV(0.7425, 0.2575), new pdxUV(0.7425, 0.4925)],
            [new pdxUV(0.5075, 0.4925), new pdxUV(0.5075, 0.2575), new pdxUV(0.7425, 0.2575)],
            // Left face
            [new pdxUV(0.0075, 0.4925), new pdxUV(0.2425, 0.2575), new pdxUV(0.2425, 0.4925)],
            [new pdxUV(0.0075, 0.4925), new pdxUV(0.0075, 0.2575), new pdxUV(0.2425, 0.2575)]
        ];

        // Per-triangle face normals using pdxVec3
        self.normals = [
            new pdxVec3( 0,  1,  0),  // Bottom tri 1
            new pdxVec3( 0,  1,  0),  // Bottom tri 2
            new pdxVec3( 0, -1,  0),  // Top tri 1
            new pdxVec3( 0, -1,  0),  // Top tri 2
            new pdxVec3( 0,  0, -1),  // Front tri 1
            new pdxVec3( 0,  0, -1),  // Front tri 2
            new pdxVec3( 0,  0,  1),  // Back tri 1
            new pdxVec3( 0,  0,  1),  // Back tri 2
            new pdxVec3(-1,  0,  0),  // Right tri 1
            new pdxVec3(-1,  0,  0),  // Right tri 2
            new pdxVec3( 1,  0,  0),  // Left tri 1
            new pdxVec3( 1,  0,  0)   // Left tri 2
        ];
    }

    static createDefaultTexture = function(size = 256) {
        var surf = surface_create(size, size);
        surface_set_target(surf);

        draw_clear(c_black);

        var quarter       = size * 0.25;
        var half          = size * 0.5;
        var three_quarter = size * 0.75;

        var colors = [c_red, c_green, c_blue, c_yellow, c_purple, c_orange];

        draw_set_color(colors[1]);
        draw_rectangle(quarter, 0, half, quarter, false);

        draw_set_color(colors[5]);
        draw_rectangle(0, quarter, quarter, half, false);

        draw_set_color(colors[2]);
        draw_rectangle(quarter, quarter, half, half, false);

        draw_set_color(colors[4]);
        draw_rectangle(half, quarter, three_quarter, half, false);

        draw_set_color(colors[3]);
        draw_rectangle(three_quarter, quarter, size, half, false);

        draw_set_color(colors[0]);
        draw_rectangle(quarter, three_quarter, half, size, false);

        draw_set_color(c_white);
        for (var i = 0; i <= 4; i++) {
            var pos = i * quarter;
            draw_line(pos, 0, pos, size);
            draw_line(0, pos, size, pos);
        }

        draw_set_font(-1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_black);

        draw_text(quarter + quarter / 2, quarter / 2,                  self.labels[1]);
        draw_text(quarter / 2,           quarter + quarter / 2,        self.labels[5]);
        draw_text(quarter + quarter / 2, quarter + quarter / 2,        self.labels[2]);
        draw_text(half + quarter / 2,    quarter + quarter / 2,        self.labels[4]);
        draw_text(three_quarter + quarter / 2, quarter + quarter / 2,  self.labels[3]);
        draw_text(quarter + quarter / 2, three_quarter + quarter / 2,  self.labels[0]);

        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_left);

        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }

    static create = function(radius) {
        self.__createShape(radius);

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vertex_format = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vertex_format);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face   = self.faces[i];
            var normal = self.normals[i];
            var face_uv = self.uvs[i];

            for (var j = 0; j < 3; j++) {
                var vert = self.vertices[face[j]];
                var uv   = face_uv[j];

                vertex_position_3d(self.vertexBuffer, vert.x,   vert.y,   vert.z);
                vertex_normal(     self.vertexBuffer, normal.x, normal.y, normal.z);
                vertex_texcoord(   self.vertexBuffer, uv.u,     uv.v);
                vertex_colour(     self.vertexBuffer, c_white, 1);
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);
    }
}

function d8() : Model() constructor {

    /// @description Create a regular octahedron whose tight AABB is
    ///              (-radius,-radius,-radius) to (radius,radius,radius).
    ///              Built as two square-base pyramids sharing an equatorial ring.
    ///              Top apex V3 at -Y (GM up), bottom apex V2 at +Y (GM down).
    ///              Winding CCW viewed from outside (LH), normals via e2×e1.
    static __createShape = function(radius) {
        self.vertices = [
            new pdxVec3( radius,  0,       0      ),  // V0 – equator +X
            new pdxVec3(-radius,  0,       0      ),  // V1 – equator -X
            new pdxVec3( 0,       radius,  0      ),  // V2 – bottom apex (+Y)
            new pdxVec3( 0,      -radius,  0      ),  // V3 – top apex    (-Y)
            new pdxVec3( 0,       0,       radius ),  // V4 – equator +Z
            new pdxVec3( 0,       0,      -radius ),  // V5 – equator -Z
        ];
    
        var triangles = [
            [3, 4, 0],  // F0 – upper, label 1
            [3, 1, 4],  // F1 – upper, label 2
            [3, 5, 1],  // F2 – upper, label 3
            [3, 0, 5],  // F3 – upper, label 4
            [2, 0, 4],  // F4 – lower, label 5
            [2, 4, 1],  // F5 – lower, label 6
            [2, 1, 5],  // F6 – lower, label 7
            [2, 5, 0],  // F7 – lower, label 8
        ];
    
     
        self.labels = [1, 2, 3, 4, 5, 6, 7, 8];

        // Atlas layout: 4 columns × 2 rows → cell 0.25 wide, 0.5 tall.
        // Same equilateral triangle UV layout as d4.
        var tri_uvs = [
            new pdxUV(0.500, 0.050),  // apex
            new pdxUV(0.930, 0.900),  // bottom-right
            new pdxUV(0.070, 0.900),  // bottom-left
        ];

        var cell_w = 0.25;
        var cell_h = 0.5;

        for (var i = 0; i < 8; i++) {
            var tri = triangles[i];
            var cu  = (i mod 4) * cell_w;
            var cv  = floor(i / 4) * cell_h;

            var va = self.vertices[tri[0]];
            var vb = self.vertices[tri[1]];
            var vc = self.vertices[tri[2]];

            var e1x = vb.x - va.x;
            var e1y = vb.y - va.y;
            var e1z = vb.z - va.z;
            var e2x = vc.x - va.x;
            var e2y = vc.y - va.y;
            var e2z = vc.z - va.z;

            var nx = e2y * e1z - e2z * e1y;
            var ny = e2z * e1x - e2x * e1z;
            var nz = e2x * e1y - e2y * e1x;
            var nl = sqrt(nx * nx + ny * ny + nz * nz);

            array_push(self.faces,   [tri[0], tri[1], tri[2]]);
            array_push(self.normals, new pdxVec3(nx / nl, ny / nl, nz / nl));
            array_push(self.uvs, [
                new pdxUV(cu + tri_uvs[0].u * cell_w, cv + tri_uvs[0].v * cell_h),
                new pdxUV(cu + tri_uvs[1].u * cell_w, cv + tri_uvs[1].v * cell_h),
                new pdxUV(cu + tri_uvs[2].u * cell_w, cv + tri_uvs[2].v * cell_h),
            ]);
        }
    }

    /// @description Create a 4×2 atlas texture; one coloured, labelled triangle
    ///              per face. Labels 1–8, opposite faces sum to 9.
    /// @param {real} size Texture size (power-of-2, e.g. 512)
    static createDefaultTexture = function(size = 512) {
        var face_colors = [
            make_colour_rgb(220,  60,  60),
            make_colour_rgb( 60, 180,  60),
            make_colour_rgb( 60,  60, 220),
            make_colour_rgb(220, 200,  40),
            make_colour_rgb(180,  60, 220),
            make_colour_rgb( 60, 200, 200),
            make_colour_rgb(220, 130,  40),
            make_colour_rgb(160, 160, 160),
        ];
    
        var tri_uvs = [
            [0.500, 0.050],
            [0.930, 0.900],
            [0.070, 0.900],
        ];
    
        var centroid_u = (tri_uvs[0][0] + tri_uvs[1][0] + tri_uvs[2][0]) / 3;
        var centroid_v = (tri_uvs[0][1] + tri_uvs[1][1] + tri_uvs[2][1]) / 3;
    
        var cell_w = size * 0.25;
        var cell_h = size * 0.5;
        var text_scale = (min(cell_w, cell_h) * 0.25) / string_height("0");
    
        var surf = surface_create(size, size);
        surface_set_target(surf);
        draw_clear(c_black);
    
        for (var i = 0; i < 8; i++) {
            var ox  = (i mod 4)    * cell_w;
            var oy  = floor(i / 4) * cell_h;
            var col = face_colors[i];
    
            draw_set_color(col);
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(ox + tri_uvs[0][0] * cell_w, oy + tri_uvs[0][1] * cell_h);
            draw_vertex(ox + tri_uvs[1][0] * cell_w, oy + tri_uvs[1][1] * cell_h);
            draw_vertex(ox + tri_uvs[2][0] * cell_w, oy + tri_uvs[2][1] * cell_h);
            draw_primitive_end();
    
            draw_set_color(c_black);
            draw_set_font(-1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text_transformed(
                ox + centroid_u * cell_w,
                oy + centroid_v * cell_h,
                string(self.labels[i]),
                text_scale,
                text_scale,
                0
            );
        }
    
        draw_set_color(c_dkgrey);
        for (var i = 0; i <= 4; i++) draw_line(i * cell_w, 0, i * cell_w, size);
        for (var i = 0; i <= 2; i++) draw_line(0, i * cell_h, size, i * cell_h);
    
        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_left);
    
        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }
    
    /// @param {real} radius Shape half-extent; AABB will be (-r,-r,-r) to (r,r,r)
    static create = function(radius = 1) {
        self.__createShape(radius);

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vfmt = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vfmt);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face    = self.faces[i];
            var normal  = self.normals[i];
            var face_uv = self.uvs[i];

            for (var j = 0; j < 3; j++) {
                var v  = self.vertices[face[j]];
                var uv = face_uv[j];

                vertex_position_3d(self.vertexBuffer, v.x,      v.y,      v.z);
                vertex_normal     (self.vertexBuffer, normal.x,  normal.y, normal.z);
                vertex_texcoord   (self.vertexBuffer, uv.u,      uv.v);
                vertex_colour     (self.vertexBuffer, c_white,   1);
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);
    }
}

function d10() : Model() constructor {
    self.radius    = 1;
    self.pole_dist = 1;

    /// @function _kite_canonical_uvs
    /// @description Derive 4 UV positions from the actual projected shape of a
    ///              kite face, so the UV cell is isometric to the 3D face.
    ///              Returns [pole, right, wide-tip, left] in [0,1]^2.
    /// @param {real} margin Padding inside the cell (default 0.05)
    static _kite_canonical_uvs = function(margin = 0.05) {
        var c36 = cos(degtorad(36));
        var rh  = self.pole_dist * (1 - c36) / (1 + c36);
        var rr  = sqrt(self.radius * self.radius - rh * rh);

        // 3D vertices of face 0: pole, upper[0], lower[0], upper[1]
        // Kept as plain local arrays — internal to UV math only.
        var v = [
            [0,                      0,                      self.pole_dist],
            [rr,                     0,                      rh            ],
            [rr*cos(degtorad(36)),   rr*sin(degtorad(36)),  -rh           ],
            [rr*cos(degtorad(72)),   rr*sin(degtorad(72)),   rh           ],
        ];

        var cx = (v[0][0]+v[1][0]+v[2][0]+v[3][0]) * 0.25;
        var cy = (v[0][1]+v[1][1]+v[2][1]+v[3][1]) * 0.25;
        var cz = (v[0][2]+v[1][2]+v[2][2]+v[3][2]) * 0.25;

        var clen = sqrt(cx*cx + cy*cy + cz*cz);
        var nx = cx/clen, ny = cy/clen, nz = cz/clen;

        var dx = v[0][0]-cx, dy = v[0][1]-cy, dz = v[0][2]-cz;
        var d  = dx*nx + dy*ny + dz*nz;
        dx -= d*nx; dy -= d*ny; dz -= d*nz;
        var dl = sqrt(dx*dx + dy*dy + dz*dz);
        var tx = dx/dl, ty = dy/dl, tz = dz/dl;

        var bx = ny*tz - nz*ty;
        var by = nz*tx - nx*tz;
        var bz = nx*ty - ny*tx;

        var pts = array_create(4);
        for (var k = 0; k < 4; k++) {
            var ex = v[k][0]-cx, ey = v[k][1]-cy, ez = v[k][2]-cz;
            pts[k] = [
                ex*tx + ey*ty + ez*tz,
                ex*bx + ey*by + ez*bz,
            ];
        }

        var min_s = pts[0][0], max_s = pts[0][0];
        var min_t = pts[0][1], max_t = pts[0][1];
        for (var k = 1; k < 4; k++) {
            min_s = min(min_s, pts[k][0]); max_s = max(max_s, pts[k][0]);
            min_t = min(min_t, pts[k][1]); max_t = max(max_t, pts[k][1]);
        }

        var span  = max(max_s - min_s, max_t - min_t);
        var scale = (1.0 - 2.0 * margin) / span;
        var mid_s = (min_s + max_s) * 0.5;
        var mid_t = (min_t + max_t) * 0.5;

        var uvs = array_create(4);
        for (var k = 0; k < 4; k++) {
            uvs[k] = [
                0.5 + (pts[k][1] - mid_t) * scale,
                0.5 - (pts[k][0] - mid_s) * scale,
            ];
        }
        return uvs;
    }

    /// @function __createShape
    /// @description Build vertices (pdxVec3), faces, normals (pdxVec3), and
    ///              UVs (pdxUV) for the pentagonal trapezohedron.
    ///              Vertices are scaled to a (-1,-1,-1)→(1,1,1) bounding box
    ///              and Y is negated to match GameMaker's +Y-down orientation.
    static __createShape = function() {
        var c36 = cos(degtorad(36));
        var rh  = self.pole_dist * (1 - c36) / (1 + c36);
        var rr  = sqrt(self.radius * self.radius - rh * rh);

        // ── 1. Place raw vertices ─────────────────────────────────────────
        // Stored as pdxVec3.  Poles first, then upper ring (indices 1-5),
        // then lower ring (indices 6-10), south pole last (index 11).
        self.vertices[0]  = new pdxVec3(0, 0,  self.pole_dist);
        self.vertices[11] = new pdxVec3(0, 0, -self.pole_dist);

        for (var k = 0; k < 5; k++) {
            var a_upper = degtorad(k * 72);
            var a_lower = degtorad(k * 72 + 36);
            self.vertices[1 + k] = new pdxVec3(
                rr * cos(a_upper), rr * sin(a_upper),  rh
            );
            self.vertices[6 + k] = new pdxVec3(
                rr * cos(a_lower), rr * sin(a_lower), -rh
            );
        }

        // ── 2. Flip Y for GameMaker orientation ───────────────────────────────
        // Negating Y corrects the handedness so that a positive rotation angle
        // rotates in the expected direction in GM's +Y-down coordinate system.
        // No normalisation is applied — vertices remain at the scale of
        // self.radius / self.pole_dist as passed to create().
        for (var k = 0; k < 12; k++) {
            self.vertices[k].y = -self.vertices[k].y;
        }

        // ── 3. Build kite index lists ─────────────────────────────────────
        var pentagons = array_create(10);
        for (var k = 0; k < 5; k++) {
            var u0 = 1 + k;
            var u1 = 1 + (k + 1) mod 5;
            var l0 = 6 + k;
            var l1 = 6 + (k + 1) mod 5;
            pentagons[k]     = [0,  u0, l0, u1];   // top kites
            pentagons[k + 5] = [11, l0, u1, l1];   // bottom kites
        }

        self.labels = [1,2,3,4,5,10,9,8,7,6];

        // ── 4. Canonical UV template ──────────────────────────────────────
        var kite_uvs  = self._kite_canonical_uvs();
        var atlas_cols = 5;
        var atlas_rows = 2;
        var cell_w = 1.0 / atlas_cols;
        var cell_h = 1.0 / atlas_rows;

        // ── 5. Triangulate each kite, compute normals, assign UVs ─────────
        for (var i = 0; i < 10; i++) {
            var kite   = pentagons[i];
            var col    = i mod atlas_cols;
            var row    = floor(i / atlas_cols);
            var cell_u = col * cell_w;
            var cell_v = row * cell_h;

            // Face normal: average centroid direction (already unit-sphere-ish
            // after scaling, so normalise explicitly).
            var cx = 0, cy = 0, cz = 0;
            for (var k = 0; k < 4; k++) {
                var vk = self.vertices[kite[k]];
                cx += vk.x; cy += vk.y; cz += vk.z;
            }
            var clen = sqrt(cx*cx + cy*cy + cz*cz);
            var face_normal = new pdxVec3(cx/clen, cy/clen, cz/clen);

            // CCW winding: top kites fan forward; bottom kites fan reversed.
            var tris;
            if (i < 5) {
                tris = [[0,1,2],[0,2,3]];
            } else {
                tris = [[0,2,1],[0,3,2]];
            }

            // Bottom faces have their kite V-flipped so the pole vertex sits
            // at the bottom of the atlas cell, matching the texture paint pass.
            var v_flip = (i >= 5);

            for (var t = 0; t < 2; t++) {
                var i0 = tris[t][0];
                var i1 = tris[t][1];
                var i2 = tris[t][2];

                array_push(self.faces,   [kite[i0], kite[i1], kite[i2]]);
                array_push(self.normals, face_normal);   // pdxVec3

                // Build UV triple as pdxUV instances
                var uvs_for_tri = [];
                var idx_list    = [i0, i1, i2];
                for (var j = 0; j < 3; j++) {
                    var idx = idx_list[j];
                    var ku  = kite_uvs[idx][0];
                    var kv  = v_flip
                            ? (1.0 - kite_uvs[idx][1])
                            : kite_uvs[idx][1];
                    array_push(uvs_for_tri, new pdxUV(
                        cell_u + ku * cell_w,
                        cell_v + kv * cell_h
                    ));
                }
                array_push(self.uvs, uvs_for_tri);
            }
        }
    }

    /// @function createDefaultTexture
    /// @description Texture atlas with one kite per face in a 5×2 grid,
    ///              labelled with die face numbers (1–10).
    /// @param {real} size Texture size (power-of-2, e.g. 256 or 512)
    /// @returns {Asset.GMSprite} Generated sprite handle
    static createDefaultTexture = function(size = 256) {
        self.labels = [1,2,3,4,5,10,9,8,7,6];

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

        var kite_uvs  = _kite_canonical_uvs();
        var atlas_cols = 5;
        var atlas_rows = 2;
        var cell_w = size / atlas_cols;
        var cell_h = size / atlas_rows;

        var surf = surface_create(size, size);
        surface_set_target(surf);
        draw_clear(c_black);

        for (var i = 0; i < 10; i++) {
            var col    = i mod atlas_cols;
            var row    = floor(i / atlas_cols);
            var ox     = col * cell_w;
            var oy     = row * cell_h;
            var v_flip = (i >= 5);

            draw_set_color(face_colors[i]);
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(ox + 0.5 * cell_w, oy + 0.5 * cell_h);
            for (var k = 0; k < 4; k++) {
                var ku = kite_uvs[k][0];
                var kv = v_flip ? (1.0 - kite_uvs[k][1]) : kite_uvs[k][1];
                draw_vertex(ox + ku * cell_w, oy + kv * cell_h);
            }
            // Close the fan back to vertex 0
            var ku0 = kite_uvs[0][0];
            var kv0 = v_flip ? (1.0 - kite_uvs[0][1]) : kite_uvs[0][1];
            draw_vertex(ox + ku0 * cell_w, oy + kv0 * cell_h);
            draw_primitive_end();

            draw_set_color(c_black);
            draw_set_font(-1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(
                ox + 0.5 * cell_w,
                oy + 0.5 * cell_h,
                string(self.labels[i])
            );
        }

        draw_set_color(c_dkgrey);
        for (var i = 0; i <= atlas_cols; i++)
            draw_line(i*cell_w, 0, i*cell_w, size);
        for (var i = 0; i <= atlas_rows; i++)
            draw_line(0, i*cell_h, size, i*cell_h);

        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }

    /// @function create
    /// @description Build the full d10: geometry, vertex buffer, and default texture.
    /// @param {real} radius     Circumradius (centre to vertex)
    /// @param {real} pole_dist  Distance from centre to each pole (defaults to radius)
    static create = function(radius, pole_dist = radius) {
        self.radius    = radius;
        self.pole_dist = pole_dist;

        self.__createShape();

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vfmt = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vfmt);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face    = self.faces[i];
            var normal  = self.normals[i];   // pdxVec3
            var face_uv = self.uvs[i];       // array of pdxUV

            for (var j = 0; j < 3; j++) {
                var v  = self.vertices[face[j]];  // pdxVec3
                var uv = face_uv[j];              // pdxUV

                vertex_position_3d(self.vertexBuffer, v.x,      v.y,      v.z);
                vertex_normal     (self.vertexBuffer, normal.x,  normal.y, normal.z);
                vertex_texcoord   (self.vertexBuffer, uv.u,      uv.v);
                vertex_colour     (self.vertexBuffer, c_white, 1);
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);
    }

}

function d12() : Model() constructor {

    static __createShape = function(radius) {
        var phi     = (1 + sqrt(5)) / 2;
        var inv_phi = 1 / phi;

        // s = radius * inv_phi  →  phi*s = radius  →  bounding box is exactly ±radius
        var s = radius * inv_phi;

        self.vertices = [
            new pdxVec3( s,            s,            s           ), // V0
            new pdxVec3( s,            s,           -s           ), // V1
            new pdxVec3( s,           -s,            s           ), // V2
            new pdxVec3( s,           -s,           -s           ), // V3
            new pdxVec3(-s,            s,            s           ), // V4
            new pdxVec3(-s,            s,           -s           ), // V5
            new pdxVec3(-s,           -s,            s           ), // V6
            new pdxVec3(-s,           -s,           -s           ), // V7
            new pdxVec3( 0,            phi*s,        inv_phi*s   ), // V8
            new pdxVec3( 0,            phi*s,       -inv_phi*s   ), // V9
            new pdxVec3( 0,           -phi*s,        inv_phi*s   ), // V10
            new pdxVec3( 0,           -phi*s,       -inv_phi*s   ), // V11
            new pdxVec3( inv_phi*s,    0,            phi*s       ), // V12
            new pdxVec3(-inv_phi*s,    0,            phi*s       ), // V13
            new pdxVec3( inv_phi*s,    0,           -phi*s       ), // V14
            new pdxVec3(-inv_phi*s,    0,           -phi*s       ), // V15
            new pdxVec3( phi*s,        inv_phi*s,    0           ), // V16
            new pdxVec3( phi*s,       -inv_phi*s,    0           ), // V17
            new pdxVec3(-phi*s,        inv_phi*s,    0           ), // V18
            new pdxVec3(-phi*s,       -inv_phi*s,    0           ), // V19
        ];

        // Pentagons with vertex order reversed (CW in standard math = CCW in
        // GameMaker's left-handed system). This corrects winding without
        // touching the triangulation loop, so UV assignments stay intact.
        var pentagons = [
            [12, 13,  4,  8,  0], // F0  (reversed)
            [16, 17,  2, 12,  0], // F1  (reversed)
            [ 8,  9,  1, 16,  0], // F2  (reversed)
            [18,  5,  9,  8,  4], // F3  (reversed)
            [10,  6, 13, 12,  2], // F4  (reversed)
            [14,  3, 17, 16,  1], // F5  (reversed)
            [13,  6, 19, 18,  4], // F6  (reversed)
            [17,  3, 11, 10,  2], // F7  (reversed)
            [ 9,  5, 15, 14,  1], // F8  (reversed)
            [18, 19,  7, 15,  5], // F9  (reversed)
            [14, 15,  7, 11,  3], // F10 (reversed)
            [10, 11,  7, 19,  6], // F11 (reversed)
        ];

        self.labels = [
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
            new pdxUV(0.5000, 0.0300),
            new pdxUV(0.9470, 0.3550),
            new pdxUV(0.7760, 0.8800),
            new pdxUV(0.2240, 0.8800),
            new pdxUV(0.0530, 0.3550),
        ];

        for (var i = 0; i < 12; i++) {
            var pent   = pentagons[i];
            var col    = i mod 4;
            var row    = floor(i / 4);
            var cell_u = col * 0.25;
            var cell_v = row / 3.0;
            var cell_w = 0.25;
            var cell_h = 1.0 / 3.0;

            // Face centroid normal — computed from pdxVec3 vertices
            var cx = 0, cy = 0, cz = 0;
            for (var k = 0; k < 5; k++) {
                var v = self.vertices[pent[k]];
                cx += v.x; cy += v.y; cz += v.z;
            }
            var len = sqrt(cx*cx + cy*cy + cz*cz);
            var nx = cx / len;
            var ny = cy / len;
            var nz = cz / len;

            // Triangulation is unchanged from original — UVs map correctly
            // because winding is handled by the reversed pentagon data above
            for (var t = 0; t < 3; t++) {
                var i0 = 0;
                var i1 = t + 1;
                var i2 = t + 2;

                array_push(self.faces,   [pent[i0], pent[i1], pent[i2]]);
                array_push(self.normals, new pdxVec3(nx, ny, nz));
                array_push(self.uvs, [
                    new pdxUV(
                        cell_u + pent_uvs[i0].u * cell_w,
                        cell_v + pent_uvs[i0].v * cell_h
                    ),
                    new pdxUV(
                        cell_u + pent_uvs[i1].u * cell_w,
                        cell_v + pent_uvs[i1].v * cell_h
                    ),
                    new pdxUV(
                        cell_u + pent_uvs[i2].u * cell_w,
                        cell_v + pent_uvs[i2].v * cell_h
                    ),
                ]);
            }
        }
    }

    static createDefaultTexture = function(size = 256) {
        self.labels = [
             1,  2,  3,  4,
             5,  6,  7,  9,
             8, 11, 12, 10,
        ];

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
            make_colour_rgb(160,  80,  40),
            make_colour_rgb(100, 160,  80),
        ];

        var pent_uvs = [
            new pdxUV(0.5000, 0.0300),
            new pdxUV(0.9470, 0.3550),
            new pdxUV(0.7760, 0.8800),
            new pdxUV(0.2240, 0.8800),
            new pdxUV(0.0530, 0.3550),
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
                    ox + pent_uvs[k].u * cell_w,
                    oy + pent_uvs[k].v * cell_h
                );
            }
            draw_vertex(
                ox + pent_uvs[0].u * cell_w,
                oy + pent_uvs[0].v * cell_h
            );
            draw_primitive_end();

            draw_set_color(c_black);
            draw_set_font(-1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(
                ox + 0.5 * cell_w,
                oy + 0.5 * cell_h,
                string(self.labels[i])
            );
        }

        draw_set_color(c_dkgrey);
        for (var i = 0; i <= 4; i++) draw_line(i * cell_w, 0, i * cell_w, size);
        for (var i = 0; i <= 3; i++) draw_line(0, i * cell_h, size, i * cell_h);

        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_left);

        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }

    static create = function(radius) {
        self.__createShape(radius);

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vertex_format = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vertex_format);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face    = self.faces[i];
            var normal  = self.normals[i]; // pdxVec3
            var face_uv = self.uvs[i];

            for (var j = 0; j < 3; j++) {
                var v  = self.vertices[face[j]]; // pdxVec3
                var uv = face_uv[j];             // pdxUV

                vertex_position_3d(self.vertexBuffer, v.x,      v.y,      v.z     );
                vertex_normal     (self.vertexBuffer, normal.x, normal.y, normal.z);
                vertex_texcoord   (self.vertexBuffer, uv.u,     uv.v              );
                vertex_colour     (self.vertexBuffer, c_white, 1                  );
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);
    }

}

function d20() : Model() constructor {

    static __createShape = function(radius) {
        var phi = (1 + sqrt(5)) / 2;
        // Scale so the maximum axis-aligned extent = radius (phi * s = radius)
        var s = radius / phi;

        // 12 vertices — three mutually perpendicular golden rectangles
        // Stored as pdxVec3 structs; bounds() already reads .x/.y/.z
        self.vertices = [
            new pdxVec3( 0,       s,   phi*s), // V0
            new pdxVec3( 0,      -s,   phi*s), // V1
            new pdxVec3( 0,       s,  -phi*s), // V2
            new pdxVec3( 0,      -s,  -phi*s), // V3
            new pdxVec3( s,   phi*s,      0 ), // V4
            new pdxVec3(-s,   phi*s,      0 ), // V5
            new pdxVec3( s,  -phi*s,      0 ), // V6
            new pdxVec3(-s,  -phi*s,      0 ), // V7
            new pdxVec3( phi*s,   0,      s ), // V8
            new pdxVec3(-phi*s,   0,      s ), // V9
            new pdxVec3( phi*s,   0,     -s ), // V10
            new pdxVec3(-phi*s,   0,     -s ), // V11
        ];

        // 20 triangular faces — winding reversed (v1↔v2) for GameMaker's
        // left-handed coordinate system (Up=-Y, Left=-X, Forward=-Z) so
        // that outward-facing normals are CCW when viewed from outside.
        var triangles = [
            [ 0,  4,  8], // F0
            [ 0,  5,  4], // F1
            [ 0,  9,  5], // F2
            [ 0,  1,  9], // F3
            [ 0,  8,  1], // F4
            [ 1,  8,  6], // F5
            [ 8, 10,  6], // F6
            [ 4, 10,  8], // F7
            [ 4,  2, 10], // F8
            [ 5,  2,  4], // F9
            [ 5, 11,  2], // F10
            [ 9, 11,  5], // F11
            [ 9,  7, 11], // F12
            [ 1,  7,  9], // F13
            [ 1,  6,  7], // F14
            [ 3, 10,  2], // F15
            [ 3,  6, 10], // F16
            [ 3,  7,  6], // F17
            [ 3, 11,  7], // F18
            [ 3,  2, 11], // F19
        ];

        // Die labels 1–20; antipodal pairs sum to 21
        self.labels = [
             1,  2,  3,  4,  5,  // F0–F4   top cap
             6,  7,  8,  9, 10,  // F5–F9   upper middle
            15, 14, 13, 12, 11,  // F10–F14 lower middle
            17, 18, 19, 20, 16,  // F15–F19 bottom cap
        ];

        // Normalised UV positions within each atlas cell (apex, BR, BL)
        var tri_uvs = [
            [0.50, 0.05], // vertex 0: apex
            [0.95, 0.95], // vertex 1: bottom-right
            [0.05, 0.95], // vertex 2: bottom-left
        ];

        for (var i = 0; i < 20; i++) {
            var tri    = triangles[i];
            var col    = i mod 5;
            var row    = floor(i / 5);
            var cell_u = col * 0.2;
            var cell_v = row * 0.25;
            var cell_w = 0.2;
            var cell_h = 0.25;

            // Face normal — normalised centroid direction (outward)
            var cx = 0, cy = 0, cz = 0;
            for (var k = 0; k < 3; k++) {
                var v = self.vertices[tri[k]]; // pdxVec3
                cx += v.x; cy += v.y; cz += v.z;
            }
            var len = sqrt(cx*cx + cy*cy + cz*cz);

            array_push(self.faces,   [tri[0], tri[1], tri[2]]);
            array_push(self.normals, new pdxVec3(cx / len, cy / len, cz / len));
            array_push(self.uvs, [
                new pdxUV(cell_u + tri_uvs[0][0] * cell_w,
                          cell_v + tri_uvs[0][1] * cell_h),
                new pdxUV(cell_u + tri_uvs[1][0] * cell_w,
                          cell_v + tri_uvs[1][1] * cell_h),
                new pdxUV(cell_u + tri_uvs[2][0] * cell_w,
                          cell_v + tri_uvs[2][1] * cell_h),
            ]);
        }
    }


    static createDefaultTexture = function(size = 256) {
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
            make_colour_rgb(160,  80,  40),
            make_colour_rgb(100, 160,  80),
            make_colour_rgb(220, 120, 200),
            make_colour_rgb( 80, 200, 160),
            make_colour_rgb(200, 180, 100),
            make_colour_rgb(120,  80, 220),
            make_colour_rgb( 60, 160, 220),
            make_colour_rgb(220,  80,  40),
            make_colour_rgb(160, 220, 200),
            make_colour_rgb(180, 140,  60),
        ];

        var tri_uvs = [
            [0.50, 0.05],
            [0.95, 0.95],
            [0.05, 0.95],
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

            draw_set_color(face_colors[i]);
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(ox + tri_uvs[0][0] * cell_w, oy + tri_uvs[0][1] * cell_h);
            draw_vertex(ox + tri_uvs[1][0] * cell_w, oy + tri_uvs[1][1] * cell_h);
            draw_vertex(ox + tri_uvs[2][0] * cell_w, oy + tri_uvs[2][1] * cell_h);
            draw_primitive_end();

            draw_set_color(c_black);
            draw_set_font(-1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(
                ox + 0.50 * cell_w,
                oy + 0.60 * cell_h,
                string(self.labels[i])
            );
        }

        draw_set_color(c_dkgrey);
        for (var i = 0; i <= 5; i++) draw_line(i * cell_w, 0, i * cell_w, size);
        for (var i = 0; i <= 4; i++) draw_line(0, i * cell_h, size, i * cell_h);

        surface_reset_target();
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_left);

        var spr = sprite_create_from_surface(
            surf, 0, 0, size, size, false, false, 0, 0
        );
        surface_free(surf);
        self.texture = sprite_get_texture(spr, 0);
    }


    function create(radius) {
        self.__createShape(radius);

        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_normal();
        vertex_format_add_texcoord();
        vertex_format_add_color();
        var vertex_format = vertex_format_end();

        self.vertexBuffer = vertex_create_buffer();
        vertex_begin(self.vertexBuffer, vertex_format);

        for (var i = 0; i < array_length(self.faces); i++) {
            var face    = self.faces[i];
            var normal  = self.normals[i]; // pdxVec3
            var face_uv = self.uvs[i];     // array of 3 pdxUV

            for (var j = 0; j < 3; j++) {
                var v  = self.vertices[face[j]]; // pdxVec3
                var uv = face_uv[j];             // pdxUV

                vertex_position_3d(self.vertexBuffer, v.x,      v.y,      v.z);
                vertex_normal     (self.vertexBuffer, normal.x, normal.y, normal.z);
                vertex_texcoord   (self.vertexBuffer, uv.u,     uv.v);
                vertex_colour     (self.vertexBuffer, c_white,  1);
            }
        }

        vertex_end(self.vertexBuffer);
        vertex_freeze(self.vertexBuffer);

        return self.vertexBuffer;
    }

}
