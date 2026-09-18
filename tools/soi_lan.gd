extends Node

## Soi HƯỚNG CÚ LĂN: nhân vật quay mặt đâu, lăn đi đâu.
##
##     godot --headless --path . tools/soi_lan.tscn
##
## Viết ra vì chủ dự án báo lăn ngược 180°, mà đọc code thì mọi thứ tự nhất
## quán: `xoay_ve()` và `lan.gd` cùng dùng `atan2(h.x, h.z)`, tức là cùng
## chuẩn "+Z là hướng mặt". Đọc mãi không ra thì đo.

const CANH_PHONG := preload("res://scenes/the_gioi/phong_thu.tscn")

var _nc: NguoiChoi = null

func _ready() -> void:
	var p := CANH_PHONG.instantiate()
	add_child(p)
	await get_tree().process_frame
	await get_tree().physics_frame
	_nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi
	if _nc == null:
		print("khong co nguoi choi")
		get_tree().quit(1)
		return
	await get_tree().physics_frame

	print("")
	print("=== camera va than ===")
	print("  gia_camera.rotation.y = %.1f do" % rad_to_deg(_nc.gia_camera.rotation.y))
	print("  than.rotation.y       = %.1f do" % rad_to_deg(_nc.than.rotation.y))
	print("  huong_mat()           = %v" % _nc.huong_mat())

	await _do("dung yen", "")
	await _do("bam W", "di_truoc")
	await _do("bam S", "di_sau")
	await _do("bam A", "di_trai")
	await _do("bam D", "di_phai")
	get_tree().quit()

func _do(ten: String, nut: String) -> void:
	_nc.mau = _nc.mau_toi_da
	_nc.the_luc = _nc.the_luc_max
	_nc.hoi_lan = 0.0
	_nc.may.doi("dung")
	_nc.global_position = Vector3(0, 1.2, 0)
	_nc.velocity = Vector3.ZERO
	await get_tree().physics_frame
	if nut != "":
		_bam(nut, true)
		# đi một nhịp cho thân quay về đúng hướng phím trước đã
		await get_tree().create_timer(0.45).timeout
	var mat_truoc := _nc.huong_mat()
	var cho_truoc := _nc.global_position
	_nc._dem["lan"] = NguoiChoi.DEM_NHAP
	await get_tree().create_timer(SoulsLike.thoi_gian_lan + 0.1).timeout
	var di: Vector3 = _nc.global_position - cho_truoc
	di.y = 0.0
	if nut != "":
		_bam(nut, false)
	await get_tree().physics_frame
	var cham := 0.0
	if di.length() > 0.05:
		cham = rad_to_deg(mat_truoc.normalized().angle_to(di.normalized()))
	print("  %-10s mặt=%v  lăn=%v  xa=%.2fm  lệch mặt=%.0f°"
		% [ten, _lam_tron(mat_truoc), _lam_tron(di.normalized()), di.length(), cham])

func _lam_tron(v: Vector3) -> Vector3:
	return Vector3(snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01))

func _bam(hanh_dong: String, xuong: bool) -> void:
	var e := InputEventAction.new()
	e.action = hanh_dong
	e.pressed = xuong
	Input.parse_input_event(e)
