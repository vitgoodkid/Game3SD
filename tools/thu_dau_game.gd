extends Node

## Chạy thử MÀN HÌNH ĐẦU GAME và đường vào ván. Chạy:
##
##     godot --headless --path . tools/thu_dau_game.tscn
##
## Thoát mã 0 nếu tất cả qua, mã 1 nếu có cái hỏng.
##
## Vì sao lại thêm một bộ nữa. Ba bộ cũ đều bị buộc vào MỘT cảnh: `thu_vong_lap`
## nạp phòng thử, `thu_the_gioi` nạp một vùng, `kiem_tra` không nạp cảnh nào.
## Còn thứ cần canh ở đây là việc **ĐỔI CẢNH** — bấm "Chơi mới" là huỷ cảnh
## đang chạy và dựng cảnh khác, mà trạng thái thì nằm trong autoload nên nó
## SỐNG QUA cú đổi ấy. Đúng loại lỗi không bộ nào ở trên với tới được.
##
## Node này cố tình KHÔNG phải `current_scene`: hàm đổi cảnh gỡ và huỷ đúng
## `current_scene`, nên bộ kiểm tra mà ngồi ở đó thì nó tự huỷ chính mình giữa
## chừng — và cái chết đó trông y hệt "test chạy xong".

const CANH_MENU := preload("res://scenes/giao_dien/man_dau_game.tscn")

var _qua := 0
var _hong := 0
var _menu: Node = null
## Bản chụp thư mục save của người thật, để trả lại nguyên vẹn lúc xong.
var _save_cu := {}

func _ready() -> void:
	# Màn đầu game dừng cây scene lúc nó mở. Không có dòng này thì chính bộ
	# kiểm tra đứng hình theo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Đợi một khung trước khi đụng vào cây scene: `_ready()` chạy trong lúc cây
	# còn đang dựng node con, và `add_child()` lúc đó bị từ chối thẳng. Bỏ dòng
	# này thì màn đầu game không vào được cây, `current_scene` vẫn là chính bộ
	# kiểm tra, và cú đổi cảnh ở nhóm "Chơi mới" huỷ luôn nó giữa chừng — treo
	# vô hạn, không báo gì.
	await get_tree().process_frame
	print("")
	print("====== THU MAN HINH DAU GAME ======")
	_cat_save()

	await _mo_menu()
	await _chua_co_save()
	await _hai_trang_con()
	await _khong_dong_duoc()
	await _choi_moi()
	await _luu_va_choi_tiep()

	_tra_save()
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

func _khung() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

# --- Giữ gìn save của người thật -------------------------------------
#
# Bộ kiểm tra này GHI ĐĨA. Chạy nó trên máy chủ dự án mà không cất save đi
# trước là ăn mất ván chơi thật — và đó là loại thiệt hại không có đường lùi.

func _cat_save() -> void:
	_save_cu.clear()
	for o in ["autosave", "1", "2", "3"]:
		var d := LuuGame.duong(o)
		if not FileAccess.file_exists(d):
			continue
		var f := FileAccess.open(d, FileAccess.READ)
		if f != null:
			_save_cu[o] = f.get_as_text()
			f.close()
		LuuGame.xoa(o)

func _tra_save() -> void:
	for o in ["autosave", "1", "2", "3"]:
		LuuGame.xoa(o)
	for o in _save_cu.keys():
		var f := FileAccess.open(LuuGame.duong(String(o)), FileAccess.WRITE)
		if f != null:
			f.store_string(String(_save_cu[o]))
			f.close()

# --- Các nhóm -------------------------------------------------------

## Dựng màn đầu game rồi ĐẶT NÓ LÀM `current_scene`. Bước thứ hai mới là mấu
## chốt: hàm đổi cảnh chỉ gỡ đúng `current_scene`, nên đặt đúng chỗ thì lát nữa
## bấm "Chơi mới" nó huỷ cái menu chứ không huỷ bộ kiểm tra.
func _mo_menu() -> void:
	_nhom("Màn đầu game mở lên")
	_menu = CANH_MENU.instantiate()
	get_tree().root.add_child(_menu)
	get_tree().current_scene = _menu
	await _khung()

	var man := _man()
	_dung(man != null, "có màn đầu game trong cảnh")
	if man == null:
		return
	_dung(man.dang_mo, "màn tự mở, không đợi ai bấm")
	_dung(man.ve_xong, "vẽ trọn tới dòng cuối")
	_bang(man._trang, 0, "mở ra là ở trang gốc")
	_dung(not get_tree().get_nodes_in_group("man_cai_dat").is_empty() == false,
		"KHÔNG nằm chung nhóm với menu tạm dừng")

func _chua_co_save() -> void:
	_nhom("Chưa có ván nào đã lưu")
	_bang(LuuGame.o_moi_nhat(), "", "chưa có ô nào")
	var man := _man()
	if man == null:
		return
	man.call("_ve_trang")
	await _khung()
	var tiep := _nut("Chơi tiếp")
	var tai := _nut("Tải ván")
	_dung(tiep != null and tiep.disabled, "nút Chơi tiếp TỐI khi chưa có save")
	_dung(tai != null and tai.disabled, "nút Tải ván TỐI khi chưa có save")
	_dung(_nut("Chơi mới") != null and not _nut("Chơi mới").disabled,
		"nút Chơi mới luôn bấm được")

## Hai trang con kế thừa từ menu tạm dừng — cái giá trị nhất của việc kế thừa
## thay vì chép, nên phải có phép thử canh rằng chúng còn sống.
func _hai_trang_con() -> void:
	_nhom("Trang Tuỳ chọn và Điều khiển dùng lại được")
	var man := _man()
	if man == null:
		return
	man.call("_di_trang", 1)
	await _khung()
	_dung(man.ve_xong, "trang Tuỳ chọn vẽ trọn")
	_dung(man.get("_nut_ap") != null, "trang Tuỳ chọn có nút Áp dụng")

	man.call("_di_trang", 2)
	await _khung()
	_dung(man.ve_xong, "trang Điều khiển vẽ trọn")

	# Esc ở TRANG CON là quay lại, không phải đóng màn.
	await _bam("thoat")
	_bang(man._trang, 0, "Esc ở trang con thì về trang gốc")
	_dung(man.dang_mo, "và màn vẫn mở")

func _khong_dong_duoc() -> void:
	_nhom("Màn đầu game không đóng được")
	var man := _man()
	if man == null:
		return
	await _bam("thoat")
	_dung(man.dang_mo, "Esc ở trang gốc KHÔNG đóng màn")
	man.call("dong")
	await _khung()
	_dung(man.dang_mo, "gọi thẳng dong() cũng không đóng được")

	# Bẫy đã chặn: tự lưu lúc không có người chơi sẽ ghi đè ô tự lưu bằng một
	# ván rỗng trỏ vào chính cái menu này.
	_dung(not LuuGame.tu_luu(), "không có người chơi thì tự lưu TỪ CHỐI")
	_dung(not LuuGame.co(LuuGame.O_TU_LUU), "và không có file save nào mọc ra")

func _choi_moi() -> void:
	_nhom("Chơi mới")
	# Bẩn sẵn mọi thứ: ván mới phải quét sạch được chúng.
	Tui.hon = 999
	Tui.chi_so["体"] = 40
	Tui.them_bo_thu("木", 5)
	Tui.nhat(SinhMonDo.sinh_mon("thi_tran", 4242))
	TheGioi.bat_bia("bia_gia")
	TheGioi.so_lan_chet = 7
	DuHanh.da_toi["dam_lay"] = true

	var dau := DuHanh.vung_dau()
	_dung(dau != "", "suy được vùng đầu chuỗi từ vung.csv (%s)" % dau)
	_dung(LuuGame.choi_moi(), "choi_moi() chạy được")
	# Đổi cảnh hoãn một khung, cộng thêm mấy khung cho vùng dựng địa hình.
	for i in 8:
		await get_tree().process_frame

	_bang(Tui.hon, 0, "ván mới sạch hồn")
	_bang(Tui.cs("体"), Tui.CHI_SO_DAU["体"], "chỉ số về mốc đầu")
	_dung(Tui.kho.is_empty(), "túi rỗng")
	_dung(Tui.bo_thu.is_empty(), "không còn bộ thủ của ván cũ")
	_bang(TriNho.so_chu_da_hoc(), Tui.CHU_BAN_DAU.size(),
		"trí nhớ về đúng mấy chữ cho sẵn")
	_bang(TheGioi.so_bia_da_bat(), 0, "chưa bia đá nào bật")
	_bang(TheGioi.so_lan_chet, 0, "số lần chết về 0")
	_dung(not DuHanh.da_mo("dam_lay"), "vùng sâu khoá lại")
	_bang(TheGioi.vung_hien_tai, dau, "đang ở vùng đầu chuỗi")

	var canh := get_tree().current_scene
	_dung(canh != null and canh.scene_file_path.ends_with("vung_dat.tscn"),
		"vào thẳng VÙNG THẬT, không phải phòng thử")
	_dung(get_tree().get_first_node_in_group("nguoi_choi") != null,
		"có người chơi trong vùng")
	var nc := get_tree().get_first_node_in_group("nguoi_choi")
	var than = nc.get_node_or_null("Than") if nc != null else null
	_dung(Tui.vu_khi_dang_cam() == null, "ván mới chưa trang bị vũ khí")
	var clip_tay_khong := String(than.call("dong_tac_dang_phat")) \
		if than != null and than.has_method("dong_tac_dang_phat") else ""
	_bang(clip_tay_khong, ThanMoHinh.TIEN_TO_KVK + "dung",
		"chưa trang bị thì mặc định phát animation TAY KHÔNG")

	# Trang bị là ranh giới duy nhất cho phép dùng bộ cầm kiếm. Thử cả hai chiều
	# để canh lỗi cũ: cờ `da_rut` mặc định true từng làm người tay trắng vẫn ôm
	# một thanh kiếm tưởng tượng.
	var vk := SinhMonDo.sinh_theo_loai("vukhi", dau, 26092026)
	_dung(vk != null, "sinh được vũ khí để thử đổi bộ animation")
	if vk != null:
		Tui.nhat(vk)
		_dung(Tui.mac_vao(vk, "vu_khi"), "trang bị được vũ khí")
		await _khung()
		var clip_co_vu_khi := String(than.call("dong_tac_dang_phat")) \
			if than != null and than.has_method("dong_tac_dang_phat") else ""
		_bang(clip_co_vu_khi, "dung",
			"trang bị vũ khí mới chuyển sang animation CẦM KIẾM")
		Tui.bo(vk)
		await _khung()
		var clip_thao_ra := String(than.call("dong_tac_dang_phat")) \
			if than != null and than.has_method("dong_tac_dang_phat") else ""
		_bang(clip_thao_ra, ThanMoHinh.TIEN_TO_KVK + "dung",
			"tháo vũ khí thì trở lại animation TAY KHÔNG")
		_dung(Tui.kho.is_empty(), "dọn món thử xong, ván mới vẫn có túi rỗng")
	_dung(get_tree().get_nodes_in_group("man_dau_game").is_empty(),
		"màn đầu game đã biến mất cùng cảnh cũ")
	_dung(not get_tree().paused, "vào ván là game chạy, không còn dừng")

func _luu_va_choi_tiep() -> void:
	_nhom("Lưu rồi chơi tiếp")
	var nc := get_tree().get_first_node_in_group("nguoi_choi")
	if nc == null:
		_dung(false, "cần người chơi để lưu — bỏ nhóm này")
		return
	# Đánh dấu ván này bằng một con số nhận ra được sau khi nạp.
	Tui.them_hon(1234)
	_dung(LuuGame.tu_luu(), "có người chơi thì tự lưu chạy")
	_bang(LuuGame.o_moi_nhat(), LuuGame.O_TU_LUU, "ô tự lưu thành ô mới nhất")

	var ds := LuuGame.danh_sach()
	_bang(ds.size(), 1, "danh sách ô có đúng một dòng")
	if not ds.is_empty():
		_bang(String(ds[0].get("vung", "")), TheGioi.vung_hien_tai,
			"dòng đó ghi đúng vùng đang chơi")

	# Bẩn lại rồi nạp: số hồn phải quay về đúng mốc đã lưu.
	Tui.hon = 1
	_dung(LuuGame.choi_tiep(), "choi_tiep() nạp được ô mới nhất")
	for i in 8:
		await get_tree().process_frame
	_bang(Tui.hon, 1234, "nạp xong thì hồn về đúng số đã lưu")

# --- Tiện tay -------------------------------------------------------

func _man() -> ManChung:
	var ds := get_tree().get_nodes_in_group("man_dau_game")
	return null if ds.is_empty() else ds[0] as ManChung

## Tìm một nút theo nhãn trong trang đang hiện. Tìm theo CHỮ chứ không theo chỉ
## số: thêm một nút vào giữa danh sách là mọi chỉ số lệch hết, mà phép thử lệch
## thì nó đi đo nhầm nút và vẫn xanh.
func _nut(nhan: String) -> Button:
	var man := _man()
	if man == null:
		return null
	return _tim_nut(man, nhan)

func _tim_nut(goc: Node, nhan: String) -> Button:
	for c in goc.get_children():
		var b := c as Button
		if b != null and b.text.strip_edges() == nhan:
			return b
		var sau := _tim_nut(c, nhan)
		if sau != null:
			return sau
	return null

func _bam(hanh_dong: String) -> void:
	var su_kien := InputEventAction.new()
	su_kien.action = hanh_dong
	su_kien.pressed = true
	Input.parse_input_event(su_kien)
	await _khung()
