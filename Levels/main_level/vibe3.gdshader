shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

// Размер пикселя (чем больше значение, тем крупнее пиксели)
uniform float pixel_size : hint_range(1.0, 32.0) = 2.0;

void fragment() {
    // Вычисляем размер одного "большого пикселя" в UV координатах
    vec2 pixel_uv = pixel_size * SCREEN_PIXEL_SIZE;

    // Округляем SCREEN_UV координаты до ближайшего "пикселя"
    vec2 pixelated_uv = floor(SCREEN_UV / pixel_uv) * pixel_uv;

    // Получаем цвет из screen_texture
    COLOR = texture(screen_texture, pixelated_uv);
}