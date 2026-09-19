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
signal doi_mp(mp: float, toi_da: float)
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
## Bấm Space HAI LẦN trong bấy nhiêu giây thì ra LĂN; một lần thì ra NHẢY.
##
## Cách chia này do chủ dự án chốt. Cái giá nằm đúng ở con số này: **cú NHẢY
## trễ bấy nhiêu giây**, vì phải đợi hết cửa sổ mới biết có lần bấm thứ hai
## không. Không có cách nào tránh — một nút gánh hai việc thì luôn có một việc
## phải chờ.
##
## Đã xếp cho cái RẺ hơn phải chờ: LĂN bắn ra ngay ở lần bấm thứ hai, không đợi
## gì; chỉ NHẢY mới chịu 0.22s. Lăn là nút bấm nhiều nhất trong souls-like nên
## nó phải nhanh; nhảy chủ yếu để né đòn quét ngang của boss, hiếm hơn nhiều.
##
## Muốn cả hai đều tức thì thì phải tách nhảy sang nút riêng.
const NGUONG_BAM_DOI := 0.22
## Giữ chuột trái quá bấy nhiêu giây thì thành đòn NẶNG, nhả sớm hơn là đòn
## NHẸ.
##
## Cùng một nút ra hai đòn nên có một cái giá không tránh được: đòn NHẸ chỉ
## bắn ra lúc NHẢ chuột, chứ không phải lúc bấm — phải đợi mới biết người chơi
## định bấm hay định giữ. Con số này CHÍNH LÀ độ trễ của mọi cú chém thường,
## nên để càng ngắn càng tốt. Dưới ~0.15s thì bấm hơi lâu tay đã lỡ ra đòn
## nặng. Muốn hết trễ hẳn thì phải tách đòn nặng sang nút riêng.
const NGUONG_GIU_NANG := 0.18
## Rút / cất vũ khí (kiểu Elden Ring). Một động tác cho MỌI vũ khí.
##
## Vì sao có cơ chế này chứ không chỉ là hai cái animation: cất kiếm phải ĐƯỢC
## cái gì đó, không thì không ai bấm và nó thành nút trang trí. Cất rồi thì đi
## và chạy nhanh hơn `TOC_DO_KHI_CAT` lần — đủ để đáng bấm khi băng qua một
## vùng, và cái giá là KHÔNG ĐÁNH ĐƯỢC: bấm đánh lúc đang cất thì nhân vật tự
## rút ra trước, mất trọn `T_RUT_VU_KHI` giây. Chạm trán bất ngờ là trả giá.
##
## Muốn bỏ hẳn phần thưởng tốc độ thì để `TOC_DO_KHI_CAT` về 1.0; cơ chế vẫn
## chạy, chỉ là không ai buồn dùng nữa.
## Đo từ clip (`tools/do_nhip_don.tscn`): `rut_vu_khi.fbx` động từ 0.11s tới
## 0.64s, `cat_vu_khi.fbx` từ 0.01s tới 0.34s. Hai đầu clip đứng im nên không
## tính vào — để nguyên thì bấm R xong nhân vật đứng đơ một nhịp trước khi tay
## bắt đầu với ra sau lưng.
const T_RUT_VU_KHI := 0.53
const T_CAT_VU_KHI := 0.33
## Cất kiếm rồi thì đi và chạy nhanh hơn bấy nhiêu lần.
const TOC_DO_KHI_CAT := 1.15
## Và chạy TỐN ÍT thể lực hơn bấy nhiêu lần.
##
## Hai phần thưởng chứ không một, vì một mình tốc độ chưa đủ đổi cách chơi:
## chạy nhanh hơn 30% mà vẫn hết hơi sau đúng ngần ấy giây thì quãng đường đi
## được chỉ nhích lên chút ít. Cộng thêm phần thể lực thì quãng đường một hơi
## chạy dài gần gấp đôi — lúc đó mới đáng bấm R trước khi băng qua một vùng.
##
## Cả hai chỉ ăn khi vũ khí ĐÃ CẤT XONG, không ăn trong lúc đang cất.
const HS_THE_LUC_KHI_CAT := 0.55
## Đang rút/cất thì lết được, chậm — đứng chôn chân giữa lúc quái lao tới là
## cái giá quá đắt cho một thao tác buộc phải làm.
const TOC_DO_KHI_DOI_VU_KHI := 0.55

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
## MP (linh lực). Trần theo chỉ số 心, xem SoulsLike mục "MP".
## CHƯA CÓ PHÉP NÀO tiêu nó — `tieu_mp()` là chỗ phép sẽ cắm vào.
var mp := 60.0
var mp_toi_da := 60.0
## Còn bao lâu nữa thì MP bắt đầu hồi. Đếm lùi vô điều kiện, KHÔNG như thể lực:
## thể lực phải đứng im suốt lúc bận hành động (đó là cả sức ép của nó), còn MP
## thì không dính gì tới việc đang vung kiếm hay đang lăn.
var _tre_hoi_mp := 0.0
## Còn bao lâu nữa mới bắt đầu hồi thể lực (mục 5.1: khựng ~0.8s).
## Còn bao lâu nữa thì thể lực bắt đầu hồi. Đếm lùi khi KHÔNG bận hành động.
var tre_hoi := 0.0
var _phat_can := 0.0    ## phạt thêm vì vừa cạn sạch thể lực
## Đang bất tử (i-frame giữa cú lăn).
var bat_tu := false
## Cú đánh gần nhất tới TỪ ĐÂU, và nó có đủ mạnh để gọi là chí mạng không.
## Dùng để chọn dáng ngã lúc chết. Vector3.INF = không rõ (chết vì rơi, vì độc…).
var _don_cuoi_tu := Vector3.INF
var _don_cuoi_manh := false

## Sát thương bằng bấy nhiêu phần máu tối đa thì tính là ĐÒN MẠNH, và lúc chết
## sẽ dùng dáng ngã dữ dội thay cho dáng đổ thường.
const TI_LE_DON_CHI_MANG := 0.25

## Siêu giáp (hyperarmor) của đòn đang vung. Cộng thẳng vào thế đứng, chỉ sống
## trong mấy khung vung tay — xem danh.gd. Đây là thứ cho phép vung rìu 1.2
## giây giữa bầy quái mà không bị nhát chém vặt nào cắt ngang.
var sieu_giap := 0.0
## Vừa đỡ trúng một đòn thì còn bấy nhiêu giây để bấm đòn nặng ra ĐÒN PHẢN.
var cho_phan_do := 0.0
## Đang trong khung đỡ phản.
var dang_do_phan := false
## Đang trong phần ĐẦU của khung đỡ phản — parry lúc này là HOÀN HẢO.
## Chỉ có nghĩa khi `dang_do_phan` còn bật; do_phan.gd tắt nó trước.
var do_phan_hoan_hao := false
## Đang giơ khiên.
var dang_do := false
## Thanh tư thế của chính mình — đầy thì vỡ, đứng ngây cho ăn đòn to.
var tu_the := 0.0
var tu_the_max := 100.0
## Vũ khí đang RÚT RA hay đã CẤT ĐI. Cất thì đi nhanh hơn nhưng không đánh
## được — xem T_RUT_VU_KHI.
var da_rut := true
## Hồi đòn sau khi lăn, để không spam lăn thành bất tử.
var hoi_lan := 0.0

## Hướng nhập vào từ WASD, đã quy về hệ toạ độ thế giới theo camera.
var huong_nhap := Vector3.ZERO
## Mục tiêu đang khoá (null = không khoá).
var muc_tieu: Node3D = null

## BỘ ĐỆM PHÍM — SỨC CHỨA ĐÚNG MỘT.
##
## Đây là chỗ quyết định phần lớn cảm giác của souls-like, và sức chứa 1 là cả
## cơ chế chứ không phải giới hạn kỹ thuật.
##
## Giữ nhiều lệnh thì spam ba nút trong lúc vung đòn sẽ cho ra ba hành động nối
## nhau sau khi đòn kết thúc — nhân vật tự chơi lấy một chuỗi mà người chơi
## không còn muốn nữa. Giữ đúng MỘT thì cái sống sót là **cú bấm cuối cùng**,
## tức là ý định mới nhất, và người chơi sửa được ý định bằng cách bấm lại.
##
## Đây cũng là lý do người chơi Elden Ring hay chết: bấm né lúc mình còn đang ở
## khung khởi động đòn đánh, lệnh nằm chờ, đánh xong mới cuộn — mà lúc đó đòn
## boss đã hạ xuống rồi. Hành vi đó là ĐÚNG, không phải lỗi cần chữa.
var _dem_ten := ""      ## lệnh đang chờ, "" là trống
var _dem_con := 0.0     ## còn bao nhiêu giây nữa thì hết hạn
## Còn bấy nhiêu giây nữa là hết cửa sổ bấm đôi Space (-1 = không có cửa sổ
## nào đang mở). Hết cửa sổ mà không có lần bấm thứ hai thì ra NHẢY.
var _cho_space := -1.0
var _giu_danh := -1.0   ## giữ chuột trái được bao lâu (-1 = không giữ)
var _da_ra_nang := false ## cú giữ này đã bắn ra đòn nặng rồi thì thôi
## Đã đánh một đòn trên không trong lần rời mặt đất này chưa. Đặt lại khi chạm
## đất. Không có cờ này thì rơi từ vách cao là chém được cả chuỗi đòn nhảy —
## mà đòn nhảy phá thế gấp 4 đòn thường, nên chuỗi đó phá vỡ mọi trận đánh.
var _da_danh_tren_khong := false

func _ready() -> void:
	add_to_group("nguoi_choi")
	mau_toi_da = Tui.mau_toi_da()
	mau = Tui.mau
	the_luc_max = Tui.the_luc_toi_da()
	the_luc = the_luc_max
	mp_toi_da = Tui.mp_toi_da()
	mp = Tui.mp
	tu_the_max = SoulsLike.TU_THE_GOC + float(Tui.cs("韧")) * 1.5
	may.khoi_dong(self)
	Tui.doi_chi_so.connect(_cap_nhat_theo_chi_so)
	Tui.doi_trang_bi.connect(_cap_nhat_theo_chi_so)
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)
	doi_mp.emit(mp, mp_toi_da)

func _cap_nhat_theo_chi_so() -> void:
	var cu := mau_toi_da
	mau_toi_da = Tui.mau_toi_da()
	the_luc_max = Tui.the_luc_toi_da()
	var mp_cu := mp_toi_da
	mp_toi_da = Tui.mp_toi_da()
	# Nâng 心 thì cộng luôn phần chênh vào MP hiện tại, cùng lý do như máu:
	# nâng chỉ số xong lại thấy thanh ngắn đi tương đối là cảm giác bị lừa.
	if mp_toi_da > mp_cu:
		mp += mp_toi_da - mp_cu
	mp = minf(mp, mp_toi_da)
	tu_the_max = SoulsLike.TU_THE_GOC + float(Tui.cs("韧")) * 1.5
	# Nâng 体 thì máu tối đa tăng — cộng luôn phần chênh vào máu hiện tại,
	# nếu không thì nâng chỉ số xong lại thấy thanh máu ngắn đi tương đối.
	if mau_toi_da > cu:
		mau += mau_toi_da - cu
	mau = minf(mau, mau_toi_da)
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)
	doi_mp.emit(mp, mp_toi_da)

# --- Vòng lặp -------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= TRONG_LUC * delta
	else:
		_da_danh_tren_khong = false
	hoi_lan = maxf(0.0, hoi_lan - delta)
	_hoi_the_luc(delta)
	_hoi_mp(delta)
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
	# Hỏi theo HÀM chứ không ép kiểu một lớp cụ thể: thân có hai bản — khối hộp
	# (`than_khoi.gd`) và model thật (`than_mo_hinh.gd`) — và cả hai cài cùng
	# một `dien()`. Ép kiểu thì đổi thân là phải sửa cả file này.
	if than == null or not than.has_method("dien"):
		return
	var td := may.hien_tai.tien_do() if may.hien_tai != null else 0.0
	var kieu := may.hien_tai.ten_dien() if may.hien_tai != null else ""
	var nap := 0.0
	if may.hien_tai != null and may.hien_tai.has_method("muc_nap"):
		nap = may.hien_tai.call("muc_nap")
	# Vũ khí nằm ở TAY hay ở LƯNG — phần nhìn phải biết, và chỉ nó mới biết
	# cách chuyển. Gọi mỗi khung cho rẻ: bên kia tự bỏ qua nếu không đổi.
	if than.has_method("dat_da_rut"):
		than.call("dat_da_rut", da_rut)
	# Mốc thời gian THÔ của state, chưa quy về 0→1. Phần nhìn có animation thật
	# cần đúng con số này để đặt clip vào chỗ máy trạng thái đang đứng — `td`
	# đã bị chuẩn hoá nên không dựng lại được (xem `ThanMoHinh._ghim_clip()`).
	var t_don := may.hien_tai.t if may.hien_tai != null else 0.0
	than.call("dien", may.ten_hien_tai, td, huong_nhap != Vector3.ZERO, delta,
		kieu, nap, t_don)

func _unhandled_input(su_kien: InputEvent) -> void:
	# Ghi đệm phím TRƯỚC khi đưa cho state: state đang bận hồi đòn vẫn phải
	# nhớ được là người chơi đã bấm, nếu không combo cảm giác bị nuốt phím.
	# "nhay" KHÔNG nằm trong danh sách này: nó không còn là một action nữa mà là
	# kết quả của việc Space HẾT cửa sổ bấm đôi, nên nó nạp vào đệm từ _process().
	for ten in ["do_phan", "uong_binh", "cat_rut"]:
		if su_kien.is_action_pressed(ten):
			ghi_dem(ten)

	# Chuột trái: nhả sớm = đòn nhẹ, giữ = đòn nặng. Đòn nặng bắn ra ngay lúc
	# CHẠM ngưỡng (xem _process) chứ không đợi nhả — giữ nút rồi mới thấy đòn
	# vung là cảm giác trễ, và người chơi cần thấy mình đang nạp đòn gì.
	if su_kien.is_action_pressed("don_nhe"):
		_giu_danh = 0.0
		_da_ra_nang = false
	elif su_kien.is_action_released("don_nhe"):
		if _giu_danh >= 0.0 and not _da_ra_nang:
			ghi_dem("don_nhe")
		_giu_danh = -1.0

	# Space: bấm HAI lần = LĂN, một lần = NHẢY.
	#
	# Lần bấm thứ hai bắn LĂN ra ngay lập tức, không đợi gì thêm. Còn lần bấm
	# đơn thì phải đợi hết cửa sổ (xem _process) mới dám gọi là nhảy — trước đó
	# chưa ai biết người chơi có bấm tiếp không.
	#
	# GIỮ Space không còn nghĩa gì nữa, nên cũng không còn cái bẫy "mở hành
	# trang giữa lúc đang giữ nút thì sự kiện nhả không bao giờ tới".
	if su_kien.is_action_pressed("lan_nhay"):
		if _cho_space >= 0.0:
			_cho_space = -1.0
			ghi_dem("lan")
		else:
			_cho_space = NGUONG_BAM_DOI

	if su_kien.is_action_pressed("doi_vu_khi"):
		Tui.doi_vu_khi()
	if su_kien.is_action_pressed("khoa_muc_tieu"):
		khoa.bat_tat()

	may.nhap(su_kien)

func _process(delta: float) -> void:
	if _cho_space >= 0.0:
		_cho_space -= delta
		# Hết cửa sổ mà không có lần bấm thứ hai ⇒ người chơi định NHẢY.
		if _cho_space < 0.0:
			ghi_dem("nhay")
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
				ghi_dem("don_nang")

## Có đang giữ Shift để chạy không.
##
## Chạy là nút GIỮ thuần, không có ngưỡng nào: Shift không phải chia sẻ với
## hành động nào khác nên không có gì để phân biệt, và vì thế chạy là thứ DUY
## NHẤT trong bộ điều khiển này không có độ trễ.
func dang_giu_chay() -> bool:
	return Input.is_action_pressed("chay_nhanh")

## Đang ở trên không — dùng để đổi đòn thường thành ĐÒN NHẢY.
##
## Hỏi is_on_floor() chứ không hỏi "có đang ở state nhay không": rơi khỏi mép
## vách cũng phải đánh được đòn nhảy, mà rơi thì state vẫn là `dung`/`di`.
func tren_khong() -> bool:
	return not is_on_floor()

## Còn được đánh một đòn trên không nữa không (mỗi lần rời đất một đòn).
func con_don_tren_khong() -> bool:
	return not _da_danh_tren_khong

## Ghi nhận đã tiêu đòn trên không của lần rời đất này.
func dung_don_tren_khong() -> void:
	_da_danh_tren_khong = true

## Còn đang giữ chuột trái không. Đòn nặng đọc cái này để nạp tiếp — giữ lâu
## hơn nữa thì ra đòn nạp, xem danh.gd.
func dang_giu_danh() -> bool:
	return _giu_danh >= 0.0

func _don_dem(delta: float) -> void:
	if _dem_ten == "":
		return
	_dem_con -= delta
	if _dem_con <= 0.0:
		_dem_ten = ""

## Người chơi có vừa bấm phím này không (trong cửa sổ đệm). Lấy ra là XOÁ —
## một lần bấm chỉ được ăn một lần, không thì một cú bấm ra ba nhát chém.
## Vứt sạch bộ đệm phím.
##
## Gọi khi người chơi bị CẮT NGANG: trúng đòn, vỡ thế, chết. Không vứt thì mấy
## cú bấm trong lúc đang bị đánh nằm chờ rồi nổ ra ngay khi vừa đứng dậy — nhân
## vật tự lăn một phát hoặc tự vung kiếm vào không khí, và người chơi đọc ra là
## game không nghe lời. Souls-like nào cũng vứt đệm ở đúng ba chỗ này.
func xoa_dem() -> void:
	_bo_lenh_cho()
	# Dọn cả hai bộ đếm GIỮ PHÍM, không chỉ cái đệm.
	#
	# Bị đánh giữa lúc đang giữ chuột trái thì cú giữ đó phải chết theo: không
	# thì đứng dậy xong nhân vật ra ngay một đòn nặng mà người chơi đã bỏ ý
	# định từ lâu. Đây là chỗ KHÁC với `_bo_lenh_cho()` bên dưới — đừng gộp.
	_cho_space = -1.0
	_giu_danh = -1.0

## Chỉ vứt lệnh đang chờ, GIỮ NGUYÊN hai bộ đếm giữ phím.
##
## Tách ra vì `lay_dem()` cũng cần dọn ô đệm, mà nó tuyệt đối không được đụng
## tới `_giu_danh`: lệnh `don_nang` bắn ra lúc CHẠM ngưỡng giữ, trong khi ngón
## tay vẫn còn đang giữ — và `TrangThaiDanh.vao()` hỏi đúng cái đang-giữ đó để
## biết có vào cú NẠP hay không. Gộp hai việc lại là cú nạp chết ngay khi vừa
## bắt đầu, im lặng, và mọi phép thử về dáng nạp đỏ cùng lúc.
func _bo_lenh_cho() -> void:
	_dem_ten = ""
	_dem_con = 0.0

## Ghi một lệnh vào đệm, ĐÈ LÊN lệnh cũ.
##
## Đè chứ không xếp hàng: xem ghi chú ở `_dem_ten`.
func ghi_dem(ten: String) -> void:
	_dem_ten = ten
	_dem_con = DEM_NHAP

func lay_dem(ten: String) -> bool:
	if _dem_ten != ten:
		return false
	_bo_lenh_cho()
	return true

func co_dem(ten: String) -> bool:
	return _dem_ten == ten

## Lệnh đang nằm chờ, "" nếu trống. Cửa cho bộ kiểm tra.
func dem_dang_cho() -> String:
	return _dem_ten

## Những lệnh TỐN THỂ LỰC. Cạn thể lực thì chúng bị vứt khỏi đệm ngay (spec của
## chủ dự án, mục "Clear Buffer"), vì để lại thì chúng nổ ra đúng lúc thanh thể
## lực vừa nhúc nhích lên một chút — người chơi không bấm mà nhân vật vẫn lăn.
const DEM_TON_THE_LUC := ["lan", "don_nhe", "don_nang", "nhay", "do_phan"]

## Vứt lệnh tốn thể lực khỏi đệm nếu đã cạn. Gọi từ `ton_the_luc()`.
func _don_dem_khi_can_the_luc() -> void:
	if the_luc > 0.0:
		return
	if _dem_ten in DEM_TON_THE_LUC:
		_bo_lenh_cho()

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

## Hệ số tốc độ theo việc đã cất vũ khí chưa. Nhân vào MỌI chỗ đặt tốc độ đi
## lại, nên chỉ có một chỗ biết luật này.
func he_so_toc_do() -> float:
	return 1.0 if da_rut else TOC_DO_KHI_CAT

## Hệ số tiêu thể lực khi CHẠY, theo việc đã cất vũ khí chưa. Chỉ chạy mới ăn
## hệ số này — đánh, lăn, đỡ thì vẫn tốn nguyên, vì mấy việc đó đều đòi rút
## kiếm ra trước rồi.
func he_so_ton_the_luc() -> float:
	return 1.0 if da_rut else HS_THE_LUC_KHI_CAT

## Đặt vận tốc ngang, giữ nguyên vận tốc rơi.
func dat_toc_ngang(huong: Vector3, toc: float) -> void:
	var t := toc * he_so_toc_do()
	velocity.x = huong.x * t
	velocity.z = huong.z * t

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
		_don_dem_khi_can_the_luc()
	doi_the_luc.emit(the_luc, the_luc_max)

func du_the_luc() -> bool:
	return SoulsLike.du_the_luc(the_luc)

# --- MP -------------------------------------------------------------

func _hoi_mp(delta: float) -> void:
	if _tre_hoi_mp > 0.0:
		_tre_hoi_mp -= delta
		return
	if mp >= mp_toi_da:
		return
	mp = minf(mp_toi_da, mp + SoulsLike.MP_HOI_MOI_GIAY * delta)
	Tui.mp = mp
	doi_mp.emit(mp, mp_toi_da)

## Tiêu MP. Trả false và KHÔNG tiêu gì nếu không đủ.
##
## Khác `ton_the_luc()` một cách cố ý: thể lực cho phép hành động khi còn > 0 dù
## không đủ trọn giá (cấm hẳn mới là chỗ ức chế), còn MP thì đủ hay không là
## chuyện rạch ròi — nửa câu thần chú không ra nửa quả cầu lửa.
##
## CHƯA CÓ PHÉP NÀO gọi hàm này. Nó là cái móc để đợt sau cắm hệ phép vào.
func tieu_mp(luong: float) -> bool:
	if luong <= 0.0:
		return true
	if mp < luong:
		return false
	mp -= luong
	Tui.mp = mp
	_tre_hoi_mp = SoulsLike.MP_TRE_HOI
	doi_mp.emit(mp, mp_toi_da)
	return true

func hoi_mp(luong: float) -> void:
	mp = minf(mp_toi_da, mp + luong)
	Tui.mp = mp
	doi_mp.emit(mp, mp_toi_da)

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

## Chịu một đòn. Trả về sát thương THỰC đã ăn, với hai giá trị âm làm dấu hiệu:
##
##   ≥ 0   sát thương đã ăn (0 = né trọn giữa i-frame)
##   -1    ĐỠ PHẢN trúng — bên gọi cho quái ngây NGAY_SAU_DO_PHAN giây
##   -2    ĐỠ PHẢN HOÀN HẢO — ngây NGAY_SAU_PERFECT giây, lâu hơn hẳn
##
## Bên gọi chỉ cần biết "âm là parry"; phân biệt -1/-2 chỉ để chọn độ dài ngây,
## nên chỗ nào không quan tâm cứ kiểm tra `< 0` như cũ là vẫn đúng.
##
## Thứ tự xét quan trọng và cố ý: bất tử → đỡ phản → đỡ → ăn thật. Đảo thứ tự
## là hỏng cảm giác — lăn qua đòn mà vẫn ăn sát thương vì đang giơ khiên thì
## người chơi sẽ chửi, và họ đúng.
func an_don(sat_thuong: int, pha_the: float, tu_dau: Vector3, hanh: String = "") -> int:
	if bat_tu:
		return 0
	bi_danh.emit(tu_dau)
	if dang_do_phan:
		if not do_phan_hoan_hao:
			AmThanh.phat("do_phan")
			return -1
		# HOÀN HẢO: hoàn lại thể lực đã tiêu cho cú parry. Không cộng thêm gì
		# ngoài phần đã tiêu — parry không được là nguồn SINH thể lực, nếu không
		# thì đứng parry mãi là chiến thuật tối ưu và thanh thể lực mất nghĩa.
		the_luc = minf(the_luc_max,
			the_luc + SoulsLike.THE_LUC_DO_PHAN * SoulsLike.HOAN_THE_LUC_PERFECT)
		doi_the_luc.emit(the_luc, the_luc_max)
		AmThanh.phat("do_phan", 1.5)   # cao độ cao hơn: nghe là biết mình vừa ăn trọn
		return -2

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

	# Nhớ cú đánh này TRƯỚC khi trừ máu: nếu nó là cú chí mạng thì `mat_mau()`
	# đổi thẳng sang state `chet`, và state đó cần biết đòn tới từ đâu để chọn
	# dáng ngã. Không nhớ ở đây thì lúc cần đã muộn.
	_don_cuoi_tu = tu_dau
	_don_cuoi_manh = float(st) >= mau_toi_da * TI_LE_DON_CHI_MANG
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
	elif SoulsLike.co_khung(the_dung(), pha_the) or _don_dang_de_gay():
		may.xin_doi("trung_don", {"tu_dau": tu_dau})
	return st

## Đòn đang vung có phải loại CHẠM LÀ GÃY không.
##
## Hỏi qua `has_method` chứ không ép kiểu `TrangThaiDanh`: chỉ state đánh mới
## có khái niệm này, và mọi state khác trả lời "không" bằng cách không có hàm.
func _don_dang_de_gay() -> bool:
	var tt = may.hien_tai
	return tt != null and tt.has_method("de_gay") and bool(tt.call("de_gay"))

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

## Tay trái có đang cầm khiên không.
##
## KHÔNG còn gác cửa parry nữa. Elden Ring cấm parry tay không; chủ dự án chốt
## cho parry tay không được, nên hàm này giờ chỉ còn dùng để hỏi han (test, giao
## diện). Khiên vẫn đáng cầm vì hai thứ khác: chặn sát thương (40–95 so với 35
## của tay không) và đòn phản đỡ. Xem mục "Cố ý KHÁC" trong TIEN_DO.md.
func co_khien() -> bool:
	return Tui.tay_trai_dang_cam() != null

func mat_mau(n: int) -> void:
	if n <= 0:
		return
	mau = maxf(0.0, mau - float(n))
	Tui.mau = mau
	doi_mau.emit(mau, mau_toi_da)
	if mau <= 0.0:
		may.doi("chet", {"tu_dau": _don_cuoi_tu, "manh": _don_cuoi_manh})
		AmThanh.phat("chet")
		da_chet.emit()
		# Quên dọn thì cú chết SAU sẽ dùng lại hướng của cú chết TRƯỚC — và nó
		# chỉ sai ở những lần chết vì rơi hay vì độc, tức là hiếm và khó thấy.
		_don_cuoi_tu = Vector3.INF
		_don_cuoi_manh = false

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
	do_phan_hoan_hao = false
	da_rut = true
	_da_danh_tren_khong = false
	mau_toi_da = Tui.mau_toi_da()
	mau = Tui.mau
	the_luc_max = Tui.the_luc_toi_da()
	the_luc = the_luc_max
	mp_toi_da = Tui.mp_toi_da()
	mp = Tui.mp
	_tre_hoi_mp = 0.0
	tre_hoi = 0.0
	_phat_can = 0.0
	hoi_lan = 0.0
	tu_the = 0.0
	dat_muc_tieu(null)
	may.doi("dung")
	doi_mau.emit(mau, mau_toi_da)
	doi_the_luc.emit(the_luc, the_luc_max)
	doi_mp.emit(mp, mp_toi_da)

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
