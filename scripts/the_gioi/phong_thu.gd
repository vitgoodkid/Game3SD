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
const CANH_BOSS := preload("res://scenes/quai/boss.tscn")

## Boss đặt ở góc xa — đủ xa để không lao vào giữa lúc đang thử đòn với quái
## thường, đủ gần để đi bộ tới trong mươi giây.
const DAT_BOSS := {"ma": "canh_hai", "tai": Vector3(0, 0, -26)}

## Quái đặt sẵn: mã trong quai.csv + chỗ đứng.
##
## Hai con ĐẦU là bù nhìn tập — cả hai đứng yên tuyệt đối (toc_do_di=0 lẫn
## toc_do_duoi=0 trong quai.csv), khác nhau đúng MỘT chỗ để so sánh cạnh nhau:
##
##   bu_nhin    tam_danh=2.2  → vào tầm là ĐÁNH TRẢ (bo_cham). Dùng để cảm
##              được nhịp qua lại thật, và thử đỡ/parry/vỡ đỡ.
##   hinh_nom   tam_phat_hien=0, tam_danh=0 → không bao giờ để ý người chơi,
##              KHÔNG BAO GIỜ đánh trả. `mau` để rất cao (999999) nên không lo
##              đấm chết giữa buổi tune. Dùng để đo sát thương/tốc độ đánh mà
##              không có gì chen vào — bao nhiêu đòn ra bấy nhiêu, không lệch
##              vì né/đỡ/phản đòn.
const DAT_QUAI := [
	{"ma": "bu_nhin", "tai": Vector3(0, 0, -9)},
	{"ma": "hinh_nom", "tai": Vector3(10, 0, 10)},
	{"ma": "soi_bien", "tai": Vector3(-8, 0, -13)},
	{"ma": "linh_ria", "tai": Vector3(9, 0, -12)},
	{"ma": "bo_cat", "tai": Vector3(-14, 0, 6)},
]

## Đồ đặt sẵn dưới đất cho lần chơi đầu. Hạt giống cố định nên chạy lại bao
## nhiêu lần cũng ra đúng ba món ấy — cần thế để tune, và để bắt được lỗi
## "món này sinh ra sai" mà không phải đánh quái mười lần cầu may.
## `loai` bỏ trống thì bốc ngẫu nhiên như đồ rơi thường.
##
## Món thứ ba CỐ Ý là vũ khí khác hệ với vũ khí khởi đầu. Trong phòng có một
## con hệ Thuỷ, mà vũ khí khởi đầu hệ Kim — Kim SINH Thuỷ, nghĩa là đánh nó
## bằng kiếm khởi đầu thì mỗi nhát chỉ ăn 1/4 (`NguHanh.HS_SINH`). Bài học đó
## chỉ dạy được nếu người chơi có đường ra: đổi sang 石剑 hệ Thổ là Thổ khắc
## Thuỷ, hạ trong bốn đòn thay vì mười sáu.
const DAT_DO := [
	{"hat": 20260914, "tai": Vector3(2.5, 0, 2.0)},
	{"hat": 777001, "tai": Vector3(-3.0, 0, 1.0)},
	{"hat": 1063, "loai": "vukhi", "tai": Vector3(-1.0, 0, -3.0)},
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
## Chữ trung tâm của vũ khí khởi đầu. Đổi chữ này là đổi hẳn loại vũ khí —
## moveset, sát thương, hình dáng đều đi theo nó (nguyen_lieu.csv + moveset.csv).
const CHU_VU_KHI_DAU := "刃"
const HAT_VU_KHI := 1000
const HAT_KHIEN := 1000

func _ready() -> void:
	_dung_san()
	_dung_cot()
	_dung_tru_leo()
	_dung_tuong_thap()
	_dat_quai()
	_dat_boss()
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

## Trụ mốc cho việc soi dáng "leo trèo" — KHÔNG PHẢI cơ chế leo trèo thật.
##
## Game chưa có leo trèo. `assets/model/dong_tac/chua_dung/leo_len.fbx` và
## `leo_xuong.fbx` đã tải về và ĐO XONG (xem DOC.md cùng thư mục: vòng lặp tại
## chỗ, 2.00s, hông đứng yên 0.69m) nhưng KHÔNG state nào tên `leo` cả — dựng
## trạm thang thật cần một `Area3D` đánh dấu trục leo, một state mới khoá di
## chuyển vào trục đó, và camera phải ngừng xoay tự do trong lúc leo (xem mục
## "CLIP LÀM CHỦ NHỊP" trong DOC_TRUOC.md của thư mục dong_tac). Đó là một
## tính năng riêng, chưa ai yêu cầu làm — trụ này CHỈ để có vật làm mốc tỉ lệ
## khi soi hai clip đó bằng `tools/soi_dong_tac.tscn` / `tools/chup_tu_the.tscn`
## đứng cạnh nhân vật, không có gì bấm được ở đây.
func _dung_tru_leo() -> void:
	var than := StaticBody3D.new()
	than.name = "TruLeo"
	than.collision_layer = 1
	add_child(than)

	const CAO := 3.2
	const BAN_KINH := 0.35
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.height = CAO
	c.top_radius = BAN_KINH
	c.bottom_radius = BAN_KINH
	m.mesh = c
	m.position = Vector3(10, CAO * 0.5, 16)
	m.material_override = _vat_lieu(Color(0.42, 0.30, 0.18))   # gỗ, khác màu cột đá
	than.add_child(m)

	var va := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.height = CAO
	s.radius = BAN_KINH
	va.shape = s
	va.position = m.position
	than.add_child(va)

## Tường thấp để soi dáng NHẢY — cơ chế nhảy đã có thật (state `nhay`), nên
## đây khác trụ leo ở trên: bấm được, chạy tới rồi nhảy qua là thấy ngay.
##
## Cao 0.9m — thấp hơn hẳn đỉnh vòng nhảy (LUC_NHAY²/(2·TRONG_LUC) ≈ 1.33m ở
## NguoiChoi), nên nhảy thẳng qua được không cần chạy lấy đà. Mỏng theo trục
## Z (0.6m) để một cú nhảy bình thường đủ xa quét qua hết bề dày, và RỘNG theo
## X (6m) để không phải căn hướng chính xác mới nhảy trúng.
func _dung_tuong_thap() -> void:
	var than := StaticBody3D.new()
	than.name = "TuongThap"
	than.collision_layer = 1
	add_child(than)
	const CAO := 0.9
	_khoi(than, Vector3(-16, CAO * 0.5, -20), Vector3(6, CAO, 0.6),
		Color(0.5, 0.48, 0.44))

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

func _dat_boss() -> void:
	var b := CANH_BOSS.instantiate() as Boss
	b.ma = String(DAT_BOSS["ma"])
	b.ma_vung = "thi_tran"
	b.position = DAT_BOSS["tai"]
	add_child(b)

## Xoá sạch quái đang có rồi đặt lại từ đầu. Phải xoá trước: TheGioi vừa quên
## hết bảng "đã hạ", nên con đang còn sống cũng sẽ được sinh thêm một bản nữa.
func _dat_lai_quai() -> void:
	# CHỪA BOSS RA. Boss nằm trong cả nhóm "quai" lẫn nhóm "boss", nên vòng lặp
	# này quét trúng nó — mà boss KHÔNG sống lại khi nghỉ ở bia. Souls-like: hạ
	# boss là hạ xong; dựng nó dậy thì cửa boss thành chỗ cày hồn.
	#
	# Và đừng thay bằng "xoá hết rồi kiểm nhóm boss còn trống không" — bẫy
	# queue_free(): node vẫn nằm trong nhóm tới hết khung hình, nên kiểm ngay
	# sau đó là nhìn hụt, boss biến mất luôn. Đã dính.
	for q in get_tree().get_nodes_in_group("quai"):
		if q.is_in_group("boss"):
			continue
		q.queue_free()
	_dat_quai()

## Ba món nằm sẵn dưới đất. Không có chúng thì người chơi vào phòng thử với hai
## bàn tay không, mà tay không thì màn hành trang trống trơn và cả cơ chế ???
## không có gì để hiện.
func _dat_do() -> void:
	for d in DAT_DO:
		var loai := String(d.get("loai", ""))
		var mon := SinhMonDo.sinh_theo_loai(loai, "thi_tran", int(d["hat"])) 			if loai != "" else SinhMonDo.sinh_mon("thi_tran", int(d["hat"]))
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
	# Phát thẳng KIẾM HAI TAY làm vũ khí khởi đầu. `sinh_theo_loai` bốc ngẫu
	# nhiên trong đám vũ khí, mà phòng thử là chỗ tune combat nên phải biết
	# chắc mình đang cầm gì.
	var vk := SinhMonDo.sinh_mon_tu_chu(CHU_VU_KHI_DAU, "thi_tran", HAT_VU_KHI)
	if vk == null:
		vk = SinhMonDo.sinh_theo_loai("vukhi", "thi_tran", HAT_VU_KHI)
	if vk != null:
		Tui.nhat(vk)
		Tui.mac_vao(vk, "vu_khi")
	var kh := SinhMonDo.sinh_theo_loai("khien", "thi_tran", HAT_KHIEN)
	if kh != null:
		Tui.nhat(kh)
		Tui.mac_vao(kh, "tay_trai")
