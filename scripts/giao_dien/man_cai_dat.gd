extends ManChung

## Menu tạm dừng (Esc) — Tiếp tục / Tuỳ chọn / Điều khiển / Thoát.
##
## Ba trang trong MỘT màn, không phải ba màn: ManChung chỉ cho mở đúng một màn
## cùng lúc (`dang_mo_man`), nên tách ra là phải tự dựng lại luật đó ở ngoài.
##
## Bản mẫu chủ dự án đưa có thêm nút LOGOUT. Bỏ — game này chơi một mình, không
## có tài khoản để mà đăng xuất, và một nút bấm vào không ra gì tệ hơn là không
## có nút.
##
## HAI TRANG CON ĐỀU PHẢI XÁC NHẬN. Kéo thanh trượt hay gán phím mới chỉ ghi vào
## tầng chờ của `CaiDat`; game không đổi gì cho tới khi bấm **Áp dụng**. Nút đó
## TỐI khi chưa có thay đổi và SÁNG khi có — nó vừa là nút bấm vừa là câu trả
## lời cho "mình đã đổi gì chưa". Rời trang mà chưa bấm thì thay đổi bị vứt.

const TRANG_MENU := 0
const TRANG_TUY_CHON := 1
const TRANG_DIEU_KHIEN := 2

## Bấm vào một hàng phím rồi, trong bấy nhiêu giây đầu KHÔNG nhận sự kiện nào.
##
## Không có nó thì chính cú nhả chuột vừa bấm vào hàng đó bị bắt luôn làm phím
## mới — người chơi định đổi phím và nhận được "Chuột trái".
const TRE_BAT_PHIM := 0.25

## Bảng phím hiện ở trang Điều khiển.
##
## Đọc TÊN ACTION từ InputMap chứ không gõ tay tên phím: gõ tay thì đổi phím
## xong bảng này nói dối, và nói dối về phím là lỗi không ai phát hiện ra cho
## tới lúc thử từng cái.
##
## Hàng nào gộp NHIỀU action (dấu "|") thì chỉ để xem, không gán lại được —
## "Đi" là bốn phím, gán lại một phím cho cả bốn là vô nghĩa.
const PHIM := [
	["Đi", "di_truoc|di_trai|di_sau|di_phai"],
	["Lăn (gõ nhanh) · Nhảy (giữ)", "lan_nhay"],
	["Chạy (giữ)", "chay_nhanh"],
	["Đòn nhẹ (bấm) · Đòn nặng (giữ)", "don_nhe"],
	["Đỡ phản (bấm) · Giơ khiên (giữ)", "do_phan"],
	["Tương tác", "tuong_tac"],
	["Uống bình", "uong_binh"],
	["Đổi vũ khí", "doi_vu_khi"],
	["Khoá mục tiêu", "khoa_muc_tieu"],
	["Đổi mục tiêu trái · phải", "doi_muc_tieu_trai|doi_muc_tieu_phai"],
	["Hành trang", "hanh_trang"],
	["Bản đồ", "ban_do"],
	["Đổi camera", "doi_camera"],
	["Menu này", "thoat"],
]

var _trang := TRANG_MENU
var _than: VBoxContainer = null
## Nút Áp dụng của trang con đang mở (null ở trang chính).
var _nut_ap: Button = null
## Action đang chờ gán phím mới ("" = không gán gì).
var _dang_gan := ""
var _tre_gan := 0.0

func _ready() -> void:
	super()
	# Tìm bằng nhóm chứ không bằng đường dẫn node — màn này nằm ở cả
	# phong_thu.tscn lẫn vung_dat.tscn, hai cây khác nhau.
	add_to_group(ten_nhom())

## Nhóm để tìm màn này. Là HÀM chứ không phải hằng vì màn đầu game kế thừa file
## này để dùng lại hai trang con, mà nó KHÔNG được nằm chung nhóm: bộ kiểm tra
## và `chup_man_hinh` tìm "màn tạm dừng" bằng nhóm, vớ nhầm màn đầu game là
## chúng đi thử nút "Tiếp tục" của một màn không có gì để tiếp tục.
func ten_nhom() -> String:
	return "man_cai_dat"

## Tiêu đề của trang gốc. Màn đầu game ghi tên game ở đây.
func ten_trang_chinh() -> String:
	return "Tạm dừng"

func phim_mo_man() -> String:
	return "thoat"

func dung_noi_dung(cha: MarginContainer) -> void:
	_than = VBoxContainer.new()
	_than.add_theme_constant_override("separation", 14)
	_than.alignment = BoxContainer.ALIGNMENT_CENTER
	cha.add_child(_than)

func lam_moi() -> void:
	_huy_gan()
	CaiDat.bo_thay_doi()
	_trang = TRANG_MENU
	_ve_trang()

## Nút Áp dụng phải bám trạng thái thật mỗi khung, không phải chỉ lúc dựng:
## một hàng bất kỳ đổi giá trị là nó phải sáng lên ngay.
func _process(delta: float) -> void:
	if _tre_gan > 0.0:
		_tre_gan -= delta
	if _nut_ap != null and is_instance_valid(_nut_ap):
		_nut_ap.disabled = not CaiDat.co_thay_doi()

# --- Phím -----------------------------------------------------------

## Bắt phím mới. Dùng `_input` chứ không `_unhandled_input`: phải chặn TRƯỚC
## khi Esc rơi xuống ManChung và đóng màn mất.
func _input(su_kien: InputEvent) -> void:
	if not dang_mo or _dang_gan == "" or _tre_gan > 0.0:
		return
	var la_phim := su_kien is InputEventKey and su_kien.is_pressed() and not su_kien.is_echo()
	var la_chuot := su_kien is InputEventMouseButton and su_kien.is_pressed()
	if not la_phim and not la_chuot:
		return
	get_viewport().set_input_as_handled()
	# Esc là ĐƯỜNG THOÁT, không phải một phím gán được. Không chừa nó ra thì
	# gán nhầm một lần là mất luôn cách mở menu để sửa lại.
	if la_phim and (su_kien as InputEventKey).physical_keycode == KEY_ESCAPE:
		_huy_gan()
		_ve_trang()
		return
	CaiDat.dat_phim_nhap(_dang_gan, su_kien)
	_huy_gan()
	_ve_trang()

func _huy_gan() -> void:
	_dang_gan = ""
	_tre_gan = 0.0

func _bat_dau_gan(hanh_dong: String) -> void:
	_dang_gan = hanh_dong
	_tre_gan = TRE_BAT_PHIM
	_ve_trang()

## Esc ở trang con là QUAY LẠI, không phải đóng màn. Đóng thẳng từ trang Tuỳ
## chọn thì người chơi mất luôn chỗ mình đang đứng, và phải bấm lại hai lần để
## về đúng đó.
func _unhandled_input(su_kien: InputEvent) -> void:
	if dang_mo and _trang != TRANG_MENU and su_kien.is_action_pressed("thoat"):
		_ve_menu()
		get_viewport().set_input_as_handled()
		return
	super(su_kien)

func _ve_trang() -> void:
	don(_than)
	_nut_ap = null
	match _trang:
		TRANG_TUY_CHON:
			dat_tieu_de("Tuỳ chọn")
			_trang_tuy_chon()
		TRANG_DIEU_KHIEN:
			dat_tieu_de("Điều khiển")
			_trang_dieu_khien()
		_:
			dat_tieu_de(ten_trang_chinh())
			_trang_menu()

# --- Trang chính ----------------------------------------------------

func _trang_menu() -> void:
	_than.add_child(_nut_to("Tiếp tục", dong))
	_than.add_child(_nut_to("Tuỳ chọn", func(): _di_trang(TRANG_TUY_CHON)))
	_than.add_child(_nut_to("Điều khiển", func(): _di_trang(TRANG_DIEU_KHIEN)))
	_than.add_child(_nut_to("Thoát game", _thoat_game))

func _di_trang(t: int) -> void:
	_trang = t
	_ve_trang()

## Rời trang con là VỨT thay đổi chưa xác nhận. Giữ lại thì người chơi quay ra
## quay vào rồi bấm Áp dụng ở lần sau, và không còn nhớ mình đã đổi những gì.
func _ve_menu() -> void:
	_huy_gan()
	CaiDat.bo_thay_doi()
	_di_trang(TRANG_MENU)

## Thoát thì LƯU trước, vào ô TỰ LƯU.
##
## Ghi đè ô tự lưu chứ không đụng ba ô tay: ô tay là mốc người chơi tự chọn, và
## một cú bấm Thoát không được phép xoá mốc đó.
##
## Vẫn lưu dù đã có tự lưu ở bia đá: khoảng giữa hai lần nghỉ bia có thể dài
## hàng chục phút, và mất ngần ấy vì bấm Thoát là cái bẫy tệ nhất để lại.
func _thoat_game() -> void:
	LuuGame.tu_luu()
	get_tree().quit()

func _nut_to(nhan: String, khi_bam: Callable) -> Button:
	var b := nut(nhan, khi_bam)
	b.theme_type_variation = GiaoDien.NUT_MENU
	b.custom_minimum_size = Vector2(440, 84)
	b.add_theme_font_size_override("font_size", 30)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b

## Hàng nút dưới cùng của hai trang con: Về mặc định · Áp dụng · Quay lại.
##
## "Áp dụng" giữ lại ở `_nut_ap` để `_process` bật/tắt nó theo `co_thay_doi()`.
func _hang_xac_nhan(ve_goc: Callable) -> void:
	_than.add_child(HSeparator.new())
	var d := HBoxContainer.new()
	d.alignment = BoxContainer.ALIGNMENT_CENTER
	d.add_theme_constant_override("separation", 18)
	_than.add_child(d)
	d.add_child(_nut_to("Về mặc định", ve_goc))
	_nut_ap = _nut_to("Áp dụng", func():
		CaiDat.ap_thay_doi()
		_ve_trang())
	_nut_ap.disabled = not CaiDat.co_thay_doi()
	d.add_child(_nut_ap)
	d.add_child(_nut_to("Quay lại", _ve_menu))

# --- Trang tuỳ chọn -------------------------------------------------

func _trang_tuy_chon() -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 40)
	g.add_theme_constant_override("v_separation", 20)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_than.add_child(g)

	_hang_truot(g, "Âm lượng chung", "am_luong_chung")
	_hang_truot(g, "Âm lượng hiệu ứng", "am_luong_tieng")
	_hang_truot(g, "Độ nhạy chuột", "do_nhay_chuot", 0.2, 3.0)
	_hang_bat(g, "Đảo trục dọc chuột", "dao_truc_y")
	_hang_bat(g, "Hiện minimap", "hien_minimap")
	_hang_bat(g, "Hiện chấm ngắm", "hien_cham_ngam")
	_hang_bat(g, "Rung màn hình", "rung_man_hinh")

	_hang_xac_nhan(func():
		# Về mặc định cũng phải XÁC NHẬN — nó là một thay đổi như mọi thay đổi
		# khác, và bấm nhầm nó mà mất sạch tuỳ chọn thì không có đường lùi.
		for k in CaiDat.MAC_DINH.keys():
			CaiDat.dat_nhap(k, CaiDat.MAC_DINH[k])
		_ve_trang())

func _hang_truot(g: GridContainer, nhan: String, khoa: String,
		nho := 0.0, to := 1.0) -> void:
	g.add_child(chu(nhan, 26))
	var hop := HBoxContainer.new()
	hop.add_theme_constant_override("separation", 16)
	var t := HSlider.new()
	t.min_value = nho
	t.max_value = to
	t.step = 0.05
	t.value = float(CaiDat.lay_nhap(khoa))
	t.custom_minimum_size = Vector2(380, 34)
	var so := chu("", 22, MAU_NHAN)
	so.custom_minimum_size = Vector2(76, 0)
	so.text = "%d%%" % roundi(t.value * 100.0)
	t.value_changed.connect(func(v: float):
		so.text = "%d%%" % roundi(v * 100.0)
		CaiDat.dat_nhap(khoa, v))
	hop.add_child(t)
	hop.add_child(so)
	g.add_child(hop)

func _hang_bat(g: GridContainer, nhan: String, khoa: String) -> void:
	g.add_child(chu(nhan, 26))
	var b := CheckButton.new()
	b.button_pressed = bool(CaiDat.lay_nhap(khoa))
	b.toggled.connect(func(v: bool): CaiDat.dat_nhap(khoa, v))
	g.add_child(b)

# --- Trang điều khiển -----------------------------------------------

func _trang_dieu_khien() -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 48)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for cap in PHIM:
		var ten := String(cap[1])
		g.add_child(chu(String(cap[0]), 24))
		g.add_child(_o_phim(ten))
	var cuon_g := cuon(g)
	cuon_g.custom_minimum_size = Vector2(0, 520)
	_than.add_child(cuon_g)
	_than.add_child(chu("Bấm vào một phím để gán lại. Esc để bỏ.", 20, MAU_CHU_MO))
	_hang_xac_nhan(func():
		CaiDat.phim_ve_mac_dinh_nhap()
		_ve_trang())

## Một ô phím. Gán lại được thì là Button, không thì là chữ thường.
func _o_phim(danh_sach: String) -> Control:
	if danh_sach.contains("|"):
		# Hàng gộp nhiều action — chỉ để xem. Gán một phím cho cả bốn hướng đi
		# là vô nghĩa, và cho gán thì phải giải thích vì sao nó không ăn.
		return chu(GiaoDien.ten_moi_phim(danh_sach), 24, MAU_NHAN)
	if _dang_gan == danh_sach:
		return chu("… bấm phím mới", 24, Color(0.95, 0.62, 0.25))
	var b := nut(_ten_phim_nhap(danh_sach), func(): _bat_dau_gan(danh_sach))
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(230, 44)
	# Phím đang chờ xác nhận tô vàng — người chơi thấy ngay hàng nào mình vừa
	# đụng, mà không phải nhớ.
	if CaiDat.lay_phim_nhap(danh_sach) != null:
		b.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	return b

## Tên phím phải hiện theo tầng CHỜ, không theo InputMap: InputMap chỉ đổi lúc
## bấm Áp dụng, mà người chơi cần thấy ngay cái mình vừa gán.
func _ten_phim_nhap(hanh_dong: String) -> String:
	var m = CaiDat.lay_phim_nhap(hanh_dong)
	if typeof(m) == TYPE_DICTIONARY and not m.is_empty():
		if String(m.get("kieu", "")) == "chuot":
			return GiaoDien.ten_nut_chuot(int(m.get("ma", 0)))
		return OS.get_keycode_string(int(m.get("ma", 0)))
	return _ten_phim(hanh_dong)

## Tên phím của một (hoặc vài) action. Dùng chung hàm của GiaoDien — dòng mời
## trên màn chơi cũng đọc từ đó, nên bảng này và cái mời bấm không thể lệch nhau.
func _ten_phim(danh_sach: String) -> String:
	return GiaoDien.ten_moi_phim(danh_sach)
