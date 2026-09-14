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
	_dung(VocabDB.nguyen_lieu.size() == 38, "nguyen_lieu.csv giữ đủ 38 nguyên liệu")
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
	_dung(SoulsLike.khung_the_luc >= 0.6 and SoulsLike.khung_the_luc <= 1.0,
		"khựng thể lực %.2fs nằm trong 0.6–1.0" % SoulsLike.khung_the_luc)
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
