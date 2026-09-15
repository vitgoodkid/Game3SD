extends Node

## Chạy thử VÒNG LẶP SOULS trong phòng thử thật. Chạy:
##
##     godot --headless --path . tools/thu_vong_lap.tscn
##
## Thoát mã 0 nếu tất cả qua, mã 1 nếu có cái hỏng.
##
## Vì sao tách khỏi tools/kiem_tra.tscn: bộ kia kiểm tầng luật, chạy trong một
## khung hình, không nạp scene nào. Còn mốc 4 là một chuỗi việc diễn ra theo
## THỜI GIAN qua nhiều node — chết, đợi 2.8 giây, rơi vũng hồn, đứng dậy ở bia,
## quái sống lại. Không có chỗ nào trong tầng luật kiểm được chuyện đó, mà hỏng
## thì hỏng cả mốc.
##
## Phím I bơm sự kiện thật vào Input, vì khâu NỐI PHÍM là chỗ duy nhất trong
## mốc này có thể sai một mình: màn hình dựng đúng, luật đúng, mà quên nối thì
## bấm I không ra gì. Phím E thì gọi thẳng hàm nó gọi — muốn bơm phím E phải
## đẩy nhân vật vào đúng tầm với của bia trước, và như thế là đi kiểm Area3D
## của Godot chứ không kiểm game nữa.

const CANH_PHONG := preload("res://scenes/the_gioi/phong_thu.tscn")

var _qua := 0
var _hong := 0
var _phong: Node3D = null
var _nc: NguoiChoi = null

func _ready() -> void:
	print("")
	print("====== THU VONG LAP SOULS ======")
	_phong = CANH_PHONG.instantiate()
	add_child(_phong)
	await get_tree().process_frame
	await get_tree().physics_frame
	_nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi

	await _dat_canh()
	await _the_luc_va_nut_danh()
	await _cam_ket_va_iframe()
	await _sieu_giap_va_phan_do()
	await _phan_nhin()
	await _phim_hanh_trang()
	await _quai_roi_do()
	await _nghi_bia_da()
	await _chet_va_hoi_sinh()
	await _nhat_lai_hon()
	await _may_trang_thai_quai()

	print("")
	print("====== %d qua, %d HONG ======" % [_qua, _hong])
	get_tree().quit(1 if _hong > 0 else 0)

# --- Khung kiểm tra -------------------------------------------------

func _dung(dieu_kien: bool, mo_ta: String) -> void:
	if dieu_kien:
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

## Bơm một phím vào như người chơi bấm thật, rồi đợi đủ lâu để nó chạy qua
## _unhandled_input. Gọi thẳng hàm thì không kiểm được khâu nối phím.
func _bam(hanh_dong: String) -> void:
	var su_kien := InputEventAction.new()
	su_kien.action = hanh_dong
	su_kien.pressed = true
	Input.parse_input_event(su_kien)
	await get_tree().process_frame
	await get_tree().process_frame

## Giữ một nút bấy nhiêu giây rồi nhả. Cần cho đòn nhẹ/nặng: cả hai đi ra từ
## CÙNG một nút, phân biệt nhau đúng ở chỗ giữ bao lâu.
func _giu(hanh_dong: String, giay: float) -> void:
	var xuong := InputEventAction.new()
	xuong.action = hanh_dong
	xuong.pressed = true
	Input.parse_input_event(xuong)
	await _cho(giay)
	var len_ := InputEventAction.new()
	len_.action = hanh_dong
	len_.pressed = false
	Input.parse_input_event(len_)
	await get_tree().process_frame
	await get_tree().process_frame

## Đợi máy trạng thái chắc chắn đã chạy. Một khung là chưa đủ: lúc await trả
## về có thể vẫn chưa tới lượt may.chay() của khung đó, và test đâm ra lúc qua
## lúc hỏng — đã dính một lần rồi.
func _hai_khung() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

## Bấm một nút và GIỮ NGUYÊN (hoặc nhả ra). Khác _giu() ở chỗ không tự nhả —
## cần cho giơ khiên, vì do_don.gd thoát ngay khi phím thôi được giữ.
func _nut(hanh_dong: String, giu: bool) -> void:
	var e := InputEventAction.new()
	e.action = hanh_dong
	e.pressed = giu
	Input.parse_input_event(e)
	await _hai_khung()

func _dem_nhom(ten: String) -> int:
	return get_tree().get_nodes_in_group(ten).size()

func _bia() -> BiaDa:
	var ds := get_tree().get_nodes_in_group("bia_da")
	return null if ds.is_empty() else ds[0] as BiaDa

# --- Các nhóm -------------------------------------------------------

func _dat_canh() -> void:
	_nhom("Phòng thử dựng lên đủ thứ")
	_dung(_nc != null, "có người chơi")
	_dung(_bia() != null, "có bia đá")
	# Phòng thử phát sẵn một vũ khí và một khiên. Không có khiên thì nửa hệ
	# phòng thủ (parry, đòn phản đỡ, vỡ đỡ) không thử tay được.
	_dung(Tui.vu_khi_dang_cam() != null, "vào phòng là đã cầm sẵn vũ khí")
	_dung(Tui.tay_trai_dang_cam() != null, "và đã cầm sẵn khiên")
	var kh_ = Tui.tay_trai_dang_cam()
	_bang(kh_.loai() if kh_ != null else "?", "khien", "món tay trái đúng là khiên")
	_dung(Tui.moveset_dang_dung() != "拳",
		"moveset theo vũ khí đang cầm chứ không phải tay không (%s)"
		% Tui.moveset_dang_dung())
	# Chữ trên đồ vẫn CHƯA đọc được — phát đồ sẵn không được phép tắt cơ chế ???
	var vk_ = Tui.vu_khi_dang_cam()
	_dung(vk_ != null and vk_.ten_hien().contains(TenDoVat.CHU_MO),
		"đồ phát sẵn vẫn hiện □, không tự dạy chữ kèm theo (%s)"
		% (vk_.ten_hien() if vk_ != null else "?"))
	_bang(_dem_nhom("quai"), 4, "bốn con quái đứng sẵn")
	_dung(_dem_nhom("vat_roi") >= 3, "có đồ nằm sẵn dưới đất (%d món)"
		% _dem_nhom("vat_roi"))
	_dung(not get_tree().get_nodes_in_group("man_bia_da").is_empty(), "có màn bia đá")
	_dung(not get_tree().get_nodes_in_group("man_hanh_trang").is_empty(),
		"có màn hành trang")

	# Nhặt một món: đây là thứ duy nhất làm túi có đồ lúc mới vào.
	var vr := get_tree().get_nodes_in_group("vat_roi")[0] as VatRoi
	var truoc := Tui.kho.size()
	vr.tuong_tac()
	_bang(Tui.kho.size(), truoc + 1, "nhặt được món đồ dưới đất")
	await get_tree().process_frame

## Phím I. Đây là thứ duy nhất trong mốc này chỉ sai được ở khâu NỐI: màn hình
## dựng đúng, luật đúng, mà quên nối phím thì bấm I không ra gì.
## Nhóm này canh quyết định "chỉ lăn / đỡ phản / chạy mới tốn thể lực", và
## canh chuyện một nút chuột trái ra được hai đòn. Cả hai đều là thứ rất dễ bị
## một lần sửa vô tình kéo ngược về cũ, mà chơi thử mới thấy — nên phải có test.
func _the_luc_va_nut_danh() -> void:
	_nhom("Thể lực và nút đánh")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	await get_tree().physics_frame

	# --- Bấm nhanh = đòn nhẹ, và TỐN thể lực (Elden Ring) ---
	var truoc := _nc.the_luc
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm nhanh chuột trái thì vào trạng thái đánh")
	var ton_nhe := truoc - _nc.the_luc
	_dung(ton_nhe > 0.0, "đòn nhẹ TỐN thể lực (%.0f điểm)" % ton_nhe)
	await _cho(1.6)

	# --- Đánh xong là hồi lại, KHÔNG khựng ---
	# Đây là chỗ hỏng cũ: mỗi lần tiêu đặt lại trọn 0.8s cấm hồi, ba nhát liên
	# tiếp là thanh thể lực đứng hình. Mô hình ER chờ từ lúc đòn KẾT THÚC.
	_dung(_nc.the_luc >= _nc.the_luc_max - 0.5,
		"đánh xong chờ một nhịp là hồi đầy lại (%.0f/%.0f)"
		% [_nc.the_luc, _nc.the_luc_max])

	# --- Giữ lâu = đòn nặng, tốn nhiều hơn đòn nhẹ ---
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	truoc = _nc.the_luc
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.12)
	await _hai_khung()
	_dung(_nc.may.ten_hien_tai == "danh", "giữ chuột trái cũng ra đòn — trạng thái: %s"
		% _nc.may.ten_hien_tai)
	var don: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_dung(don.begins_with("nang"), "giữ lâu ra đòn NẶNG (được '%s')" % don)
	_dung(truoc - _nc.the_luc > ton_nhe, "đòn nặng tốn NHIỀU HƠN đòn nhẹ (%.0f > %.0f)"
		% [truoc - _nc.the_luc, ton_nhe])
	await _cho(1.6)

	# --- Lăn thì tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	_nc.hoi_lan = 0.0
	truoc = _nc.the_luc
	await _giu("lan_chay", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "lan", "nhả Space sớm thì lăn")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_LAN, "lăn TỐN đúng THE_LUC_LAN")
	await _cho(1.2)

	# --- Đỡ phản thì tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	truoc = _nc.the_luc
	# Elden Ring KHÔNG cho parry tay không. Phòng thử giờ phát sẵn khiên, nên
	# phải cởi ra mới thử được vế "tay không thì không parry".
	_dat_khien(false)
	_dung(not _nc.co_khien(), "cởi khiên ra thì tay trái trống")
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "dung", "tay không thì chuột phải KHÔNG ra đỡ phản")
	_bang(_nc.the_luc, truoc, "và không mất thể lực oan")

	_dat_khien(true)
	_dung(_nc.co_khien(), "cầm khiên vào tay trái")
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "có khiên thì chuột phải ra đỡ phản")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_DO_PHAN,
		"đỡ phản TỐN đúng THE_LUC_DO_PHAN")
	await _cho(1.0)
	_dat_khien(false)

	# --- Cạn thể lực vẫn đánh được: đó là cả điểm của thay đổi này ---
	_nc.the_luc = 0.0
	_nc.tre_hoi = 0.0
	await get_tree().physics_frame
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh",
		"cạn sạch thể lực vẫn vung được nhát cuối — ER cũng cho")
	await _cho(1.2)
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0

## Bốn luật ghìm trận đánh, cả bốn đều không nhìn thấy trên màn hình và vì thế
## rất dễ bị nới ra lúc nào không ai hay: cam kết đòn, i-frame của cú lăn, đỡ
## phản, và vỡ tư thế. Từ khi đòn đánh thôi tốn thể lực thì CAM KẾT ĐÒN là thứ
## gần như duy nhất còn ghìm nhịp — nên nó phải có test, không thể chỉ có comment.
func _cam_ket_va_iframe() -> void:
	_nhom("Cam kết đòn và i-frame")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	# Nhóm này thử NGƯỜI CHƠI, nên bốn con quái phải đứng ngoài: mấy phép thử
	# dưới kéo dài hơn mười giây, thừa thời gian cho một con chạy tới đấm vào
	# giữa phép thử và đẩy nhân vật sang trạng thái trung_don. Bịt mắt chúng
	# thay vì xê dịch — xê dịch thì có con rơi khỏi sàn.
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	# --- Đã vung là không huỷ ---
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "vung đòn")
	await _giu("lan_chay", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm lăn GIỮA đòn không huỷ được đòn")
	await _cho(1.4)

	# --- Lăn qua đòn thì không dính ---
	_lam_moi_nguoi_choi()
	var mau_truoc := _nc.mau
	await _giu("lan_chay", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "lan", "nhả Space sớm là lăn")
	_dung(_nc.bat_tu, "đầu cú lăn là BẤT TỬ")
	_bang(_nc.an_don(50, 5.0, _truoc_mat()), 0, "ăn đòn giữa i-frame: 0 sát thương")
	_bang(_nc.mau, mau_truoc, "và máu không suy suyển")

	# Hết lăn là hết bất tử — nếu không thì lăn thành nút bất tử miễn phí.
	await _cho(1.0)
	_dung(not _nc.bat_tu, "lăn xong là hết bất tử")
	var an := _nc.an_don(50, 5.0, _truoc_mat())
	_dung(an > 0, "cùng đòn đó lúc đứng thì ăn thật (%d máu)" % an)
	_dung(_nc.mau < mau_truoc, "máu tụt thật")
	await _cho(1.0)

	# --- Đỡ phản trúng ---
	_lam_moi_nguoi_choi()
	_dat_khien(true)     # Elden Ring: không khiên thì không parry được
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "vào đỡ phản")
	_bang(_nc.an_don(50, 5.0, _truoc_mat()), -1,
		"đỡ phản TRÚNG trả -1 — dấu hiệu cho bên gọi bắt quái ngây ra")
	_bang(_nc.mau, _nc.mau_toi_da, "đỡ phản trúng thì không mất máu")
	await _cho(1.0)
	_dat_khien(false)

	# --- Vỡ tư thế ---
	_lam_moi_nguoi_choi()
	_nc.an_don(1, _nc.tu_the_max + 1.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "đầy thanh tư thế là VỠ THẾ")
	_bang(_nc.tu_the, 0.0, "vỡ xong thanh tư thế về 0")
	await _giu("lan_chay", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "đang vỡ thế thì bấm lăn cũng không thoát")
	# Ngây thật thì phải ngây THẬT, kể cả khi bị đánh tiếp. Đây là cả phần
	# thưởng của việc đánh dồn đúng nhịp: cửa sổ 2.6s đủ rộng để chạy tới kết
	# liễu. Một đòn vặt cắt ngang nó thành trung_don (ngắn hơn nhiều) là biến
	# hình phạt nặng nhất thành hình phạt nhẹ hơn cả trúng đòn thường.
	# Đòn phải đủ mạnh để bình thường VẪN gây khựng, nếu không phép thử này
	# xanh oan: SoulsLike.co_khung() chỉ khựng khi pha_the >= thế đứng.
	var manh := _nc.the_dung() + 1.0
	_nc.an_don(5, manh, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "bị đánh tiếp cũng KHÔNG cắt được vỡ thế")
	await _cho(SoulsLike.NGAY_SAU_VO + 0.3)
	_bang(_nc.may.ten_hien_tai, "dung", "ngây hết giờ thì đứng dậy")
	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Ba cơ chế lấy nguyên của Elden Ring, và cả ba đều vô hình trên màn hình.
##
##   siêu giáp   thế đứng TẠM THỜI trong mấy khung vung tay. Thiếu nó thì vũ
##               khí nặng vô dụng — vung 1.2 giây mà ai chạm cũng cắt được.
##   đòn phản đỡ vừa chặn được một đòn thì bấm đòn nặng ra đòn riêng. Đây là
##               thứ biến giơ khiên từ phòng thủ thuần thành nước đi tấn công.
##   vỡ đỡ       đỡ tới cạn thể lực thì choáng ra cho ăn kết liễu.
func _sieu_giap_va_phan_do() -> void:
	_nhom("Siêu giáp, đòn phản đỡ, vỡ đỡ")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	# --- Siêu giáp: đòn nặng của kiếm phải cõng được một đòn vặt ---
	var nen := _nc.the_dung()
	_bang(_nc.sieu_giap, 0.0, "đứng yên thì không có siêu giáp")
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.12)
	await _hai_khung()
	var don: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	var sg := float(VocabDB.don_cua(Tui.moveset_dang_dung(), don).get("sieu_giap", 0))
	_dung(sg > 0.0, "đòn nặng '%s' có siêu giáp trong moveset.csv (%.0f)" % [don, sg])
	_dung(_nc.sieu_giap > 0.0, "đang vung đòn nặng thì siêu giáp BẬT (%.0f)" % _nc.sieu_giap)
	_dung(_nc.the_dung() > nen, "thế đứng lúc vung cao hơn lúc đứng yên (%.0f > %.0f)"
		% [_nc.the_dung(), nen])

	# Một đòn vặt mạnh hơn thế đứng thường, nhưng yếu hơn siêu giáp → không cắt.
	_nc.an_don(1, nen + 1.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "đòn vặt KHÔNG cắt được đòn đang vung")

	# Đòn to hơn cả siêu giáp thì vẫn cắt được — siêu giáp không phải bất tử.
	_nc.an_don(1, _nc.the_dung() + 1.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "trung_don", "đòn to hơn siêu giáp thì vẫn cắt được")
	await _cho(1.2)
	_lam_moi_nguoi_choi()

	# --- Siêu giáp phải TẮT trong khung hồi, nếu không thì đánh là bất khả xâm phạm ---
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.12)
	await _cho(1.1)
	_bang(_nc.sieu_giap, 0.0, "hết khung gây sát thương là siêu giáp TẮT")
	await _cho(0.8)
	_lam_moi_nguoi_choi()

	# --- Đòn phản đỡ ---
	_dat_khien(true)
	await _nut("do_don", true)
	_bang(_nc.may.ten_hien_tai, "do_don", "giơ khiên lên")
	_bang(_nc.cho_phan_do, 0.0, "chưa đỡ được gì thì chưa có cửa sổ phản đỡ")
	var mau_truoc := _nc.mau
	_nc.an_don(40, 5.0, _truoc_mat())
	_dung(_nc.mau > mau_truoc - 40.0, "đỡ được thì ăn ít sát thương hơn")
	_dung(_nc.cho_phan_do > 0.0, "đỡ TRÚNG thì mở cửa sổ đòn phản (%.2fs)"
		% _nc.cho_phan_do)
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.12)
	await _hai_khung()
	var pd: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_bang(pd, "phan_do", "bấm đòn nặng trong cửa sổ đó ra ĐÒN PHẢN")
	var m_pd := VocabDB.don_cua(Tui.moveset_dang_dung(), "phan_do")
	var m_nhe := VocabDB.don_cua(Tui.moveset_dang_dung(), "nhe_1")
	_dung(float(m_pd["pha_the"]) == float(m_nhe["pha_the"]) * 6.0,
		"đòn phản phá thế gấp 6 lần đòn nhẹ — đúng tỉ lệ ER (%d vs %d)"
		% [int(m_pd["pha_the"]), int(m_nhe["pha_the"])])
	await _cho(1.2)

	# --- Vỡ đỡ: đỡ tới cạn thể lực thì choáng ---
	await _nut("do_don", false)
	_lam_moi_nguoi_choi()
	await _nut("do_don", true)
	_nc.the_luc = 1.0
	_nc.an_don(90, 5.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "đỡ tới cạn thể lực là VỠ ĐỠ")
	await _nut("do_don", false)
	await _cho(SoulsLike.NGAY_SAU_VO + 0.3)
	_dat_khien(false)
	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Phần NHÌN. Hai lỗi chơi thật mới lộ ra, cả hai đều không phải lỗi luật —
## luật chạy đúng, chỉ là màn hình không nói ra:
##
##   · khiên mặc rồi mà thân nhân vật không vẽ ⇒ tưởng chưa mặc được
##   · bảy loại đòn dùng chung một cung vung ⇒ giữ chuột ra đòn nặng mà nhìn
##     y hệt đòn nhẹ, tưởng giữ không ăn thua
##
## Thứ không nhìn thấy thì coi như không có, dù con số bên dưới đã đúng.
func _phan_nhin() -> void:
	_nhom("Phần nhìn: khiên và dáng đòn")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	var tk := _nc.than as ThanKhoi
	if tk == null:
		_dung(false, "không có thân khối")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	# --- Khiên phải HIỆN khi mặc, TẮT khi cởi ---
	_dat_khien(false)
	await _hai_khung()
	_dung(not tk._khien.visible, "cởi khiên thì thân không vẽ khiên")
	_dat_khien(true)
	await _hai_khung()
	_dung(tk._khien.visible, "mặc khiên vào thì thân VẼ khiên ra")

	# --- Mỗi loại đòn một dáng riêng ---
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.hien_tai.ten_dien(), "nhe_1", "bấm nhanh: phần nhìn biết là đòn nhẹ")
	await _cho(1.4)

	# Giữ chuột: phải báo "nap" trong lúc còn giữ, không phải tên đòn.
	var e := InputEventAction.new()
	e.action = "don_nhe"
	e.pressed = true
	Input.parse_input_event(e)
	var t_vung_nang := float(VocabDB.don_cua(Tui.moveset_dang_dung(), "nang").get("t_vung", 0.4))
	await _cho(NguoiChoi.NGUONG_GIU_NANG + t_vung_nang + 0.15)
	_bang(_nc.may.hien_tai.ten_dien(), "nap",
		"còn giữ chuột thì phần nhìn báo ĐANG NẠP — dáng giữ, không phải dáng vung")
	e = InputEventAction.new()
	e.action = "don_nhe"
	e.pressed = false
	Input.parse_input_event(e)
	await _hai_khung()
	_dung(_nc.may.hien_tai.ten_dien().begins_with("nang"),
		"nhả ra thì báo đòn nặng (%s)" % _nc.may.hien_tai.ten_dien())
	await _cho(1.6)

	# --- ĐÒN PHẢI TRÚNG THẬT, và đòn nặng phải đau hơn đòn nhẹ ---
	#
	# Phép thử này canh cái bẫy vừa dính: hộp đòn TỪNG bị kéo theo cánh tay
	# diễn hoạt ảnh, nên thêm một cái nghiêng người cho đòn nặng trông nặng
	# hơn là cả game hết trúng đòn — im lặng, không lỗi nào, test luật vẫn
	# xanh vì luật có sai đâu. Giờ hộp đòn đứng yên ở ngực; nếu ai gắn lại nó
	# vào khớp bị xoay thì phép thử này đỏ ngay.
	_lam_moi_nguoi_choi()
	var q := _quai_de_danh()
	if q == null:
		_dung(false, "không có quái để thử trúng đòn")
	else:
		var mat_nhe := await _danh_thu(q, 0.05)
		_dung(mat_nhe > 0.0, "bấm nhanh: đòn TRÚNG thật (%.0f máu)" % mat_nhe)
		var mat_nang := await _danh_thu(q, NguoiChoi.NGUONG_GIU_NANG + 0.13)
		_dung(mat_nang > 0.0, "giữ chuột: đòn TRÚNG thật (%.0f máu)" % mat_nang)
		_dung(mat_nang > mat_nhe, "và đòn giữ ĐAU HƠN đòn bấm nhanh (%.0f > %.0f)"
			% [mat_nang, mat_nhe])
		# Nhịp trận đánh: quái thường phải chết trong ÍT đòn, không thì người
		# chơi đứng cào cấu và tưởng máu nó vô hạn. Đo thật trước khi sửa:
		# 48–50 đòn nhẹ mới hạ nổi một con thường, trong khi nó giết mình
		# trong 13. Canh cả hai đầu — quá ít đòn thì trận đánh cũng vô nghĩa.
		var so_don := ceilf(q.mau_toi_da / maxf(mat_nhe, 0.001))
		_dung(q.con_song(), "bao cát vẫn sống qua cả hai nhát")
		_dung(so_don >= 2.0 and so_don <= 14.0,
			"hạ một con quái thường mất %d đòn nhẹ (muốn 2–14, kiểu Elden Ring)"
			% int(so_don))

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Kéo một con quái còn sống ra làm bao cát, và tắt não nó đi.
func _quai_de_danh() -> Quai:
	for n in get_tree().get_nodes_in_group("quai"):
		var q := n as Quai
		if q != null and q.con_song():
			q.nguoi_choi = null
			q.may.doi("quai_dung")
			return q
	return null

## Đặt quái ngay trước mặt rồi vung một đòn, trả về số máu nó mất.
func _danh_thu(q: Quai, giu: float) -> float:
	# Bơm máu bao cát lên thật cao rồi trả lại: từ khi sát thương được quy về
	# đúng thang, một nhát nhẹ đủ hạ con yếu nhất — và nhát thứ hai của phép
	# thử sẽ đánh vào cái xác, đo ra 0.
	var mau_that := q.mau_toi_da
	q.mau_toi_da = 100000.0
	q.mau = q.mau_toi_da
	q.global_position = _nc.global_position + _nc.huong_mat() * 1.4
	# Cho nó QUAY MẶT LẠI. Đánh sau lưng nhân 2.6 lần (mục 5.1), mà con số cần
	# đo ở đây là nhịp đánh CHÍNH DIỆN — đánh lén thì con nào cũng chết nhanh.
	var ve := _nc.global_position - q.global_position
	ve.y = 0.0
	if ve.length_squared() > 0.001:
		q.rotation.y = atan2(ve.x, ve.z)
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	await _hai_khung()
	await _giu("don_nhe", giu)
	for i in 150:
		await get_tree().physics_frame
		if q.mau < q.mau_toi_da:
			break
	var mat := q.mau_toi_da - q.mau
	q.mau_toi_da = mau_that
	q.mau = mau_that
	await _cho(1.5)
	return mat

## Máy trạng thái quái. Chạy CUỐI CÙNG vì nó xê dịch và hạ quái — mấy nhóm
## trước đếm đúng bốn con.
func _may_trang_thai_quai() -> void:
	_nhom("Máy trạng thái quái")
	var ds := get_tree().get_nodes_in_group("quai")
	if ds.is_empty():
		_dung(false, "không còn con quái nào để thử")
		return
	var q := ds[0] as Quai
	var cho_cu := q.global_position

	# --- Thấy người chơi thì đuổi ---
	q.global_position = _nc.global_position + Vector3(0, 0, 3.0)
	await _hai_khung()
	_dung(q.thay_nguoi_choi(), "đứng sát thì quái thấy người chơi")
	q.may.doi("quai_dung")
	await _hai_khung()
	_bang(q.may.ten_hien_tai, "quai_dung", "chưa lao ra ngay — có khoảng chờ")
	# quai_dung cố ý chờ CHO_TRUOC_KHI_DUOI giây để người chơi kịp thấy nó
	# ngẩng đầu lên. Chờ hụt là test đỏ oan.
	await _cho(0.7)
	_bang(q.may.ten_hien_tai, "quai_duoi", "chờ hết khoảng đó thì đuổi")

	# --- Mất dấu thì về chỗ, KHÔNG đứng ngây tại chỗ vừa mất dấu ---
	q.global_position = _nc.global_position + Vector3(0, 0, 60.0)
	await _hai_khung()
	_dung(not q.thay_nguoi_choi(), "kéo ra xa thì quái mất dấu")
	await _hai_khung()
	_bang(q.may.ten_hien_tai, "quai_ve_cho", "mất dấu thì quay về chỗ cũ")

	# --- Bị đỡ phản thì đứng ngây đúng NGAY_SAU_DO_PHAN ---
	q.bi_do_phan()
	await _hai_khung()
	_bang(q.may.ten_hien_tai, "quai_vo_the", "bị đỡ phản là đứng ngây")
	_dung(q.dang_ngay, "cờ dang_ngay bật — đây là thứ cho phép kết liễu")

	# Đánh một đòn vặt vào con đang ngây: cửa sổ kết liễu KHÔNG được ngắn đi.
	# Đây là phần thưởng cho việc đỡ phản trúng, mà đỡ phản là kỹ năng cao
	# nhất người chơi học được — cắt ngắn nó là rút ngược phần thưởng.
	q.an_don(1, float(q.d.get("the_dung", 30)) + 1.0, _nc.global_position)
	await _hai_khung()
	_bang(q.may.ten_hien_tai, "quai_vo_the", "đánh thêm một đòn không cắt được cửa sổ đó")

	# --- Hết máu thì chết ---
	q.global_position = cho_cu
	q.may.doi("quai_dung")
	var con := _dem_nhom("quai")
	q.an_don(int(q.mau_toi_da) + 50, 1.0, _nc.global_position)
	await _hai_khung()
	_bang(q.may.ten_hien_tai, "quai_chet", "hết máu là vào trạng thái chết")
	_dung(not q.con_song(), "và con_song() trả false")
	_dung(_dem_nhom("quai") <= con, "xác không tự nhân bản (còn %d con)"
		% _dem_nhom("quai"))

## Cho quái tạm thôi nhìn thấy người chơi (và đứng yên tại chỗ), rồi trả lại.
## thay_nguoi_choi() trả false khi nguoi_choi == null, nên đây là cái công tắc
## rẻ nhất — không đụng vào vị trí, không có con nào rơi khỏi sàn.
func _bit_mat_quai(bit: bool) -> void:
	for n in get_tree().get_nodes_in_group("quai"):
		var q := n as Quai
		if q == null or not q.con_song():
			continue
		q.nguoi_choi = null if bit else _nc
		if bit:
			q.may.doi("quai_dung")

## Nhét một cái khiên vào tay trái, hoặc lấy ra. Khiên là điều kiện để parry
## và là thứ quyết định đỡ tốn bao nhiêu thể lực (Elden Ring).
func _dat_khien(co: bool) -> void:
	if not co:
		Tui.mac["tay_trai"][Tui.tay_trai_dang] = null
		Tui.doi_trang_bi.emit()
		return
	TriNho.hoc("盾")
	var khien := MonDo.new(["盾"], 1)
	Tui.mac["tay_trai"][Tui.tay_trai_dang] = khien
	Tui.doi_trang_bi.emit()

## Đưa người chơi về trạng thái sạch giữa hai phép thử — đầy máu, đầy thể lực,
## không còn khựng, không còn dư i-frame hay hồi lăn của cú trước.
func _lam_moi_nguoi_choi() -> void:
	_nc.mau = _nc.mau_toi_da
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	_nc.tu_the = 0.0
	_nc.hoi_lan = 0.0
	_nc.bat_tu = false
	_nc.may.doi("dung")

## Một điểm ngay trước mặt nhân vật. Đòn đánh tới từ phía sau tính khác (đỡ
## không ăn, nhân hệ số sau lưng), nên phép thử phải nói rõ đòn tới từ đâu.
func _truoc_mat() -> Vector3:
	return _nc.global_position + _nc.huong_mat() * 2.0

func _phim_hanh_trang() -> void:
	_nhom("Phím I mở hành trang")
	var man := get_tree().get_nodes_in_group("man_hanh_trang")[0] as ManChung
	_dung(not man.dang_mo, "chưa bấm thì màn đóng")

	await _bam("hanh_trang")
	_dung(man.dang_mo, "bấm I là hành trang mở ra")
	_dung(man.ve_xong, "mở ra là vẽ trọn")
	_dung(get_tree().paused, "mở hành trang cũng dừng game")
	_bang(ManChung.dang_mo_man, man, "màn này ghi tên mình là màn đang mở")

	await _bam("hanh_trang")
	_dung(not man.dang_mo, "bấm I lần nữa là đóng")
	_dung(not get_tree().paused, "đóng là game chạy lại")

	await _bam("hanh_trang")
	_dung(man.dang_mo, "mở lại lần nữa")
	await _bam("thoat")
	_dung(not man.dang_mo, "Esc cũng đóng được")
	_dung(ManChung.dang_mo_man == null, "đóng xong thì không còn màn nào đang mở")

## Quái rơi đồ ra đất. Xác suất nên gọi nhiều lần: cái cần canh không phải con
## số xác suất mà là món rơi ra CÓ THẬT — dựng được node, thả được vào scene.
func _quai_roi_do() -> void:
	_nhom("Quái rơi đồ")
	var q := get_tree().get_nodes_in_group("quai")[0] as Quai
	var truoc := _dem_nhom("vat_roi")
	for i in 200:
		q._roi_mon_do()
	await get_tree().process_frame
	_dung(_dem_nhom("vat_roi") > truoc, "gọi 200 lần thì có món rơi ra đất (%d món)"
		% (_dem_nhom("vat_roi") - truoc))
	# Dọn sạch, không thì mấy trăm món nằm lại làm nhiễu các nhóm sau.
	for v in get_tree().get_nodes_in_group("vat_roi"):
		v.queue_free()
	await get_tree().process_frame

func _nghi_bia_da() -> void:
	_nhom("Nghỉ ở bia đá")
	var bia := _bia()
	_dung(not TheGioi.bia_da_bat(bia.ma), "bia chưa bật lúc mới vào")

	# Hạ một con quái trước, để thấy nghỉ ở bia là nó sống lại.
	var q := get_tree().get_nodes_in_group("quai")[0] as Quai
	q.an_don(99999, 0.0, Vector3.ZERO)
	await _cho(2.0)
	_bang(_dem_nhom("quai"), 3, "hạ một con thì còn ba")

	Tui.mau = 1.0
	bia.tuong_tac()
	_dung(TheGioi.bia_da_bat(bia.ma), "bấm E là bật bia")
	_bang(TheGioi.bia_hien_tai, bia.ma, "bia này thành điểm hồi sinh")
	_dung(get_tree().paused, "mở màn bia đá là game DỪNG")
	_bang(Tui.mau, Tui.mau_toi_da(), "nghỉ là hồi đầy máu")
	_bang(Tui.binh_con, Tui.binh_toi_da, "nghỉ là đầy bình")

	var man := get_tree().get_nodes_in_group("man_bia_da")[0] as ManBiaDa
	_dung(man.dang_mo, "màn bia đá mở ra")
	_dung(man.ve_xong, "màn bia đá vẽ trọn thẻ đầu")
	man.dong()
	_dung(not get_tree().paused, "đóng màn là game chạy lại")
	await get_tree().process_frame
	_bang(_dem_nhom("quai"), 4, "nghỉ ở bia thì quái sống lại HẾT")

func _chet_va_hoi_sinh() -> void:
	_nhom("Chết, rơi hồn, đứng dậy")
	Tui.hon = 500
	var xa_bia := _nc.global_position
	_nc.mat_mau(99999)
	_bang(_nc.may.ten_hien_tai, "chet", "hết máu là vào trạng thái chết")
	await _cho(0.5)
	_bang(Tui.hon, 0, "chết là mất sạch hồn đang cầm")
	_dung(TheGioi.co_vung_hon(), "hồn rơi lại thành vũng")
	_bang(_dem_nhom("vung_hon"), 1, "có đúng một vũng hồn trong scene")
	var vung := get_tree().get_nodes_in_group("vung_hon")[0] as VungHon
	_bang(vung.so_hon, 500, "vũng giữ đúng 500 hồn")
	_dung(vung.global_position.distance_to(xa_bia) < 1.0,
		"vũng nằm đúng chỗ ngã xuống")

	# chet.gd đợi 2.8 giây rồi mới gọi hồi sinh.
	await _cho(3.2)
	_bang(_nc.may.ten_hien_tai, "dung", "sống lại thì về trạng thái đứng")
	_dung(not _nc.bat_tu, "sống lại thì hết bất tử — không được sót cờ này")
	_bang(_nc.mau, _nc.mau_toi_da, "sống lại là đầy máu")
	_dung(_nc.global_position.distance_to(_bia().diem_hoi_sinh()) < 0.6,
		"đứng dậy ngay cạnh bia đá")
	_bang(_dem_nhom("quai"), 4, "chết cũng làm quái sống lại hết")
	_bang(_dem_nhom("vung_hon"), 1, "vũng hồn vẫn nằm đó chờ về nhặt")

func _nhat_lai_hon() -> void:
	_nhom("Về nhặt lại")
	var vung := get_tree().get_nodes_in_group("vung_hon")[0] as VungHon

	# CÁI XÁC KHÔNG NHẶT ĐƯỢC HỒN CỦA CHÍNH NÓ.
	#
	# Vũng hồn mọc ngay tại chỗ ngã xuống, nên cái xác nằm trọn trong tầm với
	# của nó suốt 2.8 giây trước khi đứng dậy ở bia. Bấm E lúc đó là nhặt lại
	# sạch — mất trắng thành ra không mất gì, và cả mục 4.5 sụp theo. Phải bơm
	# phím E THẬT: gọi thẳng vung.tuong_tac() thì đi vòng qua đúng chỗ hỏng.
	var hon_truoc := Tui.hon
	vung.nguoi_choi = _nc
	vung.trong_tam = true
	if not TuongTacDuoc.dang_trong_tam.has(vung):
		TuongTacDuoc.dang_trong_tam.append(vung)

	# "chet" phải nằm ngoài danh sách cho phép. Kiểm bằng chính hàm đó chứ
	# không ép state: vào state chet là chạy lại cả luồng chết (rơi vũng mới,
	# hồi sinh), phép thử tự gây nhiễu cho mình.
	_dung(not ("chet" in NguoiChoi.TRANG_THAI_TUONG_TAC),
		"trạng thái 'chet' KHÔNG nằm trong danh sách bấm E được")

	# Diễn lại bằng vỡ thế — cùng một đường chặn, mà không có tác dụng phụ.
	_nc.may.doi("vo_the")
	await _hai_khung()
	_dung(not _nc.tuong_tac_duoc(), "đang ngây thì không bấm E được")
	_dung(not vung.la_gan_nhat(), "và vũng hồn không mời bấm E")
	await _bam("tuong_tac")
	_bang(Tui.hon, hon_truoc, "bấm E cũng KHÔNG nhặt được")
	_bang(_dem_nhom("vung_hon"), 1, "vũng vẫn còn nguyên đó")

	_nc.may.doi("dung")
	await _hai_khung()
	_dung(_nc.tuong_tac_duoc(), "đứng dậy rồi thì bấm E được")
	# Không kiểm vung.la_gan_nhat() ở đây: lúc này người chơi vừa đứng dậy Ở
	# BIA ĐÁ, nên bia mới là thứ gần nhất chứ không phải vũng — đó là luật
	# "một phím E chỉ ăn vào cái gần nhất", không phải lỗi.
	vung.tuong_tac()
	_bang(Tui.hon, 500, "nhặt lại đủ 500 hồn")
	_dung(not TheGioi.co_vung_hon(), "nhặt xong thì hết vũng")
	await get_tree().process_frame

	# Chết lần nữa khi đang cầm hồn: vũng mới mọc ở chỗ mới.
	Tui.hon = 120
	_nc.mat_mau(99999)
	await _cho(0.5)
	_bang(_dem_nhom("vung_hon"), 1, "chết lần hai chỉ có MỘT vũng")
	_bang(TheGioi.so_hon_trong_vung(), 120, "vũng mới giữ số hồn mới")
	await _cho(3.2)
