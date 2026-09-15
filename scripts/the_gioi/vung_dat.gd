class_name VungDat
extends Node3D

## Một vùng thật (mốc 6). Thay cho `phong_thu.gd`: phòng thử đặt quái bằng một
## mảng hằng, vùng thật đọc `quai.csv` theo cột `vung`.
##
## Cấu trúc theo mục 7.2 — **lai: hoang dã sinh tự động, chốt chặn dựng tay**:
##
##   hoang dã   địa hình + cây đá + quái lang thang, sinh từ vung.csv
##   chốt chặn  bia đá và cửa boss, đặt bằng toạ độ trong `CHOT_CHAN`
##
## Bản yêu cầu nói thẳng ở mục 7.1 rằng AI làm dở việc thiết kế màn (đường tắt,
## mai phục, vòng lặp). Nên phần chốt chặn ở đây cố tình để THƯA và dễ sửa
## bằng tay: một bảng toạ độ, không có thuật toán nào. Ai có trực giác không
## gian thì vào sửa bảng đó, không phải đọc hiểu cả file.
##
## STREAMING: chỉ nạp ô địa hình quanh người chơi, xem `_cap_nhat_o()`.

const CANH_BIA := preload("res://scenes/the_gioi/bia_da.tscn")
const CANH_QUAI := preload("res://scenes/quai/quai.tscn")
const CANH_BOSS := preload("res://scenes/quai/boss.tscn")

## Nạp ô địa hình trong bán kính bấy nhiêu ô quanh người chơi. 2 nghĩa là lưới
## 5×5 ô = 320×320m — xa hơn tầm nhìn qua sương, nên không thấy mép.
const BAN_KINH_O := 2

## Bia đá của vùng: chỗ đứng, tính theo mét quanh gốc vùng. Mục 7.6 đòi 3-5 bia
## mỗi khu; ba cái là mức tối thiểu để đường về không quá xa.
const CHOT_BIA := [
	Vector3(0, 0, 0),
	Vector3(96, 0, -64),
	Vector3(-72, 0, 88),
]
## Chỗ đặt boss. Xa bia gần nhất đủ để đi bộ một đoạn, gần đủ để chết rồi
## quay lại không nản.
const CHOT_BOSS := Vector3(140, 0, 140)

## Bao nhiêu con quái lang thang. Đọc từ khu_vuc.csv nếu có, không thì mặc định.
const QUAI_MAC_DINH := 5

@export var ma_vung := "ria_bien"

var dia_hinh: DiaHinh = null
var _v := {}
var _o_dang_co := {}
var _nc: Node3D = null
var _o_cuoi := Vector2i(9999, 9999)

func _ready() -> void:
	add_to_group("vung_dat")
	_v = VocabDB.vung_cua(ma_vung)
	if _v.is_empty():
		push_warning("Khong co vung '%s' trong vung.csv" % ma_vung)
	TheGioi.vung_hien_tai = ma_vung
	# Ghi là ĐÃ TỚI ngay tại đây, không ở DuHanh.di_toi(): vùng đầu tiên người
	# chơi vào là do scene tự nạp chứ không qua bia đá nào, mà không ghi thì
	# vùng kế tiếp trong chuỗi `mo_khi` không bao giờ mở.
	DuHanh.da_toi[ma_vung] = true

	dia_hinh = DiaHinh.tao(ma_vung)
	add_child(dia_hinh)
	add_child(MoiTruongVung.tao(ma_vung))
	add_child(VongHoiSinh.new())

	_dat_bia()
	_dat_npc()
	_dat_quai()
	_dat_boss()
	TheGioi.nghi_bia_da.connect(func(_ma: String) -> void: _dat_lai_quai())
	TheGioi.hoi_sinh.connect(_dat_lai_quai)

func _process(_delta: float) -> void:
	if _nc == null:
		_nc = get_tree().get_first_node_in_group("nguoi_choi")
		if _nc == null:
			return
	_cap_nhat_o()

# --- Streaming -------------------------------------------------------

## Nạp ô quanh người chơi, huỷ ô đã đi xa. Chỉ làm việc khi người chơi ĐỔI Ô —
## quét lại danh sách mỗi khung hình là việc thừa, mà ô thì 64m mới đổi một lần.
func _cap_nhat_o() -> void:
	var o := Vector2i(
		int(floor(_nc.global_position.x / DiaHinh.CANH_O)),
		int(floor(_nc.global_position.z / DiaHinh.CANH_O)))
	if o == _o_cuoi:
		return
	_o_cuoi = o

	var can := {}
	for dz in range(-BAN_KINH_O, BAN_KINH_O + 1):
		for dx in range(-BAN_KINH_O, BAN_KINH_O + 1):
			can[Vector2i(o.x + dx, o.y + dz)] = true

	for k in can.keys():
		if not _o_dang_co.has(k):
			_nap_o(k)
	for k in _o_dang_co.keys():
		if not can.has(k):
			_o_dang_co[k].queue_free()
			_o_dang_co.erase(k)

func _nap_o(k: Vector2i) -> void:
	var o := dia_hinh.dung_o(k.x, k.y)
	RaiVat.rai(o, dia_hinh, k.x, k.y, _v)
	dia_hinh.add_child(o)
	_o_dang_co[k] = o

## Bao nhiêu ô địa hình đang nạp. Dùng cho bộ kiểm tra.
func so_o_dang_co() -> int:
	return _o_dang_co.size()

# --- Chốt chặn -------------------------------------------------------

func _dat_bia() -> void:
	for i in CHOT_BIA.size():
		var b := CANH_BIA.instantiate() as BiaDa
		b.ma = "%s_bia_%d" % [ma_vung, i]
		b.position = _tren_dat(CHOT_BIA[i])
		add_child(b)

## NPC đứng đúng chỗ khai trong npc.csv. Đây là "chốt chặn dựng tay" của mục
## 7.2 — toạ độ trong CSV chứ không rải theo thuật toán, vì chỗ đứng của một
## nhân vật kể chuyện là quyết định thiết kế, không phải số ngẫu nhiên.
func _dat_npc() -> void:
	for n in VocabDB.npc_trong_vung(ma_vung):
		add_child(Npc.tao(String(n["ma"]), _tren_dat(
			Vector3(float(n.get("x", 0)), 0.0, float(n.get("z", 0))))))

func _dat_quai() -> void:
	var ds := VocabDB.quai_trong_vung(ma_vung)
	if ds.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = int(_v.get("hat_giong", 1)) + 555
	for i in QUAI_MAC_DINH * ds.size():
		var q := CANH_QUAI.instantiate() as Quai
		q.ma = String(ds[i % ds.size()]["ma"])
		q.ma_vung = ma_vung
		# Rải trong vòng tròn quanh gốc, tránh ngay chân bia đá.
		var goc := r.randf() * TAU
		var xa := r.randf_range(26.0, 150.0)
		q.position = _tren_dat(Vector3(cos(goc) * xa, 0.0, sin(goc) * xa))
		add_child(q)

func _dat_boss() -> void:
	for b in VocabDB.boss:
		if String(b.get("vung", "")) != ma_vung:
			continue
		var n := CANH_BOSS.instantiate() as Boss
		n.ma = String(b["ma"])
		n.ma_vung = ma_vung
		n.position = _tren_dat(CHOT_BOSS)
		add_child(n)
		return

func _dat_lai_quai() -> void:
	# Chừa boss ra — hạ boss là hạ xong, nghỉ ở bia không dựng nó dậy.
	for q in get_tree().get_nodes_in_group("quai"):
		if not q.is_in_group("boss"):
			q.queue_free()
	_dat_quai()

## Đặt một thứ lên đúng mặt đất. Không có hàm này thì mọi thứ rơi tự do hoặc
## chôn trong đồi — địa hình sinh tự động nên không ai biết trước cao độ.
func _tren_dat(tai: Vector3) -> Vector3:
	return Vector3(tai.x, dia_hinh.cao_tai(tai.x, tai.z) + 0.1, tai.z)
