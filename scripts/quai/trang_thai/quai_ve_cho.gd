extends TTQuai

## Về lại chỗ đặt ban đầu sau khi mất dấu người chơi.
## Souls-like KHÔNG hồi máu cho quái lúc này — kéo quái ra rồi đánh dần là
## chiến thuật hợp lệ, và người chơi đã trả giá bằng thời gian.

func chay(delta: float) -> void:
	if q.thay_nguoi_choi():
		di("quai_duoi")
		return
	q.di_ve(q.diem_goc, float(q.d.get("toc_do_di", 2.5)), delta)
	if q.global_position.distance_to(q.diem_goc) < 0.5:
		di("quai_dung")
