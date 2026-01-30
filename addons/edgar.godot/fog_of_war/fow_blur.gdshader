shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int radius : hint_range(0, 65, 1) = 8;
uniform vec2 blur_scale = vec2(1.0, 1.0);
uniform float epsilon : hint_range(1e-6, 1e-2) = 1e-3;

void fragment() {
	float center_alpha = texture(TEXTURE, UV).a;

	if (radius != 0) {
		float blurred_alpha = 0.0;
		float total_weight = 0.0;

		// Gaussian-like weights for the blur accumulation (same as glow.gdshader)
		const float[65] w = { 0.0064,0.0063,0.0062,0.0061,0.0060,0.0059,0.0058,0.0057,0.0056,0.0055,0.0054,0.0053,0.0052,0.0051,0.0050,0.0049,0.0048,0.0047,0.0046,0.0045,0.0044,0.0043,0.0042,0.0041,0.0040,0.0039,0.0038,0.0037,0.0036,0.0035,0.0034,0.0033,0.0032,0.0031,0.0030,0.0029,0.0028,0.0027,0.0026,0.0025,0.0024,0.0023,0.0022,0.0021,0.0020,0.0019,0.0018,0.0017,0.0016,0.0015,0.0014,0.0013,0.0012,0.0011,0.0010,0.0009,0.0008,0.0007,0.0006,0.0005,0.0004,0.0003,0.0002,0.0001,0.0000 };

		// Calculate the size of a single pixel in UV coordinates
		float px = TEXTURE_PIXEL_SIZE.x * blur_scale.x;
		float py = TEXTURE_PIXEL_SIZE.y * blur_scale.y;

		// Iterate through the blur radius layers
		for(int i = 0; i < radius; i++) {
			// Current radius distance (in pixels)
			float r = float(i + 1);

			// Calculate Level of Detail (LOD) / Mipmap level for optimization
			// Distribute 8 samples around the circumference of radius 'r'
			float gap = max(1.0, (r * 0.785) * length(blur_scale));
			float k = log2(gap) - 1.0;
			k = max(0.0, k);

			// Calculate rotation angle for this layer
			float base_angle = float(i);
			float angle_step = 3.1415927 * 2.0 / 8.0; // 45 degrees in radians

			// Perform 8 samples in different directions for this radius layer
			for(int j = 0; j < 8; j++) {
				float angle = base_angle + float(j) * angle_step;
				vec2 dir = vec2(cos(angle), sin(angle));

				// Calculate the UV offset: Direction * Radius * PixelSize
				vec2 offset = dir * r * vec2(px, py);
				vec2 sample_uv = UV + offset;

				// Skip samples outside texture bounds
				if (sample_uv.x < epsilon || sample_uv.x > 1.0 - epsilon || sample_uv.y < epsilon || sample_uv.y > 1.0 - epsilon) {
					continue;
				}

				// Accumulate the sampled alpha, weighted by the distance weight 'w[i]'
				blurred_alpha += textureLod(TEXTURE, sample_uv, k).a * w[i];
				total_weight += w[i];
			}
		}

		// Normalize by total weight
		float final_alpha = blurred_alpha / total_weight;
		COLOR = vec4(fog_color.rgb, 1.0 - final_alpha);
	} else {
		COLOR = vec4(fog_color.rgb, 1.0 - center_alpha);
	}
}
