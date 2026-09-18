extends Node

## Tuỳ chọn người chơi — âm lượng, độ nhạy chuột, tầm nhìn, minimap.
## Autoload: gọi bằng "CaiDat".
##
## HAI TẦNG, và việc tách chúng ra là cả cơ chế của màn Tuỳ chọn:
##
##   `_gt`    giá trị ĐANG ÁP DỤNG — game đọc tầng này
##   `_nhap`  giá trị ĐANG CHỜ XÁC NHẬN — chỉ màn Tuỳ chọn đọc
##
## Kéo thanh trượt là ghi vào `_nhap`, game chưa đổi gì. Bấm "Áp dụng" thì
## `_nhap` đổ xuống `_gt`, áp vào game và ghi đĩa. Bỏ đi (Quay lại / Esc) thì
## `_nhap` bị xoá và không có gì xảy ra cả.
##
## Vì sao không áp ngay như bản trước: chỉnh độ nhạy chuột thì phải kéo qua kéo
## lại mới tìm được con số đúng, mà áp ngay thì mỗi nhích giữa chừng là một lần
## ghi đĩa và một lần đổi cảm giác — người chơi mất luôn cái mốc cũ để so.
##
## `dat()` vẫn áp NGAY, không qua `_nhap`. Nó dành cho code gọi thẳng (và cho
## bộ kiểm tra); màn Tuỳ chọn thì dùng `dat_nhap()`.
##
## Ghi đĩa ngay lúc áp dụng, không có nút "Lưu" riêng: tuỳ chọn mất là thứ
## người chơi cáu nhất — họ phải chỉnh lại độ nhạy chuột mỗi lần vào game.
##
## Tách hẳn khỏi file save của Tui (`save_game3sd.json`): tuỳ chọn thuộc về
## CÁI MÁY, không thuộc về ván chơi. Xoá save để chơi lại từ đầu thì không có
## lý do gì phải chỉnh lại âm lượng.
##
## File này KHÔNG được nhắc tới một `class_name` nào — xem ghi chú đầu
## giao_dien.gd về vòng tròn chết của autoload.

signal da_doi

const DUONG := "user://cai_dat.json"

## Giá trị mặc định, và cũng là danh sách khoá hợp lệ. Khoá nào không có ở đây
## thì đọc từ file lên cũng bị bỏ — save của bản cũ không làm hỏng bản mới.
const MAC_DINH := {
	"am_luong_chung": 0.8,
	"am_luong_tieng": 0.9,
	"do_nhay_chuot": 1.0,     ## HỆ SỐ nhân vào do_nhay_chuot của camera
	"dao_truc_y": false,
	"hien_minimap": true,
	"hien_cham_ngam": true,
	"rung_man_hinh": true,
}

## Phím người chơi đổi: tên action -> {"kieu": "phim"|"chuot", "ma": int}.
## Chỉ ghi action nào THẬT SỰ bị đổi — vắng mặt ở đây nghĩa là dùng phím mặc
## định của project.godot.
const KHOA_PHIM := "phim"

var _gt := {}
var _nhap := {}          ## tuỳ chọn đang chờ xác nhận
var _phim := {}          ## phím đã đổi, đang áp dụng
var _phim_nhap := {}     ## phím đang chờ xác nhận
## Sự kiện gốc của từng action, chụp lúc khởi động TRƯỚC khi áp bất cứ thay đổi
## nào. Đây là thứ cho phép "về mặc định" chạy được: bỏ override đi thì dựng
## lại từ bảng này, chứ InputMap lúc đó đã bị ghi đè mất rồi.
var _phim_goc := {}

func _ready() -> void:
	_gt = MAC_DINH.duplicate(true)
	_chup_phim_goc()
	nap()
	ap_dung()

func lay(khoa: String):
	return _gt.get(khoa, MAC_DINH.get(khoa))

## Đổi một tuỳ chọn. Áp dụng và ghi đĩa ngay.
func dat(khoa: String, gia_tri) -> void:
	if not MAC_DINH.has(khoa):
		push_warning("Khong co tuy chon '%s'" % khoa)
		return
	if _gt.get(khoa) == gia_tri:
		return
	_gt[khoa] = gia_tri
	ap_dung()
	luu()
	da_doi.emit()

func ve_mac_dinh() -> void:
	_gt = MAC_DINH.duplicate(true)
	_phim.clear()
	_nhap.clear()
	_phim_nhap.clear()
	ap_dung()
	luu()
	da_doi.emit()

# --- Tầng chờ xác nhận ----------------------------------------------

## Giá trị màn Tuỳ chọn phải HIỆN: cái đang chờ nếu có, không thì cái đang áp.
func lay_nhap(khoa: String):
	return _nhap[khoa] if _nhap.has(khoa) else lay(khoa)

## Ghi một thay đổi vào tầng chờ. KHÔNG áp vào game, KHÔNG ghi đĩa.
##
## Kéo trở lại đúng giá trị cũ thì thay đổi tự biến mất, và nút Áp dụng tắt
## lại — đó là cách người chơi biết mình đã về đúng chỗ cũ.
func dat_nhap(khoa: String, gia_tri) -> void:
	if not MAC_DINH.has(khoa):
		push_warning("Khong co tuy chon '%s'" % khoa)
		return
	if lay(khoa) == gia_tri:
		_nhap.erase(khoa)
	else:
		_nhap[khoa] = gia_tri

## Phím màn Điều khiển phải HIỆN, theo cùng luật trên. Trả {} nghĩa là dùng
## phím gốc, null nghĩa là không có gì đang chờ.
func lay_phim_nhap(hanh_dong: String):
	if _phim_nhap.has(hanh_dong):
		return _phim_nhap[hanh_dong]
	return _phim.get(hanh_dong)

## Ghi một phím vào tầng chờ. `su_kien` là phím/nút chuột người chơi vừa bấm.
func dat_phim_nhap(hanh_dong: String, su_kien: InputEvent) -> void:
	var m := _thanh_ma(su_kien)
	if m.is_empty():
		return
	if _phim.get(hanh_dong, {}) == m:
		_phim_nhap.erase(hanh_dong)
	else:
		_phim_nhap[hanh_dong] = m

## Đưa MỌI phím về mặc định, nhưng vẫn phải bấm Áp dụng mới ăn.
func phim_ve_mac_dinh_nhap() -> void:
	_phim_nhap.clear()
	for hanh_dong in _phim.keys():
		_phim_nhap[String(hanh_dong)] = {}   # rỗng = trả về phím gốc

## Có gì đang chờ xác nhận không. Nút "Áp dụng" sáng lên đúng khi hàm này true.
func co_thay_doi() -> bool:
	return not _nhap.is_empty() or not _phim_nhap.is_empty()

## Đổ tầng chờ xuống tầng áp dụng: vào game và xuống đĩa.
func ap_thay_doi() -> void:
	if not co_thay_doi():
		return
	for k in _nhap.keys():
		_gt[k] = _nhap[k]
	for hanh_dong in _phim_nhap.keys():
		var m: Dictionary = _phim_nhap[hanh_dong]
		if m.is_empty():
			_phim.erase(hanh_dong)
		else:
			_phim[hanh_dong] = m
	_nhap.clear()
	_phim_nhap.clear()
	ap_dung()
	luu()
	da_doi.emit()

## Vứt tầng chờ. Game không hề biết là đã có gì xảy ra.
func bo_thay_doi() -> void:
	_nhap.clear()
	_phim_nhap.clear()

## Đẩy giá trị vào chỗ thật sự dùng nó. Gọi lại được nhiều lần.
##
## Âm lượng đi qua AudioServer chứ không qua từng AudioStreamPlayer: am_thanh.gd
## dựng sẵn một dàn kênh và phát bằng cách chọn kênh rảnh, nên chỉnh từng kênh
## là chỉnh trượt cái đang phát dở.
func ap_dung() -> void:
	var chung := float(lay("am_luong_chung"))
	AudioServer.set_bus_mute(0, chung <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(chung, 0.001)))
	# Độ nhạy chuột do camera tự đọc mỗi khung, nên ở đây không phải đẩy đi đâu.
	_ap_dung_phim()

# --- Phím ------------------------------------------------------------

## Chụp sự kiện gốc của mọi action của game. Bỏ qua `ui_*` — đó là action của
## chính Godot (điều hướng giao diện), không phải phím chơi, và đổi chúng là
## cách nhanh nhất làm menu không bấm được nữa.
func _chup_phim_goc() -> void:
	for hanh_dong in InputMap.get_actions():
		var ten := String(hanh_dong)
		if ten.begins_with("ui_"):
			continue
		_phim_goc[ten] = InputMap.action_get_events(ten).duplicate()

## Dựng lại InputMap TỪ BẢNG GỐC rồi mới áp override lên.
##
## Phải dựng lại từ gốc chứ không sửa tại chỗ: bỏ một override đi thì phím phải
## quay về mặc định, mà lúc đó InputMap đã bị ghi đè mất rồi.
##
## Override thay CHỖ ĐẦU và giữ nguyên phím thay thế — `do_phan` có cả E lẫn
## chuột phải, đổi E sang phím khác mà xoá luôn chuột phải là lấy mất một thứ
## người chơi không hề yêu cầu.
func _ap_dung_phim() -> void:
	for hanh_dong in _phim_goc.keys():
		var goc: Array = _phim_goc[hanh_dong]
		InputMap.action_erase_events(hanh_dong)
		var moi := _tu_ma(_phim.get(hanh_dong, {}))
		for i in goc.size():
			InputMap.action_add_event(hanh_dong,
				moi if (i == 0 and moi != null) else goc[i])

func _thanh_ma(su_kien: InputEvent) -> Dictionary:
	if su_kien is InputEventKey:
		var k := su_kien as InputEventKey
		var ma := k.physical_keycode if k.physical_keycode != 0 else k.keycode
		return {} if ma == 0 else {"kieu": "phim", "ma": ma}
	if su_kien is InputEventMouseButton:
		return {"kieu": "chuot", "ma": (su_kien as InputEventMouseButton).button_index}
	return {}

func _tu_ma(m) -> InputEvent:
	if typeof(m) != TYPE_DICTIONARY or m.is_empty():
		return null
	if String(m.get("kieu", "")) == "chuot":
		var c := InputEventMouseButton.new()
		c.button_index = int(m.get("ma", 0))
		return c
	var k := InputEventKey.new()
	k.physical_keycode = int(m.get("ma", 0))
	return k

# --- Đĩa ------------------------------------------------------------

func nap() -> void:
	if not FileAccess.file_exists(DUONG):
		return
	var f := FileAccess.open(DUONG, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return
	# Chỉ nhận khoá CÓ trong MAC_DINH, và chỉ khi đúng kiểu. File tuỳ chọn nằm
	# ở chỗ người chơi sửa tay được, nên phải coi nó là dữ liệu lạ.
	for k in MAC_DINH.keys():
		if not d.has(k):
			continue
		if typeof(d[k]) == typeof(MAC_DINH[k]):
			_gt[k] = d[k]
	# Phím nằm ngoài MAC_DINH vì khoá của nó là tên action, không cố định sẵn.
	var ph = d.get(KHOA_PHIM, {})
	if typeof(ph) == TYPE_DICTIONARY:
		for hanh_dong in ph.keys():
			# Chỉ nhận action game THẬT SỰ có — file này người chơi sửa tay được.
			if _phim_goc.has(hanh_dong) and typeof(ph[hanh_dong]) == TYPE_DICTIONARY:
				_phim[String(hanh_dong)] = ph[hanh_dong]

func luu() -> void:
	var f := FileAccess.open(DUONG, FileAccess.WRITE)
	if f == null:
		push_warning("Khong ghi duoc %s" % DUONG)
		return
	var goi := _gt.duplicate(true)
	goi[KHOA_PHIM] = _phim.duplicate(true)
	f.store_string(JSON.stringify(goi, "\t"))
	f.close()
