extends TTNguoiChoi

## Nhảy. Elden Ring có, và nó có việc thật: né đòn quét ngang của boss —
## thứ mà lăn không né nổi vì đòn quét phủ cả vòng.
##
## ĐÒN NHẢY — bấm đánh khi đang trên không. Hai bậc, đúng khuôn chuột trái như
## dưới đất: bấm nhanh ra `nhay`, giữ ra `nhay_nang`. Cả hai phá thế rất mạnh
## (mục pha_the của moveset.csv: đòn nhảy nhẹ ×1.6 đòn thường, nhảy nặng ×4),
## và đó là cả lý do tồn tại của chúng — đòn nhảy là cách mở thanh vỡ thế của
## con quái đang thủ kín.
##
## Mỗi lần rời mặt đất chỉ được MỘT đòn; cờ đếm nằm ở NguoiChoi, không ở đây,
## vì rơi khỏi mép vách cũng đánh được đòn nhảy mà lúc đó state không phải là
## `nhay`. Xem NguoiChoi.con_don_tren_khong().

## Vào state này mà KHÔNG nảy lên — dùng cho lúc rời tường (tuột, bị gỡ, đạp
## tường bật ra). Cần một cửa như vậy vì `nhay` là state "đang ở trên không"
## duy nhất, mà không phải lần nào lên đó cũng vì vừa nhún chân.
func vao(du_lieu: Dictionary = {}) -> void:
	if bool(du_lieu.get("roi", false)):
		# Giữ nguyên vận tốc bên gọi đã đặt, và KHÔNG tiêu thể lực: người chơi
		# không hề bấm nhảy.
		nc.dang_do = false
		return
	nc.velocity.y = NguoiChoi.LUC_NHAY
	nc.ton_the_luc(SoulsLike.THE_LUC_NHAY)
	nc.dang_do = false

func chay(delta: float) -> void:
	# Bẻ lái trên không được, nhưng yếu — nhảy không phải là cách di chuyển.
	if nc.huong_nhap != Vector3.ZERO:
		var toc := nc.toc_do_di * float(Tui.muc_tai()["toc_do"])
		nc.velocity.x = move_toward(nc.velocity.x, nc.huong_nhap.x * toc, 9.0 * delta)
		nc.velocity.z = move_toward(nc.velocity.z, nc.huong_nhap.z * toc, 9.0 * delta)
		nc.xoay_ve(nc.huong_nhap, delta)

	# Nặng xét TRƯỚC nhẹ: giữ chuột trái nạp đủ ngưỡng thì _dem có CẢ hai, và
	# thứ người chơi cố ý chọn là cái nặng. Xét ngược lại thì đòn nhảy nặng gần
	# như không bao giờ ra được.
	if nc.lay_dem("don_nang") and nc.con_don_tren_khong():
		nc.dung_don_tren_khong()
		di("danh", {"don": "nhay_nang"})
		return
	if nc.lay_dem("don_nhe") and nc.con_don_tren_khong():
		nc.dung_don_tren_khong()
		di("danh", {"don": "nhay"})
		return
	# NHẢY ĐÂM VÀO TƯỜNG thì bám lấy nó (cửa vào thứ hai của `leo`).
	#
	# Chỉ khi còn đang bay LÊN. Chủ dự án chốt như vậy, và lý do rất thực tế:
	# xét cả lúc đang rơi thì chạy khỏi mép vách là dính tường lủng lẳng ngoài
	# ý muốn — người chơi định nhảy qua khe, hoá ra treo mình lên vách.
	if nc.velocity.y > 0.0 and nc.is_on_wall():
		var va := nc.tuong_leo_duoc(-nc.get_wall_normal())
		if not va.is_empty():
			di("leo", {"phap": va["normal"]})
			return

	# Chờ qua khung hình đầu rồi mới xét chạm đất, không thì vừa nhảy đã hạ.
	if t > 0.12 and nc.is_on_floor():
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "danh", "dung"]
