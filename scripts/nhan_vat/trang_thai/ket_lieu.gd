extends TTNguoiChoi

## Đòn kết liễu — sau khi đỡ phản trúng, hoặc sau khi làm vỡ tư thế đối
## phương. Sát thương ×4 (SoulsLike.HS_KET_LIEU).
##
## Ở góc nhìn thứ nhất, camera tự chuyển tạm sang thứ ba lúc diễn (mục 8) —
## xem camera_ba_che_do.gd, hàm muon_goc_ba().

const T_DIEN := 1.15
var _nan: Node3D = null
var _da_danh := false

func vao(du_lieu: Dictionary = {}) -> void:
	_nan = du_lieu.get("nan_nhan", null) as Node3D
	_da_danh = false
	nc.bat_tu = true
	nc.velocity = Vector3.ZERO
	if _nan != null:
		var h := _nan.global_position - nc.global_position
		h.y = 0.0
		if h.length_squared() > 0.001:
			nc.than.rotation.y = atan2(h.x, h.z)

func ra() -> void:
	nc.bat_tu = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 40.0)
	if not _da_danh and t >= T_DIEN * 0.55:
		_da_danh = true
		if _nan != null and is_instance_valid(_nan) and _nan.has_method("an_don"):
			var st := int(Tui.sat_thuong_don("nang") * SoulsLike.HS_KET_LIEU)
			_nan.an_don(st, 999.0, nc.global_position, Tui.vu_khi_dang_cam().ngu_hanh()
				if Tui.vu_khi_dang_cam() != null else "")
	if t >= T_DIEN:
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["chet", "dung"]
