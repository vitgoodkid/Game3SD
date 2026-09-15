class_name SinhMonDo
extends RefCounted

## Sinh món đồ rơi ra từ quái. Luật 1 của CLAUDE.md áp thẳng vào đây: KHÔNG có
## một chữ Hán nào viết trong file này.
##
##   trung tâm  lấy từ nguyen_lieu.csv, cột vi_tri = trung_tam (剑 刀 甲 盔…)
##   bổ nghĩa   lấy từ nguyen_lieu.csv (vi_tri = bo_nghia) trộn với từ vựng
##              theo CHỦ ĐỀ của vùng trong vung.csv
##
## Vì sao cho cả chữ thường vào chứ không chỉ 38 nguyên liệu: bản 3D cho khắc
## bất kỳ chữ nào đã học lên vũ khí (mục 4.6), nên đồ rơi cũng phải mang được
## chữ thường — nếu không thì cả đời người chơi chỉ gặp đúng 38 mặt chữ trên đồ,
## và cái "học thêm một chữ là mở khoá lại kho đồ cũ" gần như không xảy ra.
##
## Chữ của vùng nào thì ra ở vùng đó ⇒ đi sâu là gặp chữ khó hơn, đúng "độ hiếm
## = độ khó" của mục 4.5.

## Kho chữ bổ nghĩa dựng một lần cho mỗi vùng rồi giữ lại. Dữ liệu vùng không
## đổi lúc chạy, mà quét cả 1011 dòng từ vựng cho MỖI con quái chết thì đó là
## việc làm lại y hệt hàng nghìn lần.
static var _kho_theo_vung := {}

## Bảng số chữ bổ nghĩa. Bốc ngẫu nhiên một ô — trọng số nằm ở việc lặp lại số
## nào nhiều lần, khỏi cần bảng xác suất riêng.
const SO_BO_NGHIA := [0, 0, 1, 1, 1, 2, 2, 3]

## Sinh một món cho `ma_vung`. `hat` = 0 nghĩa là ngẫu nhiên thật; truyền hạt
## vào thì cùng hạt luôn ra cùng món — cần cho test, và cho việc đặt sẵn đồ ở
## một chỗ cố định trên bản đồ.
##
## Tên là `sinh_mon` chứ không phải `sinh`: GDScript đã có sẵn hàm `sinh()`
## (sin hyperbol) và nó ăn mất mọi lời gọi không có tiền tố trong file này.
static func sinh_mon(ma_vung: String = "", hat: int = 0) -> MonDo:
	var r := RandomNumberGenerator.new()
	if hat != 0:
		r.seed = hat
	else:
		r.randomize()

	var nen := VocabDB.nguyen_lieu_theo_vi_tri("trung_tam")
	if nen.is_empty():
		return null
	var tt := String(nen[r.randi() % nen.size()]["chu"])

	return _dung_mon(tt, ma_vung, r)

## Sinh một món thuộc ĐÚNG một loại trang bị (vukhi / khien / giap). Khác
## `sinh_mon` ở chỗ chữ trung tâm không bốc ngẫu nhiên trong cả bảng mà chỉ
## bốc trong đám có `loai` đó.
##
## Vẫn không có chữ Hán nào trong file này: "vukhi" và "khien" là tên LOẠI
## trong nguyen_lieu.csv, không phải nội dung từ vựng. Đổi khiên trong game
## thành chữ khác chỉ cần sửa CSV, file này không biết.
static func sinh_theo_loai(loai: String, ma_vung: String = "", hat: int = 0) -> MonDo:
	var nen := VocabDB.nguyen_lieu_theo_loai(loai)
	if nen.is_empty():
		return null
	var r := RandomNumberGenerator.new()
	if hat != 0:
		r.seed = hat
	else:
		r.randomize()
	var tt := String(nen[r.randi() % nen.size()]["chu"])

	return _dung_mon(tt, ma_vung, r)

## Dựng món đồ quanh một chữ trung tâm đã chọn: bốc thêm mấy chữ bổ nghĩa của
## vùng rồi xếp trung tâm xuống cuối. Hai hàm sinh ở trên chỉ khác nhau ở cách
## CHỌN chữ trung tâm; phần còn lại dùng chung ở đây.
static func _dung_mon(tt: String, ma_vung: String, r: RandomNumberGenerator) -> MonDo:
	var kho := kho_bo_nghia(ma_vung)
	var ten: Array = []
	var so: int = SO_BO_NGHIA[r.randi() % SO_BO_NGHIA.size()]
	var dem := 0
	while ten.size() < so and dem < so * 8 and not kho.is_empty():
		dem += 1
		var c := String(kho[r.randi() % kho.size()])
		if c != tt and not ten.has(c):
			ten.append(c)
	ten.append(tt)

	# Tên phải đọc được như một câu: trung tâm đứng cuối, bổ nghĩa đứng trước.
	# Kho bổ nghĩa đã lọc rồi nên gần như không rơi vào đây, nhưng dữ liệu sửa
	# tay thì sai lúc nào không biết — sai thì rơi món trần, đừng rơi món hỏng.
	if not bool(TenDoVat.kiem_ten(ten)["duoc"]):
		ten = [tt]
	return MonDo.new(ten, r.randi())

## Kho chữ bổ nghĩa của một vùng: nguyên liệu bổ nghĩa của bản 2D + chữ thuộc
## chủ đề vùng. Vùng không khai chủ đề (thị trấn đầu game) thì chỉ có nguyên
## liệu — đúng ý: chỗ mở đầu nên rơi đồ đọc được, không nên rơi chữ lạ hoắc.
##
## Hàm này phải THUẦN: cùng một vùng luôn cho cùng một kho, cùng thứ tự. Bản
## đầu có `shuffle()` ở đây và thế là hỏng cả tính tất định của hạt giống —
## `Array.shuffle()` bốc từ RNG toàn cục chứ không từ RNG đã gieo hạt, nên cùng
## một hạt ra hai món khác nhau. Bộ kiểm tra bắt được đúng chỗ này.
static func kho_bo_nghia(ma_vung: String) -> Array:
	if _kho_theo_vung.has(ma_vung):
		return _kho_theo_vung[ma_vung]
	var ds: Array = []
	for n in VocabDB.nguyen_lieu_theo_vi_tri("bo_nghia"):
		# Chữ không xếp vào khe nào (đồ ăn của công thức cũ) góp 0 điểm — khắc
		# lên vũ khí thì chỉ tổ làm tên dài ra mà không đổi gì.
		if String(n.get("khe", "")) != "":
			ds.append(String(n["chu"]))

	var v := VocabDB.vung_cua(ma_vung)
	for cd in v.get("chu_de", []):
		for tu in VocabDB.loc(String(cd)):
			var c := String(tu["chu"])
			# Chữ trung tâm không được đứng trước — nó là trung tâm, chỗ của nó
			# là cuối tên (mục 4.2).
			if VocabDB.vi_tri_cua(c) != "trung_tam" and not ds.has(c):
				ds.append(c)
	_kho_theo_vung[ma_vung] = ds
	return ds
