class_name ManChung
extends CanvasLayer

## Gốc chung của mọi màn hình che toàn màn (hành trang, bia đá).
##
## Gom ba việc mà màn nào cũng phải làm đúng, và làm sai là khó chịu ngay:
##   1. Mở màn thì thả chuột ra, đóng thì bắt lại. Quên là không bấm được nút.
##   2. Dừng game khi mở. Souls-like KHÔNG dừng lúc đang đánh, nhưng bia đá và
##      hành trang là chỗ an toàn nên dừng được — và phải dừng, không thì đọc
##      bảng chỉ số trong lúc quái gặm chân.
##   3. Đóng bằng Esc, và Esc KHÔNG được rơi xuống dưới thành thả chuột.
##
## Màn con cài nội dung bằng cách override `dung_noi_dung(khung)`.

signal da_mo
signal da_dong

const MAU_NEN := Color(0.06, 0.06, 0.07, 0.94)
const MAU_VIEN := Color(0.32, 0.30, 0.27)
const MAU_CHU := Color(0.92, 0.90, 0.85)
const MAU_CHU_MO := Color(0.55, 0.53, 0.50)
const MAU_NHAN := Color(0.72, 0.68, 0.60)

var dang_mo := false
var khung: MarginContainer = null
var _nen: ColorRect = null
var _tieu_de: Label = null

func _ready() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # chạy được cả khi game đang dừng

	_nen = ColorRect.new()
	_nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nen.color = MAU_NEN
	add_child(_nen)

	var ngoai := MarginContainer.new()
	ngoai.set_anchors_preset(Control.PRESET_FULL_RECT)
	ngoai.add_theme_constant_override("margin_left", 48)
	ngoai.add_theme_constant_override("margin_right", 48)
	ngoai.add_theme_constant_override("margin_top", 32)
	ngoai.add_theme_constant_override("margin_bottom", 32)
	add_child(ngoai)

	var doc := VBoxContainer.new()
	doc.add_theme_constant_override("separation", 12)
	ngoai.add_child(doc)

	_tieu_de = Label.new()
	_tieu_de.add_theme_font_size_override("font_size", 30)
	_tieu_de.add_theme_color_override("font_color", MAU_CHU)
	doc.add_child(_tieu_de)

	var vach := HSeparator.new()
	doc.add_child(vach)

	khung = MarginContainer.new()
	khung.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doc.add_child(khung)

	var duoi := Label.new()
	duoi.text = "Esc — đóng"
	duoi.add_theme_font_size_override("font_size", 15)
	duoi.add_theme_color_override("font_color", MAU_CHU_MO)
	doc.add_child(duoi)

	dung_noi_dung(khung)

## Màn con override hàm này. `cha` là chỗ nhét nội dung vào.
func dung_noi_dung(_cha: MarginContainer) -> void:
	pass

## Màn con override để đổi lại dữ liệu mỗi lần mở.
func lam_moi() -> void:
	pass

func dat_tieu_de(s: String) -> void:
	if _tieu_de != null:
		_tieu_de.text = s

# --- Mở / đóng ------------------------------------------------------

func mo() -> void:
	if dang_mo:
		return
	dang_mo = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lam_moi()
	da_mo.emit()

func dong() -> void:
	if not dang_mo:
		return
	dang_mo = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	da_dong.emit()

func bat_tat() -> void:
	if dang_mo:
		dong()
	else:
		mo()

func _unhandled_input(su_kien: InputEvent) -> void:
	if not dang_mo:
		return
	if su_kien.is_action_pressed("thoat") or su_kien.is_action_pressed("hanh_trang"):
		dong()
		# Nuốt phím, không thì Esc rơi xuống camera và thả luôn chuột.
		get_viewport().set_input_as_handled()

# --- Tiện tay cho màn con -------------------------------------------

func chu(noi_dung: String, co := 18, mau := MAU_CHU) -> Label:
	var l := Label.new()
	l.text = noi_dung
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	return l

func nut(nhan: String, khi_bam: Callable, bat := true) -> Button:
	var b := Button.new()
	b.text = nhan
	b.disabled = not bat
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(khi_bam)
	return b

func khung_vien() -> PanelContainer:
	var p := PanelContainer.new()
	var kt := StyleBoxFlat.new()
	kt.bg_color = Color(0.10, 0.10, 0.11, 0.9)
	kt.border_color = MAU_VIEN
	kt.set_border_width_all(1)
	kt.set_corner_radius_all(3)
	kt.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", kt)
	return p

func cuon(con: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	con.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(con)
	return s

## Xoá sạch con của một node. Dùng lúc lam_moi() dựng lại danh sách.
func don(cha: Node) -> void:
	for c in cha.get_children():
		c.queue_free()
