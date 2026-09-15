class_name DiaHinh
extends Node3D

## Địa hình sinh tự động cho một vùng (mốc 6). Mọi thông số đọc từ data/vung.csv.
##
## Vì sao TỰ VIẾT chứ không dùng Terrain3D như mục 7.3 gợi ý: chủ dự án chốt
## repo không phụ thuộc addon. Đổi lại phải tự lo ba thứ Terrain3D cho sẵn —
## chia ô, mức chi tiết, và va chạm. Hai cái đầu làm ở `streaming.gd`, cái thứ
## ba là `HeightMapShape3D` ngay dưới đây.
##
## Cách sinh, đúng như mục 7.1 ("heightmap + xói mòn + rải theo luật"):
##
##   1. nhiễu nhiều tầng (fBm)        → hình dáng thô
##   2. một lượt xói mòn giả          → sườn dốc thoải xuống, đỉnh sắc lại
##   3. làm phẳng quanh gốc toạ độ    → chỗ người chơi rơi xuống phải đứng được
##
## Bước 2 là thứ phân biệt "đồi do máy sinh" với "đồi trông như địa hình": chỉ
## fBm thì mọi sườn dốc đều đều một kiểu, mắt nhận ra ngay là nhiễu.
##
## KHÔNG có chữ Hán nào trong file này. Vùng nào cao bao nhiêu, gồ ghề ra sao,
## là chuyện của `vung.csv`.

## Cạnh một ô địa hình, tính bằng mét. Ô to thì ít node hơn nhưng nạp/huỷ giật
## hơn; 64m là chỗ cân bằng cho map cỡ vài trăm mét.
const CANH_O := 64.0
## Số đỉnh trên một cạnh ô. 33 cho ra lưới 32×32 ô vuông, bước 2m — đủ mịn để
## đi lại không thấy gãy, đủ thô để một vùng không nổ mất vài trăm nghìn tam giác.
const SO_DINH := 33

## Bán kính quanh gốc vùng được san phẳng, để chỗ hạ cánh luôn đứng được.
const BAN_KINH_SAN := 14.0

var ma_vung := ""
var _v := {}
var _nhieu: FastNoiseLite = null
var _nhieu_tho: FastNoiseLite = null

static func tao(ma: String) -> DiaHinh:
	var dh := DiaHinh.new()
	dh.ma_vung = ma
	return dh

func _ready() -> void:
	add_to_group("dia_hinh")
	_v = VocabDB.vung_cua(ma_vung)
	_dung_nhieu()

func _dung_nhieu() -> void:
	var hat := int(_v.get("hat_giong", 1))
	_nhieu = FastNoiseLite.new()
	_nhieu.seed = hat
	_nhieu.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_nhieu.fractal_type = FastNoiseLite.FRACTAL_FBM
	_nhieu.fractal_octaves = 5
	_nhieu.frequency = 0.013
	# Tầng thô riêng: quyết định "đây là đồng bằng hay là núi", tách khỏi tầng
	# chi tiết để đổi `do_go_ghe` không làm cả vùng đổi hình dáng lớn.
	_nhieu_tho = FastNoiseLite.new()
	_nhieu_tho.seed = hat + 7919
	_nhieu_tho.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# Tần số chọn theo CỠ VÙNG, không phải theo cảm tính: vùng chơi được rộng
	# khoảng 320m (5 ô × 64m), nên tầng thô ~240m cho một hai quả đồi lớn và
	# tầng chi tiết ~77m cho gò đống đi bộ qua được. Để thấp hơn (bản đầu:
	# 0.0012 và 0.004) thì cả vùng gần như phẳng lì — đo được đúng −1.4m ở
	# cách gốc 145m, trong khi cao_do của vùng khai là 26.
	_nhieu_tho.frequency = 0.0042

## Cao độ tại một điểm trong thế giới. Đây là NGUỒN SỰ THẬT — cả mặt lưới, cả
## va chạm, cả chỗ đặt cây đá đều hỏi hàm này, nên không bao giờ lệch nhau.
func cao_tai(x: float, z: float) -> float:
	if _nhieu == null:
		_dung_nhieu()
	var bien_do := float(_v.get("cao_do", 20))
	var go_ghe := float(_v.get("do_go_ghe", 0.3))

	var tho := _nhieu_tho.get_noise_2d(x, z)          # -1..1, thoai thoải
	var chi_tiet := _nhieu.get_noise_2d(x, z)         # -1..1, lắm chi tiết
	var h := tho * 0.65 + chi_tiet * go_ghe * 0.9

	# Xói mòn giả: kéo giá trị về phía 0 theo hàm mũ. Sườn dốc thoải xuống,
	# đỉnh giữ nguyên độ sắc. Một lượt là đủ — mô phỏng thuỷ lực thật thì đẹp
	# hơn nhưng chạy lúc nạp ô thì giật.
	h = sign(h) * pow(absf(h), 1.35)

	# San phẳng quanh gốc vùng: chỗ người chơi xuất hiện phải đứng được, không
	# rơi vào vách. Pha mềm theo khoảng cách, không cắt phựt.
	var xa := sqrt(x * x + z * z)
	if xa < BAN_KINH_SAN * 2.0:
		var k := clampf((xa - BAN_KINH_SAN) / BAN_KINH_SAN, 0.0, 1.0)
		h *= k * k * (3.0 - 2.0 * k)      # smoothstep

	return h * bien_do

## Dựng một ô địa hình ở toạ độ ô (ox, oz). Trả về node để streaming giữ và huỷ.
func dung_o(ox: int, oz: int) -> Node3D:
	var goc := Vector3(float(ox) * CANH_O, 0.0, float(oz) * CANH_O)
	var o := Node3D.new()
	o.name = "O_%d_%d" % [ox, oz]
	o.position = goc

	var buoc := CANH_O / float(SO_DINH - 1)
	var cao := PackedFloat32Array()
	cao.resize(SO_DINH * SO_DINH)

	var luoi := SurfaceTool.new()
	luoi.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in SO_DINH:
		for i in SO_DINH:
			var x := float(i) * buoc
			var z := float(j) * buoc
			var y := cao_tai(goc.x + x, goc.z + z)
			cao[j * SO_DINH + i] = y
			luoi.set_uv(Vector2(x / CANH_O, z / CANH_O))
			luoi.add_vertex(Vector3(x, y, z))
	for j in SO_DINH - 1:
		for i in SO_DINH - 1:
			var a := j * SO_DINH + i
			var b := a + 1
			var c := a + SO_DINH
			var e := c + 1
			luoi.add_index(a); luoi.add_index(c); luoi.add_index(b)
			luoi.add_index(b); luoi.add_index(c); luoi.add_index(e)
	luoi.generate_normals()

	var hien := MeshInstance3D.new()
	hien.mesh = luoi.commit()
	hien.material_override = _vat_lieu_dat()
	o.add_child(hien)

	# Va chạm dùng HeightMapShape3D chứ không phải mesh: cùng một mảng cao độ,
	# mà Jolt xử lý heightmap nhanh hơn hẳn concave mesh — và quan trọng hơn,
	# không bao giờ lệch so với thứ đang nhìn thấy.
	var than := StaticBody3D.new()
	than.collision_layer = 1
	than.collision_mask = 0
	var va := CollisionShape3D.new()
	var hs := HeightMapShape3D.new()
	hs.map_width = SO_DINH
	hs.map_depth = SO_DINH
	hs.map_data = cao
	va.shape = hs
	# HeightMapShape3D lấy tâm làm gốc, còn lưới ở trên lấy góc — dịch nửa ô.
	va.position = Vector3(CANH_O * 0.5, 0.0, CANH_O * 0.5)
	va.scale = Vector3(buoc, 1.0, buoc)
	than.add_child(va)
	o.add_child(than)
	return o

func _vat_lieu_dat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	# Màu đất suy từ MÀU SƯƠNG của vùng, tối đi. Bảy vùng bảy bảng màu mà không
	# phải khai thêm cột nào — mục 7.4: ánh sáng và màu là 80% của chữ "đẹp".
	var suong := Color.from_string("#" + String(_v.get("mau_suong", "808080")),
		Color(0.5, 0.5, 0.5))
	var mau := suong.lerp(Color(0.10, 0.11, 0.10), 0.62)
	# "Nơi nào mất tên thì mất luôn hình dạng" (mục 7.5): đất của vùng bị xoá
	# bạc ra như giấy chưa viết. Môi trường đã giảm bão hoà cả màn hình rồi,
	# nhưng làm thêm ở ĐÂY mới ra cảm giác vật thể TỰ NÓ nhạt, chứ không phải
	# camera bị chỉnh.
	var xoa := muc_bi_xoa()
	m.albedo_color = mau.lerp(Color(0.90, 0.90, 0.92), xoa * 0.7)
	m.roughness = lerpf(0.97, 0.55, xoa)
	return m

## Vùng này còn bị xoá bao nhiêu phần. Hỏi node môi trường — nó là chỗ DUY NHẤT
## tính con số đó, để đất, cây, đá và bầu trời không bao giờ nhạt lệch nhau.
func muc_bi_xoa() -> float:
	for n in get_tree().get_nodes_in_group("moi_truong_vung"):
		var mt := n as MoiTruongVung
		if mt != null and mt.ma_vung == ma_vung:
			return mt.muc_bi_xoa()
	return float(_v.get("bi_xoa", 0.0))
