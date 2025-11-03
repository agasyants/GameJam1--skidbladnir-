shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float size : hint_range(0.0, 1.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float animation_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // Расчет расстояния от центра
    vec2 uv = SCREEN_UV;
    float dist = distance(uv, vec2(0.5, 0.5));
    
    // Анимированная интенсивность
    float animated_intensity = intensity * (0.8 + 0.2 * sin(TIME * animation_speed));
    
    // Создание веньетки
    float vignette = smoothstep(size, size - 0.3, dist * (1.0 + animated_intensity));
    vignette = pow(vignette, 2.0);
    
    // Применение к цвету
    COLOR = texture(TEXTURE, UV);
    COLOR.rgb = mix(COLOR.rgb, vignette_color.rgb, vignette * vignette_color.a);
}