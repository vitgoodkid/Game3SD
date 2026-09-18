class_name ManChet
extends CanvasLayer

## Màn "BẠN ĐÃ CHẾT" — khoảnh khắc kiểu Elden Ring.
##
## Ba thứ nó phải làm, và cả ba đều là quyết định thiết kế chứ không phải trang trí:
##
## 1. **KHÔNG che cái xác.** Nền chỉ tối đi, không đặc. Người chơi cần thấy mình
##    ngã kiểu gì — dáng ngã là thứ duy nhất nói cho họ biết đòn chí mạng tới
##    từ đâu, và đó là thông tin để lần sau đứng khác đi.
## 2. **KHÔNG tự tắt.** Đợi người chơi bấm phím, không đợi đồng hồ. Đây là chỗ
##    duy nhất trong game người chơi được ngồi im bao lâu tuỳ họ; cướp mất bằng
##    một cái hẹn giờ là cướp luôn nhịp nghỉ giữa hai lần thử.
## 3. **KHÔNG nhận phím ngay.** Đợi `TrangThaiChet.T_HIEN` rồi mới cho bấm.
##    Người chơi lúc chết thường đang giữ phím; nhận ngay là màn hình loé lên
##    rồi biến mất, và họ tưởng game nuốt mất.
##
## Chữ "BẠN ĐÃ CHẾT" hiện dần chứ không bật ra: hiện dần làm cái chết nặng hơn,
## mà nặng là đúng — chết trong souls-like phải thấy mất mát.

## Cỡ chữ ở chiều cao màn hình chuẩn 1080. Tự co theo màn hình thật, nên cửa sổ
## nhỏ không làm dòng chữ tràn ra ngoài.
const CO_CHET := 108
const CO_NHAC := 26
const CAO_CHUAN := 1080.0

## Đỏ sẫm ngả vàng — màu của chữ "YOU DIED", không phải đỏ máu tươi. Đỏ tươi
## trên nền tối đọc thành cảnh báo lỗi, không thành bi kịch.
const MAU_CHET := Color(0.62, 0.11, 0.09)
const MAU_NHAC := Color(0.70, 0.66, 0.58)
const MAU_NEN := Color(0.0, 0.0, 0.0, 0.55)

## Chữ hiện dần trong bấy nhiêu giây.
const T_HIEN_DAN := 1.1

var _goc: Control = null
var _nen: ColorRect = null
var _chu: Label = null
var _nhac: Label = null
var _nc: Node = null
var _mo := 0.0
var _dang_chet := false

func _ready() -> void:
	layer = 90            # trên HUD, dưới màn tạm dừng
	add_to_group("man_chet")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dung_giao_dien()
	_an_ngay()

func _dung_giao_dien() -> void:
	_goc = Control.new()
	_goc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_goc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GiaoDien.ap_theme(_goc)
	add_child(_goc)

	_nen = ColorRect.new()
	_nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nen.color = MAU_NEN
	_nen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goc.add_child(_nen)

	_chu = _tao_chu(GiaoDien.chu_trang_tri, CO_CHET, MAU_CHET)
	_chu.text = "BẠN ĐÃ CHẾT"
	_goc.add_child(_chu)

	_nhac = _tao_chu(GiaoDien.chu_than, CO_NHAC, MAU_NHAC)
	_nhac.text = "Bấm phím bất kỳ để tiếp tục"
	_goc.add_child(_nhac)

func _tao_chu(phong: Font, co: int, mau: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if phong != null:
		l.add_theme_font_override("font", phong)
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	# Viền tối quanh chữ: nền là cảnh game thật, sáng tối chỗ nào không biết
	# trước, nên không có viền thì có map chữ đỏ chìm hẳn vào nền.
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l

func _an_ngay() -> void:
	_mo = 0.0
	_dang_chet = false
	_goc.visible = false

func _process(delta: float) -> void:
	if _nc == null:
		_nc = get_tree().get_first_node_in_group("nguoi_choi")
		if _nc != null and _nc.has_signal("da_chet"):
			_nc.da_chet.connect(_khi_chet)
	if not _dang_chet:
		return
	# Người chơi có thể sống lại bằng đường khác (bia đá, lệnh gỡ lỗi). Bám
	# theo state thật chứ không tự giữ cờ — cờ tự giữ là chỗ màn hình chết kẹt
	# lại trên đầu một nhân vật đang chạy nhảy bình thường.
	if _tt_chet() == null:
		_an_ngay()
		return
	_mo = minf(1.0, _mo + delta / T_HIEN_DAN)
	_xep()

func _khi_chet() -> void:
	_dang_chet = true
	_mo = 0.0
	_goc.visible = true
	_xep()

## Trạng thái `chet` đang chạy, null nếu người chơi không còn nằm đó.
func _tt_chet() -> Node:
	if _nc == null:
		return null
	var may = _nc.get("may")
	if may == null or may.ten_hien_tai != "chet":
		return null
	return may.hien_tai

func _xep() -> void:
	var co := get_viewport().get_visible_rect().size
	var k := co.y / CAO_CHUAN
	_chu.add_theme_font_size_override("font_size", int(CO_CHET * k))
	_nhac.add_theme_font_size_override("font_size", int(CO_NHAC * k))
	# Xếp theo CHIỀU CAO THẬT của ô chữ, không theo cỡ font.
	#
	# Bản đầu đặt dòng nhắc ở "cỡ font × 0.6" phía dưới và nó nằm ĐÈ lên chính
	# giữa dòng chữ to — vì Label căn giữa theo chiều dọc trong ô của nó, nên
	# gốc toạ độ của ô không phải là mép trên của nét chữ. Chỉ nhìn ảnh mới
	# thấy; không phép thử nào đọc ra được hai dòng chữ chồng nhau.
	var cao_chu := CO_CHET * k * 1.35
	var cao_nhac := CO_NHAC * k * 2.0
	var tren := co.y * 0.42 - cao_chu * 0.5
	_chu.position = Vector2(0, tren)
	_chu.size = Vector2(co.x, cao_chu)
	_nhac.position = Vector2(0, tren + cao_chu + 10.0 * k)
	_nhac.size = Vector2(co.x, cao_nhac)

	_nen.color = Color(MAU_NEN.r, MAU_NEN.g, MAU_NEN.b, MAU_NEN.a * _mo)
	_chu.modulate.a = _mo
	# Dòng nhắc chỉ hiện khi ĐÃ BẤM ĐƯỢC. Hiện sớm hơn là nói dối người chơi:
	# họ bấm, không có gì xảy ra, và họ kết luận game treo.
	_nhac.modulate.a = 1.0 if _bam_duoc() else 0.0

func _bam_duoc() -> bool:
	var tt := _tt_chet()
	return tt != null and tt.has_method("san_sang") and bool(tt.call("san_sang"))

func _unhandled_input(su_kien: InputEvent) -> void:
	if not _dang_chet or not _bam_duoc():
		return
	# "Phím bất kỳ" gồm cả chuột và tay cầm, nhưng KHÔNG gồm di chuyển chuột —
	# không thì lắc chuột một cái là hồi sinh trước khi kịp đọc dòng chữ.
	var bam: bool = (su_kien is InputEventKey and su_kien.pressed) \
		or (su_kien is InputEventMouseButton and su_kien.pressed) \
		or (su_kien is InputEventJoypadButton and su_kien.pressed)
	if not bam:
		return
	get_viewport().set_input_as_handled()
	tiep_tuc()

## Đứng dậy. Công khai để bộ kiểm tra gọi đúng con đường mà phím đi.
func tiep_tuc() -> void:
	var tt := _tt_chet()
	if tt == null or not _bam_duoc():
		return
	tt.call("hoi_sinh")
	_an_ngay()

## Màn đang hiện chữ không — cửa cho bộ kiểm tra.
func dang_hien() -> bool:
	return _dang_chet and _goc != null and _goc.visible
