class_name CauHoi
extends RefCounted

## Sinh câu hỏi cho màn ngồi thiền ở bia đá (mục 4.6).
##
## Giữ trọn **mười dạng câu hỏi** và 41 câu ngữ pháp của bản 2D — đúng yêu cầu.
## Khác bản 2D ở đúng một chỗ: tách hẳn khỏi giao diện. Màn chiến đấu cũ trộn
## việc dựng câu hỏi với việc vẽ khung chữ và tính sát thương, nên không dùng
## lại được ở chỗ khác. Ở đây chỉ trả về dữ liệu; ai vẽ thì tự vẽ.
##
## Trả về dictionary:
##   kieu      mã dạng câu hỏi
##   de        đề bài
##   goi_y     dòng phụ dưới đề (pinyin, Hán Việt...) — có thể rỗng
##   lua_chon  mảng đáp án để bấm
##   dung      chỉ số của đáp án đúng trong lua_chon
##   chu       chữ mà câu này đang ôn — TriNho.on_tap() ăn chữ này
##
## Nguyên tắc: KHÔNG hardcode chữ nào. Mọi thứ tra từ VocabDB.

const MOI_KIEU := [
	"trung_viet", "viet_trung", "dung_sai", "dien_tu", "ghep_bo_thu",
	"sap_xep", "np_dien", "np_dung_sai", "dong_nghia", "trai_nghia",
]
const O_TRONG := "＿"
const SO_LUA_CHON := 4

## Sinh một câu hỏi về `chu`. Dạng nào cũng được, nhưng chỉ chọn trong những
## dạng mà chữ này có đủ dữ liệu — chữ không khai `trai_nghia` thì không hỏi
## dạng trái nghĩa được, và bản 2D từng dựng ra màn hình trắng vì chuyện đó.
##
## Tên là `sinh_cau` chứ không phải `sinh`: GDScript đã có sẵn hàm `sinh()`
## (sin hyperbol), và lời gọi không có tiền tố trong chính file này rơi vào
## hàm có sẵn ấy chứ không vào đây. Lỗi im lặng, mất buổi chiều mới tìm ra.
static func sinh_cau(chu: String, cac_kieu: Array = []) -> Dictionary:
	var tu := VocabDB.tu_cua(chu)
	if tu.is_empty():
		return {}
	var duoc: Array = []
	for k in (cac_kieu if not cac_kieu.is_empty() else MOI_KIEU):
		if _du_du_lieu(String(k), tu):
			duoc.append(k)
	if duoc.is_empty():
		return {}
	return _dung(String(duoc.pick_random()), tu)

## Sinh câu hỏi cho chữ đang sắp phai nhất. Rỗng nếu chưa học chữ nào.
static func sinh_theo_lich_on() -> Dictionary:
	var ds := TriNho.sap_phai(12)
	if ds.is_empty():
		# Chưa có chữ nào tới hạn thì ôn đại một chữ đã học — ngồi thiền phải
		# luôn ra được câu hỏi, không thì người chơi bấm vào thấy màn trống.
		var da_hoc := TriNho.so.keys()
		if da_hoc.is_empty():
			return {}
		return sinh_cau(String(da_hoc.pick_random()))
	return sinh_cau(String(ds[0]["chu"]))

static func _du_du_lieu(kieu: String, tu: Dictionary) -> bool:
	match kieu:
		"dong_nghia":
			return not (tu.get("dong_nghia", []) as Array).is_empty()
		"trai_nghia":
			return not (tu.get("trai_nghia", []) as Array).is_empty()
		"ghep_bo_thu":
			return (tu.get("bo_thu", []) as Array).size() >= 2
		"dien_tu", "sap_xep":
			return String(tu.get("vi_du", "")).length() >= 3
		"np_dien", "np_dung_sai":
			return not VocabDB.ngu_phap.is_empty()
		_:
			return true

static func _dung(kieu: String, tu: Dictionary) -> Dictionary:
	match kieu:
		"trung_viet": return _trung_viet(tu)
		"viet_trung": return _viet_trung(tu)
		"dung_sai": return _dung_sai(tu)
		"dien_tu": return _dien_tu(tu)
		"ghep_bo_thu": return _ghep_bo_thu(tu)
		"sap_xep": return _sap_xep(tu)
		"np_dien": return _np_dien(tu)
		"np_dung_sai": return _np_dung_sai(tu)
		"dong_nghia": return _lien_he(tu, "dong_nghia", "đồng nghĩa")
		"trai_nghia": return _lien_he(tu, "trai_nghia", "trái nghĩa")
	return {}

# --- Mười dạng ------------------------------------------------------

static func _trung_viet(tu: Dictionary) -> Dictionary:
	var dung := String(tu["nghia"])
	var ds := _nhieu_nghia_khac(tu, dung)
	return _bo_cau(tu, "trung_viet", String(tu["chu"]),
		"%s  ·  %s" % [String(tu["pinyin"]), String(tu["han_viet"])], ds, dung)

static func _viet_trung(tu: Dictionary) -> Dictionary:
	var dung := String(tu["chu"])
	var ds := _nhieu_chu_khac(tu, dung)
	return _bo_cau(tu, "viet_trung", String(tu["nghia"]), "chọn chữ đúng", ds, dung)

## Đúng/sai: ghép chữ với MỘT nghĩa, hỏi có khớp không. Nửa số câu ghép sai.
static func _dung_sai(tu: Dictionary) -> Dictionary:
	var that := randf() < 0.5
	var nghia := String(tu["nghia"])
	if not that:
		var khac := VocabDB.lay_ngau_nhien()
		var dem := 0
		while String(khac.get("nghia", "")) == nghia and dem < 12:
			khac = VocabDB.lay_ngau_nhien()
			dem += 1
		nghia = String(khac.get("nghia", nghia))
	return _bo_cau(tu, "dung_sai", "%s  =  %s ?" % [String(tu["chu"]), nghia],
		String(tu["pinyin"]), ["Đúng", "Sai"], "Đúng" if that else "Sai")

## Điền chữ còn thiếu vào câu ví dụ.
static func _dien_tu(tu: Dictionary) -> Dictionary:
	var chu := String(tu["chu"])
	var cau := String(tu["vi_du"])
	if not cau.contains(chu):
		return _trung_viet(tu)
	return _bo_cau(tu, "dien_tu", cau.replace(chu, O_TRONG),
		String(tu.get("vi_du_nghia", "")), _nhieu_chu_khac(tu, chu), chu)

## Chữ này ghép từ những bộ thủ nào.
static func _ghep_bo_thu(tu: Dictionary) -> Dictionary:
	var bt: Array = tu.get("bo_thu", [])
	var dung := " + ".join(bt)
	var ds: Array = [dung]
	var dem := 0
	while ds.size() < SO_LUA_CHON and dem < 40:
		dem += 1
		var khac := VocabDB.lay_ngau_nhien()
		var b: Array = khac.get("bo_thu", [])
		if b.size() < 2:
			continue
		var s := " + ".join(b)
		if not ds.has(s):
			ds.append(s)
	ds.shuffle()
	return _bo_cau(tu, "ghep_bo_thu", "%s ghép từ những bộ nào?" % String(tu["chu"]),
		String(tu["han_viet"]), ds, dung)

## Xếp lại trật tự câu — dạng dạy NGỮ PHÁP nặng nhất trong mười dạng, vì nó
## bắt người chơi nghĩ về thứ tự từ. Cùng một bài học với mục 4.2.
static func _sap_xep(tu: Dictionary) -> Dictionary:
	var cau := String(tu["vi_du"]).strip_edges()
	var dung := cau
	var ds: Array = [dung]
	# Ba cách xáo khác nhau làm ba đáp án sai.
	var chu_cai: Array = []
	for c in cau:
		chu_cai.append(c)
	var dem := 0
	while ds.size() < SO_LUA_CHON and dem < 30:
		dem += 1
		var x := chu_cai.duplicate()
		x.shuffle()
		var s := "".join(x)
		if not ds.has(s):
			ds.append(s)
	ds.shuffle()
	return _bo_cau(tu, "sap_xep", "Câu nào đúng trật tự?",
		String(tu.get("vi_du_nghia", "")), ds, dung)

# --- Hai dạng ngữ pháp, dùng 41 câu trong ngu_phap.csv ---------------

static func _np_dien(tu: Dictionary) -> Dictionary:
	var cau := VocabDB.lay_ngu_phap_ngau_nhien("dien")
	if cau.is_empty():
		cau = VocabDB.lay_ngu_phap_ngau_nhien()
	if cau.is_empty():
		return _trung_viet(tu)
	var dung := String(cau.get("dap_an", cau.get("dung", "")))
	var ds: Array = [dung]
	for s in cau.get("nhieu", []):
		if not ds.has(String(s)):
			ds.append(String(s))
	while ds.size() < 2:
		ds.append(String(VocabDB.lay_ngau_nhien().get("chu", "?")))
	ds.shuffle()
	var kq := _bo_cau(tu, "np_dien", String(cau.get("cau", "")),
		String(cau.get("nghia", "")), ds, dung)
	# Cột `diem` của ngu_phap.csv là LỜI GIẢI THÍCH, không phải số điểm. Đây
	# mới là chỗ dạy thật — trả lời xong mà không biết vì sao thì lần sau vẫn
	# sai. Giao diện phải hiện nó sau khi chọn.
	kq["giai_thich"] = String(cau.get("diem", ""))
	# Câu ngữ pháp ôn chính chữ trong đáp án, không phải chữ đưa vào.
	if VocabDB.co_chu(dung):
		kq["chu"] = dung
	return kq

static func _np_dung_sai(tu: Dictionary) -> Dictionary:
	var cau := VocabDB.lay_ngu_phap_ngau_nhien("dung_sai")
	if cau.is_empty():
		return _np_dien(tu)
	var dap := String(cau.get("dap_an", cau.get("dung", "")))
	var la_dung := dap in ["dung", "Đúng", "1", "true"]
	var kq := _bo_cau(tu, "np_dung_sai", String(cau.get("cau", "")),
		String(cau.get("nghia", "")), ["Đúng", "Sai"], "Đúng" if la_dung else "Sai")
	kq["giai_thich"] = String(cau.get("diem", ""))
	# Cột `sua` là câu đã sửa đúng — chỉ có ở câu SAI, và là thứ đáng đọc nhất.
	var sua := String(cau.get("sua", ""))
	if sua != "":
		kq["giai_thich"] = "%s   →  %s" % [String(kq["giai_thich"]), sua]
	return kq

# --- Đồng nghĩa / trái nghĩa ----------------------------------------

static func _lien_he(tu: Dictionary, cot: String, nhan: String) -> Dictionary:
	var ds_dung: Array = tu.get(cot, [])
	var dung := String(ds_dung.pick_random())
	var ds := _nhieu_chu_khac(tu, dung)
	return _bo_cau(tu, cot, "Chữ nào %s với %s ?" % [nhan, String(tu["chu"])],
		"%s — %s" % [String(tu["pinyin"]), String(tu["nghia"])], ds, dung)

# --- Dựng đáp án nhiễu ----------------------------------------------

static func _nhieu_nghia_khac(tu: Dictionary, dung: String) -> Array:
	var ds: Array = [dung]
	var dem := 0
	while ds.size() < SO_LUA_CHON and dem < 40:
		dem += 1
		# Lấy nhiễu CÙNG CHỦ ĐỀ để câu hỏi khó thật, không phải khó vì đáp án
		# sai lạc lõng. "cây / rừng / gỗ / lá" khó hơn "cây / bàn / chạy / đỏ".
		var k := VocabDB.lay_ngau_nhien(String(tu["chu_de"]))
		if k.is_empty():
			k = VocabDB.lay_ngau_nhien()
		var n := String(k.get("nghia", ""))
		if n != "" and not ds.has(n):
			ds.append(n)
	ds.shuffle()
	return ds

static func _nhieu_chu_khac(tu: Dictionary, dung: String) -> Array:
	var ds: Array = [dung]
	var dem := 0
	while ds.size() < SO_LUA_CHON and dem < 40:
		dem += 1
		var k := VocabDB.lay_ngau_nhien(String(tu["chu_de"]))
		if k.is_empty():
			k = VocabDB.lay_ngau_nhien()
		var c := String(k.get("chu", ""))
		if c != "" and not ds.has(c):
			ds.append(c)
	ds.shuffle()
	return ds

static func _bo_cau(tu: Dictionary, kieu: String, de: String, goi_y: String,
		lua_chon: Array, dung: String) -> Dictionary:
	return {
		"kieu": kieu, "de": de, "goi_y": goi_y,
		"lua_chon": lua_chon, "dung": lua_chon.find(dung),
		"chu": String(tu["chu"]), "giai_thich": "",
	}
