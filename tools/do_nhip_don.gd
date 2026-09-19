extends Node3D

## ĐO NHỊP ĐÒN TỪ CHÍNH CLIP — máy suy ra `moveset.csv`, không phải tay gõ.
##
##     godot --headless --path . tools/do_nhip_don.tscn
##
## Vì sao có file này. Dự án từng đi chiều ngược lại: CSV khai nhịp, rồi
## `ThanMoHinh._toc_do()` co giãn clip cho vừa. Cái giá là mỗi clip bị kéo dãn
## một hệ số khác nhau — cú Bổ bị ép chạy nhanh **2.25 lần** — nên động tác
## đọc ra như tua nhanh, và không ai nhìn con số mà biết được.
##
## Giờ clip làm chủ: máy này đo xem trong clip lưỡi kiếm THẬT SỰ quét qua thân
## con quái vào giây thứ mấy, rồi in ra đúng bốn con số của CSV. Người chỉ việc
## chép.
##
## Ba thứ nó đo, và cả ba đều đo trên LƯỠI KIẾM chứ không trên xương tay: hộp
## đòn ăn theo thanh kiếm, mà thanh kiếm thì dài và xoay, nên cổ tay đi một
## đằng mũi kiếm đi một nẻo.
##
##   QUÃNG CHÉM   lưỡi đang bổ TỚI TRƯỚC hoặc XUỐNG DƯỚI nhanh, và nằm trong
##                tầm cao thân quái. Đây là `t_dam_tu` → `t_dam_den`.
##
##                Phải xét HƯỚNG chứ không xét tốc độ thô, và đây là chỗ bản
##                đầu của máy này đo sai. Cú vung tay lên lấy đà cũng nhanh
##                ngang cú chém — trong `danh_1` lưỡi giật về sau ở 0.21–0.42s
##                nhanh 10.4 m/s, còn cú chém ở 0.58–0.79s nhanh 14.3 m/s.
##                Đo tốc độ thô thì gom cả hai thành một quãng chém dài 0.79s
##                trên một clip 1.27s, tức là gần như lúc nào cũng gây sát
##                thương. Chỉ phần đi VỀ PHÍA con quái mới là cú chém.
##   HẾT ĐỘNG     giây cuối cùng lưỡi còn nhúc nhích (≥ `NGUONG_IM`). Phần sau
##                đó là đệm điện ảnh của clip mua sẵn — clip Bổ nằm chết dí ở
##                đáy gần một giây — và nó KHÔNG được tính vào `t_hoi`, không
##                thì mỗi nhát chém người chơi phải đứng chờ một nhịp thừa.
##   TẦM VỚI      lưỡi với xa nhất về trước bao nhiêu mét. Đây là `tam_voi`.
##
## Con quái cao khoảng 1.6m (cột `cao` của `quai.csv`), nên tầm cao thân là
## quãng `CAO_THAP`–`CAO_CAO`.

const CANH_NC := preload("res://scenes/nhan_vat/nguoi_choi.tscn")

## Vũ khí đem ra đo. Phải là vũ khí SỞ HỮU bộ clip — mọi clip trong
## `assets/model/dong_tac/` đều là clip great sword, tức là của 刃. Đo bằng vũ
## khí đang mượn clip thì ra số của clip người khác.
const CHU_VU_KHI := "刃"

## Lấy bao nhiêu mẫu dọc clip. 120 mẫu trên một clip 4.8s là mỗi 40ms — đủ mịn
## để bắt đúng khung lưỡi kiếm vào và ra khỏi thân quái.
const SO_MAU := 120

const CAO_THAP := 0.30
const CAO_CAO := 1.60

## Nhanh tới mức nào thì tính là ĐANG CHÉM, theo phần của đỉnh.
const NGUONG_CHEM := 0.35
## Chậm hơn bấy nhiêu mét/giây thì tính là lưỡi ĐỨNG IM.
##
## Tuyệt đối chứ KHÔNG theo phần của đỉnh. Đỉnh tốc độ của một cú chém vọt lên
## rất cao và mỗi clip một khác, nên lấy theo tỉ lệ thì cùng một dáng thu tay
## chỗ này tính là "còn động" chỗ kia tính là "đã chết" — bảng số ra vô nghĩa.
const NGUONG_IM := 0.50
## Phải im liên tục bấy nhiêu giây mới tính là một QUÃNG CHẾT. Ngắn hơn thì đó
## chỉ là khoảnh khắc lưỡi đổi chiều, không phải chỗ clip nằm chờ.
const IM_DAI := 0.15

## Quãng chém hẹp nhất chấp nhận được.
##
## Lấy 120 mẫu thì đỉnh vận tốc nhọn tới mức quãng liền mạch quanh nó co về
## đúng MỘT mẫu, và hộp đòn bật/tắt trong cùng một khung hình — tức là không
## bao giờ trúng ai. Chạm sàn này thì nới đều hai bên quanh đỉnh.
const CHEM_HEP_NHAT := 0.10

## LƯỠI KIẾM về lại chỗ nó đứng ở khung đầu, sai số dưới bấy nhiêu mét, thì
## coi như cú vung đã xong — phần clip sau đó không diễn gì nữa.
##
## Đo trên lưỡi kiếm chứ không trên cả bộ xương, cho nhất quán với mọi phép đo
## khác của đòn đánh: thanh kiếm dài 1.5m nên nó phóng đại mọi sai lệch của
## vai và cổ tay, còn trung bình trên 58 xương thì một cái đầu ngoẹo cũng đủ
## kéo con số xuống dưới ngưỡng trong khi tay vẫn đang thu về.
const VE_DANG_DAU := 0.12

## Làm trơn vận tốc qua bấy nhiêu mẫu trước khi tìm quãng.
##
## Vận tốc tính bằng sai phân giữa hai mẫu liền nhau nên nó nhiễu, mà mẫu càng
## mịn thì càng nhiễu — nghịch lý đúng của phép đo này. Trung bình trượt cắt
## nhiễu mà không xê dịch mốc, vì cửa sổ đối xứng.
const TRON := 3

## Đòn nào đo bằng clip nào. Đọc thẳng từ `ThanMoHinh.DONG_TAC_DON` để không
## có bảng thứ hai đi lạc khỏi bảng thật.
const DON := ["nhe_1", "nhe_2", "nhe_3", "nang", "chay", "nhay", "nhay_nang",
	"phan_do"]

var _nc: Node3D = null
var _than: Node = null
var _may: AnimationPlayer = null

func _ready() -> void:
	var vk := SinhMonDo.sinh_mon_tu_chu(CHU_VU_KHI, "thi_tran", 1000)
	if vk != null:
		Tui.nhat(vk)
		Tui.mac_vao(vk, "vu_khi", 0)
		Tui.tay_phai_dang = 0
	_nc = CANH_NC.instantiate() as Node3D
	add_child(_nc)
	for i in 4:
		await get_tree().process_frame
	_than = _nc.get_node_or_null("Than")
	if _than == null or not _than.has_method("dien"):
		push_error("Khong tim thay Than co dien()")
		get_tree().quit(1)
		return
	# Tắt vòng lặp của nhân vật: `_dien_hinh()` chạy mỗi nhịp vật lý và sẽ
	# giành lại AnimationPlayer ngay sau mỗi lần tua.
	_nc.set_physics_process(false)
	_may = _tim_may(_than)
	if _may == null:
		push_error("Khong tim thay AnimationPlayer")
		get_tree().quit(1)
		return

	print("")
	print("=== NHỊP ĐÒN ĐO TỪ CLIP — vũ khí %s ===" % CHU_VU_KHI)
	print("")
	print("| đòn | clip | dài | quãng chém | dài THẬT | quãng chết | tầm với |")
	print("|---|---|---|---|---|---|---|")
	var ra: Array = []
	for don in DON:
		var d := await _do(don)
		if not d.is_empty():
			ra.append(d)
	print("")
	_in_csv(ra)
	await _do_than()
	if OS.get_cmdline_user_args().has("--trace"):
		for don in DON:
			await _trace(don)
	get_tree().quit()

## Clip KHÔNG phải đòn đánh: lăn, đỡ phản, rút/cất vũ khí.
##
## Đo bằng XƯƠNG CHẬU chứ không bằng lưỡi kiếm. Mấy động tác này là chuyển
## động của cả người — cú lăn cuộn nguyên khối, cú rút kiếm thì thân gần như
## đứng yên — nên thanh kiếm không nói lên được gì. Xương chậu là gốc của mọi
## chuyển động còn lại, và nó không bị nhiễu bởi tay vung.
const THAN := ["lan", "do_phan", "rut_vu_khi", "cat_vu_khi", "trung_don",
	"vo_the", "nhay", "ket_lieu"]

func _tu_the() -> Array:
	var x: Skeleton3D = _than.get("_xuong")
	if x == null:
		return []
	var ra: Array = []
	for i in x.get_bone_count():
		ra.append(x.get_bone_global_pose(i).origin)
	return ra

## Bao nhiêu mét chênh lệch giữa hai tư thế, cộng trên mọi xương.
func _lech(a: Array, b: Array) -> float:
	if a.size() != b.size() or a.is_empty():
		return 0.0
	var t := 0.0
	for i in a.size():
		t += (a[i] as Vector3).distance_to(b[i] as Vector3)
	return t / float(a.size())

func _do_than() -> void:
	print("=== CLIP KHÔNG PHẢI ĐÒN ĐÁNH (đo theo xương chậu) ===")
	print("")
	print("| clip | dài | quãng ĐỘNG | dài THẬT | quãng chết |")
	print("|---|---|---|---|---|")
	for ten in THAN:
		if not _may.has_animation(ten):
			continue
		var dai: float = _may.get_animation(ten).length
		var vi: Array = []
		for n in SO_MAU:
			await _tua(ten, dai * float(n) / float(SO_MAU - 1))
			vi.append(_tu_the())
		var buoc := dai / float(SO_MAU - 1)
		var tho: Array = [0.0]
		for i in range(1, vi.size()):
			tho.append(_lech(vi[i], vi[i - 1]) / buoc)
		var toc := _tron(tho)

		# Quãng ĐỘNG: từ mẫu đầu tới mẫu cuối còn nhúc nhích.
		var dau := -1.0
		var cuoi := 0.0
		for i in toc.size():
			if float(toc[i]) >= NGUONG_IM:
				if dau < 0.0:
					dau = buoc * float(i)
				cuoi = buoc * float(i)
		if dau < 0.0:
			dau = 0.0

		# Quãng chết Ở GIỮA (hai đầu đã bị cắt bởi `dau`/`cuoi` rồi).
		var chet: Array = []
		var i_im := -1
		for i in range(1, toc.size() + 1):
			var im: bool = i < toc.size() and float(toc[i]) < NGUONG_IM
			if im:
				if i_im < 0:
					i_im = i
			elif i_im >= 0:
				var d0 := buoc * float(i_im)
				var d1 := buoc * float(i - 1)
				if d1 - d0 >= IM_DAI and d0 > dau and d1 < cuoi:
					chet.append([d0, d1])
				i_im = -1
		var bo_qua := 0.0
		for c in chet:
			bo_qua += float(c[1]) - float(c[0])
		var ke := ""
		for c in chet:
			ke += "%.2f–%.2f " % [float(c[0]), float(c[1])]
		print("| %s | %.2fs | %.2f–%.2fs | %.2fs | %s |"
			% [ten, dai, dau, cuoi, cuoi - dau - bo_qua,
				ke if ke != "" else "—"])
	print("")

## Tư thế của TOÀN BỘ bộ xương, gộp thành một vector để so hai mẫu.
##
## Không đo riêng xương chậu: nửa số clip ở đây là động tác của TAY — rút
## kiếm, cất kiếm, đỡ phản — và trong chúng cái chậu đứng im hoàn toàn, nên
## phép đo trả về "clip dài 0.00 giây". Cộng hết mọi xương thì clip nào động
## chỗ nào cũng đọc được.

## In thô từng mẫu của một clip. Chỉ để soi bằng mắt khi ngưỡng đo có vẻ sai.
func _trace(don: String) -> void:
	var clip := String(ThanMoHinh.DONG_TAC_DON.get(don, ""))
	if clip == "" or not _may.has_animation(clip):
		return
	var dai: float = _may.get_animation(clip).length
	print("\n--- %s / %s (%.2fs) ---" % [don, clip, dai])
	var truoc := Vector3.ZERO
	for n in 25:
		var giay := dai * float(n) / 24.0
		await _tua(clip, giay)
		var m := _do_luoi()
		var d: Vector3 = ((m["tam"] as Vector3) - truoc) / (dai / 24.0)
		var v := 0.0 if n == 0 else d.length()
		var b := 0.0 if n == 0 else maxf(d.z, 0.0) + maxf(-d.y, 0.0)
		truoc = m["tam"]
		print("  %5.2fs  cao=%5.2f thap=%5.2f voi=%5.2f  toc=%6.2f  bo=%6.2f" % [
			giay, m["cao"], m["thap"], m["voi"], v, b])

## Quét một clip, trả về bốn con số của CSV.
func _do(don: String) -> Dictionary:
	var clip := String(ThanMoHinh.DONG_TAC_DON.get(don, ""))
	if clip == "" or not _may.has_animation(clip):
		return {}
	var dai: float = _may.get_animation(clip).length

	# Đặt thế cầm vũ khí trước, và đợi nó ỔN ĐỊNH HẲN.
	#
	# `_keo_the_cam()` nội suy thế cầm trong `T_DOI_THE_CAM` giây, nên vài
	# khung đầu thanh kiếm còn đang trôi về chỗ. Lấy mẫu trong lúc đó là đo
	# trúng cú trôi chứ không đo clip, và vì số khung trôi phụ thuộc nhịp
	# khung hình nên chạy hai lần ra hai bảng khác nhau — đã dính đúng vậy.
	for i in 30:
		_than.call("dien", "danh", 0.0, false, 1.0 / 60.0, don, 0.0, 0.0)
		await get_tree().process_frame

	var mau: Array = []
	for n in SO_MAU:
		var giay := dai * float(n) / float(SO_MAU - 1)
		await _tua(clip, giay)
		mau.append(_do_luoi())

	var buoc := dai / float(SO_MAU - 1)
	# Hai thước đo, cố ý khác nhau:
	#   `toc`  tốc độ THÔ — dùng để biết lưỡi đã đứng hẳn chưa.
	#   `bo`   phần vận tốc đi VỀ PHÍA con quái (tới trước + xuống dưới) —
	#          dùng để biết đang chém hay đang lấy đà. Lấy đà là đi ngược lại,
	#          nên nó rơi về 0 ở thước này dù tốc độ thô vẫn cao.
	var toc_tho: Array = [0.0]
	var bo_tho: Array = [0.0]
	for i in range(1, mau.size()):
		var v: Vector3 = ((mau[i]["tam"] as Vector3)
			- (mau[i - 1]["tam"] as Vector3)) / buoc
		toc_tho.append(v.length())
		bo_tho.append(maxf(v.z, 0.0) + maxf(-v.y, 0.0))
	var toc := _tron(toc_tho)
	var bo := _tron(bo_tho)
	var dinh_toc := 0.0
	var dinh_bo := 0.0
	var i_dinh := 0
	for i in bo.size():
		dinh_toc = maxf(dinh_toc, float(toc[i]))
		if float(bo[i]) > dinh_bo:
			dinh_bo = float(bo[i])
			i_dinh = i
	if dinh_bo < 0.01:
		return {}

	# QUÃNG CHÉM: quãng LIỀN MẠCH quanh đỉnh, không phải mọi mẫu trên ngưỡng.
	#
	# Liền mạch mới đúng: một cú vung có đúng MỘT lần lưỡi đi qua thân con
	# quái. Gom mọi mẫu trên ngưỡng thì cú thu chiêu ở cuối clip cũng lọt vào,
	# và `t_dam_den` bị kéo tới tận cuối — hộp đòn bật suốt cả cú thu tay.
	var a_dau := i_dinh
	while a_dau > 0 and float(bo[a_dau - 1]) >= dinh_bo * NGUONG_CHEM:
		a_dau -= 1
	var a_cuoi := i_dinh
	while a_cuoi < bo.size() - 1 and float(bo[a_cuoi + 1]) >= dinh_bo * NGUONG_CHEM:
		a_cuoi += 1
	# Cắt hai đầu cho tới khi lưỡi thật sự phủ tầm cao thân quái.
	while a_dau < a_cuoi and not _phu(mau[a_dau]):
		a_dau += 1
	while a_cuoi > a_dau and not _phu(mau[a_cuoi]):
		a_cuoi -= 1
	# Nới cho đủ sàn bề rộng, đều hai bên quanh đỉnh.
	while (a_cuoi - a_dau) * buoc < CHEM_HEP_NHAT:
		if a_dau > 0 and (a_cuoi >= bo.size() - 1 or float(bo[a_dau - 1]) >= float(bo[a_cuoi + 1])):
			a_dau -= 1
		elif a_cuoi < bo.size() - 1:
			a_cuoi += 1
		else:
			break
	var tu := buoc * float(a_dau)
	var den := buoc * float(a_cuoi)

	# QUÃNG CHẾT: chỗ lưỡi nằm im đủ lâu. Đây là phần đệm điện ảnh của clip
	# mua sẵn — clip Bổ nằm chết dí ở đáy gần một giây trước khi thu tay về —
	# và nó phải bị NHẢY QUA, không phải bị cắt cụt ở đó: đoạn thu tay nằm
	# SAU quãng chết, mà đoạn thu tay chính là khung hồi đòn.
	var chet: Array = []
	var i_im := -1
	for i in range(1, mau.size() + 1):
		var im: bool = i < mau.size() and float(toc[i]) < NGUONG_IM
		if im:
			if i_im < 0:
				i_im = i
		elif i_im >= 0:
			var d0 := buoc * float(i_im)
			var d1 := buoc * float(i - 1)
			# Báo CẢ quãng trước cú chém. Với clip Bổ thì quãng im trước cú
			# chém chính là đoạn GIỮ Ở ĐỈNH, và đó vừa là chỗ cú gồng ghim
			# vào vừa là chỗ phải nhảy qua khi đánh thường — xem
			# `ThanMoHinh.CAT_CHET`. Lọc nó đi ở đây là giấu mất nửa câu
			# trả lời.
			if d1 - d0 >= IM_DAI:
				chet.append([d0, d1])
			i_im = -1

	# ĐUÔI CLIP SAU KHI ĐÃ VỀ DÁNG ĐẦU cũng là phần chết.
	#
	# Clip mua sẵn khép kín: khung cuối trùng khung đầu để ghép vòng được. Nên
	# sau khi thu tay xong nó còn lửng lơ thêm một quãng ở đúng dáng đứng, và
	# quãng ấy tính vào khung hồi thì đòn nặng của 刃 dài 4.0 giây — không
	# đánh nhau được. Cắt từ lúc tư thế đã về gần dáng đầu; phần còn thiếu để
	# trông liền mạch thì 0.12s hoà clip sang dáng đứng lo nốt.
	# Quét XUÔI từ sau cú chém, dừng ở mẫu ĐẦU TIÊN thấy lưỡi đã về chỗ.
	#
	# Quét ngược từ khung cuối thì hỏng: khung cuối của clip Bổ không trùng
	# khung đầu (lưỡi cao 2.03m so với 1.70m), nên phép so vấp ngay bước thứ
	# nhất và cả cái đuôi 1.4 giây đứng dậy không bị cắt — đòn nặng dài 4.0
	# giây. Cái cần tìm là chỗ cú vung KẾT THÚC, không phải chỗ clip kết thúc.
	var i_ve := -1
	for i in mau.size():
		if buoc * float(i) <= den:
			continue
		# Phải VỀ CHỖ **và** ĐÃ DỪNG. Thiếu vế thứ hai thì bắt trúng lúc lưỡi
		# mới chỉ đi ngang qua chỗ nghỉ trên đường thu về — nó còn đang bay,
		# và cắt ở đó là cụt mất cú thu chiêu: `danh_1` rớt khung hồi từ
		# 0.49s xuống 0.24s.
		if _lech_luoi(mau[i], mau[0]) <= VE_DANG_DAU \
				and float(toc[i]) < NGUONG_IM:
			i_ve = i
			break
	if i_ve > 0:
		chet.append([buoc * float(i_ve), dai])

	# Tổng thời gian THẬT của cú đánh = độ dài clip trừ phần chết.
	var bo_qua := 0.0
	for c in chet:
		bo_qua += float(c[1]) - float(c[0])
	var het := dai - bo_qua
	# `t_hoi` chỉ tính phần SAU cú chém, nên quãng chết nằm trước nó không
	# được trừ vào đây — nó đã nằm ngoài khoảng [t_dam_den, hết] rồi.
	var truoc := 0.0
	for c in chet:
		if float(c[1]) <= den:
			truoc += float(c[1]) - float(c[0])

	var voi := 0.0
	for m in mau:
		voi = maxf(voi, float(m["voi"]))

	var ke := ""
	for c in chet:
		ke += "%.2f–%.2f " % [float(c[0]), float(c[1])]
	print("| %s | %s | %.2fs | %.2f–%.2fs | %.2fs | %s | %.2fm |"
		% [don, clip, dai, tu, den, het, ke if ke != "" else "—", voi])
	# `t_vung` = chỗ CÚ VUNG TAY KẾT THÚC, không phải chỗ cú chém bắt đầu.
	#
	# Hai mốc này trùng nhau ở mọi đòn thường, nhưng KHÁC nhau ở đòn gồng
	# được: clip Bổ tự nó có một quãng đứng im giữa cú giơ lên và cú bổ
	# xuống, và đó chính là đỉnh — chỗ `TrangThaiDanh._chay_nap()` ghim lại
	# khi người chơi còn giữ chuột. Lấy `t_vung` = `t_dam_tu` ở đây là ghim
	# NHẦM vào giữa cú bổ, và cú gồng đứng hình với thanh kiếm lửng lơ nửa
	# đường xuống.
	var dinh_giu := tu
	for c in chet:
		if float(c[1]) <= tu:
			dinh_giu = minf(dinh_giu, float(c[0]))
	return {"don": don, "clip": clip, "t_vung": dinh_giu, "t_dam_tu": tu - truoc,
		"t_dam_den": den - truoc, "t_hoi": maxf(het - (den - truoc), 0.05),
		"tam_voi": voi,
		"chet": chet}

## Trung bình trượt, cửa sổ `TRON` mẫu, đối xứng nên không xê dịch mốc.
func _tron(v: Array) -> Array:
	var ra: Array = []
	var r := TRON / 2
	for i in v.size():
		var tong := 0.0
		var dem := 0
		for k in range(maxi(0, i - r), mini(v.size(), i + r + 1)):
			tong += float(v[k])
			dem += 1
		ra.append(tong / float(dem))
	return ra

## Lưỡi kiếm ở hai mẫu lệch nhau bao nhiêu mét.
func _lech_luoi(a: Dictionary, b: Dictionary) -> float:
	return maxf(maxf(absf(float(a["cao"]) - float(b["cao"])),
		absf(float(a["thap"]) - float(b["thap"]))),
		absf(float(a["voi"]) - float(b["voi"])))

## Lưỡi có phủ qua tầm cao thân con quái ở mẫu này không.
func _phu(m: Dictionary) -> bool:
	return float(m["thap"]) < CAO_CAO and float(m["cao"]) > CAO_THAP

## Bốn con số của thanh kiếm ở tư thế hiện tại, trong hệ của nhân vật.
func _do_luoi() -> Dictionary:
	var cao := -9.0
	var thap := 9.0
	var voi := -9.0
	var tong := Vector3.ZERO
	var dem := 0
	for m in _mesh_vu_khi():
		var ab: AABB = (m as MeshInstance3D).get_aabb()
		for k in 8:
			var p: Vector3 = (m.global_transform * ab.get_endpoint(k)) \
				- _nc.global_position
			cao = maxf(cao, p.y)
			thap = minf(thap, p.y)
			voi = maxf(voi, p.z)
			tong += p
			dem += 1
	if dem == 0:
		return {"cao": 0.0, "thap": 0.0, "voi": 0.0, "tam": Vector3.ZERO}
	return {"cao": cao, "thap": thap, "voi": voi, "tam": tong / float(dem)}

## Tua clip tới đúng giây rồi ÁP tư thế.
##
## `advance(0.0)` chứ KHÔNG `pause()` — xem ghi chú cùng chỗ trong
## `soi_luoi_kiem.gd`: `pause()` chặn luôn việc áp tư thế, nên mọi lần tua sau
## đó không ăn và cả bảng số ra y hệt nhau.
func _tua(clip: String, giay: float) -> void:
	if _may.current_animation != clip:
		_may.play(clip)
	_may.speed_scale = 0.0
	_may.seek(giay, true)
	_may.advance(0.0)
	# HAI khung, không phải một. `seek()` đặt thời gian, nhưng tư thế xương chỉ
	# thật sự nằm đúng chỗ sau khi Skeleton3D xử lý xong — đợi một khung thì
	# thỉnh thoảng đọc trúng tư thế của mẫu TRƯỚC, và vận tốc tính ra nhiễu
	# theo. Triệu chứng: chạy hai lần ra hai bảng số khác nhau, quãng chết lúc
	# có lúc không. Phép đo mà không lặp lại được thì không phải phép đo.
	await get_tree().process_frame
	await get_tree().process_frame

## In ra đúng phần cần chép vào `data/moveset.csv`.
func _in_csv(ra: Array) -> void:
	print("=== CHÉP VÀO data/moveset.csv (dòng %s) ===" % CHU_VU_KHI)
	print("")
	print("%-12s %8s %9s %10s %7s %9s" % ["don", "t_vung", "t_dam_tu",
		"t_dam_den", "t_hoi", "tam_voi"])
	for d in ra:
		print("%-12s %8.2f %9.2f %10.2f %7.2f %9.2f" % [d["don"], d["t_vung"],
			d["t_dam_tu"], d["t_dam_den"], d["t_hoi"], d["tam_voi"]])
	print("")
	print("=== CHÉP VÀO ThanMoHinh.CAT_CHET ===")
	print("")
	var da := {}
	for d in ra:
		var c: Array = d["chet"]
		if c.is_empty() or da.has(d["clip"]):
			continue
		da[d["clip"]] = true
		var ke := ""
		for x in c:
			ke += "[%.2f, %.2f], " % [float(x[0]), float(x[1])]
		print('\t"%s": [%s],' % [d["clip"], ke.trim_suffix(", ")])
	if da.is_empty():
		print("\t(không clip nào có quãng chết)")
	print("")
	print("Cú NẠP (`nang_nap`) dùng chung clip với `nang`, nên nó KHÔNG có nhịp")
	print("riêng để đo — phần giữ ở đỉnh dài bao lâu là do người chơi quyết.")

## Mọi mesh của VŨ KHÍ. Chúng nằm dưới `BoneAttachment3D`, khác hẳn mesh thân —
## đó là cách phân biệt duy nhất không phải đoán theo tên node.
func _mesh_vu_khi() -> Array:
	var ra: Array = []
	for g in _tim_gan(_than):
		ra.append_array(_mesh(g))
	return ra

func _tim_gan(n: Node) -> Array:
	var ra: Array = []
	if n is BoneAttachment3D:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_tim_gan(c))
	return ra

func _mesh(n: Node) -> Array:
	var ra: Array = []
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_mesh(c))
	return ra

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null
