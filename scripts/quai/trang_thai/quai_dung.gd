extends TTQuai

## Đứng canh. Thấy người chơi thì đuổi.
##
## Có một khoảng CHỜ trước khi lao ra: quái phát hiện xong mà xông tới ngay
## thì người chơi không kịp nhận ra mình đã bị thấy. Nửa giây là đủ để nhìn
## thấy nó ngẩng đầu lên.

const CHO_TRUOC_KHI_DUOI := 0.5

func chay(delta: float) -> void:
	q.dung_lai(delta)
	if q.thay_nguoi_choi() and t >= CHO_TRUOC_KHI_DUOI:
		di("quai_duoi")
		return
	# Lạc người chơi lâu rồi thì lết về chỗ cũ.
	if q.global_position.distance_to(q.diem_goc) > 1.2 and not q.thay_nguoi_choi():
		di("quai_ve_cho")
