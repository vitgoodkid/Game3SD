extends Node3D

## Phòng thử — mốc 1 và 2 của lộ trình.
##
## Đây KHÔNG phải map thật. Đây là chỗ để trả lời đúng một câu hỏi: đánh nhau
## đã ra chất souls chưa (mục 12, mốc 2 — "điểm quyết định"). Nên nó cố tình
## trống trải, bằng phẳng, có đúng vài cột để thử camera va tường và vài con
## quái đứng cách nhau để thử khoá mục tiêu.
##
## Ba con số cần tune ở đây nằm trong souls_like.gd (mục 5.2):
##   iframe_lan, tre_hoi_the_luc, và t_hoi của đòn nặng trong data/moveset.csv.

const CANH_QUAI := preload("res://scenes/quai/quai.tscn")

## Quái đặt sẵn: mã trong quai.csv + chỗ đứng.
const DAT_QUAI := [
	{"ma": "bu_nhin", "tai": Vector3(0, 0, -9)},
	{"ma": "soi_bien", "tai": Vector3(-8, 0, -13)},
	{"ma": "linh_ria", "tai": Vector3(9, 0, -12)},
	{"ma": "bo_cat", "tai": Vector3(-14, 0, 6)},
]

## Đồ đặt sẵn dưới đất cho lần chơi đầu. Hạt giống cố định nên chạy lại bao
## nhiêu lần cũng ra đúng ba món ấy — cần thế để tune, và để bắt được lỗi
## "món này sinh ra sai" mà không phải đánh quái mười lần cầu may.
const DAT_DO := [
	{"hat": 20260914, "tai": Vector3(2.5, 0, 2.0)},
	{"hat": 777001, "tai": Vector3(-3.0, 0, 1.0)},
	{"hat": 424242, "tai": Vector3(-1.0, 0, -3.0)},
]

## Đồ mặc sẵn cho lần chơi đầu: một vũ khí và một khiên, hạt cố định.
##
## Không có khiên thì KHÔNG THỬ ĐƯỢC nửa hệ phòng thủ — parry cần khiên, đòn
## phản đỡ cần đỡ trúng trước, vỡ đỡ cần có gì đó để đỡ. Mà vào phòng thử tay
## không thì muốn thử mấy cái đó phải nhặt đồ dưới đất rồi cầu may nó rơi ra
## đúng khiên. Đây là PHÒNG THỬ, không phải chỗ mở đầu của game thật — vùng
## thật sau này đừng chép đoạn này.
##
## Hai chữ trung tâm không viết trong code: `sinh_theo_loai` bốc chúng từ
## nguyen_lieu.csv theo cột `loai` (luật 1 của CLAUDE.md).
## Hạt cố định, chọn tay: hạt này cho ra KIẾM chứ không phải rìu hay cung.
## Kiếm là nhịp trung tính — rìu quá chậm để cảm được cửa sổ né, cung thì
## không thử được đòn cận chiến nào. Đổi hạt là đổi vũ khí khởi đầu; muốn thử
## SIÊU GIÁP cho rõ thì đổi sang hạt ra rìu (31337), vì rìu là lớp duy nhất có
## siêu giáp ngay cả ở đòn nhẹ.
const HAT_VU_KHI := 1000
const HAT_KHIEN := 1000

func _ready() -> void:
	_dung_san()
	_dung_cot()
	_dat_quai()
	_dat_do()
	_trang_bi_san()
	# Nghỉ ở bia và hồi sinh sau khi chết đều làm quái sống lại hết — đó là
	# luật souls, và cũng là cái giá của việc được cứu (mục 4.5).
	TheGioi.nghi_bia_da.connect(func(_ma: String) -> void: _dat_lai_quai())
	TheGioi.hoi_sinh.connect(_dat_lai_quai)

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

## Xoá sạch quái đang có rồi đặt lại từ đầu. Phải xoá trước: TheGioi vừa quên
## hết bảng "đã hạ", nên con đang còn sống cũng sẽ được sinh thêm một bản nữa.
func _dat_lai_quai() -> void:
	for q in get_tree().get_nodes_in_group("quai"):
		q.queue_free()
	_dat_quai()

## Ba món nằm sẵn dưới đất. Không có chúng thì người chơi vào phòng thử với hai
## bàn tay không, mà tay không thì màn hành trang trống trơn và cả cơ chế ???
## không có gì để hiện.
func _dat_do() -> void:
	for d in DAT_DO:
		var mon := SinhMonDo.sinh_mon("thi_tran", int(d["hat"]))
		if mon != null:
			add_child(VatRoi.tao(mon, d["tai"]))

## Nhét sẵn một vũ khí và một khiên vào túi rồi mặc lên.
##
## KHÔNG dạy chữ kèm theo. Vũ khí hiện tên đầy □ và chỉ số ???, và nó PHẢI như
## thế — đó là cơ chế xương sống của game (mục 4.1), không phải thứ được tắt đi
## cho tiện thử. Đồ vẫn đánh được bình thường: chữ chưa đọc được chỉ giấu phần
## CỘNG THÊM, không đụng vào chỉ số gốc (luật 4).
func _trang_bi_san() -> void:
	# Chơi tiếp một ván cũ thì đã có đồ rồi, đừng nhét thêm mỗi lần vào phòng.
	if Tui.vu_khi_dang_cam() != null or Tui.tay_trai_dang_cam() != null:
		return
	var vk := SinhMonDo.sinh_theo_loai("vukhi", "thi_tran", HAT_VU_KHI)
	if vk != null:
		Tui.nhat(vk)
		Tui.mac_vao(vk, "vu_khi")
	var kh := SinhMonDo.sinh_theo_loai("khien", "thi_tran", HAT_KHIEN)
	if kh != null:
		Tui.nhat(kh)
		Tui.mac_vao(kh, "tay_trai")
