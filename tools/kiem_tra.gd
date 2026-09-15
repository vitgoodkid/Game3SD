extends Node

## Bộ kiểm tra tự động. Chạy:
##
##     godot --headless --path . tools/kiem_tra.tscn
##
## Thoát mã 0 nếu tất cả qua, mã 1 nếu có cái hỏng.
##
## Vì sao tồn tại: chủ dự án làm việc từ điện thoại, máy có Godot thì tắt.
## Không có bộ này thì mọi thay đổi ở tầng luật đều là đoán mò. GitHub Actions
## chạy đúng lệnh trên (xem .github/workflows/kiem_tra.yml) nên mỗi lần đẩy
## code là biết ngay có gãy gì không.
##
## Nguyên tắc viết test ở đây: chỉ kiểm những thứ mà HỎNG LÀ CHẾT THIẾT KẾ,
## không kiểm từng hàm cho đủ số. Bốn thứ đáng kiểm nhất:
##   1. Thứ tự chữ đổi thì món đồ đổi (mục 4.2) — cơ chế xương sống
##   2. Phai chữ không bao giờ ăn vào chỉ số gốc (mục 4.7) — luật bất khả xâm
##   3. Vòng ngũ hành đúng (mục 4.4) — sai là dạy sai kiến thức thật
##   4. Mọi đòn khai trong CSV đều tồn tại — thiếu là quái đứng im giữa trận

var _qua := 0
var _hong := 0
var _ten_nhom := ""

func _ready() -> void:
	print("")
	print("====== KIEM TRA Game3SD ======")
	_nhom("Dữ liệu")
	_du_lieu()
	_nhom("Ngũ hành")
	_ngu_hanh()
	_nhom("Thang chồng bộ")
	_thang()
	_nhom("Tên món đồ — ngữ pháp")
	_ten_do_vat()
	_nhom("Trí nhớ và cơ chế phai")
	_tri_nho()
	_nhom("Moveset")
	_moveset()
	_nhom("Souls-like")
	_souls()
	_nhom("Ghép chữ ở bia đá")
	_ghep_chu()
	_nhom("Mười dạng câu hỏi")
	_cau_hoi()
	_nhom("Khắc chữ")
	_khac_chu()
	_nhom("Đồ rơi")
	_do_roi()
	_nhom("Màn hình")
	_man_hinh()

	print("")
	print("====== %d qua, %d HONG ======" % [_qua, _hong])
	get_tree().quit(1 if _hong > 0 else 0)

# --- Khung kiểm tra -------------------------------------------------

func _nhom(ten: String) -> void:
	_ten_nhom = ten
	print("")
	print("-- %s" % ten)

func _dung(dieu_kien: bool, mo_ta: String) -> void:
	if dieu_kien:
		_qua += 1
		print("   ok   %s" % mo_ta)
	else:
		_hong += 1
		print("   HONG %s" % mo_ta)

func _bang(a, b, mo_ta: String) -> void:
	_dung(a == b, "%s  (được %s, muốn %s)" % [mo_ta, str(a), str(b)])

func _gan(a: float, b: float, mo_ta: String, sai_so := 0.001) -> void:
	_dung(absf(a - b) <= sai_so, "%s  (được %.4f, muốn %.4f)" % [mo_ta, a, b])

# --- Các nhóm -------------------------------------------------------

func _du_lieu() -> void:
	_dung(VocabDB.tu_vung.size() >= 1011,
		"tu_vung.csv có %d chữ (>= 1011)" % VocabDB.tu_vung.size())
	_dung(VocabDB.ngu_phap.size() == 41, "ngu_phap.csv giữ đủ 41 câu")
	# 38 nguyên liệu của bản 2D + 盾 (khiên, thêm lúc làm combat kiểu Elden Ring
	# — ER tách khiên khỏi vũ khí và chỉ khiên mới parry được).
	_dung(VocabDB.nguyen_lieu.size() == 39, "nguyen_lieu.csv giữ đủ 39 nguyên liệu")
	var khien := 0
	for n in VocabDB.nguyen_lieu:
		if String(n.get("loai", "")) == "khien":
			khien += 1
	_dung(khien >= 1, "có ít nhất một món loại 'khien' — không có thì không ai parry được")
	_dung(VocabDB.trang_bi.size() == 18, "trang_bi.csv giữ đủ 18 công thức")
	_dung(VocabDB.vung.size() == 7, "vung.csv có đủ 7 vùng")
	_dung(not VocabDB.quai.is_empty(), "quai.csv nạp được")
	_dung(not VocabDB.don_quai.is_empty(), "don_quai.csv nạp được")

	# Không được có chữ trùng — chỉ mục dictionary sẽ nuốt mất bản sau.
	var thay := {}
	var trung: Array[String] = []
	for t in VocabDB.tu_vung:
		var c := String(t["chu"])
		if thay.has(c):
			trung.append(c)
		thay[c] = true
	_dung(trung.is_empty(), "không có chữ trùng trong tu_vung.csv%s"
		% ("" if trung.is_empty() else " — trùng: " + " ".join(trung)))

	# Cột cũ phải còn nguyên (mục 10: KHÔNG đổi cột cũ).
	for cot in ["chu", "pinyin", "han_viet", "nghia", "bo_thu", "chu_de", "cap"]:
		_dung(VocabDB.tu_vung[0].has(cot), "cột cũ '%s' còn nguyên" % cot)
	for cot in ["so_net", "ngu_hanh", "thang_goc", "thang_bac", "tan_suat"]:
		_dung(VocabDB.tu_vung[0].has(cot), "cột mới '%s' đã thêm" % cot)

func _ngu_hanh() -> void:
	# Vòng tương sinh: 木 → 火 → 土 → 金 → 水 → 木
	_bang(NguHanh.sinh_ra("木"), "火", "木 sinh 火")
	_bang(NguHanh.sinh_ra("水"), "木", "水 sinh 木 (khép vòng)")
	_bang(NguHanh.duoc_sinh_boi("火"), "木", "火 được 木 sinh")
	# Tương khắc: 木克土 土克水 水克火 火克金 金克木
	_bang(NguHanh.khac("木"), "土", "木 khắc 土")
	_bang(NguHanh.khac("土"), "水", "土 khắc 水")
	_bang(NguHanh.khac("水"), "火", "水 khắc 火")
	_bang(NguHanh.khac("火"), "金", "火 khắc 金")
	_bang(NguHanh.khac("金"), "木", "金 khắc 木")
	_bang(NguHanh.bi_khac_boi("土"), "木", "土 bị 木 khắc")

	_gan(NguHanh.he_so("木", "土"), NguHanh.HS_KHAC, "khắc được thì ×1.5")
	_gan(NguHanh.he_so("土", "木"), NguHanh.HS_BI_KHAC, "bị khắc thì ×0.6")
	_gan(NguHanh.he_so("木", "火"), NguHanh.HS_SINH, "sinh ra nó thì nó HỒI máu")
	_dung(NguHanh.he_so("木", "火") < 0.0, "hệ số sinh phải ÂM — dùng sai là tự hại")
	_gan(NguHanh.he_so("木", "木"), 1.0, "cùng hành thì ×1.0")
	_gan(NguHanh.he_so("", "火"), 1.0, "không hành thì không khắc được ai (boss 无)")
	_gan(NguHanh.he_so("火", ""), 1.0, "không hành thì không bị ai khắc")

	# Cộng hưởng đếm theo CẶP tương sinh, không theo món.
	_gan(NguHanh.cong_huong(["木", "火"]), 1.0 + NguHanh.CONG_HUONG, "một cặp tương sinh +10%")
	_gan(NguHanh.cong_huong(["木", "木", "木"]), 1.0, "cùng hành thì không cộng hưởng")

func _thang() -> void:
	var can := [["木", "林", "森"], ["人", "从", "众"], ["火", "炎", "焱"],
		["日", "昌", "晶"], ["土", "圭", "垚"], ["口", "吕", "品"]]
	for t in can:
		_bang(VocabDB.ca_thang(String(t[0])), t, "thang %s đủ ba bậc" % String(t[0]))
		_bang(TenDoVat.bac_tren(String(t[0])), String(t[1]), "%s nâng lên %s" % [t[0], t[1]])
		_bang(TenDoVat.bac_tren(String(t[2])), "", "%s đã kịch bậc" % String(t[2]))
	# Thang nhảy bậc: 水 không có bậc 2, lên thẳng 淼
	_bang(VocabDB.ca_thang("水"), ["水", "淼"], "thang 水 nhảy thẳng lên bậc 3")
	_bang(VocabDB.bac_thang_cua("森"), 3, "森 là bậc 3")
	_bang(VocabDB.bac_thang_cua("剑"), 1, "chữ ngoài thang coi như bậc 1")

	# Cảnh báo ở mục 4.3: KHÔNG được đưa chữ hiếm/xúc phạm vào thang.
	for xau in ["奻", "姦", "瞐", "刕", "畾", "劦", "孖", "沝", "眀"]:
		_dung(VocabDB.goc_thang_cua(xau) == "",
			"chữ hiếm %s không nằm trong thang nào" % xau)

func _ten_do_vat() -> void:
	# ĐÂY LÀ TEST QUAN TRỌNG NHẤT CỦA CẢ FILE.
	# Cùng ba chữ, đổi thứ tự thì ra hai món khác hẳn nhau (mục 4.2).
	var a := ["冰", "金", "剑"]     # băng [kim kiếm] — kim là chính, băng phủ ngoài
	var b := ["金", "冰", "剑"]     # kim [băng kiếm] — băng là chính
	var pa := TenDoVat.phan_tich(a)
	var pb := TenDoVat.phan_tich(b)
	_bang(String(pa["ngu_hanh"]), "金", "冰金剑 → hành Kim (kim gần trung tâm hơn)")
	_bang(String(pb["ngu_hanh"]), "水", "金冰剑 → hành Thuỷ (băng gần trung tâm hơn)")
	_dung(String(pa["ngu_hanh"]) != String(pb["ngu_hanh"]),
		"đổi thứ tự chữ là ĐỔI MÓN ĐỒ — cơ chế xương sống còn sống")

	_bang(TenDoVat.trung_tam(a), "剑", "chữ cuối là trung tâm")
	_bang(String(pa["loai"]), "vukhi", "trung tâm 剑 cho ra vũ khí")
	_gan(TenDoVat.trong_so_tai(2, 3), 1.0, "trung tâm ăn ×1.0")
	_gan(TenDoVat.trong_so_tai(1, 3), 0.6, "lùi một bậc ăn ×0.6")
	_gan(TenDoVat.trong_so_tai(0, 3), 0.35, "lùi hai bậc ăn ×0.35")

	# Trung tâm phải đứng CUỐI, không thì là câu sai ngữ pháp.
	_dung(bool(TenDoVat.kiem_ten(["冰", "剑"])["duoc"]), "冰剑 hợp lệ")
	_dung(not bool(TenDoVat.kiem_ten(["剑", "冰"])["duoc"]),
		"剑冰 KHÔNG hợp lệ — trung tâm phải đứng cuối")
	_dung(not bool(TenDoVat.kiem_ten(["剑", "刀"])["duoc"]),
		"hai trung tâm trong một tên là sai")

	# Chồng bộ nhân sát thương gốc lên.
	var goc := float(TenDoVat.phan_tich(["木", "剑"])["st_them"])
	var cao := float(TenDoVat.phan_tich(["森", "剑"])["st_them"])
	_dung(cao > goc, "森剑 mạnh hơn 木剑 (%.1f > %.1f) — chồng bộ = nâng cấp" % [cao, goc])

	# Cả chín thang phải TĂNG DẦN về sức mạnh — không thì nâng cấp là nâng lùi.
	var khong_tang: Array[String] = []
	for goc_thang in ["木", "人", "火", "日", "土", "水", "金", "石", "口"]:
		var truoc_bac := -1.0
		for chu in VocabDB.ca_thang(goc_thang):
			var suc := float(TenDoVat.phan_tich([chu, "剑"])["st_them"])
			if suc <= truoc_bac:
				khong_tang.append("%s(%s)" % [goc_thang, chu])
			truoc_bac = suc
	_dung(khong_tang.is_empty(), "cả 9 thang đều tăng sức mạnh theo bậc%s"
		% ("" if khong_tang.is_empty() else " — lùi ở: " + " ".join(khong_tang)))

	# Hành lấy từ bổ nghĩa, không từ trung tâm — trừ khi không bổ nghĩa nào có.
	_bang(String(TenDoVat.phan_tich(["剑"])["ngu_hanh"]), "金",
		"kiếm trần vẫn là hệ Kim (không bổ nghĩa nào có hành)")
	_bang(String(TenDoVat.phan_tich(["冰", "剑"])["ngu_hanh"]), "水",
		"khắc 冰 lên kiếm thì đổi thành hệ Thuỷ")

	# Hoán vị: 3 chữ bổ nghĩa cho 6 cách xếp, trung tâm không bao giờ đổi chỗ.
	var hv := TenDoVat.moi_cach_xep(["冰", "金", "极", "剑"])
	_bang(hv.size(), 6, "3 chữ bổ nghĩa → 6 cách xếp")
	var tt_luon_cuoi := true
	for t in hv:
		if String(t[t.size() - 1]) != "剑":
			tt_luon_cuoi = false
	_dung(tt_luon_cuoi, "mọi cách xếp đều giữ 剑 ở cuối")
	_bang(TenDoVat.doi_cho(["冰", "金", "剑"], 0, 2), ["冰", "金", "剑"],
		"không đổi chỗ được với trung tâm")

func _tri_nho() -> void:
	TriNho.khoi_dau(["剑", "冰"])
	_dung(TriNho.doc_duoc("剑"), "chữ vừa học thì đọc được")
	_dung(not TriNho.doc_duoc("极"), "chữ chưa học thì KHÔNG đọc được")
	_bang(TenDoVat.ten_hien(["极", "冰", "剑"]), "□冰剑", "chữ chưa biết hiện □")
	_bang(TenDoVat.dong_con_lai(["极", "冰", "剑"]), "còn 1 chữ chưa đọc được",
		"đếm đúng số chữ chưa đọc được")

	var dong := TenDoVat.dong_mo_ta(["极", "冰", "剑"])
	_bang(dong.size(), 3, "mô tả đủ ba dòng")
	_bang(String(dong[0]["nhan"]), TenDoVat.SO_MO, "chữ lạ → chỉ số ???")
	_dung(bool(dong[2]["doc_duoc"]), "chữ đã biết → hiện chỉ số thật")

	# LUẬT BẤT KHẢ XÂM PHẠM (mục 4.7): phai chữ KHÔNG ĐƯỢC ăn vào chỉ số gốc.
	var pt := TenDoVat.phan_tich(["极", "冰", "剑"])
	var st := TenDoVat.sat_thuong_thuc(pt)
	_dung(st >= float(pt["st_goc"]) - 0.001,
		"sát thương thực (%.1f) không bao giờ thấp hơn gốc (%.1f)" % [st, float(pt["st_goc"])])

	# Học thêm chữ thì món đồ CŨ mạnh lên — đúng mục 4.1.
	TriNho.hoc("极")
	var st2 := TenDoVat.sat_thuong_thuc(TenDoVat.phan_tich(["极", "冰", "剑"]))
	_dung(st2 > st, "học thêm 极 thì cây kiếm cũ mạnh lên (%.1f → %.1f)" % [st, st2])
	_bang(TenDoVat.ten_hien(["极", "冰", "剑"]), "极冰剑", "học xong thì tên hiện đủ")

	# Bốn mức thuần thục xếp tăng dần, hiệu lực khớp bảng ở mục 4.7.
	_gan(float(TriNho.HIEU_LUC[TriNho.MUC_THUOC]), 1.0, "Thuộc → 100%")
	_gan(float(TriNho.HIEU_LUC[TriNho.MUC_MO]), 0.7, "Mờ → 70%")
	_gan(float(TriNho.HIEU_LUC[TriNho.MUC_PHAI]), 0.0, "Phai → mất hết phần cộng thêm")
	_bang(TriNho.LICH_ON, [1, 3, 7, 16, 35], "lịch ôn SM-2 rút gọn")

	# Trả lời SAI không được tụt thẳng xuống Phai — hình phạt phải cân với lỗi.
	TriNho.on_tap("极", false)
	_dung(TriNho.muc_thuan_thuc("极") >= TriNho.MUC_MO,
		"trả lời sai một câu không làm mất sạch phần cộng thêm")

func _moveset() -> void:
	# Mọi đòn quái khai trong quai.csv / boss.csv phải có trong don_quai.csv.
	# Thiếu một dòng là con quái đó đứng im giữa trận — lỗi im lặng, khó thấy.
	var thieu: Array[String] = []
	for q in VocabDB.quai:
		for don in q.get("moveset", []):
			if VocabDB.don_quai_cua(String(don)).get("don", "") != String(don):
				thieu.append("%s:%s" % [q["ma"], don])
	for b in VocabDB.boss:
		for cot in ["moveset_1", "moveset_2"]:
			for don in b.get(cot, []):
				if VocabDB.don_quai_cua(String(don)).get("don", "") != String(don):
					thieu.append("%s:%s" % [b["ma"], don])
	_dung(thieu.is_empty(), "mọi đòn quái/boss đều có dữ liệu%s"
		% ("" if thieu.is_empty() else " — thiếu: " + " ".join(thieu)))

	# Mọi quái/boss phải thuộc một vùng có thật.
	var lac: Array[String] = []
	for q in VocabDB.quai:
		if VocabDB.vung_cua(String(q["vung"])).is_empty():
			lac.append(String(q["ma"]))
	for b in VocabDB.boss:
		if VocabDB.vung_cua(String(b["vung"])).is_empty():
			lac.append(String(b["ma"]))
	_dung(lac.is_empty(), "mọi quái/boss đều thuộc vùng có thật%s"
		% ("" if lac.is_empty() else " — lạc: " + " ".join(lac)))

	# ĐÒN PHẢI ĐỌC ĐƯỢC (mục 5.4): không đòn quái nào vung nhanh hơn 0.5s.
	var nhanh: Array[String] = []
	for dq in VocabDB.don_quai:
		if float(dq.get("t_dam_tu", 1.0)) < 0.5:
			nhanh.append("%s(%.2fs)" % [dq["don"], float(dq["t_dam_tu"])])
	_dung(nhanh.is_empty(), "mọi đòn quái đều vung >= 0.5s — né kịp%s"
		% ("" if nhanh.is_empty() else " — quá nhanh: " + " ".join(nhanh)))

	# Mỗi vũ khí phải có đủ combo và đòn nặng.
	for chu in ["剑", "刀", "斧", "拳"]:
		_dung(VocabDB.combo_nhe(chu).size() >= 3, "%s có combo >= 3 nhát" % chu)
		_dung(not VocabDB.don_cua(chu, "nang").is_empty(), "%s có đòn nặng" % chu)
	# Vũ khí lạ thì lùi về tay không, không được trả về rỗng.
	_dung(not VocabDB.moveset_cua("桌").is_empty(), "vũ khí lạ lùi về moveset tay không")

	# Khung gây sát thương phải nằm sau khung vung tay, không chồng ngược.
	var lech: Array[String] = []
	for m in VocabDB.moveset:
		if float(m["t_dam_den"]) <= float(m["t_dam_tu"]):
			lech.append(String(m["chu"]) + ":" + String(m["don"]))
	_dung(lech.is_empty(), "khung sát thương của mọi đòn đều hợp lệ%s"
		% ("" if lech.is_empty() else " — sai: " + " ".join(lech)))

func _souls() -> void:
	# Ba con số của mục 5.2 phải nằm trong khoảng đã chốt.
	_dung(SoulsLike.iframe_lan >= 0.30 and SoulsLike.iframe_lan <= 0.40,
		"i-frame lăn %.2fs nằm trong 0.30–0.40" % SoulsLike.iframe_lan)
	# Mục 5.2 gọi con số này là "khựng thể lực". Sau khi combat đổi sang mô hình
	# Elden Ring nó không còn là khựng-mỗi-lần-tiêu nữa mà là TRỄ HỒI sau khi
	# hành động kết thúc, nên khoảng hợp lệ cũng đổi: ER hồi lại rất nhanh.
	_dung(SoulsLike.tre_hoi_the_luc >= 0.25 and SoulsLike.tre_hoi_the_luc <= 0.60,
		"trễ hồi thể lực %.2fs nằm trong 0.25–0.60" % SoulsLike.tre_hoi_the_luc)
	var nang := VocabDB.don_cua("剑", "nang")
	_dung(float(nang["t_hoi"]) >= 0.7 and float(nang["t_hoi"]) <= 1.2,
		"khung hồi đòn nặng %.2fs nằm trong 0.7–1.2" % float(nang["t_hoi"]))

	# Tải trọng: bốn mức, i-frame giảm dần theo tải.
	_bang(String(SoulsLike.muc_tai(0.10)["muc"]), "nhe", "dưới 30% là tải nhẹ")
	_bang(String(SoulsLike.muc_tai(0.50)["muc"]), "vua", "30–70% là tải vừa")
	_bang(String(SoulsLike.muc_tai(0.85)["muc"]), "nang", "70–100% là tải nặng")
	_bang(String(SoulsLike.muc_tai(1.20)["muc"]), "qua_tai", "trên 100% là quá tải")
	_dung(SoulsLike.iframe_thuc(0.1, 20) > SoulsLike.iframe_thuc(0.85, 20),
		"mặc nhẹ thì i-frame dài hơn mặc nặng")
	_dung(SoulsLike.iframe_thuc(0.5, 40) > SoulsLike.iframe_thuc(0.5, 0),
		"韧 cao thì i-frame dài hơn")

	# Đỡ không bao giờ chặn trọn 100% — nếu không thì không ai cần học lăn.
	_dung(SoulsLike.sat_thuong_sau_do(100, 100) > 0, "đỡ khiên xịn vẫn ăn sát thương")
	_dung(SoulsLike.sat_thuong_sau_do(100, 0) == 100, "không khiên thì ăn trọn")

	# Thiên can xếp giảm dần 甲 > 乙 > 丙 > 丁 > 戊.
	var truoc := 99.0
	var xep_dung := true
	for can in SoulsLike.THU_TU_CAN:
		var hs := SoulsLike.he_so_can(can)
		if hs >= truoc:
			xep_dung = false
		truoc = hs
	_dung(xep_dung, "thiên can 甲>乙>丙>丁>戊 xếp đúng thứ tự")

	# Thanh trạng thái: tích dần, đầy mới bùng (mục 5.3).
	var th := SoulsLike.Thanh.new(100.0)
	_dung(not th.them(60.0), "tích 60 chưa bùng")
	_dung(th.them(50.0), "tích thêm 50 thì bùng")
	_dung(th.nguong > 100.0, "bùng xong ngưỡng lần sau cao hơn — không khoá cứng")

func _ghep_chu() -> void:
	# Bộ thủ TRÙNG phải đếm cho đúng: 林 cần 木|木, tức HAI mảnh. Đếm hụt thì
	# một mảnh 木 cũng ra rừng, và cả thang chồng bộ (mục 4.3) mất ý nghĩa vì
	# bậc trên rẻ ngang bậc dưới.
	Tui.bo_thu.clear()
	Tui.them_bo_thu("木", 1)
	_dung(not Tui.ghep_duoc("林"), "một mảnh 木 chưa ghép được 林 — nó cần hai")
	_bang(int(Tui.thieu_bo_thu("林").get("木", 0)), 1, "báo đúng còn thiếu một mảnh 木")
	Tui.them_bo_thu("木", 1)
	_dung(Tui.ghep_duoc("林"), "đủ hai mảnh thì ghép được 林")
	_dung(Tui.ghep("林"), "ghép 林 xong xuôi")
	_bang(Tui.so_bo_thu("木"), 0, "ghép xong trừ đủ HAI mảnh, không phải một")
	_dung(TriNho.doc_duoc("林"), "ghép xong là đọc được ngay")
	_dung(not Tui.ghep("林"), "chữ đã biết thì không ghép lại")

	# Chữ độc thể (không khai bộ thủ nào) cần đúng một mảnh của chính nó.
	Tui.bo_thu.clear()
	Tui.them_bo_thu("口", 1)
	_dung(Tui.chu_ghep_duoc().has("口"), "chữ độc thể ghép bằng một mảnh của chính nó")

func _cau_hoi() -> void:
	TriNho.khoi_dau(Tui.CHU_BAN_DAU)
	# Cả mười dạng đều phải dựng được từ dữ liệu ĐANG CÓ. Dạng nào không dựng
	# nổi là dạng chết — bản 2D từng ra màn hình trắng đúng vì chuyện này.
	var chet: Array[String] = []
	for kieu in CauHoi.MOI_KIEU:
		var duoc := false
		for i in 300:
			var tu := VocabDB.lay_ngau_nhien()
			if tu.is_empty():
				continue
			if _cau_hop_le(CauHoi.sinh_cau(String(tu["chu"]), [String(kieu)])):
				duoc = true
				break
		if not duoc:
			chet.append(String(kieu))
	_dung(chet.is_empty(), "cả 10 dạng câu hỏi đều dựng được%s"
		% ("" if chet.is_empty() else " — chết: " + " ".join(chet)))

	# Không màn nào gọi CauHoi nữa (thẻ ngồi thiền đã bỏ), nhưng nhóm test này
	# ở lại: nó là thứ duy nhất bắt Godot BIÊN DỊCH cau_hoi.gd. Gỡ nó đi thì
	# file kia hỏng lúc nào không ai biết — đúng cái bẫy đã ghi trong TIEN_DO.
	var hong := 0
	for i in 80:
		if not _cau_hop_le(CauHoi.sinh_theo_lich_on()):
			hong += 1
	_bang(hong, 0, "80 lần ngồi thiền đều ra câu hỏi hợp lệ")

	# Trả lời đúng phải đẩy lịch ôn ra xa, sai thì kéo về gần (SM-2).
	TriNho.khoi_dau(["剑"])
	var lan_dau := int(TriNho.so["剑"]["lan"])
	TriNho.on_tap("剑", true)
	_dung(int(TriNho.so["剑"]["lan"]) > lan_dau, "trả lời đúng thì lịch ôn giãn ra")
	TriNho.on_tap("剑", false)
	_bang(int(TriNho.so["剑"]["lan"]), lan_dau, "trả lời sai thì lịch ôn co lại")

## Câu hỏi dùng được: có đề, có ít nhất hai lựa chọn, và đáp án đúng nằm trong
## danh sách. Thiếu một trong ba là giao diện dựng ra thứ không bấm được.
func _cau_hop_le(c: Dictionary) -> bool:
	if c.is_empty() or String(c.get("de", "")).strip_edges().is_empty():
		return false
	var lc: Array = c.get("lua_chon", [])
	var d := int(c.get("dung", -1))
	if lc.size() < 2 or d < 0 or d >= lc.size():
		return false
	return not String(c.get("chu", "")).is_empty()

func _khac_chu() -> void:
	TriNho.khoi_dau(["剑", "冰", "金", "木", "林"])
	Tui.hon = 5000
	var mon := MonDo.new(["剑"])
	var gia := TenDoVat.gia_khac(mon.ten, "冰")
	_dung(Tui.khac_them(mon, "冰"), "khắc 冰 lên 剑")
	_bang(mon.chuoi(), "冰剑", "chữ mới đứng ngay TRƯỚC trung tâm")
	_bang(Tui.hon, 5000 - gia, "khắc xong trừ đúng giá")
	_dung(TenDoVat.gia_khac(mon.ten, "金") > TenDoVat.gia_khac(["剑"], "金"),
		"tên càng dài thì khắc thêm càng đắt — không cho nhồi mười chữ")
	_dung(not Tui.khac_them(mon, "冰"), "không khắc hai lần cùng một chữ")
	_dung(not Tui.khac_them(mon, "森"), "không khắc được chữ chưa đọc được")

	# Đổi chỗ là ĐỔI MÓN (mục 4.2) — và phải miễn phí, vì đó là bài học.
	_dung(Tui.khac_them(mon, "金"), "khắc thêm 金")
	_bang(mon.chuoi(), "冰金剑", "chữ mới vẫn chen vào sát trung tâm")
	var hanh_truoc := mon.ngu_hanh()
	var hon_truoc := Tui.hon
	_dung(Tui.doi_cho_chu(mon, 0, 1), "đổi chỗ hai chữ bổ nghĩa")
	_bang(mon.chuoi(), "金冰剑", "đổi chỗ xong tên đổi")
	_bang(Tui.hon, hon_truoc, "đổi thứ tự KHÔNG tốn hồn")
	_dung(mon.ngu_hanh() != hanh_truoc,
		"đổi thứ tự là đổi món — hành đi từ %s sang %s" % [hanh_truoc, mon.ngu_hanh()])
	_dung(not Tui.doi_cho_chu(mon, 0, 2), "không đổi chỗ được với trung tâm")
	_dung(not Tui.go_chu(mon, 2), "không gỡ được chữ trung tâm")
	_dung(Tui.go_chu(mon, 0), "gỡ được chữ bổ nghĩa")

	# Nâng bậc chồng bộ: tốn bộ thủ của chữ GỐC thang, và phải đọc được chữ mới.
	var m2 := MonDo.new(["木", "剑"])
	var can := TenDoVat.gia_nang_bac("木")
	Tui.bo_thu.clear()
	_dung(not Tui.nang_bac_chu(m2, 0), "thiếu bộ thủ thì không nâng bậc được")
	Tui.them_bo_thu("木", can)
	_dung(Tui.nang_bac_chu(m2, 0), "đủ %d mảnh 木 thì nâng được 木 → 林" % can)
	_bang(m2.chuoi(), "林剑", "nâng bậc xong tên đổi")
	_bang(Tui.so_bo_thu("木"), 0, "nâng bậc trừ đúng số mảnh")

func _do_roi() -> void:
	var a := SinhMonDo.sinh_mon("ria_bien", 12345)
	var b := SinhMonDo.sinh_mon("ria_bien", 12345)
	_dung(a != null and b != null, "sinh được món đồ")
	if a != null and b != null:
		_bang(a.chuoi(), b.chuoi(), "cùng hạt giống thì ra đúng cùng một món")

	# Mọi món rơi ra phải đọc được như một câu: trung tâm đứng cuối, và trung
	# tâm phải là chữ ĐỨNG TRUNG TÂM ĐƯỢC. Sai là món đồ không moveset.
	var hong: Array[String] = []
	var so_mon := 0
	for v in VocabDB.vung:
		for i in 20:
			var m := SinhMonDo.sinh_mon(String(v["ma"]), 1000 + i * 7)
			if m == null:
				hong.append("(null)")
				continue
			so_mon += 1
			if not bool(TenDoVat.kiem_ten(m.ten)["duoc"]):
				hong.append(m.chuoi())
			elif VocabDB.vi_tri_cua(m.trung_tam()) != "trung_tam":
				hong.append(m.chuoi())
	_dung(hong.is_empty(), "%d món sinh ra đều đúng ngữ pháp tên%s"
		% [so_mon, "" if hong.is_empty() else " — hỏng: " + " ".join(hong)])
	_dung(SinhMonDo.kho_bo_nghia("ria_bien").size()
		> SinhMonDo.kho_bo_nghia("thi_tran").size(),
		"vùng có chủ đề thì kho chữ bổ nghĩa rộng hơn — đi sâu là gặp chữ lạ hơn")

## Màn hình vẽ được tới dòng cuối không. GDScript không ném lỗi: hàm vẽ gãy
## giữa chừng thì màn hình vẫn hiện một nửa và trông như bình thường. Ba file
## màn hình từng nằm trong repo cả một mốc mà chưa ai chạy thử lần nào.
func _man_hinh() -> void:
	TriNho.khoi_dau(Tui.CHU_BAN_DAU)
	Tui.kho.clear()
	Tui.hon = 3000
	Tui.bo_thu.clear()
	Tui.them_bo_thu("木", 2)
	var mon := SinhMonDo.sinh_mon("thi_tran", 20260914)
	if mon != null:
		Tui.nhat(mon)

	var bia := ManBiaDa.new()
	add_child(bia)
	for i in ManBiaDa.TEN_THE.size():
		bia._the = i
		bia.lam_moi()
		_dung(bia.ve_xong, "màn bia đá vẽ trọn thẻ '%s'" % String(ManBiaDa.TEN_THE[i]))

	# Thẻ khắc chữ chỉ vẽ hết phần thú vị khi đã chọn món và chọn chữ.
	if not Tui.kho.is_empty():
		bia._the = ManBiaDa.TEN_THE.find("Khắc chữ")
		bia._mon = Tui.kho[0]
		bia._vi_tri = 0
		bia.lam_moi()
		_dung(bia.ve_xong, "màn bia đá vẽ trọn phần việc với một chữ đang chọn")
	bia.queue_free()

	var hanh_trang = load("res://scripts/giao_dien/man_hanh_trang.gd").new()
	add_child(hanh_trang)
	hanh_trang.lam_moi()
	_dung(hanh_trang.ve_xong, "màn hành trang vẽ trọn lúc chưa chọn món nào")
	if not Tui.kho.is_empty():
		hanh_trang._chon = Tui.kho[0]
		hanh_trang.lam_moi()
		_dung(hanh_trang.ve_xong, "màn hành trang vẽ trọn bảng chỉ số của một món")
	hanh_trang.queue_free()
