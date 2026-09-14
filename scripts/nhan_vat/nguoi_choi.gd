class_name NguoiChoi
extends CharacterBody3D

## Nhân vật người chơi. Mọi logic "đang làm gì" nằm ở máy trạng thái con;
## file này chỉ giữ SỐ LIỆU và những việc dùng chung mọi trạng thái.
##
## Ranh giới cố ý: file này không được có `if dang_danh` hay `if dang_lan`.
## Hỏi "đang làm gì" là việc của state. Ở đây chỉ có máu, thể lực, tốc độ,
## và các hàm mọi state đều gọi tới.

signal doi_mau(mau: float, toi_da: float)
signal doi_the_luc(tl: float, toi_da: float)
signal doi_muc_tieu(mt: Node3D)
signal da_chet
signal bao_ngu_hanh(chu: String)
## Ăn đòn từ hướng nào — HUD vẽ vệt đỏ rìa màn hình (bắt buộc ở góc nhìn 1).
signal bi_danh(tu_dau: Vector3)

const TRONG_LUC := 24.0            ## nặng hơn thực tế: nhảy lửng lơ là cảm giác tệ
const TOC_DO_DI := 4.2
const TOC_DO_CHAY := 7.4
const LUC_NHAY := 8.0
## Xoay người nhanh cỡ nào (radian/giây). Thấp quá thì điều khiển nhão,
## cao quá thì mất cảm giác quán tính của nhân vật có trọng lượng.
const TOC_XOAY := 12.0
## Giữ Space quá bấy nhiêu giây thì thành CHẠY, dưới thì là LĂN.
const NGUONG_GIU_CHAY := 0.22
## Đệm phím: bấm đánh trong lúc còn đang hồi đòn trước thì vẫn tính, miễn là
## sớm hơn bấy nhiêu giây. Không có đệm thì combo cảm giác như bị nuốt phím.
const DEM_NHAP := 0.35

@export var toc_do_di := TOC_DO_DI
@export var toc_do_chay := TOC_DO_CHAY

@onready var may: MayTrangThai = $May
@onready var gia_camera: Node3D = $GiaCamera
@onready var than: Node3D = $Than
@onready var hop_don: Area3D = $Than/GanTayPhai/HopDon
@onready var khoa: Node = $Khoa

var mau := 300.0
var mau_toi_da := 300.0
var the_luc := 100.0
var the_luc_max := 100.0
## Còn bao lâu nữa mới bắt đầu hồi thể lực (mục 5.1: khựng ~0.8s).
var khung_tl := 0.0
## Đang bất tử (i-frame giữa cú lăn).
var bat_tu := false
## Đang trong khung đỡ phản.
var dang_do_phan := false
## Đang giơ khiên.
var dang_do := false
## Thanh tư thế của chính mình — đầy thì vỡ, đứng ngây cho ăn đòn to.
var tu_the := 0.0
var tu_the_max := 100.0
## Hồi đòn sau khi lăn, để không spam lăn thành bất tử.
var hoi_lan := 0.0

## Hướng nhập vào từ WASD, đã quy về hệ toạ độ thế giới theo camera.
var huong_nhap := Vector3.ZERO
## Mục tiêu đang khoá (null = không khoá).
var muc_tieu: Node3D = null

var _dem := {}          ## phím đã bấm gần đây: tên -> thời điểm còn hiệu lực
var _giu_space := -1.0  ## bấm Space lúc nào (-1 = chưa bấm)

func _ready() -> void:
	add_to_group("nguoi_choi")
	mau_toi_da = Tui.mau_toi_da()
	mau = Tui.mau
	the_luc_max = Tui.the_luc_toi_da()
	the_luc = the_luc_max
	tu_the_max = SoulsLike.TU_THE_GOC + float(Tui.cs("韧")) * 1.5
	may.khoi_dong(self)
	Tui.doi_chi_so.connect(_cap_nhat_theo_chi_so)
	Tui.doi_trang_bi.connect(_cap_nhat_theo_chi_so)
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)

func _cap_nhat_theo_chi_so() -> void:
	var cu := mau_toi_da
	mau_toi_da = Tui.mau_toi_da()
	the_luc_max = Tui.the_luc_toi_da()
	tu_the_max = SoulsLike.TU_THE_GOC + float(Tui.cs("韧")) * 1.5
	# Nâng 体 thì máu tối đa tăng — cộng luôn phần chênh vào máu hiện tại,
	# nếu không thì nâng chỉ số xong lại thấy thanh máu ngắn đi tương đối.
	if mau_toi_da > cu:
		mau += mau_toi_da - cu
	mau = minf(mau, mau_toi_da)
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)

# --- Vòng lặp -------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= TRONG_LUC * delta
	hoi_lan = maxf(0.0, hoi_lan - delta)
	_hoi_the_luc(delta)
	_tut_tu_the(delta)
	_don_dem(delta)
	_doc_huong_nhap()
	may.chay(delta)
	move_and_slide()
	_dien_hinh(delta)

## Cầu nối duy nhất giữa logic và phần nhìn. Giữ nó đúng MỘT hàm để thay khối
## hộp bằng .glb + AnimationPlayer sau này chỉ phải sửa ở đây (mục 11).
func _dien_hinh(delta: float) -> void:
	var tk := than as ThanKhoi
	if tk == null:
		return
	var td := may.hien_tai.tien_do() if may.hien_tai != null else 0.0
	tk.dien(may.ten_hien_tai, td, huong_nhap != Vector3.ZERO, delta)

func _unhandled_input(su_kien: InputEvent) -> void:
	# Ghi đệm phím TRƯỚC khi đưa cho state: state đang bận hồi đòn vẫn phải
	# nhớ được là người chơi đã bấm, nếu không combo cảm giác bị nuốt phím.
	for ten in ["don_nhe", "don_nang", "do_phan", "nhay", "uong_binh"]:
		if su_kien.is_action_pressed(ten):
			_dem[ten] = DEM_NHAP

	if su_kien.is_action_pressed("lan_chay"):
		_giu_space = 0.0
	elif su_kien.is_action_released("lan_chay"):
		# Nhả sớm = lăn. Nhả muộn = vừa chạy xong, không lăn.
		if _giu_space >= 0.0 and _giu_space < NGUONG_GIU_CHAY:
			_dem["lan"] = DEM_NHAP
		_giu_space = -1.0

	if su_kien.is_action_pressed("doi_vu_khi"):
		Tui.doi_vu_khi()
	if su_kien.is_action_pressed("khoa_muc_tieu"):
		khoa.bat_tat()

	may.nhap(su_kien)

func _process(delta: float) -> void:
	if _giu_space >= 0.0:
		_giu_space += delta

## Đang giữ Space đủ lâu để tính là chạy chưa.
func dang_giu_chay() -> bool:
	return _giu_space >= NGUONG_GIU_CHAY

func _don_dem(delta: float) -> void:
	for k in _dem.keys():
		_dem[k] = float(_dem[k]) - delta
		if float(_dem[k]) <= 0.0:
			_dem.erase(k)

## Người chơi có vừa bấm phím này không (trong cửa sổ đệm). Lấy ra là XOÁ —
## một lần bấm chỉ được ăn một lần, không thì một cú bấm ra ba nhát chém.
func lay_dem(ten: String) -> bool:
	if _dem.has(ten):
		_dem.erase(ten)
		return true
	return false

func co_dem(ten: String) -> bool:
	return _dem.has(ten)

# --- Di chuyển ------------------------------------------------------

func _doc_huong_nhap() -> void:
	var v := Input.get_vector("di_trai", "di_phai", "di_truoc", "di_sau")
	if v.length_squared() < 0.01:
		huong_nhap = Vector3.ZERO
		return
	# Quy về hệ thế giới theo hướng camera đang nhìn — bấm W luôn là "đi xa
	# khỏi camera", bất kể camera đang xoay đâu.
	var co_so := gia_camera.global_transform.basis
	var truoc := -co_so.z
	var phai := co_so.x
	truoc.y = 0.0
	phai.y = 0.0
	huong_nhap = (truoc * -v.y + phai * v.x).normalized()

## Đặt vận tốc ngang, giữ nguyên vận tốc rơi.
func dat_toc_ngang(huong: Vector3, toc: float) -> void:
	velocity.x = huong.x * toc
	velocity.z = huong.z * toc

func dung_lai(delta: float, ma_sat: float = 14.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ma_sat * delta)
	velocity.z = move_toward(velocity.z, 0.0, ma_sat * delta)

## Xoay người về hướng `huong`. Khoá mục tiêu thì luôn quay mặt về mục tiêu —
## đó là cả điểm của việc khoá.
func xoay_ve(huong: Vector3, delta: float) -> void:
	var h := huong
	if muc_tieu != null:
		h = muc_tieu.global_position - global_position
	h.y = 0.0
	if h.length_squared() < 0.001:
		return
	var goc := atan2(h.x, h.z)
	than.rotation.y = lerp_angle(than.rotation.y, goc, minf(1.0, TOC_XOAY * delta))

## Hướng nhân vật đang quay mặt.
func huong_mat() -> Vector3:
	return than.global_transform.basis.z.normalized()

# --- Thể lực --------------------------------------------------------

func _hoi_the_luc(delta: float) -> void:
	if khung_tl > 0.0:
		khung_tl -= delta
		return
	if dang_do:
		return  # giơ khiên thì không hồi — đó là giá của việc đứng thủ
	if the_luc >= the_luc_max:
		return
	the_luc = minf(the_luc_max, the_luc + SoulsLike.hoi_the_luc * delta)
	doi_the_luc.emit(the_luc, the_luc_max)

## Tiêu thể lực. Cạn sạch thì khựng lâu hơn (mục 5.1).
func ton_the_luc(luong: float) -> void:
	if luong <= 0.0:
		return
	the_luc = maxf(0.0, the_luc - luong)
	khung_tl = SoulsLike.khung_the_luc
	if the_luc <= 0.0:
		khung_tl += SoulsLike.phat_can_the_luc
	doi_the_luc.emit(the_luc, the_luc_max)

func du_the_luc() -> bool:
	return SoulsLike.du_the_luc(the_luc)

# --- Tư thế ---------------------------------------------------------

func _tut_tu_the(delta: float) -> void:
	tu_the = maxf(0.0, tu_the - SoulsLike.TU_THE_TUT_MOI_GIAY * delta)

func them_tu_the(luong: float) -> bool:
	tu_the += luong
	if tu_the < tu_the_max:
		return false
	tu_the = 0.0
	return true

## Thế đứng hiện tại — từ giáp đang mặc. Giáp nặng thì ăn đòn nhỏ không khựng.
func the_dung() -> float:
	return Tui.tong_nang() * 0.9 + float(Tui.cs("韧")) * 0.6

# --- Ăn đòn ---------------------------------------------------------

## Chịu một đòn. Trả về sát thương THỰC đã ăn (0 = né/đỡ trọn).
##
## Thứ tự xét quan trọng và cố ý: bất tử → đỡ phản → đỡ → ăn thật. Đảo thứ tự
## là hỏng cảm giác — lăn qua đòn mà vẫn ăn sát thương vì đang giơ khiên thì
## người chơi sẽ chửi, và họ đúng.
func an_don(sat_thuong: int, pha_the: float, tu_dau: Vector3, hanh: String = "") -> int:
	if bat_tu:
		return 0
	bi_danh.emit(tu_dau)
	if dang_do_phan:
		return -1  # -1 = ĐỠ PHẢN TRÚNG, bên gọi cho quái ngây ra

	var st := sat_thuong
	if hanh != "":
		var hanh_minh := _hanh_giap()
		var hs := NguHanh.he_so(hanh, hanh_minh)
		st = int(round(float(st) * maxf(hs, 0.1)))
		if hs != 1.0:
			bao_ngu_hanh.emit(NguHanh.giai_thich(hanh, hanh_minh))

	if dang_do and _don_tu_phia_truoc(tu_dau):
		var chan := _chi_so_chan()
		var ton := SoulsLike.the_luc_do(st, _chi_so_on_dinh())
		ton_the_luc(ton)
		st = SoulsLike.sat_thuong_sau_do(st, chan)
		if the_luc <= 0.0:
			# Đỡ tới cạn thể lực → VỠ THẾ (mục 5.1)
			may.doi("vo_the")
		mat_mau(st)
		them_tu_the(pha_the * SoulsLike.TU_THE_KHI_DO)
		return st

	mat_mau(st)
	if them_tu_the(pha_the):
		may.doi("vo_the")
	elif SoulsLike.co_khung(the_dung(), pha_the):
		may.doi("trung_don", {"tu_dau": tu_dau})
	return st

func _don_tu_phia_truoc(tu_dau: Vector3) -> bool:
	var v := tu_dau - global_position
	v.y = 0.0
	return v.normalized().dot(huong_mat()) > 0.15

func _hanh_giap() -> String:
	var ds := Tui.hanh_dang_mac()
	return "" if ds.is_empty() else String(ds[0])

func _chi_so_chan() -> int:
	var kh = Tui.tay_trai_dang_cam()
	return 55 if kh == null else clampi(int(kh.sat_thuong() * 1.6), 40, 95)

func _chi_so_on_dinh() -> int:
	var kh = Tui.tay_trai_dang_cam()
	return 30 if kh == null else clampi(int(kh.nang() * 3.0), 20, 90)

func mat_mau(n: int) -> void:
	if n <= 0:
		return
	mau = maxf(0.0, mau - float(n))
	Tui.mau = mau
	doi_mau.emit(mau, mau_toi_da)
	if mau <= 0.0:
		may.doi("chet")
		da_chet.emit()

func hoi_mau(n: float) -> void:
	mau = minf(mau_toi_da, mau + n)
	Tui.mau = mau
	doi_mau.emit(mau, mau_toi_da)

# --- Khoá mục tiêu --------------------------------------------------

func dat_muc_tieu(mt: Node3D) -> void:
	muc_tieu = mt
	doi_muc_tieu.emit(mt)

## Tải trọng hiện tại — dùng cho i-frame và tốc độ lăn.
func ti_le_tai() -> float:
	return Tui.ti_le_tai()
