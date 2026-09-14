extends TTNguoiChoi

## Khựng vì trúng đòn. Chỉ vào đây khi đòn đủ mạnh so với thế đứng
## (SoulsLike.co_khung) — giáp nặng ăn đòn nhỏ thì vung tay tiếp được.

const DAY := 3.5
var _lui := Vector3.ZERO

func vao(du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	var tu = du_lieu.get("tu_dau", nc.global_position)
	_lui = nc.global_position - (tu as Vector3)
	_lui.y = 0.0
	_lui = _lui.normalized()

func chay(delta: float) -> void:
	nc.dat_toc_ngang(_lui, DAY * maxf(0.0, 1.0 - t / 0.25))
	if t >= 0.34:
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung"]
