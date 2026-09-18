extends Node

## Giao diện chung — font, bảng màu, kho ảnh. Autoload: gọi bằng "GiaoDien".
##
## Vì sao là autoload chứ không phải một Theme .tres dựng trong editor:
## CLAUDE.md nói rõ `.tres` do Godot sở hữu — chạy một lần là nó viết lại,
## xoá hết comment. Mà chuỗi font ở dưới thì BẮT BUỘC phải có comment giải
## thích, không thì người sau gỡ mất phần dự phòng chữ Hán và cả game hiện ô
## vuông. Dựng bằng code thì ghi chú sống được.
##
## File này KHÔNG được nhắc tới một `class_name` nào. Autoload phân giải lớp
## ngay lúc nạp, và lớp đó gọi ngược lại autoload là vòng tròn chết — đã dính
## một lần với DuHanh/VungDat, xem mục bẫy cuối TIEN_DO.md.

const THU_MUC_ANH := "res://assets/ui/"

# --- Font -----------------------------------------------------------
#
# KHÔNG FONT NÀO TRONG BỘ ASSET CÓ CHỮ HÁN. Đã đo bằng fontTools:
#
#   Cambria             3265 glyph   latin + tiếng Việt đủ dấu   KHÔNG có 漢字
#   Palatino Linotype   1063 glyph   latin + tiếng Việt đủ dấu   KHÔNG có 漢字
#   Ringbearer           153 glyph   chỉ ASCII — THIẾU CẢ ă ế ư
#
# Mà cả cơ chế của game này là hiện chữ Hán. Nên font không phải MỘT file mà
# là một CHUỖI: font đẹp đi trước, chữ nào nó không có thì rơi xuống font chữ
# Hán của hệ điều hành. Gỡ phần dự phòng đi là mọi tên món đồ thành ô vuông.
#
# Ringbearer thiếu dấu tiếng Việt nên KHÔNG dùng cho chữ nào người đọc —
# giao diện game này là tiếng Việt (luật 2). Để lại ở đây cho nhãn trang trí
# thuần ASCII, và chỉ thế thôi.

const DUONG_CHU_THAN := "res://assets/font/Cambria.ttf"
const DUONG_CHU_DAM := "res://assets/font/PalatinoBold.ttf"
const DUONG_CHU_TRANG_TRI := "res://assets/font/Ringbearer.ttf"

## Tên font chữ Hán của hệ điều hành, xếp theo thứ tự ưu tiên. Godot tự chọn
## cái đầu tiên máy có. Liệt kê cả Windows lẫn Linux vì CI chạy trên Linux.
const FONT_HAN := [
	"Microsoft YaHei UI", "Microsoft YaHei", "Microsoft JhengHei",
	"Noto Sans CJK SC", "Noto Sans CJK TC", "Source Han Sans SC",
	"WenQuanYi Micro Hei", "SimSun", "sans-serif",
]

var chu_than: Font = null        ## chữ thường, dùng khắp nơi
var chu_dam: Font = null         ## tiêu đề, số to
var chu_trang_tri: Font = null   ## CHỈ dùng cho nhãn ASCII, xem ghi chú trên
var chu_han: Font = null         ## font dự phòng, không gọi thẳng

# --- Bảng màu -------------------------------------------------------
#
# Lấy theo bộ asset: đỏ gạch, vàng đồng, nền nâu đen. Đặt một chỗ để đổi tông
# cả game là sửa mấy dòng, không phải lục mười file.

const DO := Color(0.78, 0.16, 0.13)
const DO_SANG := Color(0.94, 0.28, 0.20)
const XANH := Color(0.20, 0.44, 0.82)
const XANH_SANG := Color(0.36, 0.64, 0.96)
const LUC := Color(0.38, 0.66, 0.34)
const VANG := Color(0.92, 0.74, 0.28)
const CHU := Color(0.93, 0.90, 0.84)
const CHU_MO := Color(0.62, 0.59, 0.54)
const NEN := Color(0.07, 0.06, 0.06, 0.92)
const VIEN := Color(0.42, 0.33, 0.22)

## Theme dùng chung. Ai dựng Control thì gán cái này vào node cha cao nhất
## của mình — xem ap_theme().
var theme_chung: Theme = null

var _kho_anh := {}

func _ready() -> void:
	_dung_font()
	_dat_theme()

func _dung_font() -> void:
	chu_han = SystemFont.new()
	(chu_han as SystemFont).font_names = FONT_HAN
	# Không có font Hán nào thì SystemFont vẫn trả về một font nào đó chứ không
	# null, nên không cần canh null ở đây — chỉ là chữ Hán sẽ ra ô vuông, và
	# đó là điều duy nhất còn làm được khi máy thiếu font.
	chu_than = _nap_font(DUONG_CHU_THAN)
	chu_dam = _nap_font(DUONG_CHU_DAM)
	chu_trang_tri = _nap_font(DUONG_CHU_TRANG_TRI)

## Nạp một file font rồi GẮN font chữ Hán vào làm dự phòng.
##
## Thiếu file thì lùi về font chữ Hán luôn: thà xấu còn hơn không đọc được chữ
## nào. Tên món đồ mà mất là mất cả cơ chế xương sống của game.
func _nap_font(duong: String) -> Font:
	if not ResourceLoader.exists(duong):
		push_warning("Thieu font %s — lui ve font he thong" % duong)
		return chu_han
	var f := load(duong) as FontFile
	if f == null:
		return chu_han
	f.fallbacks = [chu_han]
	return f

## Dựng Theme dùng chung.
##
## GÁN VÀO ROOT LÀ KHÔNG ĂN. Đã đo trong Godot 4.7: `get_tree().root.theme = t`
## nhận resource thật, `t.has_stylebox("normal", "Button")` trả true, mà một
## Button bất kỳ vẫn resolve ra StyleBoxFlat mặc định của engine. Nên theme
## phải được gán THẲNG vào một Control tổ tiên — xem ap_theme(), và ManChung
## gọi nó cho mọi màn hình.
##
## Đây không phải chuyện thẩm mỹ. Font mặc định của Godot KHÔNG có chữ Hán, nên
## màn nào không ăn theme thì mọi tên món đồ hiện ra ô vuông — trông y hệt cơ
## chế ??? của game, và vì thế hỏng kiểu đó không ai nhận ra bằng mắt.
func _dat_theme() -> void:
	var t := Theme.new()
	t.default_font = chu_than
	t.default_font_size = 18
	t.set_color("font_color", "Label", CHU)
	_kieu_nut(t)
	theme_chung = t
	# Vẫn gán ở root: không đủ, nhưng không hại, và nếu Godot sửa lại chuyện
	# truyền theme thì chỗ này tự đúng.
	get_tree().root.theme = t

## Gán theme chung cho một Control và cả cây con của nó.
func ap_theme(c: Control) -> void:
	if c != null and theme_chung != null:
		c.theme = theme_chung

## Tên biến thể của nút to kiểu bản mẫu — vệt cọ đỏ. Gán bằng
## `nut.theme_type_variation = GiaoDien.NUT_MENU`.
const NUT_MENU := &"NutMenu"

## Hai kiểu nút, và việc TÁCH chúng ra là bắt buộc.
##
## Vệt cọ đỏ của bản mẫu rất hợp cho bốn cái nút to giữa màn tạm dừng, và rất
## sai cho mọi chỗ khác: màn hành trang dựng MỖI MÓN ĐỒ trong túi thành một
## Button, nên tô đỏ hết thì danh sách đồ biến thành một bức tường vệt sơn và
## chữ bị bóp lại không đọc nổi. Đã thấy tận mắt trong ảnh chụp thử — đó đúng
## là thứ tools/chup_man_hinh.tscn sinh ra để bắt.
##
## Nên `Button` trần là kiểu DANH SÁCH: chìm, gọn, đọc được. Vệt cọ đỏ nằm sau
## một biến thể, và chỉ ai gọi đích danh mới lấy được.
func _kieu_nut(t: Theme) -> void:
	t.set_color("font_color", "Button", CHU)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", CHU_MO)
	t.set_stylebox("normal", "Button", _phang(Color(0.12, 0.11, 0.11, 0.55)))
	t.set_stylebox("hover", "Button", _phang(Color(0.24, 0.16, 0.14, 0.85)))
	t.set_stylebox("pressed", "Button", _phang(Color(0.30, 0.14, 0.12, 0.90)))
	t.set_stylebox("disabled", "Button", _phang(Color(0.10, 0.10, 0.10, 0.35)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# Ảnh nút của bộ này là vệt cọ XÁM — nó vẽ ra để được TÔ MÀU, không phải để
	# dùng trần. Dùng trần thì nút chìm nghỉm vào nền tối.
	var nen := anh("Buttons/Rectangular/Button_RL_Background.png")
	var hover := anh("Buttons/Rectangular/Button_RL_Hover.png")
	if nen == null:
		return
	t.set_type_variation(NUT_MENU, "Button")
	t.set_stylebox("normal", NUT_MENU, _hop(nen, DO))
	t.set_stylebox("hover", NUT_MENU, _hop(hover if hover != null else nen, DO_SANG))
	t.set_stylebox("pressed", NUT_MENU, _hop(hover if hover != null else nen,
		DO.darkened(0.25)))
	t.set_stylebox("disabled", NUT_MENU, _hop(nen, Color(0.32, 0.20, 0.19, 0.6)))
	t.set_stylebox("focus", NUT_MENU, StyleBoxEmpty.new())

## Nền phẳng cho nút danh sách. Không dùng ảnh: ảnh của bộ này có vệt cọ tràn
## ra ngoài mép, mà hàng danh sách thì xếp sát nhau — vệt nọ chồng vệt kia.
func _phang(mau: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = mau
	s.set_corner_radius_all(3)
	s.set_content_margin_all(6)
	s.content_margin_left = 10.0
	s.content_margin_right = 10.0
	return s

## Bọc một ảnh thành StyleBoxTexture co giãn chín ô. Mép 18px: ảnh nút của bộ
## này có vệt cọ ở hai đầu, kéo giãn thẳng là nát vệt.
func _hop(tex: Texture2D, mau: Color = Color.WHITE) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(18)
	s.set_content_margin_all(10)
	s.modulate_color = mau
	return s

# --- Tên phím -------------------------------------------------------

## Tên phím đang gán cho một action, đọc thẳng từ InputMap.
##
## MỌI dòng chữ nói tên phím phải đi qua đây — đừng bao giờ gõ "E" thẳng vào
## một chuỗi. Đã dính: phím tương tác dọn từ E sang F, mà bốn dòng mời trên màn
## chơi vẫn nói "E — nhặt", nên người chơi bấm E và không có gì xảy ra. Không
## test nào bắt được, vì chuỗi đó vẫn là một chuỗi hợp lệ.
func ten_phim(hanh_dong: String) -> String:
	if not InputMap.has_action(hanh_dong):
		return "?"
	# Phím trước, chuột sau: dòng mời trên màn chơi cần MỘT cái tên ngắn, mà
	# "F" đọc nhanh hơn "Chuột phải".
	for su_kien in InputMap.action_get_events(hanh_dong):
		if su_kien is InputEventKey:
			return _ten_mot(su_kien)
	for su_kien in InputMap.action_get_events(hanh_dong):
		if su_kien is InputEventMouseButton:
			return _ten_mot(su_kien)
	return "?"

## Tên MỌI phím của một hoặc nhiều action, nối bằng dấu chấm giữa.
## `danh_sach` ngăn nhau bằng "|", ví dụ "di_truoc|di_trai".
func ten_moi_phim(danh_sach: String) -> String:
	var ra: Array[String] = []
	for ten in danh_sach.split("|"):
		if not InputMap.has_action(ten):
			continue
		for su_kien in InputMap.action_get_events(ten):
			var n := _ten_mot(su_kien)
			if n != "" and not ra.has(n):
				ra.append(n)
	return " · ".join(ra) if not ra.is_empty() else "—"

func _ten_mot(su_kien: InputEvent) -> String:
	if su_kien is InputEventKey:
		var k := su_kien as InputEventKey
		# physical_keycode: bàn phím AZERTY bấm đúng vị trí W vẫn ra "W".
		var ma := k.physical_keycode if k.physical_keycode != 0 else k.keycode
		return OS.get_keycode_string(ma)
	if su_kien is InputEventMouseButton:
		return ten_nut_chuot((su_kien as InputEventMouseButton).button_index)
	return ""

## Tên một nút chuột. Tách ra vì màn Điều khiển cần gọi nó với con số trần —
## phím đang CHỜ xác nhận chưa phải một InputEvent nào cả, mới chỉ là mã lưu.
func ten_nut_chuot(chi_so: int) -> String:
	match chi_so:
		MOUSE_BUTTON_LEFT: return "Chuột trái"
		MOUSE_BUTTON_RIGHT: return "Chuột phải"
		MOUSE_BUTTON_MIDDLE: return "Chuột giữa"
		_: return "Chuột %d" % chi_so

# --- Kho ảnh --------------------------------------------------------

## Lấy một ảnh trong assets/ui theo đường dẫn tương đối, ví dụ:
##   GiaoDien.anh("Minimap/Minimap_Mask.png")
##
## Thiếu ảnh thì trả null chứ KHÔNG dừng game — bên gọi tự lo vẽ thay. Bộ
## asset là thứ bên ngoài repo chép vào, nên phải chịu được cảnh thiếu file.
func anh(duong: String) -> Texture2D:
	if _kho_anh.has(duong):
		return _kho_anh[duong]
	var day := THU_MUC_ANH + duong
	var tex: Texture2D = null
	if ResourceLoader.exists(day):
		tex = load(day) as Texture2D
	if tex == null:
		push_warning("Thieu anh giao dien: %s" % day)
	_kho_anh[duong] = tex
	return tex
