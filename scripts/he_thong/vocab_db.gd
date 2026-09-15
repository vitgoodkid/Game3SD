extends Node

## Kho dữ liệu. Đây là autoload — luôn tồn tại, gọi từ bất cứ đâu bằng "VocabDB".
## Nguyên tắc bất di bất dịch: KHÔNG hardcode từ vựng hay câu ngữ pháp trong code.
## Muốn thêm thì sửa CSV, không đụng vào file .gd nào cả.
##
## Port từ bản 2D, giữ NGUYÊN mọi hàm cũ để code quen tay đọc được ngay.
## Bản 3D thêm hai thứ:
##   1. Chỉ mục dictionary. Bản 2D quét tuyến tính cả mảng cho mỗi lần tra —
##      chấp nhận được khi mỗi lượt hỏi một câu, nhưng ở đây tra chữ chạy
##      trong vòng lặp vẽ HUD 60 lần/giây với hàng chục món đồ. O(n) là chết.
##   2. Bốn bảng mới: moveset, quái, boss, vùng.

const DUONG_DAN_TU := "res://data/tu_vung.csv"
const DUONG_DAN_NGU_PHAP := "res://data/ngu_phap.csv"
const DUONG_DAN_KY_NANG := "res://data/ky_nang.csv"
const DUONG_DAN_KHU_VUC := "res://data/khu_vuc.csv"
const DUONG_DAN_NGUYEN_LIEU := "res://data/nguyen_lieu.csv"
const DUONG_DAN_TRANG_BI := "res://data/trang_bi.csv"
const DUONG_DAN_MOVESET := "res://data/moveset.csv"
const DUONG_DAN_QUAI := "res://data/quai.csv"
const DUONG_DAN_BOSS := "res://data/boss.csv"
const DUONG_DAN_NPC := "res://data/npc.csv"
const DUONG_DAN_VUNG := "res://data/vung.csv"
const DUONG_DAN_DON_QUAI := "res://data/don_quai.csv"

## Từ vựng: cột chứa nhiều giá trị ngăn nhau bằng "|", và cột là số.
const COT_NHIEU_TU := ["nghia_khac", "bo_thu", "nhieu", "dong_nghia", "trai_nghia"]
## so_net / thang_bac / tan_suat để RỖNG được (xem tools/sinh_du_lieu.py) nên
## không đưa vào đây — _so() tự đọc, rỗng cho 0.
const COT_SO_TU := ["thanh", "cap"]
const COT_NHIEU_NP := ["nhieu"]
const COT_SO_NP := ["cap"]
const COT_SO_KN := ["gia_tri", "so_luot"]
const COT_SO_KV := ["cap", "x", "y", "rong", "cao", "so_quai", "boss"]
const COT_SO_NL := ["cong"]
const COT_NHIEU_TB := ["thanh_phan"]
const COT_SO_TB := ["gia_tri"]
const COT_SO_MV := ["sieu_giap", "t_vung", "t_dam_tu", "t_dam_den", "t_hoi", "the_luc",
	"he_so", "pha_the", "huy_duoc", "tam_voi", "goc_quet"]
const COT_NHIEU_QUAI := ["moveset", "rot_bo_thu"]
const COT_SO_QUAI := ["mau", "giap", "the_dung", "cao", "ban_kinh",
	"toc_do_di", "toc_do_duoi", "tam_phat_hien", "tam_danh", "hon"]
const COT_NHIEU_BOSS := ["moveset_1", "moveset_2", "thuong_chu"]
const COT_SO_BOSS := ["mau", "giap", "the_dung", "cao", "ban_kinh", "toc_do",
	"nguong_gd2", "thuong_hon"]
const COT_NHIEU_VUNG := ["chu_de"]
const COT_SO_VUNG := ["cap", "hat_giong", "cao_do", "do_go_ghe", "mat_do_cay",
	"mat_do_da", "dam_suong", "goc_mat_troi", "cuong_do_troi", "bi_xoa"]
const COT_SO_DQ := ["t_vung", "t_dam_tu", "t_dam_den", "t_hoi", "sat_thuong",
	"pha_the", "tam_voi", "goc_quet", "lao_toi"]

var tu_vung: Array[Dictionary] = []
var ngu_phap: Array[Dictionary] = []
var ky_nang: Array[Dictionary] = []
var khu_vuc: Array[Dictionary] = []
var nguyen_lieu: Array[Dictionary] = []
var trang_bi: Array[Dictionary] = []
var moveset: Array[Dictionary] = []
var quai: Array[Dictionary] = []
var boss: Array[Dictionary] = []
## NPC và thoại cốt truyện (mốc 7).
var npc: Array[Dictionary] = []
var vung: Array[Dictionary] = []
var don_quai: Array[Dictionary] = []

# --- Chỉ mục (dựng một lần lúc nạp) ---------------------------------
var _tu_theo_chu := {}
var _nl_theo_chu := {}
var _tb_theo_chu := {}
var _kn_theo_chu := {}
var _mv_theo_chu := {}
var _quai_theo_ma := {}
var _boss_theo_ma := {}
var _npc_theo_ma := {}
var _vung_theo_ma := {}
var _dq_theo_ma := {}
## Chữ nào là bậc mấy của thang nào — cho TenDoVat.bac_tren() khỏi phải quét.
var _thang := {}

func _ready() -> void:
	tu_vung = _doc_csv(DUONG_DAN_TU, COT_NHIEU_TU, COT_SO_TU)
	ngu_phap = _doc_csv(DUONG_DAN_NGU_PHAP, COT_NHIEU_NP, COT_SO_NP)
	ky_nang = _doc_csv(DUONG_DAN_KY_NANG, [], COT_SO_KN)
	khu_vuc = _doc_csv(DUONG_DAN_KHU_VUC, [], COT_SO_KV)
	nguyen_lieu = _doc_csv(DUONG_DAN_NGUYEN_LIEU, [], COT_SO_NL)
	trang_bi = _doc_csv(DUONG_DAN_TRANG_BI, COT_NHIEU_TB, COT_SO_TB)
	moveset = _doc_csv(DUONG_DAN_MOVESET, [], COT_SO_MV)
	quai = _doc_csv(DUONG_DAN_QUAI, COT_NHIEU_QUAI, COT_SO_QUAI)
	boss = _doc_csv(DUONG_DAN_BOSS, COT_NHIEU_BOSS, COT_SO_BOSS)
	# Thoại tách bằng "|" — mỗi NPC nhiều câu, mỗi câu hiện một lượt.
	npc = _doc_csv(DUONG_DAN_NPC, ["thoai", "thoai_nghia", "chu_tang"],
		["x", "z", "hon_tang"])
	vung = _doc_csv(DUONG_DAN_VUNG, COT_NHIEU_VUNG, COT_SO_VUNG)
	don_quai = _doc_csv(DUONG_DAN_DON_QUAI, [], COT_SO_DQ)
	_dung_chi_muc()

func _dung_chi_muc() -> void:
	for t in tu_vung:
		_tu_theo_chu[t["chu"]] = t
		var goc := String(t.get("thang_goc", ""))
		if goc != "":
			if not _thang.has(goc):
				_thang[goc] = {}
			_thang[goc][_so(t, "thang_bac")] = String(t["chu"])
	for n in nguyen_lieu:
		_nl_theo_chu[n["chu"]] = n
	for t in trang_bi:
		_tb_theo_chu[t["chu"]] = t
	for k in ky_nang:
		_kn_theo_chu[k["chu"]] = k
	for m in moveset:
		var c: String = m["chu"]
		if not _mv_theo_chu.has(c):
			_mv_theo_chu[c] = []
		_mv_theo_chu[c].append(m)
	for q in quai:
		_quai_theo_ma[q["ma"]] = q
	for b in boss:
		_boss_theo_ma[b["ma"]] = b
	for n in npc:
		_npc_theo_ma[n["ma"]] = n
	for v in vung:
		_vung_theo_ma[v["ma"]] = v
	for dq in don_quai:
		_dq_theo_ma[dq["don"]] = dq

## Đọc một file CSV thành danh sách dictionary, lấy dòng đầu làm tên cột.
func _doc_csv(duong_dan: String, cot_nhieu: Array, cot_so: Array) -> Array[Dictionary]:
	var ket_qua: Array[Dictionary] = []

	var f := FileAccess.open(duong_dan, FileAccess.READ)
	if f == null:
		push_error("KHONG MO DUOC FILE %s — ma loi %d" % [duong_dan, FileAccess.get_open_error()])
		return ket_qua

	var tieu_de := f.get_csv_line()

	while not f.eof_reached():
		var dong := f.get_csv_line()
		if dong.size() < tieu_de.size():
			continue
		# Dòng THỪA cột = ô nào đó có dấu phẩy mà quên bọc nháy kép. Bản 2D
		# từng âm thầm nuốt mất phần đuôi của 13/19 mô tả phép vì chuyện này.
		if dong.size() > tieu_de.size():
			push_warning('%s: dong "%s" thua %d cot — o co dau phay phai boc nhay kep'
				% [duong_dan, dong[0], dong.size() - tieu_de.size()])

		var muc := {}
		for i in tieu_de.size():
			muc[tieu_de[i]] = dong[i]

		for cot in cot_nhieu:
			muc[cot] = _tach(String(muc.get(cot, "")))
		for cot in cot_so:
			muc[cot] = _doi_so(String(muc.get(cot, "")))

		ket_qua.append(muc)

	f.close()
	return ket_qua

## Ô rỗng thành 0, ô có dấu chấm thành float, còn lại thành int. Bản 2D chỉ
## có int nên int() là đủ; bản 3D có t_dam_tu=0.18 nên phải phân biệt.
func _doi_so(s: String) -> Variant:
	var t := s.strip_edges()
	if t.is_empty():
		return 0
	if t.contains("."):
		return float(t)
	return int(t)

## Tách chuỗi "a|b|c" thành ["a","b","c"]. Chuỗi rỗng cho mảng rỗng, không phải [""].
func _tach(chuoi: String) -> Array:
	if chuoi.strip_edges().is_empty():
		return []
	return Array(chuoi.split("|"))

## Đọc một cột số có thể rỗng. Dùng cho so_net / thang_bac / tan_suat.
func _so(muc: Dictionary, cot: String) -> int:
	var v: Variant = muc.get(cot, "")
	if v is int:
		return v
	if v is float:
		return int(v)
	var s := String(v).strip_edges()
	return 0 if s.is_empty() else int(s)

# --- Truy vấn từ vựng -----------------------------------------------

## Cả dòng dữ liệu của một chữ. Dictionary rỗng nếu không có chữ đó.
func tu_cua(chu: String) -> Dictionary:
	return _tu_theo_chu.get(chu, {})

func co_chu(chu: String) -> bool:
	return _tu_theo_chu.has(chu)

## Lọc từ theo chủ đề và/hoặc cấp. Để trống / để 0 nghĩa là không lọc theo tiêu chí đó.
func loc(chu_de: String = "", cap: int = 0) -> Array[Dictionary]:
	var ket_qua: Array[Dictionary] = []
	for tu in tu_vung:
		if chu_de != "" and tu["chu_de"] != chu_de:
			continue
		if cap != 0 and tu["cap"] != cap:
			continue
		ket_qua.append(tu)
	return ket_qua

## Lấy đại một từ. Trả về dictionary rỗng nếu không có từ nào khớp.
func lay_ngau_nhien(chu_de: String = "", cap: int = 0) -> Dictionary:
	var danh_sach := loc(chu_de, cap)
	if danh_sach.is_empty():
		return {}
	return danh_sach.pick_random()

## Cấp nào của chủ đề này THẬT SỰ có từ để hỏi. Giữ nguyên từ bản 2D: khu vực
## khai cấp theo độ khó của khu, còn từ vựng nằm rải rác trong CSV nên có cặp
## chủ đề × cấp rỗng hoàn toàn. Hàm này bẻ cấp câu hỏi về chỗ có dữ liệu.
func cap_co_tu(chu_de: String, cap_muon: int) -> int:
	if not loc(chu_de, cap_muon).is_empty():
		return cap_muon
	var toi_da := 1
	for tu in tu_vung:
		toi_da = maxi(toi_da, int(tu["cap"]))
	for buoc in range(1, toi_da + 1):
		for c in [cap_muon - buoc, cap_muon + buoc]:
			if c >= 1 and c <= toi_da and not loc(chu_de, c).is_empty():
				return c
	return 0

## Độ khó của một chữ, 1 (dễ) đến 5 (khó). Ưu tiên bậc phổ biến thật; chữ chưa
## tra thì lùi về số nét, rồi tới cột `cap` — đó là lý do sinh_du_lieu.py để
## trống chứ không điền bừa. Xếp chữ nào dạy trước thì hỏi hàm này.
func do_kho_cua(chu: String) -> int:
	var t := tu_cua(chu)
	if t.is_empty():
		return 3
	var ts := _so(t, "tan_suat")
	if ts > 0:
		return ts
	var net := _so(t, "so_net")
	if net > 0:
		return clampi(1 + int(net / 5), 1, 5)
	return clampi(int(t.get("cap", 2)), 1, 5)

# --- Cột mới của bản 3D ---------------------------------------------

## Hành của một chữ ("" nếu chữ không thuộc vòng ngũ hành).
func ngu_hanh_cua(chu: String) -> String:
	return String(tu_cua(chu).get("ngu_hanh", ""))

## Bậc chồng bộ: 1 (木) / 2 (林) / 3 (森). 1 nếu chữ không nằm trong thang nào.
func bac_thang_cua(chu: String) -> int:
	var b := _so(tu_cua(chu), "thang_bac")
	return b if b > 0 else 1

## Chữ gốc của thang chứa chữ này ("" nếu không thuộc thang nào).
func goc_thang_cua(chu: String) -> String:
	return String(tu_cua(chu).get("thang_goc", ""))

## Chữ ở bậc `bac` của thang gốc `goc`. "" nếu thang đó không có bậc ấy —
## thang 水 nhảy thẳng từ bậc 1 lên bậc 3, không có bậc 2.
func chu_thang(goc: String, bac: int) -> String:
	return String(_thang.get(goc, {}).get(bac, ""))

## Cả thang của một chữ, từ bậc 1 lên bậc cao nhất. Dùng để bàn khắc chữ vẽ
## được "木 → 林 → 森" cho người chơi thấy mình đang ở đâu.
func ca_thang(chu: String) -> Array:
	var goc := goc_thang_cua(chu)
	if goc == "":
		return [chu]
	var ds: Array = []
	for b in range(1, 4):
		var c := chu_thang(goc, b)
		if c != "":
			ds.append(c)
	return ds

## Chữ này đứng ở tầng nào trong tên món đồ: trung_tam / bo_nghia / "".
func vi_tri_cua(chu: String) -> String:
	return String(nguyen_lieu_cua(chu).get("vi_tri", ""))

## Loại của một nguyên liệu nền: vukhi / giap / tieu_hao.
func loai_nguyen_lieu_cua(chu: String) -> String:
	return String(nguyen_lieu_cua(chu).get("loai", ""))

## Mọi nguyên liệu đứng ở một tầng của tên món đồ: trung_tam hoặc bo_nghia.
## Bộ sinh đồ rơi hỏi hàm này để khỏi biết chữ nào tồn tại (luật 1).
func nguyen_lieu_theo_vi_tri(vi_tri: String) -> Array:
	var ds: Array = []
	for n in nguyen_lieu:
		if String(n.get("vi_tri", "")) == vi_tri:
			ds.append(n)
	return ds

# --- Truy vấn ngữ pháp ----------------------------------------------

func loc_ngu_phap(kieu: String = "", cap: int = 0) -> Array[Dictionary]:
	var ket_qua: Array[Dictionary] = []
	for cau in ngu_phap:
		if kieu != "" and cau["kieu"] != kieu:
			continue
		if cap != 0 and cau["cap"] != cap:
			continue
		ket_qua.append(cau)
	return ket_qua

func lay_ngu_phap_ngau_nhien(kieu: String = "", cap: int = 0) -> Dictionary:
	var danh_sach := loc_ngu_phap(kieu, cap)
	if danh_sach.is_empty():
		return {}
	return danh_sach.pick_random()

# --- Nguyên liệu / trang bị / kỹ năng -------------------------------

## Nguyên liệu trung tâm của một LOẠI trang bị: vukhi / khien / giap / tieu_hao.
## Dùng để đặt đồ khởi đầu mà không phải viết chữ Hán nào vào code (luật 1).
func nguyen_lieu_theo_loai(loai: String) -> Array:
	var ds: Array = []
	for n in nguyen_lieu:
		if String(n.get("loai", "")) == loai 				and String(n.get("vi_tri", "")) == "trung_tam":
			ds.append(n)
	return ds

func nguyen_lieu_cua(chu: String) -> Dictionary:
	return _nl_theo_chu.get(chu, {})

## Khe của một nguyên liệu ở bàn ghép 4 ô: pho_tu / nguyen_to / vat_lieu / nen.
func khe_cua(chu: String) -> String:
	return String(nguyen_lieu_cua(chu).get("khe", ""))

## Điểm chỉ số một chữ góp vào món đồ. Với chữ trung tâm đây là chỉ số gốc.
##
## 38 nguyên liệu của bản 2D có cột `cong` chỉnh tay — giữ nguyên, đó là cân
## bằng đã chơi thử. Nhưng bản 3D cho khắc BẤT KỲ chữ nào đã học lên vũ khí
## (mục 4.6), mà 1011 chữ thì không thể ngồi gán tay từng cái.
##
## Chữ ngoài bảng lấy điểm theo ĐỘ KHÓ: chữ càng hiếm gặp càng góp nhiều. Đây
## không phải cách lấp chỗ trống cho xong — nó chính là mục 4.5 của bản yêu
## cầu ("độ hiếm = độ khó"): đuổi theo đồ xịn cũng chính là học chữ khó hơn.
func cong_cua(chu: String) -> int:
	var nl := nguyen_lieu_cua(chu)
	if not nl.is_empty():
		return int(nl.get("cong", 0))
	return do_kho_cua(chu)

func trang_bi_cua(chu: String) -> Dictionary:
	return _tb_theo_chu.get(chu, {})

func trang_bi_theo_loai(loai: String) -> Array[Dictionary]:
	var ds: Array[Dictionary] = []
	for tb in trang_bi:
		if tb["loai"] == loai:
			ds.append(tb)
	return ds

func ky_nang_cua(chu: String) -> Dictionary:
	return _kn_theo_chu.get(chu, {})

# --- Moveset / quái / boss / vùng -----------------------------------

## Mọi đòn của một loại vũ khí (tra bằng chữ trung tâm: 剑 刀 斧 弓 拳).
## Không có vũ khí nào khớp thì lùi về tay không (拳) — nhân vật luôn đánh được.
func moveset_cua(chu: String) -> Array:
	return _mv_theo_chu.get(chu, _mv_theo_chu.get("拳", []))

## Một đòn cụ thể: don là nhe_1 / nhe_2 / nhe_3 / nang / nang_nap / chay / nhay
## / phan_do (đòn phản sau khi đỡ trúng).
## Thiếu đòn đó thì lùi về nhe_1 — dữ liệu thiếu thì xấu, chứ không được đứng im.
func don_cua(chu: String, don: String) -> Dictionary:
	var ds := moveset_cua(chu)
	for m in ds:
		if m["don"] == don:
			return m
	for m in ds:
		if m["don"] == "nhe_1":
			return m
	return {}

## Chuỗi combo đòn nhẹ của một vũ khí: ["nhe_1", "nhe_2", "nhe_3"] — dài ngắn
## tuỳ vũ khí, cung chỉ có một nhát.
func combo_nhe(chu: String) -> Array:
	var ds: Array = []
	for m in moveset_cua(chu):
		if String(m["don"]).begins_with("nhe_"):
			ds.append(m["don"])
	ds.sort()
	return ds

func quai_cua(ma: String) -> Dictionary:
	return _quai_theo_ma.get(ma, {})

func quai_trong_vung(ma_vung: String) -> Array:
	var ds: Array = []
	for q in quai:
		if q["vung"] == ma_vung:
			ds.append(q)
	return ds

## NPC trong một vùng, theo cột `vung` của npc.csv.
func npc_trong_vung(ma_vung: String) -> Array:
	var ds: Array = []
	for n in npc:
		if String(n.get("vung", "")) == ma_vung:
			ds.append(n)
	return ds

func npc_cua(ma: String) -> Dictionary:
	return _npc_theo_ma.get(ma, {})

func boss_cua(ma: String) -> Dictionary:
	return _boss_theo_ma.get(ma, {})

func boss_trong_vung(ma_vung: String) -> Dictionary:
	for b in boss:
		if b["vung"] == ma_vung:
			return b
	return {}

func vung_cua(ma: String) -> Dictionary:
	return _vung_theo_ma.get(ma, {})

## Một đòn của quái (tra bằng tên đòn ở cột `moveset` của quai.csv / boss.csv).
## Thiếu thì lùi về "bo_cham" — đòn chậm nhất, dễ né nhất. Dữ liệu thiếu phải
## làm game DỄ đi, không được biến thành đòn bất khả né.
func don_quai_cua(don: String) -> Dictionary:
	return _dq_theo_ma.get(don, _dq_theo_ma.get("bo_cham", {}))
