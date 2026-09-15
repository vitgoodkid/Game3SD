extends Node

## Âm thanh (mốc 7). Autoload: gọi bằng "AmThanh".
##
## Dự án KHÔNG có một file .wav nào, và sẽ không có cho tới khi có người làm
## âm thanh. Nên mọi tiếng ở đây được TỔNG HỢP BẰNG CODE lúc khởi động: nhiễu,
## sóng sin, bao biên độ. Xấu hơn mẫu thu thật nhiều, nhưng mục 14.6 nói đúng
## một điều quan trọng — game đang thiếu HẲN chiều nghe, và thiếu hẳn thì tệ
## hơn là có mà chưa hay.
##
## Ba thứ một tiếng động trong souls-like phải làm được, và cả ba đều làm được
## bằng bao biên độ chứ không cần mẫu đẹp:
##
##   BÁO TRƯỚC   tiếng vung tay lên báo đòn sắp tới — người chơi né bằng tai
##               khi mắt đang nhìn chỗ khác
##   XÁC NHẬN    trúng đòn khác hẳn trượt đòn, đỡ khác hẳn đỡ phản
##   PHÂN BIỆT   nhẹ khác nặng, của mình khác của quái
##
## Thay bằng file thật sau: giữ nguyên tên trong `TIENG`, nạp `AudioStream` vào
## `_kho` thay cho hàm tổng hợp. Mọi chỗ gọi `AmThanh.phat()` không phải sửa.

## Tần số lấy mẫu. 22050 đủ cho tiếng động ngắn, và nhẹ nửa bộ nhớ so với 44100.
const TAN_SO := 22050

## Bao nhiêu kênh phát cùng lúc. Đánh nhau với bốn con quái thì tiếng chồng
## nhau liên tục; ít kênh quá là nuốt tiếng, nhiều quá là ồn.
const SO_KENH := 12

var _kho := {}
var _kenh: Array[AudioStreamPlayer] = []
var _toi := 0

## Bảng tiếng. Mỗi dòng: dạng sóng, dài (giây), cao độ đầu → cuối (Hz), độ ồn,
## độ cong của bao biên độ (càng cao càng "cộc").
const TIENG := {
	"vung_nhe":  {"dang": "gio",   "dai": 0.16, "f1": 900.0, "f2": 420.0, "on": 0.9, "cong": 2.4, "to": 0.28},
	"vung_nang": {"dang": "gio",   "dai": 0.34, "f1": 520.0, "f2": 180.0, "on": 1.0, "cong": 1.6, "to": 0.42},
	"trung":     {"dang": "va",    "dai": 0.20, "f1": 240.0, "f2": 70.0,  "on": 0.55, "cong": 5.0, "to": 0.55},
	"trung_to":  {"dang": "va",    "dai": 0.34, "f1": 150.0, "f2": 44.0,  "on": 0.6, "cong": 3.6, "to": 0.7},
	"do":        {"dang": "kim",   "dai": 0.22, "f1": 1400.0, "f2": 900.0, "on": 0.35, "cong": 4.5, "to": 0.5},
	"do_phan":   {"dang": "kim",   "dai": 0.45, "f1": 2100.0, "f2": 1500.0, "on": 0.12, "cong": 2.0, "to": 0.62},
	"lan":       {"dang": "gio",   "dai": 0.26, "f1": 300.0, "f2": 120.0, "on": 1.0, "cong": 2.8, "to": 0.22},
	"uong":      {"dang": "sin",   "dai": 0.40, "f1": 380.0, "f2": 720.0, "on": 0.1, "cong": 1.4, "to": 0.34},
	"hon":       {"dang": "sin",   "dai": 0.55, "f1": 620.0, "f2": 1240.0, "on": 0.05, "cong": 1.2, "to": 0.34},
	"chet_quai": {"dang": "va",    "dai": 0.60, "f1": 180.0, "f2": 40.0,  "on": 0.7, "cong": 2.2, "to": 0.6},
	"chet":      {"dang": "sin",   "dai": 1.30, "f1": 200.0, "f2": 55.0,  "on": 0.15, "cong": 1.1, "to": 0.7},
	"vo_the":    {"dang": "kim",   "dai": 0.50, "f1": 700.0, "f2": 260.0, "on": 0.45, "cong": 1.8, "to": 0.6},
	"gam_boss":  {"dang": "gam",   "dai": 1.60, "f1": 110.0, "f2": 62.0,  "on": 0.5, "cong": 1.0, "to": 0.85},
	"bia_da":    {"dang": "sin",   "dai": 0.90, "f1": 440.0, "f2": 660.0, "on": 0.04, "cong": 1.2, "to": 0.4},
	"hoc_chu":   {"dang": "sin",   "dai": 0.70, "f1": 523.0, "f2": 1046.0, "on": 0.03, "cong": 1.3, "to": 0.45},
}

func _ready() -> void:
	for ten in TIENG.keys():
		_kho[ten] = _tong_hop(TIENG[ten])
	for i in SO_KENH:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_kenh.append(p)

## Phát một tiếng. `cao` nhân vào cao độ — cho phép cùng một tiếng nghe khác đi
## chút, để đánh mười nhát không ra mười lần y hệt nhau (thứ làm tai mệt nhất).
func phat(ten: String, cao := 1.0, to := 1.0) -> void:
	if not _kho.has(ten) or _kenh.is_empty():
		return
	var p := _kenh[_toi]
	_toi = (_toi + 1) % _kenh.size()
	p.stream = _kho[ten]
	p.pitch_scale = clampf(cao * randf_range(0.94, 1.07), 0.3, 3.0)
	p.volume_db = linear_to_db(clampf(to, 0.01, 2.0))
	p.play()

# --- Tổng hợp --------------------------------------------------------

## Dựng một tiếng thành AudioStreamWAV 16-bit mono.
##
## Bao biên độ dùng chung cho mọi dạng: tăng rất nhanh rồi tắt theo hàm mũ. Đó
## là hình dạng của gần như mọi tiếng va chạm ngoài đời, và là thứ khiến tai
## nghe ra "cú đánh" chứ không phải "tiếng ù".
func _tong_hop(c: Dictionary) -> AudioStreamWAV:
	var dai := float(c["dai"])
	var n := int(TAN_SO * dai)
	var dl := PackedByteArray()
	dl.resize(n * 2)
	var r := RandomNumberGenerator.new()
	r.seed = hash(c)
	var pha := 0.0
	var loc := 0.0     # trạng thái bộ lọc thông thấp một cực

	for i in n:
		var t := float(i) / float(n)
		# Bao biên độ: vọt lên trong 1% đầu rồi tắt dần.
		var bao := (t / 0.01) if t < 0.01 else pow(1.0 - t, float(c["cong"]))
		var f: float = lerpf(float(c["f1"]), float(c["f2"]), t * t)
		pha += TAU * f / float(TAN_SO)
		var v := 0.0
		match String(c["dang"]):
			"gio":
				# Tiếng vung tay: nhiễu lọc thông thấp, tần số cắt tụt dần.
				loc = lerpf(loc, r.randf_range(-1.0, 1.0), clampf(f / 2200.0, 0.02, 0.9))
				v = loc
			"va":
				# Tiếng đập: sin tụt cao độ nhanh + một nhúm nhiễu ở đầu.
				v = sin(pha) * 0.8 + r.randf_range(-1.0, 1.0) * float(c["on"]) * maxf(0.0, 1.0 - t * 6.0)
			"kim":
				# Tiếng kim loại: hai sin lệch nhau cho ra nhịp đập.
				v = (sin(pha) + sin(pha * 1.497)) * 0.45
			"gam":
				# Tiếng gầm: sin trầm + méo, cộng nhiễu chậm. Boss phải nghe
				# thấy từ trước khi nhìn thấy — đó là cả tác dụng của nó.
				v = tanh(sin(pha) * 2.6) * 0.7 + sin(pha * 0.5) * 0.3
			_:
				v = sin(pha)
		if String(c["dang"]) != "gio":
			v += r.randf_range(-1.0, 1.0) * float(c["on"]) * 0.25
		var m := int(clampf(v * bao * float(c["to"]), -1.0, 1.0) * 32000.0)
		dl[i * 2] = m & 0xFF
		dl[i * 2 + 1] = (m >> 8) & 0xFF

	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAN_SO
	w.stereo = false
	w.data = dl
	return w
