extends Node

## Chụp ảnh màn hình game rồi thoát. Chạy:
##
##     godot --path . tools/chup_man_hinh.tscn
##
## KHÔNG chạy được với --headless: headless không có phần vẽ nào, ảnh ra đen
## trơn. Phải mở cửa sổ thật, nên lệnh này chớp một cái cửa sổ rồi tắt.
##
## Vì sao cần: giao diện là thứ DUY NHẤT trong repo mà bộ kiểm tra không với
## tới. Test đọc được "HUD có gắn minimap", nhưng không đọc được "quả cầu máu
## vẽ đè lên thanh kỹ năng" hay "chữ Hán ra ô vuông". Ảnh thì đọc được.
##
## Ảnh ghi ra `user://` — trên Windows là
## %APPDATA%\Godot\app_userdata\Game3SD\.

const CANH := "res://scenes/the_gioi/phong_thu.tscn"
## Chờ bấy nhiêu khung rồi mới chụp: HUD tìm người chơi ở khung thứ hai, địa
## hình và quái còn đang dựng, mà chụp sớm thì ra một màn hình trống.
const CHO_KHUNG := 45

func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var canh: Node = (load(CANH) as PackedScene).instantiate()
	add_child(canh)

	for i in CHO_KHUNG:
		await get_tree().process_frame
	await _chup("hud.png")

	# Quả cầu lúc VƠI. Ảnh đầy thì không nói được gì: cả điểm của quả cầu là mức
	# nước, mà mức nước chỉ sai khi nó khác 100%. Đây là chỗ bắt lỗi cắt ảnh —
	# nước bẹp thành cái đĩa, hay dâng ngược từ trên xuống.
	var nc = get_tree().get_first_node_in_group("nguoi_choi")
	if nc != null:
		nc.set("mau", nc.get("mau_toi_da") * 0.38)
		nc.set("mp", nc.get("mp_toi_da") * 0.62)
		nc.set("the_luc", nc.get("the_luc_max") * 0.45)
		for i in 4:
			await get_tree().process_frame
		await _chup("hud_voi.png")
		nc.set("mau", nc.get("mau_toi_da"))
		nc.set("mp", nc.get("mp_toi_da"))

	# Ảnh thứ hai: menu tạm dừng. Mở bằng hàm chứ không bơm phím — ở đây chỉ
	# cần cái ảnh, còn chuyện phím Esc có nối đúng không thì thu_vong_lap lo.
	var man := get_tree().get_first_node_in_group("man_cai_dat")
	if man != null:
		man.call("mo")
		for i in 6:
			await get_tree().process_frame
		await _chup("menu.png")
		man.call("_di_trang", 1)
		for i in 6:
			await get_tree().process_frame
		await _chup("tuy_chon.png")
		man.call("_di_trang", 2)
		for i in 6:
			await get_tree().process_frame
		await _chup("dieu_khien.png")

		man.call("dong")

	# Màn hành trang: đây là chỗ chữ Hán dày nhất game, nên cũng là chỗ lỗi font
	# lộ ra rõ nhất.
	var ht := get_tree().get_first_node_in_group("man_hanh_trang")
	if ht != null:
		ht.call("mo")
		for i in 8:
			await get_tree().process_frame
		await _chup("hanh_trang.png")

	# Đóng mọi màn che lại trước đã — không thì ảnh cửa sổ nhỏ chụp trúng màn
	# hành trang đang mở, và nó che mất đúng cái HUD cần đo.
	if ht != null:
		ht.call("dong")
	for i in 6:
		await get_tree().process_frame

	# Chụp lại ở CỬA SỔ NHỎ. Minimap khai bán kính theo chiều cao tham chiếu
	# 1080, nên hai ảnh này phải cho ra cùng một TỈ LỆ so với chiều cao — đó là
	# thứ duy nhất chứng minh được nó co giãn đúng, và mắt thì không đo được.
	get_window().size = Vector2i(960, 540)
	for i in 8:
		await get_tree().process_frame
	await _chup("hud_nho.png")

	get_tree().quit()

func _chup(ten: String) -> void:
	await RenderingServer.frame_post_draw
	var anh := get_viewport().get_texture().get_image()
	var duong := "user://" + ten
	anh.save_png(duong)
	print("ANH: ", ProjectSettings.globalize_path(duong))
