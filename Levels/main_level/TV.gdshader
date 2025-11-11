shader_type canvas_item;

// Параметры эффекта
uniform float noise_strength : hint_range(0.0, 1.0) = 0.8;
uniform float distortion_amount : hint_range(0.0, 0.5) = 0.1;
uniform float line_speed : hint_range(0.0, 10.0) = 2.0;
uniform float grain_size : hint_range(1.0, 10.0) = 8.0;
uniform float channel_switch_progress : hint_range(0.0, 1.0) = 0.0;

// Функция для генерации псевдослучайного шума
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Функция для генерации шума с учетом времени
float noise(vec2 uv, float time) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i + vec2(0.0, 0.0) + time);
    float b = random(i + vec2(1.0, 0.0) + time);
    float c = random(i + vec2(0.0, 1.0) + time);
    float d = random(i + vec2(1.0, 1.0) + time);
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;
    
    // Интенсивность эффектов на основе прогресса переключения каналов
    float switch_intensity = 1.0 - abs(2.0 * channel_switch_progress - 1.0);
    
    // Сильные искажения при переключении каналов
    float channel_distortion = distortion_amount * (1.0 + 3.0 * switch_intensity);
    float channel_noise_strength = noise_strength * (1.0 + 2.0 * switch_intensity);
    
    // Горизонтальные помехи (смещение строк)
    float line_noise = noise(vec2(uv.y * 10.0, time * line_speed), time);
    uv.x += (line_noise - 0.5) * channel_distortion;
    
    // Вертикальные искажения (усиливаются при переключении)
    float vert_noise = noise(vec2(time * 5.0, uv.y * 20.0), time * 2.0);
    if (vert_noise > 0.9 - 0.3 * switch_intensity) {
        uv.x += sin(uv.y * 50.0 + time * 10.0) * 0.02 * (1.0 + switch_intensity);
    }
    
    // Получаем цвет текстуры с искаженными координатами
    vec4 color = texture(TEXTURE, uv);
    
    // Генерируем статический шум (мелкие зерна)
    vec2 grain_uv = uv * grain_size * vec2(1920.0 / grain_size, 1080.0 / grain_size);
    float static_noise = noise(grain_uv, time * 10.0);
    
    // Смешиваем оригинальное изображение с шумом (больше шума при переключении)
    vec3 noise_color = vec3(static_noise);
    color.rgb = mix(color.rgb, noise_color, channel_noise_strength);
    
    // Добавляем случайные черные/белые полосы (чаще при переключении)
    float bands = noise(vec2(0.0, uv.y * 5.0 + time * 3.0), time);
    if (bands > 0.95 - 0.2 * switch_intensity) {
        color.rgb = vec3(bands);
    }
    
    // Эффект "потери сигнала" в середине переключения
    if (channel_switch_progress > 0.4 && channel_switch_progress < 0.6) {
        float signal_loss = 1.0 - abs(2.0 * (channel_switch_progress - 0.5) * 10.0);
        color.rgb = mix(color.rgb, vec3(0.0), signal_loss * 0.8);
    }
    
    // Быстрое мерцание при переключении каналов
    float rapid_flicker = 0.7 + 0.3 * noise(vec2(time * 50.0 * (1.0 + switch_intensity * 5.0)), time);
    color.rgb *= rapid_flicker;
 
    
    // Легкое мерцание яркости (базовое)
    float flicker = 0.9 + 0.1 * noise(vec2(time * 20.0), time);
    color.rgb *= flicker;

    // Яркость (немного уменьшаем при нормальном состоянии)
    float brightness = 0.4 + 0.3 * switch_intensity;
    color *= brightness;
    
    COLOR = vec4(color.rgb, 1.0);
}