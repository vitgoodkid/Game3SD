extends Node

## Soi QUỸ ĐẠO BÀN TAY PHẢI của từng clip đánh.
##
##     godot --headless --path . tools/soi_quy_dao.tscn
##
## Viết ra vì tên file Mixamo không phân biệt được cú BỔ với cú CHÉM NGANG, mà
## dự án này bắt buộc phải phân biệt: `moveset.csv` khai đòn nặng của kiếm hai
## tay tên là "Bổ". Ghép nhầm một clip vung ngang vào đó thì người chơi đọc
## đòn nặng ra thành đòn nhẹ, và luật "đọc được đòn là nửa cơ chế" gãy ngay.
##
##   CAO/THAP  tay phải lên cao nhất / xuống thấp nhất, mét, so với chân
##   DOC       chênh lệch dọc. Lớn = bổ từ trên xuống
##   NGANG     bề rộng quét ngang. Lớn = chém ngang
##   HONG      hông thấp nhất — dưới 0.75m là đang KHOM, không dùng được
const THU_MUC := "res://assets/model/dong_tac/goc/"
const MODEL := "res://assets/model/nhan_vat_chinh.fbx"
const TAY := "mixamorig_RightHand"
const HONG := "mixamorig_Hips"
const SO_MAU := 24

var _xuong: Skeleton3D
var _may: AnimationPlayer

func _ready() -> void:
	var canh := load(MODEL) as PackedScene
	var g := canh.instantiate()
	add_child(g)
	_xuong = _tim_xuong(g)
	if _xuong == null:
		print("Model khong co Skeleton3D")
		get_tree().quit(1)
		return
	_may = AnimationPlayer.new()
	add_child(_may)
	_may.root_node = _may.get_path_to(_xuong.get_parent())

	print("")
	print("| clip | dài | cao | thấp | dọc | ngang | hông | chân |")
	print("|---|---|---|---|---|---|---|---|")
	var d := DirAccess.open(THU_MUC)
	var ds: Array[String] = []
	for f in d.get_files():
		var ten := f.trim_suffix(".import")
		if ten.ends_with(".fbx") and not ds.has(ten):
			ds.append(ten)
	ds.sort()
	for ten in ds:
		await _soi(THU_MUC + ten, ten)
	print("")
	get_tree().quit()

func _soi(duong: String, ten: String) -> void:
	var a := _rut(duong)
	if a == null:
		return
	_sua_duong(a)
	var thu := AnimationLibrary.new()
	thu.add_animation("x", a)
	if _may.has_animation_library(""):
		_may.remove_animation_library("")
	_may.add_animation_library("", thu)

	var i_tay := _xuong.find_bone(TAY)
	var i_hong := _xuong.find_bone(HONG)
	var i_ct := _xuong.find_bone("mixamorig_LeftFoot")
	var i_cp := _xuong.find_bone("mixamorig_RightFoot")
	var lech_chan := 0.0
	var cao := -99.0
	var thap := 99.0
	var x_min := 99.0
	var x_max := -99.0
	var hong_thap := 99.0
	for n in SO_MAU:
		_may.play("x")
		_may.seek(a.length * float(n) / float(SO_MAU - 1), true)
		await get_tree().process_frame
		var t: Vector3 = _xuong.get_bone_global_pose(i_tay).origin
		var h: Vector3 = _xuong.get_bone_global_pose(i_hong).origin
		cao = maxf(cao, t.y)
		thap = minf(thap, t.y)
		x_min = minf(x_min, t.x)
		x_max = maxf(x_max, t.x)
		lech_chan += (_xuong.get_bone_global_pose(i_ct).origin.x
			- _xuong.get_bone_global_pose(i_cp).origin.x)
		hong_thap = minf(hong_thap, h.y)
	_may.stop()
	print("| %s | %.2fs | %.2f | %.2f | %.2f | %.2f | %.2f | %+.3f |"
		% [ten.trim_suffix(".fbx"), a.length, cao, thap,
			cao - thap, x_max - x_min, hong_thap,
			lech_chan / float(SO_MAU)])

## Bẻ rãnh về bộ xương của model — xem ghi chú cùng tên trong than_mo_hinh.gd.
func _sua_duong(a: Animation) -> void:
	for i in range(a.get_track_count() - 1, -1, -1):
		var x := a.track_get_path(i).get_concatenated_subnames()
		if x == "" or _xuong.find_bone(x) < 0:
			a.remove_track(i)
			continue
		a.track_set_path(i, NodePath("%s:%s" % [_xuong.name, x]))

func _rut(duong: String) -> Animation:
	if not ResourceLoader.exists(duong):
		return null
	var canh := load(duong) as PackedScene
	if canh == null:
		return null
	var g := canh.instantiate()
	var ap := _tim_may(g)
	var ra: Animation = null
	if ap != null:
		for t in ap.get_animation_list():
			var a := ap.get_animation(t)
			if a != null and a.length > 0.01:
				ra = a.duplicate()
				break
	g.queue_free()
	return ra

func _tim_xuong(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var k := _tim_xuong(c)
		if k != null:
			return k
	return null

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null
