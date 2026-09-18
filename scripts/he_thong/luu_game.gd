extends Node

## LƯU / NẠP GAME — nhiều ô, kèm tự lưu. Autoload: gọi bằng "LuuGame".
##
## Ba ô tay + một ô TỰ LƯU riêng. Ô tự lưu tách hẳn ra là cố ý: nếu nó ghi đè
## lên ô người chơi vừa lưu tay thì cái "lưu tay" mất hết ý nghĩa, mà lưu tay
## tồn tại chính vì người chơi muốn một mốc KHÔNG bị máy đụng vào.
##
## Bốn thứ nằm trong một file save, và ranh giới giữa chúng là ranh giới của
## luật 1 trong dự án này:
##
##   NGƯỜI CHƠI  chỗ đứng, máu, thể lực, MP
##   THẾ GIỚI    bia đã bật, boss đã hạ, vũng hồn, vùng đã tới
##   TÚI         đồ, chỉ số, hồn, bộ thủ
##   TRÍ NHỚ     chữ nào thuộc, chữ nào sắp quên
##
## KHÔNG lưu nội dung game (bảng chữ, bảng quái, bảng vũ khí) — chúng nằm trong
## `data/*.csv` và là của BẢN GAME, không của người chơi. Nhét chúng vào save
## là mai mốt sửa một dòng CSV thì mọi file save cũ giữ nguyên bản cũ, và không
## ai hiểu vì sao con quái vừa sửa vẫn đánh như trước.
##
## MỌI ĐƯỜNG ĐỌC GHI ĐỀU CÓ THỂ HỎNG. Ổ đầy, file bị sửa tay, save của bản cũ.
## Hỏng thì trả về false và game chạy tiếp — treo giữa màn hình vì một file
## save hỏng là cách tệ nhất để báo lỗi cho người chơi.

signal da_luu(o: String)
signal da_nap(o: String)

const THU_MUC := "user://saves/"
const O_TU_LUU := "autosave"
const SO_O := 3
## Đổi số này khi cấu trúc save đổi kiểu không đọc ngược được. File có số khác
## thì bị từ chối tử tế thay vì nạp vào rồi vỡ ở đâu đó giữa game.
const PHIEN_BAN := 1

## Tổng số giây đã chơi trong lượt này, cộng dồn với phần đã lưu.
var _choi_lau := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bao_dam_thu_muc()
	# Bia đá = cột dịch chuyển của game này. Bật hoặc nghỉ ở bia là mốc an
	# toàn, và đó đúng là chỗ đáng tự lưu.
	TheGioi.nghi_bia_da.connect(func(_ma: String) -> void: tu_luu())
	TheGioi.ha_boss_xong.connect(func(_ma: String) -> void: tu_luu())

func _process(delta: float) -> void:
	_choi_lau += delta

# --- Ghi ------------------------------------------------------------

## Lưu vào ô `o`: "1".."3" cho ô tay, "autosave" cho ô tự lưu.
func luu(o: String) -> bool:
	if not _bao_dam_thu_muc():
		return false
	var d := thu_thap(o)
	var f := FileAccess.open(duong(o), FileAccess.WRITE)
	if f == null:
		push_error("Khong ghi duoc save '%s': loi %d"
			% [o, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	da_luu.emit(o)
	return true

## Tự lưu. Gọi khi bật/nghỉ bia đá, hạ boss, nhận nhiệm vụ mới.
##
## Không bao giờ đụng vào ba ô tay — xem ghi chú đầu file.
func tu_luu() -> bool:
	return luu(O_TU_LUU)

## Gom toàn bộ trạng thái thành một Dictionary thuần JSON.
func thu_thap(o: String) -> Dictionary:
	# Không khai kiểu: `NguoiChoi` là một `class_name`, mà nhắc tên lớp trong
	# AUTOLOAD buộc Godot phân giải lớp đó ngay lúc nạp autoload — đúng vòng
	# tròn autoload → lớp → autoload đã từng làm gãy cả game (xem ghi chú dài
	# trong `du_hanh.gd`). Truy cập động thì không cần biết lớp nào cả.
	var nc = _nguoi_choi()
	var nguoi := {}
	if nc != null:
		var v: Vector3 = nc.global_position
		nguoi = {
			"x": v.x, "y": v.y, "z": v.z,
			"mau": nc.mau, "the_luc": nc.the_luc, "mp": nc.mp,
			"da_rut": nc.da_rut,
		}
	return {
		"phien_ban": PHIEN_BAN,
		"o": o,
		"luc": Time.get_datetime_string_from_system(false, true),
		"luc_unix": Time.get_unix_time_from_system(),
		"choi_lau": _choi_lau,
		"canh": _duong_canh(),
		"nguoi_choi": nguoi,
		"the_gioi": TheGioi.thanh_du_lieu(),
		"du_hanh": DuHanh.thanh_du_lieu(),
		"tui": Tui.thanh_du_lieu(),
		"tri_nho": TriNho.thanh_du_lieu(),
	}

# --- Đọc ------------------------------------------------------------

## Đọc file save của một ô, {} nếu không có hoặc hỏng.
func doc(o: String) -> Dictionary:
	var duong_o := duong(o)
	if not FileAccess.file_exists(duong_o):
		return {}
	var f := FileAccess.open(duong_o, FileAccess.READ)
	if f == null:
		push_warning("Khong doc duoc save '%s'" % o)
		return {}
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if not (d is Dictionary):
		push_warning("Save '%s' hong, bo qua." % o)
		return {}
	if int((d as Dictionary).get("phien_ban", 0)) != PHIEN_BAN:
		push_warning("Save '%s' thuoc ban khac, bo qua." % o)
		return {}
	return d

## Ô này có gì không.
func co(o: String) -> bool:
	return not doc(o).is_empty()

## Tóm tắt mọi ô để vẽ màn chọn save: ô, thời gian, giờ chơi, vùng đang ở.
func danh_sach() -> Array:
	var ra: Array = []
	for o in _moi_o():
		var d := doc(o)
		if d.is_empty():
			continue
		ra.append({
			"o": o,
			"luc": String(d.get("luc", "")),
			"luc_unix": float(d.get("luc_unix", 0.0)),
			"choi_lau": float(d.get("choi_lau", 0.0)),
			"vung": String((d.get("the_gioi", {}) as Dictionary)
				.get("vung_hien_tai", "")),
		})
	ra.sort_custom(func(a, b) -> bool: return a["luc_unix"] > b["luc_unix"])
	return ra

## Ô mới nhất — đúng thứ nút "Chơi tiếp" cần. "" nếu chưa có save nào.
##
## Quét CẢ ô tự lưu. Người chơi bấm "Chơi tiếp" muốn về đúng chỗ họ vừa dừng,
## chứ không muốn biết chỗ đó do họ lưu hay do máy lưu.
func o_moi_nhat() -> String:
	var ds := danh_sach()
	return "" if ds.is_empty() else String(ds[0]["o"])

# --- Nạp ------------------------------------------------------------

## Nạp một ô. Đổi cảnh nếu cần, rồi khôi phục người chơi SAU KHI cảnh dựng xong.
##
## Thứ tự ở đây không đảo được: thế giới trước, cảnh sau, người chơi cuối. Đặt
## người chơi trước khi cảnh dựng xong là đặt vào một scene sắp bị huỷ, và nhân
## vật hiện ra ở chỗ mặc định — im lặng, không lỗi nào.
func nap(o: String) -> bool:
	var d := doc(o)
	if d.is_empty():
		return false
	Tui.tu_du_lieu(d.get("tui", {}))
	TheGioi.tu_du_lieu(d.get("the_gioi", {}))
	DuHanh.tu_du_lieu(d.get("du_hanh", {}))
	TriNho.tu_du_lieu(d.get("tri_nho", {}))
	_choi_lau = float(d.get("choi_lau", 0.0))

	var canh := String(d.get("canh", ""))
	var nguoi: Dictionary = d.get("nguoi_choi", {})
	if canh != "" and canh != _duong_canh() and ResourceLoader.exists(canh):
		_doi_canh_roi_dat(canh, nguoi)
	else:
		_dat_nguoi_choi(nguoi)
	da_nap.emit(o)
	return true

## Chơi tiếp từ ô mới nhất.
func choi_tiep() -> bool:
	var o := o_moi_nhat()
	return false if o == "" else nap(o)

func _doi_canh_roi_dat(duong_canh: String, nguoi: Dictionary) -> void:
	var canh := load(duong_canh) as PackedScene
	if canh == null:
		_dat_nguoi_choi(nguoi)
		return
	# Hoãn: hàm này hay được gọi từ một nút bấm nằm trong chính cảnh sắp huỷ.
	get_tree().paused = false
	_doi_that.call_deferred(canh, nguoi)

func _doi_that(canh: PackedScene, nguoi: Dictionary) -> void:
	var cay := get_tree()
	var moi := canh.instantiate()
	if moi == null:
		return
	var cu := cay.current_scene
	if cu != null:
		cay.root.remove_child(cu)
		cu.queue_free()
	cay.root.add_child(moi)
	cay.current_scene = moi
	# Đợi cảnh chạy xong _ready của cả cây rồi mới đặt người chơi vào chỗ.
	await cay.process_frame
	await cay.process_frame
	_dat_nguoi_choi(nguoi)

func _dat_nguoi_choi(nguoi: Dictionary) -> void:
	if nguoi.is_empty():
		return
	var nc = _nguoi_choi()
	if nc == null:
		return
	nc.global_position = Vector3(float(nguoi.get("x", 0.0)),
		float(nguoi.get("y", 0.0)), float(nguoi.get("z", 0.0)))
	nc.velocity = Vector3.ZERO
	nc.mau = float(nguoi.get("mau", nc.mau_toi_da))
	nc.the_luc = float(nguoi.get("the_luc", nc.the_luc_max))
	nc.mp = float(nguoi.get("mp", nc.mp))
	nc.da_rut = bool(nguoi.get("da_rut", true))
	# Cảnh mới dựng xong nhưng HUD chưa biết gì: máu và thể lực trong save khác
	# giá trị mặc định, mà thanh trên màn hình chỉ đổi khi có tín hiệu.
	nc.doi_mau.emit(nc.mau, nc.mau_toi_da)
	nc.doi_the_luc.emit(nc.the_luc, nc.the_luc_max)

# --- Xoá ------------------------------------------------------------

func xoa(o: String) -> bool:
	var duong_o := duong(o)
	if not FileAccess.file_exists(duong_o):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(duong_o)) == OK \
		or DirAccess.open(THU_MUC).remove(_ten_file(o)) == OK

# --- Đường dẫn ------------------------------------------------------

func duong(o: String) -> String:
	return THU_MUC + _ten_file(o)

func _ten_file(o: String) -> String:
	return "autosave.json" if o == O_TU_LUU else "slot_%s.json" % o

func _moi_o() -> Array:
	var ra: Array = [O_TU_LUU]
	for i in range(1, SO_O + 1):
		ra.append(str(i))
	return ra

## Tạo `user://saves/` nếu chưa có. Trả về false nếu không tạo nổi — lúc đó
## mọi đường ghi phải chịu thua tử tế chứ không được thử ghi rồi nổ.
func _bao_dam_thu_muc() -> bool:
	if DirAccess.dir_exists_absolute(THU_MUC):
		return true
	var loi := DirAccess.make_dir_recursive_absolute(THU_MUC)
	if loi != OK:
		push_error("Khong tao duoc %s: loi %d" % [THU_MUC, loi])
		return false
	return true

func _duong_canh() -> String:
	var c := get_tree().current_scene
	return "" if c == null else c.scene_file_path

## KHÔNG khai kiểu trả về — xem ghi chú trong `thu_thap()`.
func _nguoi_choi():
	return get_tree().get_first_node_in_group("nguoi_choi")
