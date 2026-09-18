extends Node

## Soi từng file động tác trong `assets/model/dong_tac/goc/`.
##
##     godot --headless --path . tools/soi_dong_tac.tscn
##
## Viết ra vì tên file Mixamo không nói được điều cần biết. "great sword slash"
## với "great sword slash (2)" nhìn tên là một cặp; nhìn số đo thì một cái vung
## ngang 1.1 giây còn cái kia bổ dọc 2.4 giây — ghép nhầm là cả combo lệch nhịp.
##
## Bốn con số, mỗi con trả lời một câu hỏi không nhìn tên mà biết:
##
##   DÀI       clip đánh phải co giãn về đúng nhịp `moveset.csv`; clip nào
##             dài gấp ba thì kéo về sẽ thành phim tua nhanh
##   TRÔI      hông đi được bao xa. Mixamo "In Place" thì ~0. Khác 0 nghĩa là
##             clip TỰ đẩy nhân vật, đánh nhau với `move_and_slide()`
##   XOAY      hông xoay bao nhiêu độ. Clip xoay 180° mà dùng làm dáng đứng thì
##             nhân vật tự quay lưng lại với con quái
##   HỞ        lệch giữa khung đầu và khung cuối. Gần 0 mới lặp được —
##             `dung`/`di`/`chay`/`do_don` bắt buộc phải lặp
const THU_MUC := "res://assets/model/dong_tac/goc/"
const XUONG_HONG := "mixamorig_Hips"

func _ready() -> void:
	print("")
	print("| file | dài | trôi | xoay | hở | rãnh |")
	print("|---|---|---|---|---|---|")
	var d := DirAccess.open(THU_MUC)
	if d == null:
		print("Khong mo duoc ", THU_MUC)
		get_tree().quit(1)
		return
	var ds: Array[String] = []
	for f in d.get_files():
		var ten := f.trim_suffix(".import")
		if ten.ends_with(".fbx") and not ds.has(ten):
			ds.append(ten)
	ds.sort()
	for ten in ds:
		_soi(THU_MUC + ten, ten)
	print("")
	get_tree().quit()

func _soi(duong: String, ten: String) -> void:
	var a := _rut(duong)
	if a == null:
		print("| %s | — | — | — | — | KHONG DOC DUOC |" % ten)
		return
	var troi := _troi(a)
	var xoay := _xoay(a)
	var ho := _ho(a)
	print("| %s | %.2fs | %.2fm | %.0f° | %.3f | %d |"
		% [ten.trim_suffix(".fbx"), a.length, troi, xoay, ho, a.get_track_count()])

## Hông đi xa nhất bao nhiêu so với khung đầu.
func _troi(a: Animation) -> float:
	var i := _ranh_vi_tri(a)
	if i < 0:
		return 0.0
	var dau: Vector3 = a.track_get_key_value(i, 0)
	var xa := 0.0
	for k in a.track_get_key_count(i):
		var v: Vector3 = a.track_get_key_value(i, k)
		# Bỏ trục Y: nhảy và lăn nhấc người lên là ĐÚNG, chỉ trôi ngang mới sai.
		xa = maxf(xa, Vector2(v.x - dau.x, v.z - dau.z).length())
	return xa

func _xoay(a: Animation) -> float:
	var i := _ranh_xoay(a)
	if i < 0:
		return 0.0
	var dau: Quaternion = a.track_get_key_value(i, 0)
	var lon := 0.0
	for k in a.track_get_key_count(i):
		var q: Quaternion = a.track_get_key_value(i, k)
		lon = maxf(lon, rad_to_deg(dau.angle_to(q)))
	return lon

## Lệch tổng giữa khung đầu và khung cuối trên MỌI rãnh xoay.
func _ho(a: Animation) -> float:
	var tong := 0.0
	var dem := 0
	for i in a.get_track_count():
		if a.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var n := a.track_get_key_count(i)
		if n < 2:
			continue
		var q0: Quaternion = a.track_get_key_value(i, 0)
		var q1: Quaternion = a.track_get_key_value(i, n - 1)
		tong += q0.angle_to(q1)
		dem += 1
	return rad_to_deg(tong / maxf(1.0, float(dem)))

func _ranh_vi_tri(a: Animation) -> int:
	for i in a.get_track_count():
		if a.track_get_type(i) == Animation.TYPE_POSITION_3D \
				and String(a.track_get_path(i)).ends_with(XUONG_HONG):
			return i
	return -1

func _ranh_xoay(a: Animation) -> int:
	for i in a.get_track_count():
		if a.track_get_type(i) == Animation.TYPE_ROTATION_3D \
				and String(a.track_get_path(i)).ends_with(XUONG_HONG):
			return i
	return -1

func _rut(duong: String) -> Animation:
	if not ResourceLoader.exists(duong):
		return null
	var canh := load(duong) as PackedScene
	if canh == null:
		return null
	var g := canh.instantiate()
	var ap := _tim(g)
	var ra: Animation = null
	if ap != null:
		for t in ap.get_animation_list():
			var a := ap.get_animation(t)
			if a != null and a.length > 0.01:
				ra = a.duplicate()
				break
	g.queue_free()
	return ra

func _tim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim(c)
		if k != null:
			return k
	return null
