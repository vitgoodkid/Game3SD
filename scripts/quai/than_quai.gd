class_name ThanQuai
extends Node3D

## Phần nhìn của quái: khối hộp dựng theo cỡ trong CSV, tên chữ Hán trên đầu,
## thanh máu, số sát thương bay lên.
##
## Tên quái hiện bằng chữ Hán trên đầu là ý số 5 ở mục 14 của bản yêu cầu:
## đi qua là thấy, lặp lại thụ động, học mà không bị bắt học. Chữ chưa biết
## hiện □ — và đó là lời mời đi ghép chữ.
##
## Ngả người trong khung vung tay là thứ QUAN TRỌNG NHẤT ở file này. Không có
## model thì đây là toàn bộ "đòn đọc được" của mục 5.4.

const MAU_NGAY := Color(1.0, 0.92, 0.45)     ## đang vỡ tư thế
const MAU_VUNG := Color(1.0, 0.55, 0.35)     ## đang vung tay

var _than: MeshInstance3D = null
var _dau: MeshInstance3D = null
var _nhan: Label3D = null
var _thanh: Sprite3D = null
var _vat_lieu: StandardMaterial3D = null
var _mau_goc := Color(0.6, 0.6, 0.65)
var _cao := 1.8

func dung_theo(cao: float, ban_kinh: float, hanh: String, ten: String) -> void:
	_cao = cao
	_mau_goc = NguHanh.mau_cua(hanh).lerp(Color(0.35, 0.35, 0.40), 0.35)
	_vat_lieu = StandardMaterial3D.new()
	_vat_lieu.albedo_color = _mau_goc
	_vat_lieu.roughness = 0.9

	_than = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(ban_kinh * 2.0, cao * 0.62, ban_kinh * 1.6)
	_than.mesh = b
	_than.position = Vector3(0, cao * 0.40, 0)
	_than.material_override = _vat_lieu
	add_child(_than)

	_dau = MeshInstance3D.new()
	var h := BoxMesh.new()
	h.size = Vector3(ban_kinh * 1.3, cao * 0.20, ban_kinh * 1.3)
	_dau.mesh = h
	_dau.position = Vector3(0, cao * 0.85, 0)
	_dau.material_override = _vat_lieu
	add_child(_dau)

	# Mẩu nhô ra phía trước để nhìn từ xa biết nó đang quay mặt hướng nào.
	# Không có cái này thì không đánh lén sau lưng được — mà backstab ×2.6 là
	# một trong những cơ chế thưởng chính.
	var mui := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(ban_kinh * 0.45, cao * 0.09, ban_kinh * 0.7)
	mui.mesh = mb
	mui.position = Vector3(0, cao * 0.85, ban_kinh * 1.0)
	mui.material_override = _vat_lieu
	add_child(mui)

	_nhan = Label3D.new()
	_nhan.text = ten
	_nhan.font_size = 64
	_nhan.pixel_size = 0.0022
	_nhan.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nhan.no_depth_test = false
	_nhan.position = Vector3(0, cao + 0.42, 0)
	_nhan.modulate = Color(0.95, 0.93, 0.88)
	_nhan.outline_size = 14
	add_child(_nhan)

	_thanh = Sprite3D.new()
	_thanh.texture = _anh_trang()
	_thanh.pixel_size = 0.0035
	_thanh.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_thanh.modulate = Color(0.85, 0.22, 0.22)
	_thanh.position = Vector3(0, cao + 0.18, 0)
	_thanh.visible = false
	add_child(_thanh)

func _anh_trang() -> ImageTexture:
	var img := Image.create(256, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)

## Cập nhật tên (chữ vừa ghép xong thì tên quái sáng ra ngay) và thanh máu.
func cap_nhat(ten: String, ti_le_mau: float) -> void:
	if _nhan != null:
		_nhan.text = ten
	if _thanh != null:
		_thanh.visible = ti_le_mau < 0.999 and ti_le_mau > 0.0
		_thanh.scale.x = maxf(ti_le_mau, 0.001)
		# Neo mép trái để thanh tụt về một phía, không co vào giữa.
		_thanh.position.x = -(1.0 - ti_le_mau) * 256.0 * 0.0035 * 0.5

# --- Hoạt ảnh -------------------------------------------------------

func dien(trang_thai: String, tien_do: float, delta: float) -> void:
	if _than == null:
		return
	var k := minf(1.0, 12.0 * delta)
	match trang_thai:
		"quai_danh":
			_dien_danh(tien_do, delta)
		"quai_vo_the":
			rotation_degrees.x = lerpf(rotation_degrees.x, 26.0, k)
			_to_mau(MAU_NGAY, delta, 8.0)
		"quai_trung_don":
			rotation_degrees.x = lerpf(rotation_degrees.x, -14.0, k)
			_to_mau(Color(1, 1, 1), delta, 18.0)
		"quai_chet":
			rotation_degrees.x = lerpf(rotation_degrees.x, -88.0, minf(1.0, 5.0 * delta))
			position.y = lerpf(position.y, -_cao * 0.3, minf(1.0, 5.0 * delta))
			if _nhan != null:
				_nhan.modulate.a = 1.0 - tien_do
			if _thanh != null:
				_thanh.visible = false
		_:
			rotation_degrees.x = lerpf(rotation_degrees.x, 0.0, k)
			_to_mau(_mau_goc, delta, 6.0)

## Ngả người trong khung vung tay. ĐÂY là "đòn đọc được".
##
## Ngả về SAU trong lúc vung (người chơi thấy nó lấy đà), rồi bật về TRƯỚC rất
## nhanh đúng lúc gây sát thương. Hai pha tách bạch, không nội suy mượt suốt —
## mượt quá thì không đọc được thời điểm.
func _dien_danh(tien_do: float, delta: float) -> void:
	var tt := get_parent() as Quai
	var vung := 1.0
	if tt != null and tt.may.hien_tai != null and tt.may.hien_tai.has_method("tien_do_vung"):
		vung = tt.may.hien_tai.tien_do_vung()
	if vung < 1.0:
		rotation_degrees.x = lerpf(0.0, -32.0, vung)       # lấy đà, ngả sau
		_to_mau(MAU_VUNG, delta, 10.0)
	else:
		rotation_degrees.x = lerpf(rotation_degrees.x, 24.0, minf(1.0, 26.0 * delta))
		_to_mau(_mau_goc, delta, 10.0)

## Đổi hẳn màu nền của con quái. Boss gọi lúc sang giai đoạn hai — đổi màu là
## cách rẻ nhất để người chơi NHÌN ra luật vừa đổi, không phải đọc thanh máu.
func to_lai(mau_moi: Color) -> void:
	_mau_goc = mau_moi
	if _vat_lieu != null:
		_vat_lieu.albedo_color = mau_moi

func _to_mau(dich: Color, delta: float, toc: float) -> void:
	if _vat_lieu == null:
		return
	_vat_lieu.albedo_color = _vat_lieu.albedo_color.lerp(dich, minf(1.0, toc * delta))

# --- Số sát thương bay lên ------------------------------------------

## Số bay lên đầu quái. Hệ số ngũ hành khác 1.0 thì tô màu và ghi rõ vì sao —
## đây là chỗ DẠY: người chơi thấy số lạ là đọc được ngay tại sao nó lạ.
func so_bay(st: int, he_so: float, ghi_chu: String) -> void:
	var l := Label3D.new()
	l.text = str(st) if he_so >= 0.0 else "+%d" % absi(st)
	l.font_size = 72
	l.pixel_size = 0.0026
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 16
	l.modulate = _mau_so(he_so)
	l.position = Vector3(randf_range(-0.3, 0.3), _cao * 0.7, randf_range(-0.2, 0.2))
	add_child(l)

	if ghi_chu != "":
		var g := Label3D.new()
		g.text = ghi_chu
		g.font_size = 40
		g.pixel_size = 0.0022
		g.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		g.no_depth_test = true
		g.outline_size = 12
		g.modulate = l.modulate
		g.position = l.position + Vector3(0, -0.28, 0)
		add_child(g)
		_bay(g, 1.5)

	_bay(l, 1.1)

func _mau_so(he_so: float) -> Color:
	if he_so < 0.0:
		return Color(0.45, 0.95, 0.55)    # xanh = nó đang HỒI máu, mình dùng sai
	if he_so > 1.2:
		return Color(1.0, 0.82, 0.30)     # vàng = khắc được
	if he_so < 0.9:
		return Color(0.65, 0.68, 0.75)    # xám = bị khắc lại
	return Color(0.96, 0.94, 0.90)

func _bay(l: Label3D, lau: float) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.1, lau)
	tw.tween_property(l, "modulate:a", 0.0, lau).set_delay(lau * 0.45)
	tw.chain().tween_callback(l.queue_free)
