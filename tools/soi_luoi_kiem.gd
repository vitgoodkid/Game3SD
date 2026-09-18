extends Node3D

## LƯỠI KIẾM ĐI QUA ĐÂU trong từng clip.
##
##     godot --path . tools/soi_luoi_kiem.tscn   (KHÔNG chạy được với --headless)
##
## Trả lời đúng một câu hỏi, và là câu mà không phép thử nào trong dự án với
## tới: **cú chém có quét qua thân con quái không.**
##
## Hộp đòn thì tính theo `moveset.csv` nên sát thương luôn đúng — kể cả khi
## lưỡi kiếm lướt ngay trên đầu con quái. Lúc đó game vẫn "chạy đúng" mà mắt
## đọc ra là chém hụt, và luật của dự án nói thẳng: đọc được đòn là nửa cơ chế.
##
## Đo BỀ CAO của cả thanh kiếm chứ không chỉ mũi: cạnh nào của lưỡi cũng chém
## được, nên phần thấp nhất mới là phần quyết định có với tới chân con quái.
##
## Con quái thường cao khoảng 1.6m (cột `cao` của `quai.csv`). Một cú chém đọc
## được phải có khoảng [thấp nhất, cao nhất] phủ qua quãng 0.3–1.6m.

const CANH_NC := preload("res://scenes/nhan_vat/nguoi_choi.tscn")
const CHU_VU_KHI := "刃"
const SO_MAU := 12

## Mỗi dòng: tên hiện lên, trạng thái, kiểu đòn.
const CLIP := [
	["đứng yên", "dung", ""],
	["nhát 1", "danh", "nhe_1"],
	["nhát 2", "danh", "nhe_2"],
	["nhát 3", "danh", "nhe_3"],
	["Bổ", "danh", "nang"],
	["giơ thủ", "do_don", ""],
]

var _nc: Node3D = null
var _than: Node = null

func _ready() -> void:
	get_window().size = Vector2i(320, 240)
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
	_nc.set_physics_process(false)

	print("")
	print("| clip | lưỡi cao nhất | thấp nhất | xa nhất về trước | phủ thân quái? |")
	print("|---|---|---|---|---|")
	for bo in CLIP:
		await _do(bo)
	print("")
	get_tree().quit()

func _do(bo: Array) -> void:
	var cao := -9.0
	var thap := 9.0
	var truoc := -9.0
	for n in SO_MAU:
		await _dat_tu_the(String(bo[1]), String(bo[2]), float(n) / float(SO_MAU - 1))
		for m in _mesh_vu_khi():
			var ab: AABB = (m as MeshInstance3D).get_aabb()
			for k in 8:
				var p: Vector3 = (m.global_transform * ab.get_endpoint(k)) \
					- _nc.global_position
				cao = maxf(cao, p.y)
				thap = minf(thap, p.y)
				truoc = maxf(truoc, p.z)
	var phu := thap < 1.5 and cao > 0.4
	print("| %s | %.2f | %.2f | %.2f | %s |"
		% [String(bo[0]), cao, thap, truoc, "CÓ" if phu else "KHÔNG"])

## Đặt nhân vật vào đúng tư thế và tua clip tới đúng chỗ.
##
## `advance(0.0)` chứ KHÔNG `pause()`. Đây là chỗ đã nuốt mất nửa tiếng:
## `pause()` chặn luôn việc ÁP tư thế, nên mọi lần tua sau đó không ăn và cả
## bảng số ra y hệt nhau ở mọi clip — trông như phép đo hỏng, mà thực ra là tư
## thế đóng băng ở khung hình đầu.
func _dat_tu_the(trang_thai: String, kieu: String, tien_do: float) -> void:
	for i in 8:
		_than.call("dien", trang_thai, tien_do, false, 1.0 / 60.0, kieu, 1.0)
		await get_tree().process_frame
	var may := _tim_may(_than)
	if may != null and may.current_animation != "":
		var a := may.get_animation(may.current_animation)
		if a != null:
			may.play(may.current_animation)
			may.seek(a.length * clampf(tien_do, 0.0, 1.0), true)
			may.advance(0.0)
			await get_tree().process_frame

## Mọi mesh của VŨ KHÍ. Chúng nằm dưới `BoneAttachment3D`, khác hẳn mesh thân —
## đó là cách phân biệt duy nhất không phải đoán theo tên node.
func _mesh_vu_khi() -> Array:
	var ra: Array = []
	for g in _tim_gan(_than):
		ra.append_array(_mesh(g))
	return ra

func _tim_gan(n: Node) -> Array:
	var ra: Array = []
	if n is BoneAttachment3D:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_tim_gan(c))
	return ra

func _mesh(n: Node) -> Array:
	var ra: Array = []
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_mesh(c))
	return ra

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null
