extends CanvasLayer

## HUD. Vẽ bằng code trong _draw() thay vì dựng cây Control trong editor —
## ba thanh và mấy chỉ báo thì vẽ tay ngắn hơn, và quan trọng hơn: sửa được
## từ điện thoại mà không cần mở editor.
##
## Bốn thứ ở đây là YÊU CẦU BẮT BUỘC của mục 8 (camera ba chế độ), không phải
## trang trí:
##   - chỉ báo hướng bị đánh (vệt đỏ rìa màn hình) — không có thì góc nhìn
##     thứ nhất không chơi được, vì không thấy đòn từ sau lưng
##   - mũi tên chỉ mục tiêu đang khoá khi ở góc nhìn thứ nhất
##   - chấm ngắm mờ ở đúng tầm với vũ khí đang cầm
##   - tên chế độ camera khi vừa bấm F5

const CAO_THANH := 16.0
const LE := 28.0

const MAU_MAU := Color(0.72, 0.16, 0.18)
const MAU_MAU_NEN := Color(0.16, 0.08, 0.08, 0.85)
const MAU_TL := Color(0.38, 0.66, 0.34)
const MAU_TU_THE := Color(0.92, 0.74, 0.28)
const MAU_CHU := Color(0.94, 0.92, 0.86)

var nc: NguoiChoi = null
var _ve: Control = null
var _bao: Label = null
var _t_bao := 0.0
## Hướng vừa bị đánh từ đâu tới, và còn hiện bao lâu.
var _huong_danh: Array = []
## Máu "trễ" — thanh trắng tụt chậm phía sau, cho thấy vừa mất bao nhiêu.
var _mau_tre := 1.0
## Boss đang đánh nhau với mình. Thanh máu của nó nằm dưới đáy màn hình, kiểu
## souls — to, một thanh duy nhất, tên chữ Hán ở trên.
var _boss: Boss = null
var _boss_tre := 1.0

func _ready() -> void:
	layer = 10
	# Bia đá, món đồ rơi, vũng hồn đều nhắn qua đây. Tìm bằng nhóm chứ không
	# bằng đường dẫn node, để đặt HUD ở đâu trong scene cũng được.
	add_to_group("hud")
	_ve = Control.new()
	_ve.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ve.draw.connect(_ve_het)
	add_child(_ve)

	_bao = Label.new()
	_bao.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_bao.position = Vector2(-220, 64)
	_bao.custom_minimum_size = Vector2(440, 0)
	_bao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bao.modulate = Color(1, 1, 1, 0)
	add_child(_bao)

	await get_tree().process_frame
	_tim_nguoi_choi()

func _tim_nguoi_choi() -> void:
	nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi
	if nc == null:
		return
	nc.bao_ngu_hanh.connect(bao)
	nc.bi_danh.connect(bi_danh_tu)
	var cam := nc.get_node_or_null("GiaCamera") as CameraBaCheDo
	if cam != null:
		cam.doi_che_do.connect(func(_c): bao(cam.ten_che_do()))

func _process(delta: float) -> void:
	if nc == null:
		_tim_nguoi_choi()
		return
	var ti := nc.mau / maxf(nc.mau_toi_da, 1.0)
	_mau_tre = maxf(ti, _mau_tre - delta * 0.35)
	if _mau_tre < ti:
		_mau_tre = ti
	_tut_mau_boss(delta)

	for i in range(_huong_danh.size() - 1, -1, -1):
		_huong_danh[i]["t"] = float(_huong_danh[i]["t"]) - delta
		if float(_huong_danh[i]["t"]) <= 0.0:
			_huong_danh.remove_at(i)

	if _t_bao > 0.0:
		_t_bao -= delta
		_bao.modulate.a = clampf(_t_bao, 0.0, 1.0)

	_ve.queue_redraw()

## Hiện một dòng thông báo ngắn giữa trên màn hình (ngũ hành, đổi camera...).
## Thanh trắng của boss tụt chậm phía sau, y như của người chơi — đó là thứ
## cho thấy cú vừa rồi ăn được bao nhiêu trên một thanh máu rất dài.
func _tut_mau_boss(delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var ti := _boss.mau / maxf(_boss.mau_toi_da, 1.0)
	_boss_tre = maxf(ti, _boss_tre - delta * 0.28)

func bao(dong: String) -> void:
	if dong.strip_edges().is_empty():
		return
	_bao.text = dong
	_t_bao = 2.2
	_bao.modulate.a = 1.0

## Gọi khi ăn đòn — vẽ vệt đỏ ở rìa màn hình về phía nguồn đòn.
## BẮT BUỘC ở góc nhìn thứ nhất, nơi không thấy gì phía sau lưng (mục 8).
func bi_danh_tu(vi_tri: Vector3) -> void:
	if nc == null:
		return
	var v := vi_tri - nc.global_position
	v.y = 0.0
	_huong_danh.append({"huong": v.normalized(), "t": 1.1})

# --- Vẽ -------------------------------------------------------------

func _ve_het() -> void:
	if nc == null:
		return
	var co := _ve.size
	var rong := minf(co.x * 0.30, 420.0)
	var y := LE

	# Máu — có thanh trắng tụt chậm phía sau để thấy VỪA mất bao nhiêu.
	_thanh(Vector2(LE, y), rong, nc.mau / maxf(nc.mau_toi_da, 1.0),
		MAU_MAU, MAU_MAU_NEN, _mau_tre)
	y += CAO_THANH + 6.0
	_thanh(Vector2(LE, y), rong * 0.82, nc.the_luc / maxf(nc.the_luc_max, 1.0),
		MAU_TL, Color(0.08, 0.13, 0.08, 0.85))
	y += CAO_THANH + 6.0
	# Thanh tư thế chỉ hiện khi đang tích — hiện thường trực thì nhiễu mắt,
	# mà nó chỉ có nghĩa lúc đang bị dồn.
	if nc.tu_the > 1.0:
		_thanh(Vector2(LE, y), rong * 0.7, nc.tu_the / maxf(nc.tu_the_max, 1.0),
			MAU_TU_THE, Color(0.14, 0.12, 0.05, 0.8))

	_ve_thanh_boss(co)
	_ve_goc_duoi(co)
	_ve_vet_bi_danh(co)
	var cam := nc.get_node_or_null("GiaCamera") as CameraBaCheDo
	if cam != null and cam.la_thu_nhat():
		_ve_cham_ngam(co)
		_ve_mui_ten_muc_tieu(co, cam)

## Nhận boss vào để vẽ thanh máu. Vùng nào có boss thì gọi lúc người chơi bước
## vào cửa; hạ xong thì gọi lại với null.
func theo_doi_boss(b: Boss) -> void:
	_boss = b
	_boss_tre = 1.0
	if b != null:
		var loi := b.loi_thoai()
		if loi != "":
			bao(loi)

func _ve_thanh_boss(co: Vector2) -> void:
	if _boss == null or not is_instance_valid(_boss) or not _boss.con_song():
		return
	var f := ThemeDB.fallback_font
	var rong := minf(co.x * 0.56, 760.0)
	var x := (co.x - rong) * 0.5
	var y := co.y - LE * 2.6
	var ti := _boss.mau / maxf(_boss.mau_toi_da, 1.0)

	# Tên hiện theo luật ???: chữ chưa đọc được thì hiện □. Boss vô danh là
	# một hình ảnh mạnh — và hạ xong thì `thuong_chu` dạy luôn mấy chữ đó.
	var ten := _boss.ten_hien()
	var be := _ve.get_theme_default_font_size()
	_ve.draw_string(f, Vector2(x, y - 10.0), ten,
		HORIZONTAL_ALIGNMENT_LEFT, -1, be + 8, MAU_CHU)
	# Giai đoạn hai: vạch mốc trên thanh cho thấy nó đã qua ngưỡng.
	_thanh(Vector2(x, y), rong, ti, MAU_MAU, MAU_MAU_NEN, _boss_tre)
	var moc := _boss.nguong_gd2()
	if moc > 0.0 and moc < 1.0:
		var mx := x + rong * moc
		_ve.draw_line(Vector2(mx, y - 3.0), Vector2(mx, y + CAO_THANH + 3.0),
			Color(0.95, 0.85, 0.45, 0.9), 2.0)
	if _boss.giai_doan >= 2:
		_ve.draw_string(f, Vector2(x + rong - 46.0, y - 10.0), "二",
			HORIZONTAL_ALIGNMENT_LEFT, -1, be + 6, Color(0.95, 0.55, 0.42))

func _thanh(tai: Vector2, rong: float, ti: float, mau: Color, nen: Color,
		tre: float = -1.0) -> void:
	var r := Rect2(tai, Vector2(rong, CAO_THANH))
	_ve.draw_rect(r, nen)
	if tre >= 0.0 and tre > ti:
		_ve.draw_rect(Rect2(tai, Vector2(rong * tre, CAO_THANH)), Color(0.85, 0.82, 0.78, 0.55))
	_ve.draw_rect(Rect2(tai, Vector2(rong * clampf(ti, 0.0, 1.0), CAO_THANH)), mau)
	_ve.draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)

func _ve_goc_duoi(co: Vector2) -> void:
	var f := ThemeDB.fallback_font
	var cao := 20
	var y := co.y - LE
	# Hồn — tiền tệ. Chính là chữ 魂 (mục 4.5).
	_ve.draw_string(f, Vector2(LE, y), "魂  %d" % Tui.hon,
		HORIZONTAL_ALIGNMENT_LEFT, -1, cao + 6, MAU_CHU)
	y -= 30
	var vk = Tui.vu_khi_dang_cam()
	var ten := "拳 (tay không)" if vk == null else vk.ten_hien()
	_ve.draw_string(f, Vector2(LE, y), ten, HORIZONTAL_ALIGNMENT_LEFT, -1, cao, MAU_CHU)
	y -= 26
	var tai := Tui.muc_tai()
	_ve.draw_string(f, Vector2(LE, y), "Tải: %s  ·  Bình %d/%d"
		% [String(tai["ten"]), Tui.binh_con, Tui.binh_toi_da],
		HORIZONTAL_ALIGNMENT_LEFT, -1, cao - 4, Color(0.78, 0.76, 0.72))

func _ve_vet_bi_danh(co: Vector2) -> void:
	if _huong_danh.is_empty() or nc == null:
		return
	var cam := nc.get_node_or_null("GiaCamera") as Node3D
	if cam == null:
		return
	var nhin := -cam.global_transform.basis.z
	nhin.y = 0.0
	nhin = nhin.normalized()
	var phai := nhin.cross(Vector3.UP).normalized() * -1.0
	var giua := co * 0.5
	var bk := minf(co.x, co.y) * 0.42

	for h in _huong_danh:
		var v: Vector3 = h["huong"]
		var goc := atan2(v.dot(phai), v.dot(nhin))
		var a := clampf(float(h["t"]) / 1.1, 0.0, 1.0)
		var tam := giua + Vector2(sin(goc), -cos(goc)) * bk
		# Cung tròn dày ở rìa, mờ dần — đọc được bằng khoé mắt mà không che hình.
		var diem: PackedVector2Array = []
		for i in 9:
			var g := goc + lerpf(-0.42, 0.42, float(i) / 8.0)
			diem.append(giua + Vector2(sin(g), -cos(g)) * bk)
		_ve.draw_polyline(diem, Color(0.92, 0.18, 0.16, a * 0.85), 7.0, true)
		_ve.draw_circle(tam, 4.0, Color(0.95, 0.3, 0.25, a))

## Chấm ngắm mờ ở đúng tầm với vũ khí đang cầm (mục 8). Không phải để bắn —
## để biết cây rìu với tới đâu khi không nhìn thấy tay mình.
func _ve_cham_ngam(co: Vector2) -> void:
	var m := VocabDB.don_cua(Tui.moveset_dang_dung(), "nhe_1")
	var tam := float(m.get("tam_voi", 2.0))
	var r := clampf(14.0 + tam * 3.0, 10.0, 46.0)
	var giua := co * 0.5
	_ve.draw_arc(giua, r, 0.0, TAU, 40, Color(0.92, 0.90, 0.86, 0.28), 1.6, true)
	_ve.draw_circle(giua, 2.0, Color(0.92, 0.90, 0.86, 0.45))

## Mũi tên rìa màn hình chỉ hướng mục tiêu — ở góc nhìn thứ nhất camera KHÔNG
## tự xoay về mục tiêu, nên không có mũi tên thì khoá mục tiêu vô dụng (mục 8).
func _ve_mui_ten_muc_tieu(co: Vector2, cam: CameraBaCheDo) -> void:
	if nc.muc_tieu == null or not is_instance_valid(nc.muc_tieu):
		return
	var v := nc.muc_tieu.global_position - nc.global_position
	v.y = 0.0
	var nhin := -cam.global_transform.basis.z
	nhin.y = 0.0
	nhin = nhin.normalized()
	var phai := nhin.cross(Vector3.UP).normalized() * -1.0
	var goc := atan2(v.normalized().dot(phai), v.normalized().dot(nhin))
	var giua := co * 0.5
	var bk := minf(co.x, co.y) * 0.34
	var tam := giua + Vector2(sin(goc), -cos(goc)) * bk
	var huong := (tam - giua).normalized()
	var ngang := Vector2(-huong.y, huong.x)
	_ve.draw_colored_polygon(PackedVector2Array([
		tam + huong * 13.0, tam - huong * 7.0 + ngang * 8.0,
		tam - huong * 7.0 - ngang * 8.0]), Color(0.96, 0.86, 0.45, 0.9))
