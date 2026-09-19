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
	_npc_cot_truyen()
	_am_thanh()
	_noi_dung_moc_7()

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

## Đợi cho `_process` của MỌI node chạy xong đúng một lượt.
##
## HAI lần await, không phải một. Tín hiệu `process_frame` bắn ra TRƯỚC khi
## SceneTree gọi `_process` của các node, nên một lần await thì đo được đúng
## cái trạng thái chưa đổi. Đã dính: dịch người chơi sang ô bên cạnh rồi đo
## ngay, thấy `_o_cuoi` vẫn là ô cũ và hàng chờ rỗng — trông y hệt streaming
## không chạy, trong khi nó chỉ chưa tới lượt.
func _khung() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

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

## Băng qua một ranh giới ô là nạp một CỘT ô mới — bấy nhiêu cái.
const BUOC_MOI_LAN := VungDat.BAN_KINH_O * 2 + 1

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

	# --- DỊCH CHUYỂN thì dựng NGAY, không xếp hàng ---
	#
	# Hai cú nhảy ở trên đều là dịch chuyển, nên chúng đi đường `nap_het()`.
	# Đo ở đây cho rõ, vì đó là vế đối của cả phần xếp hàng bên dưới: hở đất
	# dưới chân thì không được phép hoãn.
	_bang(_v.so_buoc_cho(), 0, "dịch chuyển xong là hàng chờ RỖNG — đất có ngay")

	# --- ĐI BỘ qua ranh giới thì XẾP HÀNG ---
	#
	# Dịch đúng MỘT ô: ô dưới chân đã nạp sẵn (nó nằm trong lưới 5×5 cũ), nên
	# đây là đường đi bộ chứ không phải dịch chuyển. Năm ô mới phải nằm chờ
	# chứ không được dựng hết trong một khung — 33 ms cho năm ô là bốn tick
	# vật lý 120Hz bị nuốt, và đó đúng là cái đợt này đi sửa.
	var o_truoc := _v.so_o_dang_co()
	_nc.global_position += Vector3(DiaHinh.CANH_O, 0.0, 0.0)
	await _khung()
	_dung(_v.so_buoc_cho() > 0,
		"đi bộ sang ô bên cạnh: việc nằm trong HÀNG CHỜ (%d bước)" % _v.so_buoc_cho())
	_dung(_v.so_o_dang_co() < o_truoc + BUOC_MOI_LAN,
		"và chưa dựng hết năm ô mới trong một khung (%d ô)" % _v.so_o_dang_co())

	# Rút dần chứ không đứng im: ngân sách nhỏ hơn một bước nên mỗi khung
	# đúng một bước, nhưng KHÔNG ĐƯỢC là không bước nào.
	var cho_truoc := _v.so_buoc_cho()
	await _khung()
	_dung(_v.so_buoc_cho() < cho_truoc,
		"mỗi khung hình rút được ít nhất một bước (%d → %d)"
		% [cho_truoc, _v.so_buoc_cho()])

	await _cho(0.6)
	_bang(_v.so_buoc_cho(), 0, "để yên một lúc thì hàng chờ rút HẾT")
	_bang(_v.so_o_dang_co(), can, "và lưới lại đủ ô")

	# --- QUAY ĐẦU giữa đường thì bỏ phần không đi nữa ---
	#
	# Không có luật này thì đi tới đi lui vài lần là hàng chờ phình ra toàn ô
	# đã không cần, và mỗi khung vẫn cắm cúi dựng chúng.
	_nc.global_position += Vector3(DiaHinh.CANH_O, 0.0, 0.0)
	await _khung()
	var cho_di := _v.so_buoc_cho()
	_dung(cho_di > 0, "đi tiếp một ô nữa: lại có việc xếp hàng (%d)" % cho_di)
	_nc.global_position -= Vector3(DiaHinh.CANH_O, 0.0, 0.0)
	await _khung()
	_dung(_v.so_buoc_cho() < cho_di,
		"quay đầu lại thì bỏ bớt việc không cần nữa (%d → %d)"
		% [cho_di, _v.so_buoc_cho()])
	await _cho(0.6)
	_bang(_v.so_o_dang_co(), can, "và vẫn về đúng lưới cũ")

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


# --- Mốc 7: NPC và cốt truyện ---------------------------------------

func _npc_cot_truyen() -> void:
	_nhom("NPC và cốt truyện (mốc 7)")
	_dung(VocabDB.npc.size() >= 7, "npc.csv có ít nhất một NPC mỗi vùng (%d)"
		% VocabDB.npc.size())
	var ds := get_tree().get_nodes_in_group("npc")
	_dung(not ds.is_empty(), "vùng dựng NPC lên (%d)" % ds.size())
	if ds.is_empty():
		return
	var n := ds[0] as Npc
	_dung(n.so_cau() > 0, "NPC có thoại (%d câu)" % n.so_cau())

	# Mọi chữ trong thoại phải CÓ THẬT trong tu_vung.csv. Thiếu một chữ là câu
	# đó không bao giờ đọc được, và cả mạch chuyện đứt mà không ai báo lỗi.
	var thieu: Array[String] = []
	for x in VocabDB.npc:
		for cau in x.get("thoai", []):
			for c in String(cau):
				if Npc._la_chu_han(c) and VocabDB.tu_cua(c).is_empty() 						and not thieu.has(c):
					thieu.append(c)
	_dung(thieu.is_empty(), "mọi chữ trong thoại đều có trong tu_vung.csv%s"
		% ("" if thieu.is_empty() else " — thiếu: " + " ".join(thieu)))

	# LUẬT ???: chưa biết chữ thì thoại hiện □, và BẢN DỊCH KHÔNG LỘ.
	# Đây là chỗ mục 13 được thi hành — phần thưởng của việc học là hiểu được
	# cốt truyện. Gỡ phép thử này đi thì chữ Hán thành trang trí.
	var cau := n.cau_chu(0)
	for c in cau:
		if Npc._la_chu_han(c):
			TriNho.so.erase(c)
	_dung(n.cau_hien(0).contains(TenDoVat.CHU_MO),
		"chữ chưa học thì thoại hiện □ (%s)" % n.cau_hien(0))
	_dung(not n.hieu_duoc(0), "và chưa hiểu được câu đó")
	var ti_truoc := n.ti_le_doc(0)

	for c in cau:
		if Npc._la_chu_han(c):
			TriNho.hoc(c)
	_dung(n.ti_le_doc(0) > ti_truoc, "học chữ xong thì đọc được nhiều hơn (%.0f%% → %.0f%%)"
		% [ti_truoc * 100.0, n.ti_le_doc(0) * 100.0])
	_dung(n.hieu_duoc(0), "và HIỂU được câu — bản dịch mới lộ ra")
	_bang(n.cau_hien(0), cau, "đọc được hết thì thoại hiện trọn, không còn □")
	_dung(n.cau_nghia(0) != "", "câu nào cũng có bản dịch tiếng Việt")

	# Nghe hết chuyện thì NPC tặng chữ, MỘT LẦN.
	var hon_truoc := Tui.hon
	var lan1 := n.nhan_thuong()
	var hon_giua := Tui.hon
	var lan2 := n.nhan_thuong()
	_dung(hon_giua > hon_truoc, "nghe hết chuyện thì được hồn (%d → %d)"
		% [hon_truoc, hon_giua])
	_bang(lan2.size(), 0, "nghe lại lần hai KHÔNG ăn thưởng thêm")
	_bang(Tui.hon, hon_giua, "và không được thêm hồn")

# --- Mốc 7: âm thanh -------------------------------------------------

func _am_thanh() -> void:
	_nhom("Âm thanh (mốc 7)")
	# Game hiện KHÔNG PHÁT TIẾNG NÀO, và đó là chủ ý — tiếng tổng hợp bằng code
	# đã bị xoá vì nghe nhức đầu. Nên nhóm này KHÔNG canh "có phát ra tiếng";
	# nó canh ba thứ vẫn phải đúng để thả file .wav vào là chạy được ngay:
	#   1. bản kê tên tiếng còn nguyên — đó là danh sách việc cho người làm âm
	#   2. gọi phat() không bao giờ nổ, kể cả tên không tồn tại
	#   3. tên nào cũng nạp được nếu có file, và im nếu chưa có
	_dung(AmThanh.TIENG.size() >= 12, "có đủ bảng tiếng (%d tiếng)"
		% AmThanh.TIENG.size())
	for can in ["vung_nhe", "vung_nang", "trung", "do_phan", "chet", "gam_boss"]:
		_dung(AmThanh.TIENG.has(can), "có tiếng '%s'" % can)

	# Mỗi khoá phải kèm một dòng mô tả việc nó làm. Bản kê mà chỉ có tên thì
	# người thu âm không biết "trung_to" khác "trung" ở chỗ nào.
	var trong: Array[String] = []
	for ten in AmThanh.TIENG.keys():
		if String(AmThanh.TIENG[ten]).strip_edges().is_empty():
			trong.append(String(ten))
	_dung(trong.is_empty(), "tiếng nào cũng có mô tả việc nó làm%s"
		% ("" if trong.is_empty() else " — trống: " + " ".join(trong)))

	# Chưa thả file nào vào assets/tieng/ thì im lặng — đó là đường đi BÌNH
	# THƯỜNG lúc này, không phải hỏng.
	var co := 0
	for ten in AmThanh.TIENG.keys():
		if AmThanh.co_tieng(ten):
			co += 1
	_dung(true, "có %d/%d tiếng thật trong assets/tieng/ (0 là bình thường)"
		% [co, AmThanh.TIENG.size()])

	# Phát thử không được nổ, dù có file hay không.
	AmThanh.phat("trung")
	AmThanh.phat("gam_boss", 1.2, 0.8)
	AmThanh.phat("khong_co_tieng_nay")
	_dung(true, "gọi phat() không nổ, kể cả tên không tồn tại")

# --- Mốc 7: nội dung -------------------------------------------------

func _noi_dung_moc_7() -> void:
	_nhom("Nội dung (mốc 7)")
	_dung(VocabDB.quai.size() >= 18, "quai.csv đủ 18 loài (%d) — mục 12"
		% VocabDB.quai.size())
	var thieu_vung: Array[String] = []
	for v in VocabDB.vung:
		if VocabDB.quai_trong_vung(String(v["ma"])).is_empty():
			thieu_vung.append(String(v["ma"]))
	_dung(thieu_vung.is_empty(), "vùng nào cũng có quái%s"
		% ("" if thieu_vung.is_empty() else " — trống: " + " ".join(thieu_vung)))

	# BOSS 无 (mục 14.8): không hành, và vũ khí càng nhiều chữ càng yếu.
	var vo: Dictionary = {}
	for b in VocabDB.boss:
		if String(b.get("ngu_hanh", "")) == "":
			vo = b
	_dung(not vo.is_empty(), "boss.csv có một con KHÔNG HÀNH")
	if vo.is_empty():
		return
	var b2 := Boss.new()
	b2.ma = String(vo["ma"])
	b2.d = vo.duplicate()
	_dung(b2.khong_hanh(), "nhận ra nó bằng cột ngu_hanh trống, không bằng mã")

	# Cây vũ khí trần phải đau hơn cây khắc đầy chữ — đảo ngược đúng bài học
	# của cả game, và đó là cả câu đố.
	var tran := MonDo.new(["剑"], 1)
	var day_chu := MonDo.new(["长", "冰", "金", "剑"], 1)
	Tui.mac["vu_khi"][Tui.tay_phai_dang] = tran
	var st_tran := b2._sat_thuong_that(100)
	Tui.mac["vu_khi"][Tui.tay_phai_dang] = day_chu
	var st_day := b2._sat_thuong_that(100)
	_dung(st_tran > st_day,
		"vũ khí TRẦN đau hơn vũ khí khắc đầy chữ (%d so với %d)" % [st_tran, st_day])
	_bang(st_tran, 100, "vũ khí trần ăn trọn sát thương")
	_dung(st_day >= 1, "mà khắc đầy chữ vẫn gây được ít nhất 1 (%d)" % st_day)
	# Dọn tay: b2 là node dựng ngoài cây scene nên phải free() tay, và khe vũ
	# khí phải trả về trống, không thì hai món đồ dựng ở đây sống tới lúc thoát.
	Tui.mac["vu_khi"][Tui.tay_phai_dang] = null
	b2.free()
