extends Node

## Trạng thái thế giới: bia đá, hồi sinh quái, vũng hồn rơi lại khi chết.
## Autoload: gọi bằng "TheGioi".
##
## Vòng lặp souls kinh điển nằm ở đây (mục 4.5):
##   chết  → rơi hết hồn chưa tiêu tại chỗ chết
##   về    → nhặt lại được
##   chết lần nữa trước khi nhặt → MẤT VĨNH VIỄN
##
## Ở game này mất hồn đau hơn mất điểm ở game khác, vì hồn chính là chữ vừa
## học xong. Đó là chủ ý, không phải tình cờ.

signal nghi_bia_da(ma_bia: String)
signal hoi_sinh
signal chet
signal vao_vung(ma_vung: String)
## Hạ xong một boss. `LuuGame` nghe để tự lưu — hạ boss là mốc mà mất tiến trình
## thì người chơi đau nhất, và cũng là mốc dễ quên lưu tay nhất.
signal ha_boss_xong(ma_boss: String)

## Bia đá đã bật. Bật rồi thì dịch chuyển tới được.
var bia_da_da_bat := {}
## Bia đá đang gắn — chết là hồi sinh ở đây.
var bia_hien_tai := ""
var vung_hien_tai := "thi_tran"

## Vũng hồn rơi lại: {vung, vi_tri (Vector3), hon}. Rỗng = không có vũng nào.
## Chỉ có MỘT vũng cùng lúc — chết lần hai là vũng cũ biến mất.
var vung_hon := {}

## Quái đã hạ, theo id ổn định của từng con. Nghỉ bia đá là xoá sạch — quái
## sống lại hết, đúng luật souls.
var quai_da_ha := {}
## Boss đã hạ thì KHÔNG sống lại. Tách riêng khỏi quái thường.
var boss_da_ha := {}
## Vùng đã khôi phục tên (mục 7.5): trắng bệch → có màu và chi tiết trở lại.
var vung_da_khoi_phuc := {}

var so_lan_chet := 0

# --- Bia đá ---------------------------------------------------------

func bat_bia(ma: String) -> void:
	bia_da_da_bat[ma] = true
	bia_hien_tai = ma

## Nghỉ ở bia đá: hồi đầy, quái sống lại. Không hồi vũng hồn — vũng nằm chỗ
## mình chết, muốn lấy phải tự đi.
func nghi(ma: String) -> void:
	bat_bia(ma)
	quai_da_ha.clear()
	Tui.hoi_day()
	nghi_bia_da.emit(ma)

func bia_da_bat(ma: String) -> bool:
	return bool(bia_da_da_bat.get(ma, false))

func so_bia_da_bat() -> int:
	return bia_da_da_bat.size()

# --- Chết và hồi sinh -----------------------------------------------

## Chết ở `vi_tri` thuộc `ma_vung`. Rơi hết hồn chưa tiêu tại đó.
##
## Vũng cũ chưa nhặt thì MẤT — đây là chỗ luật souls cắn thật. Không có ngoại
## lệ, không có "lần này tha cho", vì tha một lần là hỏng cả cơ chế.
func chet_tai(ma_vung: String, vi_tri: Vector3) -> void:
	so_lan_chet += 1
	var roi := Tui.hon
	if roi > 0:
		vung_hon = {"vung": ma_vung, "x": vi_tri.x, "y": vi_tri.y, "z": vi_tri.z, "hon": roi}
	else:
		# Chết mà không mang hồn nào thì vũng cũ (nếu có) vẫn mất. Đúng luật:
		# cái mất đi là LƯỢT về nhặt, không phải số hồn đang cầm.
		vung_hon = {}
	Tui.hon = 0
	Tui.doi_hon.emit(0)
	chet.emit()

func hoi_sinh_o_bia() -> void:
	Tui.hoi_day()
	quai_da_ha.clear()
	hoi_sinh.emit()

func co_vung_hon() -> bool:
	return not vung_hon.is_empty()

func so_hon_trong_vung() -> int:
	return 0 if vung_hon.is_empty() else int(vung_hon["hon"])

func vi_tri_vung_hon() -> Vector3:
	if vung_hon.is_empty():
		return Vector3.ZERO
	return Vector3(float(vung_hon["x"]), float(vung_hon["y"]), float(vung_hon["z"]))

func nhat_vung_hon() -> int:
	if vung_hon.is_empty():
		return 0
	var n := int(vung_hon["hon"])
	Tui.them_hon(n)
	vung_hon = {}
	return n

# --- Quái -----------------------------------------------------------

## id ổn định: mã vùng + toạ độ đặt ban đầu, làm tròn. Dùng toạ độ chứ không
## dùng chỉ số node vì địa hình vùng hoang dã sinh tự động — số node đổi mỗi
## lần nạp, toạ độ thì không.
func id_quai(ma_vung: String, dat_tai: Vector3) -> String:
	return "%s:%d,%d,%d" % [ma_vung, roundi(dat_tai.x), roundi(dat_tai.y), roundi(dat_tai.z)]

func danh_dau_ha(id: String) -> void:
	quai_da_ha[id] = true

func da_ha(id: String) -> bool:
	return bool(quai_da_ha.get(id, false))

func ha_boss(ma: String) -> void:
	boss_da_ha[ma] = true
	ha_boss_xong.emit(ma)
	# Hạ boss là khôi phục tên cho cả vùng — màu và chi tiết trở lại (mục 7.5).
	var b := VocabDB.boss_cua(ma)
	if not b.is_empty():
		khoi_phuc_vung(String(b["vung"]))

func boss_da_ha_roi(ma: String) -> bool:
	return bool(boss_da_ha.get(ma, false))

# --- Vùng -----------------------------------------------------------

func doi_vung(ma: String) -> void:
	if ma == vung_hien_tai:
		return
	vung_hien_tai = ma
	vao_vung.emit(ma)

## Vùng đã mở chưa: vùng đầu luôn mở, vùng sau cần hạ boss vùng trước.
func vung_mo(ma: String) -> bool:
	var v := VocabDB.vung_cua(ma)
	if v.is_empty():
		return false
	var truoc := String(v.get("mo_khi", ""))
	if truoc == "":
		return true
	var b := VocabDB.boss_trong_vung(truoc)
	return b.is_empty() or boss_da_ha_roi(String(b["ma"]))

func khoi_phuc_vung(ma: String) -> void:
	vung_da_khoi_phuc[ma] = true

## Mức "bị xoá" thực tế của một vùng, 0 = bình thường, 1 = trắng bệch hoàn
## toàn. Khôi phục rồi thì về 0 — đó là phần thưởng nhìn thấy được của việc
## đi khôi phục từng cái tên.
func do_bi_xoa(ma: String) -> float:
	if bool(vung_da_khoi_phuc.get(ma, false)):
		return 0.0
	return float(VocabDB.vung_cua(ma).get("bi_xoa", 0.0))

# --- Lưu / nạp ------------------------------------------------------

func thanh_du_lieu() -> Dictionary:
	return {
		"bia_da_da_bat": bia_da_da_bat.duplicate(),
		"bia_hien_tai": bia_hien_tai,
		"vung_hien_tai": vung_hien_tai,
		"vung_hon": vung_hon.duplicate(),
		"boss_da_ha": boss_da_ha.duplicate(),
		"vung_da_khoi_phuc": vung_da_khoi_phuc.duplicate(),
		"so_lan_chet": so_lan_chet,
	}

## Về đúng trạng thái của giây đầu tiên một ván mới.
##
## `vung_bat_dau` truyền từ ngoài vào chứ không đọc `DuHanh` ở đây: file này là
## AUTOLOAD đăng ký TRƯỚC `DuHanh`, và nhắc tên một autoload chưa đăng ký xong
## là đúng cái vòng tròn đã làm gãy cả game một lần (xem ghi chú dài trong
## `du_hanh.gd`). Để rỗng thì giữ nguyên vùng mặc định.
func ban_moi(vung_bat_dau: String = "") -> void:
	bia_da_da_bat.clear()
	bia_hien_tai = ""
	if vung_bat_dau != "":
		vung_hien_tai = vung_bat_dau
	vung_hon.clear()
	quai_da_ha.clear()
	boss_da_ha.clear()
	vung_da_khoi_phuc.clear()
	so_lan_chet = 0

func tu_du_lieu(d: Dictionary) -> void:
	bia_da_da_bat = d.get("bia_da_da_bat", {}).duplicate()
	bia_hien_tai = String(d.get("bia_hien_tai", ""))
	vung_hien_tai = String(d.get("vung_hien_tai", "thi_tran"))
	vung_hon = d.get("vung_hon", {}).duplicate()
	boss_da_ha = d.get("boss_da_ha", {}).duplicate()
	vung_da_khoi_phuc = d.get("vung_da_khoi_phuc", {}).duplicate()
	so_lan_chet = int(d.get("so_lan_chet", 0))
	# Quái thường KHÔNG lưu — nạp save là quái sống lại hết, như nghỉ bia đá.
	quai_da_ha.clear()
