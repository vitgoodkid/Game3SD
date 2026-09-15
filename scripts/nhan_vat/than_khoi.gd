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
## tên điểm gắn `GanTayPhai` (mục 11 của bản yêu cầu).
##
## KHÔNG CÓ DÒNG LUẬT NÀO trong file này, và câu đó phải giữ cho đúng: đừng
## gắn hộp đòn vào bất cứ khớp nào bị `dien()` xoay. Từng gắn một lần và một
## thay đổi thuần trang trí làm cả game hết trúng đòn mà không báo lỗi gì.

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
var _khien: MeshInstance3D = null
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

	# Điểm gắn vũ khí. Tên cố định `GanTayPhai` — model thật sau này phải có
	# bone rỗng trùng tên (mục 11).
	#
	# NÓ KHÔNG BÁM THEO CÁNH TAY. Bản đầu có một RemoteTransform3D kéo nó theo
	# `_tay_phai`, nghĩa là HỘP ĐÒN nằm ở đâu là do dáng vung tay quyết định —
	# mà dáng vung tay là code trang trí. Hậu quả: thêm một cái nghiêng người
	# 4° cho đòn nặng trông nặng hơn là cả game hết trúng đòn, im lặng, không
	# lỗi nào. Đã dính đúng một lần.
	#
	# Giờ điểm gắn đứng yên ở ngực (vị trí khai trong nguoi_choi.tscn) và quay
	# theo THÂN. Hộp đòn vì vậy là một vùng với phía trước mặt, đúng bằng
	# `tam_voi` và `goc_quet` của moveset.csv — hai cột đó giờ nói thật.
	if _diem_gan == null:
		_diem_gan = Node3D.new()
		_diem_gan.name = "GanTayPhai"
		_diem_gan.position = Vector3(-0.36, 1.08, 0)
		add_child(_diem_gan)

	_vu_khi = MeshInstance3D.new()
	_vu_khi.mesh = _hinh_hop(Vector3(0.08, 0.08, 1.1))
	_vu_khi.material_override = _vat_lieu(mau_vu_khi)
	_vu_khi.position = Vector3(0, -0.34, 0.45)
	_vu_khi.rotation_degrees = Vector3(90, 0, 0)
	_tay_phai.add_child(_vu_khi)

	# Khiên ở tay trái. Phải NHÌN THẤY được: cầm khiên hay không đổi hẳn cách
	# chơi (có khiên mới parry được, mới đỡ được, mới có đòn phản đỡ), nên
	# không thấy nó trên người là người chơi không biết mình đang ở chế độ nào.
	_khien = MeshInstance3D.new()
	_khien.mesh = _hinh_hop(Vector3(0.62, 0.78, 0.09))
	_khien.material_override = _vat_lieu(mau_vu_khi)
	_khien.position = Vector3(0.10, -0.40, 0.14)
	_tay_trai.add_child(_khien)

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
	_cap_nhat_khien()
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

## Khiên hiện khi tay trái có món loại `khien`.
##
## Nhận biết bằng LOẠI của món đồ, không phải bằng chữ trung tâm của nó — luật
## 1: file này không được biết chữ 盾 tồn tại. Đổi khiên trong game thành chữ
## khác chỉ cần sửa nguyen_lieu.csv.
func _cap_nhat_khien() -> void:
	if _khien == null:
		return
	var kh = Tui.tay_trai_dang_cam()
	_khien.visible = kh != null
	if kh == null:
		return
	# Tô theo độ hiếm + hành, y như vũ khí — nhìn là đoán được nó hệ gì.
	var mau: Color = kh.mau()
	var h: String = kh.ngu_hanh()
	if h != "":
		mau = mau.lerp(NguHanh.mau_cua(h), 0.55)
	_khien.material_override = _vat_lieu(mau)

# --- Hoạt ảnh tạm bằng code -----------------------------------------

## Không có animation thật thì xoay khớp bằng tay. Xấu, nhưng đủ để ĐỌC được
## đòn đánh — mà đọc được đòn mới là thứ quyết định ở mốc 2.
func dien(trang_thai: String, tien_do: float, dang_di: bool, delta: float,
		kieu: String = "") -> void:
	match trang_thai:
		"danh":
			_dien_danh(kieu, tien_do)
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

	# Lết trong lúc nạp cũng phải bước chân, không thì nhân vật trượt băng.
	if dang_di and (trang_thai in ["di", "chay_nhanh"] or kieu == "nap"):
		_nhip += delta * (11.0 if trang_thai == "chay_nhanh" else 7.0)
		var b := sin(_nhip) * (28.0 if trang_thai == "chay_nhanh" else 17.0)
		_chan_phai.rotation_degrees.x = b
		_chan_trai.rotation_degrees.x = -b
		if trang_thai != "danh":   # đang đánh thì tay do _dien_danh() lo
			_tay_phai.rotation_degrees.x = -b * 0.55
			_tay_trai.rotation_degrees.x = b * 0.55
	elif trang_thai not in ["lan", "chet"]:
		_chan_phai.rotation_degrees.x = lerpf(_chan_phai.rotation_degrees.x, 0.0,
			minf(1.0, 10.0 * delta))
		_chan_trai.rotation_degrees.x = lerpf(_chan_trai.rotation_degrees.x, 0.0,
			minf(1.0, 10.0 * delta))

## Dáng đánh, khác nhau theo LOẠI đòn.
##
## Trước đây cả bảy loại đòn dùng chung đúng một cung vung, nên đòn nặng nhìn
## y hệt đòn nhẹ — chỉ chậm hơn. Người chơi giữ chuột mà không thấy gì khác
## thì tưởng giữ không ăn thua, dù sát thương thật đã gấp rưỡi. Ở một game
## souls-like, ĐỌC ĐƯỢC ĐÒN là nửa cơ chế; nửa kia là con số.
func _dien_danh(kieu: String, tien_do: float) -> void:
	var t := clampf(tien_do, 0.0, 1.0)
	_vu_khi.scale = Vector3.ONE

	if kieu == "nap":
		# ĐANG NẠP: giơ ngược ra sau đầu rồi GIỮ NGUYÊN, rung nhẹ, vũ khí to
		# dần. Đây là khung người chơi đọc "sắp ra đòn to" — và cũng là khung
		# đối phương đọc được, nên nạp phải có rủi ro nhìn thấy được.
		_tay_phai.rotation_degrees.x = -172.0 + sin(t * 46.0) * 3.5
		_tay_trai.rotation_degrees.x = -28.0
		_than_nguoi.rotation_degrees.x = 7.0
		_vu_khi.scale = Vector3.ONE * (1.0 + t * 0.35)
		return

	if kieu == "phan_do":
		# ĐÒN PHẢN ĐỠ: thúc thẳng từ sau khiên ra, không vung vòng. Khiên vẫn
		# giơ gần hết đòn — đó là cả ý của đòn này, phản mà không bỏ thủ.
		_tay_phai.rotation_degrees.x = lerpf(-38.0, 32.0, t)
		_tay_trai.rotation_degrees.x = lerpf(-95.0, -62.0, t)
		_than_nguoi.rotation_degrees.x = lerpf(0.0, -11.0, t)
		return

	# Vung từ sau đầu ra trước. Vung tay ngược lên trước là chỗ người chơi đọc
	# được "nó sắp chém" — khung quan trọng nhất.
	var nang := kieu.begins_with("nang")
	_tay_phai.rotation_degrees.x = lerpf(-176.0 if nang else -150.0,
		80.0 if nang else 55.0, t)
	_tay_trai.rotation_degrees.x = lerpf(0.0, -25.0, t)
	# Đòn nặng đổ cả người theo cú vung rồi thẳng lại — nhìn ra sức nặng.
	_than_nguoi.rotation_degrees.x = sin(t * PI) * (-15.0 if nang else -4.0)

func _ve_thuong(delta: float) -> void:
	_vu_khi.scale = Vector3.ONE
	var k := minf(1.0, 10.0 * delta)
	_than_nguoi.rotation_degrees.x = lerpf(_than_nguoi.rotation_degrees.x, 0.0, k)
	_than_nguoi.position.y = lerpf(_than_nguoi.position.y, 0.0, k)
	_tay_phai.rotation_degrees.x = lerpf(_tay_phai.rotation_degrees.x, 0.0, k)
	_tay_trai.rotation_degrees.x = lerpf(_tay_trai.rotation_degrees.x, 0.0, k)
