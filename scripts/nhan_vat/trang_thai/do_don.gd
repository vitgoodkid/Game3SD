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
	if nc.lay_dem("do_phan") and nc.co_khien():
		di("do_phan")
		return
	# ĐÒN PHẢN SAU KHI ĐỠ (guard counter). Vừa chặn được một đòn thì bấm đòn
	# nặng trong cửa sổ ngắn sẽ ra đòn riêng, phá thế ngang đòn nặng nạp. Xét
	# TRƯỚC đòn nhẹ vì đây là nước đi người chơi cố ý chọn, không được để một
	# cú bấm nhầm đòn nhẹ nuốt mất.
	if nc.cho_phan_do > 0.0 and nc.lay_dem("don_nang"):
		nc.cho_phan_do = 0.0
		di("danh", {"don": "phan_do"})
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

## Giơ khiên thì KHÔNG hồi thể lực — đó là giá của việc đứng thủ, và là lý do
## Elden Ring bảo chỉ giơ khiên khi đoán được đòn sắp tới.
func cho_hoi_the_luc() -> bool:
	return false
