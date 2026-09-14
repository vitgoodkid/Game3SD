extends TTQuai

## Đuổi theo người chơi. Vào tầm thì đánh.
##
## Chỗ tinh tế: quái KHÔNG đứng sát rạt rồi mới đánh. Nó đi vòng quanh một
## nhịp (do _nghi) trước khi vào đòn — nếu không thì mọi trận đánh thành hai
## bên đứng ôm nhau spam nút, và người chơi không bao giờ có khoảng trống để
## đọc đòn. Đây là lý do souls-like cảm giác khác hack-n-slash.

## Nghỉ giữa hai đòn, ngẫu nhiên trong khoảng này.
const NGHI_MIN := 0.45
const NGHI_MAX := 1.35

var _nghi := 0.0

func vao(_du_lieu: Dictionary = {}) -> void:
	_nghi = randf_range(NGHI_MIN, NGHI_MAX)

func chay(delta: float) -> void:
	if not q.thay_nguoi_choi():
		di("quai_ve_cho")
		return
	if q.nguoi_choi == null:
		di("quai_dung")
		return

	if q.trong_tam_danh():
		q.dung_lai(delta, 10.0)
		q.xoay_ve(q.huong_toi_nguoi_choi(), delta)
		if t >= _nghi:
			di("quai_danh", {"don": String(q.cac_don().pick_random())})
		return

	q.di_ve(q.nguoi_choi.global_position, float(q.d.get("toc_do_duoi", 4.0)), delta)
