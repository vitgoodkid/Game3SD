extends Node

## Kiểm THẾ GIỚI (mốc 6). Chạy:
##
##     godot --headless --path . tools/thu_the_gioi.tscn
##
## Vì sao tách khỏi hai bộ kia: bộ tầng luật chạy trong một khung hình và không
## nạp scene nào; bộ vòng lặp souls nạp phòng thử — một căn phòng phẳng, dựng
## tay, không có địa hình. Mốc 6 sinh cả một vùng từ CSV rồi nạp/huỷ ô theo
## chân người chơi, và cái hỏng ở đây là loại hỏng không bộ nào kia với tới:
## đất thủng, cây mọc trên vách, ô nạp rồi không huỷ, đi lại một chỗ hai lần
## thấy hai cảnh khác nhau.

const CANH_VUNG := preload("res://scenes/the_gioi/vung_dat.tscn")

var _qua := 0
var _hong := 0
var _v: VungDat = null
var _nc: NguoiChoi = null

func _ready() -> void:
	print("")
	print("====== THU THE GIOI ======")
	_v = CANH_VUNG.instantiate() as VungDat
	add_child(_v)
	await get_tree().process_frame
	await get_tree().physics_frame
	await _cho(1.6)   # rơi từ y=8 xuống đất mất ~0.8s, chờ hụt là test đỏ oan
	_nc = get_tree().get_first_node_in_group("nguoi_choi")

	_dia_hinh()
	_rai_vat()
	await _streaming()
	_chot_chan()
	_bay_vung()
	_bi_xoa()
	_chuoi_vung()

	print("")
	print("====== %d qua, %d HONG ======" % [_qua, _hong])
	get_tree().quit(1 if _hong > 0 else 0)

# --- Khung kiểm tra -------------------------------------------------

func _dung(dk: bool, mo_ta: String) -> void:
	if dk:
		_qua += 1
		print("   ok   %s" % mo_ta)
	else:
		_hong += 1
		print("   HONG %s" % mo_ta)

func _bang(a, b, mo_ta: String) -> void:
	_dung(a == b, "%s  (được %s, muốn %s)" % [mo_ta, str(a), str(b)])

func _nhom(ten: String) -> void:
	print("")
	print("-- %s" % ten)

func _cho(giay: float) -> void:
	await get_tree().create_timer(giay).timeout

# --- Địa hình --------------------------------------------------------

func _dia_hinh() -> void:
	_nhom("Địa hình sinh từ vung.csv")
	var dh := _v.dia_hinh
	_dung(dh != null, "vùng có địa hình")
	if dh == null:
		return

	# Cùng một điểm phải luôn cho cùng một cao độ. Không có tính chất này thì
	# streaming huỷ ô rồi nạp lại là đất nhấp nhô khác đi, và người chơi rơi
	# xuyên qua chỗ vừa đứng.
	var a := dh.cao_tai(37.0, -91.0)
	var b := dh.cao_tai(37.0, -91.0)
	_bang(a, b, "hỏi hai lần cùng một điểm ra cùng một cao độ")

	# Vùng phải GỒ GHỀ thật, không phẳng lì. Đây là phép thử bắt được đúng lỗi
	# đã dính: tần số nhiễu đặt quá thấp so với cỡ vùng thì cả map phẳng như
	# sân bóng mà không ai thấy sai ở đâu.
	var lo := 9999.0
	var hi := -9999.0
	for zi in range(-8, 9):
		for xi in range(-8, 9):
			var h := dh.cao_tai(xi * 20.0, zi * 20.0)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	var chenh := hi - lo
	var cao_do := float(VocabDB.vung_cua(_v.ma_vung).get("cao_do", 20))
	_dung(chenh > cao_do * 0.5,
		"trên 320×320m có chênh cao thật: %.1fm (cao_do khai %.0f)" % [chenh, cao_do])
	_dung(chenh < cao_do * 4.0, "mà không dựng đứng thành vách: %.1fm" % chenh)

	# Gốc vùng phải ĐỨNG ĐƯỢC — chỗ người chơi xuất hiện, không được là vách.
	_dung(absf(dh.cao_tai(0.0, 0.0)) < 1.0,
		"gốc vùng san phẳng (%.2fm) — chỗ hạ cánh phải đứng được" % dh.cao_tai(0, 0))
	_dung(_nc != null and _nc.is_on_floor(), "người chơi đứng trên đất, không rơi")

	# Bảy vùng phải ra bảy địa hình khác nhau — cùng hạt giống thì vô nghĩa.
	var khac := true
	var truoc := 0.0
	var dau := true
	for v in VocabDB.vung:
		var d2 := DiaHinh.tao(String(v["ma"]))
		add_child(d2)
		var h := d2.cao_tai(55.0, 55.0)
		if not dau and absf(h - truoc) < 0.001:
			khac = false
		truoc = h
		dau = false
		d2.queue_free()
	_dung(khac, "bảy vùng cho bảy địa hình khác nhau (hạt giống riêng)")

# --- Rải cây đá ------------------------------------------------------

func _rai_vat() -> void:
	_nhom("Rải cây đá theo luật")
	var dh := _v.dia_hinh
	var o := dh.dung_o(3, 3)
	RaiVat.rai(o, dh, 3, 3, VocabDB.vung_cua(_v.ma_vung))
	var so := o.get_child_count() - 2      # trừ mesh và thân va chạm
	_dung(so > 0, "một ô có cây/đá mọc lên (%d vật)" % so)

	# Cùng ô thì cùng kết quả. Thiếu tính chất này thì mỗi lần streaming nạp
	# lại, cây mọc chỗ khác — và người chơi không bao giờ nhớ được đường, mà
	# nhớ được đường mới là thứ biến một vùng thành một NƠI CHỐN.
	var o2 := dh.dung_o(3, 3)
	RaiVat.rai(o2, dh, 3, 3, VocabDB.vung_cua(_v.ma_vung))
	_bang(o2.get_child_count(), o.get_child_count(),
		"nạp lại cùng một ô ra đúng từng ấy vật")
	var trung := true
	for i in range(2, mini(o.get_child_count(), o2.get_child_count())):
		if not (o.get_child(i) as Node3D).position.is_equal_approx(
				(o2.get_child(i) as Node3D).position):
			trung = false
	_dung(trung, "và mọc đúng từng chỗ cũ")

	# Ô khác thì phải khác — nếu không là cả vùng lặp lại một hình.
	var o3 := dh.dung_o(4, 3)
	RaiVat.rai(o3, dh, 4, 3, VocabDB.vung_cua(_v.ma_vung))
	var khac_o := o3.get_child_count() != o.get_child_count()
	if not khac_o and o.get_child_count() > 2:
		khac_o = not (o3.get_child(2) as Node3D).position.is_equal_approx(
			(o.get_child(2) as Node3D).position)
	_dung(khac_o, "ô bên cạnh thì mọc khác")
	o.queue_free()
	o2.queue_free()
	o3.queue_free()

# --- Streaming -------------------------------------------------------

func _streaming() -> void:
	_nhom("Streaming ô địa hình")
	var can := (VungDat.BAN_KINH_O * 2 + 1) * (VungDat.BAN_KINH_O * 2 + 1)
	_bang(_v.so_o_dang_co(), can, "đứng yên thì nạp đúng lưới quanh mình")

	# Đi xa rồi thì ô cũ phải ĐƯỢC HUỶ, không cứ thế chồng lên. Đây là chỗ
	# hỏng kinh điển của streaming: chạy một vòng map xong là vài trăm ô nằm
	# trong bộ nhớ, khung hình tụt dần mà không ai biết vì sao.
	_nc.global_position = Vector3(DiaHinh.CANH_O * 6.0, 40.0, DiaHinh.CANH_O * 6.0)
	await _cho(0.4)
	_bang(_v.so_o_dang_co(), can, "đi xa sáu ô: vẫn đúng từng ấy ô, ô cũ đã huỷ")

	# Quay lại chỗ cũ phải thấy đúng cảnh cũ.
	var truoc := _v.dia_hinh.cao_tai(20.0, 20.0)
	_nc.global_position = Vector3(0, 40.0, 0)
	await _cho(0.4)
	_bang(_v.so_o_dang_co(), can, "quay về: vẫn đúng từng ấy ô")
	_bang(_v.dia_hinh.cao_tai(20.0, 20.0), truoc, "và đất ở chỗ cũ y nguyên")

# --- Chốt chặn -------------------------------------------------------

func _chot_chan() -> void:
	_nhom("Chốt chặn: bia đá và boss")
	var bia := get_tree().get_nodes_in_group("bia_da")
	_dung(bia.size() >= 3, "vùng có ít nhất 3 bia đá (%d) — mục 7.6" % bia.size())
	var tren_dat := true
	for b in bia:
		var n := b as Node3D
		if absf(n.global_position.y - _v.dia_hinh.cao_tai(
				n.global_position.x, n.global_position.z)) > 1.0:
			tren_dat = false
	_dung(tren_dat, "bia đá đặt đúng trên mặt đất, không chôn trong đồi")

	var bo := get_tree().get_nodes_in_group("boss")
	_dung(bo.size() == 1, "vùng có đúng một boss (%d)" % bo.size())
	if not bo.is_empty():
		var b := bo[0] as Boss
		_bang(String(b.d.get("vung", "")), _v.ma_vung,
			"và đúng con boss khai cho vùng này trong boss.csv")

	# Quái phải đọc từ quai.csv theo cột `vung`, không phải mảng hằng trong code.
	var ds := VocabDB.quai_trong_vung(_v.ma_vung)
	_dung(not ds.is_empty(), "quai.csv có quái khai cho vùng này (%d loài)" % ds.size())
	var dung_vung := true
	for n in get_tree().get_nodes_in_group("quai"):
		var q := n as Quai
		if q == null or q.is_in_group("boss"):
			continue
		var co := false
		for x in ds:
			if String(x["ma"]) == q.ma:
				co = true
		if not co:
			dung_vung = false
	_dung(dung_vung, "mọi con quái trong vùng đều thuộc loài khai cho vùng đó")

# --- Bảy vùng, bảy bảng màu ------------------------------------------

func _bay_vung() -> void:
	_nhom("Bảy vùng bảy bảng màu (mục 7.4)")
	_bang(VocabDB.vung.size(), 7, "vung.csv có đủ bảy vùng")
	var mau := {}
	var goc_troi := {}
	for v in VocabDB.vung:
		mau[str(v.get("mau_suong", ""))] = true
		goc_troi[str(v.get("goc_mat_troi", ""))] = true
	_bang(mau.size(), 7, "bảy màu sương khác nhau")
	_dung(goc_troi.size() >= 5, "góc mặt trời khác nhau ở phần lớn vùng (%d/7)"
		% goc_troi.size())
	var mt := get_tree().get_first_node_in_group("moi_truong_vung") as MoiTruongVung
	_dung(mt != null, "vùng dựng WorldEnvironment riêng của nó")
	if mt != null:
		_dung(mt.environment != null and mt.environment.fog_enabled,
			"có sương — vừa là không khí souls, vừa che mép ô chưa nạp")
		_dung(mt.environment.sdfgi_enabled, "bật SDFGI (mục 7.4)")

# --- Vùng bị xoá (mục 7.5) -------------------------------------------

func _bi_xoa() -> void:
	_nhom("Vùng bị xoá — mất tên thì mất hình dạng")
	var mt := get_tree().get_first_node_in_group("moi_truong_vung") as MoiTruongVung
	if mt == null:
		_dung(false, "không có môi trường vùng")
		return
	var goc := float(VocabDB.vung_cua(_v.ma_vung).get("bi_xoa", 0.0))
	_dung(goc > 0.0, "vùng này có khai bị xoá trong CSV (%.2f)" % goc)
	var truoc := mt.muc_bi_xoa()
	_dung(truoc > 0.0, "và mức bị xoá thực tế > 0 (%.2f)" % truoc)
	_dung(mt.environment.adjustment_saturation < 1.0,
		"màn hình bạc màu theo mức đó (%.2f)" % mt.environment.adjustment_saturation)

	# HỌC CHỮ CỦA VÙNG THÌ VÙNG SÁNG LẠI. Đây là chỗ mục 7.5 nối vào cơ chế
	# học — không có phép thử này thì `bi_xoa` chỉ là một hằng số trang trí.
	var chu_de: Array = VocabDB.vung_cua(_v.ma_vung).get("chu_de", [])
	var hoc := 0
	for cd in chu_de:
		for tu in VocabDB.loc(String(cd)):
			if hoc >= 60:
				break
			if not TriNho.doc_duoc(String(tu["chu"])):
				TriNho.hoc(String(tu["chu"]))
				hoc += 1
	_dung(hoc > 0, "học thử %d chữ của vùng" % hoc)
	var sau := mt.muc_bi_xoa()
	_dung(sau < truoc, "học chữ xong thì vùng bớt bị xoá (%.3f → %.3f)" % [truoc, sau])

# --- Chuỗi mở khoá ---------------------------------------------------

func _chuoi_vung() -> void:
	_nhom("Chuỗi bảy vùng mở dần")
	_dung(DuHanh.vung_dau() != "", "suy ra được vùng đầu chuỗi: %s" % DuHanh.vung_dau())
	_dung(DuHanh.da_mo(DuHanh.vung_dau()), "vùng đầu luôn mở sẵn")
	_dung(DuHanh.da_mo(_v.ma_vung), "vùng đang đứng thì tính là đã tới")

	# Vùng cuối chuỗi phải KHOÁ lúc mới vào — nếu mở sẵn hết thì cả chuỗi
	# `mo_khi` là trang trí và người chơi nhảy thẳng tới boss cuối.
	var cuoi := ""
	for v in VocabDB.vung:
		if int(v.get("cap", 0)) >= 3:
			cuoi = String(v["ma"])
	_dung(cuoi != "" and not DuHanh.da_mo(cuoi),
		"vùng cuối chuỗi (%s) còn khoá" % cuoi)

	# Mỗi vùng trỏ `mo_khi` về một vùng CÓ THẬT, và không có vòng lặp.
	var hop_le := true
	for v in VocabDB.vung:
		var truoc := String(v.get("mo_khi", ""))
		if truoc != "" and VocabDB.vung_cua(truoc).is_empty():
			hop_le = false
	_dung(hop_le, "mọi cột mo_khi đều trỏ tới một vùng có thật")
