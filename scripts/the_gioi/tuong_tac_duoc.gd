class_name TuongTacDuoc
extends Area3D

## Lớp gốc của mọi thứ bấm E được: bia đá, món đồ rơi, vũng hồn.
##
## Gom đúng một luật mà thiếu là khó chịu ngay: đứng giữa bia đá và món đồ rơi
## thì MỘT phím E chỉ được ăn vào MỘT thứ — cái GẦN NHẤT. Không có luật này
## thì nhặt món đồ xong màn bia đá bật lên theo, và người chơi không hiểu vì
## sao mình lại đang ngồi thiền.
##
## Món con cài hai hàm: `dung_hinh()` (dựng phần nhìn) và `tuong_tac()` (làm gì
## khi bấm E). Phần dò tầm với và dòng mời nằm hết ở đây, không chép lại.

signal da_tuong_tac

## Những thứ người chơi đang đứng trong tầm. Tĩnh vì phím E là của cả màn chơi
## chứ không của riêng node nào — và vì chỉ có đúng một người chơi.
static var dang_trong_tam: Array = []

## Dòng mời hiện trên đầu khi đứng đủ gần.
@export var loi_moi := "E"
## Bán kính tầm với, dùng khi scene không đặt sẵn CollisionShape3D.
@export var tam_voi := 2.6
## Treo dòng mời cao bao nhiêu.
@export var cao_nhan := 1.7

var nguoi_choi: Node3D = null
var trong_tam := false
var _nhan: Label3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2          # chỉ bắt thân người chơi (lớp 2)
	monitoring = true
	if get_node_or_null("Hinh") == null:
		var va := CollisionShape3D.new()
		va.name = "Hinh"
		var hinh_cau := SphereShape3D.new()
		hinh_cau.radius = tam_voi
		va.shape = hinh_cau
		add_child(va)
	body_entered.connect(_than_vao)
	body_exited.connect(_than_ra)

	_nhan = Label3D.new()
	_nhan.font_size = 44
	_nhan.pixel_size = 0.0022
	_nhan.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nhan.modulate = Color(0.98, 0.94, 0.72)
	_nhan.outline_size = 12
	_nhan.position = Vector3(0, cao_nhan, 0)
	_nhan.visible = false
	add_child(_nhan)

	set_process(false)
	dung_hinh()

func _exit_tree() -> void:
	dang_trong_tam.erase(self)

# --- Món con cài đè ---------------------------------------------------

## Dựng phần nhìn. Gọi một lần lúc vào scene.
func dung_hinh() -> void:
	pass

## Làm gì khi người chơi bấm E.
func tuong_tac() -> void:
	pass

## Dòng mời hiện trên đầu. Override nếu nó đổi theo trạng thái.
func dong_moi() -> String:
	return loi_moi

# --- Dò tầm với -------------------------------------------------------

func _than_vao(than: Node3D) -> void:
	if not than.is_in_group("nguoi_choi"):
		return
	nguoi_choi = than
	trong_tam = true
	if not dang_trong_tam.has(self):
		dang_trong_tam.append(self)
	set_process(true)

func _than_ra(than: Node3D) -> void:
	if not than.is_in_group("nguoi_choi"):
		return
	trong_tam = false
	dang_trong_tam.erase(self)
	set_process(false)
	_nhan.visible = false

func _process(_delta: float) -> void:
	var hien := la_gan_nhat()
	_nhan.visible = hien
	if hien:
		_nhan.text = dong_moi()

## Có phải cái gần người chơi nhất trong đám đang trong tầm không.
func la_gan_nhat() -> bool:
	if not trong_tam or nguoi_choi == null:
		return false
	var xa := global_position.distance_to(nguoi_choi.global_position)
	for t in dang_trong_tam:
		var khac := t as TuongTacDuoc
		if khac == null or khac == self or not is_instance_valid(khac):
			continue
		if khac.global_position.distance_to(nguoi_choi.global_position) < xa:
			return false
	return true

func _unhandled_input(su_kien: InputEvent) -> void:
	if not su_kien.is_action_pressed("tuong_tac"):
		return
	if not la_gan_nhat():
		return
	# Nuốt phím: hai thứ cùng tầm thì chỉ cái gần nhất được ăn.
	get_viewport().set_input_as_handled()
	tuong_tac()
	da_tuong_tac.emit()

# --- Tiện tay ---------------------------------------------------------

## Nhắn một dòng lên HUD. Tìm bằng nhóm chứ không bằng đường dẫn node, để
## bia đá đặt ở bản đồ nào cũng nhắn được.
func bao_hud(dong: String) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("bao"):
		h.call("bao", dong)

## Khối hộp dựng bằng code — chưa có model nào, xem mục "Quy ước" trong
## CLAUDE.md. Trả về node để món con chỉnh thêm.
func khoi(co: Vector3, mau: Color, tai: Vector3, phat_sang := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var hop := BoxMesh.new()
	hop.size = co
	m.mesh = hop
	m.position = tai
	var vl := StandardMaterial3D.new()
	vl.albedo_color = mau
	vl.roughness = 0.9
	if phat_sang > 0.0:
		vl.emission_enabled = true
		vl.emission = mau
		vl.emission_energy_multiplier = phat_sang
	m.material_override = vl
	add_child(m)
	return m
