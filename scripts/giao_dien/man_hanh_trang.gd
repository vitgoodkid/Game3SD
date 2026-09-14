extends ManChung

## Hành trang. Đây là chỗ cơ chế xương sống của mục 4.1 hiện ra mặt người chơi.
##
## Không có bảng chỉ số bằng số cho món đồ chưa đọc được. Món đồ hiện đúng tên
## chữ Hán của nó; chỉ số hiện ra theo đúng những chữ người chơi ĐÃ BIẾT, còn
## lại là "???".
##
## Hệ quả cố ý:
##   - Người chơi mù chữ vẫn chơi được, nhưng chơi mò. Mặc thử để đoán.
##   - Biết chữ = biết trước món đồ làm gì. Lợi thế thật, cảm nhận được ngay.
##   - Học thêm một chữ là mở khoá lại TOÀN BỘ kho đồ cũ.
##
## Nếu ai đó "sửa cho tiện" thành hiện luôn mọi chỉ số, cả thiết kế game chết
## tại file này. Đừng.

const KHE_HIEN := [
	{"khe": "vu_khi", "ten": "Vũ khí tay phải"},
	{"khe": "tay_trai", "ten": "Tay trái"},
	{"khe": "giap", "ten": "Giáp"},
	{"khe": "nhan", "ten": "Nhẫn / ngọc bội"},
]

var _ds_kho: VBoxContainer = null
var _ds_mac: VBoxContainer = null
var _chi_tiet: VBoxContainer = null
var _chon: MonDo = null

func dung_noi_dung(cha: MarginContainer) -> void:
	dat_tieu_de("Hành trang")

	var ngang := HBoxContainer.new()
	ngang.add_theme_constant_override("separation", 18)
	cha.add_child(ngang)

	# Cột trái: đang mặc + chỉ số
	var trai := VBoxContainer.new()
	trai.custom_minimum_size.x = 300
	trai.add_theme_constant_override("separation", 10)
	ngang.add_child(trai)
	trai.add_child(chu("Đang mặc", 20, MAU_NHAN))
	_ds_mac = VBoxContainer.new()
	trai.add_child(cuon(_ds_mac))

	# Cột giữa: kho
	var giua := VBoxContainer.new()
	giua.custom_minimum_size.x = 260
	giua.add_theme_constant_override("separation", 10)
	ngang.add_child(giua)
	giua.add_child(chu("Trong túi", 20, MAU_NHAN))
	_ds_kho = VBoxContainer.new()
	var s := cuon(_ds_kho)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	giua.add_child(s)

	# Cột phải: chi tiết món đang chọn
	var phai := khung_vien()
	phai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ngang.add_child(phai)
	_chi_tiet = VBoxContainer.new()
	_chi_tiet.add_theme_constant_override("separation", 8)
	phai.add_child(_chi_tiet)

func lam_moi() -> void:
	_ve_dang_mac()
	_ve_kho()
	_ve_chi_tiet()

# --- Cột trái -------------------------------------------------------

func _ve_dang_mac() -> void:
	don(_ds_mac)

	# Sáu chỉ số cũng là sáu chữ (mục 4.5) — người chơi học chúng từ giờ đầu
	# chỉ bằng cách mở màn này ra xem.
	for c in Tui.CHI_SO:
		var d := HBoxContainer.new()
		d.add_theme_constant_override("separation", 8)
		var nhan := chu("%s  %d" % [c, Tui.cs(c)], 19)
		nhan.custom_minimum_size.x = 76
		d.add_child(nhan)
		d.add_child(chu(String(Tui.TEN_CHI_SO[c]), 14, MAU_CHU_MO))
		_ds_mac.add_child(d)

	var tai := Tui.muc_tai()
	_ds_mac.add_child(chu("Tải: %s  —  %.1f / %.1f  (%s)"
		% [String(tai["ten"]), Tui.tong_nang(), SoulsLike.suc_chua(Tui.cs("韧")),
			_kieu_lan(String(tai["muc"]))], 15, MAU_CHU_MO))

	var ch := Tui.he_so_cong_huong()
	if ch > 1.0:
		_ds_mac.add_child(chu("Cộng hưởng ngũ hành: +%d%%  (%s)"
			% [int(round((ch - 1.0) * 100.0)), NguHanh.chuoi_tuong_sinh()],
			15, Color(0.55, 0.85, 0.60)))

	_ds_mac.add_child(HSeparator.new())

	for k in KHE_HIEN:
		var ten_khe := String(k["khe"])
		_ds_mac.add_child(chu(String(k["ten"]), 16, MAU_NHAN))
		var a: Array = Tui.mac[ten_khe]
		for i in a.size():
			var mon = a[i]
			var nhan := "—  (%s)" % _ten_o(ten_khe, i)
			if mon != null:
				nhan = mon.ten_hien()
				if ten_khe == "vu_khi" and i == Tui.tay_phai_dang:
					nhan = "▸ " + nhan
			var b := nut(nhan, _bam_khe.bind(ten_khe, i))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if mon != null:
				b.add_theme_color_override("font_color", mon.mau())
			_ds_mac.add_child(b)

func _ten_o(khe: String, i: int) -> String:
	if khe == "giap":
		return ["đầu", "thân", "tay", "chân"][i] if i < 4 else str(i + 1)
	return str(i + 1)

func _kieu_lan(muc: String) -> String:
	match muc:
		"nhe": return "lăn xa, nhiều i-frame"
		"vua": return "lăn thường"
		"nang": return "lăn ngắn"
		_: return "LẾT — không chạy được"

func _bam_khe(khe: String, o: int) -> void:
	var mon = Tui.mac[khe][o]
	if mon == null:
		return
	# Bấm vào ô vũ khí đang mặc thì chọn nó để xem; bấm lại thì tháo ra.
	if _chon == mon:
		Tui.thao(khe, o)
		_chon = null
	else:
		_chon = mon
	lam_moi()

# --- Cột giữa -------------------------------------------------------

func _ve_kho() -> void:
	don(_ds_kho)
	if Tui.kho.is_empty():
		_ds_kho.add_child(chu("(trống)", 16, MAU_CHU_MO))
		return
	for mon in Tui.kho:
		var nhan := mon.ten_hien()
		if Tui.dang_mac(mon):
			nhan = "• " + nhan
		elif not mon.da_mac_thu:
			# Chưa mặc thử lần nào thì đánh dấu — người chơi mù chữ dựa vào
			# dấu này để biết món nào còn chưa thử.
			nhan = "＋ " + nhan
		var b := nut(nhan, func(): _chon = mon; lam_moi())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", mon.mau())
		_ds_kho.add_child(b)

# --- Cột phải -------------------------------------------------------

func _ve_chi_tiet() -> void:
	don(_chi_tiet)
	if _chon == null or not Tui.kho.has(_chon):
		_chon = null
		_chi_tiet.add_child(chu("Chọn một món để xem.", 16, MAU_CHU_MO))
		return

	var mon := _chon
	var pt := mon.phan_tich()

	# Tên: chữ chưa đọc được hiện □.
	var ten := chu(mon.ten_hien(), 34, mon.mau())
	_chi_tiet.add_child(ten)

	var hang := chu("%s  ·  %s" % [DoHiem.ten(mon.do_hiem()),
		_ten_loai(String(pt["loai"]))], 15, MAU_CHU_MO)
	_chi_tiet.add_child(hang)
	_chi_tiet.add_child(HSeparator.new())

	# ĐÂY LÀ CHỖ QUAN TRỌNG NHẤT: từng chữ một dòng, chữ chưa biết thì ???
	for d in TenDoVat.dong_mo_ta(mon.ten):
		var dong := HBoxContainer.new()
		dong.add_theme_constant_override("separation", 12)
		var doc_duoc := bool(d["doc_duoc"])
		var nhan := chu(String(d["nhan"]), 19, MAU_CHU if doc_duoc else MAU_CHU_MO)
		nhan.custom_minimum_size.x = 150
		dong.add_child(nhan)
		dong.add_child(chu(String(d["mo_ta"]), 15,
			MAU_NHAN if doc_duoc else MAU_CHU_MO))
		_chi_tiet.add_child(dong)

	var con := TenDoVat.dong_con_lai(mon.ten)
	if con != "":
		_chi_tiet.add_child(chu(con + "  —  ghép chữ ở bia đá để đọc được",
			15, Color(0.85, 0.72, 0.38)))

	_chi_tiet.add_child(HSeparator.new())

	# Chỉ số TỔNG chỉ hiện khi đã đọc được HẾT tên. Đọc được một nửa mà vẫn
	# thấy tổng sát thương thì người chơi suy ngược ra được phần còn thiếu,
	# và cả cơ chế ??? thành vô nghĩa.
	if mon.doc_het():
		_chi_tiet.add_child(chu("Sát thương  %.0f" % mon.sat_thuong(), 20))
		_chi_tiet.add_child(chu("Tải trọng  %.1f" % mon.nang(), 16, MAU_NHAN))
		var h := mon.ngu_hanh()
		if h != "":
			_chi_tiet.add_child(chu("Hệ %s (%s)  —  khắc %s, bị %s khắc"
				% [h, NguHanh.ten_cua(h), NguHanh.khac(h), NguHanh.bi_khac_boi(h)],
				16, NguHanh.mau_cua(h)))
	else:
		_chi_tiet.add_child(chu("Sát thương  %s" % TenDoVat.SO_MO, 20, MAU_CHU_MO))
		_chi_tiet.add_child(chu("Mặc thử để đoán xem nó làm gì.", 15, MAU_CHU_MO))

	_chi_tiet.add_child(HSeparator.new())
	var nut_hang := HBoxContainer.new()
	nut_hang.add_theme_constant_override("separation", 8)
	_chi_tiet.add_child(nut_hang)

	if Tui.dang_mac(mon):
		nut_hang.add_child(nut("Tháo ra", func(): Tui.thao_het(mon); lam_moi()))
	else:
		var khe := _khe_cho(mon)
		nut_hang.add_child(nut("Mặc thử", func():
			Tui.mac_vao(mon, khe)
			lam_moi(), khe != ""))
	nut_hang.add_child(nut("Bỏ đi", func():
		Tui.bo(mon)
		_chon = null
		lam_moi()))

func _khe_cho(mon: MonDo) -> String:
	match mon.loai():
		"vukhi": return "vu_khi"
		"giap": return "giap"
		_: return ""

func _ten_loai(loai: String) -> String:
	match loai:
		"vukhi": return "Vũ khí"
		"giap": return "Giáp"
		"tieu_hao": return "Tiêu hao"
		_: return "Chưa rõ"
