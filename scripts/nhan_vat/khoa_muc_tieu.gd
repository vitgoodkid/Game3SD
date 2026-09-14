class_name KhoaMucTieu
extends Node

## Khoá mục tiêu. Chuột giữa / Tab bật tắt; J / L đổi sang mục tiêu trái/phải.
##
## Quy tắc chọn mục tiêu của souls-like không phải "con gần nhất" mà là "con
## người chơi đang NHÌN". Con quái ngay sau lưng gần hơn con trước mặt, nhưng
## khoá vào nó là sai ý người chơi mọi lần.

## Chỉ khoá được trong tầm này. Xa hơn thì tự nhả — chạy khỏi trận đánh mà
## camera vẫn dính vào con quái cũ là chuyện khó chịu.
const TAM_KHOA := 22.0
const TAM_NHA := 28.0
## Góc lệch tối đa so với hướng camera đang nhìn (cosin).
const COS_TRONG_TAM := 0.30

var _nc: NguoiChoi = null
var _cam: CameraBaCheDo = null

func _ready() -> void:
	_nc = get_parent() as NguoiChoi
	_cam = _nc.get_node("GiaCamera") as CameraBaCheDo

func _process(_delta: float) -> void:
	if _nc.muc_tieu == null:
		return
	if not is_instance_valid(_nc.muc_tieu) \
			or _nc.global_position.distance_to(_nc.muc_tieu.global_position) > TAM_NHA \
			or (_nc.muc_tieu.has_method("con_song") and not _nc.muc_tieu.con_song()):
		# Mục tiêu chết thì tự nhảy sang con kế tiếp đang đánh mình, không có
		# thì nhả hẳn. Bắt bấm lại giữa đám đông là ức chế.
		_nc.dat_muc_tieu(_gan_nhat_trong_tam())

func bat_tat() -> void:
	if _nc.muc_tieu != null:
		_nc.dat_muc_tieu(null)
		return
	_nc.dat_muc_tieu(_gan_nhat_trong_tam())

func _unhandled_input(su_kien: InputEvent) -> void:
	if _nc.muc_tieu == null:
		return
	if su_kien.is_action_pressed("doi_muc_tieu_trai"):
		_doi_ben(-1.0)
	elif su_kien.is_action_pressed("doi_muc_tieu_phai"):
		_doi_ben(1.0)

## Mục tiêu hợp lệ: còn sống, trong tầm, và nằm trong nón nhìn của camera.
func _ung_vien() -> Array:
	var ds: Array = []
	var goc := _huong_nhin()
	for q in get_tree().get_nodes_in_group("quai"):
		if not (q is Node3D) or not is_instance_valid(q):
			continue
		if q.has_method("con_song") and not q.con_song():
			continue
		var v: Vector3 = (q as Node3D).global_position - _nc.global_position
		var d := v.length()
		if d > TAM_KHOA:
			continue
		v.y = 0.0
		if v.normalized().dot(goc) < COS_TRONG_TAM:
			continue
		ds.append({"nut": q, "xa": d, "huong": v.normalized()})
	return ds

func _huong_nhin() -> Vector3:
	if _cam == null:
		return _nc.huong_mat()
	var h := -_cam.global_transform.basis.z
	h.y = 0.0
	return h.normalized()

func _gan_nhat_trong_tam() -> Node3D:
	var ds := _ung_vien()
	if ds.is_empty():
		return null
	# Xếp theo độ lệch góc trước, khoảng cách sau: con đang nhìn thẳng thắng
	# con ở rìa màn hình dù con ở rìa gần hơn.
	var goc := _huong_nhin()
	ds.sort_custom(func(a, b):
		var da: float = float(a["huong"].dot(goc)) - float(a["xa"]) * 0.012
		var db: float = float(b["huong"].dot(goc)) - float(b["xa"]) * 0.012
		return da > db)
	return ds[0]["nut"] as Node3D

## Đổi mục tiêu sang bên trái (-1) hoặc phải (+1) so với mục tiêu hiện tại.
func _doi_ben(ben: float) -> void:
	var goc := _huong_nhin()
	var phai := goc.cross(Vector3.UP).normalized() * -1.0
	var hien := (_nc.muc_tieu.global_position - _nc.global_position)
	hien.y = 0.0
	var moc := hien.normalized().dot(phai)

	var tot: Node3D = null
	var tot_d := 99.0
	for u in _ung_vien():
		if u["nut"] == _nc.muc_tieu:
			continue
		var d: float = float(u["huong"].dot(phai)) - moc
		if d * ben <= 0.0:
			continue          # sai bên
		if absf(d) < tot_d:
			tot_d = absf(d)
			tot = u["nut"] as Node3D
	if tot != null:
		_nc.dat_muc_tieu(tot)
