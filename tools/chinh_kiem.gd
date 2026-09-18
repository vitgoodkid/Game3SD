extends Node3D

## CHỈNH THẾ CẦM VŨ KHÍ bằng tay, thấy đổi ngay.
##
##     godot --path . tools/chinh_kiem.tscn     (KHÔNG chạy được với --headless)
##
## Trong Godot: mở scene này rồi bấm **F6** (Run Current Scene). Mở ra XEM thì
## nó rỗng — nhân vật, đèn và camera đều dựng lúc chạy. F5 là chạy scene
## chính của game, không phải cái này.
##
## Vì sao cần một màn riêng thay vì kéo số trong tab Remote:
##
##   1. Thế cầm chỉ ĐỌC ĐƯỢC khi so với tư thế. Kiếm cầm đúng ở dáng đứng có
##      thể chĩa ra sau lưng ở dáng chạy — đã dính đúng chuyện đó. Ở đây đổi
##      tư thế bằng một phím, không phải chơi tới chỗ có con quái.
##   2. Có BA thế cầm (chiến đấu, vác lúc rảnh, treo sau lưng) mà tab Remote
##      bày cả ba cùng lúc, không nói cái nào đang hiện.
##   3. Bấm P là in ra đúng mấy dòng để dán thẳng vào `than_mo_hinh.gd`. Không
##      có nó thì chỉnh xong vẫn phải chép tay từng con số, và chép sai một
##      dấu trừ là mất cả buổi.
##
## MỖI VIỆC CÓ HAI PHÍM, và bảng phím nằm NGAY TRÊN danh sách ô.
##
## Bản đầu chỉ có Tab để chọn dòng, và dòng nhắc nằm lẫn trong một câu dài ở
## cuối màn. Chủ dự án chạy lên rồi hỏi "chỉnh Y Z thế nào, tìm không thấy" —
## phím thì có, nhưng không ai đọc dòng cuối màn khi đang nhìn thanh kiếm.
##
## Số chỉnh ở đây KHÔNG tự lưu vào file — cố ý. Đây là bàn thử, không phải chỗ
## cất kết quả; muốn giữ thì bấm P rồi dán vào code.

const CANH_NC := preload("res://scenes/nhan_vat/nguoi_choi.tscn")
const CHU_VU_KHI := "刃"

## Mỗi dòng: tên hiện lên, trạng thái, tiến độ, đang đi, kiểu đòn, đã rút.
const TU_THE := [
	["đứng yên", "dung", 0.0, false, "", true],
	["đi", "di", 0.35, true, "", true],
	["chạy", "chay_nhanh", 0.35, true, "", true],
	["đòn nhẹ", "danh", 0.45, false, "nhe_1", true],
	["đòn Bổ", "danh", 0.45, false, "nang", true],
	["giơ thủ", "do_don", 0.3, false, "", true],
	["đã cất", "dung", 0.0, false, "", false],
]

## Thế cầm nào đang chỉnh, và nó gắn với cặp thuộc tính nào.
const THE_CAM := [
	["TRÊN TAY (đứng, đánh, thủ)",
		"vu_khi_xoay", "vu_khi_lech", "vu_khi_lan"],
	["ĐI / CHẠY",
		"vu_khi_xoay_chay", "vu_khi_lech_chay", "vu_khi_lan_chay"],
	["SAU LƯNG (đã cất)",
		"vu_khi_xoay_lung", "vu_khi_lech_lung", "vu_khi_lan_lung"],
]

## Các ô chỉnh được, theo thứ tự lên xuống.
const O := ["xoay X", "xoay Y", "xoay Z", "lăn lưỡi",
	"lệch X", "lệch Y", "lệch Z", "dài (m)"]
## Bước nhảy: [góc theo độ, lệch theo mét, dài theo mét] × [nhỏ, vừa, lớn].
const BUOC := [[1.0, 5.0, 15.0], [0.005, 0.02, 0.05], [0.02, 0.05, 0.15]]
const TEN_BUOC := ["nhỏ", "vừa", "lớn"]

const XA_GAN := 1.1
const XA_XA := 8.0

var _nc: Node3D = null
var _than: Node = null
var _nhan: Label = null
var _cam: Camera3D = null
var _tu_the := 0
var _the := 1          ## bắt đầu ở thế RẢNH: đó là thế hay phải chỉnh nhất
var _o := 0
var _buoc := 1
var _goc_cam := 0.6
var _cao_cam := 0.25
var _xa := 3.2
var _keo := false

func _ready() -> void:
	# Dòng nhắc chỉ để nhìn thấy trong TRÌNH SOẠN THẢO. Scene này rỗng khi mở
	# ra xem — nó tự dựng nhân vật, đèn, camera lúc CHẠY — nên không có dòng
	# nhắc thì người mở nó ra chỉ thấy một khung lưới trống và tưởng hỏng.
	var nhac := get_node_or_null("NhacChay")
	if nhac != null:
		nhac.queue_free()
	get_window().size = Vector2i(980, 740)
	_dung_canh()
	var vk := SinhMonDo.sinh_mon_tu_chu(CHU_VU_KHI, "thi_tran", 1000)
	if vk != null:
		Tui.nhat(vk)
		Tui.mac_vao(vk, "vu_khi", 0)
		Tui.tay_phai_dang = 0

	_nc = CANH_NC.instantiate() as Node3D
	add_child(_nc)
	await get_tree().process_frame
	await get_tree().process_frame
	_than = _nc.get_node_or_null("Than")
	if _than == null or not _than.has_method("dien"):
		push_error("Khong tim thay Than co dien()")
		get_tree().quit(1)
		return
	# Máy trạng thái chạy song song sẽ ghi đè tư thế mỗi khung.
	_nc.set_physics_process(false)
	var cam := _nc.get_node_or_null("GiaCamera")
	if cam != null:
		cam.queue_free()      # camera của game tranh quyền với camera ở đây
	_ve_nhan()

func _dung_canh() -> void:
	var den := DirectionalLight3D.new()
	den.rotation_degrees = Vector3(-38, -35, 0)
	den.light_energy = 1.5
	add_child(den)
	var mt := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.22, 0.24, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.74, 0.80)
	e.ambient_light_energy = 0.6
	mt.environment = e
	add_child(mt)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)

	var lop := CanvasLayer.new()
	add_child(lop)
	# Nền tối sau chữ. Nhân vật đi qua sau bảng số là chữ chìm hẳn vào tóc đỏ —
	# và lúc đó đúng là lúc đang cần đọc số nhất.
	var nen := ColorRect.new()
	nen.color = Color(0.05, 0.05, 0.07, 0.74)
	nen.position = Vector2.ZERO
	nen.size = Vector2(340, 500)
	nen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lop.add_child(nen)
	_nhan = Label.new()
	_nhan.position = Vector2(14, 10)
	_nhan.add_theme_font_size_override("font_size", 15)
	_nhan.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
	GiaoDien.ap_theme(_nhan)
	lop.add_child(_nhan)

func _process(delta: float) -> void:
	if _than == null:
		return
	var tt: Array = TU_THE[_tu_the]
	_than.call("dat_da_rut", bool(tt[5]))
	_than.call("dien", String(tt[1]), float(tt[2]), bool(tt[3]), delta,
		String(tt[4]), 1.0)
	# Tua clip tới đúng chỗ rồi dừng: không tua thì mọi cú vung đều bị bắt ở
	# một thời điểm, và cái cần nhìn là thế cầm ở ĐỈNH cú vung.
	var may := _tim_may(_than)
	if may != null and may.is_playing():
		var a := may.get_animation(may.current_animation)
		if a != null:
			may.seek(a.length * clampf(float(tt[2]), 0.0, 1.0), true)
			may.pause()
	_dat_camera()

func _dat_camera() -> void:
	var tam := _nc.global_position + Vector3(0, 1.0, 0)
	_cam.global_position = tam + Vector3(sin(_goc_cam) * _xa,
		_cao_cam * _xa, cos(_goc_cam) * _xa)
	_cam.look_at(tam, Vector3.UP)

# --- Bấm phím ------------------------------------------------------

func _unhandled_input(su_kien: InputEvent) -> void:
	if su_kien is InputEventMouseButton:
		var nut := su_kien as InputEventMouseButton
		if nut.button_index == MOUSE_BUTTON_LEFT:
			_keo = nut.pressed
		elif nut.pressed and nut.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-1.0)
			_ve_nhan()
		elif nut.pressed and nut.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0)
			_ve_nhan()
		return
	if su_kien is InputEventMouseMotion and _keo:
		var re := su_kien as InputEventMouseMotion
		_goc_cam -= re.relative.x * 0.008
		_cao_cam = clampf(_cao_cam + re.relative.y * 0.004, -0.35, 0.9)
		return
	if not (su_kien is InputEventKey) or not su_kien.pressed or su_kien.echo:
		return
	# MỖI VIỆC HAI PHÍM: mũi tên cho người đang rời tay khỏi bàn phím, WASD cho
	# người vẫn đặt tay ở đó. Tab giữ lại vì nhiều người bấm quen tay.
	match (su_kien as InputEventKey).keycode:
		KEY_SPACE:
			_tu_the = (_tu_the + 1) % TU_THE.size()
			# Tư thế nào dùng thế cầm nào là do CODE quyết, không do người
			# chỉnh chọn. Cho chọn lệch nhau thì sẽ có lúc kéo số mỏi tay mà
			# thanh kiếm đứng im — vì cái đang sửa không phải cái đang hiện.
			_the = _the_cua_tu_the(_tu_the)
		KEY_1, KEY_2, KEY_3:
			_the = (su_kien as InputEventKey).keycode - KEY_1
			# Nhảy tới tư thế đầu tiên có dùng thế cầm vừa chọn.
			for i in TU_THE.size():
				if _the_cua_tu_the(i) == _the:
					_tu_the = i
					break
		KEY_UP, KEY_W:
			_chon(-1)
		KEY_DOWN, KEY_S, KEY_TAB:
			_chon(1)
		KEY_LEFT, KEY_A, KEY_MINUS:
			_doi(-1.0)
		KEY_RIGHT, KEY_D, KEY_EQUAL:
			_doi(1.0)
		KEY_BRACKETLEFT:
			_buoc = maxi(0, _buoc - 1)
		KEY_BRACKETRIGHT:
			_buoc = mini(BUOC[0].size() - 1, _buoc + 1)
		KEY_Z:
			_zoom(-1.0)
		KEY_X:
			_zoom(1.0)
		KEY_P:
			_in_ra()
		KEY_ESCAPE:
			get_tree().quit()
	_ve_nhan()

func _chon(dau: int) -> void:
	_o = (_o + dau + O.size()) % O.size()

## Phóng to / thu nhỏ. NHÂN chứ không cộng: ở xa thì mỗi nấc phải đi xa hơn,
## không thì kéo từ 8m về 1m mất mấy chục nấc lăn chuột.
func _zoom(dau: float) -> void:
	_xa = clampf(_xa * (1.12 if dau > 0.0 else 1.0 / 1.12), XA_GAN, XA_XA)

## Đổi giá trị ô đang chọn. Ghi thẳng vào thuộc tính của `Than` — nó có setter
## nên thanh kiếm đổi ngay trong khung hình này.
func _doi(dau: float) -> void:
	var xoay := String(THE_CAM[_the][1])
	var lech := String(THE_CAM[_the][2])
	if _o <= 2:
		var v: Vector3 = _than.get(xoay)
		v[_o] += dau * float(BUOC[0][_buoc])
		_than.set(xoay, v)
	elif _o == 3:
		var ten_lan := String(THE_CAM[_the][3])
		_than.set(ten_lan, float(_than.get(ten_lan)) + dau * float(BUOC[0][_buoc]))
	elif _o <= 6:
		var w: Vector3 = _than.get(lech)
		w[_o - 4] += dau * float(BUOC[1][_buoc])
		_than.set(lech, w)
	else:
		_than.set("vu_khi_dai", maxf(0.2, float(_than.get("vu_khi_dai"))
			+ dau * float(BUOC[2][_buoc])))

## Tư thế `i` đang cầm kiếm ở thế nào. Chép đúng luật của `ThanMoHinh.dien()`:
## đã cất thì treo sau lưng, `dung` thì vác lên, còn lại là thế chiến đấu.
func _the_cua_tu_the(i: int) -> int:
	var tt: Array = TU_THE[i]
	if not bool(tt[5]):
		return 2
	return 1 if String(tt[1]) in ThanMoHinh.TT_DI_CHUYEN else 0

func _ve_nhan() -> void:
	if _nhan == null or _than == null:
		return
	var xoay: Vector3 = _than.get(String(THE_CAM[_the][1]))
	var lech: Vector3 = _than.get(String(THE_CAM[_the][2]))
	var gt := [xoay.x, xoay.y, xoay.z, float(_than.get(String(THE_CAM[_the][3]))),
		lech.x, lech.y, lech.z, float(_than.get("vu_khi_dai"))]
	var d := ""
	d += "[Space]  tư thế:   %s\n" % String(TU_THE[_tu_the][0])
	d += "[1/2/3]  thế cầm:  %s\n" % String(THE_CAM[_the][0])
	d += "         (tư thế và thế cầm luôn đi cùng nhau)\n\n"
	# Bảng phím nằm NGAY TRÊN danh sách ô, không nhét xuống cuối màn.
	d += "  W S  hoặc  ↑ ↓   chọn dòng\n"
	d += "  A D  hoặc  ← →   giảm / tăng dòng đang chọn\n"
	d += "  [  ]             bước nhảy: %s\n\n" % TEN_BUOC[_buoc]
	for i in O.size():
		var dau := "►" if i == _o else "  "
		var dv := "°" if i <= 3 else "m"
		d += "%s %-10s %9.3f%s\n" % [dau, O[i], gt[i], dv]
	d += "\n"
	d += "  Z X  hoặc lăn chuột   phóng to / nhỏ (%.1fm)\n" % _xa
	d += "  giữ chuột trái + rê   xoay quanh nhân vật\n\n"
	d += "[P] in ra để dán vào code     [Esc] thoát"
	_nhan.text = d

## In ra đúng mấy dòng để dán vào `than_mo_hinh.gd`.
func _in_ra() -> void:
	print("")
	print("--- dán vào scripts/nhan_vat/than_mo_hinh.gd ---")
	for bo in THE_CAM:
		var v: Vector3 = _than.get(String(bo[1]))
		var w: Vector3 = _than.get(String(bo[2]))
		print("@export var %s := Vector3(%.1f, %.1f, %.1f)" % [bo[1], v.x, v.y, v.z])
		print("@export var %s := Vector3(%.3f, %.3f, %.3f)" % [bo[2], w.x, w.y, w.z])
		print("@export var %s := %.1f" % [bo[3], float(_than.get(String(bo[3])))])
	print("@export var vu_khi_dai := %.2f" % float(_than.get("vu_khi_dai")))
	print("------------------------------------------------")

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null
