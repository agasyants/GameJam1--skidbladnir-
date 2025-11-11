shader_type canvas_item;

uniform sampler2D texture_from;
uniform sampler2D texture_to;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);

// Количество "лепестков" для звезды
uniform float petals = 5.0;
// 0.0 = круг, 0.3 = мягкая звезда, 1.0 = острая звезда
uniform float shape_strength = 0.25; 
// Ширина "мягкой" границы (0.01 - 0.2)
uniform float edge_width = 0.2;
// Сила "линзы" на стыке (0.0 - 0.05)
uniform float lens_strength = 0.02;
// Сила "цветного" смещения на стыке (0.0 - 0.03)
uniform float aberr_strength = 0.012;
// Дополнительный поворот звезды (0.0 - PI*2)
uniform float rotation = 0.0;


void fragment() {
    // --- 1. Подготовка UV и полярных координат ---
    vec2 uv = UV;
    vec2 centered_uv = uv - center;

    float dist = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);

    // --- 2. Создание "Звёздной" формы ---
    float shape_mod = 1.0 + cos(angle * petals + rotation) * shape_strength;
    float scaled_dist = dist / (shape_mod + 0.0001);

    // --- 3. "Ease Out" тайминг ---
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
    
    // Б) Радиальная Хроматическая Аберрация
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