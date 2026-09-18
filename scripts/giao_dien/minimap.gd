class_name Minimap
extends Control

## Minimap tròn ở góc trên phải. Vẽ bằng _draw(), không dựng cây Control.
##
## KHÔNG đọc địa hình. Bản đồ này chỉ trả lời đúng một câu: "quanh mình có gì,
## ở hướng nào" — và câu đó trả được bằng cách quét NHÓM trong cây scene, chứ
## không cần biết mặt đất cao thấp ra sao. Đổi lại, nó chạy y hệt nhau ở phòng
## thử (dựng tay) lẫn ở bảy vùng thật (sinh từ CSV và streaming theo ô), mà
## không phải nối vào VungDat — nối vào thì phòng thử mất minimap.
##
## Bản đồ XOAY THEO NGƯỜI CHƠI: hướng đang nhìn luôn ở trên. Kiểu "bắc luôn ở
## trên" đọc chính xác hơn khi có bản đồ lớn để đối chiếu, mà game này chưa có
## bản đồ lớn — nên xoay theo người là thứ dùng được ngay.

## BA CON SỐ DƯỚI ĐÂY DO HUD ĐẨY XUỐNG, đừng sửa ở file này.
##
## Minimap được tạo bằng code (`Minimap.new()` trong hud.gd) chứ không đặt sẵn
## trong scene, nên nó KHÔNG có mặt trong Inspector lúc soạn thảo. Mọi nút vặn
## vì thế nằm ở node HUD — xem nhóm "Minimap" trong hud.gd — và HUD đẩy chúng
## xuống đây mỗi khung.
##
## Bán kính vẽ, tính bằng PIXEL CỐ ĐỊNH, không co theo cỡ cửa sổ: màn 2000px
## ngang thì 215 chiếm chừng một phần năm bề ngang, còn ở 1280×720 thì vẫn
## ngần ấy pixel, tức gần sáu phần mười chiều cao.
var ban_kinh := 215.0
## Quét quanh người chơi bao nhiêu mét. Rộng quá thì chấm chi chít không đọc
## được, hẹp quá thì thấy quái đúng lúc nó đã đấm vào mặt.
var tam_quet := 55.0
## Cách mép màn hình bao nhiêu pixel.
var le_man := 18.0

## Nhóm nào vẽ chấm gì. Thứ tự trong mảng là thứ tự VẼ, nên cái quan trọng
## xếp sau để nằm đè lên trên.
const NHOM := [
	{"nhom": "vat_roi",  "anh": "Minimap/Pins/Minimap_Pin_Yellow.png", "mau": Color(0.90, 0.80, 0.35), "co": 5.0},
	{"nhom": "vung_hon", "anh": "Minimap/Pins/Minimap_Pin_Yellow.png", "mau": Color(0.55, 0.80, 0.95), "co": 6.0},
	{"nhom": "npc",      "anh": "Minimap/Pins/Minimap_Pin_Green.png",  "mau": Color(0.45, 0.85, 0.45), "co": 6.0},
	{"nhom": "bia_da",   "anh": "Minimap/Pins/Minimap_Pin_Yellow.png", "mau": Color(0.95, 0.85, 0.40), "co": 7.0},
	{"nhom": "quai",     "anh": "Minimap/Pins/Minimap_Pin_Red.png",    "mau": Color(0.90, 0.25, 0.22), "co": 6.0},
	{"nhom": "boss",     "anh": "Minimap/Pins/Minimap_Pin_Boss.png",   "mau": Color(1.00, 0.45, 0.25), "co": 10.0},
]

var nc: Node3D = null

var _pin := {}

func _ready() -> void:
	add_to_group("minimap")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in NHOM:
		_pin[n["nhom"]] = GiaoDien.anh(String(n["anh"]))

func _process(_delta: float) -> void:
	visible = bool(CaiDat.lay("hien_minimap"))
	if not visible:
		return
	# Tự đặt chỗ mỗi khung thay vì dùng anchor. Anchor của một Control nằm
	# thẳng dưới CanvasLayer tính theo viewport, nhưng preset ghi đè cả offset
	# nên `position` gán một lần lúc dựng bị nó nuốt mất — bản đồ lọt hẳn ra
	# ngoài mép phải. Tính tay thì đúng ngay, và đổi cỡ cửa sổ cũng theo kịp.
	# Cỡ tính lại mỗi khung, không đặt một lần lúc dựng: `ban_kinh` chỉnh tay
	# được trong lúc game đang chạy (Inspector tab Remote), mà nếu cỡ chỉ tính
	# một lần thì kéo con số đó chẳng thấy gì đổi.
	var canh := ban_kinh * 2.0 + 18.0
	custom_minimum_size = Vector2(canh, canh)
	size = custom_minimum_size
	var man := get_viewport_rect().size
	position = Vector2(man.x - size.x - le_man, le_man)
	queue_redraw()

## Hướng camera đang nhìn, quy về góc trên mặt phẳng ngang. Bản đồ xoay ngược
## lại góc này, nên thứ nằm trước mặt người chơi hiện ra ở phía trên bản đồ.
func _goc_nhin() -> float:
	if nc == null:
		return 0.0
	var gia = nc.get_node_or_null("GiaCamera")
	var co_so: Basis = (gia as Node3D).global_transform.basis if gia != null \
		else nc.global_transform.basis
	var truoc := -co_so.z
	return atan2(truoc.x, truoc.z)

func _draw() -> void:
	var giua := size * 0.5
	# Nền tối mờ. Vẽ trước mọi thứ, kể cả khi chưa tìm ra người chơi — khung
	# tròn trống vẫn tốt hơn một lỗ thủng trên HUD.
	draw_circle(giua, ban_kinh, Color(0.08, 0.08, 0.09, 0.72))

	if nc != null and is_instance_valid(nc):
		_ve_cham(giua)
		_ve_nguoi_choi(giua)

	_ve_vanh(giua)

## Vành bản đồ. Vẽ bằng draw_arc, KHÔNG dùng Minimap_Mask.png.
##
## Cái tên đánh lừa: "Mask" của bộ asset này không phải khung viền mà là một
## MẶT NẠ — xám đều (104,104,104) ở alpha ~0.8 trên TOÀN BỘ mặt đĩa, để dùng
## làm mask cho shader. Vẽ đè nó lên bản đồ là phủ một lớp voan xám kín mít,
## và càng phóng to bản đồ thì lớp voan đó càng rõ. Đó đúng là "viền mờ màu đen
## nhìn không rõ" mà chủ dự án báo.
##
## Vành vẽ tay thì sắc ở mọi cỡ, và không ăn mất chút sáng nào của mặt bản đồ.
func _ve_vanh(giua: Vector2) -> void:
	# Ba nét lồng nhau: tối bên ngoài, đồng ở giữa, tối mảnh bên trong. Một nét
	# đơn ở bán kính lớn trông như một sợi chỉ, không ra cái khung.
	draw_arc(giua, ban_kinh + 5.0, 0.0, TAU, 96, Color(0.05, 0.05, 0.06, 0.95), 9.0, true)
	draw_arc(giua, ban_kinh + 1.0, 0.0, TAU, 96, GiaoDien.VIEN, 3.0, true)
	draw_arc(giua, ban_kinh - 2.0, 0.0, TAU, 96, Color(0, 0, 0, 0.55), 2.0, true)

func _ve_cham(giua: Vector2) -> void:
	var goc := _goc_nhin()
	var tam := nc.global_position
	for n in NHOM:
		var ten := String(n["nhom"])
		for v in get_tree().get_nodes_in_group(ten):
			var n3 := v as Node3D
			if n3 == null or not is_instance_valid(n3):
				continue
			# Boss nằm trong CẢ nhóm "quai" lẫn "boss" — vẽ nó ở lượt "quai"
			# nữa là hai chấm chồng nhau, chấm đỏ nhỏ đè lên chấm boss.
			if ten == "quai" and n3.is_in_group("boss"):
				continue
			if n3.has_method("con_song") and not n3.call("con_song"):
				continue
			var d := n3.global_position - tam
			d.y = 0.0
			if d.length() > tam_quet:
				continue
			# Quay ngược góc nhìn: trục -Z của thế giới thành "lên" trên bản đồ.
			var q := d.rotated(Vector3.UP, -goc)
			var tai := giua + Vector2(q.x, -q.z) / tam_quet * ban_kinh
			_cham(tai, _pin.get(ten), Color(n["mau"]), float(n["co"]))

func _cham(tai: Vector2, tex: Texture2D, mau: Color, co: float) -> void:
	if tex != null:
		var r := co * 1.9
		draw_texture_rect(tex, Rect2(tai - Vector2(r, r), Vector2(r * 2, r * 2)),
			false, mau)
		return
	draw_circle(tai, co, mau)
	draw_arc(tai, co, 0.0, TAU, 12, Color(0, 0, 0, 0.7), 1.5, true)

## Người chơi là một tam giác ở đúng tâm, luôn chỉ lên. Không vẽ chấm tròn:
## chấm tròn không nói được hướng, mà hướng chính là thứ bản đồ xoay này bán.
func _ve_nguoi_choi(giua: Vector2) -> void:
	var d := PackedVector2Array([
		giua + Vector2(0, -9), giua + Vector2(6.5, 7), giua + Vector2(0, 3.5),
		giua + Vector2(-6.5, 7),
	])
	draw_colored_polygon(d, Color(0.96, 0.94, 0.88, 0.95))
	draw_polyline(d + PackedVector2Array([d[0]]), Color(0.1, 0.1, 0.1, 0.9), 1.5, true)
