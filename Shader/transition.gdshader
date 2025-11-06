shader_type canvas_item;

uniform sampler2D texture_from;
uniform sampler2D texture_to;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);

//float hash(vec2 p) {
    //return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
//}
//
//void fragment() {
    //vec2 uv = UV;
    //vec2 center = vec2(0.5, 0.5);
    //float dist = length(uv - center);
    //
    //// Радиальная волна с резкими полосами
    //float wave = progress * 2.0 - dist;
    //
    //// Блочное искажение - пиксельные глитчи
    //vec2 block_uv = floor(uv * 40.0) / 40.0;
    //float block_noise = hash(block_uv + vec2(progress * 10.0));
    //wave += (block_noise - 0.5) * 0.3;
    //
    //// Резкий переход
    //float mask = step(0.0, wave);
    //
    //// Глитч-смещение на границе
    //float edge = abs(wave);
    //edge = 1.0 - smoothstep(0.0, 0.15, edge);
    //
    //vec2 offset = vec2(
        //hash(block_uv + vec2(0.0, progress)) - 0.5,
        //hash(block_uv + vec2(100.0, progress)) - 0.5
    //) * edge * 0.05;
    //
    //vec4 col_from = texture(texture_from, uv + offset * (1.0 - mask));
    //vec4 col_to = texture(texture_to, uv + offset * mask);
    //
    //// Резкий микс
    //vec4 final = mix(col_from, col_to, mask);
    //
    //// Яркая вспышка на границе
    //final.rgb += vec3(edge * 2.0);
    //
    //// Инверсия цветов на пике
    //if (progress > 0.4 && progress < 0.6 && edge > 0.5) {
        //final.rgb = vec3(1.0) - final.rgb;
    //}
    //
    //COLOR = final;
//}

//void fragment() {
    //vec2 uv = UV;
    //vec4 col_from = texture(texture_from, uv);
    //vec4 col_to = texture(texture_to, uv);
//
    //vec2 center = vec2(0.5, 0.5);
    //float dist = length(uv - center); // 0 в центре, ~0.707 в углу
//
    //// Ширина зоны смешивания
    //float edge = 0.1;
//
    //// Плавный переход между col_from и col_to
    //float t = smoothstep(progress - edge, progress + edge, dist);
//
    //vec4 final = mix(col_to, col_from, t);
//
    //COLOR = final;
//}


// --- Новые Uniforms (для настройки) ---
// Количество "лепестков" для звезды
uniform float petals = 5.0;
// 0.0 = круг, 0.3 = мягкая звезда, 1.0 = острая звезда
uniform float shape_strength = 0.25; 
// Ширина "мягкой" границы (0.01 - 0.2)
uniform float edge_width = 0.2; 
// Сила "линзы" на стыке (0.0 - 0.05)
uniform float lens_strength = 0.02;
// Сила "цветного" смещения на стыке (0.0 - 0.03)
uniform float aberr_strength = 0.01;


void fragment() {
    // --- 1. Подготовка UV и полярных координат ---
    vec2 uv = UV;
    vec2 centered_uv = uv - center;

    float dist = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);

    // --- 2. Создание "Звёздной" формы (как в Варианте 1) ---
    float shape_mod = 1.0 + cos(angle * petals) * shape_strength;
    // Нормализуем дистанцию по новой, "звёздной" форме
    float scaled_dist = dist / (shape_mod + 0.0001); // (добавил 0.0001 для защиты от / 0)

    // --- 3. НОВОЕ: "Ease Out" тайминг ---
    // Мы "искривляем" время.
    // Вместо 'progress', мы используем 'eased_progress'.
    // sin(t * 0.5 * PI) - это классическая "Sine Ease Out" функция.
    // Она стартует быстро, а к 1.0 "подъезжает" очень плавно.
    float eased_progress = 1.0 - pow(1.0 - progress, 1.2);

    // --- 4. Расчет маски перехода (t) ---
    // 't' будет плавно меняться от 0 до 1 на границе
    float t = smoothstep(eased_progress - edge_width, eased_progress + edge_width, scaled_dist);

    // --- 5. НОВОЕ: "Смешение на стыке" (Линза + Радиальная Аберрация) ---
    
    // 'edge_factor' - это наш "пульс". Он 0.0 везде,
    // кроме границы перехода, где он плавно достигает 1.0 в центре.
    float edge_factor = t * (1.0 - t) * 4.0;

    // Вектор, направленный "от центра"
    vec2 radial_dir = normalize(centered_uv + 0.0001); // (снова защита от 0)

    // A) Эффект Линзы (Пространственное смещение)
    // Мы "сдвигаем" UV в радиальном направлении на величину "линзы".
    // Это создает "щипок" (pinch) или "выпуклость" (bulge) на границе.
    vec2 lens_displace = radial_dir * edge_factor * lens_strength;
    
    // Б) Радиальная Хроматическая Аберрация (Цветовое смещение)
    // Улучшение из Варианта 1: теперь аберрация не просто R/B,
    // а "расходится" от центра вдоль границы. Это выглядит гораздо лучше.
    vec2 aberr_displace = radial_dir * edge_factor * aberr_strength;

    // --- 6. Сэмплирование текстур с новыми эффектами ---

    // col_to ("куда") "втягивается"
    vec2 uv_to_r = uv - lens_displace + aberr_displace;
    vec2 uv_to_g = uv - lens_displace;
    vec2 uv_to_b = uv - lens_displace - aberr_displace;
    vec4 col_to = vec4(
        texture(texture_to, uv_to_r).r,
        texture(texture_to, uv_to_g).g,
        texture(texture_to, uv_to_b).b,
        texture(texture_to, uv_to_g).a
    );

    // col_from ("откуда") "выталкивается"
    vec2 uv_from_r = uv + lens_displace + aberr_displace;
    vec2 uv_from_g = uv + lens_displace;
    vec2 uv_from_b = uv + lens_displace - aberr_displace;
    vec4 col_from = vec4(
        texture(texture_from, uv_from_r).r,
        texture(texture_from, uv_from_g).g,
        texture(texture_from, uv_from_b).b,
        texture(texture_from, uv_from_g).a
    );

    // --- 7. Финальное смешивание ---
    // Мы смешиваем уже искаженные текстуры, используя 't' (нашу маску)
    vec4 final = mix(col_to, col_from, t);
    COLOR = final;
}