class_name VatRoi
extends TuongTacDuoc

## Món đồ nằm ngoài đất, bấm E để nhặt.
##
## Tên hiện trên món rơi cũng theo luật ???: chữ chưa đọc được thì hiện □
## (mục 4.1). Nghĩa là nhìn từ xa đã phải quyết định "có đáng chạy qua đám quái
## kia để nhặt không" trong khi chưa đọc nổi tên nó. Đó là chủ ý.
##
## Học thêm một chữ thì cả những món đang nằm dưới đất cũng sáng ra ngay, không
## cần nhặt lên mới biết — vì thế mới nối vào `Tui.doi_trang_bi`.

const TOC_XOAY := 1.4

var mon: MonDo = null
var _khoi: MeshInstance3D = null
var _nhan_ten: Label3D = null
var _goc := 0.0

## Dựng một món rơi sẵn sàng thả vào cây scene.
static func tao(mon_moi: MonDo, tai: Vector3) -> VatRoi:
	var v := VatRoi.new()
	v.mon = mon_moi
	v.position = tai
	return v

func dung_hinh() -> void:
	add_to_group("vat_roi")
	cao_nhan = 1.05
	tam_voi = 1.9
	if mon == null:
		return

	# Khối nhỏ xoay chậm, màu theo độ hiếm. Không có model nào, nên màu là tín
	# hiệu duy nhất nhìn từ xa — và nó KHÔNG tiết lộ chỉ số, chỉ tiết lộ bậc.
	_khoi = khoi(Vector3(0.32, 0.32, 0.32), mon.mau(), Vector3(0, 0.4, 0), 0.7)

	_nhan_ten = Label3D.new()
	_nhan_ten.font_size = 38
	_nhan_ten.pixel_size = 0.0020
	_nhan_ten.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nhan_ten.outline_size = 12
	_nhan_ten.modulate = mon.mau()
	_nhan_ten.position = Vector3(0, 0.78, 0)
	add_child(_nhan_ten)
	_cap_nhat_ten()
	Tui.doi_trang_bi.connect(_cap_nhat_ten)

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_goc += TOC_XOAY * delta
	if _khoi != null:
		_khoi.rotation.y = _goc
		_khoi.position.y = 0.4 + sin(_goc * 1.6) * 0.06

func dong_moi() -> String:
	return "%s — nhặt %s" % [phim(), "?" if mon == null else mon.ten_hien()]

func tuong_tac() -> void:
	if mon == null:
		queue_free()
		return
	Tui.nhat(mon)
	bao_hud("Nhặt được %s  (%s)" % [mon.ten_hien(), DoHiem.ten(mon.do_hiem())])
	dang_trong_tam.erase(self)
	queue_free()

func _cap_nhat_ten() -> void:
	if _nhan_ten != null and mon != null:
		_nhan_ten.text = mon.ten_hien()
