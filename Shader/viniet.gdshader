shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float size : hint_range(0.0, 1.5) = 1.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
    // Расчет расстояния от центра
    vec2 uv = UV;
    float dist = distance(uv, vec2(0.5, 0.55));
    
    // Анимированная интенсивность
    float animated_intensity = intensity * (0.8 + 0.2 * sin(TIME*8.0));
    
    // Создание веньетки
    float vignette = smoothstep(size, size - 0.3, dist * (1.0 + animated_intensity));
    vignette = pow(vignette, 2.0);
    
    // Устанавливаем только альфа-канал для прозрачности
    COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vignette * vignette_color.a);
}