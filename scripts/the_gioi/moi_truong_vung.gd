class_name MoiTruongVung
extends WorldEnvironment

## Môi trường riêng cho từng vùng, sinh từ data/vung.csv lúc chạy.
##
## Mục 7.4 của bản yêu cầu gọi đây là lời khuyên quan trọng nhất của cả phần
## map: **chỗ đáng đầu tư để "đẹp" là ÁNH SÁNG, không phải hình khối.** Một quả
## đồi đơn giản + ánh sáng tốt đẹp hơn hẳn quả đồi chi tiết + ánh sáng mặc
## định. Và ánh sáng là thứ chỉnh được bằng SỐ, hình khối thì không — nên nó
## nằm trong CSV, và bảy vùng trông khác hẳn nhau mà không tốn một mesh nào.
##
## Sáu cột của vung.csv điều khiển toàn bộ: `mau_troi` `mau_suong` `dam_suong`
## `goc_mat_troi` `cuong_do_troi` `bi_xoa`.
##
## `bi_xoa` là cột đặc biệt — xem mục 7.5. Nơi nào mất tên thì mất luôn hình
## dạng: vùng bị xoá nhiều thì bạc màu, sương dày, mặt trời yếu. Nó KHÔNG phải
## trang trí mà là một cái đồng hồ đo: người chơi khôi phục chữ thì vùng sáng
## lại. Xem `cap_nhat_theo_chu()`.

var ma_vung := ""
var _v := {}
var _mat_troi: DirectionalLight3D = null

static func tao(ma: String) -> MoiTruongVung:
	var mt := MoiTruongVung.new()
	mt.ma_vung = ma
	return mt

func _ready() -> void:
	add_to_group("moi_truong_vung")
	_v = VocabDB.vung_cua(ma_vung)
	_dung_mat_troi()
	dung_lai_moi_truong()
	# Ghép được chữ là vùng sáng ra ngay, không cần đi ra đi vào.
	Tui.doi_trang_bi.connect(dung_lai_moi_truong)

func _dung_mat_troi() -> void:
	_mat_troi = DirectionalLight3D.new()
	_mat_troi.name = "MatTroi"
	_mat_troi.shadow_enabled = true
	_mat_troi.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_mat_troi.directional_shadow_max_distance = 220.0
	add_child(_mat_troi)

## Dựng lại toàn bộ môi trường từ CSV + mức khôi phục chữ hiện tại.
func dung_lai_moi_truong() -> void:
	if _v.is_empty():
		return
	var xoa := muc_bi_xoa()

	var troi := _mau("mau_troi", Color(0.35, 0.45, 0.6))
	var suong := _mau("mau_suong", Color(0.6, 0.65, 0.7))
	# Bị xoá thì BẠC MÀU — kéo mọi màu về phía trắng xám, đúng mục 7.5:
	# "trắng bệch, mất vân, mờ dần ở rìa, như giấy chưa viết".
	var trang := Color(0.88, 0.88, 0.90)
	troi = troi.lerp(trang, xoa * 0.75)
	suong = suong.lerp(trang, xoa * 0.80)

	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var bt := Sky.new()
	var vl := ProceduralSkyMaterial.new()
	vl.sky_top_color = troi.darkened(0.25)
	vl.sky_horizon_color = suong
	vl.ground_bottom_color = troi.darkened(0.6)
	vl.ground_horizon_color = suong.darkened(0.2)
	bt.sky_material = vl
	e.sky = bt

	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 2.4
	e.ssil_enabled = true
	e.sdfgi_enabled = true
	e.sdfgi_cascades = 5
	e.sdfgi_use_occlusion = true
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.05

	# Sương: vừa là không khí souls, vừa là thứ che rìa map cho khỏi thấy mép
	# ô địa hình chưa nạp. Vùng bị xoá thì dày thêm — mất tên thì mờ đi.
	e.fog_enabled = true
	e.fog_light_color = suong
	e.fog_density = float(_v.get("dam_suong", 0.005)) * (1.0 + xoa * 1.6)
	e.fog_sky_affect = 0.45
	e.fog_height = -8.0
	e.fog_height_density = 0.04
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.016 * (1.0 + xoa)
	e.volumetric_fog_albedo = suong.lightened(0.1)
	e.volumetric_fog_gi_inject = 0.8
	e.volumetric_fog_length = 96.0

	e.adjustment_enabled = true
	e.adjustment_brightness = 1.02
	# Mất tên thì mất màu. Đây là một dòng, và nó là cả art direction của mục 7.5.
	e.adjustment_saturation = lerpf(1.05, 0.12, xoa)
	e.adjustment_contrast = 1.06
	environment = e

	if _mat_troi != null:
		_mat_troi.rotation_degrees = Vector3(
			float(_v.get("goc_mat_troi", -40)), -38.0, 0.0)
		_mat_troi.light_energy = float(_v.get("cuong_do_troi", 1.0)) * (1.0 - xoa * 0.45)
		_mat_troi.light_color = suong.lerp(Color(1, 0.96, 0.88), 0.5)

## Đọc một cột màu của vung.csv. Cột ghi mã hex không có dấu thăng (ví dụ
## `6b93b8`) — CSV mà có `#` thì người sửa hay quên, còn quên dấu thăng thì
## Godot đọc ra đen thui và không ai biết vì sao.
func _mau(cot: String, mac_dinh: Color) -> Color:
	var s := String(_v.get(cot, ""))
	if s == "":
		return mac_dinh
	return Color.from_string("#" + s, mac_dinh)

## Vùng này còn bị xoá bao nhiêu phần (0 = đã khôi phục hẳn, 1 = trắng bệch).
##
## Bắt đầu từ cột `bi_xoa` của vung.csv rồi TRỪ DẦN theo số chữ của vùng mà
## người chơi đã đọc được. Đây là chỗ nối mục 7.5 vào cơ chế học: khôi phục
## tên là khôi phục hình dạng, và người chơi thấy cả một vùng đổi màu vì mình
## vừa ghép xong một chữ.
func muc_bi_xoa() -> float:
	var goc := float(_v.get("bi_xoa", 0.0))
	if goc <= 0.0:
		return 0.0
	var chu_de: Array = _v.get("chu_de", [])
	if chu_de.is_empty():
		return goc
	var tong := 0
	var biet := 0
	for cd in chu_de:
		for tu in VocabDB.loc(String(cd)):
			tong += 1
			if TriNho.doc_duoc(String(tu["chu"])):
				biet += 1
	if tong == 0:
		return goc
	return goc * (1.0 - float(biet) / float(tong))
