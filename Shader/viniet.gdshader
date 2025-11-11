shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float size : hint_range(0.0, 1.5) = 1.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float distortion_speed : hint_range(0.0, 5.0) = 2.0;
uniform float distortion_intensity : hint_range(0.0, 0.5) = 0.1;
uniform float pulse_speed : hint_range(0.0, 5.0) = 3.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    if (intensity < 0.001) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        vec2 uv = UV;

        // Добавляем пульсацию для эффекта сердцебиения/сознания
        float pulse = sin(TIME * pulse_speed) * 0.1 + 1.0;
        float animated_intensity = intensity * (0.7 + 0.3 * sin(TIME * 8.0)) * pulse;

        // Добавляем искажения для неровных краев
        vec2 distorted_uv = uv;
        distorted_uv.x += sin(uv.y * 20.0 + TIME * distortion_speed) * distortion_intensity * 0.1;
        distorted_uv.y += cos(uv.x * 15.0 + TIME * distortion_speed * 1.2) * distortion_intensity * 0.1;

        float dist = distance(distorted_uv, vec2(0.5, 0.45));

        // Добавляем шум для более органичного вида
        float noise = random(uv * 10.0 + TIME) * 0.2;
        dist += noise * distortion_intensity;

        // Создаем веньетку с более сложной формой
        float base_vignette = smoothstep(size * 0.8, size * 0.8 - 0.4, dist * (1.0 + animated_intensity));

        // Вторая маска для дополнительной сложности
        float secondary_vignette = smoothstep(size * 1.2, size * 1.2 - 0.5, dist * (1.0 + animated_intensity * 0.7));

        // Комбинируем маски
        float vignette = mix(base_vignette, secondary_vignette, 0.3);
        vignette = pow(vignette, 1.5);

        // Добавляем мерцание
        float flicker = 0.8 + 0.2 * sin(TIME * 12.0) * cos(TIME * 7.0) * intensity;

        COLOR = vec4(0.0, 0.0, 0.0, (1.0 - vignette * flicker) * vignette_color.a);
    }
}