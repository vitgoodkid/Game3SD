extends Node

## Soi model trong assets/model: có xương không, cao bao nhiêu, gốc ở đâu.
##
##     godot --headless --path . tools/soi_model.tscn
##
## Viết ra vì ba câu hỏi này quyết định model có dùng được không, mà không câu
## nào trả lời được bằng cách nhìn tên file:
##
##   CÓ XƯƠNG KHÔNG  không có Skeleton3D thì nhân vật đứng nguyên tư thế chữ T
##                   trượt quanh map — đọc đòn đánh bằng mắt thành bất khả, mà
##                   đọc được đòn là nửa cơ chế của souls-like
##   CAO BAO NHIÊU   luật của repo: nhân vật cao 1.8m (xem CLAUDE.md mục Quy ước)
##   GỐC Ở ĐÂU       phải dưới CHÂN. Gốc ở hông thì nhân vật lún nửa người
##                   xuống đất, và sửa bằng cách bù trừ tay là sai từ đầu

const THU_MUC := "res://assets/model/"

func _ready() -> void:
	print("")
	print("====== SOI MODEL ======")
	var ds := _liet_ke()
	if ds.is_empty():
		print("Khong co .fbx/.glb nao trong ", THU_MUC)
		get_tree().quit(1)
		return
	for duong in ds:
		_soi(duong)
	print("")
	get_tree().quit()

func _liet_ke() -> Array[String]:
	var ra: Array[String] = []
	var d := DirAccess.open(THU_MUC)
	if d == null:
		return ra
	for f in d.get_files():
		var ten := f.trim_suffix(".import")
		if ten.ends_with(".fbx") or ten.ends_with(".glb") or ten.ends_with(".gltf"):
			if not ra.has(THU_MUC + ten):
				ra.append(THU_MUC + ten)
	ra.sort()
	return ra

func _soi(duong: String) -> void:
	var canh := load(duong) as PackedScene
	if canh == null:
		print("  %-26s NAP KHONG DUOC" % duong.get_file())
		return
	var g := canh.instantiate()
	add_child(g)

	var xuong := _tim_xuong(g)
	var hop := _hop_bao(g)
	var so_mesh := _dem_mesh(g)
	var anim := _tim_anim(g)

	print("  %-26s xuong=%-4s so_xuong=%-4s mesh=%-3d anim=%-3d cao=%.2fm  day_y=%+.2f" % [
		duong.get_file(),
		"CO" if xuong != null else "KHONG",
		str(xuong.get_bone_count()) if xuong != null else "-",
		so_mesh, anim,
		hop.size.y, hop.position.y,
	])
	# In tên xương gốc của con ĐẦU TIÊN thôi — mười bốn bộ xương giống nhau thì
	# in cả mười bốn chỉ là nhiễu.
	if xuong != null and not _da_in_xuong:
		_da_in_xuong = true
		var ten: Array[String] = []
		for i in mini(xuong.get_bone_count(), 80):
			ten.append(xuong.get_bone_name(i))
		print("    xuong: ", " ".join(ten))
	g.queue_free()
	remove_child(g)

var _da_in_xuong := false

func _tim_xuong(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var k := _tim_xuong(c)
		if k != null:
			return k
	return null

func _dem_mesh(n: Node) -> int:
	var d := 1 if n is MeshInstance3D else 0
	for c in n.get_children():
		d += _dem_mesh(c)
	return d

func _tim_anim(n: Node) -> int:
	if n is AnimationPlayer:
		return (n as AnimationPlayer).get_animation_list().size()
	for c in n.get_children():
		var d := _tim_anim(c)
		if d > 0:
			return d
	return 0

## Hộp bao quanh toàn bộ mesh, tính trong hệ toạ độ của gốc model.
func _hop_bao(n: Node, goc: Node3D = null) -> AABB:
	if goc == null:
		goc = n as Node3D
	var ra := AABB()
	var co := false
	for m in _moi_mesh(n):
		var h: AABB = m.get_aabb()
		var t: Transform3D = goc.global_transform.affine_inverse() * m.global_transform
		h = t * h
		if not co:
			ra = h
			co = true
		else:
			ra = ra.merge(h)
	return ra

func _moi_mesh(n: Node) -> Array:
	var ra: Array = []
	if n is MeshInstance3D:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_moi_mesh(c))
	return ra
