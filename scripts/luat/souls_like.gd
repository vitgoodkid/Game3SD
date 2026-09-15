extends Node

## Luật souls-like — thể lực, i-frame, thế đứng, tư thế, đỡ phản.
## Autoload: gọi bằng "SoulsLike". Tất cả đo bằng GIÂY, không phải lượt.
##
## Vì sao tách khỏi chien_dau.gd: chien_dau.gd trả lời câu "đòn này mất mấy
## máu" và đúng ở mọi chế độ chơi, kể cả màn hỏi-đáp theo lượt của bản 2D.
## File này trả lời câu "người chơi có kịp né không" — chỉ có nghĩa khi thời
## gian chạy liên tục. Trộn hai thứ vào nhau là chỗ mọi port 2D→3D chết.
##
## MỌI CON SỐ CẢM GIÁC NẰM Ở ĐÂY. Mục 5.2 của bản yêu cầu nói rõ ba con số
## quyết định trận đánh đã ra chất souls chưa. Đặt chung một chỗ để tune được
## mà không phải lục sáu file.

# --- Ba con số của mục 5.2 ------------------------------------------

## Bao nhiêu giây bất tử giữa cú lăn. Dưới 0.28 là ức chế, trên 0.45 là quá dễ.
## Đây là con số quan trọng nhất của cả game.
@export var iframe_lan := 0.35
## Lăn xong bao lâu mới lăn tiếp được — không có cái này thì spam lăn là bất tử.
## ER: 8 khung hồi ở tải nhẹ/vừa, 16 khung ở tải nặng — nhân theo HOI_LAN_TAI.
@export var hoi_lan := 0.45
## Hệ số hồi lăn theo mức tải. Đây mới là chỗ ER phạt giáp nặng, không phải
## i-frame: lăn xong đứng ì gấp đôi thì vẫn ăn đòn thứ hai của chuỗi.
const HOI_LAN_TAI := {"nhe": 1.0, "vua": 1.0, "nang": 2.0, "qua_tai": 3.0}
## Tổng thời gian một cú lăn (gồm cả phần đã hết bất tử nhưng chưa đứng dậy).
@export var thoi_gian_lan := 0.62

## Hành động xong bao lâu thì thể lực bắt đầu hồi lại.
##
## ĐỌC KỸ CHỖ NÀY TRƯỚC KHI SỬA. Đây từng là chỗ hỏng nặng nhất của combat:
## con số này trước kia bị đặt lại MỖI LẦN tiêu thể lực, mà một đòn đánh tiêu
## ngay lúc bắt đầu vung — nên đánh liên tiếp ba nhát là ba lần đặt lại, thanh
## thể lực gần như không bao giờ được hồi, và trận đánh khựng cứng.
##
## Elden Ring không làm vậy. Nó không hồi thể lực TRONG LÚC hành động (đánh,
## lăn, chạy, giơ khiên), rồi chờ một khoảng NGẮN sau khi hành động KẾT THÚC
## và hồi rất nhanh. Cài ở `TrangThaiMay.cho_hoi_the_luc()` + `tre_hoi`.
@export var tre_hoi_the_luc := 0.40
## Thể lực hồi mỗi giây, khi đã qua trễ và không đang bận hành động nào.
@export var hoi_the_luc := 45.0
## Cạn sạch thể lực thì phạt thêm bấy nhiêu giây nữa mới hồi — cạn kiệt phải
## đau hơn là tiêu vừa đủ, nếu không thì không ai buồn quản lý thể lực.
@export var phat_can_the_luc := 0.55

## Khung hồi của đòn nặng nằm trong data/moveset.csv (cột t_hoi), không ở đây —
## mỗi vũ khí một khác. Ở đây chỉ giữ hệ số chung nhân lên khi đang mệt.

# --- Thể lực --------------------------------------------------------

# --- Quy thang sát thương 2D sang 3D --------------------------------

## Nhân sát thương của NGƯỜI CHƠI lên bấy nhiêu lần.
##
## Vì sao cần: điểm `cong` trong nguyen_lieu.csv là thang của bản 2D, nơi trận
## đánh theo lượt và trả lời đúng một câu là quái mất MỘT máu. Máu quái trong
## quai.csv (120–300) và máu người chơi (390) lại là thang hành động thời gian
## thực. Hai thang đó chưa bao giờ được quy về nhau, nên một nhát kiếm 10 điểm
## đập vào con quái 300 máu — đo thật: 48–50 nhát mới hạ nổi một con thường,
## trong khi nó giết mình trong 13 nhát. Combat thành cào cấu.
##
## Sửa bằng MỘT hằng số ở đây chứ không sửa 38 nguyên liệu: giá trị của bản 2D
## đã cân với nhau rồi, chỉ sai thang. Đổi số này là đổi nhịp cả game —
## quái thường nên chết trong 4–8 nhát đòn nhẹ như Elden Ring.
const HS_SAT_THUONG_NGUOI_CHOI := 3.5

## Thể lực gốc khi 韧 (Nhận) = 0. Mỗi điểm 韧 cộng thêm THE_LUC_MOI_NHAN.
const THE_LUC_GOC := 90.0
const THE_LUC_MOI_NHAN := 2.4

## CÁI GÌ TỐN THỂ LỰC — theo đúng Elden Ring: đánh, lăn, nhảy, chạy, và đỡ
## một đòn. Tất cả đều tiêu.
##
##   đánh       cột `the_luc` của moveset.csv, theo mốc, lúc bắt đầu vung
##   lăn        THE_LUC_LAN
##   nhảy       THE_LUC_NHAY
##   đỡ phản    THE_LUC_DO_PHAN
##   đỡ một đòn = sát thương gốc × THE_LUC_DO_MOI_SAT_THUONG, giảm theo
##              chỉ số CHẶN ĐỠ của khiên (guard boost của ER)
##   chạy       THE_LUC_CHAY_MOI_GIAY, liên tục theo giây
##
## Cái KHÔNG tốn: đứng giơ khiên mà không ăn đòn nào. Nhưng giơ khiên thì
## không hồi — xem cho_hoi_the_luc().
const THE_LUC_CHAY_MOI_GIAY := 14.0
const THE_LUC_LAN := 22.0
const THE_LUC_NHAY := 12.0
const THE_LUC_DO_PHAN := 10.0
## Đỡ một đòn tốn = sát thương gốc × hệ số này, rồi giảm theo chặn đỡ.
const THE_LUC_DO_MOI_SAT_THUONG := 0.55

func the_luc_toi_da(nhan: int) -> float:
	return THE_LUC_GOC + THE_LUC_MOI_NHAN * float(maxi(nhan, 0))

## Còn đủ thể lực để làm việc này không. Chú ý: souls-like cho phép hành động
## khi thể lực CÒN > 0 dù không đủ trọn giá — cấm hẳn mới là chỗ ức chế.
func du_the_luc(hien_tai: float) -> bool:
	return hien_tai > 0.0

# --- i-frame và tải trọng -------------------------------------------

## Mức tải: nhẹ / vừa / nặng / quá tải (mục 6.1). Ngưỡng tính theo % sức chứa
## — ba con số 30% / 70% / 100% lấy đúng của Elden Ring.
##
## Cột `iframe` bám theo ER và vì thế gần như PHẲNG: ER cho 13 khung bất tử ở
## tải nhẹ, 13 ở tải vừa, 12 ở tải nặng — chênh nhau đúng một khung hình. Mặc
## nặng ở ER KHÔNG làm cửa sổ né hẹp đi đáng kể; thứ tụt hẳn là QUÃNG ĐƯỜNG
## lăn (4.09m / 3.21m / 2.66m / 0.51m — đó là cột `xa`) và độ ì khi hồi.
##
## Bản trước của file này cho tải nặng 0.85 và quá tải 0.60 — mặc giáp nặng là
## mất gần nửa cửa sổ né. Đó là luật của Dark Souls 1, không phải của ER, và nó
## làm mọi build giáp nặng thành không chơi được.
const NGUONG_TAI := [
	{"tu": 1.00, "muc": "qua_tai", "ten": "Quá tải", "iframe": 0.00, "xa": 0.12, "toc_do": 0.45},
	{"tu": 0.70, "muc": "nang",    "ten": "Nặng",    "iframe": 0.92, "xa": 0.65, "toc_do": 0.88},
	{"tu": 0.30, "muc": "vua",     "ten": "Vừa",     "iframe": 1.00, "xa": 0.78, "toc_do": 1.00},
	{"tu": 0.00, "muc": "nhe",     "ten": "Nhẹ",     "iframe": 1.00, "xa": 1.00, "toc_do": 1.06},
]
## Quá tải thì ER KHÔNG cho lăn, chỉ lết. iframe 0.00 ở trên là chỗ thi hành.

## Sức chứa = gốc + theo 韧. Mặc quá ngưỡng này là lết.
const SUC_CHUA_GOC := 40.0
const SUC_CHUA_MOI_NHAN := 1.8

func suc_chua(nhan: int) -> float:
	return SUC_CHUA_GOC + SUC_CHUA_MOI_NHAN * float(maxi(nhan, 0))

## Tra mức tải từ tỉ lệ (tong_nang / suc_chua).
func muc_tai(ti_le: float) -> Dictionary:
	for m in NGUONG_TAI:
		if ti_le >= m["tu"]:
			return m
	return NGUONG_TAI[-1]

## Số giây bất tử thật của cú lăn: hệ số theo tải trọng, cộng thêm theo 韧.
## Mục 5.1 nói rõ: tăng theo 韧, giảm theo tải trọng. Cả hai nằm trong một hàm
## để không bao giờ lệch nhau.
func iframe_thuc(ti_le_tai: float, nhan: int) -> float:
	var m := muc_tai(ti_le_tai)
	var hs := float(m["iframe"])
	if hs <= 0.0:
		return 0.0   # quá tải: lết, không có cửa sổ bất tử nào
	var them := 0.0012 * float(maxi(nhan, 0))  # 韧 40 ⇒ +0.048s, đáng kể mà không vỡ
	return iframe_lan * hs + them

## Lăn xong bao lâu mới lăn tiếp được, theo mức tải.
func hoi_lan_thuc(ti_le_tai: float) -> float:
	var m := muc_tai(ti_le_tai)
	return hoi_lan * float(HOI_LAN_TAI.get(String(m["muc"]), 1.0))

# --- Thế đứng (poise) và SIÊU GIÁP (hyperarmor) ---------------------
#
# Elden Ring tách hai thứ mà nhìn ngoài dễ tưởng là một:
#
#   THẾ ĐỨNG (poise)   chỉ số bị động từ giáp đang mặc. Cao thì ăn đòn nhỏ
#                      không khựng. ER có ba mốc nổi tiếng: 51 chịu được phần
#                      lớn đòn thường, 61, và 101.
#   SIÊU GIÁP          thế đứng TẠM THỜI, chỉ bật trong mấy khung của một đòn
#   (hyperarmor)       đang vung. ER cho đòn nặng và vũ khí to có siêu giáp,
#                      đòn nhẹ thì hầu như không. Đây là lý do người chơi dám
#                      đổi đòn tay đôi với boss bằng búa tạ mà không bị cắt.
#
# Thiếu siêu giáp thì vũ khí nặng ở game này vô dụng: vung 1.2 giây mà con quái
# nào chạm vào cũng cắt được thì không ai cầm rìu.

## Trúng đòn có khựng không: đòn phá thế mạnh hơn thế đứng thì khựng.
## `the_dung` đã gồm cả siêu giáp của đòn đang vung, nếu đang vung đòn nào.
func co_khung(the_dung: float, pha_the: float) -> bool:
	return pha_the >= the_dung

## Thế đứng vỡ rồi thì hồi lại sau bấy nhiêu giây không trúng đòn.
const HOI_THE_DUNG := 3.0

# --- Tư thế (posture) — vỡ thì ăn đòn kết liễu ----------------------
#
# Khác thế đứng: thế đứng là "có khựng không" tính theo TỪNG đòn, tư thế là
# thanh tích luỹ, đầy thì đứng chết trân cho ăn một đòn to (kiểu Sekiro).

const TU_THE_GOC := 100.0
## Đỡ được một đòn cũng tích tư thế cho chính mình, ít hơn là ăn thẳng.
const TU_THE_KHI_DO := 0.35
## Tư thế tự tụt mỗi giây khi không bị đánh — thanh này phải tụt nhanh, nếu
## không thì mọi trận dài đều kết thúc bằng vỡ tư thế, mất hết ý nghĩa.
const TU_THE_TUT_MOI_GIAY := 12.0
## Vỡ tư thế rồi đứng ngây bấy nhiêu giây cho người chơi kịp chạy tới kết liễu.
const NGAY_SAU_VO := 2.6
## Đòn kết liễu nhân bấy nhiêu lần sát thương.
const HS_KET_LIEU := 4.0
## Đòn sau lưng (mục 5.1).
const HS_SAU_LUNG := 2.6

# --- Đỡ và đỡ phản --------------------------------------------------

## Cửa sổ đỡ phản — hẹp là cố ý. Đây là kỹ năng cao nhất của người chơi.
@export var cua_so_do_phan := 0.15
## Bấm đỡ phản hụt thì đứng ngây bấy nhiêu giây, không đỡ được gì.
@export var hoi_do_phan := 0.45
## Đỡ phản trúng thì đối phương ngây bấy nhiêu giây.
const NGAY_SAU_DO_PHAN := 2.2

## Đỡ được bao nhiêu phần sát thương. `chan` là chỉ số chặn của khiên (0-100).
## Không bao giờ chặn trọn 100% — giơ khiên đứng im phải có giá, nếu không
## thì người chơi không bao giờ cần học lăn.
const CHAN_TOI_DA := 0.90

func sat_thuong_sau_do(sat_thuong: int, chan: int) -> int:
	var ti_le: float = minf(float(chan) / 100.0, CHAN_TOI_DA)
	return maxi(1, int(round(float(sat_thuong) * (1.0 - ti_le))))

## Đỡ một đòn tốn bao nhiêu thể lực. `on_dinh` là CHẶN ĐỠ của khiên (guard
## boost của ER, 0-100): càng cao thì đỡ càng đỡ tốn. Cạn thể lực giữa lúc đỡ
## là VỠ ĐỠ — xem NguoiChoi.an_don().
func the_luc_do(sat_thuong: int, on_dinh: int) -> float:
	var giam: float = 1.0 - minf(float(on_dinh) / 100.0, 0.75)
	return float(sat_thuong) * THE_LUC_DO_MOI_SAT_THUONG * giam

# --- Đòn phản sau khi đỡ (guard counter) ----------------------------
#
# Cơ chế riêng của Elden Ring, không có trong Dark Souls: vừa đỡ trúng một đòn
# thì bấm đòn NẶNG ra một đòn phản riêng, phá thế rất mạnh (30 stance — ngang
# đòn nặng nạp, gấp 6 lần đòn nhẹ).
#
# Vì sao nó quan trọng: không có nó thì giơ khiên là hành động THUẦN phòng thủ,
# và người chơi cầm khiên không bao giờ thắng được cuộc đua sát thương. Có nó
# thì đỡ trở thành một nước đi tấn công, và đó là cách ER làm cho build khiên
# chơi được.

## Đỡ trúng xong còn bấy nhiêu giây để bấm đòn nặng ra đòn phản.
@export var cua_so_phan_do := 0.60
## Đòn phản nhân sát thương bấy nhiêu lần.
const HS_PHAN_DO := 1.35

# --- Trạng thái tích dần (mục 5.3) ----------------------------------
#
# Bản 2D cho độc/băng ăn NGAY khi trúng. Bản 3D đổi sang tích thành thanh,
# đầy mới bùng — đúng chuẩn souls, và quan trọng hơn: nó cho người chơi thời
# gian PHẢN ỨNG (lùi ra, uống thuốc giải) thay vì chỉ biết chịu.

const TRANG_THAI_NGUONG := 100.0
## Không bị dính thêm thì thanh tích tụt bấy nhiêu mỗi giây.
const TRANG_THAI_TUT_MOI_GIAY := 6.0
## Bùng xong thì thanh về 0 và ngưỡng lần sau cao hơn — không cho khoá cứng.
const TRANG_THAI_TANG_NGUONG := 1.35

## Thanh tích của một trạng thái. Dùng: var t := SoulsLike.Thanh.new()
class Thanh:
	var gia_tri := 0.0
	var nguong := 0.0
	var dang_bung := false

	func _init(nguong_dau: float = 100.0) -> void:
		nguong = nguong_dau

	## Cộng tích. Trả true đúng MỘT lần, ngay khoảnh khắc thanh đầy.
	func them(luong: float) -> bool:
		if luong <= 0.0:
			return false
		gia_tri += luong
		if gia_tri < nguong:
			return false
		gia_tri = 0.0
		nguong *= 1.35
		dang_bung = true
		return true

	func tut(delta: float, moi_giay: float) -> void:
		gia_tri = maxf(0.0, gia_tri - moi_giay * delta)

	func ti_le() -> float:
		return clampf(gia_tri / maxf(nguong, 1.0), 0.0, 1.0)

# --- Thiên can — hệ số nhân theo chỉ số (mục 4.5) -------------------
#
# 甲 > 乙 > 丙 > 丁 > 戊 thay cho S/A/B/C/D. Nhìn bảng chỉ số là học luôn năm
# chữ thiên can, không cần bài giảng nào.

const THIEN_CAN := {
	"甲": {"ten": "Giáp", "hs": 1.00},
	"乙": {"ten": "Ất",   "hs": 0.72},
	"丙": {"ten": "Bính", "hs": 0.50},
	"丁": {"ten": "Đinh", "hs": 0.32},
	"戊": {"ten": "Mậu",  "hs": 0.18},
}
const THU_TU_CAN := ["甲", "乙", "丙", "丁", "戊"]

func he_so_can(can: String) -> float:
	return float(THIEN_CAN.get(can, {}).get("hs", 0.0))

func ten_can(can: String) -> String:
	return String(THIEN_CAN.get(can, {}).get("ten", "—"))

## Sát thương cộng thêm từ chỉ số. Dùng đường cong bậc hai nhẹ (căn bậc hai)
## thay vì tuyến tính: dồn hết điểm vào một chỉ số vẫn hơn, nhưng không hơn
## tới mức mọi build khác thành vô nghĩa.
func cong_tu_chi_so(chi_so: int, can: String, st_goc: float) -> float:
	var hs := he_so_can(can)
	if hs <= 0.0:
		return 0.0
	return st_goc * hs * sqrt(float(maxi(chi_so, 0))) * 0.11
