extends TTQuai

## Vỡ tư thế — đứng ngây cho người chơi chạy tới kết liễu (mục 5.1).
##
## Đây là phần thưởng cho việc đánh dồn đúng nhịp, nên cửa sổ phải ĐỦ RỘNG để
## chạy tới kịp (2.6s), và phải nhìn thấy rõ: ThanQuai đổ người về trước và
## đổi màu.

var _lau := 0.0

func vao(du_lieu: Dictionary = {}) -> void:
	_lau = float(du_lieu.get("lau", SoulsLike.NGAY_SAU_VO))
	q.dang_ngay = true
	q.velocity = Vector3.ZERO

func ra() -> void:
	q.dang_ngay = false

func chay(delta: float) -> void:
	q.dung_lai(delta, 30.0)
	if t >= _lau:
		di("quai_duoi")

func tien_do() -> float:
	return clampf(t / maxf(_lau, 0.01), 0.0, 1.0)

func cho_doi(ten: String) -> bool:
	return ten in ["quai_chet", "quai_duoi"]
