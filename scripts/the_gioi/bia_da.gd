class_name BiaDa
extends TuongTacDuoc

## Bia đá — điểm hồi sinh, và là nơi VIỆC HỌC thật sự diễn ra (mục 4.6).
##
## Cái bia làm đúng ba việc: đứng đó cho thấy, ghi nhận "đã bật", và mở màn
## bốn thẻ. Bốn việc học nằm ở `man_bia_da.gd` — tách ra vì cái bia là vật thể
## trong thế giới, còn bốn việc kia là giao diện; trộn vào nhau thì bản đồ nào
## cũng phải kéo theo cả đống Control.
##
## Nghỉ ở bia là hồi đầy máu và bình, và quái sống lại HẾT — kể cả con vừa hạ
## xong. Đó là luật souls, và nó là cái giá của việc được cứu.

@export var ma := "bia_thi_tran"
@export var ten := "Bia đá"

var _dinh: MeshInstance3D = null
var _nhan_ten: Label3D = null

func dung_hinh() -> void:
	add_to_group("bia_da")
	cao_nhan = 2.7

	# Bệ + phiến đá dựng đứng. Cố tình cao hơn đầu người (1.8m) để nhìn từ xa
	# qua đám quái vẫn thấy — bia đá phải là thứ NHÌN THẤY TRƯỚC khi chết.
	khoi(Vector3(1.4, 0.3, 1.4), Color(0.26, 0.25, 0.24), Vector3(0, 0.15, 0))
	khoi(Vector3(0.55, 2.1, 0.30), Color(0.34, 0.33, 0.31), Vector3(0, 1.25, 0))
	_dinh = khoi(Vector3(0.28, 0.28, 0.28), Color(0.95, 0.80, 0.42),
		Vector3(0, 2.45, 0))

	_nhan_ten = Label3D.new()
	_nhan_ten.text = ten
	_nhan_ten.font_size = 40
	_nhan_ten.pixel_size = 0.0020
	_nhan_ten.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nhan_ten.outline_size = 12
	_nhan_ten.modulate = Color(0.88, 0.86, 0.80)
	_nhan_ten.position = Vector3(0, 3.05, 0)
	add_child(_nhan_ten)

	_ve_lua()

func dong_moi() -> String:
	if not TheGioi.bia_da_bat(ma):
		return "E — bật bia đá"
	return "E — nghỉ"

func tuong_tac() -> void:
	AmThanh.phat("bia_da")
	var lan_dau := not TheGioi.bia_da_bat(ma)
	# nghi() tự bật bia luôn, nên chỉ cần hỏi TRƯỚC khi gọi.
	TheGioi.nghi(ma)
	_ve_lua()
	bao_hud(("Bật bia đá — %s" if lan_dau else "Nghỉ ở %s") % ten)

	var man := get_tree().get_first_node_in_group("man_bia_da") as ManBiaDa
	if man != null:
		man.mo_o_bia(ten)

## Chỗ đứng dậy sau khi chết: ngay trước mặt bia, không chồng vào phiến đá.
## "Trước mặt" là -Z, đúng quy ước hướng nhìn của Node3D trong Godot.
func diem_hoi_sinh() -> Vector3:
	var truoc := -global_transform.basis.z
	truoc.y = 0.0
	return global_position + truoc.normalized() * 1.6

## Bia chưa bật thì đỉnh xám và tối; bật rồi thì sáng. Đây là toàn bộ phần
## thưởng nhìn thấy được của việc tìm ra một bia đá mới.
func _ve_lua() -> void:
	if _dinh == null:
		return
	var sang := TheGioi.bia_da_bat(ma)
	var vl := _dinh.material_override as StandardMaterial3D
	if vl == null:
		return
	vl.albedo_color = Color(0.95, 0.80, 0.42) if sang else Color(0.30, 0.30, 0.32)
	vl.emission_enabled = sang
	vl.emission = Color(1.0, 0.82, 0.40)
	vl.emission_energy_multiplier = 2.4 if sang else 0.0
