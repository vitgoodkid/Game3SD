class_name CameraBaCheDo
extends Node3D

## Camera kiểu Minecraft: F5 xoay vòng ba chế độ (mục 8).
##   0  thứ ba, sau lưng (mặc định) — lệch vai
##   1  thứ nhất — trong mắt, không thấy thân
##   2  thứ ba, trước mặt — nhìn vào mặt nhân vật
##
## Mục 15 của bản yêu cầu đã chốt: "kiểu Minecraft" là CAMERA, không phải thế
## giới voxel. Thế giới là địa hình 3D bình thường.
##
## SpringArm3D là bắt buộc, không thì camera xuyên tường.

signal doi_che_do(che_do: int)

const SAU := 0
const THU_NHAT := 1
const TRUOC := 2
const TEN_CHE_DO := ["Thứ ba — sau lưng", "Thứ nhất", "Thứ ba — trước mặt"]

const DAI_SAU := 4.2
const DAI_TRUOC := 3.4
## Lệch vai: souls-like nào cũng lệch, để nhân vật không che mất mục tiêu.
const LECH_VAI := Vector3(0.55, 0.0, 0.0)
const CAO_MAT := 1.62      ## ngang tầm mắt nhân vật cao 1.8m

@export var do_nhay_chuot := 0.0032
@export var goc_tren := 1.20      ## radian, ~69°
@export var goc_duoi := -0.95
## Cài đặt "giảm xoay camera khi lăn" — bật mặc định vì lăn ở góc nhìn thứ
## nhất gây chóng mặt thật (mục 8).
@export var giam_xoay_khi_lan := true

var che_do := SAU
var _nc: NguoiChoi = null
var _tay: SpringArm3D = null
var _cam: Camera3D = null
## Camera tạm chuyển sang góc ba lúc diễn kết liễu/backstab rồi trả về.
var _tam_goc_ba := false

func _ready() -> void:
	_nc = get_parent() as NguoiChoi
	_tay = $Tay
	_cam = $Tay/Camera
	top_level = true          # không xoay theo thân nhân vật
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ap_che_do()

func _unhandled_input(su_kien: InputEvent) -> void:
	if su_kien is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := su_kien as InputEventMouseMotion
		var hs := 1.0
		if giam_xoay_khi_lan and _nc != null and _nc.may.ten_hien_tai == "lan":
			hs = 0.35
		# Khoá mục tiêu ở góc thứ ba: camera tự bám mục tiêu, chuột chỉ để
		# hất đổi mục tiêu (xử ở khoa_muc_tieu.gd) nên không xoay ở đây.
		if _nc != null and _nc.muc_tieu != null and che_do != THU_NHAT:
			return
		rotation.y -= mm.relative.x * do_nhay_chuot * hs
		rotation.x = clampf(rotation.x - mm.relative.y * do_nhay_chuot * hs,
			goc_duoi, goc_tren)

	if su_kien.is_action_pressed("doi_camera"):
		che_do = (che_do + 1) % 3
		_ap_che_do()
		doi_che_do.emit(che_do)

	if su_kien.is_action_pressed("thoat"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if \
			Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if _nc == null:
		return
	# Bám theo nhân vật, mượt nhẹ. Bám cứng thì mọi va giật của
	# CharacterBody3D đều dội thẳng vào camera.
	var dich := _nc.global_position + Vector3(0, CAO_MAT, 0)
	global_position = global_position.lerp(dich, minf(1.0, 18.0 * delta))

	# Khoá mục tiêu: camera tự quay về mục tiêu, TRỪ góc nhìn thứ nhất — ở đó
	# camera không tự xoay, chỉ có mũi tên rìa màn hình chỉ hướng (mục 8).
	if _nc.muc_tieu != null and _che_do_thuc() != THU_NHAT:
		_quay_ve_muc_tieu(delta)

func _quay_ve_muc_tieu(delta: float) -> void:
	var v := _nc.muc_tieu.global_position - global_position
	if v.length_squared() < 0.01:
		return
	var y := atan2(-v.x, -v.z)
	var x := clampf(atan2(v.y, Vector2(v.x, v.z).length()), goc_duoi, goc_tren)
	var k := minf(1.0, 9.0 * delta)
	rotation.y = lerp_angle(rotation.y, y, k)
	rotation.x = lerp_angle(rotation.x, x, k)

func _che_do_thuc() -> int:
	return SAU if _tam_goc_ba else che_do

func _ap_che_do() -> void:
	match _che_do_thuc():
		THU_NHAT:
			_tay.spring_length = 0.0
			_tay.position = Vector3.ZERO
			_tay.rotation.y = 0.0
			_cam.position = Vector3.ZERO
			# Giấu thân, không thì ở trong đầu mình nhìn ra thấy toàn mặt trong
			# của hộp. Vũ khí vẫn hiện — người chơi cần thấy mình đang cầm gì.
			_hien_than(false)
		TRUOC:
			_tay.spring_length = DAI_TRUOC
			_tay.position = Vector3.ZERO
			_tay.rotation.y = PI
			_cam.position = Vector3.ZERO
			_hien_than(true)
		_:
			_tay.spring_length = DAI_SAU
			_tay.position = LECH_VAI
			_tay.rotation.y = 0.0
			_cam.position = Vector3.ZERO
			_hien_than(true)

## Ẩn/hiện thân người. Tra node bằng đường dẫn chứ không qua _nc.than: _ready()
## của camera chạy TRƯỚC _ready() của nhân vật (con trước cha trong Godot), nên
## lúc này @onready var than của NguoiChoi vẫn còn null.
func _hien_than(hien: bool) -> void:
	if _nc == null:
		return
	var tn := _nc.get_node_or_null("Than/ThanNguoi")
	if tn != null:
		tn.visible = hien

## Diễn hoạt ảnh kết liễu / backstab ở góc nhìn thứ nhất thì tạm chuyển sang
## góc ba, xong trả về (mục 8). Gọi muon_goc_ba(true) khi vào, false khi ra.
func muon_goc_ba(bat: bool) -> void:
	if _tam_goc_ba == bat:
		return
	_tam_goc_ba = bat
	_ap_che_do()

func ten_che_do() -> String:
	return TEN_CHE_DO[che_do]

## Có đang ở góc nhìn thứ nhất không — HUD hỏi để quyết định vẽ chấm ngắm,
## mũi tên chỉ mục tiêu và chỉ báo hướng bị đánh.
func la_thu_nhat() -> bool:
	return _che_do_thuc() == THU_NHAT
