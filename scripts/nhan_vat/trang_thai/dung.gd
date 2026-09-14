extends TTNguoiChoi

## Đứng yên. State mặc định, mọi state khác kết thúc là quay về đây.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false

func chay(delta: float) -> void:
	if thu_hanh_dong():
		return
	if nc.huong_nhap != Vector3.ZERO:
		di("di")
		return
	nc.dung_lai(delta)
	nc.xoay_ve(nc.huong_mat(), delta)
