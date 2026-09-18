extends Node

## Đo NHỊP COMBO thật: hai nhát liên tiếp cách nhau bao nhiêu giây.
##
##     godot --headless --path . tools/soi_combo.tscn
##
## Đo bằng lúc HỘP ĐÒN BẬT, không bằng lúc đổi state. Người chơi cảm nhận combo
## qua khoảng cách giữa hai lần TRÚNG, mà hộp đòn bật mới là lúc đó — đổi state
## xảy ra sớm hơn một quãng bằng cả khung vung tay.

const CANH_PHONG := preload("res://scenes/the_gioi/phong_thu.tscn")

var _nc: NguoiChoi = null
var _moc: Array = []
var _bat_truoc := false
var _t := 0.0
var _ghi := false

func _ready() -> void:
	add_child(CANH_PHONG.instantiate())
	await get_tree().process_frame
	await get_tree().physics_frame
	_nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi
	for chu in ["剑", "刃"]:
		await _do(chu)
		await _do_tre(chu)
	get_tree().quit()

## Đo ĐỘ TRỄ ĐẦU VÀO: từ lúc bấm tới lúc hộp đòn bật.
##
## Đây là con số quyết định game "nhạy" hay "khựng", và nó gồm hai phần cộng
## lại — cái thứ hai thường bị bỏ quên:
##   NGUONG_GIU_NANG  đòn nhẹ chỉ bắn ra lúc NHẢ, vì cùng nút với đòn nặng
##   t_vung           khung vung tay lên, của riêng từng đòn
func _do_tre(chu: String) -> void:
	_nc.may.doi("dung")
	for i in 60:
		await get_tree().physics_frame
		if _nc.is_on_floor():
			break
	_moc.clear()
	_bat_truoc = false
	_t = 0.0
	_ghi = true
	_bam()
	for i in 200:
		await get_tree().physics_frame
		if not _moc.is_empty():
			break
	_ghi = false
	_nc.may.doi("dung")
	await get_tree().physics_frame
	var m := VocabDB.don_cua(chu, "nhe_1")
	if _moc.is_empty():
		print("  %s: KHONG RA DON" % chu)
		return
	print("  %s trễ đầu vào: %.2fs  (ngưỡng giữ %.2f + vung tay %.2f)"
		% [chu, float(_moc[0][0]), NguoiChoi.NGUONG_GIU_NANG,
			float(m.get("t_vung", 0.0))])

func _do(chu: String) -> void:
	var vk := SinhMonDo.sinh_mon_tu_chu(chu, "thi_tran", 1000)
	Tui.nhat(vk)
	Tui.mac_vao(vk, "vu_khi", 0)
	Tui.tay_phai_dang = 0
	_nc.mau = _nc.mau_toi_da
	_nc.the_luc = 9999.0
	_nc.the_luc_max = 9999.0
	_nc.may.doi("dung")
	# Đợi chạm đất: rơi từ lúc dựng scene thì cú bấm đầu ra ĐÒN NHẢY, không
	# phải nhát một của combo.
	for i in 90:
		await get_tree().physics_frame
		if _nc.is_on_floor():
			break
	_moc.clear()
	_bat_truoc = false
	_t = 0.0
	_ghi = true
	# Bấm liên tục như người chơi mash: 0.14 giây một lần, trong 4 giây.
	var xong := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < xong:
		_bam()
		await get_tree().create_timer(0.14).timeout
	_ghi = false
	_nc.may.doi("dung")
	await get_tree().physics_frame

	print("")
	print("=== %s (%s) ===" % [chu, Tui.moveset_dang_dung()])
	var truoc := -1.0
	for m in _moc:
		var cach := "" if truoc < 0.0 else "  cách nhát trước %.2fs" % (m[0] - truoc)
		print("  nhát %-10s bật hộp đòn ở %.2fs%s" % [m[1], m[0], cach])
		truoc = m[0]
	if _moc.size() >= 2:
		var tong := float(_moc[_moc.size() - 1][0]) - float(_moc[0][0])
		print("  => trung bình %.2fs một nhát" % (tong / float(_moc.size() - 1)))

func _physics_process(delta: float) -> void:
	if not _ghi or _nc == null:
		return
	_t += delta
	var bat: bool = _nc.hop_don.monitoring
	if bat and not _bat_truoc:
		var d := "?"
		if _nc.may.ten_hien_tai == "danh":
			d = _nc.may.hien_tai._don
		_moc.append([_t, d])
	_bat_truoc = bat

func _bam() -> void:
	for xuong in [true, false]:
		var e := InputEventAction.new()
		e.action = "don_nhe"
		e.pressed = xuong
		Input.parse_input_event(e)
