extends Node

## Trí nhớ — chữ nào thuộc, chữ nào sắp quên. Autoload: gọi bằng "TriNho".
##
## Đây là chỗ khớp cơ chế với cốt truyện "chữ bị xoá khỏi thế giới" (mục 4.7).
## Chữ lâu không gặp thì phai; món đồ mang chữ đó mờ đi theo.
##
## MỘT LUẬT KHÔNG ĐƯỢC PHÉP VI PHẠM — phai chỉ ăn vào PHẦN CỘNG THÊM của chữ,
## không bao giờ ăn vào chỉ số gốc của vũ khí. Người chơi không bao giờ bị yếu
## đi tới mức không qua nổi chỗ đã qua. Chỗ thi hành luật này nằm ở
## TenDoVat.sat_thuong_thuc() — st_goc cộng thẳng, không nhân hieu_luc().
##
## Dữ liệu ở đây nằm trong FILE SAVE, không nằm trong CSV. CSV là nội dung
## game, cái này là tiến trình của một người chơi.

signal da_hoc_chu(chu: String)
signal chu_phai(chu: String)

## Bốn mức. Số tăng dần theo độ thuộc, nên so sánh `>=` được.
const MUC_LA := 0      ## chưa ghép bao giờ — không biết chữ này tồn tại
const MUC_PHAI := 1    ## đã học nhưng quên rồi — hiện □, chỉ số về ???
const MUC_MO := 2      ## nhớ mang máng — hiện chỉ số nhưng yếu đi
const MUC_THUOC := 3   ## thuộc — đủ chỉ số, hiệu lực 100%

const TEN_MUC := {
	MUC_LA: "Lạ", MUC_PHAI: "Phai", MUC_MO: "Mờ", MUC_THUOC: "Thuộc",
}

## Hiệu lực phần cộng thêm theo từng mức (mục 4.7).
const HIEU_LUC := {
	MUC_LA: 0.0, MUC_PHAI: 0.0, MUC_MO: 0.7, MUC_THUOC: 1.0,
}

## Lịch ôn — khoảng cách tăng dần, rút gọn từ SM-2. Đơn vị: ngày thật.
## Năm mốc là đủ; thêm mốc 70/150 ngày thì không ai chơi tới đó để kiểm.
const LICH_ON := [1, 3, 7, 16, 35]

## Quá hạn ôn bao nhiêu LẦN khoảng cách thì tụt một mức.
## 1.0 = vừa quá hạn đã tụt thì quá ác; 2.0 cho người chơi khoảng thở.
const HE_SO_QUA_HAN := 2.0

## Mỗi chữ: {lan: chỉ số trong LICH_ON, lan_cuoi: unix giây, dung: int, sai: int,
##           muc: một trong bốn hằng trên}
var so := {}

## Cho phép tắt cơ chế phai (mục cài đặt). Người muốn chơi souls thuần thì
## bật tắt được — cưỡng ép học là cách nhanh nhất để người ta bỏ game.
var bat_phai := true

# --- Tra cứu --------------------------------------------------------

func muc_thuan_thuc(chu: String) -> int:
	if not so.has(chu):
		return MUC_LA
	_cap_nhat_phai(chu)
	return int(so[chu]["muc"])

## Có đọc được chữ này không — dùng ở mọi chỗ hiển thị. Phai và Lạ đều KHÔNG
## đọc được; khác nhau ở chỗ Phai ôn một lượt là về, Lạ thì phải ghép lại.
func doc_duoc(chu: String) -> bool:
	return muc_thuan_thuc(chu) >= MUC_MO

## Đã từng học chữ này chưa (kể cả đã phai).
func da_tung_hoc(chu: String) -> bool:
	return so.has(chu)

## Hệ số nhân vào phần cộng thêm của chữ.
func hieu_luc(chu: String) -> float:
	return float(HIEU_LUC[muc_thuan_thuc(chu)])

func ten_muc(chu: String) -> String:
	return String(TEN_MUC[muc_thuan_thuc(chu)])

func so_chu_da_hoc() -> int:
	return so.size()

func so_chu_thuoc() -> int:
	var n := 0
	for chu in so.keys():
		if muc_thuan_thuc(chu) == MUC_THUOC:
			n += 1
	return n

# --- Học và ôn ------------------------------------------------------

## Ghép xong bộ thủ ở bia đá = BIẾT chữ. Từ đây chữ đó lộ ra ở mọi món đồ,
## kể cả những món đã bỏ xó trong túi từ mười giờ chơi trước (mục 4.1).
func hoc(chu: String) -> void:
	if so.has(chu):
		# Học lại chữ đã phai: về thẳng Thuộc, nhưng lịch ôn lùi một bậc để
		# chữ từng quên được hỏi lại sớm hơn chữ chưa quên bao giờ.
		so[chu]["muc"] = MUC_THUOC
		so[chu]["lan"] = maxi(0, int(so[chu]["lan"]) - 1)
		so[chu]["lan_cuoi"] = _bay_gio()
		return
	so[chu] = {"lan": 0, "lan_cuoi": _bay_gio(), "dung": 0, "sai": 0, "muc": MUC_THUOC}
	da_hoc_chu.emit(chu)

## Ôn một chữ. Đúng thì đẩy lịch ôn ra xa, sai thì kéo về gần — SM-2 rút gọn.
##
## Ai gọi: hai thẻ chế đồ ở bia đá (khắc chữ, nâng bậc chồng bộ) — dùng được
## chữ nghĩa là thuộc chữ. Thẻ hỏi-đáp đã bỏ, nên đây là đường DUY NHẤT để một
## chữ đã phai quay lại mức Thuộc; gỡ mấy lời gọi đó đi là cơ chế phai thành
## một chiều. Tham số `dung` giữ lại vì `cau_hoi.gd` vẫn còn trong repo.
func on_tap(chu: String, dung: bool) -> void:
	if not so.has(chu):
		hoc(chu)
	var m: Dictionary = so[chu]
	m["lan_cuoi"] = _bay_gio()
	if dung:
		m["dung"] = int(m["dung"]) + 1
		m["lan"] = mini(int(m["lan"]) + 1, LICH_ON.size() - 1)
		m["muc"] = MUC_THUOC
	else:
		m["sai"] = int(m["sai"]) + 1
		m["lan"] = maxi(0, int(m["lan"]) - 1)
		# Sai thì KHÔNG tụt xuống Phai ngay. Trả lời sai một câu mà mất sạch
		# phần cộng thêm của cả bộ đồ là hình phạt lệch hẳn với lỗi lầm.
		m["muc"] = maxi(MUC_MO, int(m["muc"]) - 1)

## Gặp lại chữ một cách thụ động — nhặt được món mang chữ đó, đọc tên quái
## trên đầu nó. Đẩy lùi ngày phai mà không tính là ôn tập thật.
##
## Vì sao chỉ đẩy nửa vời: nếu đi ngang qua con quái cũng được tính như ôn
## tập, thì cơ chế phai không bao giờ kích hoạt và mục 4.7 thành trang trí.
func gap_lai(chu: String) -> void:
	if not so.has(chu):
		return
	var m: Dictionary = so[chu]
	var da := _bay_gio() - int(m["lan_cuoi"])
	m["lan_cuoi"] = int(m["lan_cuoi"]) + int(da / 2)

# --- Phai -----------------------------------------------------------

## Số ngày kể từ lần gặp cuối.
func ngay_tu_lan_cuoi(chu: String) -> float:
	if not so.has(chu):
		return 0.0
	return float(_bay_gio() - int(so[chu]["lan_cuoi"])) / 86400.0

## Còn bao nhiêu ngày nữa thì tới hạn ôn. Số âm = đã quá hạn.
func con_may_ngay(chu: String) -> float:
	if not so.has(chu):
		return 0.0
	var han := float(LICH_ON[int(so[chu]["lan"])])
	return han - ngay_tu_lan_cuoi(chu)

func _cap_nhat_phai(chu: String) -> void:
	if not bat_phai:
		return
	var m: Dictionary = so[chu]
	var han := float(LICH_ON[int(m["lan"])])
	var da := ngay_tu_lan_cuoi(chu)
	var muc_cu := int(m["muc"])
	var muc_moi := MUC_THUOC
	if da > han * HE_SO_QUA_HAN:
		muc_moi = MUC_PHAI
	elif da > han:
		muc_moi = MUC_MO
	else:
		muc_moi = mini(muc_cu, MUC_THUOC)
	# Chỉ cho TỤT bằng cơ chế phai, không cho lên. Lên mức là việc của ôn tập.
	if muc_moi < muc_cu:
		m["muc"] = muc_moi
		if muc_moi == MUC_PHAI and muc_cu > MUC_PHAI:
			chu_phai.emit(chu)

## Danh sách chữ sắp phai, sắp xếp cái gần hạn nhất lên đầu. Bia đá hiện
## "12 chữ sắp phai" bằng hàm này.
func sap_phai(gioi_han: int = 20) -> Array:
	var ds: Array = []
	for chu in so.keys():
		var con := con_may_ngay(chu)
		if con <= 1.0:
			ds.append({"chu": chu, "con": con, "muc": muc_thuan_thuc(chu)})
	ds.sort_custom(func(a, b): return float(a["con"]) < float(b["con"]))
	return ds.slice(0, gioi_han)

## Đồ rơi cũng theo lịch ôn (mục 4.7): quái ưu tiên rơi bộ thủ của chữ sắp
## phai. Người chơi được đưa đúng thứ mình cần ôn mà không thấy bị bắt học.
##
## Trả về chữ nên rơi, hoặc "" nếu không có chữ nào đang cần ôn — khi đó bên
## gọi rơi theo bảng thường của con quái.
func chu_nen_roi() -> String:
	var ds := sap_phai(8)
	if ds.is_empty():
		return ""
	return String(ds.pick_random()["chu"])

# --- Lưu / nạp ------------------------------------------------------

func _bay_gio() -> int:
	return int(Time.get_unix_time_from_system())

func thanh_du_lieu() -> Dictionary:
	return {"so": so.duplicate(true), "bat_phai": bat_phai}

func tu_du_lieu(d: Dictionary) -> void:
	so = d.get("so", {}).duplicate(true)
	bat_phai = bool(d.get("bat_phai", true))

## Bắt đầu ván mới: người chơi biết sẵn sáu chữ chỉ số và năm chữ thiên can.
## Không cho sẵn thì màn hình chỉ số toàn ??? ngay từ giây đầu — không phải
## bí ẩn hay ho gì, chỉ là khó chịu.
func khoi_dau(chu_cho_san: Array) -> void:
	so.clear()
	for chu in chu_cho_san:
		hoc(String(chu))
