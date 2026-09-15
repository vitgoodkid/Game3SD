extends TTNguoiChoi

## Đỡ phản (parry). Cửa sổ ~0.15s, hụt thì đứng ngây.
##
## Đây là kỹ năng cao nhất người chơi học được, nên phần thưởng phải lớn (mở
## đòn kết liễu ×4) và hình phạt phải thật (0.45s đứng ngây, đủ để ăn trọn
## một đòn nặng). Cân bằng nó bằng cách đổi hai con số trong souls_like.gd.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = true
	nc.ton_the_luc(SoulsLike.THE_LUC_DO_PHAN)

func ra() -> void:
	nc.dang_do_phan = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 20.0)
	if t >= SoulsLike.cua_so_do_phan:
		nc.dang_do_phan = false
	if t >= SoulsLike.cua_so_do_phan + SoulsLike.hoi_do_phan:
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "ket_lieu", "dung"]
