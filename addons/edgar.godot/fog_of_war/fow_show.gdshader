shader_type canvas_item;

uniform sampler2D add_texture;
uniform int cols = 48;
uniform int rows = 27;
uniform int grid_data[2048];

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec4 final_color = original;
    
    vec2 base_size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 stamp_size = vec2(textureSize(add_texture, 0));
    vec2 ratio = base_size / stamp_size;
    
    vec2 half_extent = 0.5 / ratio; 
    
    int x_min = int(floor((UV.x - half_extent.x) * float(cols)));
    int x_max = int(floor((UV.x + half_extent.x) * float(cols)));
    int y_min = int(floor((UV.y - half_extent.y) * float(rows)));
    int y_max = int(floor((UV.y + half_extent.y) * float(rows)));
    
    x_min = max(x_min, 0);
    x_max = min(x_max, cols - 1);
    y_min = max(y_min, 0);
    y_max = min(y_max, rows - 1);
    
    float current_alpha = 0.0;
    vec3 overlay_color = vec3(0.0);
    
    for (int y = y_min; y <= y_max; y++) {
        for (int x = x_min; x <= x_max; x++) {
            int index = y * cols + x;
            int array_idx = index / 32;
            int bit_idx = index % 32;
            
            bool is_active = ((grid_data[array_idx] >> bit_idx) & 1) != 0;
            
            if (is_active) {
                vec2 cell_center_uv = vec2((float(x) + 0.5) / float(cols), (float(y) + 0.5) / float(rows));
                
                vec2 stamp_uv = (UV - cell_center_uv) * ratio + 0.5;
                
                if (stamp_uv.x > 0.0 && stamp_uv.x < 1.0 && 
                    stamp_uv.y > 0.0 && stamp_uv.y < 1.0) {
                    vec4 stamp = texture(add_texture, stamp_uv);
                    if (stamp.a > current_alpha) {
                        current_alpha = stamp.a;
                        overlay_color = stamp.rgb;
                    }
                }
            }
        }
    }
    
    final_color = mix(final_color, vec4(overlay_color, 1.0), current_alpha);
    
    COLOR = final_color;
}