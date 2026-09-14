class_name MonDo
extends RefCounted

## Một món đồ. Cốt lõi chỉ là MỘT MẢNG CHỮ — mọi chỉ số suy ra từ đó.
##
## Vì sao không lưu sẵn chỉ số vào đây: vì chỉ số món đồ phụ thuộc vào việc
## người chơi đọc được chữ nào (mục 4.1) và chữ đó đã phai chưa (mục 4.7),
## cả hai đều đổi theo thời gian. Lưu sẵn là đông cứng, học thêm một chữ mà
## cái kiếm cũ trong túi không sáng ra thì mất luôn khoảnh khắc hay nhất của
## cả thiết kế.
##
## Cái duy nhất được phép lưu sẵn: `hat` — hạt giống ngẫu nhiên, để cùng một
## tên vẫn ra hai món khác nhau chút đỉnh (kiểu Diablo), và để món rơi ra ở
## lần chơi này giống hệt lần nạp save sau.

## Mảng chữ, trái sang phải. Chữ cuối là trung tâm.
var ten: Array = []
## Hạt giống cho phần ngẫu nhiên nhỏ (±8% sát thương gốc).
var hat: int = 0
## Đã xác định được đây là đồ gì chưa — món nhặt ngoài đất thì chưa, mặc thử
## một lần là biết (mục 4.1: "người chơi mù chữ vẫn chơi được, nhưng chơi mò").
var da_mac_thu: bool = false

func _init(ten_moi: Array = [], hat_moi: int = 0) -> void:
	ten = ten_moi.duplicate()
	hat = hat_moi if hat_moi != 0 else randi()

func chuoi() -> String:
	return "".join(ten)

## Tên hiện ra màn hình — chữ chưa đọc được thành □.
func ten_hien() -> String:
	return TenDoVat.ten_hien(ten)

func trung_tam() -> String:
	return TenDoVat.trung_tam(ten)

## vukhi / giap / tieu_hao — tra từ chữ trung tâm.
func loai() -> String:
	return VocabDB.loai_nguyen_lieu_cua(trung_tam())

## dau / than / tay / chan / quan / vu_khi — bộ phận mặc được.
func bo_phan() -> String:
	return String(VocabDB.nguyen_lieu_cua(trung_tam()).get("bo_phan", ""))

func phan_tich() -> Dictionary:
	return TenDoVat.phan_tich(ten)

## Lệch ngẫu nhiên cố định theo hạt giống: ±8%. Cùng một món luôn ra cùng
## một số, kể cả sau khi nạp save.
func lech() -> float:
	var r := RandomNumberGenerator.new()
	r.seed = hat
	return 1.0 + (r.randf() - 0.5) * 0.16

## Sát thương thực, đã tính độ thuần thục và lệch ngẫu nhiên.
func sat_thuong() -> float:
	return TenDoVat.sat_thuong_thuc(phan_tich()) * lech()

func nang() -> float:
	return float(phan_tich()["nang"])

func ngu_hanh() -> String:
	return String(phan_tich()["ngu_hanh"])

func do_hiem() -> String:
	return DoHiem.hiem_mon(ten)

func mau() -> Color:
	return DoHiem.mau_mon(ten)

## Đọc được hết tên chưa.
func doc_het() -> bool:
	for c in ten:
		if not TriNho.doc_duoc(String(c)):
			return false
	return true

# --- Lưu / nạp ------------------------------------------------------

func thanh_du_lieu() -> Dictionary:
	return {"ten": ten.duplicate(), "hat": hat, "da_mac_thu": da_mac_thu}

static func tu_du_lieu(d: Dictionary) -> MonDo:
	var m := MonDo.new(d.get("ten", []), int(d.get("hat", 0)))
	m.da_mac_thu = bool(d.get("da_mac_thu", false))
	return m
