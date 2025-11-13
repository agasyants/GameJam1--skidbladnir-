shader_type canvas_item;

uniform float aberration_amount = 0.8;
uniform float grain_amount = 1.5;
uniform float vignette_strength = 0.5;
uniform sampler2D screen_texture : hint_screen_texture;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = uv - 0.5;

    // Chromatic aberration
    float r = texture(screen_texture, uv + center * aberration_amount).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - center * aberration_amount).b;

    vec3 col = vec3(r, g, b);

    // Desaturation
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(gray), 0.3);

    // Vignette
    float dist = length(center);
    float vignette = smoothstep(0.7, 0.3, dist);
    col *= mix(1.0 - vignette_strength, 1.0, vignette);

    // Grain
    float noise = rand(uv + vec2(TIME)) * grain_amount;
    col += noise;

    // Tint (холодный зеленоватый)
    col *= vec3(0.9, 1.0, 0.95);

    COLOR = vec4(col, 1.0);
}