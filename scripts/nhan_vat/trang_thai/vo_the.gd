extends TTNguoiChoi

## Vỡ tư thế: đứng ngây cho đối phương kết liễu. Kiểu Sekiro/Elden Ring.
##
## Đây là hình phạt nặng nhất của người chơi, nên phải BÁO TRƯỚC được: thanh
## tư thế hiện trên HUD, tụt nhanh khi không bị đánh (12/giây). Vỡ tư thế
## luôn là hậu quả của việc đứng ăn đòn liên tục, không bao giờ là bất ngờ.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = false
	nc.tu_the = 0.0
	nc.xoa_dem()

func chay(delta: float) -> void:
	nc.dung_lai(delta, 30.0)
	if t >= SoulsLike.NGAY_SAU_VO:
		di("dung")

## Ngây thật thì phải ngây thật — không cho thoát bằng bất cứ nút nào.
func cho_doi(ten: String) -> bool:
	return ten in ["chet", "dung"]
