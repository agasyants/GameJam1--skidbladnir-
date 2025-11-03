shader_type canvas_item;

uniform sampler2D texture_from;
uniform sampler2D texture_to;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    
    // Радиальная волна с резкими полосами
    float wave = progress * 2.0 - dist;
    
    // Блочное искажение - пиксельные глитчи
    vec2 block_uv = floor(uv * 40.0) / 40.0;
    float block_noise = hash(block_uv + vec2(progress * 10.0));
    wave += (block_noise - 0.5) * 0.3;
    
    // Резкий переход
    float mask = step(0.0, wave);
    
    // Глитч-смещение на границе
    float edge = abs(wave);
    edge = 1.0 - smoothstep(0.0, 0.15, edge);
    
    vec2 offset = vec2(
        hash(block_uv + vec2(0.0, progress)) - 0.5,
        hash(block_uv + vec2(100.0, progress)) - 0.5
    ) * edge * 0.05;
    
    vec4 col_from = texture(texture_from, uv + offset * (1.0 - mask));
    vec4 col_to = texture(texture_to, uv + offset * mask);
    
    // Резкий микс
    vec4 final = mix(col_from, col_to, mask);
    
    // Яркая вспышка на границе
    final.rgb += vec3(edge * 2.0);
    
    // Инверсия цветов на пике
    if (progress > 0.4 && progress < 0.6 && edge > 0.5) {
        final.rgb = vec3(1.0) - final.rgb;
    }
    
    COLOR = final;
}