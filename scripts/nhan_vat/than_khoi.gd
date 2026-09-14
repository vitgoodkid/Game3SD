class_name ThanKhoi
extends Node3D

## Thân nhân vật dựng bằng khối primitive, sinh trong code.
##
## Vì sao tồn tại: kho model chưa có, mà mốc 2 (combat lõi) là điểm quyết định
## của cả dự án và nó KHÔNG cần model đẹp — nó cần đòn đánh đọc được. Khối hộp
## có vung tay rõ ràng thì tune được cảm giác; model đẹp mà timing sai thì
## không.
##
## Thay model thật về sau: giấu node này đi, nạp .glb vào cùng chỗ, giữ nguyên
## tên điểm gắn `GanTayPhai` (mục 11 của bản yêu cầu). Không có dòng luật nào
## nằm trong file này — đây thuần là chỗ để nhìn.

## Cao 1.8m, đúng chuẩn mục 11. Sai cỡ là hỏng toàn bộ tune combat.
const CAO := 1.8

@export var mau_than := Color(0.42, 0.45, 0.52)
@export var mau_da := Color(0.78, 0.66, 0.55)
@export var mau_vu_khi := Color(0.80, 0.82, 0.86)

var _tay_phai: Node3D = null
var _tay_trai: Node3D = null
var _chan_trai: Node3D = null
var _chan_phai: Node3D = null
var _vu_khi: MeshInstance3D = null
var _than_nguoi: Node3D = null
var _diem_gan: Node3D = null

## Nhịp bước chân, để chân đung đưa khi đi.
var _nhip := 0.0

func _ready() -> void:
	_than_nguoi = get_node_or_null("ThanNguoi")
	if _than_nguoi == null:
		_than_nguoi = Node3D.new()
		_than_nguoi.name = "ThanNguoi"
		add_child(_than_nguoi)
	_diem_gan = get_node_or_null("GanTayPhai")
	_dung_hinh()
	Tui.doi_trang_bi.connect(_cap_nhat_vu_khi)
	_cap_nhat_vu_khi()

func _dung_hinh() -> void:
	# Thân
	_them(_than_nguoi, _hop(Vector3(0.52, 0.70, 0.30), mau_than), Vector3(0, 1.12, 0))
	# Đầu
	_them(_than_nguoi, _hop(Vector3(0.30, 0.32, 0.30), mau_da), Vector3(0, 1.62, 0))
	# Hai tay: node xoay riêng để vung được
	_tay_phai = _chi(_than_nguoi, Vector3(-0.36, 1.42, 0), Vector3(0.18, 0.62, 0.18), mau_da)
	_tay_trai = _chi(_than_nguoi, Vector3(0.36, 1.42, 0), Vector3(0.18, 0.62, 0.18), mau_da)
	# Hai chân
	_chan_phai = _chi(_than_nguoi, Vector3(-0.15, 0.76, 0), Vector3(0.21, 0.76, 0.21), mau_than)
	_chan_trai = _chi(_than_nguoi, Vector3(0.15, 0.76, 0), Vector3(0.21, 0.76, 0.21), mau_than)

	# Điểm gắn vũ khí ở đầu tay phải. Tên cố định `GanTayPhai` — model thật
	# sau này phải có bone rỗng trùng tên (mục 11).
	if _diem_gan == null:
		_diem_gan = Node3D.new()
		_diem_gan.name = "GanTayPhai"
		add_child(_diem_gan)
	_tay_phai.add_child(_theo_doi(_diem_gan))

	_vu_khi = MeshInstance3D.new()
	_vu_khi.mesh = _hinh_hop(Vector3(0.08, 0.08, 1.1))
	_vu_khi.material_override = _vat_lieu(mau_vu_khi)
	_vu_khi.position = Vector3(0, -0.34, 0.45)
	_vu_khi.rotation_degrees = Vector3(90, 0, 0)
	_tay_phai.add_child(_vu_khi)

## Node rỗng bám theo tay phải — HopDon là con của GanTayPhai trong .tscn nên
## không di dời được, thay vào đó gắn một node trung gian theo dõi vị trí.
func _theo_doi(dich: Node3D) -> Node3D:
	var n := RemoteTransform3D.new()
	n.name = "TruyenVeGanTayPhai"
	n.remote_path = dich.get_path()
	n.position = Vector3(0, -0.34, 0.0)
	return n

func _chi(cha: Node3D, vi_tri: Vector3, co: Vector3, mau: Color) -> Node3D:
	# Khớp xoay đặt ở VAI/HÔNG, khối hộp treo bên dưới — xoay node cha là chi
	# quay quanh khớp, không phải quay quanh giữa thân nó.
	var khop := Node3D.new()
	khop.position = vi_tri
	cha.add_child(khop)
	var m := MeshInstance3D.new()
	m.mesh = _hinh_hop(co)
	m.material_override = _vat_lieu(mau)
	m.position = Vector3(0, -co.y * 0.5, 0)
	khop.add_child(m)
	return khop

func _them(cha: Node3D, m: MeshInstance3D, vi_tri: Vector3) -> void:
	m.position = vi_tri
	cha.add_child(m)

func _hop(co: Vector3, mau: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = _hinh_hop(co)
	m.material_override = _vat_lieu(mau)
	return m

func _hinh_hop(co: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = co
	return b

func _vat_lieu(mau: Color) -> StandardMaterial3D:
	var v := StandardMaterial3D.new()
	v.albedo_color = mau
	v.roughness = 0.85
	return v

# --- Vũ khí đang cầm ------------------------------------------------

## Vũ khí đổi hình theo chữ trung tâm: rìu to và ngắn, kiếm dài và mảnh, cung
## dẹt. Không phải trang trí — người chơi phải NHÌN ra mình đang cầm gì, nhất
## là ở góc nhìn thứ nhất khi chỉ thấy đúng cái vũ khí.
const HINH_VU_KHI := {
	"剑": Vector3(0.07, 0.07, 1.15),
	"刀": Vector3(0.09, 0.05, 0.85),
	"斧": Vector3(0.26, 0.10, 0.95),
	"弓": Vector3(0.05, 0.95, 0.12),
	"拳": Vector3(0.0, 0.0, 0.0),
}

func _cap_nhat_vu_khi() -> void:
	if _vu_khi == null:
		return
	var chu := Tui.moveset_dang_dung()
	var co: Vector3 = HINH_VU_KHI.get(chu, HINH_VU_KHI["剑"])
	_vu_khi.visible = co.length_squared() > 0.0
	if not _vu_khi.visible:
		return
	_vu_khi.mesh = _hinh_hop(co)
	var vk = Tui.vu_khi_dang_cam()
	var mau := mau_vu_khi
	if vk != null:
		# Tô theo ĐỘ HIẾM, và nếu có hành thì pha màu ngũ hành vào. Nhìn thanh
		# vũ khí là đoán được nó hệ gì — thêm một chỗ chữ Hán nắm thông tin.
		mau = vk.mau()
		var h := vk.ngu_hanh()
		if h != "":
			mau = mau.lerp(NguHanh.mau_cua(h), 0.55)
	_vu_khi.material_override = _vat_lieu(mau)

# --- Hoạt ảnh tạm bằng code -----------------------------------------

## Không có animation thật thì xoay khớp bằng tay. Xấu, nhưng đủ để ĐỌC được
## đòn đánh — mà đọc được đòn mới là thứ quyết định ở mốc 2.
func dien(trang_thai: String, tien_do: float, dang_di: bool, delta: float) -> void:
	match trang_thai:
		"danh":
			# Vung từ sau đầu ra trước: -150° → +55°. Vung tay ngược lên trước
			# là chỗ người chơi đọc được "nó sắp chém" — khung quan trọng nhất.
			var g := lerpf(-150.0, 55.0, clampf(tien_do, 0.0, 1.0))
			_tay_phai.rotation_degrees.x = g
			_tay_trai.rotation_degrees.x = lerpf(0.0, -25.0, tien_do)
		"lan":
			var vong := clampf(tien_do, 0.0, 1.0) * 360.0
			_than_nguoi.rotation_degrees.x = vong
			_than_nguoi.position.y = sin(clampf(tien_do, 0.0, 1.0) * PI) * 0.22
		"do_don", "do_phan":
			_than_nguoi.rotation_degrees.x = 0.0
			_than_nguoi.position.y = 0.0
			_tay_trai.rotation_degrees.x = -95.0
			_tay_phai.rotation_degrees.x = -20.0
		"trung_don", "vo_the":
			_than_nguoi.rotation_degrees.x = lerpf(_than_nguoi.rotation_degrees.x, -18.0,
				minf(1.0, 14.0 * delta))
		"chet":
			_than_nguoi.rotation_degrees.x = lerpf(_than_nguoi.rotation_degrees.x, -88.0,
				minf(1.0, 4.0 * delta))
			_than_nguoi.position.y = lerpf(_than_nguoi.position.y, -0.45, minf(1.0, 4.0 * delta))
		_:
			_ve_thuong(delta)

	if dang_di and trang_thai in ["di", "chay_nhanh"]:
		_nhip += delta * (11.0 if trang_thai == "chay_nhanh" else 7.0)
		var b := sin(_nhip) * (28.0 if trang_thai == "chay_nhanh" else 17.0)
		_chan_phai.rotation_degrees.x = b
		_chan_trai.rotation_degrees.x = -b
		if trang_thai != "danh":
			_tay_phai.rotation_degrees.x = -b * 0.55
			_tay_trai.rotation_degrees.x = b * 0.55
	elif trang_thai not in ["lan", "chet"]:
		_chan_phai.rotation_degrees.x = lerpf(_chan_phai.rotation_degrees.x, 0.0,
			minf(1.0, 10.0 * delta))
		_chan_trai.rotation_degrees.x = lerpf(_chan_trai.rotation_degrees.x, 0.0,
			minf(1.0, 10.0 * delta))

func _ve_thuong(delta: float) -> void:
	var k := minf(1.0, 10.0 * delta)
	_than_nguoi.rotation_degrees.x = lerpf(_than_nguoi.rotation_degrees.x, 0.0, k)
	_than_nguoi.position.y = lerpf(_than_nguoi.position.y, 0.0, k)
	_tay_phai.rotation_degrees.x = lerpf(_tay_phai.rotation_degrees.x, 0.0, k)
	_tay_trai.rotation_degrees.x = lerpf(_tay_trai.rotation_degrees.x, 0.0, k)
