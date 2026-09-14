class_name VuKhiHopDon
extends Area3D

## Hộp đòn của vũ khí. Gắn vào điểm bàn tay phải, bật/tắt theo khung gây sát
## thương của đòn đang vung (xem danh.gd).
##
## Mục 9 của bản yêu cầu: trong bản có model thật, việc bật/tắt do animation
## track gọi chứ không phải đồng hồ đếm — 3D phải khớp hình, không thì người
## chơi thấy kiếm chưa chạm mà máu đã tụt. Ở bản khối hộp này chưa có
## animation nên dùng mốc thời gian trong moveset.csv; đổi sang animation
## track sau chỉ cần gọi bat()/tat() từ AnimationPlayer, luật ở đây giữ nguyên.

## Mỗi lần vung chỉ đánh trúng mỗi mục tiêu MỘT lần. Không có cái này thì
## Area3D báo chạm mỗi khung hình và một nhát kiếm ăn 20 lần sát thương.
var _da_trung := {}

var _chu_mv := "拳"
var _don := "nhe_1"
var _nguon: Node3D = null

func _ready() -> void:
	monitoring = false
	body_entered.connect(_cham)
	area_entered.connect(_cham)

## danh.gd gọi trước khi bật, để hộp đòn biết đang là đòn nào của vũ khí nào.
func dat_don(chu_mv: String, don: String, nguon: Node3D) -> void:
	_chu_mv = chu_mv
	_don = don
	_nguon = nguon
	_da_trung.clear()
	_cap_nhat_hinh()

## Tầm với và góc quét lấy từ CSV — rìu quét rộng hơn dao, và người chơi phải
## CẢM THẤY điều đó chứ không chỉ đọc được trong bảng.
func _cap_nhat_hinh() -> void:
	var m := VocabDB.don_cua(_chu_mv, _don)
	if m.is_empty():
		return
	var hinh := get_node_or_null("Hinh") as CollisionShape3D
	if hinh == null:
		return
	var tam := float(m.get("tam_voi", 2.0))
	var goc := float(m.get("goc_quet", 90.0))
	# Xấp xỉ vùng quét bằng một hộp: dài bằng tầm với, rộng theo góc quét.
	var h := hinh.shape as BoxShape3D
	if h == null:
		h = BoxShape3D.new()
		hinh.shape = h
	var rong := clampf(tam * sin(deg_to_rad(minf(goc, 180.0)) * 0.5), 0.4, tam)
	h.size = Vector3(rong * 2.0, 1.4, tam)
	hinh.position = Vector3(0, 0, tam * 0.5)

func _cham(vat: Node) -> void:
	if vat == _nguon or vat == null:
		return
	var id := vat.get_instance_id()
	if _da_trung.has(id):
		return
	_da_trung[id] = true

	var muc := vat
	if not muc.has_method("an_don") and muc.get_parent() != null:
		muc = muc.get_parent()
	if not muc.has_method("an_don"):
		return

	var m := VocabDB.don_cua(_chu_mv, _don)
	var st := int(round(Tui.sat_thuong_don(_don)))
	var pha := float(m.get("pha_the", 10.0))
	var vk = Tui.vu_khi_dang_cam()
	var hanh := "" if vk == null else vk.ngu_hanh()

	# Đòn sau lưng ×2.6 (mục 5.1). Tính bằng hướng quay của mục tiêu chứ
	# không phải vị trí — đứng sau lưng mà nó vừa xoay lại thì không tính.
	if _sau_lung(muc):
		st = int(round(float(st) * SoulsLike.HS_SAU_LUNG))
		pha *= 1.8

	muc.an_don(st, pha, _nguon.global_position if _nguon != null else global_position, hanh)

func _sau_lung(muc: Node) -> bool:
	if _nguon == null or not (muc is Node3D):
		return false
	var m3 := muc as Node3D
	var toi := m3.global_position - _nguon.global_position
	toi.y = 0.0
	if toi.length_squared() < 0.01:
		return false
	# Mặt của mục tiêu là +Z trong hệ Godot của model quay về −Z... quy ước
	# ở dự án này: mọi nhân vật quay mặt theo basis.z (xem NguoiChoi.huong_mat).
	var mat := m3.global_transform.basis.z.normalized()
	return toi.normalized().dot(mat) > 0.55
