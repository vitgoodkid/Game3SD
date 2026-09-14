extends Node

## Độ hiếm của nguyên liệu và của món chế ra. Autoload: gọi bằng "DoHiem".
##
## Ý chính: ĐỘ HIẾM = ĐỘ KHÓ. Chữ ở khu càng sâu thì càng hiếm, mà khu càng sâu
## thì từ vựng càng khó. Nên đuổi theo đồ xịn cũng chính là học từ khó hơn —
## hệ độ hiếm tự nó đi dạy học, không phải màu mè dán thêm cho vui.
##
## Bậc của từng nguyên liệu nằm ở cột "hiem" trong data/nguyen_lieu.csv, suy ra
## từ thứ tự khu rơi nó (xem ZoneLootManager.ZONES). Muốn chỉnh thì sửa CSV,
## không đụng file này.

## Bậc xếp từ thấp lên cao. "diem" là điểm cộng vào khi ghép món (xem hiem_mon).
const BAC := {
	"thuong":      {"ten": "Thường",       "diem": 0, "mau": Color(0.71, 0.72, 0.76)},
	"hiem":        {"ten": "Hiếm",         "diem": 1, "mau": Color(0.37, 0.85, 0.48)},
	"quy":         {"ten": "Quý",          "diem": 2, "mau": Color(0.33, 0.66, 0.94)},
	"su_thi":      {"ten": "Sử thi",       "diem": 3, "mau": Color(0.72, 0.48, 0.94)},
	"huyen_thoai": {"ten": "Huyền thoại",  "diem": 4, "mau": Color(0.94, 0.57, 0.24)},
}
const BAC_MAC_DINH := "thuong"

## Thứ tự bậc từ thấp lên cao, để tra ngược từ điểm ra bậc.
const THU_TU := ["thuong", "hiem", "quy", "su_thi", "huyen_thoai"]

## Tổng điểm của các thành phần rơi vào khoảng nào thì món ra bậc đó.
## Món ở bàn ghép có tới 4 ô nên với tay được lên bậc cao hơn công thức cố định
## (chỉ 2 thành phần) — đúng ý đồ: bàn ghép mới là chỗ chơi về cuối.
const NGUONG := [
	{"tu": 9, "bac": "huyen_thoai"},
	{"tu": 6, "bac": "su_thi"},
	{"tu": 4, "bac": "quy"},
	{"tu": 2, "bac": "hiem"},
	{"tu": 0, "bac": "thuong"},
]

# --- Tra cứu -------------------------------------------------------

## Bậc hiếm của một nguyên liệu. Chữ lạ thì coi như thường.
func hiem_cua(chu: String) -> String:
	var bac: String = VocabDB.nguyen_lieu_cua(chu).get("hiem", "")
	return bac if BAC.has(bac) else BAC_MAC_DINH

func diem_cua(chu: String) -> int:
	return BAC[hiem_cua(chu)]["diem"]

func mau(bac: String) -> Color:
	return BAC.get(bac, BAC[BAC_MAC_DINH])["mau"]

func ten(bac: String) -> String:
	return BAC.get(bac, BAC[BAC_MAC_DINH])["ten"]

## Màu của cả một món, tra thẳng từ danh sách thành phần.
func mau_mon(thanh_phan: Array) -> Color:
	return mau(hiem_mon(thanh_phan))

# --- Độ hiếm của món chế ra ----------------------------------------

## Bậc của món = cộng điểm mọi thành phần rồi dò bảng ngưỡng.
## Cộng chứ không lấy max: nhét thêm một chữ hiếm vào phải NÂNG được món lên,
## đúng như cách bàn ghép hoạt động — càng nhiều bổ nghĩa xịn, món càng xịn.
func hiem_mon(thanh_phan: Array) -> String:
	var diem := 0
	for chu in thanh_phan:
		diem += diem_cua(chu)
	for muc in NGUONG:
		if diem >= muc["tu"]:
			return muc["bac"]
	return BAC_MAC_DINH

## Tổng điểm hiếm — để hiện "còn thiếu bao nhiêu nữa thì lên bậc".
func diem_mon(thanh_phan: Array) -> int:
	var diem := 0
	for chu in thanh_phan:
		diem += diem_cua(chu)
	return diem
