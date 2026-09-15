class_name ManBiaDa
extends ManChung

## Bia đá — bốn việc (mục 4.6 + mốc 6).
##
##   Ghép chữ     bộ thủ nhặt được → chữ. Ghép xong là BIẾT, và mọi món đồ cũ
##                trong túi sáng ra cùng lúc. Đây là cái lò rèn của game này.
##   Khắc chữ     lắp / tháo / đổi thứ tự / nâng bậc chồng bộ (mục 4.2 + 4.3).
##   Nâng chỉ số  tiêu hồn tăng 体韧力巧智心.
##   Du hành      đi sang vùng khác (mốc 6). Bảy vùng nối thành một chuỗi,
##                khai ở cột `mo_khi` của vung.csv.
##
## KHÔNG có thẻ hỏi-đáp. Từng có một thẻ "Ngồi thiền" bắn câu hỏi trắc nghiệm;
## chủ dự án bỏ đi vì ngồi trả lời hết câu này tới câu khác là quá mất thì giờ
## so với thứ nhận lại được. Việc học giờ nằm trọn trong hai thẻ CHẾ ĐỒ ở
## trên: ghép một chữ hay khắc một chữ lên vũ khí đều tính là ôn chữ đó
## (`TriNho.on_tap`), nên chữ được ôn bằng việc dùng nó chứ không bằng việc bị
## hỏi về nó. Bộ sinh câu hỏi `cau_hoi.gd` vẫn còn trong repo và vẫn có test
## canh, phòng khi cần lại — chỉ là không màn nào gọi tới nữa.
##
## Vì sao ba việc dồn vào một màn thay vì ba chỗ khác nhau: nghỉ ở bia là lúc
## DUY NHẤT người chơi được dừng lại nghĩ. Bắt họ chạy sang chỗ khác để đổi thứ
## tự chữ là bắt họ bỏ luôn việc đó.
##
## Màn này KHÔNG dạy chữ bằng cách chặn đường. Đóng nó lại và đi đánh tiếp thì
## game vẫn chạy bình thường — chỉ là món đồ trong túi vẫn còn đầy □.

const TEN_THE := ["Ghép chữ", "Khắc chữ", "Nâng chỉ số", "Du hành"]
## Hiện nhiều nhất bấy nhiêu chữ "sắp ghép được" — đủ để biết đang thiếu gì,
## không nhiều tới mức thành bảng tra cứu.
const SAP_GHEP_TOI_DA := 12
## Lưới chữ để khắc: nhiều hơn số này thì cuộn mỏi tay, mà chọn chữ để khắc là
## việc nên nghĩ chứ không nên lướt.
const CHU_KHAC_TOI_DA := 120

var _ten_bia := "Bia đá"
var _the := 0
var _noi_dung: VBoxContainer = null
var _hang_the: HBoxContainer = null

# Khắc chữ
var _mon: MonDo = null
var _vi_tri := -1

func dung_noi_dung(cha: MarginContainer) -> void:
	add_to_group("man_bia_da")

	var doc := VBoxContainer.new()
	doc.add_theme_constant_override("separation", 12)
	cha.add_child(doc)

	_hang_the = HBoxContainer.new()
	_hang_the.add_theme_constant_override("separation", 8)
	doc.add_child(_hang_the)
	for i in TEN_THE.size():
		var b := nut(String(TEN_THE[i]), _doi_the.bind(i))
		_hang_the.add_child(b)

	var vien := khung_vien()
	vien.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doc.add_child(vien)

	_noi_dung = VBoxContainer.new()
	_noi_dung.add_theme_constant_override("separation", 8)
	var s := cuon(_noi_dung)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vien.add_child(s)

## Bia đá mở màn này bằng hàm này, không gọi mo() thẳng — mỗi lần ngồi xuống
## là một câu hỏi mới, không phải câu còn dở của lần trước.
func mo_o_bia(ten_bia: String) -> void:
	_ten_bia = ten_bia
	mo()

func lam_moi() -> void:
	dat_tieu_de("%s  —  %s" % [_ten_bia, String(TEN_THE[_the])])
	for i in _hang_the.get_child_count():
		var b := _hang_the.get_child(i) as Button
		if b != null:
			b.text = ("▸ " if i == _the else "   ") + String(TEN_THE[i])
	_ve_the()

func _doi_the(i: int) -> void:
	_the = i
	lam_moi()

func _ve_the() -> void:
	ve_xong = false
	don(_noi_dung)
	match _the:
		0: _ve_ghep_chu()
		1: _ve_khac_chu()
		2: _ve_nang_chi_so()
		3: _ve_du_hanh()
	ve_xong = true

# --- Thẻ 1: ghép chữ ------------------------------------------------

func _ve_ghep_chu() -> void:
	_noi_dung.add_child(chu("Bộ thủ nhặt được", 20, MAU_NHAN))
	if Tui.bo_thu.is_empty():
		_noi_dung.add_child(chu("Chưa có mảnh nào. Đánh quái là rơi.", 16, MAU_CHU_MO))
	else:
		var ds := Tui.bo_thu.keys()
		ds.sort()
		var dong := ""
		for bt in ds:
			dong += "%s ×%d    " % [String(bt), Tui.so_bo_thu(String(bt))]
		_noi_dung.add_child(chu(dong, 20))

	_noi_dung.add_child(HSeparator.new())

	var duoc := Tui.chu_ghep_duoc()
	_noi_dung.add_child(chu("Ghép được ngay  (%d)" % duoc.size(), 20, MAU_NHAN))
	if duoc.is_empty():
		_noi_dung.add_child(chu("Chưa đủ mảnh cho chữ nào.", 16, MAU_CHU_MO))
	for c in duoc:
		var ten_chu := String(c)
		var tu := VocabDB.tu_cua(ten_chu)
		var b := nut("%s   %s — %s      (%s)" % [ten_chu,
			String(tu.get("han_viet", "")).capitalize(), String(tu.get("nghia", "")),
			" + ".join(Tui.bo_thu_can(ten_chu))], _ghep.bind(ten_chu))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_noi_dung.add_child(b)

	_noi_dung.add_child(HSeparator.new())
	_ve_sap_ghep()

## "Sắp ghép được" là thứ giữ người chơi đi đánh tiếp: thấy còn thiếu đúng một
## mảnh 口 thì biết mình đang đi đâu, thay vì nhặt mù.
func _ve_sap_ghep() -> void:
	var ds: Array = []
	for tu in VocabDB.tu_vung:
		var c := String(tu["chu"])
		if TriNho.doc_duoc(c):
			continue
		var thieu := Tui.thieu_bo_thu(c)
		if thieu.is_empty():
			continue
		var co_mot_phan := false
		for bt in Tui.bo_thu_can(c):
			if Tui.so_bo_thu(String(bt)) > 0:
				co_mot_phan = true
				break
		if not co_mot_phan:
			continue
		var con := 0
		for k in thieu:
			con += int(thieu[k])
		ds.append({"chu": c, "con": con, "thieu": thieu})
	ds.sort_custom(func(a, b): return int(a["con"]) < int(b["con"]))

	_noi_dung.add_child(chu("Sắp ghép được", 20, MAU_NHAN))
	if ds.is_empty():
		_noi_dung.add_child(chu("(chưa có mảnh nào khớp chữ nào)", 16, MAU_CHU_MO))
		return
	for m in ds.slice(0, SAP_GHEP_TOI_DA):
		var thieu: Dictionary = m["thieu"]
		var phan: Array[String] = []
		for k in thieu:
			phan.append("%s ×%d" % [String(k), int(thieu[k])])
		_noi_dung.add_child(chu("%s   còn thiếu  %s"
			% [String(m["chu"]), ", ".join(phan)], 16, MAU_CHU_MO))

func _ghep(c: String) -> void:
	if Tui.ghep(c):
		var tu := VocabDB.tu_cua(c)
		_bao("Ghép được %s (%s) — %s" % [c,
			String(tu.get("han_viet", "")), String(tu.get("nghia", ""))])
	lam_moi()

# --- Thẻ 2: khắc chữ ------------------------------------------------

func _ve_khac_chu() -> void:
	if not Tui.kho.has(_mon):
		_mon = null
		_vi_tri = -1

	_noi_dung.add_child(chu("Hồn: %d" % Tui.hon, 18, MAU_NHAN))
	if Tui.kho.is_empty():
		_noi_dung.add_child(chu("Túi rỗng — chưa có gì để khắc.", 16, MAU_CHU_MO))
		return

	_noi_dung.add_child(chu("Chọn món", 20, MAU_NHAN))
	var luoi := HFlowContainer.new()
	luoi.add_theme_constant_override("h_separation", 6)
	_noi_dung.add_child(luoi)
	for m in Tui.kho:
		var b := nut(("▸ " if m == _mon else "") + m.ten_hien(), _chon_mon.bind(m))
		b.add_theme_color_override("font_color", m.mau())
		luoi.add_child(b)

	if _mon == null:
		return

	_noi_dung.add_child(HSeparator.new())
	_ve_tung_chu()
	_ve_viec_voi_chu()
	_noi_dung.add_child(HSeparator.new())
	_ve_chu_khac_duoc()

## Tên món đồ bày ra từng chữ một, bấm vào chữ nào là chọn chữ đó. Chữ cuối
## đánh dấu là trung tâm — người chơi phải THẤY được cái luật "trung tâm đứng
## cuối", không phải đọc nó ở đâu đó.
func _ve_tung_chu() -> void:
	var pt := _mon.phan_tich()
	_noi_dung.add_child(chu("%s   ·   %s" % [_mon.ten_hien(),
		DoHiem.ten(_mon.do_hiem())], 26, _mon.mau()))

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 6)
	_noi_dung.add_child(hang)
	var n: int = _mon.ten.size()
	for i in n:
		var c := String(_mon.ten[i])
		var hien := c if TriNho.doc_duoc(c) else TenDoVat.CHU_MO
		var b := nut(("▸ " if i == _vi_tri else "") + hien, _chon_vi_tri.bind(i))
		b.add_theme_font_size_override("font_size", 26)
		hang.add_child(b)
		if i == n - 1:
			hang.add_child(chu("(trung tâm)", 14, MAU_CHU_MO))

	if _mon.doc_het():
		_noi_dung.add_child(chu("Sát thương %.0f  ·  tải %.1f"
			% [_mon.sat_thuong(), _mon.nang()], 18))
	else:
		_noi_dung.add_child(chu("Sát thương %s  —  %s"
			% [TenDoVat.SO_MO, TenDoVat.dong_con_lai(_mon.ten)], 18, MAU_CHU_MO))
	var h := String(pt["ngu_hanh"])
	if h != "":
		_noi_dung.add_child(chu("Hệ %s (%s)" % [h, NguHanh.ten_cua(h)], 16,
			NguHanh.mau_cua(h)))

func _ve_viec_voi_chu() -> void:
	if _vi_tri < 0 or _vi_tri >= _mon.ten.size():
		_noi_dung.add_child(chu("Bấm vào một chữ để đổi chỗ, gỡ ra, hay nâng bậc.",
			15, MAU_CHU_MO))
		return

	var c := String(_mon.ten[_vi_tri])
	var la_trung_tam := _vi_tri == _mon.ten.size() - 1
	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 8)
	_noi_dung.add_child(hang)

	# Đổi chỗ: chữ càng gần trung tâm càng bổ nghĩa chặt ⇒ góp càng nhiều. Đổi
	# chỗ là MIỄN PHÍ, vì đây chính là bài học của mục 4.2.
	hang.add_child(nut("◀ dịch trái", _doi_cho.bind(_vi_tri, _vi_tri - 1),
		not la_trung_tam and _vi_tri > 0))
	hang.add_child(nut("dịch phải ▶", _doi_cho.bind(_vi_tri, _vi_tri + 1),
		not la_trung_tam and _vi_tri < _mon.ten.size() - 2))
	hang.add_child(nut("Gỡ ra", _go_chu.bind(_vi_tri), not la_trung_tam))

	# Nâng bậc chồng bộ: 木 → 林 → 森 (mục 4.3).
	var tren := TenDoVat.bac_tren(c)
	if tren == "":
		return
	var goc := VocabDB.goc_thang_cua(c)
	var gia := TenDoVat.gia_nang_bac(c)
	var du_manh := Tui.so_bo_thu(goc) >= gia
	var doc_duoc_tren := TriNho.doc_duoc(tren)
	hang.add_child(nut("%s → %s   (%d %s)" % [c, tren if doc_duoc_tren else TenDoVat.CHU_MO,
		gia, goc], _nang_bac.bind(_vi_tri), du_manh and doc_duoc_tren))
	var vi_sao := ""
	if not doc_duoc_tren:
		vi_sao = "Chưa đọc được chữ bậc trên — ghép nó ra trước đã."
	elif not du_manh:
		vi_sao = "Đang có %d %s, cần %d." % [Tui.so_bo_thu(goc), goc, gia]
	if vi_sao != "":
		_noi_dung.add_child(chu(vi_sao, 15, MAU_CHU_MO))
	else:
		_noi_dung.add_child(chu("Thuần thục cao thì nâng bậc rẻ hơn — %s đang %s."
			% [c, TriNho.ten_muc(c)], 15, MAU_CHU_MO))

## Lưới chữ khắc thêm được. Chỉ chữ ĐÃ ĐỌC ĐƯỢC — khắc chữ là viết, mà không ai
## viết được cái chữ mình chưa thấy mặt bao giờ.
func _ve_chu_khac_duoc() -> void:
	var ds: Array = []
	for c in TriNho.so.keys():
		var s := String(c)
		if not TriNho.doc_duoc(s) or _mon.ten.has(s):
			continue
		ds.append({"chu": s, "gia": TenDoVat.gia_khac(_mon.ten, s)})
	ds.sort_custom(func(a, b): return int(a["gia"]) < int(b["gia"]))

	_noi_dung.add_child(chu("Khắc thêm chữ  (%d chữ đọc được)" % ds.size(),
		20, MAU_NHAN))
	if ds.is_empty():
		_noi_dung.add_child(chu("Chưa đọc được chữ nào chưa có trên món này.",
			16, MAU_CHU_MO))
		return

	var luoi := HFlowContainer.new()
	luoi.add_theme_constant_override("h_separation", 6)
	_noi_dung.add_child(luoi)
	for m in ds.slice(0, CHU_KHAC_TOI_DA):
		var c := String(m["chu"])
		var gia := int(m["gia"])
		var b := nut("%s  %d" % [c, gia], _khac_them.bind(c), Tui.hon >= gia)
		b.tooltip_text = "%s — %s" % [String(VocabDB.tu_cua(c).get("han_viet", "")),
			String(VocabDB.tu_cua(c).get("nghia", ""))]
		luoi.add_child(b)
	if ds.size() > CHU_KHAC_TOI_DA:
		_noi_dung.add_child(chu("… và %d chữ nữa, rẻ nhất xếp trước."
			% (ds.size() - CHU_KHAC_TOI_DA), 15, MAU_CHU_MO))

func _chon_mon(m: MonDo) -> void:
	_mon = m
	_vi_tri = -1
	lam_moi()

func _chon_vi_tri(i: int) -> void:
	_vi_tri = -1 if _vi_tri == i else i
	lam_moi()

func _doi_cho(a: int, b: int) -> void:
	if Tui.doi_cho_chu(_mon, a, b):
		_vi_tri = b
	lam_moi()

func _go_chu(i: int) -> void:
	if Tui.go_chu(_mon, i):
		_vi_tri = -1
	lam_moi()

func _nang_bac(i: int) -> void:
	if Tui.nang_bac_chu(_mon, i):
		_bao("Nâng bậc: %s" % _mon.ten_hien())
	lam_moi()

func _khac_them(c: String) -> void:
	if Tui.khac_them(_mon, c):
		_bao("Khắc %s — %s" % [c, _mon.ten_hien()])
	lam_moi()

# --- Thẻ 3: nâng chỉ số ---------------------------------------------

func _ve_nang_chi_so() -> void:
	var gia := Tui.gia_nang_chi_so()
	_noi_dung.add_child(chu("Hồn: %d      Giá một điểm: %d" % [Tui.hon, gia],
		20, MAU_NHAN))
	_noi_dung.add_child(chu("Giá tính theo TỔNG mọi chỉ số — dồn hết vào một "
		+ "chỉ số cũng đắt như rải đều.", 15, MAU_CHU_MO))
	_noi_dung.add_child(HSeparator.new())

	for c in Tui.CHI_SO:
		var hang := HBoxContainer.new()
		hang.add_theme_constant_override("separation", 10)
		_noi_dung.add_child(hang)
		var nhan := chu("%s  %d" % [c, Tui.cs(c)], 22)
		nhan.custom_minimum_size.x = 90
		hang.add_child(nhan)
		hang.add_child(nut("+1", _nang.bind(c), Tui.hon >= gia))
		var mo_ta := chu(String(Tui.TEN_CHI_SO[c]), 15, MAU_CHU_MO)
		mo_ta.custom_minimum_size.x = 220
		hang.add_child(mo_ta)
		hang.add_child(chu(_doi_thanh_gi(c), 15, MAU_NHAN))

	_noi_dung.add_child(HSeparator.new())
	_noi_dung.add_child(chu("Máu %.0f  ·  thể lực %.0f  ·  sức chứa %.1f  ·  MP %.0f"
		% [Tui.mau_toi_da(), Tui.the_luc_toi_da(),
			SoulsLike.suc_chua(Tui.cs("韧")), Tui.mp_toi_da()], 16))

## Nâng một điểm thì được gì — nói bằng con số thật, không nói "tăng sức mạnh".
func _doi_thanh_gi(c: String) -> String:
	match c:
		"体": return "+%.0f máu" % Tui.MAU_MOI_THE
		"韧": return "+%.1f thể lực, +%.1f sức chứa" % [
			SoulsLike.THE_LUC_MOI_NHAN, SoulsLike.SUC_CHUA_MOI_NHAN]
		"心": return "+%.0f MP" % Tui.MP_MOI_TAM
		_: return "sát thương theo thiên can của đòn"

func _nang(c: String) -> void:
	if Tui.nang_chi_so(c):
		_bao("%s lên %d" % [c, Tui.cs(c)])
	lam_moi()

# --- Tiện tay -------------------------------------------------------

func _bao(dong: String) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("bao"):
		h.call("bao", dong)

# --- Thẻ 4: du hành -------------------------------------------------

func _ve_du_hanh() -> void:
	_noi_dung.add_child(chu("Đi tới vùng khác", 20, MAU_NHAN))
	_noi_dung.add_child(chu(
		"Vùng mở dần theo chuỗi — tới được vùng này thì vùng sau hiện ra.",
		15, MAU_CHU_MO))
	_noi_dung.add_child(HSeparator.new())

	for v in DuHanh.danh_sach():
		var ma := String(v["ma"])
		var ten := String(v["ten"])
		# Tên chữ Hán của vùng cũng theo luật ???: chữ chưa đọc được hiện □.
		# Đi tới nơi rồi học chữ ở đó thì tên vùng sáng ra — cùng một cơ chế
		# với tên món đồ, đặt lên bản đồ.
		var tc := ""
		for c in String(v["ten_chu"]):
			tc += c if TriNho.doc_duoc(c) else TenDoVat.CHU_MO
		var nhan := "%s   %s" % [tc, ten]
		if bool(v["dang_o"]):
			_noi_dung.add_child(chu("▸ " + nhan + "   (đang ở đây)", 18,
				Color(0.85, 0.80, 0.55)))
			continue
		if not bool(v["mo"]):
			_noi_dung.add_child(chu("   " + TenDoVat.CHU_MO + TenDoVat.CHU_MO
				+ "   — chưa tới được", 17, MAU_CHU_MO))
			continue
		_noi_dung.add_child(nut(nhan, _di_toi.bind(ma)))

func _di_toi(ma: String) -> void:
	if DuHanh.di_toi(ma):
		dong()
