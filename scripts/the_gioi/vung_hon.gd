class_name VungHon
extends TuongTacDuoc

## Vũng hồn — chỗ mình vừa chết, mang theo toàn bộ hồn chưa tiêu (mục 4.5).
##
##   chết  → rơi hết hồn chưa tiêu tại chỗ
##   về    → nhặt lại được
##   chết lần nữa trước khi nhặt → MẤT VĨNH VIỄN
##
## Ở game này mất hồn đau hơn mất điểm ở game khác, vì hồn chính là chữ vừa học
## xong. Đó là chủ ý, không phải tình cờ.
##
## Chỉ có MỘT vũng cùng lúc. Node này không tự giữ luật đó — TheGioi giữ; ở đây
## chỉ là phần nhìn thấy được của cái dictionary ấy.

var so_hon := 0
var _khoi: MeshInstance3D = null
var _nhan_hon: Label3D = null
var _t := 0.0

static func tao(hon: int, tai: Vector3) -> VungHon:
	var v := VungHon.new()
	v.so_hon = hon
	v.position = tai
	return v

func dung_hinh() -> void:
	add_to_group("vung_hon")
	cao_nhan = 1.5
	tam_voi = 2.2

	_khoi = khoi(Vector3(0.7, 0.05, 0.7), Color(0.72, 0.88, 0.95),
		Vector3(0, 0.05, 0), 1.6)

	_nhan_hon = Label3D.new()
	# 魂 là tiền tệ, đã hiện y hệt ở HUD — người chơi đọc nó hàng giờ mà không
	# ai dạy, đúng kiểu học thụ động của mục 14.
	_nhan_hon.text = "魂  %d" % so_hon
	_nhan_hon.font_size = 44
	_nhan_hon.pixel_size = 0.0022
	_nhan_hon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nhan_hon.outline_size = 12
	_nhan_hon.modulate = Color(0.80, 0.93, 1.0)
	_nhan_hon.position = Vector3(0, 1.0, 0)
	add_child(_nhan_hon)

func _physics_process(delta: float) -> void:
	# Nhấp nháy chậm. Vũng hồn phải NHÌN THẤY từ xa qua đám quái đang canh nó —
	# đó là cả trò chơi của mục 4.5.
	_t += delta
	if _khoi != null:
		_khoi.scale = Vector3.ONE * (1.0 + sin(_t * 2.0) * 0.12)

func dong_moi() -> String:
	return "E — nhặt lại %d hồn" % so_hon

func tuong_tac() -> void:
	AmThanh.phat("hon")
	var n := TheGioi.nhat_vung_hon()
	bao_hud("Nhặt lại %d hồn" % n)
	dang_trong_tam.erase(self)
	queue_free()
