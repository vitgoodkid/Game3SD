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
	await _phim_hanh_trang()
	await _quai_roi_do()
	await _nghi_bia_da()
	await _chet_va_hoi_sinh()
	await _nhat_lai_hon()

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
	_nc.khung_tl = 0.0
	await get_tree().physics_frame

	# --- Bấm nhanh = đòn nhẹ, và KHÔNG tốn thể lực ---
	var truoc := _nc.the_luc
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "bấm nhanh chuột trái thì vào trạng thái đánh")
	_bang(_nc.the_luc, truoc, "đòn nhẹ KHÔNG tốn thể lực")
	_bang(_nc.khung_tl, 0.0, "đánh xong không bị khựng hồi thể lực")
	await _cho(1.2)

	# --- Giữ lâu = đòn nặng, cũng không tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.khung_tl = 0.0
	truoc = _nc.the_luc
	await _giu("don_nhe", NguoiChoi.NGUONG_GIU_NANG + 0.12)
	await _hai_khung()
	_dung(_nc.may.ten_hien_tai == "danh", "giữ chuột trái cũng ra đòn — trạng thái: %s"
		% _nc.may.ten_hien_tai)
	var don: String = _nc.may.hien_tai._don if _nc.may.ten_hien_tai == "danh" else "?"
	_dung(don.begins_with("nang"), "giữ lâu ra đòn NẶNG (được '%s')" % don)
	_bang(_nc.the_luc, truoc, "đòn nặng cũng KHÔNG tốn thể lực")
	await _cho(1.6)

	# --- Lăn thì tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.khung_tl = 0.0
	_nc.hoi_lan = 0.0
	truoc = _nc.the_luc
	await _giu("lan_chay", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "lan", "nhả Space sớm thì lăn")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_LAN, "lăn TỐN đúng THE_LUC_LAN")
	await _cho(1.2)

	# --- Đỡ phản thì tốn ---
	_nc.the_luc = _nc.the_luc_max
	_nc.khung_tl = 0.0
	truoc = _nc.the_luc
	await _bam("do_phan")
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "do_phan", "chuột phải ra đỡ phản")
	_bang(_nc.the_luc, truoc - SoulsLike.THE_LUC_DO_PHAN, "đỡ phản TỐN đúng THE_LUC_DO_PHAN")
	await _cho(1.0)

	# --- Cạn thể lực vẫn đánh được: đó là cả điểm của thay đổi này ---
	_nc.the_luc = 0.0
	_nc.khung_tl = 0.0
	await get_tree().physics_frame
	await _giu("don_nhe", 0.05)
	await _hai_khung()
	_bang(_nc.may.ten_hien_tai, "danh", "cạn sạch thể lực vẫn đánh được")
	await _cho(1.2)
	_nc.the_luc = _nc.the_luc_max
	_nc.khung_tl = 0.0

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
