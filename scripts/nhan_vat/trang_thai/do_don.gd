extends TTNguoiChoi

## Giơ khiên. Giữ Q. Thả ra là về đứng.
##
## Giơ khiên thì KHÔNG hồi thể lực (xem NguoiChoi._hoi_the_luc) — đó là giá
## của việc đứng thủ. Không có giá này thì đứng giơ khiên là chiến thuật tối
## ưu ở mọi tình huống, và trận đánh chết ngay tại đó.
##
## Đỡ tới cạn thể lực thì VỠ THẾ — xử ở NguoiChoi.an_don().

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = true

func ra() -> void:
	nc.dang_do = false

func chay(delta: float) -> void:
	if not Input.is_action_pressed("do_don"):
		di("dung")
		return
	if nc.lay_dem("lan") and nc.hoi_lan <= 0.0:
		di("lan")
		return
	if nc.lay_dem("do_phan"):
		di("do_phan")
		return
	if nc.lay_dem("don_nhe"):
		di("danh", {"don": "nhe_1"})
		return

	# Giơ khiên vẫn đi được, nhưng chậm — lết ngang né đòn là chiến thuật hợp
	# lệ, chỉ không được nhanh bằng bỏ khiên xuống mà chạy.
	if nc.huong_nhap != Vector3.ZERO:
		nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_di * 0.45)
		nc.xoay_ve(nc.huong_nhap, delta)
	else:
		nc.dung_lai(delta)
