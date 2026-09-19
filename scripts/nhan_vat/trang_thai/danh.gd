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
var _giu_dinh := false   ## đã vung lên tới đỉnh và đang giữ ở đó
## Đòn này ra từ một cú nạp. Phần nhìn cần biết để vẽ cung vung TỪ ĐỈNH xuống
## chứ không vẽ lại từ đầu — tay đã giơ sẵn trên đó rồi.
var _tu_nap := false
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
	# CHỈ đòn "nang" dưới đất mới nạp được. Đòn phản đỡ là một nhát dứt khoát,
	# không phải đòn nặng; còn đòn nhảy nặng thì đang rơi — giữ để nạp giữa
	# không trung là thứ không có nghĩa, và nó sẽ đóng băng nhân vật lơ lửng.
	_nap = _don == "nang" and nc.dang_giu_danh()
	_giu_dinh = false
	_tu_nap = false
	_t_nap = 0.0
	nc.dang_do = false
	nc.ton_the_luc(float(_m.get("the_luc", 15)))
	# Tiếng vung tay là tiếng BÁO TRƯỚC — quái nghe được đòn của mình, và
	# người chơi nghe được đòn của quái khi mắt đang nhìn chỗ khác.
	# "nang" ở BẤT KỲ đâu trong tên, không chỉ ở đầu: "nhay_nang" cũng là một cú
	# vung nặng và phải nghe ra như vậy.
	AmThanh.phat("vung_nang" if "nang" in _don else "vung_nhe")
	_nham()

## Xoay về hướng đang nhắm. Gọi lúc bắt đầu vung, và gọi LẠI lúc nhả nạp —
## sau đó khoá cứng, vì xoay được giữa cú vung là cách nhanh nhất giết chết
## cảm giác souls. Nạp thì khác: cú vung chưa bắt đầu, nên nhắm lại là hợp lệ.
func _nham() -> void:
	var h := nc.huong_nhap if nc.huong_nhap != Vector3.ZERO else nc.huong_mat()
	if nc.muc_tieu != null:
		h = nc.muc_tieu.global_position - nc.global_position
		h.y = 0.0
	if h.length_squared() > 0.001:
		nc.than.rotation.y = atan2(h.x, h.z)

## Đòn này có GÃY khi bị đánh trúng không (cột `huy_duoc` của moveset.csv).
##
## Khác hẳn "không có siêu giáp". Không có siêu giáp nghĩa là thế đứng chỉ còn
## phần của tải trọng và 韧 — vẫn đủ nuốt một đòn vặt. Còn `huy_duoc` nghĩa là
## thế đứng bằng KHÔNG cho riêng đòn này: chạm là gãy, bất kể mặc giáp gì.
##
## Dùng cho đòn nặng của kiếm hai tay: sát thương ×2.95, vung 0.72 giây, và cái
## giá là suốt 0.72 giây đó ai chạm cũng cắt được. Đó là chỗ để con quái phản
## đòn, và là lý do người chơi phải chọn LÚC NÀO mới bổ.
func de_gay() -> bool:
	return int(_m.get("huy_duoc", 0)) != 0

func ra() -> void:
	nc.hop_don.monitoring = false
	nc.sieu_giap = 0.0

func chay(delta: float) -> void:
	# Bám chân tại chỗ: đòn đánh souls-like gần như không tự di chuyển, trừ
	# đòn chạy và đòn nhảy vốn mang sẵn quán tính.
	#
	# Ngoại lệ: ĐANG NẠP thì lết được, chậm hẳn (mục 5.1). Cú vung chưa bắt
	# đầu nên chưa có gì để cam kết — cam kết tính từ lúc NHẢ.
	if _nap and nc.huong_nhap != Vector3.ZERO:
		var tai := float(Tui.muc_tai()["toc_do"])
		nc.dat_toc_ngang(nc.huong_nhap,
			nc.toc_do_di * tai * SoulsLike.TOC_DO_KHI_NAP)
		nc.xoay_ve(nc.huong_nhap, delta)
	elif _don in ["chay", "nhay", "nhay_nang"]:
		nc.dung_lai(delta, 6.0)
	else:
		nc.dung_lai(delta, 22.0)

	var t_vung := float(_m.get("t_vung", 0.2))
	var t_tu := float(_m.get("t_dam_tu", t_vung))
	var t_den := float(_m.get("t_dam_den", t_tu + 0.12))
	var t_hoi := float(_m.get("t_hoi", 0.5))
	var t_het := t_den + t_hoi

	# SIÊU GIÁP bật từ lúc bắt đầu vung tới hết khung gây sát thương, rồi TẮT
	# trong khung hồi. Elden Ring đặt đúng như vậy, và chỗ tắt mới là chỗ quan
	# trọng: khung hồi phải ăn đòn bình thường, nếu không thì vung vũ khí nặng
	# là bất khả xâm phạm và cả trận đánh mất hết rủi ro.
	#
	# Tính cả lúc ĐANG NẠP — nạp mà ai chạm cũng cắt được thì không ai dám nạp,
	# và đòn nạp thành nút chết. ER cũng cho siêu giáp suốt khung giữ.
	#
	# TRỪ đòn có `huy_duoc` (xem `de_gay()`): đòn đó CỐ Ý không có giáp, kể cả
	# lúc nạp. Chủ dự án chốt như vậy cho đòn Bổ. Muốn trả giáp về thì sửa cột
	# `sieu_giap` trong `moveset.csv`, không phải sửa file này.
	nc.sieu_giap = float(_m.get("sieu_giap", 0)) if (_nap or t < t_den) else 0.0

	if _nap:
		_chay_nap(delta, t_vung)
		return

	# Bật hộp đòn đúng khung gây sát thương. Trong bản có model thật thì việc
	# này sẽ do animation track gọi (mục 9); ở đây dùng mốc thời gian trong
	# CSV, và CSV chính là thứ animation track sẽ đọc lại — nên đổi engine
	# animation không phải sửa lại cân bằng.
	if not _da_bat and t >= t_tu:
		_bat_hop_don()
	if _da_bat and not _da_tat and t >= t_den:
		_tat_hop_don()

	# XẢ BỘ ĐỆM theo đúng cửa sổ đang mở.
	#
	# Thứ tự trong khung hình này là MA TRẬN ƯU TIÊN, không phải thứ tự cửa sổ:
	# cửa sổ NÉ mở SAU cửa sổ NỐI, nhưng khi cả hai đã mở thì NÉ THẮNG — phòng
	# thủ trên tấn công. Nhờ vậy quãng giữa hai mốc vẫn là quãng chỉ nối được,
	# còn từ mốc né trở đi thì người chơi rút ra được kể cả khi đã lỡ bấm đánh.
	if cho_ne() and _huy_sang_thu():
		return
	if cho_noi():
		if _noi == "":
			_thu_noi()
		if _noi != "":
			_tat_hop_don()
			di("danh", {"don": _noi})
			return

	if t >= t_het:
		di("dung")

## Nạp đòn.
##
## VUNG TAY LÊN TRƯỚC, RỒI MỚI GIỮ. Bản đầu giữ ngay từ khung hình đầu tiên và
## chỉ bắt đầu vung SAU KHI nhả, nên bấm giữ là đứng đơ một nhịp rồi mới thấy
## động tác — đòn nặng cảm giác chậm hơn hẳn con số thật của nó. Elden Ring
## vung tay lên rồi giữ ở ĐỈNH; người chơi thấy ngay là mình đang nạp, và đối
## phương cũng thấy, nên nạp có rủi ro đọc được.
func _chay_nap(delta: float, t_vung: float) -> void:
	if t < t_vung:
		return          # còn đang vung tay lên, để timeline chạy bình thường
	# ĐẾM TỪ LÚC TỚI ĐỈNH, không đếm từ lúc bấm.
	#
	# Cú vung tay lên không phải là nạp — người chơi chưa giữ được gì trong
	# quãng đó, nó chạy hết bằng ấy giây dù có bấm hay không. Đếm cả nó vào
	# `T_NAP_TOI_DA` là lấy ngân sách nạp đi trả cho phần không ai điều khiển
	# được, và vũ khí nào vung tay càng lâu thì càng nạp được ít. Với 刃 —
	# vung tay 0.85s trên ngân sách 1.1s — chỉ còn 0.25s để giữ, tức là cú
	# gồng gần như không tồn tại. `muc_nap()` cũng đọc con số này, nên đếm sai
	# thì thanh báo nạp đầy sẵn ngay khi vừa tới đỉnh.
	_t_nap += delta
	may.t = t_vung      # tới đỉnh thì đóng băng, giữ nguyên đó
	_giu_dinh = true
	if nc.dang_giu_danh() and _t_nap < T_NAP_TOI_DA:
		return

	# Nhả sớm thì ra đòn nặng thường, giữ đủ lâu thì ra đòn nạp.
	var ra_don := "nang_nap" if _t_nap >= T_NAP_TOI_DA * 0.55 else "nang"
	_nap = false
	_giu_dinh = false
	_tu_nap = true
	if ra_don != _don:
		_don = ra_don
		_m = VocabDB.don_cua(_chu_mv, ra_don)
		# Giữ đủ lâu thành đòn nạp thì tiêu thêm — ER cũng tính đòn nạp đắt hơn.
		nc.ton_the_luc(float(_m.get("the_luc", 30)) * 0.4)
	# Lết quanh trong lúc nạp xong thì nhắm LẠI theo hướng đang đứng — chém ra
	# sau lưng vì lúc bắt đầu nạp đang quay hướng khác là lỗi cảm giác nặng.
	_nham()
	# Tay đã vung lên xong rồi, vào THẲNG khung gây sát thương — đừng bắt vung
	# lại từ đầu, đó đúng là chỗ làm đòn nặng dài gấp đôi cần thiết.
	may.t = float(_m.get("t_vung", t_vung))

## Rút ra khỏi cú đánh bằng lăn hoặc khiên. Trả về true nếu đã đổi state.
func _huy_sang_thu() -> bool:
	if nc.lay_dem("lan"):
		if nc.hoi_lan <= 0.0 and nc.du_the_luc():
			_tat_hop_don()
			di("lan")
			return true
		# Không đủ thể lực thì cú bấm coi như mất — giữ lại trong đệm thì nó
		# nổ ra muộn hơn, đúng lúc người chơi đã đổi ý.
		return false
	if Input.is_action_pressed("do_don") and nc.du_the_luc():
		_tat_hop_don()
		di("do_don")
		return true
	return false

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

## Đang nạp thì báo "nap" chứ không báo tên đòn: dáng nạp là dáng ĐỨNG GIỮ,
## khác hẳn dáng vung.
## Báo "nap" cho SUỐT cú nạp, kể cả lúc còn đang giơ tay lên.
##
## Bản đầu chỉ báo "nap" khi đã giữ tới đỉnh, còn lúc giơ lên thì báo "nang" —
## và thế là phần nhìn vẽ cung vung của đòn nặng ngay từ khung đầu. Tay quét
## tới trước 68° rồi GIẬT NGƯỢC về dáng giữ. Nhìn ra đúng như một đòn thường
## vung hụt trước khi đòn nặng bắt đầu, và đó là thứ người chơi báo lỗi.
func ten_dien() -> String:
	return "nap" if _nap else _don

## Tiến độ cho phần nhìn. Ba đoạn, và phải tách ra đúng ba đoạn:
##
##   đang nạp, chưa tới đỉnh   0 → 1 theo khung VUNG TAY  ⇒ giơ lên
##   đang giữ ở đỉnh           1.0                        ⇒ đứng giữ
##   đã nhả / đòn thường       0 → 1 theo cung vung       ⇒ chém xuống
##
## Đoạn ba đo TỪ `t_vung` nếu đòn ra từ cú nạp: tay đã giơ sẵn trên đỉnh rồi,
## đo lại từ 0 thì cung vung bắt đầu ở lưng chừng và tay nhảy một phát 112°.
func tien_do() -> float:
	var t_vung := float(_m.get("t_vung", 0.2))
	if _nap:
		if _giu_dinh:
			return 1.0
		return clampf(t / maxf(t_vung, 0.01), 0.0, 1.0)
	var t_den := float(_m.get("t_dam_den", 0.3))
	var het := t_den + float(_m.get("t_hoi", 0.5))
	var dau := t_vung if _tu_nap else 0.0
	return clampf((t - dau) / maxf(het - dau, 0.01), 0.0, 1.0)

## Nạp được bao nhiêu phần (0→1). Phần nhìn dùng để rung mạnh dần và phình vũ
## khí to dần — người chơi phải thấy được mình đã nạp tới đâu.
func muc_nap() -> float:
	return clampf(_t_nap / T_NAP_TOI_DA, 0.0, 1.0)

## Năm đoạn của một cú đánh — xem `SoulsLike` mục "Cửa sổ huỷ đòn".
##
## Tính từ MỐC THỜI GIAN TRONG CSV, không từ animation. Đây là chỗ dự án này
## cố ý khác với khuôn "Call Method Track" thường thấy: gắn mốc vào file
## animation là chuyển cân bằng game sang cho file `.fbx` giữ, và đổi một clip
## là lệch cả bảng số mà không ai thấy. CSV giữ sự thật, animation co giãn theo
## nó (xem `ThanMoHinh._toc_do()`).
const GD_KHOI := 1   ## Startup — khoá cứng
const GD_CHAM := 2   ## Active — hộp đòn bật, vẫn khoá cứng, và cú THU CHIÊU
const GD_NOI := 3    ## Combo Window — nối được, chưa né được
const GD_THU := 4    ## Defense Window — né / đỡ / đỡ phản cắt ngang
const GD_XONG := 5   ## End — về đứng, đi lại tự do

## Đoạn 2 kéo DÀI HƠN khung hộp đòn.
##
## Hộp đòn tắt ở `t_dam_den`, nhưng cửa sổ nối chỉ mở sau đó một quãng bằng
## `ti_le_cua_so_noi` phần khung hồi. Quãng ở giữa là cú THU CHIÊU — vẫn khoá
## cứng, và vẫn phải nhìn thấy. Bỏ nó đi thì lưỡi kiếm nhảy cóc từ cuối nhát
## này sang đầu nhát sau.
func giai_doan() -> int:
	if _nap:
		return GD_KHOI
	var t_tu := float(_m.get("t_dam_tu", 0.2))
	var t_den := float(_m.get("t_dam_den", t_tu + 0.12))
	var t_hoi := float(_m.get("t_hoi", 0.5))
	if t < t_tu:
		return GD_KHOI
	if t >= t_den + t_hoi:
		return GD_XONG
	if t < t_den + t_hoi * SoulsLike.ti_le_cua_so_noi:
		return GD_CHAM
	if t < t_den + t_hoi * SoulsLike.ti_le_cua_so_thu:
		return GD_NOI
	return GD_THU

# --- Bốn cờ trạng thái (isLocked / canCombo / canDodge / canMove) ----
#
# Đặt tên theo đúng bốn cờ của bản thiết kế. Công khai vì cả bộ kiểm tra lẫn
# phần nhìn đều cần hỏi, và hỏi bằng cờ thì không ai phải biết công thức mốc
# thời gian nằm ở đâu.

## Khoá cứng: mọi phím chỉ được đẩy vào bộ đệm, không cắt được gì.
func bi_khoa() -> bool:
	return giai_doan() <= GD_CHAM

## Nhận lệnh nối đòn.
func cho_noi() -> bool:
	return giai_doan() >= GD_NOI

## Nhận lệnh né / đỡ / đỡ phản.
func cho_ne() -> bool:
	return giai_doan() >= GD_THU

## Hết hẳn, đi lại tự do.
func cho_di() -> bool:
	return giai_doan() >= GD_XONG

## CAM KẾT ĐÒN ĐÁNH. Đã vung là không huỷ.
##
## Đây là một dòng code, và nó là thứ phân biệt souls-like với hack-n-slash.
## Mọi thứ khác trong repo này — thể lực, i-frame, ngũ hành, chữ Hán — đều
## vô nghĩa nếu người chơi bấm lăn giữa đòn là thoát được hậu quả.
func cho_doi(ten: String) -> bool:
	# NGẮT BẮT BUỘC — bậc 1 của ma trận ưu tiên. Không cửa sổ nào chặn được.
	if ten in ["trung_don", "chet", "vo_the", "danh", "dung"]:
		return true
	# Phòng thủ chỉ cắt được từ đoạn 4 — xem `cho_ne()`.
	return cho_ne() and ten in ["lan", "do_don", "do_phan"]

## Đang vung thì không hồi thể lực (Elden Ring). Hồi lại ngay giữa đòn là mất
## hết sức ép của việc "tiêu bao nhiêu cho nhát này".
func cho_hoi_the_luc() -> bool:
	return false
