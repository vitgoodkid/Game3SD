class_name ManThoai
extends ManChung

## Màn thoại NPC (mốc 7). Chỗ cốt truyện được kể — hay đúng hơn, chỗ nó được
## GIẢI MÃ.
##
## Mỗi câu hiện ba tầng, và thứ tự ba tầng ấy là cả thiết kế:
##
##   1. câu tiếng Trung, chữ chưa đọc được hiện □
##   2. thanh "đọc được bao nhiêu phần"
##   3. bản dịch — CHỈ khi đã đọc được ≥ NGUONG_HIEU
##
## Không cho xem bản dịch ngay là cố ý. Cho xem thì chữ Hán thành trang trí, và
## game mất đúng thứ làm nó khác mọi game khác. Mục 13 của bản yêu cầu nói
## thẳng: "phần thưởng của việc học là hiểu được cốt truyện — không cần cơ chế
## gì thêm". Đây là chỗ thi hành câu đó.
##
## Người chơi vẫn đi tiếp được khi chưa hiểu gì. Câu chuyện không chặn đường —
## nó chỉ sáng dần lên, và người chơi quay lại đọc lại khi đã biết thêm chữ.

var _npc: Npc = null
var _cau := 0
var _noi_dung: VBoxContainer = null

func dung_noi_dung(cha: MarginContainer) -> void:
	add_to_group("man_thoai")
	_noi_dung = VBoxContainer.new()
	_noi_dung.add_theme_constant_override("separation", 10)
	cha.add_child(_noi_dung)

func mo_voi(n: Npc) -> void:
	_npc = n
	_cau = 0
	mo()

func lam_moi() -> void:
	if _npc == null:
		return
	dat_tieu_de(_npc.ten_hien())
	ve_xong = false
	don(_noi_dung)

	var tong := _npc.so_cau()
	if tong == 0:
		_noi_dung.add_child(chu("…", 24, MAU_CHU_MO))
		ve_xong = true
		return

	# Câu tiếng Trung, to, là thứ chính. Không phải bản dịch.
	_noi_dung.add_child(chu(_npc.cau_hien(_cau), 34))

	var ti := _npc.ti_le_doc(_cau)
	_noi_dung.add_child(chu("đọc được %d%%" % int(round(ti * 100.0)), 15,
		MAU_CHU_MO if ti < Npc.NGUONG_HIEU else Color(0.62, 0.85, 0.60)))
	_noi_dung.add_child(HSeparator.new())

	if _npc.hieu_duoc(_cau):
		_noi_dung.add_child(chu(_npc.cau_nghia(_cau), 19, MAU_NHAN))
	else:
		# Không nói "bạn chưa đủ trình". Nói cho biết THIẾU GÌ — người chơi
		# phải ra về với một việc cụ thể để làm, không phải với một lời từ chối.
		var chua: Array[String] = []
		for c in _npc.cau_chu(_cau):
			if Npc._la_chu_han(c) and not TriNho.doc_duoc(c) and not chua.has(c):
				chua.append(c)
		_noi_dung.add_child(chu("Chưa hiểu. Thiếu: " + " ".join(chua), 17, MAU_CHU_MO))
		_noi_dung.add_child(chu(
			"Ghép mấy chữ này ở bia đá rồi quay lại nghe.", 15, MAU_CHU_MO))

	_noi_dung.add_child(HSeparator.new())
	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 8)
	_noi_dung.add_child(hang)
	if _cau > 0:
		hang.add_child(nut("← Câu trước", _lui))
	if _cau < tong - 1:
		hang.add_child(nut("Câu tiếp →", _tiep))
	else:
		hang.add_child(nut("Xong", _xong))
	hang.add_child(chu("  %d/%d" % [_cau + 1, tong], 15, MAU_CHU_MO))
	ve_xong = true

func _lui() -> void:
	_cau = maxi(0, _cau - 1)
	lam_moi()

func _tiep() -> void:
	_cau = mini(_npc.so_cau() - 1, _cau + 1)
	lam_moi()

## Nghe hết chuyện thì NPC tặng chữ. Tặng CẢ KHI chưa hiểu câu nào — nghe hết
## là đã chịu đứng lại nghe, và mấy chữ được tặng chính là chìa để lần sau
## quay lại hiểu được.
func _xong() -> void:
	var moi := _npc.nhan_thuong()
	if not moi.is_empty():
		_bao("Học được " + " ".join(moi))
	dong()

func _bao(dong_chu: String) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("bao"):
		h.call("bao", dong_chu)
