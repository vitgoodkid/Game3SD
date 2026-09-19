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

## Ngân sách dựng ô mỗi khung hình, tính bằng mili giây.
##
## VÌ SAO PHẢI CÓ. Băng qua MỘT ranh giới ô là năm ô mới cùng lúc, và bản
## trước dựng cả năm trong một khung hình. Đo được **33 ms** (đất 3.1 ms +
## rải prop 3.5 ms mỗi ô). Nhịp vật lý là 120Hz — 8.33 ms một tick — nên cứ
## mỗi 64m đi được là BỐN tick bị nuốt trong một khung. Vùng bây giờ nhỏ nên
## ít khi băng ranh giới; map rộng ra thì cứ mươi giây chạy là một cú khựng,
## và khựng giữa lúc đánh nhau là thứ souls-like không tha.
##
## 2.0 ms là ngân sách "không ai thấy" ở 60fps. Nó KHÔNG cắt được giữa chừng
## một bước — bước nhỏ nhất (rải prop cho một ô) vẫn ~3.5 ms — nên tác dụng
## thật của nó là **mỗi khung hình đúng MỘT bước**, thay vì mười bước dồn vào
## một chỗ. Hạ xuống 0 cũng không nhanh hơn được nữa; nâng lên là gom nhiều
## bước lại, tức là quay về phía cái khựng cũ.
const NGAN_SACH_MS := 2.0

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
## Hai hàng chờ, và chúng TÁCH NHAU có lý do: đất phải có trước prop. Dựng
## xong đất một ô rồi mới quay lại rải cây cho nó thì cái vỡ tệ nhất — người
## chơi rơi xuyên xuống vực vì ô chưa có đất — không bao giờ xảy ra. Cái giá
## là cây mọc ra sau đất một nhịp, ở cách ít nhất 64m, trong sương.
var _hang_dat: Array[Vector2i] = []
var _hang_prop: Array[Vector2i] = []

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

## Xếp lại hàng chờ khi người chơi ĐỔI Ô, rồi mỗi khung hình dựng dần theo
## ngân sách. Quét lại danh sách mỗi khung là việc thừa — ô thì 64m mới đổi
## một lần — nhưng RÚT hàng chờ thì phải làm mỗi khung.
func _cap_nhat_o() -> void:
	var o := _o_cua(_nc.global_position)
	if o != _o_cuoi:
		_o_cuoi = o
		_xep_hang(o)
	_chay_hang()

func _o_cua(v: Vector3) -> Vector2i:
	return Vector2i(int(floor(v.x / DiaHinh.CANH_O)),
		int(floor(v.z / DiaHinh.CANH_O)))

func _xep_hang(o: Vector2i) -> void:
	var can := {}
	for dz in range(-BAN_KINH_O, BAN_KINH_O + 1):
		for dx in range(-BAN_KINH_O, BAN_KINH_O + 1):
			can[Vector2i(o.x + dx, o.y + dz)] = true

	# Huỷ thì làm NGAY, không xếp hàng: `queue_free()` rẻ, mà giữ lại ô đã đi
	# xa là đúng cái lỗi kinh điển bộ kiểm tra đang canh.
	for k in _o_dang_co.keys():
		if not can.has(k):
			_o_dang_co[k].queue_free()
			_o_dang_co.erase(k)
	# Quay đầu giữa đường thì không phải trả tiền cho quãng mình không đi nữa.
	_hang_dat = _hang_dat.filter(func(k: Vector2i) -> bool: return can.has(k))
	_hang_prop = _hang_prop.filter(func(k: Vector2i) -> bool: return can.has(k))

	for k in can.keys():
		if not _o_dang_co.has(k) and not _hang_dat.has(k):
			_hang_dat.append(k)
	# Gần người chơi dựng trước. Không có dòng này thì hàng chờ rút theo thứ
	# tự Dictionary, và ô ngay trước mặt có thể nằm cuối hàng.
	_hang_dat.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - o).length_squared() < (b - o).length_squared())

	# CHÂN NGƯỜI CHƠI KHÔNG ĐƯỢC HỞ ĐẤT.
	#
	# Đây là chỗ phân đôi cả cơ chế, và ranh giới là ĐI BỘ hay DỊCH CHUYỂN:
	#   • đi bộ — ô mới gần nhất cách ít nhất 64m, mà chạy nhanh nhất trong
	#     game là 9.6 m/s (7.4 × 1.30 lúc cất vũ khí), tức còn gần BẢY GIÂY.
	#     Hàng chờ rút hết trong khoảng một phần năm giây, nên hoãn là miễn phí.
	#   • dịch chuyển — nhảy cảnh, hồi sinh ở bia, du hành, nạp save. Ô dưới
	#     chân biến mất NGAY, và hoãn lúc đó là rơi xuyên xuống vực.
	# Nên: hở đất thì dựng hết tại chỗ, còn lại thì xếp hàng.
	if not _o_dang_co.has(o):
		nap_het()

## Rút hàng chờ theo ngân sách. Luôn làm ÍT NHẤT một bước — không có luật đó
## thì một khung hình nặng sẵn sẽ đẩy hàng chờ sang khung sau mãi mãi.
func _chay_hang() -> void:
	if _hang_dat.is_empty() and _hang_prop.is_empty():
		return
	var han := Time.get_ticks_usec() + int(NGAN_SACH_MS * 1000.0)
	while true:
		if not _hang_dat.is_empty():
			_dung_dat(_hang_dat.pop_front())
		elif not _hang_prop.is_empty():
			_rai_prop(_hang_prop.pop_front())
		else:
			return
		if Time.get_ticks_usec() >= han:
			return

func _dung_dat(k: Vector2i) -> void:
	var o := dia_hinh.dung_o(k.x, k.y)
	dia_hinh.add_child(o)
	_o_dang_co[k] = o
	_hang_prop.append(k)

func _rai_prop(k: Vector2i) -> void:
	var o: Node3D = _o_dang_co.get(k)
	if o == null or not is_instance_valid(o):
		return          # ô bị huỷ mất giữa lúc còn nằm trong hàng
	RaiVat.rai(o, dia_hinh, k.x, k.y, _v)

## Dựng hết những gì đang chờ, NGAY LẬP TỨC.
##
## Hai bên gọi, và cả hai đều không đợi được: chỗ hở đất dưới chân người chơi
## ở `_xep_hang()`, và bộ kiểm tra — nó dịch chuyển người chơi rồi đo ngay ở
## khung sau, đúng kiểu "dịch chuyển" mà hàng chờ cố ý không phục vụ.
func nap_het() -> void:
	while not _hang_dat.is_empty():
		_dung_dat(_hang_dat.pop_front())
	while not _hang_prop.is_empty():
		_rai_prop(_hang_prop.pop_front())

## Bao nhiêu ô địa hình đang nạp. Dùng cho bộ kiểm tra.
func so_o_dang_co() -> int:
	return _o_dang_co.size()

## Bao nhiêu BƯỚC còn nằm trong hàng chờ. Dùng cho bộ kiểm tra.
##
## Ô chưa có đất tốn HAI bước (dựng đất, rồi rải prop), ô đã có đất tốn một.
## Cộng thẳng hai mảng lại là đếm sai: dựng xong đất một ô chỉ chuyển nó từ
## mảng này sang mảng kia, nên con số đứng im trong khi việc vẫn đang chạy —
## và một phép thử "mỗi khung rút được ít nhất một bước" sẽ đỏ oan vì thế.
func so_buoc_cho() -> int:
	return _hang_dat.size() * 2 + _hang_prop.size()

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
