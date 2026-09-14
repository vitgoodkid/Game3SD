extends Node

## Tên món đồ là một CÂU tiếng Trung. Autoload: gọi bằng "TenDoVat".
##
## Đây là cơ chế xương sống của cả game (mục 4.1 + 4.2 + 4.3 của bản yêu cầu).
## Phép thử phải qua: thay hết chữ Hán bằng icon vô nghĩa thì game HỎNG.
## File này là chỗ nó hỏng — vì ở đây thứ tự chữ và mặt chữ nắm THÔNG TIN,
## không phải chỉ số.
##
## Ba việc:
##   4.2  Đọc tên trái→phải như ngữ pháp thật: bổ nghĩa trước, trung tâm sau.
##        Chữ càng gần trung tâm càng bổ nghĩa chặt ⇒ đóng góp càng nhiều.
##        冰金剑 và 金冰剑 cùng ba chữ, ra hai món khác hẳn nhau.
##   4.3  Chồng bộ thủ = nâng cấp: 木 → 林 → 森.
##   4.1  Chỉ hiện chỉ số của những chữ người chơi ĐÃ BIẾT. Còn lại là "???".
##
## Không hàm nào ở đây biết chữ cụ thể nào tồn tại — mọi thứ tra từ VocabDB.

## Trọng số theo khoảng cách tới trung tâm. Phần tử 0 là chính trung tâm.
## Con số lấy thẳng từ mục 4.2, đừng đổi lẻ tẻ: đây là thứ làm cho việc đổi
## thứ tự chữ có ý nghĩa. Cho thoải mái hơn 3 bậc để tên dài vẫn chạy.
const TRONG_SO := [1.0, 0.6, 0.35, 0.2, 0.12]
const TRONG_SO_XA := 0.08

## Hệ số theo bậc chồng bộ (cột thang_bac trong tu_vung.csv).
## 木 ×1.0, 林 ×1.45, 森 ×2.0 — người chơi NHÌN THẤY vũ khí mạnh lên vì chữ
## dày đặc thêm, không cần đọc con số nào.
const HS_BAC := {1: 1.0, 2: 1.45, 3: 2.0}

## Chữ chưa đọc được hiện thế này. `□` là ô trống trong nhà in — đúng nghĩa
## "chữ đã bị xoá khỏi thế giới" của cốt truyện.
const CHU_MO := "□"
const SO_MO := "???"

# --- Đọc cấu trúc tên -----------------------------------------------

## Trung tâm của tên = chữ CUỐI. Tiếng Trung đặt trung tâm sau, nên không cần
## tra bảng gì cả — vị trí đã nói lên tất cả. Đó chính là bài học.
func trung_tam(ten: Array) -> String:
	return "" if ten.is_empty() else String(ten[ten.size() - 1])

func bo_nghia(ten: Array) -> Array:
	return [] if ten.size() < 2 else ten.slice(0, ten.size() - 1)

## Trọng số của chữ ở vị trí `i` trong tên dài `n`. i = n-1 là trung tâm.
func trong_so_tai(i: int, n: int) -> float:
	var lui := n - 1 - i
	return TRONG_SO[lui] if lui < TRONG_SO.size() else TRONG_SO_XA

## Tên món đồ có hợp lệ không: phải có đúng một trung tâm, và nó phải đứng
## cuối. Chữ trung tâm kẹt ở giữa là câu sai ngữ pháp — không cho chế.
##
## Trả về {"duoc": bool, "vi_sao": String}. Chuỗi vì sao hiện thẳng ở bàn
## khắc chữ, nên viết cho người chơi đọc chứ không phải cho lập trình viên.
func kiem_ten(ten: Array) -> Dictionary:
	if ten.is_empty():
		return {"duoc": false, "vi_sao": "Chưa có chữ nào."}
	var tt := trung_tam(ten)
	if VocabDB.vi_tri_cua(tt) != "trung_tam":
		return {"duoc": false, "vi_sao": "%s không đứng cuối được — nó là chữ bổ nghĩa." % tt}
	for i in ten.size() - 1:
		var c := String(ten[i])
		if VocabDB.vi_tri_cua(c) == "trung_tam":
			return {"duoc": false,
				"vi_sao": "%s là trung tâm, phải đứng CUỐI. Tiếng Trung: bổ nghĩa trước, trung tâm sau." % c}
	return {"duoc": true, "vi_sao": ""}

# --- Phân tích ra chỉ số --------------------------------------------

## Phân tích trọn vẹn một tên món đồ thành chỉ số.
##
## Trả về dictionary:
##   ten_chu     chuỗi tên, vd "极冰金剑"
##   trung_tam   chữ trung tâm
##   loai        loại vũ khí/giáp, tra từ nguyen_lieu.csv (dùng cho moveset)
##   st_goc      sát thương gốc — CHỈ từ trung tâm. Phần này phai chữ KHÔNG
##               bao giờ ăn vào (mục 4.7), nên tách riêng ngay từ đầu.
##   st_them     sát thương cộng thêm từ các chữ bổ nghĩa
##   nang        tải trọng
##   ngu_hanh    hành của món — lấy của chữ bổ nghĩa GẦN trung tâm nhất có hành
##   bac_cao     bậc chồng bộ cao nhất trong tên
##   phan        mảng từng chữ: {chu, vi_tri, trong_so, gop, ngu_hanh, bac}
func phan_tich(ten: Array) -> Dictionary:
	var kq := {
		"ten_chu": "".join(ten), "trung_tam": "", "loai": "",
		"st_goc": 0.0, "st_them": 0.0, "nang": 0.0,
		"ngu_hanh": "", "bac_cao": 1, "phan": [],
	}
	if ten.is_empty():
		return kq

	var n := ten.size()
	var tt := trung_tam(ten)
	kq["trung_tam"] = tt
	kq["loai"] = VocabDB.loai_nguyen_lieu_cua(tt)

	for i in n:
		var chu := String(ten[i])
		var ts := trong_so_tai(i, n)
		var bac := VocabDB.bac_thang_cua(chu)
		var hs_bac: float = HS_BAC.get(bac, 1.0)
		var cong := float(VocabDB.cong_cua(chu))
		var gop := cong * ts * hs_bac

		if i == n - 1:
			# Trung tâm: điểm của nó là sát thương GỐC, không nhân trọng số
			# (trọng số nó vốn đã là 1.0) nhưng vẫn ăn bậc chồng bộ.
			kq["st_goc"] = cong * hs_bac
		else:
			kq["st_them"] += gop

		kq["nang"] += cong * 0.35 * (1.0 if i == n - 1 else 0.45)
		kq["bac_cao"] = maxi(int(kq["bac_cao"]), bac)

		kq["phan"].append({
			"chu": chu, "vi_tri": i, "trong_so": ts, "gop": gop,
			"ngu_hanh": VocabDB.ngu_hanh_cua(chu), "bac": bac, "cong": cong,
			"lui": n - 1 - i,
		})

	# Hành của món: chữ BỔ NGHĨA gần trung tâm nhất mà có hành thì thắng. Đây
	# chính là chỗ 冰金剑 (kim là chính, băng phủ ngoài) khác hẳn 金冰剑 (băng
	# là chính) — hai món khác nhau từ cùng ba chữ.
	#
	# Chú ý thứ tự: quét BỔ NGHĨA trước, trung tâm SAU. Chữ trung tâm cũng có
	# hành của nó (剑 vốn là 金), nhưng nếu để nó tham gia cùng vòng quét thì
	# nó luôn thắng — vì nó gần trung tâm nhất, nó LÀ trung tâm — và mọi cây
	# kiếm đều thành hệ Kim bất kể khắc chữ gì. Cơ chế xương sống chết ngay tại
	# đó. Hành của trung tâm chỉ dùng khi không chữ bổ nghĩa nào có hành.
	for i in range(n - 2, -1, -1):
		var hanh := VocabDB.ngu_hanh_cua(String(ten[i]))
		if hanh != "":
			kq["ngu_hanh"] = hanh
			break
	if String(kq["ngu_hanh"]) == "":
		kq["ngu_hanh"] = VocabDB.ngu_hanh_cua(tt)

	return kq

## Sát thương thực sau khi tính độ thuần thục. Mục 4.7 nói rõ một câu KHÔNG
## được vi phạm: phai chữ chỉ ăn vào PHẦN CỘNG THÊM, không bao giờ ăn vào
## chỉ số gốc. Người chơi không bao giờ bị yếu tới mức không qua nổi chỗ đã qua.
func sat_thuong_thuc(pt: Dictionary) -> float:
	var them := 0.0
	var n: int = pt["phan"].size()
	for p in pt["phan"]:
		if int(p["vi_tri"]) == n - 1:
			continue
		them += float(p["gop"]) * TriNho.hieu_luc(String(p["chu"]))
	return float(pt["st_goc"]) + them

# --- Hiện ra cho người chơi (mục 4.1) -------------------------------

## Từng dòng mô tả món đồ, theo đúng những chữ người chơi ĐÃ BIẾT.
##
## Đây là chỗ cơ chế xương sống sống hay chết. Không có bảng chỉ số bằng số
## cho món đồ chưa đọc được — chữ nào chưa biết thì dòng của nó là "???".
## Học thêm một chữ là mở khoá lại TOÀN BỘ kho đồ cũ.
##
## Trả về mảng {chu, doc_duoc, nhan, mo_ta}.
func dong_mo_ta(ten: Array) -> Array:
	var pt := phan_tich(ten)
	var ds: Array = []
	var n: int = ten.size()
	for p in pt["phan"]:
		var chu := String(p["chu"])
		var muc := TriNho.muc_thuan_thuc(chu)
		var la_tt: bool = int(p["vi_tri"]) == n - 1
		# Lạ và Phai đều không đọc được. Khác nhau ở chỗ Phai ôn một lượt là
		# về, còn Lạ thì phải đi ghép bộ thủ lại từ đầu.
		if not TriNho.doc_duoc(chu):
			ds.append({"chu": CHU_MO, "doc_duoc": false, "nhan": SO_MO, "mo_ta": ""})
			continue

		var tu := VocabDB.tu_cua(chu)
		var nhan := "%s %s" % [chu, String(tu.get("han_viet", "")).capitalize()]
		var mo_ta := ""
		if la_tt:
			mo_ta = "%s — %s" % [String(tu.get("nghia", "")), _mo_ta_moveset(chu)]
		else:
			mo_ta = _mo_ta_bo_nghia(p, tu)
		# Chữ đang MỜ thì cho thấy chỉ số nhưng nói rõ là đang yếu đi.
		if muc == TriNho.MUC_MO:
			mo_ta += "   (mờ — còn %d%%)" % int(round(TriNho.hieu_luc(chu) * 100.0))
		ds.append({"chu": chu, "doc_duoc": true, "nhan": nhan, "mo_ta": mo_ta})
	return ds

func _mo_ta_moveset(chu: String) -> String:
	var mv := VocabDB.moveset_cua(chu)
	if mv.is_empty():
		return "chưa có moveset"
	var don: Array[String] = []
	for m in mv:
		don.append(String(m["ten"]))
	return "moveset: " + ", ".join(don)

func _mo_ta_bo_nghia(p: Dictionary, tu: Dictionary) -> String:
	var phan: Array[String] = []
	var gop := float(p["gop"])
	if gop > 0.0:
		phan.append("+%.0f sát thương" % gop)
	var hanh := String(p["ngu_hanh"])
	if hanh != "":
		phan.append("hệ %s (%s), khắc %s" % [hanh, NguHanh.ten_cua(hanh), NguHanh.khac(hanh)])
	var bac := int(p["bac"])
	if bac > 1:
		phan.append("bậc chồng bộ %d — ×%.2f" % [bac, float(HS_BAC.get(bac, 1.0))])
	var lui := int(p.get("lui", 0))
	if lui > 0:
		phan.append("đứng cách trung tâm %d bậc — chỉ ăn %.0f%%"
			% [lui, float(p["trong_so"]) * 100.0])
	if phan.is_empty():
		phan.append(String(tu.get("nghia", "")))
	return "  ·  ".join(phan)

## Tên món đồ hiện ra màn hình: chữ chưa biết thay bằng □.
func ten_hien(ten: Array) -> String:
	var s := ""
	for chu in ten:
		s += String(chu) if TriNho.doc_duoc(String(chu)) else CHU_MO
	return s

## Dòng "còn N chữ chưa đọc được" dưới bảng chỉ số. Trả "" nếu đọc được hết.
func dong_con_lai(ten: Array) -> String:
	var la := 0
	for chu in ten:
		if not TriNho.doc_duoc(String(chu)):
			la += 1
	return "" if la == 0 else "còn %d chữ chưa đọc được" % la

# --- Chồng bộ thủ (mục 4.3) -----------------------------------------

## Chữ bậc trên của `chu` trong thang chồng bộ, "" nếu đã kịch bậc hoặc chữ
## này không nằm trong thang nào.
func bac_tren(chu: String) -> String:
	var goc := VocabDB.goc_thang_cua(chu)
	if goc == "":
		return ""
	var bac := VocabDB.bac_thang_cua(chu)
	for tu in VocabDB.tu_vung:
		if String(tu.get("thang_goc", "")) == goc and int(tu.get("thang_bac", 0)) == bac + 1:
			return String(tu["chu"])
	return ""

## Giá nâng bậc: cần bấy nhiêu bộ thủ CÙNG chữ gốc. Thuần thục cao thì rẻ hơn
## (mục 4.6) — đó là phần thưởng thật cho việc chịu ngồi thiền.
func gia_nang_bac(chu: String) -> int:
	var bac := VocabDB.bac_thang_cua(chu)
	var gia := 3 if bac <= 1 else 8
	var giam := TriNho.hieu_luc(chu)
	return maxi(1, int(round(float(gia) * (1.3 - 0.3 * giam))))

## Nâng một chữ trong tên lên bậc trên. Trả về tên MỚI, không sửa tên cũ —
## bên gọi tự quyết định có nhận hay không sau khi trừ nguyên liệu.
func nang_bac(ten: Array, vi_tri: int) -> Array:
	if vi_tri < 0 or vi_tri >= ten.size():
		return ten.duplicate()
	var tren := bac_tren(String(ten[vi_tri]))
	if tren == "":
		return ten.duplicate()
	var moi := ten.duplicate()
	moi[vi_tri] = tren
	return moi

# --- So sánh hai cách xếp (dạy trật tự từ) --------------------------

## Xếp lại thứ tự bổ nghĩa cho ra món khác. Hàm này để bàn khắc chữ hiện
## trước/sau khi đổi, cho người chơi THẤY trật tự từ làm thay đổi cái gì.
func doi_cho(ten: Array, a: int, b: int) -> Array:
	var moi := ten.duplicate()
	if a < 0 or b < 0 or a >= moi.size() or b >= moi.size():
		return moi
	# Trung tâm không bao giờ đổi chỗ — nó quyết định moveset (mục 4.2).
	var tt := moi.size() - 1
	if a == tt or b == tt:
		return moi
	var tam = moi[a]
	moi[a] = moi[b]
	moi[b] = tam
	return moi

## Mọi hoán vị của phần bổ nghĩa, để bàn khắc chữ liệt kê "xếp kiểu nào".
## Giới hạn 6 chữ bổ nghĩa (720 hoán vị) — quá số đó là người chơi không đọc
## nổi danh sách, mà tên dài như thế cũng không còn là một câu nữa.
func moi_cach_xep(ten: Array) -> Array:
	var bo := bo_nghia(ten)
	if bo.size() > 6:
		return [ten.duplicate()]
	var tt = ten[ten.size() - 1]
	var ds: Array = []
	for hv in _hoan_vi(bo):
		var t: Array = hv.duplicate()
		t.append(tt)
		ds.append(t)
	return ds

func _hoan_vi(mang: Array) -> Array:
	if mang.size() <= 1:
		return [mang.duplicate()]
	var ds: Array = []
	for i in mang.size():
		var con := mang.duplicate()
		var lay = con.pop_at(i)
		for phu in _hoan_vi(con):
			var t: Array = [lay]
			t.append_array(phu)
			ds.append(t)
	return ds
