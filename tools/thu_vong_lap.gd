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
	# Khựng hình bóp `Engine.time_scale`, mà cả bộ thử này đo bằng đồng hồ —
	# bật suốt thì mỗi cú đánh kéo dài mọi phép chờ phía sau nó. Tắt mặc định,
	# và bật lại đúng trong nhóm đi kiểm chính nó.
	KhungDung.bat = false
	_phong = CANH_PHONG.instantiate()
	# Phòng thử MẶC ĐỊNH TRỐNG quái (chủ dự án chốt — nó là chỗ soi động tác).
	# Bộ kiểm tra thì cần cả năm con lẫn boss, nên tự bật lên. Gán TRƯỚC
	# `add_child()`: `_ready()` của phòng đọc cờ này, mà `_ready()` chạy ngay
	# lúc vào cây.
	_phong.co_quai = true
	add_child(_phong)
	await get_tree().process_frame
	await get_tree().physics_frame
	_nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi

	await _dat_canh()
	await _the_luc_va_nut_danh()
	await _cam_ket_va_iframe()
	await _nut_moi_va_don_nhay()
	await _rut_cat_vu_khi()
	await _toc_do_va_bam_chan()
	await _don_nang_de_gay()
	await _khoa_muc_tieu_strafe()
	await _cua_so_huy_va_khung_dung()
	await _nhip_combo()
	await _bo_dem_va_uu_tien()
	await _mp_va_giao_dien()
	await _sieu_giap_va_phan_do()
	await _mot_nut_phong_thu()
	await _phan_nhin()
	await _let_khi_nap()
	await _leo_tuong()
	await _phim_hanh_trang()
	await _quai_roi_do()
	await _nghi_bia_da()
	await _chet_va_hoi_sinh()
	await _nhat_lai_hon()
	await _may_trang_thai_quai()
	await _boss_hai_giai_doan()
	# CHẠY CUỐI CÙNG, và phải ở cuối. Nhóm này nghỉ ở bia đá và nạp lại save,
	# mà cả hai việc đó đều đặt lại bảng quái của cả phòng thử — nhóm nào chạy
	# sau nó sẽ đếm ra NĂM con quái ở chỗ vừa hạ còn bốn.
	await _luu_va_nap()

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
##
## NHẢ RA Ở CUỐI, và đó không phải chi tiết thừa. Bản trước chỉ bơm cú BẤM rồi
## bỏ đó, nên `Input.is_action_pressed()` của phím ấy còn bật tới hết buổi
## chạy. Bao lâu nay vô hại vì không ai hỏi phím nào đang giữ; từ khi đỡ và đỡ
## phản chung một nút thì `do_phan` bị hỏi mỗi khung, và một cú `_bam` bỏ quên
## sẽ khoá nhân vật đứng giơ khiên suốt phần còn lại của bộ thử.
func _bam(hanh_dong: String) -> void:
	var su_kien := InputEventAction.new()
	su_kien.action = hanh_dong
	su_kien.pressed = true
	Input.parse_input_event(su_kien)
	await get_tree().process_frame
	var len_ := InputEventAction.new()
	len_.action = hanh_dong
	len_.pressed = false
	Input.parse_input_event(len_)
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
## Đợi phím kịp đi hết đường và state kịp đổi.
##
## Phải có CẢ `process_frame`: sự kiện phím đi qua `_unhandled_input`, chạy ở
## khung hình chứ không ở nhịp vật lý. Bản trước chỉ đợi hai nhịp vật lý, và
## khi nhịp vật lý lên 120Hz thì hai nhịp đó chỉ còn 16ms — ngắn hơn một khung
## hình, nên có lần phím chưa tới nơi mà phép thử đã hỏi.
##
## Hỏng kiểu đó không đỏ đều: nó đỏ một lần trong vài chục lượt chạy, ở một
## phép thử khác nhau mỗi lần, và trông y như "bộ thử chập chờn".
## Đợi phím kịp đi hết đường và state kịp đổi.
##
## Phải có CẢ `process_frame`: sự kiện phím đi qua `_unhandled_input`, chạy ở
## khung hình chứ không ở nhịp vật lý. Bản trước chỉ đợi hai nhịp vật lý, và
## khi nhịp vật lý lên 120Hz thì hai nhịp đó chỉ còn 16ms — ngắn hơn một khung
## hình, nên có lần phím chưa tới nơi mà phép thử đã hỏi. Hỏng kiểu đó không đỏ
## đều: nó đỏ một lần trong vài chục lượt, ở một phép thử khác nhau mỗi lần, và
## trông y như "bộ thử chập chờn".
func _hai_khung() -> void:
	await get_tree().process_frame
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

## Bấm Space MỘT lần rồi đợi hết cửa sổ bấm đôi ⇒ lệnh NHẢY.
func _space_nhay() -> void:
	await _giu("lan_nhay", 0.03)
	await _cho(NguoiChoi.NGUONG_BAM_DOI + 0.06)
	await _hai_khung()

## Bấm Space HAI lần sát nhau ⇒ lệnh LĂN, bắn ra ngay ở lần thứ hai.
func _space_lan() -> void:
	await _giu("lan_nhay", 0.02)
	await _giu("lan_nhay", 0.02)
	await _hai_khung()

func _dem_nhom(ten: String) -> int:
	# Boss nằm trong CẢ nhóm "quai" lẫn nhóm "boss" (nó kế thừa Quai). Mọi phép
	# đếm quái thường phải chừa nó ra, không thì bốn con hoá thành năm.
	if ten == "quai":
		return _quai_thuong().size()
	return get_tree().get_nodes_in_group(ten).size()

## Quái thường đang còn trong scene — không tính boss.
func _quai_thuong() -> Array:
	var ds: Array = []
	for n in get_tree().get_nodes_in_group("quai"):
		if not n.is_in_group("boss"):
			ds.append(n)
	return ds

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
	# Phòng thử phát KIẾM HAI TAY (xem `phong_thu.CHU_VU_KHI_DAU`), mà hai tay
	# thì tay trái bận giữ chuôi — không cầm khiên được. Đó là cái giá của vũ
	# khí lớn, và phép thử phải nói đúng như vậy.
	_dung(Tui.dang_cam_hai_tay(), "vũ khí khởi đầu là loại CẦM HAI TAY")
	_dung(Tui.tay_trai_dang_cam() == null,
		"cầm hai tay thì tay trái trả null — không khiên, không đòn phản đỡ")
	# Từ đây trở đi ghim về vũ khí MỘT TAY: cả bộ kiểm tra đo nhịp combat theo
	# nó, xem `_dat_vu_khi()`.
	_dat_vu_khi("剑")
	_dung(not Tui.dang_cam_hai_tay(), "ghim về vũ khí một tay để đo nhịp")
	_dung(Tui.moveset_dang_dung() != "拳",
		"moveset theo vũ khí đang cầm chứ không phải tay không (%s)"
		% Tui.moveset_dang_dung())
	# Chữ trên đồ vẫn CHƯA đọc được — phát đồ sẵn không được phép tắt cơ chế ???
	var vk_ = Tui.vu_khi_dang_cam()
	_dung(vk_ != null and vk_.ten_hien().contains(TenDoVat.CHU_MO),
		"đồ phát sẵn vẫn hiện □, không tự dạy chữ kèm theo (%s)"
		% (vk_.ten_hien() if vk_ != null else "?"))
	# Năm con: hai bù nhìn tập (đứng yên) + ba con tuần tra thật. Xem
	# `PhongThu.DAT_QUAI` — thêm bớt quái ở đó thì sửa con số này theo.
	_bang(_dem_nhom("quai"), 5, "năm con quái đứng sẵn")
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
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "lan", "bấm đôi Space thì lăn")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_LAN, "lăn TỐN đúng THE_LUC_LAN")
	await _cho(1.2)

	# --- Đỡ phản thì tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	truoc = _nc.the_luc
	# Parry KHÔNG cần khiên nữa (chủ dự án chốt, ngược ER — xem TIEN_DO.md).
	# Cởi khiên ra rồi thử: phải vào được đỡ phản y như lúc có khiên.
	_dat_khien(false)
	_dung(not _nc.co_khien(), "cởi khiên ra thì tay trái trống")
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "TAY KHÔNG vẫn bấm chuột phải ra đỡ phản")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_DO_PHAN,
		"đỡ phản TỐN đúng THE_LUC_DO_PHAN")
	await _cho(1.0)

	_nc.the_luc = _nc.the_luc_max
	_nc.tre_hoi = 0.0
	truoc = _nc.the_luc
	_dat_khien(true)
	_dung(_nc.co_khien(), "cầm khiên vào tay trái")
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "có khiên thì cũng ra đỡ phản")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_DO_PHAN,
		"tốn đúng bấy nhiêu, có khiên hay không không đổi")
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
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm lăn GIỮA đòn không huỷ được đòn")
	await _cho(1.4)

	# --- Lăn qua đòn thì không dính ---
	_lam_moi_nguoi_choi()
	var mau_truoc := _nc.mau
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "lan", "bấm đôi Space là lăn")
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

	# --- Đỡ phản trúng: HAI BẬC ---
	#
	# Đặt thẳng may.t thay vì đợi đồng hồ thật: hai cửa sổ cách nhau 0.10s, mà
	# một khung hình đã là 0.017s — đợi thật thì phép thử đâm ra lúc qua lúc
	# hỏng tuỳ máy chạy nhanh chậm. Đặt t là đúng thứ state đọc, nên vẫn thử
	# đúng cơ chế chứ không đi đường tắt nào.
	_lam_moi_nguoi_choi()
	_dat_khien(true)

	# Bậc HOÀN HẢO — nửa đầu cửa sổ perfect.
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "vào đỡ phản")
	_nc.may.t = SoulsLike.cua_so_perfect * 0.4
	await _hai_khung()
	_dung(_nc.do_phan_hoan_hao, "trong cửa sổ perfect thì cờ hoàn hảo bật")
	var tl_truoc := _nc.the_luc
	_bang(_nc.an_don(50, 5.0, _truoc_mat()), -2,
		"parry HOÀN HẢO trả -2 — bên gọi cho quái ngây NGAY_SAU_PERFECT")
	_bang(_nc.mau, _nc.mau_toi_da, "parry hoàn hảo thì không mất máu")
	_dung(_nc.the_luc > tl_truoc, "parry hoàn hảo HOÀN LẠI thể lực (%.0f → %.0f)"
		% [tl_truoc, _nc.the_luc])
	_dung(_nc.the_luc <= _nc.the_luc_max,
		"nhưng không vượt trần — parry không được SINH ra thể lực")
	await _cho(1.0)

	# Bậc THƯỜNG — đã qua cửa sổ perfect, còn trong cửa sổ parry.
	_lam_moi_nguoi_choi()
	await _bam("do_phan")
	await _hai_khung()
	_nc.may.t = SoulsLike.cua_so_perfect + 0.02
	await _hai_khung()
	_dung(not _nc.do_phan_hoan_hao, "qua cửa sổ perfect thì cờ hoàn hảo tắt")
	_dung(_nc.dang_do_phan, "nhưng vẫn còn trong cửa sổ parry thường")
	_bang(_nc.an_don(50, 5.0, _truoc_mat()), -1,
		"parry THƯỜNG trả -1 như cũ")
	_bang(_nc.mau, _nc.mau_toi_da, "parry thường cũng không mất máu")
	await _cho(1.0)

	# Bấm HỤT — quá cả cửa sổ parry thì ăn đòn thật. Không có vế này thì hai vế
	# trên chỉ chứng minh "bấm E là bất tử".
	_lam_moi_nguoi_choi()
	await _bam("do_phan")
	await _hai_khung()
	_nc.may.t = SoulsLike.cua_so_do_phan + 0.02
	await _hai_khung()
	_dung(not _nc.dang_do_phan, "quá cửa sổ parry thì hết đỡ được")
	_dung(_nc.an_don(50, 5.0, _truoc_mat()) > 0, "và ăn đòn THẬT — parry hụt có giá")
	await _cho(1.0)
	_dat_khien(false)

	# --- Vỡ tư thế ---
	_lam_moi_nguoi_choi()
	_nc.an_don(1, _nc.tu_the_max + 1.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "đầy thanh tư thế là VỠ THẾ")
	_bang(_nc.tu_the, 0.0, "vỡ xong thanh tư thế về 0")
	await _space_lan()
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

	# --- Siêu giáp: ĐÒN NHẢY NẶNG phải cõng được một đòn vặt ---
	#
	# Dùng đòn nhảy nặng chứ không dùng đòn nặng dưới đất, vì đòn nặng dưới đất
	# GIỜ CỐ Ý KHÔNG CÓ GIÁP (chủ dự án chốt — xem nhóm "Đòn Bổ không có giáp").
	# Cơ chế siêu giáp thì vẫn còn và vẫn phải đúng, nên phép thử dọn sang một
	# đòn còn khai siêu giáp trong CSV.
	var nen := _nc.the_dung()
	_bang(_nc.sieu_giap, 0.0, "đứng yên thì không có siêu giáp")
	await _space_nhay()
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.08)
	await _hai_khung()
	var don: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	var sg := float(VocabDB.don_cua(Tui.moveset_dang_dung(), don).get("sieu_giap", 0))
	_dung(sg > 0.0, "đòn '%s' có siêu giáp trong moveset.csv (%.0f)" % [don, sg])
	_dung(_nc.sieu_giap > 0.0, "đang vung thì siêu giáp BẬT (%.0f)" % _nc.sieu_giap)
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
	await _cho(1.4)
	_lam_moi_nguoi_choi()

	# --- Siêu giáp phải TẮT trong khung hồi, nếu không thì đánh là bất khả xâm phạm ---
	await _space_nhay()
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.08)
	await _cho(1.4)
	_bang(_nc.sieu_giap, 0.0, "hết khung gây sát thương là siêu giáp TẮT")
	await _cho(0.8)
	_lam_moi_nguoi_choi()

	# --- Đòn phản đỡ ---
	_dat_khien(true)
	# MỘT NÚT: bấm ra parry trước, GIỮ tiếp mới thành giơ khiên. Phải đợi hết
	# cửa sổ parry rồi mới đo, không thì đòn dưới rơi trúng cửa sổ parry và
	# nhóm này đo nhầm sang cơ chế khác.
	await _nut("do_phan", true)
	await _cho(SoulsLike.cua_so_do_phan + 0.06)
	_bang(_nc.may.ten_hien_tai, "do_don", "giữ chuột phải đủ lâu thì giơ khiên lên")
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
	await _nut("do_phan", false)
	_lam_moi_nguoi_choi()
	await _nut("do_phan", true)
	await _cho(SoulsLike.cua_so_do_phan + 0.06)
	_nc.the_luc = 1.0
	_nc.an_don(90, 5.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "vo_the", "đỡ tới cạn thể lực là VỠ ĐỠ")
	await _nut("do_phan", false)
	await _cho(SoulsLike.NGAY_SAU_VO + 0.3)
	_dat_khien(false)
	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## MỘT NÚT gánh cả đỡ lẫn đỡ phản (chuột phải), và parry cắt được đòn lẫn lăn.
##
## Năm thứ nhóm này canh, cả năm đều là chuyện CẢM GIÁC mà không nhóm nào khác
## với tới: gõ nhanh khác giữ ra sao, ngón tay giữ sẵn có được tặng một cửa sổ
## parry không, và parry có thật sự cắt được khung hồi đòn với cú lăn không.
func _mot_nut_phong_thu() -> void:
	_nhom("Một nút: đỡ + đỡ phản")
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()
	_dat_khien(true)

	# --- Phím cũ trống THẬT, không phải chỉ đổi nhãn ---
	_dung(not InputMap.has_action("do_don"),
		"action 'do_don' không còn — đỡ gộp hẳn vào nút đỡ phản")
	_bang(GiaoDien.ten_moi_phim("do_phan"), "Chuột phải",
		"và đỡ/đỡ phản còn đúng MỘT phím")

	# --- GÕ NHANH: parry rồi ĐỨNG NGÂY, đúng hình phạt cũ ---
	await _bam("do_phan")
	_bang(_nc.may.ten_hien_tai, "do_phan", "gõ nhanh ra đỡ phản")
	await _cho(SoulsLike.cua_so_do_phan + 0.06)
	_bang(_nc.may.ten_hien_tai, "do_phan",
		"hết cửa sổ parry mà đã nhả nút thì VẪN đứng ngây, chưa ra khiên")
	await _cho(SoulsLike.hoi_do_phan + 0.12)
	_bang(_nc.may.ten_hien_tai, "dung", "ngây xong mới về đứng")

	# --- GIỮ: parry rồi LÊN KHIÊN ngay, bỏ qua khung ngây ---
	_lam_moi_nguoi_choi()
	await _nut("do_phan", true)
	_bang(_nc.may.ten_hien_tai, "do_phan", "giữ nút cũng ra đỡ phản trước")
	await _cho(SoulsLike.cua_so_do_phan + 0.06)
	_bang(_nc.may.ten_hien_tai, "do_don",
		"còn giữ thì hết cửa sổ parry là LÊN KHIÊN, bỏ qua khung ngây")
	_dung(SoulsLike.hoi_do_phan > 0.0,
		"và khung ngây bỏ qua được là khung có thật (%.2fs)" % SoulsLike.hoi_do_phan)

	# --- Ngón tay GIỮ SẴN từ trước KHÔNG được tặng một cú parry ---
	_nc.may.doi("dung")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_don",
		"đang giữ sẵn thì vào thẳng giơ khiên, không phát parry không ai bấm")
	await _nut("do_phan", false)
	_bang(_nc.may.ten_hien_tai, "dung", "nhả nút là hạ khiên")
	_dat_khien(false)

	# --- Parry CẮT được khung hồi đòn, y như lăn ---
	_lam_moi_nguoi_choi()
	await _giu("don_nhe", 0.05)
	var vao_danh := false
	for i in range(240):
		await get_tree().physics_frame
		if _nc.may.ten_hien_tai == "danh":
			vao_danh = true
			break
	_dung(vao_danh, "vung được một đòn nhẹ")
	var mo_ne := false
	for i in range(600):
		await get_tree().physics_frame
		if _nc.may.ten_hien_tai != "danh":
			break
		if bool(_nc.may.hien_tai.call("cho_ne")):
			mo_ne = true
			break
	_dung(mo_ne, "cú đánh chạy tới đoạn 4, cửa sổ rút ra MỞ")
	_nc.ghi_dem("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan",
		"bấm parry ở đó là CẮT đòn ngay, không phải đợi hết animation")
	await _cho(SoulsLike.cua_so_do_phan + SoulsLike.hoi_do_phan + 0.2)

	# --- Parry CẮT được cú LĂN, kể cả giữa khung bất tử ---
	_lam_moi_nguoi_choi()
	_nc.hoi_lan = 0.0
	_nc.may.doi("lan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "lan", "vào cú lăn")
	_dung(_nc.bat_tu, "và đang trong khung bất tử")
	_nc.ghi_dem("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "bấm parry giữa cú lăn là CẮT được")
	_dung(not _nc.bat_tu, "cắt sớm thì mất luôn phần bất tử còn lại")
	_dung(_nc.hoi_lan > 0.0,
		"nhưng hoi_lan vẫn nguyên — cắt lăn KHÔNG cho lăn lại sớm hơn (%.2fs)"
		% _nc.hoi_lan)

	await _cho(SoulsLike.cua_so_do_phan + SoulsLike.hoi_do_phan + 0.2)
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
	# Hỏi qua cửa chung chứ không ép kiểu: thân có hai bản (khối hộp và model
	# thật) và cả hai đều cài `khien_hien()` / `goc_tay_phai()`. Ép kiểu một
	# bản thì đổi thân là test đỏ, dù game chẳng hỏng gì.
	var tk: Node = _nc.than
	if tk == null or not tk.has_method("khien_hien"):
		_dung(false, "thân không có cửa hỏi khien_hien()")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	# --- Khiên phải HIỆN khi mặc, TẮT khi cởi ---
	_dat_khien(false)
	await _hai_khung()
	_dung(not tk.call("khien_hien"), "cởi khiên thì thân không vẽ khiên")
	_dat_khien(true)
	await _hai_khung()
	_dung(tk.call("khien_hien"), "mặc khiên vào thì thân VẼ khiên ra")

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

	# --- NẠP ĐÒN KHÔNG ĐƯỢC VUNG HỤT MỘT NHÁT TRƯỚC ---
	#
	# Bản đầu: lúc giơ tay lên, phần nhìn vẫn báo "nang" nên nó vẽ CUNG VUNG
	# của đòn nặng ngay từ khung đầu — tay quét tới trước 68° rồi giật ngược
	# về dáng giữ. Nhìn hệt một đòn thường vung hụt trước khi đòn nặng bắt
	# đầu, và chủ dự án báo đúng như vậy.
	#
	# Canh bằng GÓC TAY: suốt cú nạp tay chỉ được đi MỘT CHIỀU ra sau. Quay
	# ngược ra trước dù một khung hình là hỏng.
	_lam_moi_nguoi_choi()
	var than_nap: Node = _nc.than
	if than_nap == null or not than_nap.has_method("goc_tay_phai"):
		_dung(false, "thân không có cửa hỏi goc_tay_phai()")
	else:
		await _nut("don_nhe", true)
		var truoc := 999.0
		var lui := 0.0
		var goc_max := -999.0
		# Có file động tác thật thì GÓC TAY đứng yên: `dien()` nhường hẳn cho
		# clip và không xoay khớp nữa. Cùng một câu hỏi thì phải hỏi bằng thứ
		# tiếng mà phần nhìn đang nói — xem `ThanMoHinh.dong_tac_dang_phat()`.
		# Có clip thật thì hỏi bằng ĐỘ CAO BÀN TAY, không hỏi bằng góc khớp:
		# `dien()` nhường hẳn cho AnimationPlayer nên `goc_tay_phai()` đứng im,
		# và mọi phép thử canh theo góc đều mù. Bản trước hỏi "clip đang phát
		# có tên là 'nap' không" — câu đó KHÔNG trả lời được gì về dáng, và
		# `nap.fbx` hoá ra là một clip ĐỨNG THỞ: tay quanh quẩn ở độ cao nghỉ
		# suốt 3.5 giây, thanh kiếm không hề giơ lên. Phép thử vẫn xanh, còn
		# người chơi thì thấy nhân vật đứng thở lúc đang gồng.
		var co_cao := than_nap.has_method("cao_tay_phai")
		var clip_nap := ""
		var cao_max := -999.0
		var cao_dau := 0.0
		for i in 48:
			await get_tree().physics_frame
			if _nc.may.hien_tai.ten_dien() == "nap":
				if clip_nap == "":
					clip_nap = String(than_nap.call("dong_tac_dang_phat"))
					if co_cao:
						cao_dau = than_nap.call("cao_tay_phai")
				if co_cao:
					cao_max = maxf(cao_max, than_nap.call("cao_tay_phai"))
			var g: float = than_nap.call("goc_tay_phai")
			if truoc < 900.0 and g > truoc + 0.5:
				lui = maxf(lui, g - truoc)
			goc_max = maxf(goc_max, absf(g))
			truoc = g
		if clip_nap != "" and co_cao:
			_dung(cao_max > cao_dau + 0.25,
				"nạp đòn: THẬT SỰ giơ kiếm lên (%.2fm → %.2fm)" % [cao_dau, cao_max])
		else:
			_dung(goc_max > 150.0,
				"nạp đòn: giơ tay lên tới đỉnh (%.0f°)" % goc_max)
		_dung(lui < 6.0,
			"suốt cú nạp tay đi MỘT CHIỀU, không vung hụt rồi giật lại (lùi %.1f°)"
			% lui)
		_bang(_nc.may.hien_tai.ten_dien(), "nap", "và phần nhìn báo ĐANG NẠP từ đầu")

		# GIỮ Ở ĐỈNH, không phải vung chậm.
		#
		# `_chay_nap()` ghim `may.t` lại ở `t_vung` khi tay đã lên tới đỉnh,
		# và phần nhìn phải ghim theo. Thả cho clip tự chạy thì thanh kiếm cứ
		# thế bổ xuống trong lúc người chơi vẫn còn đang giữ chuột — cú nạp
		# mất hẳn cái dáng "đang chờ", mà đó là thứ ĐỐI PHƯƠNG đọc để né.
		# Không có phép thử này thì gỡ chỗ ghim đi cũng không ai thấy.
		# Phải giữ TỚI SÁT TRẦN NẠP mới đo được. Clip `nang` tự nó có sẵn một
		# đoạn đứng yên ở đỉnh (20–40% độ dài clip), nên trong vài khung đầu
		# thì ghim hay không ghim trông giống hệt nhau — đo ngắn là phép thử
		# xanh dù chỗ ghim đã bị gỡ. Qua hết đoạn ấy thì clip bắt đầu bổ
		# xuống, và lúc đó mới lòi ra.
		# ĐỢI TỚI LÚC ĐỒNG HỒ STATE ĐỨNG LẠI rồi mới đo.
		#
		# `_chay_nap()` chỉ ghim `may.t` sau khi tay đã lên tới đỉnh, mà cú
		# vung tay lên dài bao nhiêu là do CLIP quyết (`t_vung` của
		# `moveset.csv`, đo từ file động tác). Đếm một số khung cố định rồi đo
		# là đo trúng đoạn đang giơ tay — tay đang đi lên thì tất nhiên độ cao
		# đổi, và phép thử đỏ oan. Đổi một file `.fbx` là mốc ấy xê dịch, nên
		# phải bám vào cái đồng hồ chứ không bám vào số khung.
		if clip_nap != "" and co_cao:
			for i in 200:
				if _nc.may.ten_hien_tai != "danh" \
						or _nc.may.hien_tai.ten_dien() != "nap":
					break
				if _nc.may.hien_tai.get("_giu_dinh"):
					break
				await get_tree().physics_frame
		if clip_nap != "" and co_cao and _nc.may.ten_hien_tai == "danh" \
				and _nc.may.hien_tai.ten_dien() == "nap":
			var cao_a: float = than_nap.call("cao_tay_phai")
			var cao_cuoi := cao_a
			for i in 22:
				await get_tree().physics_frame
				if _nc.may.ten_hien_tai != "danh" \
						or _nc.may.hien_tai.ten_dien() != "nap":
					break
				cao_cuoi = than_nap.call("cao_tay_phai")
			_dung(absf(cao_cuoi - cao_a) < 0.15,
				"lên tới đỉnh rồi thì GIỮ NGUYÊN ở đó, không tự bổ xuống (%.2fm → %.2fm)"
				% [cao_a, cao_cuoi])

		# NHẢ RA LÀ CHÉM TIẾP, KHÔNG DIỄN LẠI TỪ ĐẦU.
		#
		# Đây là cái bẫy thật sự của cú nạp, và nó đã nổ một lần: cú nạp có
		# clip riêng, nên lúc nhả thì `play()` clip đòn nặng và con trỏ về
		# khung 0 — người chơi xem HAI cú vung tay cho MỘT nhát chém, mà hộp
		# đòn thì đã bật ngay từ đầu cú thứ hai. Canh bằng hai thứ cùng lúc:
		# tên clip không được đổi, và con trỏ clip không được lùi.
		var g_giu: float = than_nap.call("goc_tay_phai")
		var co_vi_tri := than_nap.has_method("vi_tri_dong_tac")
		var vi_tri_giu: float = than_nap.call("vi_tri_dong_tac") if co_vi_tri else 0.0
		await _nut("don_nhe", false)
		var g_sau: float = than_nap.call("goc_tay_phai")
		_dung(absf(g_sau - g_giu) < 25.0,
			"nhả ra thì chém tiếp từ chỗ đang giữ, không nhảy (%.0f° → %.0f°)"
			% [g_giu, g_sau])
		# ĐỢI ĐÚNG KHOẢNH KHẮC CHUYỂN, đừng đo ngay lúc nhả nút.
		#
		# `_chay_nap()` chỉ xét cú nhả SAU KHI tay đã vung lên tới đỉnh
		# (`t >= t_vung`), nên nhả sớm thì state còn ở "nap" thêm một quãng —
		# đo lúc đó là đo đúng cái chưa đổi, và phép thử xanh dù clip vẫn nhảy
		# về đầu ngay sau đấy. Bản đầu của phép thử này dính đúng vậy.
		for i in 90:
			if _nc.may.ten_hien_tai != "danh" or _nc.may.hien_tai.ten_dien() != "nap":
				break
			vi_tri_giu = than_nap.call("vi_tri_dong_tac") if co_vi_tri else 0.0
			await get_tree().physics_frame
		if clip_nap != "" and _nc.may.ten_hien_tai == "danh":
			_bang(String(than_nap.call("dong_tac_dang_phat")), clip_nap,
				"cú nạp và cú chém là MỘT clip, nhả ra không đổi sang clip khác")
			if co_vi_tri:
				# NGƯỠNG 0.2s, không phải 0.02s — con số này có lý do.
				#
				# Bản đầu để 0.02 và nó ĐỎ trên CI trong khi xanh ở máy khác:
				# đo được 1.79s → 1.77s, lùi đúng một nhịp làm tròn. Cú nhả
				# GHIM lại con trỏ theo `may.t`, nên lùi vài phần trăm giây là
				# chuyện hai khung hình lệch nhau, không phải chuyện cơ chế —
				# và một ngưỡng chặt tới mức đó chỉ đang đo độ ổn định của cái
				# máy chạy test.
				#
				# Thứ phép thử này canh là clip NHẢY VỀ ĐẦU. Về đầu nghĩa là
				# tụt gần 1.8 giây, nên 0.2 vẫn bắt được nó thừa sức.
				var vi_tri_sau: float = than_nap.call("vi_tri_dong_tac")
				_dung(vi_tri_sau >= vi_tri_giu - 0.2,
					"con trỏ clip đi TIẾP chứ không chạy lại từ đầu (%.2fs → %.2fs)"
					% [vi_tri_giu, vi_tri_sau])
		await _cho(2.2)
		_lam_moi_nguoi_choi()

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
	for n in _quai_thuong():
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

## Nạp đòn thì LẾT ĐƯỢC, nhưng chậm.
##
## Elden Ring không cho đi lúc nạp — đứng im là cả cái giá của đòn nạp. Chủ dự
## án chốt cho đi, nên cái giá chuyển sang tốc độ. Ba điều phải giữ cùng lúc,
## thiếu một là hỏng cân bằng:
##   1. nạp thì đi được (nếu không thì yêu cầu này chưa làm)
##   2. đi CHẬM HƠN hẳn đi thường (nếu không thì nạp thành miễn phí)
##   3. đòn NHẸ vẫn không đi được (cam kết đòn chỉ được nới cho lúc nạp thôi)
func _let_khi_nap() -> void:
	_nhom("Nạp đòn thì lết được, chậm")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	var xa_thuong := await _do_quang_duong("", 0.0)
	_dung(xa_thuong > 0.1, "đi thường có nhúc nhích (%.2fm)" % xa_thuong)

	var xa_nap := await _do_quang_duong("don_nhe", 0.0)
	_dung(xa_nap > 0.05, "ĐANG NẠP vẫn lết được (%.2fm)" % xa_nap)
	_dung(xa_nap < xa_thuong * 0.6,
		"nhưng chậm hơn hẳn đi thường (%.2fm so với %.2fm)" % [xa_nap, xa_thuong])

	# Đòn nhẹ thì vẫn bám chân tại chỗ — chỉ lúc NẠP mới được nới.
	_lam_moi_nguoi_choi()
	var truoc := _nc.global_position
	await _giu("don_nhe", 0.04)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm nhanh ra đòn nhẹ")
	await _nut("di_truoc", true)
	await _cho(0.25)
	var xa_nhe := truoc.distance_to(_nc.global_position)
	await _nut("di_truoc", false)
	_dung(xa_nhe < xa_nap, "đòn NHẸ vẫn bám chân tại chỗ (%.2fm)" % xa_nhe)

	await _cho(1.6)
	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Giữ `nut` (rỗng = không giữ gì) rồi đẩy hướng đi trong 0.35 giây, trả về
## quãng đường đi được. Dùng để so tốc độ giữa hai tình huống.
func _do_quang_duong(nut: String, _bo: float) -> float:
	_lam_moi_nguoi_choi()
	await _hai_khung()
	var e: InputEventAction = null
	if nut != "":
		e = InputEventAction.new()
		e.action = nut
		e.pressed = true
		Input.parse_input_event(e)
		# Chờ qua ngưỡng giữ + khung vung tay để chắc chắn đã vào thế nạp.
		var tv := float(VocabDB.don_cua(Tui.moveset_dang_dung(), "nang").get("t_vung", 0.4))
		await _cho(NguoiChoi.NGUONG_GIU_NANG + tv + 0.1)
	var truoc := _nc.global_position
	await _nut("di_truoc", true)
	await _cho(0.35)
	var xa := truoc.distance_to(_nc.global_position)
	await _nut("di_truoc", false)
	if e != null:
		var r := InputEventAction.new()
		r.action = nut
		r.pressed = false
		Input.parse_input_event(r)
	await _cho(1.6)
	return xa

## Boss hai giai đoạn (mốc 5).
##
## Canh đúng thứ phân biệt boss với một con quái nhiều máu: máu tụt qua ngưỡng
## thì nó ĐỔI LUẬT — moveset dài ra, có đòn chưa từng thấy. Và khung chuyển
## giai đoạn phải BẤT TỬ, không thì người chơi học được đúng một điều là cứ
## thấy boss đổi dạng thì xông vào chém miễn phí.
func _boss_hai_giai_doan() -> void:
	_nhom("Boss hai giai đoạn")
	var ds := get_tree().get_nodes_in_group("boss")
	if ds.is_empty():
		_dung(false, "phòng thử không có boss nào")
		return
	var b := ds[0] as Boss
	_dung(b != null, "boss dựng lên được")
	_dung(b.mau_toi_da >= 1000.0, "boss máu lấy từ boss.csv (%.0f)" % b.mau_toi_da)
	_bang(b.giai_doan, 1, "vào trận là giai đoạn một")

	var don_gd1 := b.cac_don()
	var don_gd2: Array = b.d.get("moveset_2", [])
	_dung(don_gd1.size() > 0, "giai đoạn một có moveset (%d đòn)" % don_gd1.size())
	_dung(don_gd2.size() > don_gd1.size(),
		"giai đoạn hai có nhiều đòn hơn (%d so với %d)" % [don_gd2.size(), don_gd1.size()])
	var la := []
	for x in don_gd2:
		if not don_gd1.has(x):
			la.append(String(x))
	_dung(not la.is_empty(), "và có đòn CHƯA TỪNG THẤY ở giai đoạn một: %s"
		% " ".join(la))

	# --- Đánh tụt qua ngưỡng ---
	# Kéo boss về sát người chơi: boss đứng ở góc xa, mà cửa boss thật thì
	# người chơi bước hẳn vào phòng nó. Không kéo lại thì nó mất dấu và về chỗ.
	b.nguoi_choi = _nc
	b.global_position = _nc.global_position + _nc.huong_mat() * 4.0
	b.diem_goc = b.global_position
	_dung(b.thay_nguoi_choi(), "đứng trong phòng thì boss thấy người chơi")
	_dung(float(b.d.get("toc_do_duoi", 0)) == float(b.d.get("toc_do", -1)),
		"tốc độ đuổi lấy từ cột toc_do của boss.csv (%.1f)"
		% float(b.d.get("toc_do_duoi", 0)))
	var nguong := b.nguong_gd2()
	b.an_don(int(b.mau_toi_da * (1.0 - nguong) + 20.0), 1.0, _nc.global_position)
	await _hai_khung()
	_bang(b.giai_doan, 2, "tụt qua ngưỡng %.0f%% là sang giai đoạn hai"
		% (nguong * 100.0))
	_bang(b.may.ten_hien_tai, "boss_doi_gd", "và vào khung chuyển giai đoạn")
	_bang(b.cac_don().size(), don_gd2.size(), "moveset đã đổi sang bảng hai")

	# --- Khung đó phải BẤT TỬ ---
	var mau_truoc := b.mau
	_bang(b.an_don(9999, 50.0, _nc.global_position), 0,
		"đánh lúc đang đổi giai đoạn: 0 sát thương")
	_bang(b.mau, mau_truoc, "máu boss không suy suyển")
	_dung(b.dang_ngay, "nó đứng ngây thật, không phải chỉ bất tử")

	# --- Hết khung thì đánh tiếp, và KHÔNG đổi giai đoạn lần nữa ---
	await _cho(Boss.NGAY_DOI_GIAI_DOAN + 0.3)
	_bang(b.may.ten_hien_tai, "quai_duoi", "hết khung là quay lại đuổi đánh")
	b.an_don(10, 1.0, _nc.global_position)
	await _hai_khung()
	_bang(b.giai_doan, 2, "không có giai đoạn ba")

	# --- Hạ boss: dạy chữ + cho hồn ---
	var hon_truoc := Tui.hon
	var chu_thuong: Array = b.d.get("thuong_chu", [])
	for c in chu_thuong:
		TriNho.so.erase(String(c))
	b.an_don(99999, 1.0, _nc.global_position)
	await _hai_khung()
	_dung(not b.con_song(), "hạ được boss")
	await _cho(0.6)
	_dung(Tui.hon > hon_truoc, "boss cho hồn (%d → %d)" % [hon_truoc, Tui.hon])
	var day_du := true
	for c in chu_thuong:
		if String(c) != "" and not TriNho.doc_duoc(String(c)):
			day_du = false
	_dung(day_du, "hạ boss là HỌC LUÔN mấy chữ ở cột thuong_chu (%s)"
		% " ".join(chu_thuong))

## Máy trạng thái quái. Chạy CUỐI CÙNG vì nó xê dịch và hạ quái — mấy nhóm
## trước đếm đúng bốn con.
func _may_trang_thai_quai() -> void:
	_nhom("Máy trạng thái quái")
	var ds := _quai_thuong()
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
		if bit and q.may.ten_hien_tai != "boss_doi_gd":
			q.may.doi("quai_dung")

## Ghim vũ khí đang cầm về đúng một loại.
##
## Phép thử nào đo NHỊP (mấy nhát thì hạ quái, bao lâu thì hồi thể lực, lăn có
## kịp không) đều phải ghim, đừng tin vào thứ phòng thử phát sẵn: đổi vũ khí
## khởi đầu của phòng thử là đổi hết mấy con số đó. Đã dính đúng vậy khi phòng
## thử chuyển sang phát kiếm hai tay — tám phép thử đỏ cùng lúc, mà không phép
## nào sai cả, chỉ là chúng đang đo một cây kiếm khác.
func _dat_vu_khi(chu: String) -> void:
	var vk := SinhMonDo.sinh_mon_tu_chu(chu, "thi_tran", 1000)
	if vk == null:
		return
	Tui.nhat(vk)
	# Ô 0 và CHUYỂN TAY sang ô 0. `mac_vao` không có ô thì nhét vào khe trống
	# đầu tiên, mà ô 0 đang có vũ khí cũ — nên nó rơi xuống ô 1 và
	# `tay_phai_dang` vẫn trỏ cây cũ. Ghim mà không đổi tay là không ghim gì cả.
	Tui.mac_vao(vk, "vu_khi", 0)
	Tui.tay_phai_dang = 0
	Tui.doi_trang_bi.emit()

## Nhét một cái khiên vào tay trái, hoặc lấy ra. Khiên KHÔNG còn là điều kiện
## để parry (chủ dự án chốt, ngược ER); nó quyết định chặn được bao nhiêu sát
## thương, đỡ tốn bao nhiêu thể lực, và có ra được đòn phản đỡ hay không.
func _dat_khien(co: bool) -> void:
	if not co:
		Tui.mac["tay_trai"][Tui.tay_trai_dang] = null
		Tui.doi_trang_bi.emit()
		return
	# Cầm hai tay thì `Tui.tay_trai_dang_cam()` trả null dù khe có đồ — nên
	# muốn thử khiên là phải đổi về vũ khí một tay trước.
	_dat_vu_khi("剑")
	TriNho.hoc("盾")
	var khien := MonDo.new(["盾"], 1)
	Tui.mac["tay_trai"][Tui.tay_trai_dang] = khien
	Tui.doi_trang_bi.emit()

## Đưa người chơi về trạng thái sạch giữa hai phép thử — đầy máu, đầy thể lực,
## không còn khựng, không còn dư i-frame hay hồi lăn của cú trước.
## Leo tường (state `leo`).
##
## Phòng thử có sẵn bốn thứ để hỏi đủ bốn câu, và chúng CỐ Ý cao khác nhau —
## xem `PhongThu._dung_tru_leo()` / `_dung_tuong_thap()` / `_dung_san()`:
##
##   tháp leo 5.2m   leo được, và có mặt trên để thử cú TRÈO QUA MÉP
##   bệ 1.2m         dưới ngưỡng `CAO_LEO_TOI_THIEU` ⇒ không bám
##   tường nhảy 0.9m dựng ra ĐỂ nhảy qua ⇒ không được biến thành thang
##   tường biên 4m   nhóm `khong_leo` ⇒ không trèo ra khỏi map được
func _leo_tuong() -> void:
	_nhom("Leo tường")
	_lam_moi_nguoi_choi()

	# --- Dò tĩnh: đứng sát rồi hỏi, không cần đợi đồng hồ nào ---
	_dung(not _do_tuong(Vector3(10, 0.2, 18.5)).is_empty(),
		"tháp leo 5.2m: bám được")
	_dung(_do_tuong(Vector3(13.2, 0.2, 17.6)).is_empty(),
		"bệ 1.2m: THẤP hơn ngưỡng nên không bám")
	_dung(_do_tuong(Vector3(-16, 0.2, -19.3)).is_empty(),
		"tường nhảy 0.9m: không bám — nó dựng ra để NHẢY qua")
	_dung(_do_tuong(Vector3(0, 0.2, -34.2)).is_empty(),
		"tường biên: nhóm khong_leo nên không trèo ra khỏi map được")
	_dung(_do_tuong(Vector3(0, 0.2, 0)).is_empty(),
		"giữa sân trống: không có gì để bám")

	# --- Ép phím vào tường đủ lâu thì bám ---
	#
	# W đi theo −Z (camera mặc định), mà mặt bắc của tháp ở z = 18, nên đứng ở
	# z = 19.2 bấm W là đâm thẳng vào nó.
	_dat_truoc_thap()
	await _nut("di_truoc", true)
	var cho := 0
	while _nc.may.ten_hien_tai != "leo" and cho < 200:
		cho += 1
		await get_tree().physics_frame
	_bang(_nc.may.ten_hien_tai, "leo", "ép phím vào tường đủ lâu thì BÁM")
	# Ngưỡng phải THẬT SỰ có tác dụng: chạm phát bám ngay là sai cơ chế.
	_dung(cho >= int(NguoiChoi.T_EP_TUONG * 60.0),
		"và phải ép đủ %.1fs mới bám, không bám ngay lúc chạm"
		% NguoiChoi.T_EP_TUONG)

	# --- Leo lên thật, tốn thể lực thật ---
	var y_dau := _nc.global_position.y
	var tl_dau := _nc.the_luc
	await _cho(0.5)
	_dung(_nc.global_position.y > y_dau + 0.5,
		"giữ phím thì trèo LÊN (%.2fm → %.2fm)"
		% [y_dau, _nc.global_position.y])
	_dung(_nc.the_luc < tl_dau, "và leo lên thì TỐN thể lực (%.0f → %.0f)"
		% [tl_dau, _nc.the_luc])

	# --- Tới đỉnh thì tự trèo lên mặt trên ---
	var len_duoc := false
	for i in 400:
		await get_tree().physics_frame
		if _nc.may.ten_hien_tai != "leo":
			len_duoc = _nc.global_position.y > 4.5
			break
	_dung(len_duoc, "leo hết tháp thì TỰ TRÈO lên đứng trên nóc (y=%.2f)"
		% _nc.global_position.y)
	await _nut("di_truoc", false)

	# --- Treo im giữa tường: không mất và cũng không hồi thể lực ---
	# Dùng nửa thanh và đợi qua trễ hồi: ghim ở mức tối đa sẽ không bắt được
	# lỗi vô tình cho hồi khi bám. Đứng cao để không thoát leo vì chạm sàn.
	await _bam_giua_thap()
	_nc.the_luc = _nc.the_luc_max * 0.5
	var tl_treo := _nc.the_luc
	var vi_tri_treo := _nc.global_position
	await _cho(SoulsLike.tre_hoi_the_luc + 0.2)
	_dung(_nc.may.ten_hien_tai == "leo" and not _nc.is_on_floor(),
		"không giữ phím vẫn BÁM giữa tường, chân không chạm sàn")
	_bang(_nc.the_luc, tl_treo, "treo im không mất và không hồi thể lực")
	_dung(_nc.global_position.distance_to(vi_tri_treo) < 0.01,
		"treo im thì vị trí không trôi")

	# --- Cả bốn hướng đều phải chuyển động thật rồi mới đo thể lực ---
	for ca in [
		{"phim": "di_truoc", "huong": Vector3.UP, "ten": "LÊN"},
		{"phim": "di_sau", "huong": Vector3.DOWN, "ten": "XUỐNG"},
		{"phim": "di_trai", "huong": Vector3.LEFT, "ten": "TRÁI"},
		{"phim": "di_phai", "huong": Vector3.RIGHT, "ten": "PHẢI"},
	]:
		await _bam_giua_thap()
		_nc.the_luc = _nc.the_luc_max * 0.5
		var tl_truoc := _nc.the_luc
		var vi_tri_truoc := _nc.global_position
		var phim: String = ca["phim"]
		var huong: Vector3 = ca["huong"]
		var ten: String = ca["ten"]
		await _nut(phim, true)
		await _cho(0.25)
		await _nut(phim, false)
		_dung(_nc.may.ten_hien_tai == "leo"
			and (_nc.global_position - vi_tri_truoc).dot(huong) > 0.15,
			"leo %s dịch chuyển thật trên mặt tường" % ten)
		_dung(_nc.the_luc < tl_truoc,
			"leo %s thì mất thể lực (%.2f → %.2f)"
			% [ten, tl_truoc, _nc.the_luc])

		# Nhả phím sau khi đang leo phải ngừng trừ ngay, kể cả sau khi leo ngang.
		var tl_sau := _nc.the_luc
		var vi_tri_sau := _nc.global_position
		await _cho(SoulsLike.tre_hoi_the_luc + 0.2)
		_bang(_nc.may.ten_hien_tai, "leo", "nhả phím %s vẫn bám tường" % ten)
		_bang(_nc.the_luc, tl_sau,
			"nhả phím %s thì thể lực giữ nguyên, không hồi" % ten)
		_dung(_nc.global_position.distance_to(vi_tri_sau) < 0.01,
			"nhả phím %s thì đứng yên trên tường" % ten)

	# --- Leo tới cạn thể lực thì tuột, không phải thoát vì chạm sàn ---
	await _bam_giua_thap()
	_nc.the_luc = 2.0
	await _nut("di_truoc", true)
	var tuot := 0
	while _nc.may.ten_hien_tai == "leo" and tuot < 200:
		tuot += 1
		await get_tree().physics_frame
	_bang(_nc.the_luc, 0.0, "leo thật sự tiêu CẠN thể lực")
	_bang(_nc.may.ten_hien_tai, "nhay", "cạn thể lực thì TUỘT khỏi tường")
	_dung(not _nc.is_on_floor() and _nc.global_position.y > 1.0,
		"tuột lúc còn ở trên cao, không phải thoát leo vì chạm sàn")
	await _nut("di_truoc", false)
	await _hai_khung()
	_dung(_nc.velocity.y < 0.0, "sau khi cạn thể lực thì rơi xuống thật")

	# Mốc cạn vẫn được xét khi không giữ phím, không bị lọt qua nhánh treo im.
	await _bam_giua_thap()
	_nc.the_luc = 0.0
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "nhay", "treo im nhưng đã cạn thể lực vẫn tuột")

	# --- Ăn đòn khi đang bám thì rơi ---
	#
	# Không có luật này thì bám tường thành chỗ trốn an toàn giữa trận đánh.
	_lam_moi_nguoi_choi()
	_dat_truoc_thap()
	_nc.global_position.z = 18.4
	_nc.may.doi("leo", {"phap": Vector3(0, 0, 1)})
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "leo", "đang bám tường")
	_nc.an_don(30, 60.0, _nc.global_position + Vector3(0, 0, 5))
	await _hai_khung()
	_dung(_nc.may.ten_hien_tai != "leo",
		"ăn đòn khi đang bám thì RƠI khỏi tường (%s)" % _nc.may.ten_hien_tai)

	# --- RƠI quét qua tường thì KHÔNG tự bám ---
	#
	# Chỉ cú nhảy còn đang bay LÊN mới bám. Xét cả lúc rơi xuống thì chạy khỏi
	# mép vách là dính tường lủng lẳng ngoài ý muốn.
	_lam_moi_nguoi_choi()
	_nc.global_position = Vector3(10, 4.0, 19.0)
	await _hai_khung()
	_nc.may.doi("nhay", {"roi": true})
	_nc.velocity = Vector3(0, -1.0, -3.0)
	var dinh := false
	var cham := false
	for i in 120:
		await get_tree().physics_frame
		if _nc.is_on_wall():
			cham = true
		if _nc.may.ten_hien_tai == "leo":
			dinh = true
			break
		if _nc.is_on_floor():
			break
	_dung(cham, "cú rơi có quét qua mặt tường thật")
	_dung(not dinh, "nhưng đang RƠI thì không tự bám — rơi thẳng xuống đất")

	_lam_moi_nguoi_choi()
	_nc.global_position = Vector3(0, 0.2, 4)
	await _hai_khung()

## Bám giữa tháp để thử thể lực mà không dính sàn hoặc chạm tới mép trên.
## Cần một nhịp vật lý trên không TRƯỚC khi vào leo: dịch chuyển vị trí không
## xoá cờ is_on_floor() của nhịp cũ, nên vào leo ngay có thể thoát về dung.
func _bam_giua_thap() -> void:
	_lam_moi_nguoi_choi()
	_dat_truoc_thap()
	_nc.global_position = Vector3(10, 2.0, 18.4)
	_nc.velocity = Vector3.ZERO
	_nc.may.doi("nhay", {"roi": true})
	await _hai_khung()
	_nc.may.doi("leo", {"phap": Vector3(0, 0, 1)})
	await _hai_khung()

## Đặt nhân vật ngay trước mặt bắc của tháp leo, quay mặt vào nó.
##
## GHIM LẠI HƯỚNG CAMERA, và đó không phải chi tiết thừa: `huong_nhap` quy phím
## WASD về hệ thế giới THEO CAMERA (`NguoiChoi._doc_huong_nhap()`), nên bấm W
## chỉ đi về −Z khi camera chưa xoay. Mấy nhóm test chạy trước đã xoay nó đi,
## và khi đó W đẩy nhân vật đi hướng khác — nhân vật không bao giờ chạm tháp,
## phép thử đỏ mà chẳng liên quan gì tới cơ chế leo. Đã dính đúng vậy.
##
## Bỏ khoá mục tiêu luôn: khoá rồi thì `xoay_ve()` ép quay mặt về con quái,
## và nhân vật đi ngang vào tường thay vì đâm thẳng.
func _dat_truoc_thap() -> void:
	_nc.muc_tieu = null
	_nc.gia_camera.rotation = Vector3.ZERO
	_nc.global_position = Vector3(10, 0.2, 19.2)
	_nc.than.rotation.y = PI
	_nc.quen_ep_tuong()

## Đứng vào `tai` rồi hỏi "tường trước mặt (hướng −Z) có leo được không".
func _do_tuong(tai: Vector3) -> Dictionary:
	_nc.global_position = tai
	_nc.force_update_transform()
	return _nc.tuong_leo_duoc(Vector3(0, 0, -1))

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

## Một điểm ngay SAU lưng nhân vật — dùng cho đòn đánh lén và dáng ngã.
func _sau_lung() -> Vector3:
	return _nc.global_position - _nc.huong_mat() * 2.0

## RÚT / CẤT vũ khí (phím R).
##
## Cơ chế này chỉ có nghĩa nếu cất kiếm ĐƯỢC cái gì đó — không thì không ai bấm
## và nó thành nút trang trí, đúng loại thứ đã bị bỏ đi ở màn tạm dừng (LOGOUT).
## Nên nhóm này canh cả hai vế: cái LỢI (đi nhanh hơn) và cái GIÁ (không đánh
## được, phải rút ra trước).
func _rut_cat_vu_khi() -> void:
	_nhom("Rút / cất vũ khí")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	_dung(_nc.da_rut, "vào game là đã RÚT sẵn vũ khí")
	_bang(_nc.he_so_toc_do(), 1.0, "rút ra thì đi tốc độ thường")

	# --- Bấm R là cất ---
	await _bam("cat_rut")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "cat_vu_khi", "bấm R là vào trạng thái CẤT")
	_dung(_nc.da_rut, "đang cất thì vũ khí VẪN coi như đang rút — chưa xong thì chưa tính")
	await _cho(NguoiChoi.T_CAT_VU_KHI + 0.25)
	_dung(not _nc.da_rut, "cất xong thì cờ đổi")
	_bang(_nc.may.ten_hien_tai, "dung", "và về đứng yên")
	_dung(_nc.he_so_toc_do() > 1.0,
		"CẤT RỒI THÌ ĐI NHANH HƠN (×%.2f) — đó là lý do để bấm"
		% _nc.he_so_toc_do())
	_dung(_nc.he_so_ton_the_luc() < 1.0,
		"và chạy TỐN ÍT THỂ LỰC hơn (×%.2f)" % _nc.he_so_ton_the_luc())

	# Đo thật MỘT HƠI CHẠY DÀI BAO LÂU. Đo thời gian chứ không đo quãng đường:
	# bản đầu đo quãng đường và ra 32.5m cho cả hai — vì nhân vật đâm vào rìa
	# phòng thử chứ không phải vì hết thể lực. Phép đo phụ thuộc cỡ căn phòng
	# thì nó đang đo căn phòng, không đo cơ chế.
	var lau_rut := await _do_hoi_chay(true)
	var lau_cat := await _do_hoi_chay(false)
	_dung(lau_cat > lau_rut * 1.5,
		"một hơi chạy khi CẤT dài hơn hẳn khi rút (%.2fs vs %.2fs)"
		% [lau_cat, lau_rut])

	# --- Đang cất mà bấm đánh: TỰ RÚT trước, cú bấm nằm chờ ---
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "rut_vu_khi",
		"đang cất mà bấm đánh thì TỰ RÚT trước, không bắt bấm R")
	_dung(_nc.co_dem("don_nhe"),
		"và cú bấm đánh nằm chờ trong bộ đệm để nổ ngay khi rút xong")
	await _cho(NguoiChoi.T_RUT_VU_KHI + 0.25)
	_dung(_nc.da_rut, "rút xong thì cờ đổi lại")
	await _cho(2.0)

	# --- Cam kết: đang rút/cất thì không lăn thoát được ---
	_lam_moi_nguoi_choi()
	await _bam("cat_rut")
	await _hai_khung()
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "cat_vu_khi",
		"đang cất thì bấm lăn KHÔNG cắt được — có cam kết, nên có rủi ro")
	await _cho(NguoiChoi.T_CAT_VU_KHI + 0.4)

	# --- Chết rồi sống lại thì cầm sẵn vũ khí ---
	_nc.song_lai(_nc.global_position)
	await _hai_khung()
	_dung(_nc.da_rut, "đứng dậy sau khi chết là đã rút sẵn — không ai muốn hồi sinh tay không")

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Chạy một hơi cho tới khi cạn thể lực, trả về DÀI BAO NHIÊU GIÂY.
##
## Đo thời gian, không đo quãng đường: quãng đường còn phụ thuộc phòng thử rộng
## bao nhiêu, mà đâm vào tường thì phép đo hoá ra đang đo căn phòng. Thời gian
## thì chỉ phụ thuộc đúng cái cần đo — thể lực tụt nhanh chậm ra sao.
##
## Quãng đường thật = thời gian này × tốc độ, mà tốc độ đã có phép thử riêng ở
## trên. Hai phần thưởng của việc cất kiếm nhân vào nhau chứ không cộng.
func _do_hoi_chay(rut: bool) -> float:
	_lam_moi_nguoi_choi()
	var dau := _nc.global_position
	_nc.da_rut = rut
	# BẮT ĐẦU TỪ MỘT PHẦN BA thể lực, không từ đầy. Đầy thì hết hơi mất hơn 8
	# giây, mà chạy hai lượt là mười sáu giây cho một phép thử — bộ kiểm tra
	# dài thêm ngần ấy để đo đúng một TỈ LỆ vốn không đổi theo mức bắt đầu.
	_nc.the_luc = _nc.the_luc_max * 0.34
	await _nut("chay_nhanh", true)
	await _nut("di_truoc", true)
	var n := 0
	while _nc.the_luc > 1.0 and n < 600:
		await get_tree().physics_frame
		n += 1
	await _nut("chay_nhanh", false)
	await _nut("di_truoc", false)
	await _hai_khung()
	# TRẢ NHÂN VẬT VỀ CHỖ CŨ. Bỏ dòng này thì nó đứng cách bao cát ba chục mét,
	# và bốn phép thử sau đó đánh vào khoảng không — đã dính đúng vậy một lần.
	_nc.global_position = dau
	_nc.velocity = Vector3.ZERO
	_lam_moi_nguoi_choi()
	await _hai_khung()
	return float(n) / 60.0

## Bộ nút đổi hẳn ở đợt này, mà đổi nút là chỗ hỏng ÂM THẦM nhất trong cả repo:
## game vẫn chạy, không lỗi nào, chỉ là bấm không ra gì — và không phép thử nào
## cũ bắt được, vì chúng gọi action theo TÊN chứ không theo phím.
##
## Bốn vế, đúng bốn thứ vừa đổi chỗ:
##   Space gõ nhanh = LĂN     ·  Space giữ = NHẢY
##   Shift giữ      = CHẠY    ·  đánh trên không = ĐÒN NHẢY, mỗi lần rơi MỘT đòn
func _nut_moi_va_don_nhay() -> void:
	_nhom("Nút mới: Space lăn/nhảy, Shift chạy, đòn nhảy")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)
	_lam_moi_nguoi_choi()

	# --- Space bấm HAI lần ra LĂN ---
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "lan", "bấm đôi Space ra LĂN")
	await _cho(1.2)

	# --- Space bấm MỘT lần ra NHẢY, và KHÔNG lăn kèm theo ---
	_lam_moi_nguoi_choi()
	await _space_nhay()
	_bang(_nc.may.ten_hien_tai, "nhay", "bấm một lần Space ra NHẢY")
	_dung(not _nc.is_on_floor(), "và chân rời mặt đất thật")
	# Một lần bấm KHÔNG được đệm thêm cú lăn — không thì mỗi lần nhảy là tự
	# lăn một phát ngay lúc tiếp đất.
	_dung(not _nc.co_dem("lan"), "bấm một lần thì KHÔNG đệm lăn")
	await _cho(1.5)

	# --- Lần bấm thứ hai phải đến ĐÚNG LÚC mới thành lăn ---
	#
	# Bấm hai lần cách nhau quá xa là HAI cú nhảy, không phải một cú lăn. Thiếu
	# phép thử này thì nới cửa sổ lên 1 giây vẫn xanh, mà game thì thành ra bấm
	# nhảy hai lần liên tiếp không bao giờ nhảy được lần hai.
	_lam_moi_nguoi_choi()
	await _giu("lan_nhay", 0.02)
	await _cho(NguoiChoi.NGUONG_BAM_DOI + 0.10)
	await _giu("lan_nhay", 0.02)
	await _hai_khung()
	_dung(_nc.may.ten_hien_tai != "lan",
		"bấm hai lần CÁCH XA nhau thì không phải lăn (%s)" % _nc.may.ten_hien_tai)
	await _cho(1.5)

	# --- Lăn đi ĐÚNG HƯỚNG MẶT ---
	#
	# Bản trước lấy hướng ngược lại khi không bấm phím nào, định làm backstep,
	# nhưng vẫn xoay cả người về hướng lăn — ra thành quay ngoắt 180° rồi lăn
	# tới. Đo được bằng `tools/soi_lan.tscn`, và không phép thử nào cũ bắt được
	# vì tất cả chúng chỉ hỏi "state có phải là lan không".
	_lam_moi_nguoi_choi()
	var cho_cu := _nc.global_position
	_nc.global_position = Vector3(0, 1.2, 0)
	_nc.velocity = Vector3.ZERO
	await _hai_khung()
	var mat := _nc.huong_mat()
	var tu := _nc.global_position
	await _space_lan()
	await _cho(SoulsLike.thoi_gian_lan + 0.1)
	var di: Vector3 = _nc.global_position - tu
	di.y = 0.0
	var lech := 180.0
	if di.length() > 0.3:
		lech = rad_to_deg(mat.normalized().angle_to(di.normalized()))
	_dung(lech < 30.0,
		"lăn tại chỗ đi THEO hướng mặt, không ngược (lệch %.0f°, xa %.1fm)"
		% [lech, di.length()])
	# Phép thử nào xê dịch nhân vật thì phải dọn sau mình.
	_nc.global_position = cho_cu
	_nc.velocity = Vector3.ZERO
	await _hai_khung()

	# --- Shift giữ là CHẠY ---
	_lam_moi_nguoi_choi()
	await _nut("chay_nhanh", true)
	_dung(_nc.dang_giu_chay(), "dang_giu_chay() đọc đúng Shift")
	# Chạy cần CÓ HƯỚNG: chay_nhanh.gd quay về `di` ngay nếu huong_nhap trống.
	await _nut("di_truoc", true)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "chay_nhanh", "giữ Shift + W là CHẠY")
	await _nut("chay_nhanh", false)
	await _hai_khung()
	_dung(not _nc.dang_giu_chay(), "nhả Shift thì thôi chạy")
	_bang(_nc.may.ten_hien_tai, "di", "và về đi bộ")
	await _nut("di_truoc", false)
	await _hai_khung()

	# --- Đòn nhảy NHẸ ---
	_lam_moi_nguoi_choi()
	await _space_nhay()
	_dung(not _nc.is_on_floor(), "đang ở trên không")
	_dung(_nc.con_don_tren_khong(), "chưa đánh thì còn nguyên đòn trên không")
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm đánh trên không ra đòn")
	var don1: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_bang(don1, "nhay", "và đó là ĐÒN NHẢY, không phải nhe_1")
	_dung(not _nc.con_don_tren_khong(), "đánh rồi thì hết đòn trên không của lần rơi này")
	await _cho(1.8)
	_dung(_nc.is_on_floor(), "rồi cũng tiếp đất")
	_dung(_nc.con_don_tren_khong(), "chạm đất là đòn trên không được nạp lại")

	# --- Đòn nhảy NẶNG: cùng một nút, phân biệt ở chỗ GIỮ ---
	_lam_moi_nguoi_choi()
	await _space_nhay()
	_dung(not _nc.is_on_floor(), "lại đang ở trên không")
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.08)
	await _hai_khung()
	var don2: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_bang(don2, "nhay_nang", "GIỮ chuột trên không ra ĐÒN NHẢY NẶNG")
	# Đòn nhảy nặng phải phá thế hơn hẳn đòn nhảy nhẹ — đó là cả lý do nó tồn
	# tại. Đọc thẳng từ CSV chứ không gán số ở đây: luật 1.
	var mv := Tui.moveset_dang_dung()
	var pha_nhe := float(VocabDB.don_cua(mv, "nhay").get("pha_the", 0))
	var pha_nang := float(VocabDB.don_cua(mv, "nhay_nang").get("pha_the", 0))
	_dung(pha_nang > pha_nhe, "nhay_nang phá thế mạnh hơn nhay (%.0f > %.0f)"
		% [pha_nang, pha_nhe])
	await _cho(2.0)

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## LƯU / NẠP GAME: nhiều ô, tự lưu, chơi tiếp.
##
## Nhóm này đi ĐÚNG con đường của nút bấm — ghi ra `user://saves/` thật rồi đọc
## lại thật. Giả lập bằng Dictionary trong bộ nhớ thì bỏ lọt đúng những chỗ hay
## hỏng: thư mục chưa có, JSON không nuốt được kiểu Vector3, số nguyên lớn về
## thành float.
func _luu_va_nap() -> void:
	_nhom("Lưu / nạp game")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	# Dọn trước: phòng thử có thể chạy lại trên máy đã có save cũ.
	for o in ["1", "2", LuuGame.O_TU_LUU]:
		LuuGame.xoa(o)

	# --- Ghi rồi đọc lại ---
	_lam_moi_nguoi_choi()
	var cho_cu := _nc.global_position
	_nc.global_position = Vector3(7.0, 1.2, -3.0)
	_nc.mau = 123.0
	Tui.hon = 4242
	TheGioi.bat_bia("bia_thu")
	await _hai_khung()
	_dung(LuuGame.luu("1"), "lưu được vào ô 1")
	_dung(LuuGame.co("1"), "và file ô 1 có thật trên đĩa")
	_dung(FileAccess.file_exists(LuuGame.duong("1")),
		"đúng đường dẫn %s" % LuuGame.duong("1"))

	# Đổi hết mọi thứ đi rồi nạp lại — nạp mà không đổi gì thì phép thử không
	# phân biệt được "khôi phục đúng" với "chưa bao giờ đụng vào".
	_nc.global_position = Vector3(-20.0, 1.2, 20.0)
	_nc.mau = 999.0
	Tui.hon = 0
	await _hai_khung()
	_dung(LuuGame.nap("1"), "nạp lại được ô 1")
	await _hai_khung()
	_bang(Tui.hon, 4242, "hồn khôi phục đúng")
	_dung(absf(_nc.mau - 123.0) < 0.5, "máu khôi phục đúng (%.0f)" % _nc.mau)
	_dung(_nc.global_position.distance_to(Vector3(7.0, 1.2, -3.0)) < 1.0,
		"chỗ đứng khôi phục đúng (%v)" % _nc.global_position)
	_dung(TheGioi.bia_da_bat("bia_thu"), "bia đã bật vẫn còn bật sau khi nạp")

	# --- Ô nào ra ô nấy ---
	Tui.hon = 77
	await _hai_khung()
	_dung(LuuGame.luu("2"), "lưu được vào ô 2")
	_dung(LuuGame.nap("1"), "nạp lại ô 1")
	_bang(Tui.hon, 4242, "ô 1 KHÔNG bị ô 2 ghi đè")
	_dung(LuuGame.nap("2"), "nạp ô 2")
	_bang(Tui.hon, 77, "và ô 2 giữ đúng phần của nó")

	# --- TỰ LƯU khi nghỉ bia đá, và nó KHÔNG đụng vào ô tay ---
	_dung(not LuuGame.co(LuuGame.O_TU_LUU), "chưa nghỉ bia thì chưa có bản tự lưu")
	Tui.hon = 555
	TheGioi.nghi("bia_thu")
	await _hai_khung()
	_dung(LuuGame.co(LuuGame.O_TU_LUU), "nghỉ ở bia đá là TỰ LƯU")
	_dung(LuuGame.nap("1"), "nạp lại ô 1 lần nữa")
	_bang(Tui.hon, 4242, "tự lưu KHÔNG ghi đè lên ô tay")

	# --- CHƠI TIẾP lấy bản MỚI NHẤT, kể cả khi đó là bản tự lưu ---
	var ds := LuuGame.danh_sach()
	_dung(ds.size() >= 3, "liệt kê được cả ba bản (%d)" % ds.size())
	_bang(LuuGame.o_moi_nhat(), LuuGame.O_TU_LUU,
		"bản mới nhất là bản tự lưu — 'Chơi tiếp' phải về đúng chỗ vừa dừng")
	_dung(LuuGame.choi_tiep(), "chơi tiếp chạy được")
	await _hai_khung()
	_bang(Tui.hon, 555, "và nó nạp đúng bản tự lưu")

	# --- Ô rỗng và file hỏng đều phải THUA TỬ TẾ ---
	_dung(not LuuGame.co("3"), "ô chưa lưu thì báo rỗng")
	_dung(not LuuGame.nap("3"), "nạp ô rỗng trả về false chứ không nổ")
	var f := FileAccess.open(LuuGame.duong("3"), FileAccess.WRITE)
	if f != null:
		f.store_string("{ đây không phải JSON")
		f.close()
	_dung(not LuuGame.nap("3"), "file save hỏng cũng trả về false, game chạy tiếp")

	for o in ["1", "2", "3", LuuGame.O_TU_LUU]:
		LuuGame.xoa(o)
	_nc.global_position = cho_cu
	_nc.velocity = Vector3.ZERO
	await _hai_khung()
	_lam_moi_nguoi_choi()

## BỘ ĐỆM SỨC CHỨA 1, MA TRẬN ƯU TIÊN, và BỐN CỜ CỬA SỔ.
##
## Ba thứ này là kiến trúc chứ không phải tính năng, nên chúng hỏng theo kiểu
## khó thấy nhất: game vẫn chạy, chỉ là nhân vật thỉnh thoảng làm một việc mà
## người chơi không còn muốn nữa.
func _bo_dem_va_uu_tien() -> void:
	_nhom("Bộ đệm sức chứa 1, ưu tiên, cờ cửa sổ")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)

	# --- SỨC CHỨA ĐÚNG MỘT: lệnh sau ĐÈ lệnh trước ---
	#
	# Giữ nhiều lệnh thì spam ba nút lúc đang vung sẽ cho ra ba hành động nối
	# nhau sau khi đòn kết thúc — nhân vật tự chơi lấy một chuỗi mà người chơi
	# đã bỏ ý định. Giữ một thì cái sống sót là Ý ĐỊNH MỚI NHẤT.
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	_nc.ghi_dem("lan")
	_bang(_nc.dem_dang_cho(), "lan", "ghi lệnh đầu")
	_nc.ghi_dem("uong_binh")
	_bang(_nc.dem_dang_cho(), "uong_binh", "lệnh sau ĐÈ lên lệnh trước")
	_dung(not _nc.co_dem("lan"), "và lệnh cũ biến mất, không xếp hàng")

	# --- HẾT HẠN thì tự rơi ---
	_nc.ghi_dem("lan")
	await _cho(NguoiChoi.DEM_NHAP + 0.15)
	_bang(_nc.dem_dang_cho(), "", "quá hạn dùng thì lệnh tự rơi khỏi đệm")

	# --- CẠN THỂ LỰC thì vứt lệnh tốn thể lực ---
	#
	# Để lại thì nó nổ ra đúng lúc thanh thể lực vừa nhúc nhích lên một chút,
	# và nhân vật lăn một phát mà người chơi không hề bấm ở thời điểm đó.
	_lam_moi_nguoi_choi()
	_nc.ghi_dem("lan")
	_bang(_nc.dem_dang_cho(), "lan", "có lệnh lăn đang chờ")
	_nc.ton_the_luc(_nc.the_luc_max + 10.0)
	_bang(_nc.the_luc, 0.0, "tiêu cạn thể lực")
	_bang(_nc.dem_dang_cho(), "", "cạn thể lực thì lệnh LĂN bị vứt")
	# Lệnh KHÔNG tốn thể lực thì phải còn: uống bình là thứ duy nhất cứu được
	# người chơi lúc cạn, vứt nó đi là phạt hai lần cho một sai lầm.
	_lam_moi_nguoi_choi()
	_nc.ghi_dem("uong_binh")
	_nc.ton_the_luc(_nc.the_luc_max + 10.0)
	_bang(_nc.dem_dang_cho(), "uong_binh", "nhưng lệnh UỐNG BÌNH thì vẫn còn")

	# --- BỐN CỜ khớp với năm đoạn ---
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	await _giu("don_nhe", 0.04)
	await _hai_khung()
	if _nc.may.ten_hien_tai != "danh":
		_dung(false, "không vào được trạng thái đánh để soi cờ")
	else:
		var tt = _nc.may.hien_tai
		_dung(tt.bi_khoa(), "đầu cú vung: KHOÁ CỨNG")
		_dung(not tt.cho_noi(), "đầu cú vung: chưa nối được")
		_dung(not tt.cho_ne(), "đầu cú vung: chưa né được")
		var m := VocabDB.don_cua(Tui.moveset_dang_dung(), "nhe_1")
		var t_den := float(m.get("t_dam_den", 0.3))
		var t_hoi := float(m.get("t_hoi", 0.5))
		# Giữa cửa sổ NỐI: nối được, chưa né được. Đây là quãng buộc phải chọn.
		var giua_noi := t_den + t_hoi * (SoulsLike.ti_le_cua_so_noi
			+ SoulsLike.ti_le_cua_so_thu) * 0.5
		await _den_moc(giua_noi)
		if _nc.may.ten_hien_tai == "danh":
			var t2 = _nc.may.hien_tai
			_dung(t2.cho_noi(), "giữa cửa sổ NỐI: nối được")
			_dung(not t2.cho_ne(), "giữa cửa sổ NỐI: VẪN CHƯA né được")
			_dung(not t2.bi_khoa(), "và không còn khoá cứng")
		else:
			_dung(false, "đòn kết thúc trước cửa sổ nối")
		# Cuối khung hồi: né được.
		await _den_moc(t_den + t_hoi * (SoulsLike.ti_le_cua_so_thu + 1.0) * 0.5)
		if _nc.may.ten_hien_tai == "danh":
			_dung(_nc.may.hien_tai.cho_ne(), "cuối khung hồi: né được")
		else:
			_dung(false, "đòn kết thúc trước cửa sổ thủ")
	await _cho(1.2)

	# --- ƯU TIÊN: phòng thủ thắng tấn công ---
	#
	# Lúc hoảng người chơi bấm cả hai. Né sai thì mất một nhịp, đánh sai thì
	# mất một mạng — nên chiều đúng là cho né thắng.
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	_nc.ghi_dem("don_nhe")
	_nc.ghi_dem("lan")        # bấm sau ⇒ đè lên, và nó là lệnh phòng thủ
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "lan", "bấm đánh rồi bấm né: RA NÉ")
	await _cho(1.2)

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Chờ tới đúng mốc `giay` tính từ lúc đòn bắt đầu, đo bằng đồng hồ của state.
##
## Không dùng `_cho()`: nó đo từ lúc GỌI, mà giữa lúc gọi với lúc đòn bắt đầu
## đã trôi mất vài khung hình — cộng dồn lại đủ để vượt qua cả một cửa sổ.
func _den_moc(giay: float) -> void:
	var han := 0.0
	while han < giay + 1.0:
		await get_tree().physics_frame
		han += 1.0 / float(Engine.physics_ticks_per_second)
		if _nc.may.ten_hien_tai != "danh":
			return
		if _nc.may.hien_tai.t >= giay:
			return

## NHỊP COMBO: nối đòn phải CẮT khung hồi, và cú bấm sớm không được bị nuốt.
##
## Hai thứ này hỏng theo kiểu khác nhau nhưng ra cùng một cảm giác — "khựng" —
## nên phải kiểm cả hai:
##   1. Bắt cú bấm quá muộn ⇒ phím hết hạn trong bộ đệm, bấm mà không ra gì.
##   2. Nối đòn mà vẫn đợi trọn khung hồi ⇒ không phải nối, chỉ là xếp hàng.
##
## Cả hai đều không làm test nào cũ đỏ: state vẫn đúng, sát thương vẫn đúng,
## chỉ có nhịp là sai. Đo bằng LÚC HỘP ĐÒN BẬT, vì đó mới là lúc người chơi
## cảm nhận một nhát chém.
func _nhip_combo() -> void:
	_nhom("Nhịp combo: nối đòn cắt khung hồi")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)

	var mv := Tui.moveset_dang_dung()
	var m1 := VocabDB.don_cua(mv, "nhe_1")
	var t_den := float(m1.get("t_dam_den", 0.3))
	var t_hoi := float(m1.get("t_hoi", 0.5))

	# --- Bấm SỚM (giữa khung vung tay) vẫn phải nối được ---
	#
	# Đây là chỗ hỏng cũ: bộ đệm chỉ giữ DEM_NHAP giây, mà bản trước chỉ hỏi
	# tới nó từ `t_dam_den` trở đi. Vũ khí nào có `t_dam_den` lớn hơn hạn dùng
	# của đệm thì cú bấm bốc hơi trước khi có ai hỏi.
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	_nc.the_luc = _nc.the_luc_max
	await _giu("don_nhe", 0.04)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "nhát một ra")
	# Bấm ngay TRƯỚC lúc cửa sổ nối mở, trong hạn dùng của bộ đệm. Bấm sớm hơn
	# thì lệnh hết hạn trước khi cửa sổ mở — và đó là hành vi ĐÚNG, không phải
	# lỗi: bộ đệm souls-like cố ý có hạn dùng.
	var mo_noi := t_den + t_hoi * SoulsLike.ti_le_cua_so_noi
	await _cho(maxf(0.0, mo_noi - NguoiChoi.DEM_NHAP * 0.5))
	await _giu("don_nhe", 0.04)
	# Chờ THEO SỰ KIỆN, không theo đồng hồ. Canh sát mốc nối thì phép thử chập
	# chờn: nó rơi đúng vào khung hình mà đòn hai vừa bắt đầu hay chưa là
	# chuyện của nhịp vật lý, không phải của cơ chế đang kiểm.
	var don2 := "?"
	var han := t_den + t_hoi + 0.8
	var da := 0.0
	while da < han:
		await get_tree().physics_frame
		da += 1.0 / float(Engine.physics_ticks_per_second)
		if _nc.may.ten_hien_tai == "danh" and _nc.may.hien_tai._don == "nhe_2":
			don2 = "nhe_2"
			break
	_bang(don2, "nhe_2", "bấm sớm giữa cú vung vẫn NỐI được sang nhát hai")

	# --- Và nó phải tới SỚM HƠN mốc hết đòn ---
	_dung(SoulsLike.ti_le_cua_so_noi < 1.0,
		"nối đòn cắt bớt khung hồi (mở ở %.0f%% khung hồi)"
		% (SoulsLike.ti_le_cua_so_noi * 100.0))
	# Thứ tự hai cửa sổ LÀ thiết kế, nên nó phải có phép thử riêng: đảo lại là
	# lăn luôn thắng combo, và cái quyết định "đánh tiếp hay rút ra" biến mất.
	_dung(SoulsLike.ti_le_cua_so_noi < SoulsLike.ti_le_cua_so_thu,
		"cửa sổ NỐI mở TRƯỚC cửa sổ THỦ (%.2f < %.2f)"
		% [SoulsLike.ti_le_cua_so_noi, SoulsLike.ti_le_cua_so_thu])
	await _cho(2.0)

	# --- KHÔNG bấm thì phải chạy TRỌN khung hồi rồi mới về đứng ---
	#
	# Thiếu phép thử này thì hạ `ti_le_hoi_khi_noi` về 0 vẫn xanh, mà game thì
	# thành ra đòn nào cũng không có đuôi — đánh xong là đứng ngay, và cả khái
	# niệm "khung hồi" biến mất.
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	await _giu("don_nhe", 0.04)
	await _hai_khung()
	await _cho((t_den + t_hoi) * 0.75)
	_bang(_nc.may.ten_hien_tai, "danh",
		"không bấm tiếp thì vẫn đang trong khung hồi ở 75%% cú đánh")
	await _cho((t_den + t_hoi) * 0.4)
	_bang(_nc.may.ten_hien_tai, "dung", "hết khung hồi mới về đứng")

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## CỬA SỔ HUỶ ĐÒN, XOÁ ĐỆM PHÍM, KHỰNG HÌNH — ba thứ của mốc "huỷ đòn".
##
## Cả ba đều là loại hỏng im lặng: cửa sổ huỷ mở sai lúc thì game vẫn chạy, chỉ
## là hết rủi ro; đệm phím không xoá thì nhân vật tự lăn sau khi ăn đòn; khựng
## hình kẹt thì `Engine.time_scale` nằm lại ở 0.02 và cả game chạy chậm 50 lần
## mà không lỗi nào nổ.
func _cua_so_huy_va_khung_dung() -> void:
	_nhom("Cửa sổ huỷ đòn, xoá đệm, khựng hình")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)

	# --- ĐOẠN 1–2: khoá cứng, lăn không cắt được ---
	_lam_moi_nguoi_choi()
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	var tt = _nc.may.hien_tai
	_bang(_nc.may.ten_hien_tai, "danh", "vung đòn")
	_dung(tt.giai_doan() <= tt.GD_CHAM,
		"vừa vung là đang ở đoạn khởi/chạm (đoạn %d)" % tt.giai_doan())
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "danh", "đoạn khoá cứng: lăn KHÔNG cắt được")

	await _cho(1.4)

	var m := VocabDB.don_cua(Tui.moveset_dang_dung(), "nhe_1")
	var t_den := float(m.get("t_dam_den", 0.3))
	var t_hoi := float(m.get("t_hoi", 0.5))
	var mo := t_den + t_hoi * SoulsLike.ti_le_cua_so_thu   ## cửa sổ THỦ mở lúc này
	# Chờ tới giữa cửa sổ THỦ: quá sớm thì chưa mở, quá muộn thì đòn tự hết.
	var cho := t_den + t_hoi * (SoulsLike.ti_le_cua_so_thu + 1.0) * 0.5

	# --- ĐỆM PHÍM: bấm TRƯỚC khi cửa sổ mở, nổ ra đúng lúc nó mở ---
	#
	# Đây là cả điểm của bộ đệm: không ai canh được đúng khung hình cửa sổ mở,
	# nên cú bấm hơi sớm phải được GIỮ LẠI chứ không nuốt mất.
	#
	# Bấm trong vòng `DEM_NHAP` giây trước lúc mở, không sớm hơn: đệm có hạn
	# dùng, và có hạn dùng là cố ý — giữ vô thời hạn thì mọi cú bấm nhầm đều
	# nổ ra muộn, và người chơi đọc ra là game tự chơi lấy.
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	await _cho(maxf(0.0, mo - NguoiChoi.DEM_NHAP * 0.5))
	await _space_lan()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm lúc cửa sổ chưa mở: chưa cắt ngay")
	await _cho(NguoiChoi.DEM_NHAP * 0.5 + 0.12)
	_bang(_nc.may.ten_hien_tai, "lan",
		"cú lăn bấm hơi sớm NẰM CHỜ rồi nổ ra đúng lúc cửa sổ thủ mở")
	await _cho(1.2)

	# --- ĐOẠN 4: bấm lăn ĐÚNG trong cửa sổ thì cắt ngay ---
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_nc.xoa_dem()
	await _cho(cho - 0.05)
	if _nc.may.ten_hien_tai == "danh":
		_dung(_nc.may.hien_tai.giai_doan() >= tt.GD_THU,
			"tới cuối khung hồi thì mở cửa sổ THỦ (đoạn %d)"
			% _nc.may.hien_tai.giai_doan())
		await _space_lan()
		_bang(_nc.may.ten_hien_tai, "lan", "trong cửa sổ THỦ: lăn CẮT được đòn")
	else:
		_dung(false, "đòn kết thúc sớm hơn cửa sổ thủ (%s)" % _nc.may.ten_hien_tai)
	await _cho(1.2)

	# --- XOÁ ĐỆM khi bị cắt ngang ---
	_lam_moi_nguoi_choi()
	_nc.xoa_dem()
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	await _space_lan()
	_dung(_nc.co_dem("lan"), "cú lăn bị chặn thì NẰM LẠI trong đệm")
	_nc.an_don(1, _nc.the_dung() + 50.0, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "trung_don", "ăn đòn to thì khựng lại")
	_dung(not _nc.co_dem("lan"),
		"và bộ đệm bị VỨT SẠCH — không tự lăn một phát khi vừa đứng vững")
	await _cho(1.2)
	_lam_moi_nguoi_choi()

	# --- KHỰNG HÌNH ---
	KhungDung.bat = true
	_dung(not KhungDung.dang_khung(), "chưa đánh ai thì không khựng")
	KhungDung.theo_sat_thuong(200.0)
	_dung(KhungDung.dang_khung(), "gọi khựng thì nó khựng")
	_dung(Engine.time_scale < 0.5, "và đồng hồ game chậm hẳn lại (%.3f)"
		% Engine.time_scale)
	# ĐẾM BẰNG THỜI GIAN THẬT. `_cho()` dùng SceneTreeTimer, mà timer bị chính
	# `time_scale` bóp — đợi bằng nó là đợi gấp năm mươi lần, hoặc treo hẳn.
	var han := Time.get_ticks_msec() + 400
	while KhungDung.dang_khung() and Time.get_ticks_msec() < han:
		await get_tree().process_frame
	_dung(not KhungDung.dang_khung(), "rồi TỰ GỠ, không kẹt lại")
	_bang(Engine.time_scale, 1.0, "và trả đồng hồ về đúng 1.0")
	KhungDung.bat = false

	_bit_mat_quai(false)

## KHOÁ MỤC TIÊU: mặt luôn quay về con quái, chân đi bốn hướng riêng.
##
## Đây là chỗ phần luật và phần nhìn phải đồng ý với nhau, mà cả hai đều có thể
## đúng một mình: luật quay mặt đúng về mục tiêu, phần nhìn phát clip đi tới —
## và cái ra được là một người bước ngược chiều thân. Không phép thử nào cũ với
## tới, vì cả hai vế đều "đúng".
func _khoa_muc_tieu_strafe() -> void:
	_nhom("Khoá mục tiêu: quay mặt và đi ngang")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	var cho_cu := _nc.global_position
	_lam_moi_nguoi_choi()

	# Dựng một mục tiêu ở đúng phía TRƯỚC, rồi tự quay nhân vật đi chỗ khác.
	var quai := _quai_gan_nhat()
	if quai == null:
		_dung(false, "không tìm được con quái nào để khoá")
		return
	_nc.global_position = quai.global_position - Vector3(0, 0, 4.0)
	_nc.velocity = Vector3.ZERO
	await _hai_khung()
	_nc.dat_muc_tieu(quai)
	_dung(_nc.muc_tieu == quai, "khoá được vào con quái")

	# Quay lưng lại rồi đứng yên: đang khoá thì phải TỰ xoay về mục tiêu.
	_nc.than.rotation.y += PI
	await _cho(0.8)
	var toi_quai: Vector3 = quai.global_position - _nc.global_position
	toi_quai.y = 0.0
	var lech := rad_to_deg(_nc.huong_mat().angle_to(toi_quai.normalized()))
	_dung(lech < 20.0, "đứng yên mà đang khoá thì vẫn tự quay về mục tiêu (lệch %.0f°)" % lech)

	# Dạt NGANG: thân vẫn nhìn quái, còn clip phải là clip đi ngang.
	if _nc.than.has_method("dong_tac_dang_phat"):
		await _nut("di_trai", true)
		await _cho(0.45)
		var clip: String = _nc.than.call("dong_tac_dang_phat")
		var van_nhin: Vector3 = quai.global_position - _nc.global_position
		van_nhin.y = 0.0
		var lech2 := rad_to_deg(_nc.huong_mat().angle_to(van_nhin.normalized()))
		await _nut("di_trai", false)
		await _hai_khung()
		_dung(clip.ends_with("_trai") or clip.ends_with("_phai"),
			"dạt ngang thì phát clip ĐI NGANG, không phải clip đi tới (%s)" % clip)
		_dung(lech2 < 30.0,
			"và trong lúc dạt vẫn quay mặt về quái (lệch %.0f°)" % lech2)

	# Nhả khoá là về đi tự do: quay mặt theo phím, không theo quái nữa.
	_nc.dat_muc_tieu(null)
	await _nut("di_trai", true)
	await _cho(0.6)
	var clip2: String = _nc.than.call("dong_tac_dang_phat") 		if _nc.than.has_method("dong_tac_dang_phat") else ""
	await _nut("di_trai", false)
	await _hai_khung()
	_dung(not (clip2.ends_with("_trai") or clip2.ends_with("_phai")),
		"nhả khoá thì xoay người theo phím và đi TỚI, không dạt ngang nữa (%s)" % clip2)

	_nc.global_position = cho_cu
	_nc.velocity = Vector3.ZERO
	await _hai_khung()
	_lam_moi_nguoi_choi()

func _quai_gan_nhat() -> Node3D:
	var tot: Node3D = null
	var xa := 1e9
	for q in get_tree().get_nodes_in_group("quai"):
		if not (q is Node3D) or not is_instance_valid(q):
			continue
		if q.has_method("con_song") and not q.call("con_song"):
			continue
		var d: float = (q as Node3D).global_position.distance_to(_nc.global_position)
		if d < xa:
			xa = d
			tot = q as Node3D
	return tot

## Đòn Bổ: chạm là GÃY, còn đòn nhẹ thì không.
##
## Cặp đôi này phải thử CÙNG NHAU. Thử một mình cái gãy thì không phân biệt được
## "đòn nặng cố ý mong manh" với "mọi đòn đều bị cắt", mà hai thứ đó là hai game
## khác nhau.
func _don_nang_de_gay() -> void:
	_nhom("Đòn Bổ không có giáp: chạm là gãy")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)

	# Một đòn NHỎ: phá thế 6, thừa sức bị nuốt bởi thế đứng thường.
	var pha_nho := 6.0

	# --- Đòn NHẸ nuốt được cú chạm đó ---
	_lam_moi_nguoi_choi()
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "vung đòn nhẹ")
	_nc.an_don(1, pha_nho, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh",
		"đòn NHẸ có siêu giáp: chạm nhẹ không cắt được")
	await _cho(1.2)

	# --- Đòn BỔ thì gãy ngay ---
	_lam_moi_nguoi_choi()
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.05)
	await _hai_khung()
	var don: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_bang(don, "nang", "giữ chuột ra đòn BỔ")
	_dung(_nc.may.hien_tai.has_method("de_gay") and _nc.may.hien_tai.call("de_gay"),
		"và đòn Bổ khai là loại chạm-là-gãy trong moveset.csv")
	_nc.an_don(1, pha_nho, _truoc_mat())
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "trung_don",
		"cùng cú chạm đó CẮT ĐỨT đòn Bổ")
	await _cho(1.2)

	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Tốc độ đi, và BÀN CHÂN CÓ BÁM ĐẤT KHÔNG.
##
## Nhóm này kiểm một thứ mà không phép thử nào khác với tới: quan hệ giữa tốc
## độ đi của LUẬT và tốc độ tự đi của CLIP. Lệch nhau thì chân trượt, mà luật
## vẫn đúng từng con số nên mọi phép thử khác vẫn xanh.
func _toc_do_va_bam_chan() -> void:
	_nhom("Tốc độ đi và bàn chân bám đất")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return
	_bit_mat_quai(true)
	var cho_cu := _nc.global_position

	var rut := await _do_toc(true)
	var cat := await _do_toc(false)
	_dung(cat[0] > rut[0],
		"cất vũ khí thì đi NHANH hơn (%.2f > %.2f m/s)" % [cat[0], rut[0]])

	# Hệ số phát chạm đúng trần nghĩa là ĐANG BỊ KẸP: clip quá chậm so với tốc
	# độ đi, và bàn chân đang trượt trên đất. Đây là cách duy nhất đo được
	# chuyện đó mà không phải nhìn.
	var tran := ThanMoHinh.TOC_CLIP_MAX
	_dung(rut[1] < tran - 0.01,
		"đi có vũ khí: clip theo kịp, không bị kẹp (hệ số %.2f < %.1f)" % [rut[1], tran])
	_dung(cat[1] < tran - 0.01,
		"đi tay không: clip theo kịp, không bị kẹp (hệ số %.2f < %.1f)" % [cat[1], tran])

	_nc.global_position = cho_cu
	_nc.velocity = Vector3.ZERO
	_nc.da_rut = true
	await _hai_khung()
	_lam_moi_nguoi_choi()
	_bit_mat_quai(false)

## Đi thẳng một quãng rồi trả về [tốc độ m/s, hệ số phát clip].
func _do_toc(rut: bool) -> Array:
	_lam_moi_nguoi_choi()
	_nc.da_rut = rut
	_nc.global_position = Vector3(0, 1.2, 0)
	_nc.velocity = Vector3.ZERO
	await _hai_khung()
	await _nut("di_truoc", true)
	# Đợi nhân vật đạt tốc rồi mới bấm giờ — đo cả quãng tăng tốc là đo sai.
	await _cho(0.5)
	var tu := _nc.global_position
	var he_so := 1.0
	if _nc.than.has_method("he_so_phat"):
		he_so = float(_nc.than.call("he_so_phat"))
	await _cho(0.5)
	var di: Vector3 = _nc.global_position - tu
	di.y = 0.0
	await _nut("di_truoc", false)
	await _hai_khung()
	return [di.length() / 0.5, he_so]

## MP, tuỳ chọn, minimap, màn tạm dừng — bốn thứ mới của đợt dựng giao diện.
##
## Giao diện là chỗ dễ hỏng âm thầm y như bộ nút: thiếu một file ảnh thì HUD vẫn
## vẽ, chỉ là trống một mảng, và không lỗi nào nổ ra. Nên phần lớn nhóm này
## kiểm thứ KHÔNG nhìn thấy được: font có dự phòng chữ Hán không, ảnh nạp được
## không, tuỳ chọn có ghi xuống đĩa không.
func _mp_va_giao_dien() -> void:
	_nhom("MP, tuỳ chọn, minimap, màn tạm dừng")
	if _nc == null:
		_dung(false, "không có người chơi để thử")
		return

	# --- MP ---
	_nc.mp = _nc.mp_toi_da
	_bang(_nc.mp_toi_da, Tui.mp_toi_da(), "trần MP lấy từ chỉ số 心")
	var truoc := _nc.mp
	_dung(_nc.tieu_mp(10.0), "đủ MP thì tiêu được")
	_bang(_nc.mp, truoc - 10.0, "và trừ đúng bấy nhiêu")
	_dung(not _nc.tieu_mp(_nc.mp_toi_da * 2.0), "không đủ MP thì trả false")
	_bang(_nc.mp, truoc - 10.0, "và KHÔNG tiêu gì cả — không có nửa câu thần chú")

	# Hồi lại sau khoảng trễ. Tiêu xong là trễ, nên phải đợi qua MP_TRE_HOI.
	var sau_tieu := _nc.mp
	await _cho(SoulsLike.MP_TRE_HOI + 0.6)
	_dung(_nc.mp > sau_tieu, "qua khoảng trễ thì MP tự hồi (%.0f → %.0f)"
		% [sau_tieu, _nc.mp])
	_nc.mp = _nc.mp_toi_da

	# --- Font: PHẢI có dự phòng chữ Hán ---
	#
	# Không font nào trong bộ asset có 漢字. Gỡ chuỗi dự phòng đi là mọi tên món
	# đồ thành ô vuông, mà ô vuông thì trông y hệt cơ chế ??? của game — hỏng
	# kiểu đó không ai nhận ra được bằng mắt.
	_dung(GiaoDien.chu_than != null, "có font chữ thường")
	var dp := (GiaoDien.chu_than as FontFile).fallbacks if GiaoDien.chu_than is FontFile else []
	_dung(dp.size() > 0, "font chữ thường CÓ gắn font dự phòng")
	_dung(GiaoDien.chu_than.has_char("ế".unicode_at(0)),
		"font chính có dấu tiếng Việt (luật 2: giao diện tiếng Việt)")

	# --- Theme phải tới được Control THẬT ---
	#
	# Gán theme ở root KHÔNG ăn trong Godot 4.7 (đã đo), nên màn nào quên gọi
	# GiaoDien.ap_theme() thì Label của nó dùng font mặc định của engine — mà
	# font đó không có chữ Hán. Hỏng kiểu này trông y hệt cơ chế ??? của game:
	# tên món đồ ra ô vuông, và không ai phân biệt được bằng mắt.
	var man_ht := get_tree().get_first_node_in_group("man_hanh_trang") as ManChung
	if man_ht != null:
		var l := Label.new()
		man_ht.khung.add_child(l)
		await get_tree().process_frame
		_dung(l.get_theme_font("font") == GiaoDien.chu_than,
			"Label trong màn hình ăn đúng font chung (có dự phòng chữ Hán)")
		man_ht.khung.remove_child(l)
		l.queue_free()

	# --- Hai kiểu nút phải TÁCH nhau ---
	#
	# Vệt cọ đỏ chỉ dành cho nút to ở menu. Để nó thành kiểu của mọi Button thì
	# danh sách đồ trong hành trang — mỗi món một Button — biến thành bức tường
	# vệt sơn. Đã hỏng đúng như vậy một lần, bắt được bằng ảnh chụp thử.
	var n_ds := Button.new()
	var n_menu := Button.new()
	n_menu.theme_type_variation = GiaoDien.NUT_MENU
	_ve_tam(n_ds)
	_ve_tam(n_menu)
	await get_tree().process_frame
	_dung(n_ds.get_theme_stylebox("normal") is StyleBoxFlat,
		"nút DANH SÁCH dùng nền phẳng — đọc được, không nuốt chữ")
	_dung(n_menu.get_theme_stylebox("normal") is StyleBoxTexture,
		"nút MENU dùng vệt cọ đỏ của bộ asset")
	n_ds.queue_free()
	n_menu.queue_free()

	# --- Dòng mời phải nói ĐÚNG phím đang gán ---
	#
	# Lỗi này đã lọt một lần: phím tương tác dọn từ E sang F, mà bốn dòng mời
	# trên màn chơi vẫn mời "E — nhặt". Người chơi đứng trên món đồ bấm E và
	# không có gì xảy ra. KHÔNG test nào cũ bắt được, vì "E — nhặt" vẫn là một
	# chuỗi hợp lệ — phải so với InputMap mới thấy.
	_bang(GiaoDien.ten_phim("tuong_tac"), "F",
		"ten_phim('tuong_tac') đọc từ InputMap ra đúng phím đang gán")
	var phim_tt := GiaoDien.ten_phim("tuong_tac")
	var so_moi := 0
	for nhom in ["bia_da", "vat_roi", "vung_hon", "npc"]:
		for n in get_tree().get_nodes_in_group(nhom):
			var tt := n as TuongTacDuoc
			if tt == null:
				continue
			so_moi += 1
			_dung(tt.dong_moi().begins_with(phim_tt),
				"dòng mời của %s mở đầu bằng phím thật (\"%s\")"
				% [nhom, tt.dong_moi()])
	_dung(so_moi > 0, "có ít nhất một thứ tương tác được để thử (%d)" % so_moi)

	# --- Minimap KHÔNG được phủ mặt nạ lên mặt bản đồ ---
	#
	# "Minimap_Mask.png" nghe như khung viền nhưng là một MẶT NẠ: xám đều ở
	# alpha ~0.8 trên toàn đĩa. Vẽ đè lên là phủ voan xám kín bản đồ, càng
	# phóng to càng rõ. Canh bằng cách đọc chính file đó, không phải bằng mắt.
	var mn := GiaoDien.anh("Minimap/Minimap_Mask.png")
	if mn != null:
		var px := mn.get_image()
		var giua_px := px.get_pixel(px.get_width() / 2, px.get_height() / 2)
		_dung(giua_px.a > 0.5,
			"Minimap_Mask ĐỤC ở giữa (a=%.2f) — nên nó là mặt nạ, không phải viền"
			% giua_px.a)

	# --- Ảnh giao diện nạp được ---
	for duong in ["Action Bar/Globes/ActionBar_Globe_Fill.png",
			"Action Bar/Globes/ActionBar_Globe_Background.png",
			"Action Bar/ActionBar_Background.png",
			"Action Bar/Slot/ActionBar_Slot_Frame.png",
			"Minimap/Pins/Minimap_Pin_Red.png",
			"XP Bar/XPBar_Fill.png", "Buttons/Rectangular/Button_RL_Background.png"]:
		_dung(GiaoDien.anh(duong) != null, "nạp được ảnh %s" % duong)

	# --- Tuỳ chọn: đổi, áp dụng, ghi đĩa ---
	var cu = CaiDat.lay("do_nhay_chuot")
	CaiDat.dat("do_nhay_chuot", 1.75)
	_bang(CaiDat.lay("do_nhay_chuot"), 1.75, "đổi tuỳ chọn thì đọc lại ra giá trị mới")
	_dung(FileAccess.file_exists(CaiDat.DUONG), "đổi xong là GHI ĐĨA ngay, không đợi nút Lưu")
	# Cảnh báo "Khong co tuy chon" in ra ở đây là ĐÚNG — đó chính là thứ đang thử.
	CaiDat.dat("khong_co_khoa_nay", 1)
	_dung(CaiDat.lay("khong_co_khoa_nay") == null, "khoá lạ thì bỏ qua, không nhét vào")
	CaiDat.ve_mac_dinh()
	_bang(CaiDat.lay("do_nhay_chuot"), CaiDat.MAC_DINH["do_nhay_chuot"],
		"về mặc định thì trả đúng giá trị gốc")
	CaiDat.dat("do_nhay_chuot", cu)

	# --- Tầng CHỜ XÁC NHẬN: đổi gì cũng phải bấm Áp dụng mới ăn ---
	#
	# Đây là cả điểm của nút Áp dụng: kéo thanh trượt mà game đổi ngay thì người
	# chơi mất luôn cái mốc cũ để so, và mỗi nhích giữa chừng là một lần ghi đĩa.
	CaiDat.bo_thay_doi()
	_dung(not CaiDat.co_thay_doi(), "chưa đụng gì thì không có thay đổi nào chờ")
	var nhay_cu = CaiDat.lay("do_nhay_chuot")
	CaiDat.dat_nhap("do_nhay_chuot", 2.5)
	_dung(CaiDat.co_thay_doi(), "ghi tầng chờ thì co_thay_doi() bật")
	_bang(CaiDat.lay("do_nhay_chuot"), nhay_cu,
		"nhưng game VẪN đọc giá trị cũ — chưa áp dụng thì chưa đổi")
	_bang(CaiDat.lay_nhap("do_nhay_chuot"), 2.5,
		"còn màn Tuỳ chọn thì hiện giá trị đang chờ")

	# Kéo về đúng chỗ cũ là thay đổi tự biến mất — nút Áp dụng phải tắt lại.
	CaiDat.dat_nhap("do_nhay_chuot", nhay_cu)
	_dung(not CaiDat.co_thay_doi(),
		"kéo trở lại đúng giá trị cũ thì thay đổi tự biến mất")

	CaiDat.dat_nhap("do_nhay_chuot", 2.5)
	CaiDat.bo_thay_doi()
	_dung(not CaiDat.co_thay_doi(), "bỏ thay đổi thì tầng chờ sạch")
	_bang(CaiDat.lay("do_nhay_chuot"), nhay_cu, "và game không hề biết gì đã xảy ra")

	CaiDat.dat_nhap("do_nhay_chuot", 2.5)
	CaiDat.ap_thay_doi()
	_bang(CaiDat.lay("do_nhay_chuot"), 2.5, "bấm Áp dụng thì giá trị mới vào game")
	_dung(not CaiDat.co_thay_doi(), "áp xong thì tầng chờ sạch")
	CaiDat.dat("do_nhay_chuot", nhay_cu)

	# --- Gán lại phím ---
	#
	# Phím mới chỉ vào InputMap lúc bấm Áp dụng. Không có luật đó thì bấm nhầm
	# một phím giữa chừng là điều khiển đổi ngay trong lúc còn đang chọn.
	var e_phim := InputEventKey.new()
	e_phim.physical_keycode = KEY_G
	CaiDat.dat_phim_nhap("tuong_tac", e_phim)
	_dung(CaiDat.co_thay_doi(), "gán phím mới thì co_thay_doi() bật")
	_bang(GiaoDien.ten_phim("tuong_tac"), "F",
		"nhưng InputMap CHƯA đổi — vẫn là phím cũ")
	CaiDat.ap_thay_doi()
	_bang(GiaoDien.ten_phim("tuong_tac"), "G", "bấm Áp dụng thì InputMap đổi thật")

	# Phím THAY THẾ phải còn nguyên: khoá mục tiêu có cả chuột giữa lẫn Tab,
	# đổi cái đầu mà xoá luôn cái sau là lấy mất một thứ người chơi không hề
	# yêu cầu.
	#
	# Nhóm này từng canh trên `do_phan` vì nó có cả E lẫn chuột phải. Từ khi
	# đỡ và đỡ phản gộp vào MỘT nút thì `do_phan` chỉ còn một phím, nên phép
	# thử phải dọn sang action khác — chứ không phải bỏ đi.
	var goc_kmt := GiaoDien.ten_moi_phim("khoa_muc_tieu")
	_dung(goc_kmt.contains(" · "), "khoá mục tiêu có hai phím (%s)" % goc_kmt)
	var e2 := InputEventKey.new()
	e2.physical_keycode = KEY_H
	CaiDat.dat_phim_nhap("khoa_muc_tieu", e2)
	CaiDat.ap_thay_doi()
	var moi_kmt := GiaoDien.ten_moi_phim("khoa_muc_tieu")
	_dung(moi_kmt.contains("H"), "đổi được phím chính (%s)" % moi_kmt)
	_dung(moi_kmt.contains(goc_kmt.split(" · ")[1]),
		"và phím THAY THẾ còn nguyên (%s)" % moi_kmt)

	# Về mặc định phải dựng lại được TỪ BẢNG GỐC — lúc này InputMap đã bị ghi đè.
	CaiDat.ve_mac_dinh()
	_bang(GiaoDien.ten_phim("tuong_tac"), "F", "về mặc định thì phím trở lại như cũ")
	_bang(GiaoDien.ten_moi_phim("khoa_muc_tieu"), goc_kmt,
		"cả phím chính lẫn phím thay thế đều trở lại")

	# --- Nút Áp dụng: TỐI khi chưa đổi, SÁNG khi có đổi ---
	var man_cd := get_tree().get_first_node_in_group("man_cai_dat")
	if man_cd != null:
		man_cd.call("mo")
		man_cd.call("_di_trang", 1)
		await get_tree().process_frame
		await get_tree().process_frame
		var nut_ap = man_cd.get("_nut_ap")
		_dung(nut_ap != null, "trang Tuỳ chọn có nút Áp dụng")
		if nut_ap != null:
			_dung(nut_ap.disabled, "chưa đổi gì thì nút Áp dụng TỐI")
			CaiDat.dat_nhap("do_nhay_chuot", 2.0)
			await get_tree().process_frame
			await get_tree().process_frame
			_dung(not nut_ap.disabled, "có thay đổi thì nút Áp dụng SÁNG lên")
		# Rời trang là vứt thay đổi chưa xác nhận.
		man_cd.call("_ve_menu")
		_dung(not CaiDat.co_thay_doi(), "rời trang thì thay đổi chưa xác nhận bị vứt")
		man_cd.call("dong")
		await get_tree().process_frame
	CaiDat.ve_mac_dinh()

	# --- Minimap ---
	var mm := get_tree().get_first_node_in_group("minimap") as Minimap
	_dung(mm != null, "HUD có gắn minimap")
	if mm != null:
		_dung(mm.nc == _nc, "minimap biết người chơi là ai")
		# Đợi khung IDLE chứ không phải khung vật lý: minimap đọc tuỳ chọn
		# trong _process(), mà _process chạy theo nhịp idle. Đợi physics_frame
		# thì có lúc trúng có lúc trượt, và test đâm ra lúc xanh lúc đỏ.
		CaiDat.dat("hien_minimap", false)
		await get_tree().process_frame
		await get_tree().process_frame
		_dung(not mm.visible, "tắt trong Tuỳ chọn thì minimap ẩn")
		# Bán kính khai theo chiều cao tham chiếu 1080 rồi co giãn theo cửa sổ
		# thật — đó là thứ giữ cho minimap chiếm đúng một phần màn hình như
		# nhau ở mọi cỡ cửa sổ. Không có luật này thì kéo cửa sổ nhỏ lại là bản
		# đồ nuốt mất góc màn hình.
		var hud = get_tree().get_first_node_in_group("hud")
		if hud != null:
			var cao: float = get_viewport().get_visible_rect().size.y
			var mong: float = float(hud.get("minimap_ban_kinh")) * cao / 1080.0
			_dung(absf(mm.ban_kinh - mong) < 0.5,
				"bán kính minimap co giãn theo cửa sổ (%.1f, muốn %.1f ở cao %.0f)"
				% [mm.ban_kinh, mong, cao])
		CaiDat.dat("hien_minimap", true)
		await get_tree().process_frame
		await get_tree().process_frame
		_dung(mm.visible, "bật lại thì hiện")

	# --- Màn tạm dừng: Esc mở, Esc ở trang con là QUAY LẠI ---
	var man := get_tree().get_first_node_in_group("man_cai_dat") as ManChung
	_dung(man != null, "có màn tạm dừng trong scene")
	if man != null:
		_dung(not man.dang_mo, "chưa bấm thì màn đóng")
		await _bam("thoat")
		_dung(man.dang_mo, "bấm Esc là màn tạm dừng mở ra")
		_dung(get_tree().paused, "mở menu thì game DỪNG")
		_bang(man._trang, 0, "mở ra là ở trang chính")

		man._di_trang(1)
		await _hai_khung()
		_bang(man._trang, 1, "vào được trang Tuỳ chọn")
		await _bam("thoat")
		_bang(man._trang, 0, "Esc ở trang con là QUAY LẠI, không phải đóng màn")
		_dung(man.dang_mo, "và màn vẫn đang mở")

		await _bam("thoat")
		_dung(not man.dang_mo, "Esc ở trang chính thì đóng màn")
		_dung(not get_tree().paused, "đóng menu thì game chạy lại")

	_lam_moi_nguoi_choi()

## Gắn tạm một Control vào đúng chỗ có theme để hỏi nó resolve ra cái gì.
## Phải nằm DƯỚI khung của một ManChung: theme được gán ở đó, không ở root.
func _ve_tam(c: Control) -> void:
	var man := get_tree().get_first_node_in_group("man_hanh_trang") as ManChung
	if man != null:
		man.khung.add_child(c)
	else:
		add_child(c)

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
	_bang(_dem_nhom("quai"), 4, "hạ một con thì còn bốn")

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
	_bang(_dem_nhom("quai"), 5, "nghỉ ở bia thì quái sống lại HẾT")

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

	# --- Dáng ngã theo hướng đòn, và màn "BẠN ĐÃ CHẾT" ---
	#
	# Người ngã RA XA cú đánh. Cú vừa rồi tới từ 0 sát thương nên không có
	# hướng; chỗ này kiểm cả hai nhánh bằng cách gọi thẳng `_chon_dang()` với
	# hướng đã biết — không thể giết nhân vật bốn lần trong một phép thử.
	var tt_chet := _nc.may.hien_tai
	_dung(tt_chet.has_method("ten_dien"), "trạng thái chết khai dáng ngã")
	var d_truoc: String = tt_chet._chon_dang({"tu_dau": _truoc_mat()})
	var d_sau: String = tt_chet._chon_dang({"tu_dau": _sau_lung()})
	var d_manh: String = tt_chet._chon_dang({"tu_dau": _truoc_mat(), "manh": true})
	_bang(d_truoc, "sau", "đòn từ TRƯỚC mặt thì đổ NGỬA ra sau")
	_bang(d_sau, "truoc", "đòn từ SAU lưng thì úp mặt về trước")
	_bang(d_manh, "manh", "đòn chí mạng thì dùng dáng ngã dữ, bỏ qua hướng")

	var man: Node = get_tree().get_first_node_in_group("man_chet")
	if man == null:
		for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if n.has_method("dang_hien"):
				man = n
				break
	_dung(man != null, "scene có màn BẠN ĐÃ CHẾT")

	# Chưa tới T_HIEN thì bấm phím KHÔNG được đứng dậy — người chơi lúc chết
	# thường đang giữ phím, nhận ngay là màn hình loé lên rồi biến mất.
	_dung(not tt_chet.call("san_sang"), "vừa ngã thì chưa cho bấm phím")
	tt_chet.call("hoi_sinh")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "chet", "gọi hồi sinh sớm cũng không ăn thua")

	await _cho(1.4)
	_dung(tt_chet.call("san_sang"), "nằm đủ lâu thì mới cho bấm")
	if man != null:
		_dung(man.call("dang_hien"), "và màn BẠN ĐÃ CHẾT đang hiện")
		man.call("tiep_tuc")
	else:
		tt_chet.call("hoi_sinh")
	await _cho(0.4)
	_bang(_nc.may.ten_hien_tai, "dung", "sống lại thì về trạng thái đứng")
	_dung(not _nc.bat_tu, "sống lại thì hết bất tử — không được sót cờ này")
	_bang(_nc.mau, _nc.mau_toi_da, "sống lại là đầy máu")
	_dung(_nc.global_position.distance_to(_bia().diem_hoi_sinh()) < 0.6,
		"đứng dậy ngay cạnh bia đá")
	_bang(_dem_nhom("quai"), 5, "chết cũng làm quái sống lại hết")
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
