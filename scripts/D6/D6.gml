/// @function create_cube
/// @description Create cube with UV coordinates and correct CCW winding
/// @param {real} radius Half the edge length of the cube
/// @returns {struct} Struct containing vertices, faces, normals, and UVs arrays

function create_cube(radius) {
    var r = radius;
    
    // Create vertices array (8 corners of cube)
    var vertices = [
        [-r,  r,  r],  // V0: bottom-left-back
        [ r,  r,  r],  // V1: bottom-right-back
        [ r, -r,  r],  // V2: top-right-back
        [-r, -r,  r],  // V3: top-left-back
        [-r,  r, -r],  // V4: bottom-left-front
        [ r,  r, -r],  // V5: bottom-right-front
        [ r, -r, -r],  // V6: top-right-front
        [-r, -r, -r]   // V7: top-left-front
    ];
    
    // Faces with CORRECTED CCW ordering (2 triangles per face, 12 triangles total)
    var faces = [
        // Bottom face — CORRECT, unchanged
        [0, 4, 5], [0, 5, 1],
        // Top face — FIXED
        [3, 6, 7], [3, 2, 6],
        // Front face — FIXED
        [4, 6, 5], [4, 7, 6],
        // Back face — FIXED
        [1, 3, 0], [1, 2, 3],
        // Right face — FIXED
        [5, 2, 1], [5, 6, 2],
        // Left face — FIXED
        [0, 7, 4], [0, 3, 7]
    ];    
        
    
    // UV coordinates for each face (arranged in cross pattern)
    var face_uvs = [
        // Bottom face
        [[0.2575, 0.9925], [0.2575, 0.7575], [0.4925, 0.7575]], [[0.2575, 0.9925], [0.4925, 0.7575], [0.4925, 0.9925]],
        // Top face — inverted (y)
        [[0.2575, 0.0075], [0.4925, 0.2425], [0.2575, 0.2425]], [[0.2575, 0.0075], [0.4925, 0.0075], [0.4925, 0.2425]],
        // Front face
        [[0.2575, 0.4925], [0.4925, 0.2575], [0.4925, 0.4925]], [[0.2575, 0.4925], [0.2575, 0.2575], [0.4925, 0.2575]],
        // Back face
        [[0.7575, 0.4925], [0.9925, 0.2575], [0.9925, 0.4925]], [[0.7575, 0.4925], [0.7575, 0.2575], [0.9925, 0.2575]],
        // Right face
        [[0.5075, 0.4925], [0.7425, 0.2575], [0.7425, 0.4925]], [[0.5075, 0.4925], [0.5075, 0.2575], [0.7425, 0.2575]],
        // Left face
        [[0.0075, 0.4925], [0.2425, 0.2575], [0.2425, 0.4925]], [[0.0075, 0.4925], [0.0075, 0.2575], [0.2425, 0.2575]]
    ];
            
        
    // CORRECTED Face normals (outward pointing)
    var face_normals = [
        [ 0,  1,  0],  // Bottom face triangle 1
        [ 0,  1,  0],  // Bottom face triangle 2
        [ 0, -1,  0],   // Top face triangle 1
        [ 0, -1,  0],   // Top face triangle 2
        [ 0,  0, -1],   // Front face triangle 1
        [ 0,  0, -1],   // Front face triangle 2
        [ 0,  0,  1],  // Back face triangle 1
        [ 0,  0,  1],  // Back face triangle 2
        [-1,  0,  0],   // Right face triangle 1
        [-1,  0,  0],   // Right face triangle 2
        [ 1,  0,  0],  // Left face triangle 1
        [ 1,  0,  0]   // Left face triangle 2
    ];
    
    return {
        vertices: vertices,
        faces: faces,
        normals: face_normals,
        uvs: face_uvs
    };
}

/// @function create_simple_cube_texture
/// @description Create a simple texture for the cube
/// @param {real} size Texture size (power of 2, e.g., 128, 256, 512)
/// @returns {Id.Texture} Generated texture

function create_simple_cube_texture(size = 256) {
    var surf = surface_create(size, size);
    surface_set_target(surf);
    
    draw_clear(c_black);
    
    var quarter = size * 0.25;
    var half = size * 0.5;
    var three_quarter = size * 0.75;
    
    // Define colors for each face
    var colors = [c_red, c_green, c_blue, c_yellow, c_purple, c_orange];
    var face_names = ["3", "4", "6", "1", "5", "2"];
    
    // Draw colored rectangles for each face in cross pattern
    // Top face
    draw_set_color(colors[1]);
    draw_rectangle(quarter, 0, half, quarter, false);
    
    // Middle row: Left, Front, Right, Back
    draw_set_color(colors[5]); // Left
    draw_rectangle(0, quarter, quarter, half, false);
    
    draw_set_color(colors[2]); // Front
    draw_rectangle(quarter, quarter, half, half, false);
    
    draw_set_color(colors[4]); // Right
    draw_rectangle(half, quarter, three_quarter, half, false);
    
    draw_set_color(colors[3]); // Back
    draw_rectangle(three_quarter, quarter, size, half, false);
    
    // Bottom face
    draw_set_color(colors[0]);
    draw_rectangle(quarter, three_quarter, half, size, false);
    
    // Add grid lines
    draw_set_color(c_white);
    for (var i = 0; i <= 4; i++) {
        var pos = i * quarter;
        draw_line(pos, 0, pos, size);     // Vertical lines
        draw_line(0, pos, size, pos);     // Horizontal lines
    }
    
    // Add face labels
    draw_set_font(-1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    
    draw_text(quarter + quarter/2, quarter/2, face_names[1]);           // Top
    draw_text(quarter/2, quarter + quarter/2, face_names[5]);           // Left
    draw_text(quarter + quarter/2, quarter + quarter/2, face_names[2]); // Front
    draw_text(half + quarter/2, quarter + quarter/2, face_names[4]);    // Right
    draw_text(three_quarter + quarter/2, quarter + quarter/2, face_names[3]); // Back
    draw_text(quarter + quarter/2, three_quarter + quarter/2, face_names[0]); // Bottom
    
    // Reset all defaults
    surface_reset_target();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_left);

    var spr = sprite_create_from_surface(
        surf, 0, 0, size, size, false, false, 0, 0
    );
    
    if(!file_exists("c:\\temp\\d6.png")) {
        sprite_save(spr, 0, "c:\\temp\\d6.png");
    }

    return spr;
}

/// @function create_cube_vertex_buffer
/// @description Create a vertex buffer for the cube with UVs
/// @param {real} radius Half the edge length of the cube
/// @returns {Id.VertexBuffer} Vertex buffer containing the cube

function create_cube_vertex_buffer(radius) {
    var cube_data = create_cube(radius);
    
    // Create vertex format (position + normal + UV)
    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    vertex_format_add_color();
    var vertex_format = vertex_format_end();
    
    // Create vertex buffer
    var vbuff = vertex_create_buffer();
    vertex_begin(vbuff, vertex_format);
    
    // Add triangles to vertex buffer
    for (var i = 0; i < array_length(cube_data.faces); i++) {
        var face = cube_data.faces[i];
        var normal = cube_data.normals[i];
        var face_uv = cube_data.uvs[i];
        
        // Add each vertex of the triangle
        for (var j = 0; j < 3; j++) {
            var vertex_idx = face[j];
            var vertex = cube_data.vertices[vertex_idx];
            var uv = face_uv[j];
            
            // Position
            vertex_position_3d(vbuff, vertex[0], vertex[1], vertex[2]);
            // Normal
            vertex_normal(vbuff, normal[0], normal[1], normal[2]);
            // UV coordinates
            vertex_texcoord(vbuff, uv[0], uv[1]);
            // Blend Colour
            vertex_colour(vbuff, c_white, 1);
        }
    }
    
    vertex_end(vbuff);
    vertex_freeze(vbuff);
    
    return vbuff;
}

/// @function draw_cube
/// @description Draw cube using vertex buffer
/// @param {Id.VertexBuffer} vbuff Vertex buffer containing cube
/// @param {Id.Texture} texture Texture to apply

function draw_cube(vbuff, texture) {
    vertex_submit(vbuff, pr_trianglelist, texture);
}