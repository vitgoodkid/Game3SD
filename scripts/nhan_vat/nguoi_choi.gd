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
## Giữ chuột trái quá bấy nhiêu giây thì thành đòn NẶNG, nhả sớm hơn là đòn
## NHẸ.
##
## Cùng một nút ra hai đòn nên có một cái giá không tránh được: đòn NHẸ chỉ
## bắn ra lúc NHẢ chuột, chứ không phải lúc bấm — phải đợi mới biết người chơi
## định bấm hay định giữ. Con số này CHÍNH LÀ độ trễ của mọi cú chém thường,
## nên để càng ngắn càng tốt. Dưới ~0.15s thì bấm hơi lâu tay đã lỡ ra đòn
## nặng. Muốn hết trễ hẳn thì phải tách đòn nặng sang nút riêng.
const NGUONG_GIU_NANG := 0.18
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
## Còn bao lâu nữa thì thể lực bắt đầu hồi. Đếm lùi khi KHÔNG bận hành động.
var tre_hoi := 0.0
var _phat_can := 0.0    ## phạt thêm vì vừa cạn sạch thể lực
## Đang bất tử (i-frame giữa cú lăn).
var bat_tu := false
## Siêu giáp (hyperarmor) của đòn đang vung. Cộng thẳng vào thế đứng, chỉ sống
## trong mấy khung vung tay — xem danh.gd. Đây là thứ cho phép vung rìu 1.2
## giây giữa bầy quái mà không bị nhát chém vặt nào cắt ngang.
var sieu_giap := 0.0
## Vừa đỡ trúng một đòn thì còn bấy nhiêu giây để bấm đòn nặng ra ĐÒN PHẢN.
var cho_phan_do := 0.0
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
var _giu_danh := -1.0   ## giữ chuột trái được bao lâu (-1 = không giữ)
var _da_ra_nang := false ## cú giữ này đã bắn ra đòn nặng rồi thì thôi

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
	cho_phan_do = maxf(0.0, cho_phan_do - delta)
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
	var kieu := may.hien_tai.ten_dien() if may.hien_tai != null else ""
	tk.dien(may.ten_hien_tai, td, huong_nhap != Vector3.ZERO, delta, kieu)

func _unhandled_input(su_kien: InputEvent) -> void:
	# Ghi đệm phím TRƯỚC khi đưa cho state: state đang bận hồi đòn vẫn phải
	# nhớ được là người chơi đã bấm, nếu không combo cảm giác bị nuốt phím.
	for ten in ["do_phan", "nhay", "uong_binh"]:
		if su_kien.is_action_pressed(ten):
			_dem[ten] = DEM_NHAP

	# Chuột trái: nhả sớm = đòn nhẹ, giữ = đòn nặng. Đòn nặng bắn ra ngay lúc
	# CHẠM ngưỡng (xem _process) chứ không đợi nhả — giữ nút rồi mới thấy đòn
	# vung là cảm giác trễ, và người chơi cần thấy mình đang nạp đòn gì.
	if su_kien.is_action_pressed("don_nhe"):
		_giu_danh = 0.0
		_da_ra_nang = false
	elif su_kien.is_action_released("don_nhe"):
		if _giu_danh >= 0.0 and not _da_ra_nang:
			_dem["don_nhe"] = DEM_NHAP
		_giu_danh = -1.0

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
	if _giu_danh >= 0.0:
		# Tự gỡ kẹt: mở hành trang giữa lúc đang giữ chuột thì game dừng, và
		# sự kiện NHẢ không bao giờ tới _unhandled_input. Không có dòng này
		# thì nhân vật tưởng người chơi còn đang giữ chuột mãi mãi.
		if not Input.is_action_pressed("don_nhe"):
			_giu_danh = -1.0
		else:
			_giu_danh += delta
			if not _da_ra_nang and _giu_danh >= NGUONG_GIU_NANG:
				_da_ra_nang = true
				_dem["don_nang"] = DEM_NHAP

## Đang giữ Space đủ lâu để tính là chạy chưa.
func dang_giu_chay() -> bool:
	return _giu_space >= NGUONG_GIU_CHAY

## Còn đang giữ chuột trái không. Đòn nặng đọc cái này để nạp tiếp — giữ lâu
## hơn nữa thì ra đòn nạp, xem danh.gd.
func dang_giu_danh() -> bool:
	return _giu_danh >= 0.0

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

## Những trạng thái mà bấm E được. DANH SÁCH CHO PHÉP, không phải danh sách
## cấm — thêm trạng thái mới thì mặc định là KHÔNG tương tác được, và đó là
## chiều an toàn.
##
## Vì sao cần: cái xác nằm đúng trong tầm với của vũng hồn vừa rơi ra, suốt
## 2.8 giây trước khi đứng dậy ở bia. Không có luật này thì chết xong bấm E là
## nhặt lại sạch hồn của chính mình — mất trắng thành ra không mất gì, và cả
## mục 4.5 sụp theo.
const TRANG_THAI_TUONG_TAC := ["dung", "di", "chay_nhanh", "do_don"]

## Có đang ở tư thế bấm E được không.
func tuong_tac_duoc() -> bool:
	return may.ten_hien_tai in TRANG_THAI_TUONG_TAC

## Hướng nhân vật đang quay mặt.
func huong_mat() -> Vector3:
	return than.global_transform.basis.z.normalized()

# --- Thể lực --------------------------------------------------------

## Hồi thể lực theo mô hình Elden Ring, không phải mô hình cũ.
##
## Cũ: mỗi lần TIÊU là đặt lại trọn 0.8s cấm hồi ⇒ đánh ba nhát liên tiếp là
##     ba lần đặt lại, thanh thể lực đứng hình, trận đánh khựng cứng.
## Nay: đang BẬN (đánh/lăn/chạy/giơ khiên) thì không hồi; hết bận rồi chờ
##     `tre_hoi_the_luc` giây là hồi, và hồi nhanh.
##
## Khác biệt nằm ở chỗ mốc trễ tính từ lúc hành động KẾT THÚC, nên nó không
## cộng dồn theo số nhát chém.
func _hoi_the_luc(delta: float) -> void:
	var ban := may.hien_tai != null and not may.hien_tai.cho_hoi_the_luc()
	if ban:
		# Còn đang bận thì mốc trễ nằm im, chờ sẵn cho lúc xong việc.
		tre_hoi = SoulsLike.tre_hoi_the_luc + _phat_can
		return
	if tre_hoi > 0.0:
		tre_hoi -= delta
		return
	_phat_can = 0.0
	if the_luc >= the_luc_max:
		return
	the_luc = minf(the_luc_max, the_luc + SoulsLike.hoi_the_luc * delta)
	doi_the_luc.emit(the_luc, the_luc_max)

## Tiêu thể lực. Cạn SẠCH thì bị phạt thêm một khoảng trễ nữa — cạn kiệt phải
## đau hơn tiêu vừa đủ, nếu không thì không ai buồn quản lý thể lực (mục 5.1).
func ton_the_luc(luong: float) -> void:
	if luong <= 0.0:
		return
	the_luc = maxf(0.0, the_luc - luong)
	tre_hoi = maxf(tre_hoi, SoulsLike.tre_hoi_the_luc)
	if the_luc <= 0.0:
		_phat_can = SoulsLike.phat_can_the_luc
		tre_hoi += _phat_can
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

## Thế đứng hiện tại = phần BỊ ĐỘNG từ giáp đang mặc, cộng SIÊU GIÁP tạm thời
## của đòn đang vung (nếu đang vung). Elden Ring tách đôi đúng như vậy: mặc
## giáp cho thế đứng thường trực, còn siêu giáp chỉ bật trong khung của một số
## đòn — và chính siêu giáp mới là thứ quyết định vũ khí nặng có chơi được không.
func the_dung() -> float:
	return Tui.tong_nang() * 0.9 + float(Tui.cs("韧")) * 0.6 + sieu_giap

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
		AmThanh.phat("do_phan")
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
		ton_the_luc(SoulsLike.the_luc_do(st, _chi_so_chan_do()))
		st = SoulsLike.sat_thuong_sau_do(st, chan)
		mat_mau(st)
		if the_luc <= 0.0:
			# VỠ ĐỠ (guard break của ER): đỡ một đòn nặng hơn số thể lực còn
			# lại thì đòn đó vẫn chặn được, nhưng người chơi choáng ra và ăn
			# trọn một đòn kết liễu. Đây là giá của việc đứng thủ lì.
			may.xin_doi("vo_the")
			return st
		# Đỡ TRÚNG thì mở cửa sổ đòn phản — bấm đòn nặng ngay là ra đòn riêng,
		# phá thế ngang đòn nặng nạp. Không có cái này thì giơ khiên là hành
		# động thuần phòng thủ và build khiên không bao giờ thắng nổi cuộc đua
		# sát thương; ER thêm đúng cơ chế này để chữa.
		cho_phan_do = SoulsLike.cua_so_phan_do
		AmThanh.phat("do")
		if them_tu_the(pha_the * SoulsLike.TU_THE_KHI_DO):
			AmThanh.phat("vo_the")
			may.xin_doi("vo_the")
		return st

	mat_mau(st)
	# xin_doi() chứ không doi(): trạng thái hiện tại được quyền từ chối. Đang
	# VỠ THẾ mà một đòn vặt đẩy sang trung_don là biến hình phạt nặng nhất của
	# game thành nhẹ hơn cả trúng đòn thường — vo_the.cho_doi() chặn đúng chỗ
	# đó. Riêng đường CHẾT trong mat_mau() vẫn đổi thẳng: chết thì không trạng
	# thái nào được phép từ chối.
	AmThanh.phat("trung_to" if st >= 40 else "trung", 1.15)
	if them_tu_the(pha_the):
		AmThanh.phat("vo_the")
		may.xin_doi("vo_the")
	elif SoulsLike.co_khung(the_dung(), pha_the):
		may.xin_doi("trung_don", {"tu_dau": tu_dau})
	return st

func _don_tu_phia_truoc(tu_dau: Vector3) -> bool:
	var v := tu_dau - global_position
	v.y = 0.0
	return v.normalized().dot(huong_mat()) > 0.15

func _hanh_giap() -> String:
	var ds := Tui.hanh_dang_mac()
	return "" if ds.is_empty() else String(ds[0])

## Chặn được bao nhiêu phần sát thương (0-100).
##
## Không cầm khiên thì vẫn đỡ được, nhưng kém hẳn — đó là đỡ bằng chính cây vũ
## khí, thứ Elden Ring cho phép khi cầm hai tay và cố tình để rất tệ. Con số
## này trước đây là 55 cho tay không, cao hơn cả khiên tệ nhất (40), khiến khe
## tay trái gần như vô nghĩa.
func _chi_so_chan() -> int:
	var kh = Tui.tay_trai_dang_cam()
	return 35 if kh == null else clampi(int(kh.sat_thuong() * 1.6), 40, 95)

## Chặn đỡ (guard boost của ER, 0-100): càng cao thì đỡ một đòn càng đỡ tốn
## thể lực. Khiên to chặn đỡ cao, tay không thì gần như không có.
func _chi_so_chan_do() -> int:
	var kh = Tui.tay_trai_dang_cam()
	return 10 if kh == null else clampi(int(kh.nang() * 3.0), 20, 90)

## Tay trái có đang cầm khiên không. Elden Ring KHÔNG cho parry tay không —
## phải có khiên nhỏ/vừa, hoặc vũ khí được gắn Ash of War "Parry".
func co_khien() -> bool:
	return Tui.tay_trai_dang_cam() != null

func mat_mau(n: int) -> void:
	if n <= 0:
		return
	mau = maxf(0.0, mau - float(n))
	Tui.mau = mau
	doi_mau.emit(mau, mau_toi_da)
	if mau <= 0.0:
		may.doi("chet")
		AmThanh.phat("chet")
		da_chet.emit()

## Đứng dậy ở bia đá sau khi chết. Gọi bởi VongHoiSinh, không gọi từ state —
## state `chet` chỉ biết mình chết, không biết bia đá nằm đâu.
##
## Lưu ý thứ tự: `TheGioi.hoi_sinh_o_bia()` đã đổ đầy máu vào Tui trước khi tín
## hiệu tới đây, nên chỗ này CHÉP từ Tui ra chứ không tự tính lại — tính lại là
## chỗ hai con số máu bắt đầu trôi khỏi nhau.
func song_lai(tai: Vector3) -> void:
	global_position = tai
	velocity = Vector3.ZERO
	bat_tu = false
	dang_do = false
	dang_do_phan = false
	mau_toi_da = Tui.mau_toi_da()
	mau = Tui.mau
	the_luc_max = Tui.the_luc_toi_da()
	the_luc = the_luc_max
	tre_hoi = 0.0
	_phat_can = 0.0
	hoi_lan = 0.0
	tu_the = 0.0
	dat_muc_tieu(null)
	may.doi("dung")
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)

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
