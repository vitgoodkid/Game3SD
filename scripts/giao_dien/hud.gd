extends CanvasLayer

## HUD. Vẽ bằng _draw() thay vì dựng cây Control trong editor — sửa được từ
## điện thoại mà không cần mở editor, và bố cục theo góc màn hình thì viết ra
## toạ độ ngắn hơn là kéo anchor.
##
## Bốn thứ ở đây là YÊU CẦU BẮT BUỘC của mục 8 (camera ba chế độ), không phải
## trang trí — đừng gỡ khi dọn giao diện:
##   - chỉ báo hướng bị đánh (vệt đỏ rìa màn hình) — không có thì góc nhìn
##     thứ nhất không chơi được, vì không thấy đòn từ sau lưng
##   - mũi tên chỉ mục tiêu đang khoá khi ở góc nhìn thứ nhất
##   - chấm ngắm mờ ở đúng tầm với vũ khí đang cầm
##   - tên chế độ camera khi vừa bấm F5
##
## BỐ CỤC (theo bản mẫu chủ dự án đưa):
##
##   trái trên    khung nhân vật — tên vũ khí, tải trọng, thanh TƯ THẾ
##   giữa trên    thanh máu BOSS, rộng 44% bề ngang
##   phải trên    minimap
##   giữa dưới    thanh kỹ năng, và THANH THỂ LỰC ngay trên nó
##   trái dưới    quả cầu ĐỎ — máu
##   phải dưới    quả cầu XANH — MP
##
## Vì sao thể lực là THANH chứ không phải quả cầu thứ ba: nó đảo quá nhanh.
## Máu và MP tụt từng nấc và ở lại đó, mắt liếc một cái là đọc được; thể lực
## thì mỗi cú lăn rút một phần ba rồi đầy lại trong một giây. Nhồi nhịp đó vào
## một quả cầu tròn thì nó nhấp nháy suốt trận và không ai đọc nổi. Thanh ngang
## ngay trên thanh kỹ năng đọc được bằng khoé mắt, đó là chỗ đúng của nó.

# --- Nút vặn bố cục -------------------------------------------------
#
# MỌI con số bố cục là `@export`, cố ý. HUD vẽ bằng `_draw()` nên Godot không
# hiện nó ra thành cây node kéo thả được; nhóm export này là cách duy nhất
# chỉnh được bằng tay mà không phải mở file code.
#
# CHỈNH SỐNG, không cần biên dịch lại:
#   1. F5 chạy game
#   2. trong editor: dock Scene → tab **Remote** (cạnh tab Local)
#   3. chọn node `HUD`, kéo mấy con số dưới đây trong Inspector
#   4. thấy đổi NGAY trên cửa sổ game
#   5. ưng rồi thì chép con số đó sang tab **Local** cho nó sống qua lần sau
#
# Bước 5 là bước hay quên: sửa ở tab Remote chỉ sống trong phiên chạy đó.

@export_group("Quả cầu")
## Bán kính quả cầu máu / MP.
@export var cau_ban_kinh := 92.0
## Đáy quả cầu cách đáy màn hình bấy nhiêu.
##
## Để nhỏ là cố ý: ảnh khung quả cầu còn một vành trong suốt quanh mép, nên
## phần NHÌN THẤY của nó đã tự lùi vào vài pixel rồi.
@export var cau_le := 2.0
## Hở giữa mép thanh kỹ năng và mép quả cầu.
@export var cau_cach := 10.0
## Khung quả cầu thò ra ngoài bán kính bao nhiêu PHẦN (không phải pixel).
@export var cau_vien := 0.07
## Xê dịch riêng cái KHUNG so với mực nước, tính bằng pixel. Dương = sang phải
## / xuống dưới.
##
## Có nút này vì ảnh khung và ảnh nước là hai file khác nhau, vẽ ở hai cỡ khác
## nhau, và tâm "lòng kính" của ảnh khung không nhất thiết trùng tâm ảnh. Không
## có cách nào tính ra con số đúng — phải nhìn rồi nhích.
@export var cau_vien_lech := Vector2.ZERO

@export_group("Thanh kỹ năng")
@export var so_o := 10
@export var o_co := 52.0
@export var o_cach := 6.0
## Ảnh nền cao bằng bấy nhiêu lần bán kính quả cầu.
##
## Đừng kéo tới 2.0 (đúng bằng đường kính cầu): nội dung thật trong nền chỉ có
## thanh thể lực + một hàng ô, cộng lại ~80px, nên nền cao bằng cầu là để thừa
## một khoảng trống rộng ngoác phía dưới hàng ô.
@export var nen_cao_theo_cau := 1.25
## Ảnh nền rộng hơn hàng ô bấy nhiêu pixel (chừa chỗ vệt cọ hai đầu).
@export var nen_rong_them := 150.0
## Hàng ô cách đáy ảnh nền bấy nhiêu.
@export var nen_le_duoi := 16.0

@export_group("Minimap")
## HUD đẩy mấy con số này xuống Minimap mỗi khung — Minimap tạo bằng code nên
## tự nó không có mặt trong Inspector.
##
## Bán kính tính Ở CHIỀU CAO THAM CHIẾU (1080px). Cửa sổ cao hơn hay thấp hơn
## thì bán kính co giãn theo, nên minimap chiếm đúng một phần màn hình như nhau
## ở mọi cỡ cửa sổ — kéo cửa sổ nhỏ lại không làm nó nuốt mất góc màn hình.
@export var minimap_ban_kinh := 215.0
## Quét quanh người chơi bao nhiêu MÉT. Đây là con số của thế giới, không phải
## của màn hình, nên nó KHÔNG co giãn theo cửa sổ.
@export var minimap_tam_quet := 55.0
## Cách mép màn hình bấy nhiêu, cũng tính ở chiều cao tham chiếu.
@export var minimap_le := 18.0

@export_group("Thanh máu boss")
## Rộng bằng bấy nhiêu PHẦN bề ngang màn hình.
@export var boss_rong := 0.44
@export var boss_cao := 16.0
## Cách đỉnh màn hình bấy nhiêu pixel.
@export var boss_le_tren := 80.0
## Cỡ chữ tên boss.
@export var boss_co_chu := 26

@export_group("Khung nhân vật")
## Phóng to / thu nhỏ CẢ khung: ảnh nền, ảnh mặt, chữ, thanh tư thế.
@export var khung_nv_co := 1.0
## Góc trên trái của khung, tính bằng pixel.
@export var khung_nv_tai := Vector2(28, 28)

const MAU_MAU := Color(0.72, 0.16, 0.18)
const MAU_MAU_NEN := Color(0.16, 0.08, 0.08, 0.85)
const MAU_TL := Color(0.38, 0.66, 0.34)
const MAU_MP := Color(0.24, 0.48, 0.86)

## Màu TÔ quả cầu — khác hẳn hai màu trên, và phải khác.
##
## Ảnh nước của bộ asset là xám mức ~0.52, mà modulate thì NHÂN. Tô nó bằng
## đúng màu muốn thấy là ra một màu tối hơn một nửa — đó là lý do quả cầu lúc
## đầu trông như máu khô chứ không như trong bản mẫu. Nên hai màu này đã chia
## sẵn cho 0.52, và vì thế có thành phần > 1.0 (Godot cho phép, nó chỉ là hệ số
## nhân). Đổi màu ở đây thì nhớ chia lại, đừng chép màu từ bảng trên xuống.
const MAU_CAU_MAU := Color(1.58, 0.28, 0.22)
const MAU_CAU_MP := Color(0.26, 0.82, 1.72)
const MAU_TU_THE := Color(0.92, 0.74, 0.28)
const MAU_CHU := Color(0.94, 0.92, 0.86)

var nc: NguoiChoi = null
var _ve: Control = null
var _bao: Label = null
var _t_bao := 0.0
## Hướng vừa bị đánh từ đâu tới, và còn hiện bao lâu.
var _huong_danh: Array = []
## Máu "trễ" — thanh trắng tụt chậm phía sau, cho thấy vừa mất bao nhiêu.
var _mau_tre := 1.0
## Boss đang đánh nhau với mình. Thanh máu của nó nằm dưới đáy màn hình, kiểu
## souls — to, một thanh duy nhất, tên chữ Hán ở trên.
var _boss: Boss = null
var _boss_tre := 1.0
## Minimap là node con thật (nó tự _draw), không vẽ chung trong _ve_het.
var _minimap: Minimap = null

func _ready() -> void:
	layer = 10
	# Bia đá, món đồ rơi, vũng hồn đều nhắn qua đây. Tìm bằng nhóm chứ không
	# bằng đường dẫn node, để đặt HUD ở đâu trong scene cũng được.
	add_to_group("hud")
	_ve = Control.new()
	_ve.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ve.draw.connect(_ve_het)
	add_child(_ve)

	_bao = Label.new()
	_bao.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# Đặt dưới chỗ thanh máu boss ngồi (đỉnh giữa), không thì hai thứ đè nhau
	# đúng lúc đang đánh boss — tức là đúng lúc cần đọc cả hai nhất.
	_bao.position = Vector2(-220, 136)
	_bao.custom_minimum_size = Vector2(440, 0)
	_bao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bao.modulate = Color(1, 1, 1, 0)
	# Dòng thông báo hay có chữ Hán (tên boss, giải thích ngũ hành) — không gán
	# font thì nó ra ô vuông, xem GiaoDien._dat_theme().
	GiaoDien.ap_theme(_bao)
	add_child(_bao)

	_minimap = Minimap.new()
	# Minimap tự đặt chỗ mỗi khung theo cỡ viewport (xem Minimap._process) —
	# ở đây chỉ việc gắn nó vào.
	add_child(_minimap)

	await get_tree().process_frame
	_tim_nguoi_choi()

func _tim_nguoi_choi() -> void:
	nc = get_tree().get_first_node_in_group("nguoi_choi") as NguoiChoi
	if nc == null:
		return
	if _minimap != null:
		_minimap.nc = nc
	nc.bao_ngu_hanh.connect(bao)
	nc.bi_danh.connect(bi_danh_tu)
	var cam := nc.get_node_or_null("GiaCamera") as CameraBaCheDo
	if cam != null:
		cam.doi_che_do.connect(func(_c): bao(cam.ten_che_do()))

func _process(delta: float) -> void:
	if nc == null:
		_tim_nguoi_choi()
		return
	var ti := nc.mau / maxf(nc.mau_toi_da, 1.0)
	_mau_tre = maxf(ti, _mau_tre - delta * 0.35)
	if _mau_tre < ti:
		_mau_tre = ti
	_tut_mau_boss(delta)

	for i in range(_huong_danh.size() - 1, -1, -1):
		_huong_danh[i]["t"] = float(_huong_danh[i]["t"]) - delta
		if float(_huong_danh[i]["t"]) <= 0.0:
			_huong_danh.remove_at(i)

	if _t_bao > 0.0:
		_t_bao -= delta
		_bao.modulate.a = clampf(_t_bao, 0.0, 1.0)

	if _minimap != null:
		# Đẩy mỗi khung, không đặt một lần: kéo con số trong Inspector tab
		# Remote lúc game đang chạy phải thấy đổi NGAY, không thì nút vặn coi
		# như không có.
		var hs := _he_so_man()
		_minimap.ban_kinh = minimap_ban_kinh * hs
		_minimap.tam_quet = minimap_tam_quet
		_minimap.le_man = minimap_le * hs
	_ve.queue_redraw()

## Hiện một dòng thông báo ngắn giữa trên màn hình (ngũ hành, đổi camera...).
## Thanh trắng của boss tụt chậm phía sau, y như của người chơi — đó là thứ
## cho thấy cú vừa rồi ăn được bao nhiêu trên một thanh máu rất dài.
func _tut_mau_boss(delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var ti := _boss.mau / maxf(_boss.mau_toi_da, 1.0)
	_boss_tre = maxf(ti, _boss_tre - delta * 0.28)

func bao(dong: String) -> void:
	if dong.strip_edges().is_empty():
		return
	_bao.text = dong
	_t_bao = 2.2
	_bao.modulate.a = 1.0

## Gọi khi ăn đòn — vẽ vệt đỏ ở rìa màn hình về phía nguồn đòn.
## BẮT BUỘC ở góc nhìn thứ nhất, nơi không thấy gì phía sau lưng (mục 8).
func bi_danh_tu(vi_tri: Vector3) -> void:
	if nc == null:
		return
	var v := vi_tri - nc.global_position
	v.y = 0.0
	_huong_danh.append({"huong": v.normalized(), "t": 1.1})

# --- Vẽ -------------------------------------------------------------

func _ve_het() -> void:
	if nc == null:
		return
	var co := _ve.size
	var k := _khung_duoi(co)

	_ve_khung_nhan_vat(co)
	_ve_thanh_ky_nang(co, k)
	_ve_cau(k["trai"], nc.mau / maxf(nc.mau_toi_da, 1.0), MAU_CAU_MAU, _mau_tre)
	_ve_cau(k["phai"], nc.mp / maxf(nc.mp_toi_da, 1.0), MAU_CAU_MP)

	_ve_thanh_boss(co)
	_ve_vet_bi_danh(co)
	var cam := nc.get_node_or_null("GiaCamera") as CameraBaCheDo
	if cam != null and cam.la_thu_nhat():
		if bool(CaiDat.lay("hien_cham_ngam")):
			_ve_cham_ngam(co)
		_ve_mui_ten_muc_tieu(co, cam)

## Chiều cao màn hình mà mọi con số pixel của minimap được khai theo.
const CAO_THAM_CHIEU := 1080.0

## Hệ số co giãn theo cỡ cửa sổ.
##
## Lấy theo CHIỀU CAO chứ không phải chiều rộng: màn siêu rộng (21:9) thì chiều
## rộng nhảy vọt mà chiều cao gần như không đổi, và một thứ nằm ở góc thì phải
## bám chiều cao mới giữ đúng cỡ so với những gì người chơi thật sự thấy.
func _he_so_man() -> float:
	var cao := _ve.size.y if _ve != null else 0.0
	if cao < 1.0:
		return 1.0
	return cao / CAO_THAM_CHIEU

# --- Cụm dưới màn hình ----------------------------------------------

## Nửa chiều cao THẬT của khung quả cầu, tính bằng pixel.
##
## Ảnh khung 326×308 KHÔNG vuông, nên nửa chiều cao KHÁC bán kính. Bản trước
## nhét ảnh vào một ô vuông — kéo giãn dọc 6%, vành dày lên và lệch hẳn so với
## mực nước. Giữ đúng tỉ lệ ảnh thì phải hỏi lại chiều cao ở đây, vì _khung_duoi()
## cần nó để canh đáy cụm cho khớp.
func _cau_nua_cao() -> float:
	var khung := GiaoDien.anh("Action Bar/Globes/ActionBar_Globe_Background.png")
	var ty := 1.0
	if khung != null and khung.get_width() > 0:
		ty = float(khung.get_height()) / float(khung.get_width())
	return cau_ban_kinh * (1.0 + cau_vien) * ty

## Toạ độ của cả cụm cầu–thanh–cầu. Tính MỘT chỗ rồi chuyền đi, vì ba thứ đó
## phải canh theo nhau: đổi cỡ quả cầu mà thanh kỹ năng không biết thì chúng
## rời nhau ra, và không có test nào bắt được chuyện đó.
func _khung_duoi(co: Vector2) -> Dictionary:
	var rong := so_o * o_co + (so_o - 1) * o_cach
	# MỘT TÂM CHUNG cho cả ba: quả cầu, hàng ô và ảnh nền đều canh giữa theo
	# `giua_y`. Quả cầu là thứ cao nhất nên nó quyết định tâm đó nằm đâu — đặt
	# sao cho đáy cầu vừa đúng cách đáy màn hình cau_le.
	#
	# Canh theo ĐÁY (bản trước) thì về con số là khớp mà nhìn vẫn sai: cầu cao
	# gấp ba hàng ô nên nó dồn hết lên trên, đọc ra như hai quả bóng treo cạnh
	# một cái thanh thấp. Canh theo tâm thì ba thứ nằm cùng một dải.
	var rong_nen := rong + nen_rong_them
	var cao_nen := cau_ban_kinh * nen_cao_theo_cau
	var giua_y := co.y - cau_le - _cau_nua_cao() - maxf(cau_vien_lech.y, 0.0)
	# Hàng ô dính ĐÁY ảnh nền, không nằm giữa nó: phía trên hàng ô còn phải
	# chứa thanh thể lực, phía dưới thì không chứa gì cả. Đặt nó vào giữa nền
	# là để thừa một khoảng trống rộng ngoác bên dưới.
	var y := giua_y + cao_nen * 0.5 - nen_le_duoi - o_co
	var x := (co.x - rong) * 0.5
	return {
		"x": x, "y": y, "rong": rong, "giua_y": giua_y,
		"rong_nen": rong_nen, "cao_nen": cao_nen,
		"trai": Vector2(x - cau_cach - cau_ban_kinh, giua_y),
		"phai": Vector2(x + rong + cau_cach + cau_ban_kinh, giua_y),
	}

# --- Quả cầu máu / MP -----------------------------------------------

## Một quả cầu. `ti` là phần còn lại (0-1).
##
## KHÔNG có con số ở giữa — bản mẫu không có, và souls cũng không. Mức nước
## CHÍNH LÀ số liệu: đọc "còn một phần ba" bằng khoé mắt nhanh hơn đọc "130",
## vì "130" chỉ có nghĩa khi còn nhớ trần là bao nhiêu. Muốn số thì thêm lại
## một dòng draw_string ở cuối hàm này.
##
## Phần nước dâng lên bằng cách CẮT ẢNH theo chiều dọc — lấy đúng dải dưới của
## ảnh fill rồi dán vào đúng dải dưới của quả cầu. Kéo giãn cả ảnh cho thấp
## xuống thì nước bị bẹp và trông như một cái đĩa, không như một quả cầu vơi.
func _ve_cau(tam: Vector2, ti: float, mau: Color, tre: float = -1.0) -> void:
	var r := cau_ban_kinh
	var o := Rect2(tam - Vector2(r, r), Vector2(r * 2, r * 2))
	var nuoc := GiaoDien.anh("Action Bar/Globes/ActionBar_Globe_Fill.png")
	var khung := GiaoDien.anh("Action Bar/Globes/ActionBar_Globe_Background.png")

	# THỨ TỰ QUAN TRỌNG: nền (cái ly rỗng) trước, nước sau. Bộ asset này không
	# có ảnh "vành" riêng — "Background" là cái ly tối màu và nó ĐỤC, nên vẽ nó
	# sau cùng là nó phủ kín mực và quả cầu lúc nào cũng trông như đang cạn.
	_ve.draw_circle(tam, r * 0.94, Color(0.05, 0.05, 0.06, 0.9))
	if khung != null:
		# GIỮ ĐÚNG TỈ LỆ ẢNH. Ảnh 326×308 nhét vào ô vuông là giãn dọc 6%, lòng
		# kính méo theo và nước thôi khớp vành — đó đúng là lỗi chủ dự án báo.
		var rong_k := r * 2.0 * (1.0 + cau_vien)
		var cao_k := rong_k * khung.get_height() / khung.get_width()
		var tam_k := tam + cau_vien_lech
		_ve.draw_texture_rect(khung,
			Rect2(tam_k - Vector2(rong_k, cao_k) * 0.5, Vector2(rong_k, cao_k)),
			false)
	# Vệt "vừa mất bao nhiêu": mực trắng mờ tụt chậm phía sau mực thật.
	if tre >= 0.0 and tre > ti:
		_nuoc(o.grow(-r * 0.10), nuoc, tre, Color(0.86, 0.84, 0.80, 0.40))
	_nuoc(o.grow(-r * 0.10), nuoc, ti, mau)
	if khung == null:
		_ve.draw_arc(tam, r, 0.0, TAU, 48, GiaoDien.VIEN, 3.0, true)

func _nuoc(o: Rect2, tex: Texture2D, ti: float, mau: Color) -> void:
	var t := clampf(ti, 0.0, 1.0)
	if t <= 0.001:
		return
	if tex == null:
		_ve.draw_rect(Rect2(o.position.x, o.position.y + o.size.y * (1.0 - t),
			o.size.x, o.size.y * t), mau)
		return
	var kt := tex.get_size()
	var nguon := Rect2(0, kt.y * (1.0 - t), kt.x, kt.y * t)
	var dich := Rect2(o.position.x, o.position.y + o.size.y * (1.0 - t),
		o.size.x, o.size.y * t)
	_ve.draw_texture_rect_region(tex, dich, nguon, mau)

# --- Thanh kỹ năng và thanh thể lực ---------------------------------

func _ve_thanh_ky_nang(co: Vector2, k: Dictionary) -> void:
	var rong: float = k["rong"]
	var x: float = k["x"]
	var y: float = k["y"]

	# Ảnh nền cùng TÂM với quả cầu và cao theo nó — xem nen_cao_theo_cau.
	var nen := GiaoDien.anh("Action Bar/ActionBar_Background.png")
	if nen != null:
		var rong_nen: float = k["rong_nen"]
		var cao_nen: float = k["cao_nen"]
		_ve.draw_texture_rect(nen,
			Rect2((co.x - rong_nen) * 0.5, float(k["giua_y"]) - cao_nen * 0.5,
				rong_nen, cao_nen),
			false, Color(1, 1, 1, 0.95))

	# THANH THỂ LỰC — ngay trên thanh kỹ năng, luôn hiện.
	#
	# Trước đây nó nằm chồng dưới thanh máu ở góc trái trên, chung một cột với
	# hai thanh khác, và ở đó thì không ai thấy: mắt người chơi souls bám giữa
	# màn hình và bám con quái, không bám góc trái. Đưa xuống giữa dưới là đưa
	# nó vào đúng chỗ mắt đã nhìn sẵn.
	_thanh_anh(Vector2(x + 20.0, y - 26.0), rong - 40.0,
		nc.the_luc / maxf(nc.the_luc_max, 1.0), MAU_TL, 16.0)

	var f := GiaoDien.chu_than if GiaoDien.chu_than != null else ThemeDB.fallback_font
	var khung := GiaoDien.anh("Action Bar/Slot/ActionBar_Slot_Frame.png")
	for i in so_o:
		var ox := x + float(i) * (o_co + o_cach)
		var o := Rect2(ox, y, o_co, o_co)
		_ve.draw_rect(o, Color(0.06, 0.06, 0.07, 0.72))
		_noi_dung_o(i, o, f)
		if khung != null:
			_ve.draw_texture_rect(khung, o.grow(4.0), false)
		else:
			_ve.draw_rect(o, GiaoDien.VIEN, false, 2.0)
		# Số phím ở góc trên trái mỗi ô. Ô thứ 10 là phím 0.
		_ve.draw_string(f, Vector2(ox + 4.0, y + 14.0), str((i + 1) % 10),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.70, 0.66))

## Nội dung của một ô. Hai ô đầu có thật, còn lại để trống — thanh kỹ năng là
## cái khung cho hệ phép (chưa có) và đồ tiêu hao (chưa có) cắm vào sau.
## Vẽ ô trống chứ không giấu đi: người chơi phải thấy chỗ trống để biết là còn
## thứ gì đó sẽ lấp vào.
func _noi_dung_o(i: int, o: Rect2, f: Font) -> void:
	var giua := o.position + o.size * 0.5
	match i:
		0:
			# Bình thuốc — phím 1, đúng phím uong_binh.
			var het := Tui.binh_con <= 0
			_ve.draw_string(f, Vector2(o.position.x, giua.y + 4.0), "瓶",
				HORIZONTAL_ALIGNMENT_CENTER, o.size.x, 24,
				Color(0.55, 0.52, 0.50) if het else Color(0.95, 0.82, 0.45))
			_ve.draw_string(f, Vector2(o.position.x, o.end.y - 5.0),
				"%d/%d" % [Tui.binh_con, Tui.binh_toi_da],
				HORIZONTAL_ALIGNMENT_CENTER, o.size.x, 12, MAU_CHU)
		1:
			# Vũ khí đang cầm. Hiện theo luật ??? như mọi chỗ khác — chữ chưa
			# đọc được thì ra □, và ô này không được phá lệ đó.
			var vk = Tui.vu_khi_dang_cam()
			var ten := "拳" if vk == null else vk.ten_hien()
			_ve.draw_string(f, Vector2(o.position.x, giua.y + 8.0),
				ten.substr(0, 2), HORIZONTAL_ALIGNMENT_CENTER, o.size.x, 22, MAU_CHU)

func _thanh_anh(tai: Vector2, rong: float, ti: float, mau: Color, cao: float) -> void:
	var day := GiaoDien.anh("XP Bar/XPBar_Fill.png")
	var o := Rect2(tai, Vector2(rong, cao))
	# Nền vẽ bằng rect chứ không bằng ảnh: ảnh nền của bộ này cao 36px, ép
	# xuống 16px thì vệt trang trí của nó nát thành một dải lem.
	_ve.draw_rect(o.grow(2.0), Color(0.04, 0.04, 0.05, 0.9))
	_ve.draw_rect(o.grow(2.0), Color(0.30, 0.25, 0.18, 0.9), false, 2.0)
	var t := clampf(ti, 0.0, 1.0)
	if t <= 0.001:
		return
	var trong := Rect2(tai, Vector2(rong * t, cao))
	if day != null:
		var kt := day.get_size()
		_ve.draw_texture_rect_region(day, trong, Rect2(0, 0, kt.x * t, kt.y), mau)
	else:
		_ve.draw_rect(trong, mau)

# --- Khung nhân vật góc trái trên ------------------------------------

## Khung nhân vật góc trái trên: ảnh mặt, tên vũ khí, tải trọng, hồn, tư thế.
##
## MỌI con số ở đây nhân với `khung_nv_co`, kể cả cỡ chữ. Phóng to mà chữ đứng
## yên thì chữ tràn ra ngoài khung — và đó là kiểu "chỉnh to nhỏ được" chỉ đúng
## một nửa, tệ hơn là không chỉnh được.
func _ve_khung_nhan_vat(_co: Vector2) -> void:
	var f := GiaoDien.chu_than if GiaoDien.chu_than != null else ThemeDB.fallback_font
	var k := khung_nv_co
	var x := khung_nv_tai.x
	var y := khung_nv_tai.y
	var nen := GiaoDien.anh("Unit Frames/UnitFrame_Background.png")
	if nen != null:
		var rn := 320.0 * k
		_ve.draw_texture_rect(nen,
			Rect2(x - 10.0 * k, y - 12.0 * k, rn,
				rn * nen.get_height() / nen.get_width()),
			false, Color(1, 1, 1, 0.92))

	var vk = Tui.vu_khi_dang_cam()
	var ten := "拳 (tay không)" if vk == null else vk.ten_hien()
	_ve.draw_string(f, Vector2(x + 62.0 * k, y + 20.0 * k), ten,
		HORIZONTAL_ALIGNMENT_LEFT, 230.0 * k, roundi(18 * k), MAU_CHU)
	var tai := Tui.muc_tai()
	_ve.draw_string(f, Vector2(x + 62.0 * k, y + 40.0 * k),
		"Tải: %s   ·   魂 %d" % [String(tai["ten"]), Tui.hon],
		HORIZONTAL_ALIGNMENT_LEFT, 230.0 * k, roundi(14 * k),
		Color(0.78, 0.76, 0.72))

	var mat := GiaoDien.anh("Unit Frames/Avatar/UnitFrame_Avatar_Background.png")
	if mat != null:
		_ve.draw_texture_rect(mat,
			Rect2(x - 6.0 * k, y - 10.0 * k, 62.0 * k, 62.0 * k), false)

	# Thanh TƯ THẾ chỉ hiện khi đang tích. Hiện thường trực thì nhiễu mắt, mà
	# nó chỉ có nghĩa lúc đang bị dồn — đầy là đứng ngây cho ăn đòn kết liễu.
	if nc.tu_the > 1.0:
		_thanh_anh(Vector2(x + 62.0 * k, y + 48.0 * k), 200.0 * k,
			nc.tu_the / maxf(nc.tu_the_max, 1.0), MAU_TU_THE, 9.0 * k)

## Nhận boss vào để vẽ thanh máu. Vùng nào có boss thì gọi lúc người chơi bước
## vào cửa; hạ xong thì gọi lại với null.
func theo_doi_boss(b: Boss) -> void:
	_boss = b
	_boss_tre = 1.0
	if b != null:
		var loi := b.loi_thoai()
		if loi != "":
			bao(loi)

func _ve_thanh_boss(co: Vector2) -> void:
	if _boss == null or not is_instance_valid(_boss) or not _boss.con_song():
		return
	var f := ThemeDB.fallback_font
	# ĐỈNH màn hình, giữa, rộng đúng một phần ba.
	#
	# Souls để thanh máu boss sát đáy, và bản này từng làm vậy — nhưng đáy giờ
	# là cụm cầu–thanh–cầu, và mỗi lần nới bán kính quả cầu là thanh boss lại
	# cắt ngang đỉnh hai quả cầu. Đưa lên đỉnh là gỡ hẳn sự ràng buộc đó: hai
	# cụm không còn tranh chỗ, nên đổi cỡ cụm dưới không đụng gì tới thanh boss.
	#
	# 44% bề ngang: đủ dài để đọc ra mình vừa ăn được bao nhiêu, chưa dài tới
	# mức một nhát chém trông như không ăn thua (boss nào cũng vài trăm máu).
	var rong := co.x * boss_rong
	var x := (co.x - rong) * 0.5
	var y := boss_le_tren
	var ti := _boss.mau / maxf(_boss.mau_toi_da, 1.0)

	# Tên hiện theo luật ???: chữ chưa đọc được thì hiện □. Boss vô danh là
	# một hình ảnh mạnh — và hạ xong thì `thuong_chu` dạy luôn mấy chữ đó.
	var ten := _boss.ten_hien()
	_ve.draw_string(f, Vector2(x, y - 10.0), ten,
		HORIZONTAL_ALIGNMENT_LEFT, -1, boss_co_chu, MAU_CHU)
	# Giai đoạn hai: vạch mốc trên thanh cho thấy nó đã qua ngưỡng.
	_thanh(Vector2(x, y), rong, boss_cao, ti, MAU_MAU, MAU_MAU_NEN, _boss_tre)
	var moc := _boss.nguong_gd2()
	if moc > 0.0 and moc < 1.0:
		var mx := x + rong * moc
		_ve.draw_line(Vector2(mx, y - 3.0), Vector2(mx, y + boss_cao + 3.0),
			Color(0.95, 0.85, 0.45, 0.9), 2.0)
	if _boss.giai_doan >= 2:
		_ve.draw_string(f, Vector2(x + rong - 46.0, y - 10.0), "二",
			HORIZONTAL_ALIGNMENT_LEFT, -1, boss_co_chu - 2, Color(0.95, 0.55, 0.42))

func _thanh(tai: Vector2, rong: float, cao: float, ti: float, mau: Color,
		nen: Color, tre: float = -1.0) -> void:
	var r := Rect2(tai, Vector2(rong, cao))
	_ve.draw_rect(r, nen)
	if tre >= 0.0 and tre > ti:
		_ve.draw_rect(Rect2(tai, Vector2(rong * tre, cao)), Color(0.85, 0.82, 0.78, 0.55))
	_ve.draw_rect(Rect2(tai, Vector2(rong * clampf(ti, 0.0, 1.0), cao)), mau)
	_ve.draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)

func _ve_vet_bi_danh(co: Vector2) -> void:
	if _huong_danh.is_empty() or nc == null:
		return
	var cam := nc.get_node_or_null("GiaCamera") as Node3D
	if cam == null:
		return
	var nhin := -cam.global_transform.basis.z
	nhin.y = 0.0
	nhin = nhin.normalized()
	var phai := nhin.cross(Vector3.UP).normalized() * -1.0
	var giua := co * 0.5
	var bk := minf(co.x, co.y) * 0.42

	for h in _huong_danh:
		var v: Vector3 = h["huong"]
		var goc := atan2(v.dot(phai), v.dot(nhin))
		var a := clampf(float(h["t"]) / 1.1, 0.0, 1.0)
		var tam := giua + Vector2(sin(goc), -cos(goc)) * bk
		# Cung tròn dày ở rìa, mờ dần — đọc được bằng khoé mắt mà không che hình.
		var diem: PackedVector2Array = []
		for i in 9:
			var g := goc + lerpf(-0.42, 0.42, float(i) / 8.0)
			diem.append(giua + Vector2(sin(g), -cos(g)) * bk)
		_ve.draw_polyline(diem, Color(0.92, 0.18, 0.16, a * 0.85), 7.0, true)
		_ve.draw_circle(tam, 4.0, Color(0.95, 0.3, 0.25, a))

## Chấm ngắm mờ ở đúng tầm với vũ khí đang cầm (mục 8). Không phải để bắn —
## để biết cây rìu với tới đâu khi không nhìn thấy tay mình.
func _ve_cham_ngam(co: Vector2) -> void:
	var m := VocabDB.don_cua(Tui.moveset_dang_dung(), "nhe_1")
	var tam := float(m.get("tam_voi", 2.0))
	var r := clampf(14.0 + tam * 3.0, 10.0, 46.0)
	var giua := co * 0.5
	_ve.draw_arc(giua, r, 0.0, TAU, 40, Color(0.92, 0.90, 0.86, 0.28), 1.6, true)
	_ve.draw_circle(giua, 2.0, Color(0.92, 0.90, 0.86, 0.45))

## Mũi tên rìa màn hình chỉ hướng mục tiêu — ở góc nhìn thứ nhất camera KHÔNG
## tự xoay về mục tiêu, nên không có mũi tên thì khoá mục tiêu vô dụng (mục 8).
func _ve_mui_ten_muc_tieu(co: Vector2, cam: CameraBaCheDo) -> void:
	if nc.muc_tieu == null or not is_instance_valid(nc.muc_tieu):
		return
	var v := nc.muc_tieu.global_position - nc.global_position
	v.y = 0.0
	var nhin := -cam.global_transform.basis.z
	nhin.y = 0.0
	nhin = nhin.normalized()
	var phai := nhin.cross(Vector3.UP).normalized() * -1.0
	var goc := atan2(v.normalized().dot(phai), v.normalized().dot(nhin))
	var giua := co * 0.5
	var bk := minf(co.x, co.y) * 0.34
	var tam := giua + Vector2(sin(goc), -cos(goc)) * bk
	var huong := (tam - giua).normalized()
	var ngang := Vector2(-huong.y, huong.x)
	_ve.draw_colored_polygon(PackedVector2Array([
		tam + huong * 13.0, tam - huong * 7.0 + ngang * 8.0,
		tam - huong * 7.0 - ngang * 8.0]), Color(0.96, 0.86, 0.45, 0.9))
