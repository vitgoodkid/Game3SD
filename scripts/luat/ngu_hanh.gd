extends Node

## Ngũ hành — tương sinh tương khắc. Autoload: gọi bằng "NguHanh".
##
## Vì sao hệ này đáng có mặt: bảng kháng nguyên tố của phần lớn game là luật
## bịa, người chơi học thuộc xong ra khỏi game là vứt. Vòng ngũ hành thì có
## thật, dùng được ngoài đời, và nó TỰ BẮT người chơi phải thuộc — không thuộc
## thì đánh boss bằng vũ khí sinh ra hành của nó, boss hồi máu.
##
## Chú ý luật số 1 của dự án: code KHÔNG được biết chữ 火 tồn tại. Vòng ngũ
## hành là ngoại lệ DUY NHẤT được phép, vì nó là năm hằng số của văn hoá chứ
## không phải nội dung game — thêm hành thứ sáu là chuyện vô nghĩa. Còn chữ
## nào MANG hành nào thì vẫn nằm ở cột `ngu_hanh` trong data/tu_vung.csv.

## Thứ tự trong mảng chính là vòng TƯƠNG SINH: mỗi hành sinh ra hành đứng sau,
## hành cuối vòng lại sinh hành đầu. Mọi quan hệ còn lại suy ra từ đây, không
## khai báo thêm bảng nào — bảng khai tay là chỗ sinh lỗi.
const VONG := ["木", "火", "土", "金", "水"]

const TEN := {
	"木": "Mộc", "火": "Hoả", "土": "Thổ", "金": "Kim", "水": "Thuỷ",
}

## Màu để tô viền món đồ / thanh máu quái. Theo màu ngũ hành cổ điển.
const MAU := {
	"木": Color(0.36, 0.74, 0.42),
	"火": Color(0.89, 0.34, 0.26),
	"土": Color(0.78, 0.63, 0.35),
	"金": Color(0.85, 0.85, 0.90),
	"水": Color(0.32, 0.55, 0.88),
}

# --- Hệ số ----------------------------------------------------------
# Ba con số này quyết định hệ ngũ hành có sức nặng hay chỉ là trang trí.
# 1.5 / 0.6 đủ để người chơi CẢM THẤY khác biệt mà không tới mức bắt buộc
# phải mang đủ năm vũ khí. Đổi ở đây, không rải số ra khắp nơi.

## Vũ khí khắc được hành của quái.
const HS_KHAC := 1.5
## Vũ khí bị hành của quái khắc lại.
const HS_BI_KHAC := 0.6
## Vũ khí sinh ra hành của quái — quái HỒI máu bằng ngần này phần sát thương.
## Số âm là cố ý: dùng sai thì đánh càng mạnh càng tự hại.
const HS_SINH := -0.5
## Hai món trang bị tương sinh nhau thì cả hai cùng được cộng.
const CONG_HUONG := 0.10

# --- Tra cứu vòng ---------------------------------------------------

func hop_le(hanh: String) -> bool:
	return VONG.has(hanh)

func ten_cua(hanh: String) -> String:
	return TEN.get(hanh, "")

func mau_cua(hanh: String) -> Color:
	return MAU.get(hanh, Color(0.72, 0.72, 0.75))

## Hành mà `hanh` sinh ra (木 sinh 火).
func sinh_ra(hanh: String) -> String:
	var i := VONG.find(hanh)
	return "" if i < 0 else VONG[(i + 1) % VONG.size()]

## Hành sinh ra `hanh` (火 được 木 sinh).
func duoc_sinh_boi(hanh: String) -> String:
	var i := VONG.find(hanh)
	return "" if i < 0 else VONG[(i - 1 + VONG.size()) % VONG.size()]

## Hành mà `hanh` khắc (木 khắc 土). Trong vòng năm hành, khắc = cách hai bậc.
func khac(hanh: String) -> String:
	var i := VONG.find(hanh)
	return "" if i < 0 else VONG[(i + 2) % VONG.size()]

## Hành khắc được `hanh` (土 bị 木 khắc).
func bi_khac_boi(hanh: String) -> String:
	var i := VONG.find(hanh)
	return "" if i < 0 else VONG[(i - 2 + VONG.size()) % VONG.size()]

# --- Áp vào sát thương ----------------------------------------------

## Hệ số nhân sát thương khi vũ khí hành `hanh_danh` đánh vào hành `hanh_chiu`.
##
## Trả về ÂM nghĩa là đối phương hồi máu — bên gọi phải xử đúng dấu, đừng
## clamp về 0. Đó chính là hình phạt cho việc dùng sai vũ khí, và là lý do
## người chơi phải thuộc vòng sinh.
##
## Một trong hai bên không có hành (quái vô danh, boss 无) thì trả 1.0 —
## không khắc được cũng không bị khắc. Boss cuối cố ý như vậy.
func he_so(hanh_danh: String, hanh_chiu: String) -> float:
	if not hop_le(hanh_danh) or not hop_le(hanh_chiu):
		return 1.0
	if khac(hanh_danh) == hanh_chiu:
		return HS_KHAC
	if bi_khac_boi(hanh_danh) == hanh_chiu:
		return HS_BI_KHAC
	if sinh_ra(hanh_danh) == hanh_chiu:
		return HS_SINH
	return 1.0

## Câu một dòng giải thích vì sao đòn vừa rồi mạnh/yếu — hiện ở HUD lúc đánh
## trúng. Đây là chỗ DẠY: người chơi thấy số lạ thì đọc được ngay tại sao.
func giai_thich(hanh_danh: String, hanh_chiu: String) -> String:
	if not hop_le(hanh_danh) or not hop_le(hanh_chiu):
		return ""
	if khac(hanh_danh) == hanh_chiu:
		return "%s khắc %s" % [hanh_danh, hanh_chiu]
	if bi_khac_boi(hanh_danh) == hanh_chiu:
		return "%s khắc %s — đòn yếu đi" % [hanh_chiu, hanh_danh]
	if sinh_ra(hanh_danh) == hanh_chiu:
		return "%s sinh %s — nó đang HỒI MÁU" % [hanh_danh, hanh_chiu]
	return ""

# --- Cộng hưởng giữa các món đang mặc -------------------------------

## Đếm số cặp tương sinh trong danh sách hành của đồ đang mặc, rồi trả về
## hệ số cộng chung. Ví dụ mặc đồ 木 và 火 (mộc sinh hoả) thì cả hai +10%.
##
## Đếm theo CẶP chứ không theo món, để mặc năm món cùng hành không ăn gì —
## người chơi phải nghĩ về vòng sinh mới xếp được bộ đồ tốt.
func cong_huong(danh_sach_hanh: Array) -> float:
	var cap := 0
	for i in danh_sach_hanh.size():
		for j in range(i + 1, danh_sach_hanh.size()):
			var a: String = danh_sach_hanh[i]
			var b: String = danh_sach_hanh[j]
			if sinh_ra(a) == b or sinh_ra(b) == a:
				cap += 1
	return 1.0 + CONG_HUONG * float(cap)

## Chuỗi mô tả vòng sinh để hiện ở bảng chỉ số / màn hướng dẫn. Không hardcode
## ở giao diện — lấy từ đây để đổi VONG là đổi luôn mọi chỗ hiển thị.
func chuoi_tuong_sinh() -> String:
	var phan: Array[String] = []
	for h in VONG:
		phan.append(h)
	phan.append(VONG[0])
	return " → ".join(phan)

func chuoi_tuong_khac() -> String:
	var phan: Array[String] = []
	for h in VONG:
		phan.append("%s khắc %s" % [h, khac(h)])
	return "   ".join(phan)
