class_name RaiVat
extends RefCounted

## Rải cây và đá lên địa hình theo luật (mốc 6, mục 7.1 — "rải theo luật").
##
## Ba luật, và cả ba đều là luật chứ không phải toạ độ tay:
##
##   mật độ    `mat_do_cay` / `mat_do_da` của vùng trong vung.csv
##   độ dốc    cây không mọc trên vách; đá thì ngược lại, càng dốc càng nhiều
##   hạt giống cùng một ô luôn ra đúng một kết quả, đi đi lại lại không đổi
##
## Luật thứ ba quan trọng hơn vẻ ngoài: streaming huỷ ô rồi nạp lại, mà mỗi
## lần nạp lại cây mọc chỗ khác thì người chơi không bao giờ nhớ được đường.
## Nhớ được đường chính là thứ làm một vùng thành một NƠI CHỐN.
##
## Không dùng ProtonScatter (mục 7.3) vì lý do như địa hình: repo không phụ
## thuộc addon. Mất phần rải theo spline, chưa cần tới.

## Nhiều hơn số này trong một ô thì thôi — ô 64×64 mà nhét vài nghìn node là
## giật lúc nạp, mà mắt cũng không phân biệt được nữa.
const TOI_DA_MOI_O := 90

## Dốc quá bấy nhiêu (0 = phẳng, 1 = vách đứng) thì cây không mọc.
const DOC_TOI_DA_CAY := 0.42

static func rai(o: Node3D, dh: DiaHinh, ox: int, oz: int, v: Dictionary) -> void:
	var xoa := dh.muc_bi_xoa()
	var r := RandomNumberGenerator.new()
	# Hạt giống trộn từ hạt của vùng và toạ độ ô — cùng ô thì cùng kết quả,
	# khác ô thì khác hẳn, và không có hai ô nào trùng nhau.
	r.seed = int(v.get("hat_giong", 1)) * 73856093 + ox * 19349663 + oz * 83492791

	var goc := Vector3(float(ox) * DiaHinh.CANH_O, 0.0, float(oz) * DiaHinh.CANH_O)
	var mat_cay := float(v.get("mat_do_cay", 0.3))
	var mat_da := float(v.get("mat_do_da", 0.2))
	var so := int(clampf((mat_cay + mat_da) * 120.0, 0.0, float(TOI_DA_MOI_O)))
	if so <= 0:
		return

	var ti_cay := mat_cay / maxf(mat_cay + mat_da, 0.001)
	var goc_cay := Color.from_string("#" + String(v.get("mau_suong", "708060")),
		Color(0.45, 0.5, 0.4))
	# Mất tên thì mất màu — cây đá của vùng bị xoá bạc ra như đất (mục 7.5).
	goc_cay = goc_cay.lerp(Color(0.90, 0.90, 0.92), xoa * 0.7)

	for i in so:
		var x := goc.x + r.randf() * DiaHinh.CANH_O
		var z := goc.z + r.randf() * DiaHinh.CANH_O
		var y := dh.cao_tai(x, z)
		var doc := _do_doc(dh, x, z)
		var la_cay := r.randf() < ti_cay
		if la_cay and doc > DOC_TOI_DA_CAY:
			continue                    # cây không mọc trên vách
		if not la_cay and doc < 0.10 and r.randf() < 0.7:
			continue                    # đá thì thưa ở chỗ phẳng
		o.add_child(_mot_vat(la_cay, Vector3(x, y, z) - goc, r, goc_cay, doc))

## Độ dốc tại một điểm: lấy chênh cao theo hai trục. Không cần chính xác —
## chỉ cần phân biệt được "sườn thoải" với "vách".
static func _do_doc(dh: DiaHinh, x: float, z: float) -> float:
	var d := 1.5
	var gx := absf(dh.cao_tai(x + d, z) - dh.cao_tai(x - d, z))
	var gz := absf(dh.cao_tai(x, z + d) - dh.cao_tai(x, z - d))
	return clampf(maxf(gx, gz) / (d * 2.0), 0.0, 1.0)

static func _mot_vat(la_cay: bool, tai: Vector3, r: RandomNumberGenerator,
		mau_nen: Color, doc: float) -> Node3D:
	var n := Node3D.new()
	n.position = tai
	n.rotation.y = r.randf() * TAU

	if la_cay:
		var cao := r.randf_range(3.2, 7.5)
		var than := _hop(Vector3(0.34, cao, 0.34),
			Color(0.24, 0.18, 0.13).lerp(mau_nen, 0.18))
		than.position.y = cao * 0.5
		n.add_child(than)
		var tan := _hop(Vector3(2.6, 2.4, 2.6),
			mau_nen.lerp(Color(0.16, 0.30, 0.14), 0.55))
		tan.position.y = cao + 0.9
		tan.scale = Vector3.ONE * r.randf_range(0.75, 1.35)
		n.add_child(tan)
		# Cây nghiêng nhẹ theo dốc — đứng thẳng tắp trên sườn nhìn ra ngay là giả.
		n.rotation.x = r.randf_range(-0.09, 0.09) + doc * 0.18
		n.rotation.z = r.randf_range(-0.09, 0.09)
	else:
		var co := r.randf_range(0.6, 2.3)
		var da := _hop(Vector3(co, co * r.randf_range(0.5, 1.1), co * r.randf_range(0.7, 1.3)),
			mau_nen.lerp(Color(0.30, 0.30, 0.32), 0.7))
		da.position.y = co * 0.25
		n.add_child(da)
		n.rotation.x = r.randf_range(-0.4, 0.4)
		n.rotation.z = r.randf_range(-0.4, 0.4)
	return n

static func _hop(co: Vector3, mau: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = co
	m.mesh = b
	var vl := StandardMaterial3D.new()
	vl.albedo_color = mau
	vl.roughness = 0.95
	m.material_override = vl
	return m
