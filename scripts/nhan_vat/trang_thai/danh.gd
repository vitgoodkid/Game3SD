extends TTNguoiChoi

## Đánh. Đây là chỗ "cam kết đòn đánh" (mục 5.1) thật sự được thi hành.
##
## Mỗi đòn chia ba khung, đọc thẳng từ data/moveset.csv:
##
##   │─── vung tay ───│── gây sát thương ──│──── hồi ────│
##      t_vung           t_dam_tu→t_dam_den    t_hoi
##      người chơi       hộp đòn BẬT          không huỷ được
##      nhìn và né                            → cửa sổ phản đòn
##
## Khung "hồi" là chỗ đối phương phản đòn. Cắt ngắn nó đi thì trận đánh thành
## hack-n-slash. Cho huỷ nó bằng cách lăn thì cũng vậy. Nên cho_doi() ở dưới
## chặn gần như mọi thứ — đó là cả mục đích của file này.
##
## ĐÁNH KHÔNG TỐN THỂ LỰC (xem "Cái gì tốn thể lực" trong souls_like.gd). Thứ
## ghìm nhịp đòn đánh là cam kết đòn + khung hồi ở trên, không phải thanh thể
## lực. Cột `the_luc` của moveset.csv vì vậy hiện không ai đọc.
##
## Nhẹ hay nặng là do GIỮ CHUỘT TRÁI lâu hay không, không phải hai nút khác
## nhau: nc.dang_giu_danh() còn true nghĩa là người chơi vẫn đang giữ, và đòn
## nặng nạp tiếp thành đòn nạp.

var _don := "nhe_1"
var _m := {}
var _chu_mv := "拳"
var _da_bat := false     ## hộp đòn đã bật trong đòn này chưa
var _da_tat := false
var _nap := false        ## còn giữ chuột trái để nạp tiếp thành đòn nạp
var _t_nap := 0.0
## Đã đệm sẵn đòn kế tiếp của combo chưa.
var _noi := ""

const T_NAP_TOI_DA := 1.1

func vao(du_lieu: Dictionary = {}) -> void:
	_don = String(du_lieu.get("don", "nhe_1"))
	_chu_mv = Tui.moveset_dang_dung()
	_m = VocabDB.don_cua(_chu_mv, _don)
	_da_bat = false
	_da_tat = false
	_noi = ""
	# Đòn phản đỡ không nạp được — nó là một nhát dứt khoát, không phải đòn nặng.
	_nap = _don == "nang" and nc.dang_giu_danh()
	_t_nap = 0.0
	nc.dang_do = false
	nc.ton_the_luc(float(_m.get("the_luc", 15)))
	# Xoay về hướng đang nhắm NGAY lúc bắt đầu vung. Sau đó khoá cứng —
	# xoay được giữa đòn là cách nhanh nhất giết chết cảm giác souls.
	var h := nc.huong_nhap if nc.huong_nhap != Vector3.ZERO else nc.huong_mat()
	if nc.muc_tieu != null:
		h = nc.muc_tieu.global_position - nc.global_position
		h.y = 0.0
	if h.length_squared() > 0.001:
		nc.than.rotation.y = atan2(h.x, h.z)

func ra() -> void:
	nc.hop_don.monitoring = false
	nc.sieu_giap = 0.0

func chay(delta: float) -> void:
	# Bám chân tại chỗ: đòn đánh souls-like gần như không tự di chuyển, trừ
	# đòn chạy và đòn nhảy vốn mang sẵn quán tính.
	if _don in ["chay", "nhay"]:
		nc.dung_lai(delta, 6.0)
	else:
		nc.dung_lai(delta, 22.0)

	if _nap:
		_chay_nap(delta)
		return

	var t_vung := float(_m.get("t_vung", 0.2))
	var t_tu := float(_m.get("t_dam_tu", t_vung))
	var t_den := float(_m.get("t_dam_den", t_tu + 0.12))
	var t_het := t_den + float(_m.get("t_hoi", 0.5))

	# Bật hộp đòn đúng khung gây sát thương. Trong bản có model thật thì việc
	# này sẽ do animation track gọi (mục 9); ở đây dùng mốc thời gian trong
	# CSV, và CSV chính là thứ animation track sẽ đọc lại — nên đổi engine
	# animation không phải sửa lại cân bằng.
	# SIÊU GIÁP bật từ lúc bắt đầu vung tới hết khung gây sát thương, rồi TẮT
	# trong khung hồi. Elden Ring đặt đúng như vậy, và chỗ tắt mới là chỗ quan
	# trọng: khung hồi phải ăn đòn bình thường, nếu không thì vung vũ khí nặng
	# là bất khả xâm phạm và cả trận đánh mất hết rủi ro.
	nc.sieu_giap = float(_m.get("sieu_giap", 0)) if t < t_den else 0.0

	if not _da_bat and t >= t_tu:
		_bat_hop_don()
	if _da_bat and not _da_tat and t >= t_den:
		_tat_hop_don()

	# Đệm đòn kế tiếp trong lúc đang hồi → nối combo cho mượt.
	if t >= t_den and _noi == "":
		_thu_noi()

	if t >= t_het:
		if _noi != "":
			di("danh", {"don": _noi})
		else:
			di("dung")

func _chay_nap(delta: float) -> void:
	_t_nap += delta
	if not nc.dang_giu_danh() or _t_nap >= T_NAP_TOI_DA:
		# Nhả sớm thì ra đòn nặng thường, giữ đủ lâu thì ra đòn nạp.
		var ra_don := "nang_nap" if _t_nap >= T_NAP_TOI_DA * 0.55 else "nang"
		_nap = false
		_don = ra_don
		_m = VocabDB.don_cua(_chu_mv, ra_don)
		# Giữ đủ lâu thành đòn nạp thì tiêu thêm — ER cũng tính đòn nạp đắt hơn.
		if ra_don == "nang_nap":
			nc.ton_the_luc(float(_m.get("the_luc", 30)) * 0.4)
		may.t = 0.0

func _thu_noi() -> void:
	var combo := VocabDB.combo_nhe(_chu_mv)
	var i := combo.find(_don)
	if nc.co_dem("don_nhe") and i >= 0 and i + 1 < combo.size():
		nc.lay_dem("don_nhe")
		_noi = String(combo[i + 1])
	elif nc.co_dem("don_nang"):
		nc.lay_dem("don_nang")
		_noi = "nang"

func _bat_hop_don() -> void:
	_da_bat = true
	var hd := nc.hop_don as VuKhiHopDon
	hd.dat_don(_chu_mv, _don, nc)
	nc.hop_don.monitoring = true

func _tat_hop_don() -> void:
	_da_tat = true
	nc.hop_don.monitoring = false

func tien_do() -> float:
	if _nap:
		return clampf(_t_nap / T_NAP_TOI_DA, 0.0, 1.0) * 0.35
	var t_den := float(_m.get("t_dam_den", 0.3))
	var het := t_den + float(_m.get("t_hoi", 0.5))
	return clampf(t / maxf(het, 0.01), 0.0, 1.0)

## CAM KẾT ĐÒN ĐÁNH. Đã vung là không huỷ.
##
## Đây là một dòng code, và nó là thứ phân biệt souls-like với hack-n-slash.
## Mọi thứ khác trong repo này — thể lực, i-frame, ngũ hành, chữ Hán — đều
## vô nghĩa nếu người chơi bấm lăn giữa đòn là thoát được hậu quả.
func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "danh", "dung"]

## Đang vung thì không hồi thể lực (Elden Ring). Hồi lại ngay giữa đòn là mất
## hết sức ép của việc "tiêu bao nhiêu cho nhát này".
func cho_hoi_the_luc() -> bool:
	return false
