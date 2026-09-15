class_name Quai
extends CharacterBody3D

## Quái. Mọi thông số đọc từ data/quai.csv — không hardcode con nào trong code.
##
## Linh hồn của souls-like nằm ở một câu (mục 5.4): ĐÒN PHẢI ĐỌC ĐƯỢC. Mỗi
## đòn có khung vung tay rõ ràng, nhìn là biết né hướng nào. Quan trọng hơn
## mọi thứ khác — hơn cả model đẹp, hơn cả số lượng loài.
##
## Ở bản khối hộp này, "đọc được" thể hiện bằng: thân ngả về sau rõ rệt trong
## khung vung tay, và thời gian vung KHÔNG dưới 0.5s cho mọi đòn.

signal doi_mau(mau: float, toi_da: float)
signal chet_roi(q: Quai)

const TRONG_LUC := 24.0

## Mã trong quai.csv. Đặt trong editor hoặc lúc sinh ra.
@export var ma := "bu_nhin"
## Mã vùng, để tính id ổn định cho việc hồi sinh.
@export var ma_vung := "thi_tran"

@onready var may: MayTrangThai = $May
@onready var than: Node3D = $Than
@onready var hop_don: Area3D = $Than/HopDon
@onready var hinh: CollisionShape3D = $Hinh

var d := {}                 ## dòng dữ liệu trong quai.csv
var mau := 100.0
var mau_toi_da := 100.0
var tu_the := 0.0
var tu_the_max := 100.0
var ngu_hanh := ""
var nguoi_choi: Node3D = null
## Điểm đặt ban đầu — quay về đây khi mất dấu người chơi.
var diem_goc := Vector3.ZERO
var id_on_dinh := ""
## Vỡ tư thế: đứng ngây cho ăn đòn kết liễu.
var dang_ngay := false

func _ready() -> void:
	add_to_group("quai")
	diem_goc = global_position
	id_on_dinh = TheGioi.id_quai(ma_vung, diem_goc)
	if TheGioi.da_ha(id_on_dinh):
		queue_free()
		return
	_nap_du_lieu()
	nguoi_choi = get_tree().get_first_node_in_group("nguoi_choi")
	may.khoi_dong(self)

func _nap_du_lieu() -> void:
	d = VocabDB.quai_cua(ma)
	if d.is_empty():
		push_warning("Khong co quai '%s' trong quai.csv" % ma)
		d = {}
	mau_toi_da = float(d.get("mau", 100))
	mau = mau_toi_da
	tu_the_max = float(d.get("the_dung", 30)) * 2.2 + 40.0
	ngu_hanh = String(d.get("ngu_hanh", ""))
	var cao := float(d.get("cao", 1.8))
	var bk := float(d.get("ban_kinh", 0.5))
	var c := hinh.shape as CapsuleShape3D
	if c != null:
		c.height = cao
		c.radius = bk
	hinh.position.y = cao * 0.5
	var tk := than as ThanQuai
	if tk != null:
		tk.dung_theo(cao, bk, ngu_hanh, ten_hien())
		tk.cap_nhat(ten_hien(), 1.0)
	# Ghép được chữ trong tên nó thì tên trên đầu sáng ra ngay, không cần
	# đánh lại con nào — đúng tinh thần mục 4.1 áp cho quái.
	Tui.doi_trang_bi.connect(_cap_nhat_nhan)
	doi_mau.emit(mau, mau_toi_da)

func _cap_nhat_nhan() -> void:
	var tk := than as ThanQuai
	if tk != null:
		tk.cap_nhat(ten_hien(), mau / maxf(mau_toi_da, 1.0))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= TRONG_LUC * delta
	tu_the = maxf(0.0, tu_the - SoulsLike.TU_THE_TUT_MOI_GIAY * delta)
	may.chay(delta)
	move_and_slide()
	var tk := than as ThanQuai
	if tk != null:
		tk.dien(may.ten_hien_tai, may.hien_tai.tien_do() if may.hien_tai != null else 0.0, delta)

# --- Tra cứu --------------------------------------------------------

func con_song() -> bool:
	return mau > 0.0

## Tên hiện trên đầu quái. Quái vô danh (chưa hạ lần nào) hiện □□ — mục 7.5.
## Đây cũng là chỗ dạy chữ thụ động: đi qua là thấy, lặp lại không bị bắt học.
func ten_hien() -> String:
	var tc := String(d.get("ten_chu", ""))
	if tc == "":
		return String(d.get("ten", "?"))
	var s := ""
	for c in tc:
		s += c if TriNho.doc_duoc(c) else TenDoVat.CHU_MO
	return s

func xa_nguoi_choi() -> float:
	if nguoi_choi == null:
		return 9999.0
	return global_position.distance_to(nguoi_choi.global_position)

func thay_nguoi_choi() -> bool:
	return nguoi_choi != null and xa_nguoi_choi() <= float(d.get("tam_phat_hien", 14))

func trong_tam_danh() -> bool:
	return nguoi_choi != null and xa_nguoi_choi() <= float(d.get("tam_danh", 2.2))

## Danh sách đòn của con này, khai ở cột `moveset` của quai.csv.
func cac_don() -> Array:
	var m: Array = d.get("moveset", [])
	return m if not m.is_empty() else ["bo_cham"]

# --- Di chuyển ------------------------------------------------------

func di_ve(dich: Vector3, toc: float, delta: float) -> void:
	var v := dich - global_position
	v.y = 0.0
	if v.length() < 0.15:
		dung_lai(delta)
		return
	v = v.normalized()
	velocity.x = v.x * toc
	velocity.z = v.z * toc
	xoay_ve(v, delta)

func dung_lai(delta: float, ma_sat: float = 16.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ma_sat * delta)
	velocity.z = move_toward(velocity.z, 0.0, ma_sat * delta)

func xoay_ve(huong: Vector3, delta: float, toc: float = 7.0) -> void:
	var h := huong
	h.y = 0.0
	if h.length_squared() < 0.001:
		return
	than.rotation.y = lerp_angle(than.rotation.y, atan2(h.x, h.z), minf(1.0, toc * delta))

func huong_toi_nguoi_choi() -> Vector3:
	if nguoi_choi == null:
		return Vector3.ZERO
	var v := nguoi_choi.global_position - global_position
	v.y = 0.0
	return v.normalized()

# --- Ăn đòn ---------------------------------------------------------

## Chịu một đòn. Trả về sát thương thực đã ăn.
##
## Ngũ hành xử ở đây (mục 4.4). Hệ số ÂM nghĩa là quái HỒI máu — dùng vũ khí
## sinh ra hành của nó là tự hại. Không clamp về 0: đó chính là hình phạt.
func an_don(sat_thuong: int, pha_the: float, tu_dau: Vector3, hanh: String = "") -> int:
	if not con_song():
		return 0

	var st := float(sat_thuong)
	var hs := NguHanh.he_so(hanh, ngu_hanh)
	st *= hs
	st -= float(d.get("giap", 0))
	# Luôn ăn ít nhất một máu. Trước đây câu này có điều kiện `hs > 0.0` vì hệ
	# số ngũ hành từng ÂM (quái hồi máu); giờ hệ số thấp nhất là 0.25 nên không
	# còn đường nào cho sát thương âm, và cũng không được phép có — xem
	# NguHanh.HS_SINH.
	st = maxf(float(ChienDau.DON_TOI_THIEU), st)

	mau = clampf(mau - st, 0.0, mau_toi_da)
	doi_mau.emit(mau, mau_toi_da)
	_cap_nhat_nhan()
	_bao_so(int(round(st)), hs, hanh)

	AmThanh.phat("trung_to" if st >= 40.0 else "trung",
		1.0 / clampf(float(d.get("cao", 1.8)) / 1.8, 0.7, 2.0))
	if mau <= 0.0:
		may.doi("quai_chet")
		AmThanh.phat("chet_quai")
		return int(round(st))

	# Vỡ tư thế → đứng ngây cho ăn đòn kết liễu (mục 5.1).
	# xin_doi() chứ không doi() — cùng lý do như NguoiChoi.an_don(): con quái
	# đang đứng ngây cho ăn kết liễu thì một đòn vặt không được cắt ngang cửa
	# sổ đó (quai_vo_the.cho_doi chặn). Đường CHẾT ở trên vẫn đổi thẳng.
	tu_the += pha_the
	if tu_the >= tu_the_max:
		tu_the = 0.0
		may.xin_doi("quai_vo_the")
	elif SoulsLike.co_khung(float(d.get("the_dung", 30)), pha_the):
		may.xin_doi("quai_trung_don", {"tu_dau": tu_dau})
	elif may.ten_hien_tai in ["quai_dung", "quai_tuan", "quai_duoi"]:
		# Bị đánh lén thì quay lại đánh, kể cả khi chưa thấy người chơi.
		may.xin_doi("quai_duoi")
	return int(round(st))

func _bao_so(st: int, hs: float, hanh: String) -> void:
	var tk := than as ThanQuai
	if tk == null:
		return
	var ghi := ""
	if hs != 1.0:
		ghi = NguHanh.giai_thich(hanh, ngu_hanh)
	tk.so_bay(st, hs, ghi)

## Đối phương đỡ phản trúng đòn của mình → đứng ngây.
func bi_do_phan() -> void:
	may.xin_doi("quai_vo_the", {"lau": SoulsLike.NGAY_SAU_DO_PHAN})

# --- Chết -----------------------------------------------------------

## Rơi hồn và bộ thủ. Đây là chỗ nối lịch ôn vào vòng lặp chơi (mục 4.7):
## quái ƯU TIÊN rơi bộ thủ của chữ đang sắp phai. Người chơi được đưa đúng
## thứ mình cần ôn mà không hề thấy bị bắt học.
func roi_do() -> void:
	Tui.them_hon(int(d.get("hon", 10)))
	TheGioi.danh_dau_ha(id_on_dinh)
	_roi_mon_do()

	var can_on := TriNho.chu_nen_roi()
	if can_on != "" and randf() < 0.55:
		for bt in _bo_thu_cua(can_on):
			Tui.them_bo_thu(String(bt))
		return

	var bang: Array = d.get("rot_bo_thu", [])
	if bang.is_empty():
		return
	Tui.them_bo_thu(String(bang.pick_random()))

func _bo_thu_cua(chu: String) -> Array:
	var bt: Array = VocabDB.tu_cua(chu).get("bo_thu", [])
	return bt if not bt.is_empty() else [chu]

## Rơi một món đồ ra đất. Xác suất suy thẳng từ số hồn con này cho — con càng
## hiếm càng hay rơi đồ — nên thêm quái mới vào quai.csv là có ngay tỉ lệ rơi
## hợp lý, không phải khai thêm cột nào.
func _roi_mon_do() -> void:
	var ti := clampf(float(d.get("hon", 10)) / 900.0, 0.06, 0.45)
	if randf() > ti:
		return
	var mon := SinhMonDo.sinh_mon(ma_vung)
	var cha := get_parent()
	if mon == null or cha == null:
		return
	# Thêm node giữa lúc chạy vật lý phải hoãn lại — Area3D dựng ngay tại đây
	# là dựng trong lúc Jolt đang duyệt truy vấn va chạm.
	cha.add_child.call_deferred(
		VatRoi.tao(mon, global_position + Vector3(0, 0.05, 0)))
