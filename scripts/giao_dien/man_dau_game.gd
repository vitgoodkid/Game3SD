extends "res://scripts/giao_dien/man_cai_dat.gd"

## Màn hình ĐẦU GAME — Chơi tiếp / Chơi mới / Tải ván / Tuỳ chọn / Điều khiển /
## Thoát.
##
## **Kế thừa `man_cai_dat.gd` chứ không chép nó.** Menu tạm dừng đã có sẵn hai
## trang con nặng nhất — Tuỳ chọn (bảy hàng, tầng chờ, nút Áp dụng sáng/tối) và
## Điều khiển (gán lại phím, bảng đọc thẳng từ InputMap). Chép sang đây là chép
## 130 dòng, và từ hôm đó trở đi mỗi lần thêm một tuỳ chọn là phải nhớ sửa hai
## chỗ — mà cái quên sửa thì không test nào bắt được, vì cả hai bản đều chạy.
##
## Màn này khác menu tạm dừng ở đúng bốn chỗ, và cả bốn đều vì MỘT lý do: ở đây
## CHƯA CÓ VÁN NÀO ĐANG CHẠY.
##
##   1. Không đóng được. Đóng ra thì lộ một scene trống trơn.
##   2. Esc không làm gì ở trang gốc (ở trang con vẫn là "quay lại").
##   3. Thoát KHÔNG tự lưu — không có gì để lưu, mà lưu là ghi đè save thật
##      bằng một ván rỗng. `LuuGame.tu_luu()` cũng đã tự chặn, đây là lớp thứ hai.
##   4. Không nằm trong nhóm "man_cai_dat" — xem `ten_nhom()` ở lớp cha.

const TRANG_TAI_VAN := 3

## Tên hiện ở đầu màn. Không phải tên vùng hay tên chữ nào — đây là chỗ duy
## nhất trong game nói tên chính nó.
const TEN_GAME := "Game3SD"
const PHU_DE := "Souls-like · chữ Hán nằm ở trang bị"

func _ready() -> void:
	super()
	add_to_group("man_dau_game")
	# Tự mở: màn này KHÔNG có ai mở hộ. Mọi màn khác đều do một phím hoặc một
	# cái bia đá mở ra, còn đây là thứ đầu tiên người chơi thấy.
	mo()

func ten_nhom() -> String:
	return "man_dau_game"

func ten_trang_chinh() -> String:
	return TEN_GAME

## Không có phím nào bật/tắt màn này — nó luôn mở.
func phim_mo_man() -> String:
	return ""

## Chân màn để trống. Lớp cha mời "Esc — đóng", mà ở đây Esc không đóng gì cả.
func dong_chan() -> String:
	return ""

## **Không đóng được.** Không phải để cứng đầu: đóng màn này ra thì phía sau là
## một scene rỗng, người chơi nhìn vào màn hình đen và không còn đường nào bấm.
## Chặn ở `dong()` chứ không chỉ chặn phím Esc, để mọi đường gọi tới đều chịu
## chung một luật.
##
## Đường ra khỏi màn này là ĐỔI SCENE — Chơi mới / Chơi tiếp / Tải ván đều đi
## qua `LuuGame`, và `ManChung._exit_tree()` nhả `paused` khi màn bị huỷ theo.
func dong() -> void:
	pass

## Esc: ở trang con là quay lại (lớp cha lo), ở trang gốc thì NUỐT.
##
## Nuốt chứ không bỏ qua: không nuốt thì Esc rơi xuống camera và thả chuột ra,
## mà chuột đang cần để bấm nút.
func _unhandled_input(su_kien: InputEvent) -> void:
	if dang_mo and _trang == TRANG_MENU and su_kien.is_action_pressed("thoat"):
		get_viewport().set_input_as_handled()
		return
	super(su_kien)

func _ve_trang() -> void:
	ve_xong = false
	if _trang == TRANG_TAI_VAN:
		don(_than)
		_nut_ap = null
		dat_tieu_de("Tải ván")
		_trang_tai_van()
	else:
		super()
	ve_xong = true

# --- Trang gốc ------------------------------------------------------

func _trang_menu() -> void:
	_than.add_child(_chu_giua(PHU_DE, 24, MAU_CHU_MO))
	_than.add_child(HSeparator.new())

	# "Chơi tiếp" đứng TRÊN "Chơi mới" và là nút đầu tiên: người chơi mở game
	# lên lần thứ hai trở đi hầu như luôn muốn đi tiếp, không muốn bắt đầu lại.
	var co_save := LuuGame.o_moi_nhat() != ""
	var b := _nut_to("Chơi tiếp", _choi_tiep)
	b.disabled = not co_save
	_than.add_child(b)

	_than.add_child(_nut_to("Chơi mới", _choi_moi))
	var b_tai := _nut_to("Tải ván", func(): _di_trang(TRANG_TAI_VAN))
	b_tai.disabled = not co_save
	_than.add_child(b_tai)

	_than.add_child(_nut_to("Tuỳ chọn", func(): _di_trang(TRANG_TUY_CHON)))
	_than.add_child(_nut_to("Điều khiển", func(): _di_trang(TRANG_DIEU_KHIEN)))
	_than.add_child(_nut_to("Thoát", _thoat_game))

	if not co_save:
		_than.add_child(_chu_giua("Chưa có ván nào đã lưu.", 20, MAU_CHU_MO))

## Một dòng chữ CĂN GIỮA.
##
## `ManChung.chu()` trả về Label căn TRÁI, và ở màn hành trang thì đó là đúng —
## mỗi món đồ một dòng, đọc theo cột. Ở đây thì sai: mọi nút đều nằm giữa, nên
## một dòng chữ căn trái bị đẩy ra tận mép màn hình, cách nội dung cả ngàn
## pixel trên màn rộng. `alignment` của VBox không cứu được — nó căn theo chiều
## DỌC, còn đây là chiều ngang.
##
## Không test nào bắt được chuyện này: dòng chữ vẫn ở đó, vẫn đúng nội dung,
## chỉ nằm sai chỗ. Ảnh chụp mới thấy.
func _chu_giua(noi_dung: String, co := 22, mau := MAU_CHU) -> Label:
	var l := chu(noi_dung, co, mau)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Thoát từ màn đầu game: KHÔNG tự lưu.
##
## Lớp cha lưu trước khi thoát, và ở giữa ván thì đó là việc đúng. Ở đây thì
## không có ván nào — lưu là ghi một file save rỗng đè lên ô tự lưu thật.
func _thoat_game() -> void:
	get_tree().quit()

func _choi_moi() -> void:
	# Ván mới KHÔNG đụng file save nào (xem `LuuGame.choi_moi()`), nên không
	# hỏi lại. Bấm nhầm thì quay về màn này là ván cũ vẫn còn nguyên.
	LuuGame.choi_moi()

func _choi_tiep() -> void:
	LuuGame.choi_tiep()

# --- Trang tải ván --------------------------------------------------

func _trang_tai_van() -> void:
	var ds := LuuGame.danh_sach()
	if ds.is_empty():
		_than.add_child(_chu_giua("Chưa có ván nào đã lưu.", 24, MAU_CHU_MO))
		_than.add_child(_nut_to("Quay lại", _ve_menu))
		return

	# Ô mới nhất lên đầu (`danh_sach()` đã xếp sẵn) — đó gần như luôn là ô
	# người chơi định bấm.
	for m in ds:
		_than.add_child(_nut_o(m))
	_than.add_child(HSeparator.new())
	_than.add_child(_nut_to("Quay lại", _ve_menu))

func _nut_o(m: Dictionary) -> Button:
	var o := String(m["o"])
	var b := _nut_to(_nhan_o(m), func(): LuuGame.nap(o))
	# Nút cao hơn nút thường: mỗi ô là hai dòng chữ.
	b.custom_minimum_size = Vector2(620, 92)
	b.add_theme_font_size_override("font_size", 22)
	return b

## Một dòng tóm tắt ô save. Tên vùng đọc từ `vung.csv` chứ không gõ vào đây —
## luật 1, và cũng để đổi tên vùng trong CSV là bảng này tự đúng.
func _nhan_o(m: Dictionary) -> String:
	var o := String(m["o"])
	var ten_o := "Tự lưu" if o == LuuGame.O_TU_LUU else "Ô %s" % o
	var v := VocabDB.vung_cua(String(m.get("vung", "")))
	var ten_vung := String(v.get("ten", "—")) if not v.is_empty() else "—"
	return "%s   ·   %s\n%s   ·   đã chơi %s" % [ten_o, ten_vung,
		String(m.get("luc", "")), _gio_phut(float(m.get("choi_lau", 0.0)))]

## Giây → "2 giờ 14 phút". Người chơi đọc giờ chơi để nhận ra ô nào là ô nào,
## nên đơn vị phải là thứ họ nhớ được, không phải 8043 giây.
func _gio_phut(giay: float) -> String:
	var tong := int(giay)
	var gio := tong / 3600
	var phut := (tong % 3600) / 60
	if gio > 0:
		return "%d giờ %d phút" % [gio, phut]
	return "%d phút" % phut
