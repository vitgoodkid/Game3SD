extends Control

## Bàn chế đồ kéo–thả. Ngữ pháp món đồ = ngữ pháp tiếng Trung:
##   [cường hoá] + [nguyên tố] + [vật liệu] + [trang bị]
##   极 + 冰 + 金 + 剑  ->  极冰金剑  (cực băng kim kiếm)
##
## Chỉ ô TRANG BỊ là bắt buộc; ba ô bổ nghĩa đứng trước đều tuỳ chọn — đúng như
## tiếng Trung, bỏ hết bổ nghĩa vẫn còn một danh từ hợp lệ.
##
## Chỉ số món = chỉ số món nền + điểm cộng của từng thứ bổ nghĩa (cột "cong"
## trong nguyen_lieu.csv). Loại/bộ phận lấy theo ô TRANG BỊ.
##
## Kho liệu KHÔNG bị trừ lúc thả vào bàn — chỉ trừ đúng lúc bấm Chế. Nhờ vậy
## đóng túi giữa chừng không bao giờ mất đồ; bàn chỉ là chỗ bày, không phải kho.

## Bốn ô xếp hình chữ thập quanh cái đe: cường hoá trên, vật liệu trái,
## nguyên tố phải, TRANG BỊ ở giữa (ô bắt buộc, nên đặt chính giữa) — cộng ô
## kết quả bên trái đe.
##
## NĂM Ô NÀY ĐẶT SẴN TRONG craft.tscn (BanGhep), không dựng bằng code nữa:
## toạ độ, cỡ ô, chữ gợi ý và khe đều chỉnh ngay trong editor bằng chuột.
## Ở đây chỉ còn TÊN NODE để tìm, thứ tự quyết định I_NEN bên dưới.
const NODE_KHE_NHAP := ["KhePhoTu", "KheNguyenTo", "KheVatLieu", "KheNen"]
const NODE_O_RA := "OKetQua"
## Số ô tối thiểu luôn bày ở kho, kể cả chưa nhặt được nguyên liệu nào.
const SO_O_KHO := 18
## Ô TRANG BỊ là ô cuối — bắt buộc phải có thì mới chế được.
## (khoá dữ liệu vẫn là "nen" trong nguyen_lieu.csv, chỉ đổi chữ hiện ra.)
const I_NEN := 3

const MAU_VUI := Color(0.5, 0.95, 0.55)
const MAU_BUON := Color(0.9, 0.55, 0.4)
const TEN_LOAI := {"giap": "giáp", "vukhi": "vũ khí", "tieu_hao": "đồ hồi máu"}
const TEN_KHE := {"pho_tu": "cường hoá", "nguyen_to": "nguyên tố", "vat_lieu": "vật liệu"}
const TEN_BP := {"dau": "Đầu", "than": "Thân", "tay": "Tay", "chan": "Chân",
	"quan": "Quần", "vu_khi": "Vũ khí", "hoi_mau": "hồi máu"}

## Báo ra ngoài để craft.gd kể trong khung mô tả phía dưới.
signal bao(chu: String, mau: Color)
## Kể chi tiết khi rê chuột vào một ô kho: hai dòng của khung mô tả.
signal ke(d1: String, d2: String)
signal thoi_ke

@onready var _kho_luoi: GridContainer = $KhoCuon/KhoLuoi
@onready var _ban_ghep: Control = $BanGhep
@onready var _nut_che: Button = $NutChe
@onready var _ket_qua: Label = $KetQua

var _o_nhap: Array[CraftSlot] = []
var _o_ra: CraftSlot

func _ready() -> void:
	_dung_ban()
	Tui.thay_doi.connect(_ve_kho)
	_nut_che.pressed.connect(_on_che)
	_ve_kho()
	_cap_nhat_nut()

## Tìm 4 ô nhập + ô kết quả đã đặt sẵn trong scene rồi nối tín hiệu.
func _dung_ban() -> void:
	for ten in NODE_KHE_NHAP:
		var o := _ban_ghep.get_node_or_null(ten) as CraftSlot
		if o == null:
			push_error("craft.tscn thiếu ô '%s' trong BanGhep" % ten)
			continue
		o.doi.connect(_on_ban_doi)
		_o_nhap.append(o)

	_o_ra = _ban_ghep.get_node_or_null(NODE_O_RA) as CraftSlot
	if _o_ra == null:
		push_error("craft.tscn thiếu ô '%s' trong BanGhep" % NODE_O_RA)

# --- Kho liệu -------------------------------------------------------

## Số món còn rút được của một chữ = trong kho trừ đi số đang bày trên bàn.
func _con_lai(chu: String) -> int:
	var n := Tui.co_nl(chu)
	for o in _o_nhap:
		if o.chu == chu:
			n -= 1
	return n

## Kho luôn bày đủ SO_O_KHO ô, thiếu thì bù ô trống. Trang sách rỗng trơ ra
## trông như lỗi hiển thị; có sẵn khung ô thì đọc ra ngay là "chưa có gì".
## Ô trống vẫn nhận được đồ trả từ bàn ghép về.
func _ve_kho() -> void:
	for c in _kho_luoi.get_children():
		_kho_luoi.remove_child(c)
		c.queue_free()
	var co := []
	var ds := Tui.nguyen_lieu.keys()
	ds.sort()
	for chu in ds:
		# Chữ không xếp vào khe nào (đồ ăn trong công thức cũ) thì không bày ở bàn.
		if _con_lai(chu) > 0 and VocabDB.khe_cua(chu) != "":
			co.append(chu)
	var tong: int = maxi(SO_O_KHO, int(ceil(co.size() / 3.0)) * 3)
	for i in tong:
		var o := CraftSlot.new(CraftSlot.Kieu.KHO)
		o.custom_minimum_size = CraftSlot.CO_O
		o.doi.connect(_on_ban_doi)
		_kho_luoi.add_child(o)
		if i < co.size():
			var chu: String = co[i]
			o.dat(chu, _con_lai(chu))
			o.mouse_entered.connect(_ke_lieu.bind(chu))
			o.mouse_exited.connect(func() -> void: thoi_ke.emit())

## Rê vào một nguyên liệu: nói nó thuộc khe nào và góp bao nhiêu chỉ số.
func _ke_lieu(chu: String) -> void:
	var m := VocabDB.nguyen_lieu_cua(chu)
	var d1: String = "%s   (nguyên liệu)" % chu
	if not m.is_empty():
		d1 = "%s   %s (%s) — %s" % [chu, m["pinyin"], m["han_viet"], m["nghia"]]
	var khe := VocabDB.khe_cua(chu)
	var bac := DoHiem.hiem_cua(chu)
	var d2 := ""
	if khe == "nen":
		d2 = "Đang có %d  ·  ô TRANG BỊ  ·  chỉ số gốc %d" % [
			Tui.co_nl(chu), VocabDB.cong_cua(chu)]
	else:
		d2 = "Đang có %d  ·  ô %s  ·  +%d chỉ số" % [
			Tui.co_nl(chu), TEN_KHE.get(khe, khe), VocabDB.cong_cua(chu)]
	d2 += "  ·  %s" % DoHiem.ten(bac)
	ke.emit(d1, d2)

# --- Ghép -----------------------------------------------------------

func _on_ban_doi() -> void:
	# Gọi trễ một nhịp: lúc _drop_data bắn tín hiệu, ô nguồn có thể chưa dọn xong.
	_ve_kho.call_deferred()
	_cap_nhat_nut.call_deferred()

## Tên món = nối chữ trong 4 ô theo đúng thứ tự khe.
func _ten_ghep() -> String:
	var ten := ""
	for o in _o_nhap:
		ten += o.chu
	return ten

## Chỉ số = nền + mọi điểm cộng của thứ bổ nghĩa đang đặt.
func _chi_so() -> int:
	var t := 0
	for o in _o_nhap:
		if not o.trong():
			t += VocabDB.cong_cua(o.chu)
	return t

func _cap_nhat_nut() -> void:
	var co_nen := not _o_nhap[I_NEN].trong()
	_nut_che.disabled = not co_nen
	if not co_nen:
		_ket_qua.text = "Kéo một chữ TRANG BỊ vào ô giữa."
		return
	var nen := VocabDB.nguyen_lieu_cua(_o_nhap[I_NEN].chu)
	var loai: String = nen.get("loai", "")
	# Vũ khí / tiêu hao chỉ có một chỗ đeo nên nói tên loại là đủ; riêng giáp
	# mới cần kèm bộ phận, không thì ra "vũ khí Vũ khí".
	var mo_ta: String = TEN_LOAI.get(loai, "")
	if loai == "giap":
		mo_ta += " " + TEN_BP.get(nen.get("bo_phan", ""), "")
	# Bậc hiếm hiện ngay lúc còn đang bày, chưa bấm Chế — để thấy nhét thêm một
	# chữ hiếm vào thì món nhảy bậc, đó chính là cái đáng chơi ở bàn ghép này.
	var dang_co := _chu_dang_bay()
	var bac := DoHiem.hiem_mon(dang_co)
	var nt := ChienDau.nguyen_to_cua(dang_co)
	var dong_nt := "" if nt == "" else "\n%s %s" % [nt, ChienDau.ten_nguyen_to(nt)]
	_ket_qua.text = "%s\n%s  ·  %d  ·  %s%s" % [
		_ten_ghep(), mo_ta, _chi_so(), DoHiem.ten(bac), dong_nt]
	_ket_qua.add_theme_color_override("font_color", DoHiem.mau(bac))

## Các chữ đang nằm trên bàn, theo đúng thứ tự khe.
func _chu_dang_bay() -> Array:
	var ds := []
	for o in _o_nhap:
		if not o.trong():
			ds.append(o.chu)
	return ds

func _on_che() -> void:
	var o_nen := _o_nhap[I_NEN]
	if o_nen.trong():
		_bao("Thiếu chữ TRANG BỊ — món nào cũng phải có một món nền.", MAU_BUON)
		return

	# Tên món = nối chữ 4 ô, mà cách nối đó tái tạo đúng tên 11/18 món trong
	# trang_bi.csv (红药 = 红 + 药, 宝剑 = 宝 + 剑...). Tui.mon_cua() ưu tiên đồ
	# tự chế nên chế trúng tên đó là GHI ĐÈ món cũ vĩnh viễn — 红药 tụt từ hồi
	# 60 xuống 41, ghi thẳng vào file lưu. Chặn ngay từ đây, KHÔNG tiêu liệu.
	var ten := _ten_ghep()
	if not VocabDB.trang_bi_cua(ten).is_empty():
		_bao("%s đã có công thức sẵn — sang thẻ Chế tạo để chế món đó." % ten, MAU_BUON)
		return

	# Gom liệu cần tiêu. Ô bày trên bàn chưa trừ kho nên phải kiểm lại lần cuối:
	# kho có thể đã đổi (bán/chế món khác) trong lúc đang bày.
	var can := {}
	for o in _o_nhap:
		if not o.trong():
			can[o.chu] = can.get(o.chu, 0) + 1
	for chu in can:
		if Tui.co_nl(chu) < can[chu]:
			_bao("Thiếu %s — cần %d, kho còn %d." % [chu, can[chu], Tui.co_nl(chu)], MAU_BUON)
			return

	var nen := VocabDB.nguyen_lieu_cua(o_nen.chu)
	# can.keys() không mất chữ nào: mỗi chữ chỉ hợp đúng một khe, nên bốn ô
	# không bao giờ chứa hai chữ trùng nhau.
	var thanh_phan: Array = can.keys()
	var mon := {
		"chu": ten,
		"loai": nen.get("loai", "giap"),
		"bo_phan": nen.get("bo_phan", "than"),
		"gia_tri": _chi_so(),
		"thanh_phan": thanh_phan,
		"hiem": DoHiem.hiem_mon(thanh_phan),
		"nguyen_to": ChienDau.nguyen_to_cua(thanh_phan),
		"nghia": "đồ tự chế",
		"tu_che": true,
	}

	for chu in can:
		Tui.bot_nl(chu, can[chu])
	Tui.che_tu_do(mon)

	for o in _o_nhap:
		o.xoa()
	_o_ra.dat(ten)
	# Cập nhật nút TRƯỚC khi báo, vì _cap_nhat_nut cũng ghi vào _ket_qua.
	_cap_nhat_nut()

	var hieu := ""
	match mon["loai"]:
		"giap": hieu = "giảm %d sát thương nhận" % mon["gia_tri"]
		"vukhi": hieu = "tăng %d sát thương gây ra" % mon["gia_tri"]
		"tieu_hao": hieu = "hồi %d máu" % mon["gia_tri"]
	var nt: String = mon["nguyen_to"]
	var them_nt := "" if nt == "" else " · mang nguyên tố %s %s" % [nt, ChienDau.ten_nguyen_to(nt)]
	# Báo bằng chính màu của bậc, để lúc ra được món xịn thì thấy ngay.
	_bao("Chế ra %s [%s] — %s%s. Sang Hành trang để mặc." % [
		ten, DoHiem.ten(mon["hiem"]), hieu, them_nt], DoHiem.mau(mon["hiem"]))
	_ve_kho()

## Tin nhắn đi ra khung mô tả to dưới đáy (craft.gd giữ khung đó), không nhồi
## vào ô kết quả bé xíu trong lòng khung sách.
func _bao(chu: String, mau: Color) -> void:
	bao.emit(chu, mau)
