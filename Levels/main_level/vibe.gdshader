shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float brightnessMult : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float wiggleMult : hint_range(0.0, 0.01, 0.0001) = 0.005;
uniform float chromaticAberrationOffset : hint_range(0.0, 0.01, 0.00001) = 0.001;
uniform float insanity : hint_range(0.0, 2.0) = 1.0;

// t — время
// period — длительность одного витка синусоиды
// silence — длительность тишины после витка
// freq — частота синусоиды
float pulsedSine(float t, float period, float silence, float freq) {
    float cycle = period + silence;
    float localT = mod(t, cycle);

    if (localT < period) {
        float phase = (localT / period) * 2.0 * PI * freq;

        // Двусторонняя огибающая: плавный fade-in и fade-out
        float fadeIn = smoothstep(0.0, 0.2, localT / period);
        float fadeOut = smoothstep(1.0, 0.8, localT / period);
        float env = fadeIn * fadeOut;

        return sin(phase) * env;
    } else {
        return 0.0;
    }
}


void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = SCREEN_UV;
    vec3 color;

    // Wiggle/distortion
    float x = pulsedSine(TIME * 5.0 + uv.y * 31.0, 3.0, 30.0, 1.0) * sin(TIME * 4.0 + uv.y * 19.0) * sin(TIME * 2.0 + uv.x * 10.0) * wiggleMult * insanity;

    // Chromatic aberration + boost
    color.r = texture(screen_texture, vec2(x + uv.x + chromaticAberrationOffset * insanity, uv.y + chromaticAberrationOffset)).r + 0.045;
    color.g = texture(screen_texture, vec2(x + uv.x, uv.y - chromaticAberrationOffset)).g + 0.05;
    color.b = texture(screen_texture, vec2(x + uv.x - chromaticAberrationOffset, uv.y)).b + 0.055;

    // Vignette
    float vignette = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
    color *= vec3(pow(vignette, 0.3));

    // Color grading
    color *= vec3(0.8, 1.12, 1.1); // Синий-зелёный оттенок
    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), 0.2); // Десатурация

    // Scanlines
    float scans = clamp(0.35 + 0.35 * sin(3.5 * TIME + uv.y * iResolution.y * 1.5), 0.0, 1.0);
    float s = pow(scans, 1.7);
    color *= vec3(0.4 + 0.7 * s);

    // Brightness
    color *= brightnessMult;

    COLOR = vec4(color, 1.0);
}