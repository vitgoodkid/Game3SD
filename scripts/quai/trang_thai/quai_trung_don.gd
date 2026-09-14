extends TTQuai

## Khựng vì trúng đòn. Chỉ vào đây khi đòn phá thế đủ mạnh so với thế đứng
## của con quái — quái giáp dày ăn đòn nhẹ thì vẫn vung tay tiếp.

const DAY := 3.0
var _lui := Vector3.ZERO

func vao(du_lieu: Dictionary = {}) -> void:
	var tu = du_lieu.get("tu_dau", q.global_position)
	_lui = q.global_position - (tu as Vector3)
	_lui.y = 0.0
	_lui = _lui.normalized()

func chay(delta: float) -> void:
	q.velocity.x = _lui.x * DAY * maxf(0.0, 1.0 - t / 0.22)
	q.velocity.z = _lui.z * DAY * maxf(0.0, 1.0 - t / 0.22)
	if t >= 0.36:
		di("quai_duoi")

func cho_doi(ten: String) -> bool:
	return ten in ["quai_trung_don", "quai_chet", "quai_vo_the", "quai_duoi"]
