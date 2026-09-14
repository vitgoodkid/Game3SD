class_name VongHoiSinh
extends Node

## Vòng lặp souls ở mức bản đồ: chết → rơi vũng hồn tại chỗ → đứng dậy ở bia
## đá → tự đi về mà nhặt (mục 4.5).
##
## Tách khỏi phong_thu.gd vì phần này đúng với MỌI bản đồ, còn phong_thu.gd chỉ
## biết chỗ đặt mấy con quái của riêng nó. Thả node này vào scene nào là scene
## đó có vòng lặp souls, không phải chép lại.
##
## Không đụng tới quái: quái sống lại là việc của bản đồ, vì chỉ bản đồ mới
## biết ban đầu nó đặt con nào ở đâu. Bản đồ nghe hai tín hiệu `TheGioi.hoi_sinh`
## và `TheGioi.nghi_bia_da` là đủ.

func _ready() -> void:
	TheGioi.chet.connect(_khi_chet)
	TheGioi.hoi_sinh.connect(_khi_hoi_sinh)

## Chết: dựng vũng hồn ở đúng chỗ ngã xuống. Vũng cũ biến mất — TheGioi đã
## quyết chuyện đó rồi (chỉ giữ một vũng), ở đây chỉ dọn cái node cũ cho khớp.
func _khi_chet() -> void:
	for v in get_tree().get_nodes_in_group("vung_hon"):
		v.queue_free()
	if not TheGioi.co_vung_hon():
		return
	var cha := get_parent()
	if cha == null:
		return
	cha.add_child.call_deferred(
		VungHon.tao(TheGioi.so_hon_trong_vung(), TheGioi.vi_tri_vung_hon()))

func _khi_hoi_sinh() -> void:
	var nc := get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi
	if nc == null:
		return
	nc.song_lai(_cho_dung_day(nc.global_position))
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("bao"):
		h.call("bao", "Chết lần thứ %d" % TheGioi.so_lan_chet)

## Đứng dậy ở bia đá đang gắn. Chưa nghỉ ở bia nào (chết trước khi tới được bia
## đầu tiên) thì lấy bia gần nhất trên bản đồ — thà hồi sinh sai chỗ còn hơn
## hồi sinh ngay tại vũng hồn, vì như thế thì chết chẳng mất gì.
func _cho_dung_day(dang_o: Vector3) -> Vector3:
	var ds := get_tree().get_nodes_in_group("bia_da")
	var chon: BiaDa = null
	for b in ds:
		var bia := b as BiaDa
		if bia == null:
			continue
		if bia.ma == TheGioi.bia_hien_tai:
			chon = bia
			break
		if chon == null or bia.global_position.distance_to(dang_o) \
				< chon.global_position.distance_to(dang_o):
			chon = bia
	return dang_o if chon == null else chon.diem_hoi_sinh()
