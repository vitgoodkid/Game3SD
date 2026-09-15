extends Node

## Luật chiến đấu DÙNG CHUNG — không phụ thuộc vào việc đánh nhau theo kiểu nào.
## Autoload: gọi bằng "ChienDau".
##
## Vì sao tách khỏi màn chiến đấu của bản 2D (`battle.gd`, đã xoá khỏi repo): sau này game có thêm chế độ chém ngoài map, và
## hai chế độ dùng chung y hệt mọi thứ ở đây — cách tính sát thương, giáp trừ
## bao nhiêu, phép hồi máu hồi mấy điểm, nguyên tố băng/lửa làm gì. Nếu viết
## thẳng vào màn đó thì tới lúc dựng chế độ kia phải chép lại toàn bộ, rồi
## từ đó về sau mỗi lần chỉnh cân bằng phải nhớ sửa hai chỗ.
##
## QUY TẮC để biết code mới nên nằm ở đâu — tự hỏi một câu:
##     "Cái này còn nghĩa gì không nếu không có câu hỏi nào?"
##   CÓ    (sát thương, giáp, hồi máu, chặn đòn, nguyên tố, độ hiếm)  -> viết vào ĐÂY
##   KHÔNG (xoá bớt đáp án sai, bỏ qua câu hỏi, chọn dạng câu hỏi)    -> việc của màn hình

## Hiệu ứng phép chạy được ở MỌI kiểu đánh nhau. Hai cái không có trong danh
## sách này — loai_bot (xoá đáp án sai) và bo_qua (bỏ qua câu) — chỉ có nghĩa
## khi đang có câu hỏi trước mặt, nên màn hình tự lo lấy.
const HIEU_UNG_CHUNG := ["hoi_mau", "chan_don", "don_manh", "danh_truoc"]

## Dù giáp dày tới đâu cũng luôn chịu ít nhất bấy nhiêu máu mỗi đòn. Không có
## sàn này thì mặc đủ giáp là bất tử và trận đánh mất sạch sức nặng.
const DON_TOI_THIEU := 1

## Mỗi chữ HỌC được làm quái đánh đau thêm bấy nhiêu phần.
##
## Vì sao phải có: máu tối đa người chơi = 100 + 6 × số chữ đã ghép, mà vốn từ
## giờ mở tới 165 chữ ⇒ trần máu 1090. Sát thương quái vốn chỉ tăng theo CẤP KHU
## nên tới khu cuối người chơi chịu được hơn 60 câu sai — trận đánh mất sạch sức
## ép. Cho quái mạnh lên theo đúng vốn từ thì tỉ lệ "chịu được mấy câu sai" giữ
## nguyên 5-7 suốt game (đã đo trên cả 6 chặng).
##
## 0.025 chọn từ tính ngược: muốn giữ 4-7 câu sai với giáp thực tế từng chặng.
const SUC_MOI_CHU := 0.025

## CHỈ nhân vào SÁT THƯƠNG quái, KHÔNG nhân vào máu quái. Sát thương người chơi
## không tăng theo vốn từ (chỉ tăng theo vũ khí), nên máu quái mà cũng nhân lên
## thì trận cuối dài tới 45 câu đúng mới hạ nổi một con boss.
func he_so_theo_von_tu(so_chu: int) -> float:
	return 1.0 + SUC_MOI_CHU * float(maxi(so_chu, 0))

func la_hieu_ung_chung(hieu_ung: String) -> bool:
	return HIEU_UNG_CHUNG.has(hieu_ung)

# --- Nguyên tố --------------------------------------------------------
#
# Bảy chữ có khe="nguyen_to" trong nguyen_lieu.csv, nhưng chỉ SÁU chữ dưới
# đây có phép riêng — 红 (hồng) là đá quý THƯỜNG, chỉ cộng chỉ số như mọi
# khe khác lúc ghép (bàn khắc chữ ở bia đá), không có hiệu ứng trong trận.
## % nghĩa là số thập phân (0.2 = 20%), không phải số nguyên phần trăm.
const NGUYEN_TO := {
	"火": {"ten": "Hoả", "st_them_pt": 0.20},
	"水": {"ten": "Thuỷ", "hut_mau_pt": 0.20},
	"毒": {"ten": "Độc", "doc_pt": 0.25, "doc_luot": 3},
	"冰": {"ten": "Băng", "ne_pt": 0.15},
	"石": {"ten": "Thạch", "giap_them": 6},
	"魔": {"ten": "Ma", "phep_them_pt": 0.30},
}
## Hằng tên chữ, để bên gọi không phải gõ thẳng ký tự Hán vào —
## đổi chữ đại diện cho nguyên tố nào thì chỉ sửa NGUYEN_TO ở trên và hai
## dòng này, không phải lục khắp nơi.
const NGUYEN_TO_DOC := "毒"
const NGUYEN_TO_NE := "冰"
const NGUYEN_TO_MA := "魔"

## Nguyên tố (nếu có) trong danh sách thành phần một món đồ. "" nếu không có
## nguyên tố nào, hoặc chữ đó là 红 (đá quý thường, không có phép riêng).
func nguyen_to_cua(thanh_phan: Array) -> String:
	for chu in thanh_phan:
		if NGUYEN_TO.has(chu):
			return chu
	return ""

func ten_nguyen_to(nt: String) -> String:
	return NGUYEN_TO.get(nt, {}).get("ten", "")

# --- Tính sát thương ------------------------------------------------

## Sát thương mình gây ra: bốc trong khoảng của vũ khí, cộng phần "đòn mạnh"
## đang tích sẵn (phép don_manh) nếu có, rồi nhân thêm % của Hoả nếu vũ khí
## mang nguyên tố đó.
func sat_thuong_gay(st_min: int, st_max: int, cong_them: int = 0, nt_vu_khi: String = "") -> int:
	var dam := randi_range(st_min, st_max) + cong_them
	var pt: float = NGUYEN_TO.get(nt_vu_khi, {}).get("st_them_pt", 0.0)
	if pt > 0.0:
		dam = int(round(dam * (1.0 + pt)))
	return dam

## Sát thương mình phải chịu: giáp trừ thẳng vào con số quái bốc được,
## nhưng không bao giờ xuống dưới DON_TOI_THIEU.
func sat_thuong_chiu(st_min: int, st_max: int, giap: int) -> int:
	return maxi(DON_TOI_THIEU, randi_range(st_min, st_max) - giap)

## Máu hồi được nhờ Thuỷ trên vũ khí, tính trên sát thương VỪA gây ra. 0 nếu
## vũ khí không mang Thuỷ.
func hut_mau(sat_thuong: int, nt_vu_khi: String) -> int:
	var pt: float = NGUYEN_TO.get(nt_vu_khi, {}).get("hut_mau_pt", 0.0)
	return int(round(sat_thuong * pt)) if pt > 0.0 else 0

## Độc trên vũ khí: trả về (số lượt còn rải độc, sát thương mỗi lượt). Gọi
## dat_doc() trên TrangThai của quái bằng kết quả này ngay sau đòn đánh trúng.
func doc_tu_danh(sat_thuong: int, nt_vu_khi: String) -> Vector2i:
	var tt: Dictionary = NGUYEN_TO.get(nt_vu_khi, {})
	if not tt.has("doc_pt"):
		return Vector2i.ZERO
	return Vector2i(int(tt["doc_luot"]), int(round(sat_thuong * tt["doc_pt"])))

## Băng trên giáp: né TRỌN một đòn sắp ăn, miễn phí — không tốn khiên phép.
## Gọi MỘT LẦN cho mỗi đòn sắp chịu, không né được thì bên gọi tính sát
## thương chịu như thường.
func ne_duoc(nt_giap: String) -> bool:
	var pt: float = NGUYEN_TO.get(nt_giap, {}).get("ne_pt", 0.0)
	return pt > 0.0 and randf() < pt

## Giáp cộng thêm cố định từ Thạch trên một món giáp — cộng dồn được nếu
## nhiều món cùng mang nguyên tố này (bên gọi tự lặp qua từng món).
func giap_tu_thach(nt_giap: String) -> int:
	return int(NGUYEN_TO.get(nt_giap, {}).get("giap_them", 0))

## Hệ số nhân cho dung_phep() — 1.0 nếu không có món nào mang Ma, 1.0 + %
## nếu có. co_ma: có ít nhất một món trang bị đang mặc mang nguyên tố Ma.
func he_so_ma(co_ma: bool) -> float:
	if not co_ma:
		return 1.0
	return 1.0 + float(NGUYEN_TO.get(NGUYEN_TO_MA, {}).get("phep_them_pt", 0.0))

# --- Trạng thái tạm trong lúc đánh ----------------------------------

## Khiên còn mấy lần đỡ, đòn kế tiếp cộng thêm bao nhiêu. Cả hai chế độ đánh
## đều cần đúng hai thứ này, nên để chung một chỗ.
## Dùng:  var tt := ChienDau.TrangThai.new()
class TrangThai:
	## Số lần mất máu sắp tới sẽ bị chặn (do phép chan_don).
	var chan := 0
	## Cộng thêm cho lần gây sát thương KẾ TIẾP, rồi tự hết (do phép don_manh).
	var don_them := 0
	## Độc do nguyên tố 毒 trên vũ khí đối phương rải lên MÌNH: còn mấy lượt,
	## mỗi lượt mất bao nhiêu. Quái và người chơi đều dùng chung class này nên
	## ai trúng độc thì mang trạng thái này, không phân biệt bên nào.
	var doc_con_lai := 0
	var doc_moi_luot := 0

	## Lấy phần cộng thêm ra rồi xoá đi — đòn mạnh chỉ ăn đúng một lần.
	func rut_don_them() -> int:
		var n := don_them
		don_them = 0
		return n

	## Thử dùng khiên đỡ một lần mất máu. True = đỡ trọn, lần này không mất máu.
	func do_duoc() -> bool:
		if chan <= 0:
			return false
		chan -= 1
		return true

	## Bắt đầu (hoặc làm mới) độc — lần đánh trúng bằng vũ khí Độc TIẾP THEO
	## ghi đè lượt còn lại, không cộng dồn chồng chất.
	func dat_doc(luot_va_moi_luot: Vector2i) -> void:
		if luot_va_moi_luot.x <= 0:
			return
		doc_con_lai = luot_va_moi_luot.x
		doc_moi_luot = luot_va_moi_luot.y

	## Đầu mỗi lượt mới: rút sát thương độc của lượt này, giảm lượt còn lại.
	## 0 nếu không (còn) trúng độc.
	func rut_doc() -> int:
		if doc_con_lai <= 0:
			return 0
		doc_con_lai -= 1
		return doc_moi_luot

	func xoa() -> void:
		chan = 0
		don_them = 0
		doc_con_lai = 0
		doc_moi_luot = 0

# --- Dùng phép ------------------------------------------------------

## Chạy một phép có hiệu ứng chung. KHÔNG tự trừ/cộng máu — chỉ trả về việc
## cần làm, để bên gọi tự áp theo cách của mình: khung chữ trong trận đấu thì
## vẽ một dòng thông báo, còn ngoài map thì cho số bay lên đầu quái.
##
## he_so_ma: có món đồ nào đang mang nguyên tố Ma thì truyền 1.0 + phep_them_pt
## vào đây — nhân thêm vào phần HỒI/ĐÁNH của phép (không đụng tới chan/don_them,
## vì hai cái đó tính bằng số LƯỢT/LẦN, nhân lên không có nghĩa gì).
##
## Trả về: { "chay": có phải hiệu ứng chung không, "hoi": hồi bao nhiêu máu,
##           "danh": gây ngay bao nhiêu sát thương }
func dung_phep(hieu_ung: String, gia_tri: int, tt: TrangThai, he_so_ma: float = 1.0) -> Dictionary:
	var kq := {"chay": true, "hoi": 0, "danh": 0}
	match hieu_ung:
		"hoi_mau":
			kq["hoi"] = int(round(gia_tri * he_so_ma))
		"chan_don":
			tt.chan += gia_tri
		"don_manh":
			tt.don_them += gia_tri
		"danh_truoc":
			kq["danh"] = int(round(gia_tri * he_so_ma))
		_:
			# Phép riêng của một kiểu đánh (loai_bot, bo_qua) — bên gọi tự xử.
			kq["chay"] = false
	return kq
