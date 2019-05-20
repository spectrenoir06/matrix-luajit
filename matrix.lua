local ffi = require("ffi")
local socket = require("socket")
local struct = require("struct")

udp = socket.udp()
udp:setsockname("*", 1234)
udp:settimeout(0)

local lib = ffi.load("/home/pi/matrix-luajit/librgbmatrix.so.1")

ffi.cdef([[
struct RGBLedMatrix {};
struct LedCanvas {};
struct LedFont {};

struct RGBLedMatrixOptions {
  const char *hardware_mapping;
  int rows;
  int cols;
  int chain_length;
  int parallel;
  int pwm_bits;
  int pwm_lsb_nanoseconds;
  int pwm_dither_bits;
  int brightness;
  int scan_mode;
  int row_address_type;  /* Corresponding flag: --led-row-addr-type */
  int multiplexing;
  const char *led_rgb_sequence;     /* Corresponding flag: --led-rgb-sequence */
  const char *pixel_mapper_config;  /* Corresponding flag: --led-pixel-mapper */
  unsigned disable_hardware_pulsing:1;
  unsigned show_refresh_rate:1;  /* Corresponding flag: --led-show-refresh    */
  // unsigned swap_green_blue:1; /* deprecated, use led_sequence instead */
  unsigned inverse_colors:1;     /* Corresponding flag: --led-inverse         */
};

struct RGBLedMatrix *led_matrix_create_from_options(
             struct RGBLedMatrixOptions *options, int *argc, char ***argv);
//void led_matrix_print_flags(FILE *out);
struct RGBLedMatrix *led_matrix_create(int rows, int chained, int parallel);
void led_matrix_delete(struct RGBLedMatrix *matrix);
struct LedCanvas *led_matrix_get_canvas(struct RGBLedMatrix *matrix);
void led_canvas_get_size(const struct LedCanvas *canvas,
                         int *width, int *height);
void led_canvas_set_pixel(struct LedCanvas *canvas, int x, int y,
			  uint8_t r, uint8_t g, uint8_t b);
void led_canvas_clear(struct LedCanvas *canvas);
void led_canvas_fill(struct LedCanvas *canvas, uint8_t r, uint8_t g, uint8_t b);
struct LedCanvas *led_matrix_create_offscreen_canvas(struct RGBLedMatrix *matrix);
struct LedCanvas *led_matrix_swap_on_vsync(struct RGBLedMatrix *matrix,
                                           struct LedCanvas *canvas);
uint8_t led_matrix_get_brightness(struct RGBLedMatrix *matrix);
void led_matrix_set_brightness(struct RGBLedMatrix *matrix, uint8_t brightness);
struct LedFont *load_font(const char *bdf_font_file);
void delete_font(struct LedFont *font);
int draw_text(struct LedCanvas *c, struct LedFont *font, int x, int y,
	uint8_t r, uint8_t g, uint8_t b,
	const char *utf8_text, int kerning_offset);
int vertical_draw_text(struct LedCanvas *c, struct LedFont *font, int x, int y,
	uint8_t r, uint8_t g, uint8_t b, const char *utf8_text, int kerning_offset);
void draw_circle(struct LedCanvas *c, int xx, int y, int radius, uint8_t r, uint8_t g, uint8_t b);
void draw_line(struct LedCanvas *c, int x0, int y0, int x1, int y1, uint8_t r, uint8_t g, uint8_t b);
]])

function color_wheel(WheelPos)
	WheelPos = WheelPos % 255
	WheelPos = 255 - WheelPos
	if (WheelPos < 85) then
		return {255 - WheelPos * 3, 0, WheelPos * 3}
	elseif (WheelPos < 170) then
		WheelPos = WheelPos - 85
		return {0, WheelPos * 3, 255 - WheelPos * 3}
	else
		WheelPos = WheelPos - 170
		return {WheelPos * 3, 255 - WheelPos * 3, 0}
	end
end


local options = ffi.new("struct RGBLedMatrixOptions")
local matrix = ffi.new("struct RGBLedMatrix")
local offscreen_canvas = ffi.new("struct LedCanvas")

options.rows = 32
options.cols = 64
options.chain_length = 2
options.hardware_mapping = "adafruit-hat"
options.pixel_mapper_config = "U-mapper"

local matrix = ffi.gc(lib.led_matrix_create_from_options(options, nil, nil), lib.led_matrix_delete)
offscreen_canvas = lib.led_matrix_create_offscreen_canvas(matrix)


--
while true do
	data, ip, port = udp:receivefrom()



	if data then
		print("Received: ",ip,port)
		print(data)
		for x=0,64-1 do
			for y=0,64-1 do
				local c = color_wheel(x+y)
				lib.led_canvas_set_pixel(offscreen_canvas, x, y, c[1], c[2], c[3]);
			end
		end
		offscreen_canvas = lib.led_matrix_swap_on_vsync(matrix, offscreen_canvas);
	end
	socket.sleep(0.1)
end
