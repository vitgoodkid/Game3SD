extends Node

## Âm thanh (mốc 7). Autoload: gọi bằng "AmThanh".
##
## HIỆN GIỜ KHÔNG PHÁT GÌ CẢ, và đó là chủ ý.
##
## Bản trước TỔNG HỢP mọi tiếng bằng code lúc khởi động — nhiễu lọc, sin tụt
## cao độ, bao biên độ mũ. Lý do lúc đó: mục 14.6 nói game thiếu HẲN chiều
## nghe, mà thiếu hẳn thì tệ hơn là có mà chưa hay. Chủ dự án chơi thử và bác
## bỏ đúng cái tiền đề đó: tiếng tổng hợp chói và ồn tới mức nghe nhức đầu, nên
## **im lặng tốt hơn**. Đã xoá sạch phần tổng hợp; đừng chép lại.
##
## CÁI CÒN GIỮ LẠI, và vì sao:
##
##   `TIENG`      bản kê tên tiếng — chính là danh sách việc cho người làm âm
##                thanh. Xoá nó đi là mất luôn thông tin "game này cần những
##                tiếng nào", thứ chỉ moi lại được bằng cách đọc 18 chỗ gọi.
##   `phat()`     18 chỗ trong code gọi hàm này. Chúng đánh dấu ĐÚNG khoảnh
##                khắc mỗi tiếng phải vang lên — thông tin đắt hơn code phát
##                tiếng nhiều. Bỏ chúng đi thì thêm âm thanh sau là phải đi dò
##                lại cả repo.
##
## THÊM TIẾNG THẬT SAU: thả file vào `assets/tieng/<tên>.wav` (hoặc .ogg/.mp3),
## tên đúng như khoá trong `TIENG`. Khởi động là nó tự nạp và tự phát, không
## phải sửa một dòng code nào. Thiếu file thì im — không nổ, không cảnh báo ồn.

## Bao nhiêu kênh phát cùng lúc. Đánh nhau với bốn con quái thì tiếng chồng
## nhau liên tục; ít kênh quá là nuốt tiếng, nhiều quá là ồn.
const SO_KENH := 12

## Thư mục tiếng thật. Chưa tồn tại — tạo lúc có file đầu tiên.
const THU_MUC := "res://assets/tieng/"
const DUOI := [".wav", ".ogg", ".mp3"]

## Bản kê tiếng: tên → mô tả việc nó phải làm. Ba thứ một tiếng động trong
## souls-like phải làm được, và đây là chỗ ghi lại thứ nào lo việc nào:
##
##   BÁO TRƯỚC   tiếng vung tay lên báo đòn sắp tới — người chơi né bằng tai
##               khi mắt đang nhìn chỗ khác
##   XÁC NHẬN    trúng đòn khác hẳn trượt đòn, đỡ khác hẳn đỡ phản
##   PHÂN BIỆT   nhẹ khác nặng, của mình khác của quái
const TIENG := {
	"vung_nhe":  "vung tay đòn nhẹ — BÁO TRƯỚC, phải nghe ra là nhẹ và nhanh",
	"vung_nang": "vung tay đòn nặng — BÁO TRƯỚC, dài hơn hẳn đòn nhẹ",
	"trung":     "trúng đòn thường",
	"trung_to":  "trúng đòn nặng (từ 40 sát thương) — phải khác hẳn 'trung'",
	"do":        "đỡ trúng bằng khiên",
	"do_phan":   "ĐỠ PHẢN trúng — phần thưởng của kỹ năng cao nhất, phải đã tai",
	"lan":       "lăn né",
	"uong":      "uống bình",
	"hon":       "nhặt hồn",
	"chet_quai": "quái chết",
	"chet":      "người chơi chết",
	"vo_the":    "vỡ tư thế — báo cửa sổ kết liễu đã mở",
	"gam_boss":  "boss gầm — phải nghe thấy TRƯỚC khi nhìn thấy",
	"bia_da":    "bật bia đá",
	"hoc_chu":   "học được một chữ mới",
}

var _kho := {}
var _kenh: Array[AudioStreamPlayer] = []
var _toi := 0

func _ready() -> void:
	_nap_tieng_that()
	for i in SO_KENH:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_kenh.append(p)

## Quét `assets/tieng/` tìm file khớp tên trong `TIENG`.
##
## Thư mục chưa có thì thôi — đây là đường đi bình thường cho tới khi có người
## làm âm thanh, không phải lỗi, nên KHÔNG cảnh báo. Cảnh báo mười lăm dòng mỗi
## lần khởi động cũng là một kiểu ồn.
func _nap_tieng_that() -> void:
	if not DirAccess.dir_exists_absolute(THU_MUC):
		return
	for ten in TIENG.keys():
		for duoi in DUOI:
			var duong: String = THU_MUC + String(ten) + duoi
			if not ResourceLoader.exists(duong):
				continue
			var tieng := load(duong) as AudioStream
			if tieng != null:
				_kho[ten] = tieng
			break

## Phát một tiếng. Chưa có file thật cho tên đó thì KHÔNG phát gì — im lặng là
## đường đi bình thường lúc này, không phải lỗi.
##
## `cao` nhân vào cao độ, cho phép cùng một tiếng nghe khác đi chút để đánh
## mười nhát không ra mười lần y hệt nhau (thứ làm tai mệt nhất).
func phat(ten: String, cao := 1.0, to := 1.0) -> void:
	if not _kho.has(ten) or _kenh.is_empty():
		return
	var p := _kenh[_toi]
	_toi = (_toi + 1) % _kenh.size()
	p.stream = _kho[ten]
	p.pitch_scale = clampf(cao * randf_range(0.94, 1.07), 0.3, 3.0)
	p.volume_db = linear_to_db(clampf(to, 0.01, 2.0))
	p.play()

## Có tiếng thật cho tên này chưa. Bộ kiểm tra dùng để phân biệt "chưa có file"
## (bình thường) với "có file mà nạp hỏng".
func co_tieng(ten: String) -> bool:
	return _kho.has(ten)
