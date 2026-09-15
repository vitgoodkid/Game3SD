extends Node

## Túi đồ, trang bị, chỉ số, lưu/nạp. Autoload: gọi bằng "Tui".
## Giữ tên của bản 2D để người quen code cũ đọc được ngay.

signal doi_trang_bi
signal doi_chi_so
signal doi_hon(hon: int)
signal nhat_duoc(mon: MonDo)

const DUONG_SAVE := "user://save_game3sd.json"

## Sáu chỉ số cũng là sáu chữ (mục 4.5). Thứ tự trong mảng là thứ tự hiện ở
## bảng chỉ số. Khai ở đây chứ không rải trong code, để đổi là đổi một chỗ.
const CHI_SO := ["体", "韧", "力", "巧", "智", "心"]
const TEN_CHI_SO := {
	"体": "Thể — máu tối đa",
	"韧": "Nhận — thể lực, sức chứa",
	"力": "Lực — vũ khí nặng",
	"巧": "Xảo — vũ khí nhẹ, tốc độ",
	"智": "Trí — sức mạnh phép",
	"心": "Tâm — MP, kháng trạng thái",
}

## Chữ cho sẵn từ giây đầu: sáu chỉ số + năm thiên can. Không cho sẵn thì màn
## hình chỉ số toàn ??? ngay lúc mới vào — không phải bí ẩn, chỉ là khó chịu.
const CHU_BAN_DAU := ["体", "韧", "力", "巧", "智", "心",
	"甲", "乙", "丙", "丁", "戊"]

## Số khe (mục 6.2). Bảy ô chữ mang theo giữ đúng bản 2D.
const SO_KHE := {
	"vu_khi": 3, "tay_trai": 3, "giap": 4, "nhan": 4, "chu_mang": 7,
}
const BO_PHAN_GIAP := ["dau", "than", "tay", "chan"]

const MAU_MOI_THE := 9.0
const MAU_GOC := 300.0
const MP_MOI_TAM := 6.0
const MP_GOC := 60.0

# --- Trạng thái -----------------------------------------------------

var chi_so := {"体": 10, "韧": 10, "力": 10, "巧": 10, "智": 8, "心": 8}
## Hồn — tiền tệ. Chính là chữ 魂. Chết là rơi hết chỗ chưa tiêu (mục 4.5).
var hon := 0
## Bộ thủ nhặt được, chưa ghép thành chữ: {"木": 3, "口": 1, ...}
var bo_thu := {}
## Mọi món đang có trong túi.
var kho: Array[MonDo] = []
## Đang mặc: khe -> mảng MonDo (null ở ô trống).
var mac := {}
## Ô vũ khí tay phải đang cầm (0-2). Đổi trong trận được.
var tay_phai_dang := 0
var tay_trai_dang := 0
## Bình thuốc: chung quota kiểu Elden Ring.
var binh_toi_da := 4
var binh_con := 4

var mau := 300.0
var mp := 60.0

func _ready() -> void:
	_dung_khe()
	TriNho.khoi_dau(CHU_BAN_DAU)
	hoi_day()

func _dung_khe() -> void:
	for khe in SO_KHE.keys():
		var a: Array = []
		a.resize(int(SO_KHE[khe]))
		mac[khe] = a

# --- Chỉ số ---------------------------------------------------------

func cs(chu: String) -> int:
	return int(chi_so.get(chu, 0))

func mau_toi_da() -> float:
	return MAU_GOC + MAU_MOI_THE * float(cs("体"))

func mp_toi_da() -> float:
	return MP_GOC + MP_MOI_TAM * float(cs("心"))

func the_luc_toi_da() -> float:
	return SoulsLike.the_luc_toi_da(cs("韧"))

func hoi_day() -> void:
	mau = mau_toi_da()
	mp = mp_toi_da()
	binh_con = binh_toi_da

## Giá tiêu hồn để tăng một chỉ số thêm một điểm. Tăng dần theo TỔNG mọi chỉ
## số, không theo riêng chỉ số đó — đúng kiểu souls: dồn hết vào một chỉ số
## vẫn đắt như rải đều, nên build nào cũng trả cùng một giá.
func gia_nang_chi_so() -> int:
	var tong := 0
	for c in CHI_SO:
		tong += cs(c)
	return int(round(pow(float(tong), 1.62)) + 120)

func nang_chi_so(chu: String) -> bool:
	if not chi_so.has(chu):
		return false
	var gia := gia_nang_chi_so()
	if hon < gia:
		return false
	hon -= gia
	chi_so[chu] = cs(chu) + 1
	doi_chi_so.emit()
	doi_hon.emit(hon)
	return true

# --- Hồn ------------------------------------------------------------

func them_hon(n: int) -> void:
	if n == 0:
		return
	hon = maxi(0, hon + n)
	doi_hon.emit(hon)

# --- Bộ thủ và ghép chữ ---------------------------------------------

func them_bo_thu(chu: String, so_luong: int = 1) -> void:
	bo_thu[chu] = int(bo_thu.get(chu, 0)) + so_luong

func so_bo_thu(chu: String) -> int:
	return int(bo_thu.get(chu, 0))

func bot_bo_thu(chu: String, so_luong: int) -> bool:
	if so_bo_thu(chu) < so_luong:
		return false
	bo_thu[chu] = so_bo_thu(chu) - so_luong
	if int(bo_thu[chu]) <= 0:
		bo_thu.erase(chu)
	return true

## Ghép bộ thủ thành chữ ở bia đá. Ghép xong = BIẾT chữ (mục 4.6) → chữ đó
## lộ ra ở MỌI món đồ từ đó về sau, kể cả món đã nằm trong túi từ lâu.
##
## Cần đủ mọi bộ thủ khai ở cột `bo_thu` của tu_vung.csv. Chữ không khai bộ
## thủ nào (chữ độc thể như 木 人 口) thì cần đúng một mảnh của chính nó.
func ghep_duoc(chu: String) -> bool:
	return thieu_bo_thu(chu).is_empty()

## Những bộ thủ cần để ghép một chữ. Chữ độc thể (木 人 口) không khai bộ thủ
## nào thì cần đúng một mảnh của chính nó.
##
## Mảng này CÓ THỂ TRÙNG: 林 cần 木|木, tức hai mảnh 木 chứ không phải một.
func bo_thu_can(chu: String) -> Array:
	var bt: Array = VocabDB.tu_cua(chu).get("bo_thu", [])
	return bt if not bt.is_empty() else [chu]

## Còn thiếu bộ thủ nào để ghép chữ này: {"木": 1}. Rỗng = ghép được ngay.
##
## Phải đếm chứ không được chỉ hỏi "có không": 林 cần HAI mảnh 木. Hỏi có-không
## thì cầm một mảnh cũng ghép ra rừng, mà bậc chồng bộ (mục 4.3) chết ngay tại
## đó — 木 và 林 thành cùng một giá.
func thieu_bo_thu(chu: String) -> Dictionary:
	var can := {}
	for bt in bo_thu_can(chu):
		var k := String(bt)
		can[k] = int(can.get(k, 0)) + 1
	var thieu := {}
	for k in can:
		var con := int(can[k]) - so_bo_thu(String(k))
		if con > 0:
			thieu[k] = con
	return thieu

func ghep(chu: String) -> bool:
	if TriNho.doc_duoc(chu):
		return false
	if not ghep_duoc(chu):
		return false
	for bt in bo_thu_can(chu):
		bot_bo_thu(String(bt), 1)
	TriNho.hoc(chu)
	doi_trang_bi.emit()  # mọi món đồ vừa đổi cách hiện
	return true

## Những chữ hiện tại ghép được — bia đá liệt kê bằng hàm này.
func chu_ghep_duoc() -> Array:
	var ds: Array = []
	for tu in VocabDB.tu_vung:
		var chu := String(tu["chu"])
		if not TriNho.doc_duoc(chu) and ghep_duoc(chu):
			ds.append(chu)
	return ds

# --- Khắc chữ ở bia đá (mục 4.6) ------------------------------------
#
# Bốn việc, và chỉ có ở bia đá. Mọi hàm ở đây tự trừ giá và tự báo đổi trang
# bị — giao diện chỉ gọi rồi vẽ lại, không tự tính tiền. Đặt ở đây chứ không
# ở màn hình vì hồn và bộ thủ nằm ở đây; tách ra là chỗ để quên trừ.
#
# Luật chung: KHÔNG khắc được chữ mình chưa đọc được. Khắc chữ là viết, mà
# không ai viết được cái chữ mình chưa thấy mặt bao giờ.

## Khắc thêm một chữ bổ nghĩa vào món đồ. Tốn hồn.
func khac_them(mon: MonDo, chu: String) -> bool:
	if mon == null or not TriNho.doc_duoc(chu):
		return false
	if mon.ten.has(chu):
		return false
	var moi := TenDoVat.khac_them(mon.ten, chu)
	if not bool(TenDoVat.kiem_ten(moi)["duoc"]):
		return false
	var gia := TenDoVat.gia_khac(mon.ten, chu)
	if hon < gia:
		return false
	hon -= gia
	mon.ten = moi
	# Khắc một chữ lên vũ khí TÍNH LÀ ÔN chữ đó, không chỉ lùi ngày phai. Từ
	# khi bỏ thẻ ngồi thiền, hai thẻ chế đồ là đường duy nhất để chữ đã phai
	# quay lại mức Thuộc — chữ được ôn bằng việc dùng nó. Không farm rẻ được:
	# mỗi lần khắc đều trừ hồn, và giá tăng theo độ dài tên.
	TriNho.on_tap(chu, true)
	doi_hon.emit(hon)
	doi_trang_bi.emit()
	return true

## Gỡ một chữ bổ nghĩa ra. Không tốn gì, cũng không trả lại gì — cái mất đi là
## công khắc, và người chơi cần được thử sai thoải mái ở chỗ này.
func go_chu(mon: MonDo, vi_tri: int) -> bool:
	if mon == null:
		return false
	var moi := TenDoVat.go_chu(mon.ten, vi_tri)
	if moi.size() == mon.ten.size():
		return false
	mon.ten = moi
	doi_trang_bi.emit()
	return true

## Đổi chỗ hai chữ bổ nghĩa. MIỄN PHÍ, cố ý: đây chính là bài học của mục 4.2,
## mà bài học thì không được bắt trả tiền để thử.
func doi_cho_chu(mon: MonDo, a: int, b: int) -> bool:
	if mon == null:
		return false
	var moi := TenDoVat.doi_cho(mon.ten, a, b)
	if moi == mon.ten:
		return false
	mon.ten = moi
	doi_trang_bi.emit()
	return true

## Nâng một chữ trong tên lên bậc chồng bộ trên (木 → 林). Tốn bộ thủ của CHỮ
## GỐC thang đó, và phải đọc được chữ mới.
func nang_bac_chu(mon: MonDo, vi_tri: int) -> bool:
	if mon == null or vi_tri < 0 or vi_tri >= mon.ten.size():
		return false
	var chu := String(mon.ten[vi_tri])
	var tren := TenDoVat.bac_tren(chu)
	if tren == "" or not TriNho.doc_duoc(tren):
		return false
	var goc := VocabDB.goc_thang_cua(chu)
	var gia := TenDoVat.gia_nang_bac(chu)
	if so_bo_thu(goc) < gia:
		return false
	bot_bo_thu(goc, gia)
	mon.ten = TenDoVat.nang_bac(mon.ten, vi_tri)
	# Nâng bậc chồng bộ cũng là ôn — và cũng có giá (tốn bộ thủ), xem khac_them.
	TriNho.on_tap(tren, true)
	doi_trang_bi.emit()
	return true

# --- Kho và trang bị ------------------------------------------------

func nhat(mon: MonDo) -> void:
	kho.append(mon)
	# Gặp lại chữ một cách thụ động — đẩy lùi ngày phai (mục 4.7).
	for c in mon.ten:
		TriNho.gap_lai(String(c))
	nhat_duoc.emit(mon)

func bo(mon: MonDo) -> void:
	thao_het(mon)
	kho.erase(mon)
	doi_trang_bi.emit()

func dang_mac(mon: MonDo) -> bool:
	for khe in mac.keys():
		if mac[khe].has(mon):
			return true
	return false

## Mặc một món vào khe. `o` = -1 nghĩa là tìm ô trống đầu tiên.
## Trả về false nếu món không hợp khe đó.
func mac_vao(mon: MonDo, khe: String, o: int = -1) -> bool:
	if not mac.has(khe):
		return false
	if not _hop_khe(mon, khe, o):
		return false
	thao_het(mon)
	var i := o
	if i < 0:
		i = mac[khe].find(null)
		if i < 0:
			i = 0
	mac[khe][i] = mon
	mon.da_mac_thu = true
	for c in mon.ten:
		TriNho.gap_lai(String(c))
	doi_trang_bi.emit()
	return true

func _hop_khe(mon: MonDo, khe: String, o: int) -> bool:
	var loai := mon.loai()
	match khe:
		"vu_khi":
			return loai == "vukhi"
		"tay_trai":
			# Tay trái là khe KHIÊN, không phải khe vũ khí thứ hai. Elden Ring
			# tách hẳn hai thứ: khiên có chỉ số chặn đỡ riêng, và parry chỉ
			# làm được khi tay trái có khiên.
			return loai == "khien"
		"giap":
			# Bốn ô giáp cố định theo bộ phận: đầu / thân / tay / chân.
			if loai != "giap":
				return false
			if o < 0:
				return true
			return mon.bo_phan() == BO_PHAN_GIAP[o] or mon.bo_phan() == "quan"
		"nhan":
			return loai == "nhan" or loai == ""
		_:
			return true

func thao_het(mon: MonDo) -> void:
	for khe in mac.keys():
		var a: Array = mac[khe]
		for i in a.size():
			if a[i] == mon:
				a[i] = null

func thao(khe: String, o: int) -> void:
	if mac.has(khe) and o >= 0 and o < mac[khe].size():
		mac[khe][o] = null
		doi_trang_bi.emit()

func vu_khi_dang_cam() -> MonDo:
	return mac["vu_khi"][tay_phai_dang]

func tay_trai_dang_cam() -> MonDo:
	return mac["tay_trai"][tay_trai_dang]

## Đổi sang vũ khí tiếp theo có trong khe. Bỏ qua ô trống — bấm đổi mà đổi
## sang tay không giữa trận đánh là chuyện không ai muốn.
func doi_vu_khi() -> void:
	var a: Array = mac["vu_khi"]
	for b in range(1, a.size() + 1):
		var i := (tay_phai_dang + b) % a.size()
		if a[i] != null:
			tay_phai_dang = i
			doi_trang_bi.emit()
			return

## Chữ trung tâm của vũ khí đang cầm — quyết định moveset. Không cầm gì thì
## đánh tay không (拳).
func moveset_dang_dung() -> String:
	var vk := vu_khi_dang_cam()
	return "拳" if vk == null else vk.trung_tam()

# --- Tải trọng (mục 6.1) --------------------------------------------

func tong_nang() -> float:
	var t := 0.0
	for khe in mac.keys():
		if khe == "chu_mang":
			continue
		for m in mac[khe]:
			if m != null:
				t += m.nang()
	return t

func ti_le_tai() -> float:
	return tong_nang() / maxf(SoulsLike.suc_chua(cs("韧")), 1.0)

func muc_tai() -> Dictionary:
	return SoulsLike.muc_tai(ti_le_tai())

# --- Ngũ hành của bộ đồ đang mặc ------------------------------------

func hanh_dang_mac() -> Array:
	var ds: Array = []
	for khe in mac.keys():
		if khe == "chu_mang":
			continue
		for m in mac[khe]:
			if m != null:
				var h := String(m.ngu_hanh())
				if h != "":
					ds.append(h)
	return ds

func he_so_cong_huong() -> float:
	return NguHanh.cong_huong(hanh_dang_mac())

# --- Sát thương thực của đòn đang vung ------------------------------

## Sát thương cuối cùng của một đòn: sát thương vũ khí × hệ số đòn, cộng phần
## theo chỉ số (thiên can), rồi nhân cộng hưởng ngũ hành của bộ đồ.
##
## Phần ngũ hành ĐỐI KHÁNG (khắc / bị khắc / sinh) KHÔNG tính ở đây — nó phụ
## thuộc con quái đang đánh, nên do bên gọi nhân vào sau. Tách ra để hàm này
## còn dùng được ở bảng chỉ số "món này đánh mấy" lúc chưa có quái nào.
func sat_thuong_don(don: String) -> float:
	var vk := vu_khi_dang_cam()
	var chu_mv := moveset_dang_dung()
	var m := VocabDB.don_cua(chu_mv, don)
	if m.is_empty():
		return 0.0
	var goc := 12.0 if vk == null else vk.sat_thuong()
	var st := goc * float(m.get("he_so", 1.0))
	var can := String(m.get("he_so_bac", "丙"))
	var chinh := String(m.get("chi_so_chinh", "力"))
	st += SoulsLike.cong_tu_chi_so(cs(chinh), can, goc)
	return st * he_so_cong_huong()

# --- Lưu / nạp ------------------------------------------------------

func thanh_du_lieu() -> Dictionary:
	var kho_d: Array = []
	for m in kho:
		kho_d.append(m.thanh_du_lieu())
	# Đồ đang mặc lưu bằng CHỈ SỐ trong kho, không lưu lại cả món — nếu lưu
	# cả món thì nạp lên sẽ ra hai bản sao khác nhau của cùng một cái kiếm.
	var mac_d := {}
	for khe in mac.keys():
		var a: Array = []
		for m in mac[khe]:
			a.append(-1 if m == null else kho.find(m))
		mac_d[khe] = a
	return {
		"chi_so": chi_so.duplicate(), "hon": hon, "bo_thu": bo_thu.duplicate(),
		"kho": kho_d, "mac": mac_d, "tay_phai_dang": tay_phai_dang,
		"tay_trai_dang": tay_trai_dang, "binh_toi_da": binh_toi_da,
		"tri_nho": TriNho.thanh_du_lieu(),
	}

func tu_du_lieu(d: Dictionary) -> void:
	chi_so = d.get("chi_so", chi_so).duplicate()
	hon = int(d.get("hon", 0))
	bo_thu = d.get("bo_thu", {}).duplicate()
	kho.clear()
	for md in d.get("kho", []):
		kho.append(MonDo.tu_du_lieu(md))
	_dung_khe()
	var mac_d: Dictionary = d.get("mac", {})
	for khe in mac.keys():
		var a: Array = mac_d.get(khe, [])
		for i in mini(a.size(), mac[khe].size()):
			var idx := int(a[i])
			mac[khe][i] = kho[idx] if idx >= 0 and idx < kho.size() else null
	tay_phai_dang = int(d.get("tay_phai_dang", 0))
	tay_trai_dang = int(d.get("tay_trai_dang", 0))
	binh_toi_da = int(d.get("binh_toi_da", 4))
	TriNho.tu_du_lieu(d.get("tri_nho", {}))
	hoi_day()
	doi_trang_bi.emit()
	doi_chi_so.emit()

func luu() -> void:
	var d := {"tui": thanh_du_lieu(), "the_gioi": TheGioi.thanh_du_lieu()}
	var f := FileAccess.open(DUONG_SAVE, FileAccess.WRITE)
	if f == null:
		push_error("Khong ghi duoc save: %d" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(d, "  "))
	f.close()

func nap() -> bool:
	if not FileAccess.file_exists(DUONG_SAVE):
		return false
	var f := FileAccess.open(DUONG_SAVE, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if not (d is Dictionary):
		push_error("Save hong, bo qua.")
		return false
	tu_du_lieu(d.get("tui", {}))
	TheGioi.tu_du_lieu(d.get("the_gioi", {}))
	return true
