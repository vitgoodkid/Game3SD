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

## Màn đang mở. Tĩnh vì luật là của cả game: mở được ĐÚNG MỘT màn cùng lúc.
## Không có luật này thì đứng ở bia đá bấm I là hành trang chồng lên bia đá,
## đóng một cái thì cái kia vẫn đó mà game đã chạy lại rồi.
static var dang_mo_man: ManChung = null

## Cỡ chữ tiêu đề màn hình. To hẳn so với chữ thường: đây là thứ duy nhất trên
## màn che toàn màn nói cho người chơi biết họ đang ở đâu.
const CO_TIEU_DE := 54

const MAU_NEN := Color(0.06, 0.06, 0.07, 0.94)
const MAU_VIEN := Color(0.32, 0.30, 0.27)
const MAU_CHU := Color(0.92, 0.90, 0.85)
const MAU_CHU_MO := Color(0.55, 0.53, 0.50)
const MAU_NHAN := Color(0.72, 0.68, 0.60)

var dang_mo := false
## Lần vẽ gần nhất có chạy tới dòng cuối không.
##
## GDScript không ném lỗi: hàm vẽ gãy giữa chừng thì màn hình hiện một nửa và
## trông y như bình thường, chỉ thiếu mấy dòng cuối. Cờ này là thứ duy nhất
## giúp bộ kiểm tra phân biệt "vẽ xong" với "vẽ được một nửa rồi chết".
var ve_xong := false
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
	# Theme gán ở ĐÂY chứ không ở root — gán ở root thì Godot 4.7 không truyền
	# xuống, xem GiaoDien._dat_theme(). Gán ở node cha cao nhất của màn thì cả
	# cây con ăn theo, kể cả font chữ Hán.
	GiaoDien.ap_theme(ngoai)
	ngoai.set_anchors_preset(Control.PRESET_FULL_RECT)
	ngoai.add_theme_constant_override("margin_left", 64)
	ngoai.add_theme_constant_override("margin_right", 64)
	ngoai.add_theme_constant_override("margin_top", 40)
	ngoai.add_theme_constant_override("margin_bottom", 36)
	add_child(ngoai)

	var doc := VBoxContainer.new()
	doc.add_theme_constant_override("separation", 12)
	ngoai.add_child(doc)

	# Tiêu đề GIỮA và to. Nằm ở mép trái như bản trước thì trên màn rộng nó bị
	# đẩy ra tận góc, cách nội dung (vốn ở giữa) cả ngàn pixel — mắt đọc xong
	# tiêu đề rồi phải quét ngang cả màn hình mới tới thứ mình cần bấm.
	_tieu_de = Label.new()
	_tieu_de.add_theme_font_size_override("font_size", CO_TIEU_DE)
	_tieu_de.add_theme_color_override("font_color", MAU_CHU)
	_tieu_de.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doc.add_child(_tieu_de)

	var vach := HSeparator.new()
	doc.add_child(vach)

	khung = MarginContainer.new()
	khung.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doc.add_child(khung)

	var duoi := Label.new()
	duoi.text = "Esc — đóng"
	duoi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duoi.add_theme_font_size_override("font_size", 20)
	duoi.add_theme_color_override("font_color", MAU_CHU_MO)
	doc.add_child(duoi)

	dung_noi_dung(khung)

## Màn con override hàm này. `cha` là chỗ nhét nội dung vào.
func dung_noi_dung(_cha: MarginContainer) -> void:
	pass

## Màn con override để đổi lại dữ liệu mỗi lần mở.
func lam_moi() -> void:
	pass

## Phím tự mở màn này. Để rỗng thì màn chỉ mở bằng code — bia đá mở lúc bấm E
## đứng cạnh bia, nó không có phím riêng.
func phim_mo_man() -> String:
	return ""

func dat_tieu_de(s: String) -> void:
	if _tieu_de != null:
		_tieu_de.text = s

# --- Mở / đóng ------------------------------------------------------

func mo() -> void:
	if dang_mo:
		return
	# Đang mở màn khác thì thôi — xem dang_mo_man ở đầu file.
	if dang_mo_man != null and is_instance_valid(dang_mo_man):
		return
	dang_mo = true
	dang_mo_man = self
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lam_moi()
	da_mo.emit()

func dong() -> void:
	if not dang_mo:
		return
	dang_mo = false
	if dang_mo_man == self:
		dang_mo_man = null
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	da_dong.emit()

func bat_tat() -> void:
	if dang_mo:
		dong()
	else:
		mo()

## Màn bị xoá lúc đang mở (đổi scene) thì phải nhả game ra, không thì scene sau
## nạp lên trong trạng thái dừng và không ai biết vì sao.
func _exit_tree() -> void:
	if dang_mo_man == self:
		dang_mo_man = null
		get_tree().paused = false

func _unhandled_input(su_kien: InputEvent) -> void:
	var phim := phim_mo_man()
	if not dang_mo:
		if phim != "" and su_kien.is_action_pressed(phim) and dang_mo_man == null:
			mo()
			get_viewport().set_input_as_handled()
		return
	if su_kien.is_action_pressed("thoat") or (phim != "" and su_kien.is_action_pressed(phim)):
		dong()
		# Nuốt phím, không thì Esc rơi xuống camera và thả luôn chuột.
		get_viewport().set_input_as_handled()

# --- Tiện tay cho màn con -------------------------------------------

func chu(noi_dung: String, co := 22, mau := MAU_CHU) -> Label:
	var l := Label.new()
	l.text = noi_dung
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	return l

func nut(nhan: String, khi_bam: Callable, bat := true) -> Button:
	var b := Button.new()
	b.text = nhan
	b.disabled = not bat
	b.add_theme_font_size_override("font_size", 21)
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
##
## Gỡ khỏi cây TRƯỚC rồi mới queue_free: queue_free chỉ đánh dấu, node vẫn còn
## nằm đó tới hết khung hình. Chỉ gọi queue_free thì trong khung hình đó
## container xếp cả hàng cũ lẫn hàng mới, và danh sách nhấp nháy đôi.
func don(cha: Node) -> void:
	for c in cha.get_children():
		cha.remove_child(c)
		c.queue_free()
