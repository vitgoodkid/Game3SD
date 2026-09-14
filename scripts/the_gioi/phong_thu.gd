extends Node3D

## Phòng thử — mốc 1 và 2 của lộ trình.
##
## Đây KHÔNG phải map thật. Đây là chỗ để trả lời đúng một câu hỏi: đánh nhau
## đã ra chất souls chưa (mục 12, mốc 2 — "điểm quyết định"). Nên nó cố tình
## trống trải, bằng phẳng, có đúng vài cột để thử camera va tường và vài con
## quái đứng cách nhau để thử khoá mục tiêu.
##
## Ba con số cần tune ở đây nằm trong souls_like.gd (mục 5.2):
##   iframe_lan, khung_the_luc, và t_hoi của đòn nặng trong data/moveset.csv.

const CANH_QUAI := preload("res://scenes/quai/quai.tscn")

## Quái đặt sẵn: mã trong quai.csv + chỗ đứng.
const DAT_QUAI := [
	{"ma": "bu_nhin", "tai": Vector3(0, 0, -9)},
	{"ma": "soi_bien", "tai": Vector3(-8, 0, -13)},
	{"ma": "linh_ria", "tai": Vector3(9, 0, -12)},
	{"ma": "bo_cat", "tai": Vector3(-14, 0, 6)},
]

func _ready() -> void:
	_dung_san()
	_dung_cot()
	_dat_quai()

func _dung_san() -> void:
	var than := StaticBody3D.new()
	than.name = "San"
	than.collision_layer = 1
	add_child(than)

	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(70, 1, 70)
	m.mesh = b
	m.position = Vector3(0, -0.5, 0)
	m.material_override = _vat_lieu(Color(0.30, 0.31, 0.29))
	than.add_child(m)

	var va := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(70, 1, 70)
	va.shape = s
	va.position = Vector3(0, -0.5, 0)
	than.add_child(va)

	# Bốn bức tường để không lăn ra khỏi mép, và để thử camera va tường.
	for i in 4:
		var goc := float(i) * PI * 0.5
		_khoi(than, Vector3(sin(goc) * 35.0, 2.0, cos(goc) * 35.0),
			Vector3(70, 4, 1) if i % 2 == 0 else Vector3(1, 4, 70),
			Color(0.24, 0.25, 0.26))

func _dung_cot() -> void:
	var than := StaticBody3D.new()
	than.name = "Cot"
	than.collision_layer = 1
	add_child(than)
	# Cột đặt lệch nhau, không đối xứng — camera SpringArm3D phải va vào thứ
	# gì đó mới biết nó có hoạt động không.
	for tai in [Vector3(5, 0, 3), Vector3(-6, 0, -4), Vector3(12, 0, -7),
			Vector3(-11, 0, 9), Vector3(2, 0, -16)]:
		_khoi(than, tai + Vector3(0, 2.5, 0), Vector3(1.6, 5, 1.6),
			Color(0.38, 0.36, 0.33))

func _khoi(cha: StaticBody3D, tai: Vector3, co: Vector3, mau: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = co
	m.mesh = b
	m.position = tai
	m.material_override = _vat_lieu(mau)
	cha.add_child(m)
	var va := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = co
	va.shape = s
	va.position = tai
	cha.add_child(va)

func _vat_lieu(mau: Color) -> StandardMaterial3D:
	var v := StandardMaterial3D.new()
	v.albedo_color = mau
	v.roughness = 0.95
	return v

func _dat_quai() -> void:
	for d in DAT_QUAI:
		var q := CANH_QUAI.instantiate() as Quai
		q.ma = String(d["ma"])
		q.ma_vung = "thi_tran"
		q.position = d["tai"]
		add_child(q)
