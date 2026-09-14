extends CanvasLayer

## Màn chiến đấu. Một trận gồm NHIỀU lượt hỏi liên tiếp:
##   trả lời đúng -> quái mất 1 máu
##   trả lời sai  -> mình mất 1 máu
signal ket_thuc(thang: bool, mau_player_con_lai: int, mp_con_lai: int)
## Chạy thoát khỏi trận: không thắng cũng không thua, quái còn sống, giữ máu.
signal chay_thoat(mau_player_con_lai: int, mp_con_lai: int)

const MAU_DUNG := Color(0.4, 0.88, 0.4)
const MAU_SAI := Color(0.92, 0.35, 0.35)

## Màu ba làn của khung Máu/Phép/Thể lực — dùng CHUNG ảnh với HUD bản đồ
## (world.gd) để trận đấu trông y hệt ngoài map, không phải khung riêng.
const ANH_THANH_DO := preload("res://assets/ui/thanh/day_do.png")
const ANH_THANH_XANH_DUONG := preload("res://assets/ui/thanh/day_xanhduong.png")
const ANH_THANH_XANH_LA := preload("res://assets/ui/thanh/day_xanhla.png")
const MAU_GOI_Y := Color(0.62, 0.66, 0.76)
const MAU_KY_NANG := Color(0.6, 0.8, 1.0)

## Ô kỹ năng dùng lại đúng scene ô hành trang cho đồng bộ.
const O_KY_NANG := preload("res://scenes/o_hanh_trang.tscn")
## Số ô của khung hành trang trong trận. Lấy thẳng từ Tui để hai bên không lệch
## nhau — chính Tui giữ danh sách 7 ô mang theo.
const SO_O_HT := Tui.SO_O_MANG_THEO

## Mọi kiểu câu hỏi hiện có. Quái để trống danh sách thì được hỏi bằng tất.
const TAT_CA_KIEU := [
	"trung_viet", "viet_trung", "dung_sai", "dien_tu", "ghep_bo_thu", "sap_xep",
	"np_dien", "np_dung_sai", "dong_nghia", "trai_nghia",
]
const DAU_CAU := "。，？！"
const O_TRONG := "＿"

var _chu_de := ""
var _cap := 1
var _cac_kieu: Array = []
var _mau_quai := 0
var _mau_player := 0
var _mau_quai_toi_da := 0
var _mau_player_toi_da := 0
## Khoảng sát thương của hai bên. Sau này bên mình do vũ khí quyết định,
## bên quái do hạng của nó.
var _st_min := 25
var _st_max := 40
var _quai_st_min := 12
var _quai_st_max := 20
## Thứ tự khu (0 = khu đầu) để tính tỉ lệ bỏ chạy: 40% rồi −3% mỗi khu sau.
var _khu_index := 0

var _cau: Dictionary = {}
var _dang_xep: Array = []
var _kieu_truoc := ""
var _da_chon := false

## Khiên còn mấy lần đỡ + đòn kế cộng thêm bao nhiêu. Để trong ChienDau chứ
## không phải ở đây, vì chế độ chém ngoài map sau này cần đúng hai thứ đó.
var _tt := ChienDau.TrangThai.new()
## Trạng thái của QUÁI — khác _tt (của mình). Hiện chỉ mang độc rải từ vũ
## khí có nguyên tố 毒; quái không dùng phép nên chưa cần chan/don_them.
var _tt_quai := ChienDau.TrangThai.new()
## Giảm sát thương nhận vào mỗi câu sai — từ giáp đang mặc (đã cộng sẵn
## giáp cứng của Thạch nếu có, xem Tui.giam_sat_thuong()).
var _giap := 0
## Nguyên tố trên vũ khí đang cầm — "" nếu không có.
var _nt_vu_khi := ""
## Có món giáp nào đang mặc mang Băng không (né miễn phí một đòn sắp ăn).
var _co_bang := false
## Có món nào (giáp hoặc vũ khí) đang mặc mang Ma không (tăng hiệu quả phép).
var _co_ma := false

## MP — chặn THÊM lên trên "lượt" (Tui.con_luot) khi dùng phép, xem
## _dung_duoc_ky_nang()/_on_dung_ky_nang(). Mỗi phép tốn CO_PHEP_MP điểm.
var _mp := 0
var _mp_toi_da := 0
const CO_PHEP_MP := 1
## Thể lực — KHÔNG đổi trong trận (lướt là chuyện ngoài map), chỉ hiện tĩnh
## cho khung ba-trong-một khớp với HUD bản đồ.
var _the_luc := 0.0
var _the_luc_toi_da := 0.0
## Hồi ĐẦY mp khi trả lời đúng 2 câu LIÊN TIẾP, hoặc 3 câu đúng dù có
## ngắt quãng (sai không reset _dung_tong, chỉ reset _dung_lien_tiep) —
## thưởng cho cả chuỗi ngon lẫn độ chính xác rải rác, không ép phải ăn may
## liên tục mới có phép dùng.
var _dung_lien_tiep := 0
var _dung_tong := 0
## Chỗ đứng gốc của hai ô đấu sĩ, để hiệu ứng lao tới xong biết đường lùi về.
var _cho_nhan_vat: Vector2
var _cho_quai: Vector2
## Nhân vật đã gục chưa — để animation gục không bị đè về idle.
var _nv_da_guc := false
## Loại quái đang gặp (khoá hoạt ảnh trong enemy_frames.tres) và đã gục chưa —
## y hệt cặp biến của nhân vật, dùng để chạy animation đánh/trúng đòn/gục thật.
var _loai_quai := ""
var _quai_da_guc := false
## Tween chớp trắng đang chạy trên hình quái — giữ lại để _guc() dừng được nó,
## không thì hai tween cùng ghi modulate và quái không mờ dần được.
var _chop_quai: Tween = null

@onready var _de_bai: Label = $UI/Khung/DeBai
@onready var _cau_hoi: Label = $UI/Khung/CauHoi
@onready var _ket_qua: Label = $UI/Khung/KetQua
@onready var _luoi: GridContainer = $UI/Khung/DapAn
@onready var _cau_dang_xep: Label = $UI/Khung/CauDangXep
@onready var _kho_chu: HBoxContainer = $UI/Khung/KhoChu
@onready var _nut_xoa: Button = $UI/Khung/NutXoa
@onready var _hinh_nhan_vat: ColorRect = $UI/NhanVat
@onready var _anim_nv: AnimatedSprite2D = $UI/NhanVatAnim
@onready var _hinh_quai: AnimatedSprite2D = $UI/QuaiAnim
@onready var _hanh_trang: HBoxContainer = $UI/HanhTrang
@onready var _nut_bo_chay: Button = $UI/NutBoChay
@onready var _mo_ta_ky_nang: Label = $UI/KyNangMoTa
@onready var _hien_tai_nguyen: Control = $UI/TaiNguyenPlayer
@onready var _hien_mau_quai: Control = $UI/MauQuai

func _ready() -> void:
	# Nối tín hiệu nút MỘT LẦN duy nhất ở đây.
	# Nếu nối lại mỗi lượt thì tới lượt thứ ba một cú bấm sẽ tính thành ba lần.
	for i in _luoi.get_child_count():
		_luoi.get_child(i).pressed.connect(_on_chon_dap_an.bind(i))
	for i in _kho_chu.get_child_count():
		_kho_chu.get_child(i).pressed.connect(_on_nhat_chu.bind(i))
	_nut_xoa.pressed.connect(_xoa_cau_dang_xep)

	_cho_nhan_vat = _hinh_nhan_vat.position
	_cho_quai = _hinh_quai.position

	# Đánh/trúng đòn là animation KHÔNG lặp — chạy xong tự về idle (trừ khi đã gục).
	_anim_nv.animation_finished.connect(_nv_anim_xong)
	_hinh_quai.animation_finished.connect(_quai_anim_xong)
	_nut_bo_chay.pressed.connect(_on_bo_chay)

	_hien_tai_nguyen.dat_mau_lan(ANH_THANH_DO, ANH_THANH_XANH_DUONG, ANH_THANH_XANH_LA)
	# Quái chỉ có máu — cùng khung ảnh với người chơi, nhưng ẩn hai làn
	# Phép/Thể lực vì quái không có hai thứ đó.
	_hien_mau_quai.dat_mau_lan(ANH_THANH_DO)
	_hien_mau_quai.dat_chi_hp()

## CHEAT để thử quái cho nhanh: Ctrl+X là thắng ngay.
##
## Giữ lại theo yêu cầu — CHỈ xoá khi chủ dự án bảo xoá, đừng tự ý dọn.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if not (event.ctrl_pressed and event.keycode == KEY_X):
		return
	get_viewport().set_input_as_handled()
	if _da_chon:
		return
	_da_chon = true
	_mau_quai = 0
	_ket_qua.text = "CHEAT — thắng ngay"
	_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	_ve_thanh_mau()
	_guc(_hinh_quai)
	await get_tree().create_timer(0.35).timeout
	ket_thuc.emit(true, maxi(_mau_player, 1), _mp)

## Cỡ quái trong khung đấu, theo hạng — cùng tỉ lệ 1.5x / 3x như ngoài bản đồ
## (enemy.gd:CO_HANG) nhưng phóng to hơn để lấp khung 128x128 của trận đấu.
const CO_HANG_TRAN := {"thuong": 90.0, "elite": 135.0, "boss": 230.0}

func bat_dau(quai: Dictionary, nguoi: Dictionary) -> void:
	_chu_de = quai["chu_de"]
	_cap = quai["cap"]
	_cac_kieu = quai["cac_kieu"]
	_mau_quai = quai["mau"]
	_mau_quai_toi_da = quai["mau"]
	_quai_st_min = quai["st_min"]
	_quai_st_max = quai["st_max"]
	_dat_hinh_quai(quai["loai"], quai["hang"])

	_mau_player = nguoi["mau"]
	_mau_player_toi_da = nguoi["mau_toi_da"]
	_st_min = nguoi["st_min"]
	_st_max = nguoi["st_max"]
	_giap = nguoi.get("giap", 0)
	_nt_vu_khi = nguoi.get("nt_vu_khi", "")
	_co_bang = nguoi.get("co_bang", false)
	_co_ma = nguoi.get("co_ma", false)
	_mp = nguoi.get("mp", 0)
	_mp_toi_da = nguoi.get("mp_toi_da", 0)
	_the_luc = nguoi.get("the_luc", 0.0)
	_the_luc_toi_da = nguoi.get("the_luc_toi_da", 0.0)
	_hien_tai_nguyen.dat_the_luc(_the_luc, _the_luc_toi_da)
	_dung_lien_tiep = 0
	_dung_tong = 0
	_tt.xoa()
	_tt_quai.xoa()
	_khu_index = quai.get("khu_index", 0)
	_dung_o_ky_nang()
	_luot_moi()

## Gán đúng sprite con quái đang gặp — mặt quay trái để nhìn về phía nhân vật.
func _dat_hinh_quai(loai: String, hang: String) -> void:
	_loai_quai = loai
	_quai_da_guc = false
	_hinh_quai.animation = "%s_idle_left" % loai
	_hinh_quai.modulate = Color.WHITE
	var khung := _hinh_quai.sprite_frames.get_frame_texture(_hinh_quai.animation, 0)
	if khung == null:
		return
	var target: float = CO_HANG_TRAN.get(hang, CO_HANG_TRAN["thuong"])
	var ty_le := target / khung.get_size().x
	_hinh_quai.scale = Vector2(ty_le, ty_le)

## Đánh/trúng đòn của QUÁI chạy xong thì tự quay về idle — trừ khi đã gục.
func _quai_anim_xong() -> void:
	if _quai_da_guc:
		return
	_hinh_quai.play("%s_idle_left" % _loai_quai)

## Tỉ lệ bỏ chạy: 40% ở khu đầu, giảm 3% mỗi khu sau, sàn 10%.
func _ti_le_bo_chay() -> int:
	return maxi(10, 40 - 3 * _khu_index)

func _on_bo_chay() -> void:
	if _da_chon:
		return
	_da_chon = true
	if randi() % 100 < _ti_le_bo_chay():
		_ket_qua.text = "Chạy thoát!"
		_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
		await get_tree().create_timer(0.6).timeout
		chay_thoat.emit(_mau_player, _mp)
		return
	# Hụt: ăn một đòn của quái rồi trận tiếp tục (mất lượt) — trừ khi Băng
	# trên giáp né được, y hệt câu trả lời sai.
	if _co_bang and ChienDau.ne_duoc(ChienDau.NGUYEN_TO_NE):
		_ket_qua.text = "Chạy hụt! Băng né trọn!"
		_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	else:
		var an := ChienDau.sat_thuong_chiu(_quai_st_min, _quai_st_max, _giap)
		_mau_player -= an
		_ket_qua.text = "Chạy hụt!  −%d máu" % an
		_ket_qua.add_theme_color_override("font_color", MAU_SAI)
	_lao(_hinh_quai, _cho_quai, -1.0)
	_nv_dinh_don()
	_ve_thanh_mau()
	await get_tree().create_timer(1.1).timeout
	if _mau_player <= 0:
		_nv_guc()
		await get_tree().create_timer(0.9).timeout
		ket_thuc.emit(false, 0, 0)
	else:
		_luot_moi()

func _luot_moi() -> void:
	_da_chon = false
	_ket_qua.text = ""
	_ve_thanh_mau()

	var tu := VocabDB.lay_ngau_nhien(_chu_de, _cap)
	if tu.is_empty():
		# Không nên xảy ra nữa (world.gd đã lọc chủ đề lúc sinh quái), nhưng nếu
		# CSV lại thủng thì phải THẤY được, chứ không để lại màn đấu trắng trơn.
		#
		# KHOÁ LẠI ngay: 1,2 giây chờ dưới đây mà để _da_chon = false thì trong
		# quãng đó vẫn bấm được phép — _loai_bot() đọc _cau["dap_an"] trên
		# Dictionary rỗng là crash, còn phép 休 (bo_qua) hay Ctrl+X thì gọi
		# _luot_moi()/emit thêm lần nữa ⇒ ket_thuc bắn HAI LẦN, world.gd rơi đồ
		# hai lượt rồi đọc node quái đã queue_free.
		_da_chon = true
		push_error("Khong co tu nao cho chu de %s cap %d" % [_chu_de, _cap])
		_de_bai.text = "Thiếu dữ liệu"
		_cau_hoi.text = "Chủ đề \"%s\" chưa có từ ở cấp %d" % [_chu_de, _cap]
		_luoi.visible = false
		_kho_chu.visible = false
		_nut_xoa.visible = false
		await get_tree().create_timer(1.2).timeout
		ket_thuc.emit(true, maxi(_mau_player, 1), _mp)
		return

	_cau = _tao_cau_hoi(tu)
	_kieu_truoc = _cau["kieu"]
	_hien_cau_hoi()
	_cap_nhat_ky_nang()

# --- Chọn và dựng câu hỏi -------------------------------------------

func _tao_cau_hoi(tu: Dictionary) -> Dictionary:
	var cho_phep: Array = _cac_kieu if not _cac_kieu.is_empty() else TAT_CA_KIEU

	var kha_dung := []
	for k in cho_phep:
		if _dung_duoc(k, tu):
			kha_dung.append(k)
	if kha_dung.is_empty():
		kha_dung = ["trung_viet"]

	# Tránh hỏi trùng kiểu hai lượt liền — đơn điệu thì chán rất nhanh.
	var khac := kha_dung.filter(func(k): return k != _kieu_truoc)
	var kieu: String = (khac if not khac.is_empty() else kha_dung).pick_random()

	match kieu:
		"viet_trung": return _cau_viet_trung(tu)
		"dung_sai": return _cau_dung_sai(tu)
		"dien_tu": return _cau_dien_tu(tu)
		"ghep_bo_thu": return _cau_ghep_bo_thu(tu)
		"sap_xep": return _cau_sap_xep(tu)
		"np_dien": return _cau_np_dien()
		"np_dung_sai": return _cau_np_dung_sai()
		"dong_nghia": return _cau_dong_nghia(tu)
		"trai_nghia": return _cau_trai_nghia(tu)
		_: return _cau_trung_viet(tu)

func _dung_duoc(kieu: String, tu: Dictionary) -> bool:
	match kieu:
		# Hai kiểu ngữ pháp không dựa vào từ đang hỏi, mà lấy câu từ kho riêng.
		# Chỉ hỏi được nếu kho ngữ pháp có câu đúng cấp này.
		"np_dien":
			return not VocabDB.loc_ngu_phap("dien", _cap).is_empty()
		"np_dung_sai":
			return not VocabDB.loc_ngu_phap("dung_sai", _cap).is_empty()
		"ghep_bo_thu":
			return tu["bo_thu"].size() >= 2
		"sap_xep":
			var n := _tach_chu(tu["vi_du"]).size()
			return n >= 3 and n <= 6
		"dien_tu":
			return tu["vi_du"].contains(tu["chu"])
		"dong_nghia":
			return not tu["dong_nghia"].is_empty()
		"trai_nghia":
			return not tu["trai_nghia"].is_empty()
		_:
			return true

## Hiện chữ Hán, chọn nghĩa tiếng Việt.
func _cau_trung_viet(tu: Dictionary) -> Dictionary:
	# Chiều này nhiễu phải là NGHĨA, mà cột "nhieu" chứa chữ,
	# nên lấy nghĩa của các từ khác trong kho làm nhiễu.
	#
	# Phải loại cả NGHĨA KHÁC của chính chữ đang hỏi, không chỉ nghĩa chính:
	# 口 có nghia="miệng" nhưng nghia_khac cũng có "cửa", mà 门 lại mang đúng
	# nghĩa "cửa" ⇒ bốc trúng 门 làm nhiễu thì cả hai đáp án đều đúng, người
	# chơi chọn "cửa" bị chấm SAI và mất máu oan. Có 5 cặp như vậy trong CSV
	# (口 中 晚 老 里). _nghia_khac_han() ở dưới đã cẩn thận đúng chỗ này rồi.
	var cam := {tu["nghia"]: true}
	for n in tu["nghia_khac"]:
		cam[n] = true
	var kho := []
	for khac in VocabDB.tu_vung:
		if khac["chu"] != tu["chu"] and not cam.has(khac["nghia"]):
			kho.append(khac["nghia"])
	return {
		"kieu": "trung_viet",
		"de_bai": tu["chu"], "co_de_bai": 38,
		"cau_hoi": "%s — chữ này nghĩa là gì?" % tu["pinyin"],
		"dap_an": tu["nghia"],
		"lua_chon": _tron_dap_an(tu["nghia"], kho),
		"co_nut": 11,
	}

## Hiện nghĩa tiếng Việt, chọn chữ Hán. Đây là chiều khó.
func _cau_viet_trung(tu: Dictionary) -> Dictionary:
	# Chiều này dùng đúng cột "nhieu" — các chữ NHÌN GIỐNG chữ đúng.
	return {
		"kieu": "viet_trung",
		"de_bai": tu["nghia"], "co_de_bai": 20,
		"cau_hoi": "nghĩa này là chữ nào?",
		"dap_an": tu["chu"],
		"lua_chon": _tron_dap_an(tu["chu"], tu["nhieu"]),
		"co_nut": 18,
	}

## Tìm từ ĐỒNG NGHĨA — dạng khó, không còn dựa vào hình chữ hay nghĩa hiện sẵn,
## phải nhớ quan hệ giữa hai chữ.
func _cau_dong_nghia(tu: Dictionary) -> Dictionary:
	var dap_an: String = tu["dong_nghia"].pick_random()
	return {
		"kieu": "dong_nghia",
		"de_bai": tu["chu"], "co_de_bai": 38,
		"cau_hoi": "%s — từ nào ĐỒNG NGHĨA?" % tu["pinyin"],
		"dap_an": dap_an,
		"lua_chon": _tron_dap_an(dap_an, _kho_chu_khac_quan_he(tu)),
		"co_nut": 18,
	}

## Tìm từ TRÁI NGHĨA — cùng độ khó với đồng nghĩa.
func _cau_trai_nghia(tu: Dictionary) -> Dictionary:
	var dap_an: String = tu["trai_nghia"].pick_random()
	return {
		"kieu": "trai_nghia",
		"de_bai": tu["chu"], "co_de_bai": 38,
		"cau_hoi": "%s — từ nào TRÁI NGHĨA?" % tu["pinyin"],
		"dap_an": dap_an,
		"lua_chon": _tron_dap_an(dap_an, _kho_chu_khac_quan_he(tu)),
		"co_nut": 18,
	}

## Kho nhiễu cho đồng/trái nghĩa: MỌI chữ khác trong từ vựng, trừ chính từ
## đang hỏi và trừ luôn đồng nghĩa/trái nghĩa của nó — không thì nhiễu lại
## thành một đáp án đúng khác, làm câu hỏi có hai lựa chọn đều đúng.
func _kho_chu_khac_quan_he(tu: Dictionary) -> Array:
	var loai_tru: Array = [tu["chu"]] + tu["dong_nghia"] + tu["trai_nghia"]
	var kho := []
	for khac in VocabDB.tu_vung:
		if not loai_tru.has(khac["chu"]):
			kho.append(khac["chu"])
	return kho

## Cặp chữ-nghĩa, hỏi đúng hay sai. Nhanh, nhưng ép đọc kỹ.
func _cau_dung_sai(tu: Dictionary) -> Dictionary:
	var that := randi() % 2 == 0
	var nghia_hien: String = tu["nghia"]

	if not that:
		var kho := _nghia_khac_han(tu)
		if kho.is_empty():
			that = true
		else:
			nghia_hien = kho.pick_random()

	return {
		"kieu": "dung_sai",
		"de_bai": "%s  =  %s" % [tu["chu"], nghia_hien], "co_de_bai": 22,
		"cau_hoi": "%s — cặp này đúng hay sai?" % tu["pinyin"],
		"dap_an": "ĐÚNG" if that else "SAI",
		"lua_chon": ["ĐÚNG", "SAI"],
		"co_nut": 13,
	}

## Các nghĩa chắc chắn KHÔNG phải của từ này.
## Phải loại cả cột nghia_khac, không thì câu dựng ra để SAI lại hoá ra đúng.
func _nghia_khac_han(tu: Dictionary) -> Array:
	var kho := []
	for khac in VocabDB.tu_vung:
		if khac["chu"] == tu["chu"]:
			continue
		if khac["nghia"] == tu["nghia"]:
			continue
		if tu["nghia_khac"].has(khac["nghia"]):
			continue
		kho.append(khac["nghia"])
	return kho

## Khoét chữ khỏi câu ví dụ.
func _cau_dien_tu(tu: Dictionary) -> Dictionary:
	var cau: String = tu["vi_du"]
	var vt := cau.find(tu["chu"])
	var che := cau.substr(0, vt) + O_TRONG + cau.substr(vt + tu["chu"].length())
	return {
		"kieu": "dien_tu",
		"de_bai": che, "co_de_bai": 26,
		"cau_hoi": "%s — thiếu chữ nào?" % tu["vi_du_nghia"],
		"dap_an": tu["chu"],
		"lua_chon": _tron_dap_an(tu["chu"], tu["nhieu"]),
		"co_nut": 18,
	}

## Ghép bộ thủ thành chữ — nối thẳng vào hệ bộ thủ của Giai đoạn 1.
func _cau_ghep_bo_thu(tu: Dictionary) -> Dictionary:
	return {
		"kieu": "ghep_bo_thu",
		"de_bai": "  +  ".join(tu["bo_thu"]) + "  =  ?", "co_de_bai": 26,
		"cau_hoi": "ghép lại thành chữ nào?",
		"dap_an": tu["chu"],
		"lua_chon": _tron_dap_an(tu["chu"], tu["nhieu"]),
		"co_nut": 18,
	}

## Xáo chữ, bắt xếp lại thành câu đúng. Đây là dạng gần ngữ pháp nhất
## mà dữ liệu hiện có làm được: nó luyện trật tự từ.
func _cau_sap_xep(tu: Dictionary) -> Dictionary:
	var chu := _tach_chu(tu["vi_du"])
	var xao := chu.duplicate()
	# Xáo tới khi khác thứ tự gốc, không thì đề bày sẵn đáp án.
	for i in 10:
		xao.shuffle()
		if xao != chu:
			break
	return {
		"kieu": "sap_xep",
		"de_bai": tu["vi_du_nghia"], "co_de_bai": 15,
		"cau_hoi": "xếp lại thành câu tiếng Trung đúng",
		"thu_tu": chu,
		"xao": xao,
	}

## Ngữ pháp: khoét một chữ chức năng khỏi câu, chọn chữ đúng điền vào.
## Nhiễu ở đây là các chữ chức năng dễ nhầm với nhau (是 / 很 / 的 / 了).
func _cau_np_dien() -> Dictionary:
	var g := VocabDB.lay_ngu_phap_ngau_nhien("dien", _cap)
	return {
		"kieu": "np_dien",
		"de_bai": g["cau"], "co_de_bai": 24,
		"cau_hoi": "%s — thiếu chữ nào?" % g["nghia"],
		"dap_an": g["dap_an"],
		"lua_chon": _tron_dap_an(g["dap_an"], g["nhieu"]),
		"co_nut": 18,
		"giai_thich": g["diem"],
	}

## Ngữ pháp: cho xem một câu, hỏi câu đó viết đúng chưa.
func _cau_np_dung_sai() -> Dictionary:
	var g := VocabDB.lay_ngu_phap_ngau_nhien("dung_sai", _cap)
	var la_dung: bool = g["dap_an"] == "dung"

	var giai_thich: String = g["diem"]
	if not la_dung:
		giai_thich = "%s  ->  %s" % [g["diem"], g["sua"]]

	return {
		"kieu": "np_dung_sai",
		"de_bai": g["cau"], "co_de_bai": 24,
		"cau_hoi": "%s — câu này viết đúng chưa?" % g["nghia"],
		"dap_an": "ĐÚNG" if la_dung else "SAI",
		"lua_chon": ["ĐÚNG", "SAI"],
		"co_nut": 13,
		"giai_thich": giai_thich,
		"loi_giai": g["sua"] if not la_dung else g["cau"],
	}

## Tách câu thành từng chữ, bỏ dấu câu.
func _tach_chu(cau: String) -> Array:
	var ds := []
	for c in cau:
		if not DAU_CAU.contains(c):
			ds.append(c)
	return ds

## Ghép đáp án đúng với tối đa 3 nhiễu rồi xáo vị trí.
func _tron_dap_an(dung: String, kho_nhieu: Array) -> Array:
	var pool := []
	for x in kho_nhieu:
		if x != dung and not pool.has(x):
			pool.append(x)
	pool.shuffle()

	var ds := [dung]
	for i in mini(3, pool.size()):
		ds.append(pool[i])
	ds.shuffle()
	return ds

# --- Vẽ lên màn hình ------------------------------------------------

func _hien_cau_hoi() -> void:
	_de_bai.text = _cau["de_bai"]
	_de_bai.add_theme_font_size_override("font_size", _cau["co_de_bai"])
	_cau_hoi.text = _cau["cau_hoi"]
	_cau_hoi.add_theme_color_override("font_color", MAU_GOI_Y)

	var xep: bool = _cau["kieu"] == "sap_xep"
	_luoi.visible = not xep
	_cau_dang_xep.visible = xep
	_kho_chu.visible = xep
	_nut_xoa.visible = xep

	if xep:
		_dang_xep = []
		_bay_kho_chu()
		_ve_cau_dang_xep()
	else:
		for i in _luoi.get_child_count():
			var b: Button = _luoi.get_child(i)
			b.visible = i < _cau["lua_chon"].size()
			if b.visible:
				b.text = str(_cau["lua_chon"][i])
				b.add_theme_font_size_override("font_size", _cau["co_nut"])

func _bay_kho_chu() -> void:
	for i in _kho_chu.get_child_count():
		var b: Button = _kho_chu.get_child(i)
		b.visible = i < _cau["xao"].size()
		if b.visible:
			b.text = _cau["xao"][i]

func _ve_cau_dang_xep() -> void:
	var s := ""
	for c in _dang_xep:
		s += c
	for i in range(_dang_xep.size(), _cau["thu_tu"].size()):
		s += O_TRONG
	_cau_dang_xep.text = s

# --- Nhận thao tác --------------------------------------------------

func _on_chon_dap_an(i: int) -> void:
	# _cau rỗng = chưa dựng nổi câu hỏi; bấm vào lúc đó thì đọc _cau["dap_an"]
	# là văng game, nên chặn ngay từ đây.
	if _da_chon or _cau.is_empty() or _cau.get("kieu", "") == "sap_xep":
		return
	var loi_giai: String = _cau.get("loi_giai", str(_cau["dap_an"]))
	_cham_diem(_luoi.get_child(i).text == _cau["dap_an"], loi_giai)

func _on_nhat_chu(i: int) -> void:
	if _da_chon or _cau.is_empty():
		return
	var b: Button = _kho_chu.get_child(i)
	_dang_xep.append(b.text)
	b.visible = false
	_ve_cau_dang_xep()

	if _dang_xep.size() == _cau["thu_tu"].size():
		var loi_giai := ""
		for c in _cau["thu_tu"]:
			loi_giai += c
		_cham_diem(_dang_xep == _cau["thu_tu"], loi_giai)

func _xoa_cau_dang_xep() -> void:
	if _da_chon:
		return
	_dang_xep = []
	_bay_kho_chu()
	_ve_cau_dang_xep()

func _cham_diem(dung: bool, loi_giai: String) -> void:
	if _da_chon:
		return
	_da_chon = true

	# Độc (毒) rải từ đòn trước phát tác ĐẦU MỖI LƯỢT, trước cả đòn của lượt
	# này — _tt_quai là trạng thái riêng của QUÁI, tách khỏi _tt (của mình).
	var dong_doc := ""
	var dam_doc := _tt_quai.rut_doc()
	if dam_doc > 0:
		_mau_quai -= dam_doc
		dong_doc = "\n%s %s rỉ ra:  −%d máu quái" % [
			ChienDau.NGUYEN_TO_DOC, ChienDau.ten_nguyen_to(ChienDau.NGUYEN_TO_DOC), dam_doc]

	# MP hồi ĐẦY khi đúng 2 câu liên tiếp, hoặc 3 câu đúng dù ngắt quãng.
	var dong_mp := ""
	if dung:
		_dung_lien_tiep += 1
		_dung_tong += 1
	else:
		_dung_lien_tiep = 0
	# Bộ đếm phải reset NGAY khi chạm ngưỡng, kể cả lúc MP đang đầy. Trước đây
	# guard "_mp < _mp_toi_da" nằm chung một if nên lúc MP đầy thì ngưỡng đạt mà
	# không reset ⇒ bộ đếm "nợ" lại: đúng 3 câu (MP đầy, đếm kẹt ở 3) rồi dùng
	# một phép, câu tiếp theo TRẢ LỜI SAI vẫn thoả _dung_tong >= 3 ⇒ MP đầy lại
	# ngay trong lượt vừa ăn đòn.
	if _mp_toi_da > 0 and (_dung_lien_tiep >= 2 or _dung_tong >= 3):
		_dung_lien_tiep = 0
		_dung_tong = 0
		if _mp < _mp_toi_da:
			_mp = _mp_toi_da
			dong_mp = "\nMP đầy!"

	if dung:
		var sat_thuong := ChienDau.sat_thuong_gay(_st_min, _st_max, _tt.rut_don_them(), _nt_vu_khi)
		_mau_quai -= sat_thuong
		_ket_qua.text = "ĐÚNG!  −%d máu quái" % sat_thuong
		_ket_qua.add_theme_color_override("font_color", MAU_DUNG)

		# Thuỷ trên vũ khí: hút một phần sát thương vừa gây thành máu mình.
		var hut := ChienDau.hut_mau(sat_thuong, _nt_vu_khi)
		if hut > 0:
			_mau_player = mini(_mau_player + hut, _mau_player_toi_da)
			_ket_qua.text += "\n%s hút máu:  +%d" % [ChienDau.ten_nguyen_to(_nt_vu_khi), hut]

		# Độc trên vũ khí: đòn này gieo (hoặc làm mới) độc lên quái, phát
		# tác từ lượt SAU trở đi — không phát ngay trong lượt vừa đánh trúng.
		var doc_moi := ChienDau.doc_tu_danh(sat_thuong, _nt_vu_khi)
		if doc_moi.x > 0:
			_tt_quai.dat_doc(doc_moi)
	elif _co_bang and ChienDau.ne_duoc(ChienDau.NGUYEN_TO_NE):
		# Băng trên giáp: né MIỄN PHÍ, không tốn khiên phép — kiểm trước
		# khiên nên khiên chỉ tiêu khi né hụt.
		_ket_qua.text = "SAI — là %s. Băng né trọn!" % loi_giai
		_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	elif _tt.do_duoc():
		# Có khiên thì câu sai này không mất máu, nhưng khiên tiêu đi một lần.
		_ket_qua.text = "SAI — là %s. Khiên đỡ trọn!" % loi_giai
		_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	else:
		var an_don := ChienDau.sat_thuong_chiu(_quai_st_min, _quai_st_max, _giap)
		_mau_player -= an_don
		var do_giap := "" if _giap <= 0 else "  (giáp đỡ %d)" % _giap
		_ket_qua.text = "SAI — là %s.  −%d máu%s" % [loi_giai, an_don, do_giap]
		_ket_qua.add_theme_color_override("font_color", MAU_SAI)

	_ket_qua.text += dong_doc + dong_mp

	# Khoảnh khắc dạy học nằm ở đây: trả lời xong mới hiện VÌ SAO.
	if _cau.has("giai_thich"):
		_cau_hoi.text = _cau["giai_thich"]
		_cau_hoi.add_theme_color_override("font_color", MAU_DUNG if dung else MAU_SAI)

	if dung:
		_nv_danh()
		_an_don(_hinh_quai, _cho_quai)
	else:
		_lao(_hinh_quai, _cho_quai, -1.0)
		_nv_dinh_don()

	_ve_thanh_mau()
	_cap_nhat_ky_nang()

	# create_timer chạy cả khi cây scene đang bị pause, nên đếm giờ được.
	await get_tree().create_timer(2.4 if _cau.has("giai_thich") else 1.3).timeout

	if _mau_quai <= 0:
		_guc(_hinh_quai)
		await get_tree().create_timer(0.45).timeout
		ket_thuc.emit(true, maxi(_mau_player, 1), _mp)
	elif _mau_player <= 0:
		_nv_guc()
		await get_tree().create_timer(0.9).timeout
		ket_thuc.emit(false, 0, 0)
	else:
		_luot_moi()

# --- Kỹ năng --------------------------------------------------------
#
# Chữ ghép được từ bộ thủ biến thành phép dùng trong trận.
# Tác dụng nằm trong data/ky_nang.csv, KHÔNG hardcode ở đây —
# muốn đổi 明 từ "xoá 2 đáp án" thành "xoá 3" thì sửa CSV là xong.

func _dung_o_ky_nang() -> void:
	for cu in _hanh_trang.get_children():
		_hanh_trang.remove_child(cu)
		cu.queue_free()
	_mo_ta_ky_nang.text = ""

	# Chỉ dựng đúng những gì người chơi ĐÃ CHỌN MANG THEO ở màn Hành trang.
	#
	# Trước đây chỗ này tự gộp TẤT CẢ phép rồi mới nối đồ hồi máu vào đuôi, cắt
	# cứng ở 7 ô — mà ky_nang.csv có 19 phép, nên học tới phép thứ 7 là đồ hồi
	# máu bị đẩy văng hết, mất luôn thứ chống thua. Giờ người chơi tự quyết.
	for i in SO_O_HT:
		var o: OHanhTrang = O_KY_NANG.instantiate()
		_hanh_trang.add_child(o)
		var chu: String = Tui.mang_theo[i] if i < Tui.mang_theo.size() else ""
		if chu == "":
			o.disabled = true   # ô trống: không bấm được nhưng vẫn sáng bình thường
			continue
		var kn := VocabDB.ky_nang_cua(chu)
		if not kn.is_empty() and Tui.da_co_chu(chu):
			o.set_meta("kn", kn)
			o.pressed.connect(_on_dung_ky_nang.bind(kn))
			o.mouse_entered.connect(_ke_ky_nang.bind(kn))
			o.mouse_exited.connect(_xoa_mo_ta_ky_nang)
			o.dat(chu, Tui.con_luot(chu), false)
		else:
			var tb := Tui.mon_cua(chu)
			o.set_meta("th", chu)
			o.pressed.connect(_on_dung_tieu_hao.bind(chu))
			o.mouse_entered.connect(_ke_tieu_hao.bind(tb))
			o.mouse_exited.connect(_xoa_mo_ta_ky_nang)
			o.modulate = Color(0.6, 1.0, 0.7)
			o.dat(chu, Tui.so_co(chu), false)

func _ke_tieu_hao(tb: Dictionary) -> void:
	var con: int = Tui.so_co(tb["chu"])
	_mo_ta_ky_nang.text = "%s  %s — hồi %d máu  ·  còn %d" % [
		tb["chu"], tb["nghia"], int(tb["gia_tri"]), con]

func _on_dung_tieu_hao(chu: String) -> void:
	if _da_chon or _mau_player >= _mau_player_toi_da:
		return
	var gt := Tui.dung_tieu_hao(chu)
	if gt <= 0:
		return
	_mau_player = mini(_mau_player + gt, _mau_player_toi_da)
	_ket_qua.text = "Dùng %s — hồi %d máu" % [chu, gt]
	_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	_ve_thanh_mau()
	# Số lượng đổi (có thể hết) nên dựng lại cả thanh cho đúng.
	_dung_o_ky_nang()
	# _dung_o_ky_nang() dựng ô mới ở trạng thái mặc định (sáng, bấm được), nên
	# phải chạy lại _cap_nhat_ky_nang() — không thì phép hết lượt / thiếu MP
	# bỗng sáng trắng trở lại và trông như bấm được.
	_cap_nhat_ky_nang()

func _ke_ky_nang(kn: Dictionary) -> void:
	var con: int = Tui.con_luot(kn["chu"])
	var tinh_trang := "  ·  còn %d lượt  ·  tốn %d MP" % [con, CO_PHEP_MP]
	if con <= 0:
		tinh_trang = "  ·  HẾT LƯỢT — về hành trang ghép lại để nạp"
	elif _mp < CO_PHEP_MP:
		tinh_trang = "  ·  còn %d lượt  ·  THIẾU MP (cần %d)" % [con, CO_PHEP_MP]
	elif not _dung_duoc_ky_nang(kn):
		tinh_trang = "  ·  còn %d lượt  ·  giờ chưa dùng được" % con
	_mo_ta_ky_nang.text = "%s  %s — %s%s" % [kn["chu"], kn["ten"], kn["mo_ta"], tinh_trang]

func _xoa_mo_ta_ky_nang() -> void:
	_mo_ta_ky_nang.text = ""

func _dung_duoc_ky_nang(kn: Dictionary) -> bool:
	if Tui.con_luot(kn["chu"]) <= 0 or _da_chon or _mp < CO_PHEP_MP:
		return false
	match kn["hieu_ung"]:
		"loai_bot":
			# Câu sắp xếp không có đáp án để xoá bớt.
			return _cau.get("kieu", "") != "sap_xep" and _so_nut_hien() > 2
		"hoi_mau":
			return _mau_player < _mau_player_toi_da
		_:
			return true

func _cap_nhat_ky_nang() -> void:
	for o in _hanh_trang.get_children():
		if not o.has_meta("kn"):
			continue  # ô trống hoặc đồ tiêu hao, không phải phép
		var kn: Dictionary = o.get_meta("kn")
		var con: int = Tui.con_luot(kn["chu"])
		o.dat(kn["chu"], con, false)
		o.disabled = not _dung_duoc_ky_nang(kn)
		o.modulate = Color(0.45, 0.45, 0.5) if con <= 0 else Color.WHITE

func _so_nut_hien() -> int:
	var n := 0
	for b in _luoi.get_children():
		if b.visible:
			n += 1
	return n

## Xoá bớt đáp án sai, nhưng luôn chừa lại ít nhất 2 lựa chọn.
func _loai_bot(so: int) -> void:
	# _cau rỗng = chưa dựng nổi câu hỏi. Đọc _cau["dap_an"] lúc đó là crash,
	# nên chặn ở đây luôn chứ không chỉ dựa vào _da_chon ở ngoài.
	if _cau.is_empty():
		return
	var sai := []
	for b in _luoi.get_children():
		if b.visible and b.text != _cau["dap_an"]:
			sai.append(b)
	sai.shuffle()

	var bo_toi_da: int = maxi(0, _so_nut_hien() - 2)
	for i in mini(so, mini(sai.size(), bo_toi_da)):
		sai[i].visible = false

func _on_dung_ky_nang(kn: Dictionary) -> void:
	if not _dung_duoc_ky_nang(kn):
		return
	if not Tui.dung_luot(kn["chu"]):
		return
	_mp -= CO_PHEP_MP

	var gt: int = kn["gia_tri"]
	# Hiệu ứng dùng chung cho mọi kiểu đánh nhau thì để ChienDau lo — nó chỉ
	# trả về VIỆC CẦN LÀM, còn vẽ ra sao thì màn này tự quyết.
	var kq := ChienDau.dung_phep(kn["hieu_ung"], gt, _tt, ChienDau.he_so_ma(_co_ma))
	if kq["hoi"] > 0:
		_mau_player = mini(_mau_player + kq["hoi"], _mau_player_toi_da)
	if kq["danh"] > 0:
		_mau_quai -= kq["danh"]
		_an_don(_hinh_quai, _cho_quai)
	# Phép chỉ có nghĩa khi đang có câu hỏi trước mặt thì xử ngay tại đây.
	if not kq["chay"]:
		match kn["hieu_ung"]:
			"loai_bot":
				_loai_bot(gt)

	_ket_qua.text = "Dùng %s — %s" % [kn["chu"], kn["ten"]]
	_ket_qua.add_theme_color_override("font_color", MAU_KY_NANG)
	_ve_thanh_mau()
	_cap_nhat_ky_nang()
	_ke_ky_nang(kn)

	if kn["hieu_ung"] == "danh_truoc" and _mau_quai <= 0:
		_da_chon = true
		_guc(_hinh_quai)
		await get_tree().create_timer(0.45).timeout
		ket_thuc.emit(true, maxi(_mau_player, 1), _mp)
	elif kn["hieu_ung"] == "bo_qua":
		_da_chon = true
		await get_tree().create_timer(0.7).timeout
		_luot_moi()

# --- Hiệu ứng đánh nhau (bên QUÁI) -----------------------------------
#
# enemy_frames.tres giờ có animation đánh/trúng đòn/gục thật (hướng trái,
# cắt từ Attack/Hurt/Death của cùng bộ ảnh idle/walk) — chạy animation thật
# SONG SONG với tween lao/rung/mờ có sẵn, chứ không thay hẳn, vì tween còn
# lo phần "di chuyển vị trí" mà animation không có.

const XA_LAO := 14.0

## Lao tới rồi lùi về, kèm animation đánh thật.
func _lao(hinh: AnimatedSprite2D, cho_cu: Vector2, huong: float) -> void:
	if not _quai_da_guc:
		hinh.play("%s_attack_left" % _loai_quai)

	var t := create_tween()
	t.tween_property(hinh, "position:x", cho_cu.x + XA_LAO * huong, 0.09)
	t.tween_property(hinh, "position:x", cho_cu.x, 0.20)

## Rung ngang + chớp trắng, kèm animation trúng đòn thật.
func _an_don(hinh: AnimatedSprite2D, cho_cu: Vector2) -> void:
	if not _quai_da_guc:
		hinh.play("%s_hurt_left" % _loai_quai)
	var mau_cu: Color = hinh.modulate

	var rung := create_tween()
	for i in 3:
		rung.tween_property(hinh, "position:x", cho_cu.x + 4.0, 0.04)
		rung.tween_property(hinh, "position:x", cho_cu.x - 4.0, 0.04)
	rung.tween_property(hinh, "position:x", cho_cu.x, 0.04)

	var chop := create_tween()
	chop.tween_property(hinh, "modulate", Color(2.2, 2.2, 2.2, 1), 0.05)
	chop.tween_property(hinh, "modulate", mau_cu, 0.30)
	_chop_quai = chop

## Chạy animation gục thật, rồi mờ dần biến mất.
func _guc(hinh: AnimatedSprite2D) -> void:
	_quai_da_guc = true
	hinh.play("%s_death_left" % _loai_quai)
	# Tween chớp trắng của _an_don() cũng ghi vào modulate (đủ 4 kênh, alpha = 1)
	# nên nếu nó còn chạy thì nó ghi đè phần mờ dần ở đây. Bình thường hai lời
	# gọi cách nhau hơn 1,3 giây nên không đụng, nhưng phép "đánh trước" (早) kết
	# liễu quái thì gọi cả hai TRONG CÙNG MỘT KHUNG HÌNH ⇒ quái biến mất phựt
	# thay vì mờ dần. Dừng nó trước.
	if _chop_quai != null and _chop_quai.is_valid():
		_chop_quai.kill()
	hinh.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(hinh, "modulate:a", 0.0, 0.40)

# --- Hình NHÂN VẬT: sprite thật, đánh bằng animation kiếm (mặt quay phải).
# Đánh / trúng đòn là animation KHÔNG lặp → chạy xong _nv_anim_xong đưa về idle.

func _nv_danh() -> void:
	if _nv_da_guc:
		return
	_anim_nv.play("sword_attack_right")

func _nv_dinh_don() -> void:
	if _nv_da_guc:
		return
	_anim_nv.play("sword_hurt_right")

func _nv_guc() -> void:
	_nv_da_guc = true
	_anim_nv.play("sword_death_right")

func _nv_anim_xong() -> void:
	if _nv_da_guc:
		return
	_anim_nv.play("sword_idle_right")

func _ve_thanh_mau() -> void:
	_hien_tai_nguyen.dat_hp(_mau_player, _mau_player_toi_da)
	_hien_tai_nguyen.dat_mp(_mp, _mp_toi_da)
	_hien_mau_quai.dat_hp(_mau_quai, _mau_quai_toi_da)
