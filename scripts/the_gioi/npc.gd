class_name Npc
extends TuongTacDuoc

## NPC và cốt truyện (mốc 7). Mọi thông số đọc từ data/npc.csv.
##
## Đây là chỗ mục 13 của bản yêu cầu nói tới: **phần thưởng của việc học là
## HIỂU ĐƯỢC CỐT TRUYỆN** — không cần cơ chế gì thêm.
##
## Thoại hiện bằng tiếng Trung theo đúng luật ???: chữ chưa đọc được hiện □.
## Bản dịch tiếng Việt chỉ lộ ra khi đã đọc được đủ phần trăm câu đó. Nghĩa là
## người chơi không "được kể" câu chuyện — họ GIẢI MÃ nó, và mỗi chữ học thêm
## là một câu sáng ra.
##
## Vì sao không cho xem bản dịch ngay: cho xem thì chữ Hán thành trang trí, và
## cả trò chơi mất đúng thứ làm nó khác mọi game khác. Phép thử của CLAUDE.md
## ("thay chữ bằng icon vô nghĩa — game có hỏng không") phải hỏng ở đây nữa.

## Đọc được bao nhiêu phần của câu thì mới lộ bản dịch.
const NGUONG_HIEU := 0.6

@export var ma := ""

var d := {}
var _cau := 0

static func tao(ma_npc: String, tai: Vector3) -> Npc:
	var n := Npc.new()
	n.ma = ma_npc
	n.position = tai
	return n

func dung_hinh() -> void:
	add_to_group("npc")
	d = VocabDB.npc_cua(ma)
	cao_nhan = 2.1
	tam_voi = 3.0

	# Thân NPC: cột hẹp, sáng nhẹ. Cố ý KHÁC hình quái — người chơi phải phân
	# biệt được "cái này đánh được" với "cái này nói chuyện được" từ xa, trước
	# khi kịp đọc tên trên đầu.
	khoi(Vector3(0.5, 1.7, 0.5), Color(0.72, 0.68, 0.52), Vector3(0, 0.85, 0), 0.35)
	khoi(Vector3(0.62, 0.16, 0.62), Color(0.55, 0.50, 0.38), Vector3(0, 1.78, 0))

	var nhan := Label3D.new()
	nhan.text = ten_hien()
	nhan.font_size = 40
	nhan.pixel_size = 0.0024
	nhan.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nhan.outline_size = 12
	nhan.modulate = Color(0.92, 0.88, 0.70)
	nhan.position = Vector3(0, 2.35, 0)
	add_child(nhan)
	Tui.doi_trang_bi.connect(func() -> void: nhan.text = ten_hien())

## Tên NPC theo luật ???. Kẻ không tên ở vùng cuối hiện đúng một ô trống — và
## đó là cả nhân vật ấy.
func ten_hien() -> String:
	var tc := String(d.get("ten_chu", ""))
	if tc == "":
		return String(d.get("ten", "?"))
	var s := ""
	for c in tc:
		s += c if TriNho.doc_duoc(c) else TenDoVat.CHU_MO
	return s

func dong_moi() -> String:
	return "E — nói chuyện"

func tuong_tac() -> void:
	_cau = 0
	var man := get_tree().get_first_node_in_group("man_thoai")
	if man != null and man.has_method("mo_voi"):
		man.call("mo_voi", self)

# --- Thoại -----------------------------------------------------------

func so_cau() -> int:
	var t: Array = d.get("thoai", [])
	return t.size()

func cau_chu(i: int) -> String:
	var t: Array = d.get("thoai", [])
	return "" if i < 0 or i >= t.size() else String(t[i])

func cau_nghia(i: int) -> String:
	var t: Array = d.get("thoai_nghia", [])
	return "" if i < 0 or i >= t.size() else String(t[i])

## Câu hiện ra: chữ chưa đọc được thay bằng □. Dấu câu giữ nguyên — nó không
## phải chữ phải học, mà bỏ đi thì câu mất nhịp.
func cau_hien(i: int) -> String:
	var s := ""
	for c in cau_chu(i):
		s += c if (not _la_chu_han(c) or TriNho.doc_duoc(c)) else TenDoVat.CHU_MO
	return s

## Đọc được bao nhiêu phần của câu này.
func ti_le_doc(i: int) -> float:
	var tong := 0
	var biet := 0
	for c in cau_chu(i):
		if not _la_chu_han(c):
			continue
		tong += 1
		if TriNho.doc_duoc(c):
			biet += 1
	return 1.0 if tong == 0 else float(biet) / float(tong)

## Hiểu được câu này chưa — đủ ngưỡng thì mới lộ bản dịch.
func hieu_duoc(i: int) -> bool:
	return ti_le_doc(i) >= NGUONG_HIEU

static func _la_chu_han(c: String) -> bool:
	var m := c.unicode_at(0)
	return m >= 0x4E00 and m <= 0x9FFF

## Nói hết chuyện thì NPC tặng chữ và hồn — MỘT LẦN. Ghi vào TheGioi để đọc
## lại lần hai không ăn thêm.
func nhan_thuong() -> Array[String]:
	var moi: Array[String] = []
	if TheGioi.da_ha("npc:" + ma):
		return moi
	TheGioi.danh_dau_ha("npc:" + ma)
	for c in d.get("chu_tang", []):
		var s := String(c)
		if s != "" and not TriNho.doc_duoc(s):
			TriNho.hoc(s)
			moi.append(s)
	var hon := int(d.get("hon_tang", 0))
	if hon > 0:
		Tui.them_hon(hon)
	if not moi.is_empty():
		Tui.doi_trang_bi.emit()
	return moi
