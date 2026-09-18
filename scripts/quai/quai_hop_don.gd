class_name QuaiHopDon
extends Area3D

## Hộp đòn của quái. Đối xứng với VuKhiHopDon của người chơi.

var _da_trung := {}
var _don := "bo_cham"
var _nguon: Quai = null

func _ready() -> void:
	monitoring = false
	body_entered.connect(_cham)

func dat_don(don: String, nguon: Quai) -> void:
	_don = don
	_nguon = nguon
	_da_trung.clear()
	_cap_nhat_hinh()

func _cap_nhat_hinh() -> void:
	var m := VocabDB.don_quai_cua(_don)
	var hinh := get_node_or_null("Hinh") as CollisionShape3D
	if hinh == null or m.is_empty():
		return
	var h := hinh.shape as BoxShape3D
	if h == null:
		h = BoxShape3D.new()
		hinh.shape = h
	var tam := maxf(float(m.get("tam_voi", 2.0)), 0.3)
	var goc := float(m.get("goc_quet", 90.0))
	var rong := clampf(tam * sin(deg_to_rad(minf(goc, 180.0)) * 0.5), 0.4, tam)
	h.size = Vector3(rong * 2.0, 1.8, tam)
	hinh.position = Vector3(0, 0.9, tam * 0.5)

func _cham(vat: Node) -> void:
	if _nguon == null or vat == _nguon:
		return
	var id := vat.get_instance_id()
	if _da_trung.has(id):
		return
	_da_trung[id] = true
	if not vat.has_method("an_don"):
		return

	var m := VocabDB.don_quai_cua(_don)
	var st := int(m.get("sat_thuong", 20))
	# Quái mạnh lên theo vốn từ của người chơi — giữ nguyên luật của bản 2D
	# (ChienDau.he_so_theo_von_tu): máu tối đa tăng theo số chữ đã học, nên
	# sát thương quái phải tăng theo, không thì cuối game không còn sức ép.
	st = int(round(float(st) * ChienDau.he_so_theo_von_tu(TriNho.so_chu_da_hoc())))
	var pha := float(m.get("pha_the", 20))
	var kq: int = vat.an_don(st, pha, _nguon.global_position, _nguon.ngu_hanh)
	if kq < 0:
		# Âm = người chơi ĐỠ PHẢN trúng. Quái đứng ngây, mở đòn kết liễu.
		# -1 là parry thường, -2 là parry HOÀN HẢO — ngây lâu hơn hẳn, đủ để
		# chạy vòng ra sau lưng rồi mới kết liễu.
		_nguon.bi_do_phan(SoulsLike.NGAY_SAU_PERFECT if kq <= -2
			else SoulsLike.NGAY_SAU_DO_PHAN)
