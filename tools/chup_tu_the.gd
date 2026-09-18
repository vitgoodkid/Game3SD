extends Node3D

## Chụp nhân vật ở từng TƯ THẾ, mỗi tư thế một ảnh.
##
##     godot --path . tools/chup_tu_the.tscn     (KHÔNG chạy được với --headless)
##
## Vì sao cần: model không có animation nào, mọi dáng đều do `than_mo_hinh.gd`
## xoay xương bằng tay. Mà trục xoay của từng xương thì mỗi rig một khác và
## không có cách nào biết trước ngoài THỬ — gập nhầm trục là khớp bẻ ngược,
## và không lỗi nào nổ ra. Bộ kiểm tra cũng không thấy: nó đọc được "state đang
## là danh", không đọc được "cánh tay đang gập ngược ra sau".

const CANH_NC := preload("res://scenes/nhan_vat/nguoi_choi.tscn")
## Khung rộng hơn người: kiếm hai tay dài 1.25m và nó vung RA NGOÀI người.
## Khung vừa khít thân thì mọi cú chém đều bị cắt mất phần lưỡi — đúng phần
## cần nhìn nhất.
const CO_ANH := Vector2i(460, 520)

## Mỗi dòng: tên ảnh, trạng thái, tiến độ, đang đi, kiểu đòn, đã rút vũ khí.
##
## `tiến độ` giờ vừa là tiến độ của state, vừa là chỗ TUA clip động tác tới.
## Không tua thì mọi ảnh đòn đánh đều chụp đúng một thời điểm — khung thứ 40 —
## và cú vung nào cũng ra cùng một dáng.
const TU_THE := [
	["dung", "dung", 0.0, false, "", true],
	["di", "di", 0.35, true, "", true],
	["chay", "chay_nhanh", 0.35, true, "", true],
	["danh_nhe", "danh", 0.45, false, "nhe_1", true],
	["danh_nang", "danh", 0.45, false, "nang", true],
	["nap", "danh", 0.5, false, "nap", true],
	["phan_do", "danh", 0.5, false, "phan_do", true],
	["do_don", "do_don", 0.3, false, "", true],
	["do_phan", "do_phan", 0.6, false, "", true],
	["lan", "lan", 0.35, false, "", true],
	["nhay", "nhay", 0.4, false, "", true],
	["trung_don", "trung_don", 0.3, false, "", true],
	["chet", "chet", 0.95, false, "", true],
	["cat_dung", "dung", 0.0, false, "", false],
	["cat_chay", "chay_nhanh", 0.35, true, "", false],
	["cat_vu_khi", "cat_vu_khi", 0.8, false, "", true],
	["rut_vu_khi", "rut_vu_khi", 0.8, false, "", true],
]

var _nc: Node3D = null
var _than: Node = null

func _ready() -> void:
	get_window().size = CO_ANH
	_dung_canh()
	# Phát vũ khí và khiên như phòng thử làm. Không có chúng thì không nhìn ra
	# cú chém — tay không vung trông gần như tay buông.
	var vk := SinhMonDo.sinh_mon_tu_chu("刃", "thi_tran", 1000)
	if vk != null:
		Tui.nhat(vk)
		Tui.mac_vao(vk, "vu_khi")
	var kh := SinhMonDo.sinh_theo_loai("khien", "thi_tran", 1000)
	if kh != null:
		Tui.nhat(kh)
		Tui.mac_vao(kh, "tay_trai")

	_nc = CANH_NC.instantiate() as Node3D
	add_child(_nc)
	await get_tree().process_frame
	await get_tree().process_frame
	_than = _nc.get_node_or_null("Than")
	if _than == null or not _than.has_method("dien"):
		print("KHONG TIM THAY THAN CO dien()")
		get_tree().quit(1)
		return
	# Máy trạng thái chạy song song sẽ ghi đè dáng mỗi khung — tắt nó đi thì
	# ảnh mới đứng yên ở đúng tư thế mình muốn xem.
	_nc.set_physics_process(false)

	for tt in TU_THE:
		await _chup(tt)
	print("XONG")
	get_tree().quit()

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
	var cam := Camera3D.new()
	cam.position = Vector3(2.5, 1.45, 3.45)
	cam.rotation_degrees = Vector3(-11, 36, 0)
	cam.fov = 50.0
	add_child(cam)

func _chup(tt: Array) -> void:
	if _than.has_method("dat_da_rut"):
		_than.call("dat_da_rut", bool(tt[5]))
	# Gọi dien() nhiều khung: phần lớn dáng dùng nội suy, một khung thì mới đi
	# được vài phần trăm đường.
	for i in 40:
		_than.call("dien", String(tt[1]), float(tt[2]), bool(tt[3]), 1.0 / 60.0,
			String(tt[4]), 1.0)
		await get_tree().process_frame
	# Có clip thật thì TUA nó tới đúng chỗ rồi mới chụp. Nếu không, mọi cú vung
	# đều bị bắt ở giây thứ 0.66 — chỗ mà đòn dài thì còn chưa giơ tay lên, còn
	# đòn ngắn thì đã thu về xong.
	var may := _tim_may(_than)
	if may != null and may.is_playing():
		var a := may.get_animation(may.current_animation)
		if a != null:
			may.seek(a.length * clampf(float(tt[2]), 0.0, 1.0), true)
			may.pause()
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var anh := get_viewport().get_texture().get_image()
	anh.save_png("user://tuthe_%s.png" % String(tt[0]))
	print("ANH: ", tt[0])

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null
