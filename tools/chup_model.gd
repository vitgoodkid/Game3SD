extends Node3D

## Chụp từng model trong assets/model ra một ảnh riêng, để NHÌN mà chọn.
##
##     godot --path . tools/chup_model.tscn      (KHÔNG chạy được với --headless)
##
## Vì sao cần: tên file không nói con nào nam con nào nữ, mặc gì, trông ra sao.
## Chiều cao thì đoán được (đo ở soi_model.gd) nhưng đoán không phải là biết.

## Thư mục quét. Đổi ở đây rồi chạy lại là chụp bộ khác.
@export var thu_muc := "res://assets/model/vu_khi/"
## Ảnh atlas ép vào mọi mesh; để trống thì giữ nguyên vật liệu của file.
@export var duong_texture := ""
const CO_ANH := Vector2i(300, 520)

var _cam: Camera3D = null

func _ready() -> void:
	get_window().size = CO_ANH
	_dung_canh()
	await get_tree().process_frame

	for duong in _liet_ke():
		await _chup_mot(duong)
	print("XONG")
	get_tree().quit()

func _dung_canh() -> void:
	var den := DirectionalLight3D.new()
	den.rotation_degrees = Vector3(-38, -35, 0)
	den.light_energy = 1.5
	add_child(den)
	var den2 := DirectionalLight3D.new()   # đèn phụ chống mặt tối thui
	den2.rotation_degrees = Vector3(-15, 150, 0)
	den2.light_energy = 0.6
	add_child(den2)

	var mt := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.22, 0.24, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.78)
	e.ambient_light_energy = 0.55
	mt.environment = e
	add_child(mt)

	_cam = Camera3D.new()
	# Ngang tầm ngực, lùi đủ xa để lấy trọn người cao 1.8m.
	_cam.position = Vector3(0, 0.95, 2.35)
	_cam.fov = 48.0
	add_child(_cam)

func _liet_ke() -> Array[String]:
	var ra: Array[String] = []
	var d := DirAccess.open(thu_muc)
	if d == null:
		return ra
	for f in d.get_files():
		var ten := f.trim_suffix(".import")
		if ten.ends_with(".fbx") or ten.ends_with(".glb") or ten.ends_with(".gltf"):
			if not ra.has(thu_muc + ten):
				ra.append(thu_muc + ten)
	ra.sort()
	return ra

func _chup_mot(duong: String) -> void:
	var canh := load(duong) as PackedScene
	if canh == null:
		return
	var g := canh.instantiate() as Node3D
	add_child(g)
	_ep_texture(g)
	for i in 4:
		await get_tree().process_frame
	# Tự canh khung theo hộp bao: bộ vũ khí dài ngắn chênh nhau mấy lần, để
	# camera cố định thì con thì tràn khung con thì bé như cái tăm.
	_canh_khung(g)
	for i in 2:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var anh := get_viewport().get_texture().get_image()
	var ten := duong.get_file().get_basename() + ".png"
	anh.save_png("user://mau_" + ten)
	print("ANH: ", ten)
	remove_child(g)
	g.queue_free()

## Ép atlas chung vào mọi mesh.
##
## Vật liệu trong FBX trỏ tới một đường dẫn texture không còn tồn tại, nên phần
## lớn model nạp lên là đen thui. Cả bộ mười bốn con dùng CHUNG một atlas, nên
## ép thẳng nó vào là xong — không phải sửa từng file.
func _ep_texture(n: Node) -> void:
	if duong_texture == "":
		return
	var tex := load(duong_texture) as Texture2D
	if tex == null:
		return
	for m in _moi_mesh(n):
		var vl := StandardMaterial3D.new()
		vl.albedo_texture = tex
		# Atlas bé tí (mỗi mảng màu vài pixel) — lọc mượt là màu lem sang nhau.
		vl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.material_override = vl

func _moi_mesh(n: Node) -> Array:
	var ra: Array = []
	if n is MeshInstance3D:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_moi_mesh(c))
	return ra

## Đẩy camera ra xa vừa đủ ôm trọn vật, và ngắm vào giữa nó.
func _canh_khung(g: Node3D) -> void:
	var h := AABB()
	var co := false
	for m in _moi_mesh(g):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		h = b if not co else h.merge(b)
		co = true
	if not co:
		return
	var giua := h.position + h.size * 0.5
	var lon := maxf(h.size.y, maxf(h.size.x, h.size.z))
	_cam.position = Vector3(giua.x, giua.y, giua.z + lon * 1.35 + 0.4)
	_cam.look_at(giua, Vector3.UP)
