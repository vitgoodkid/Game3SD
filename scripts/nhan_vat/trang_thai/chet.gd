extends TTNguoiChoi

## Chết. Rơi hết hồn chưa tiêu tại chỗ (mục 4.5), rồi về bia đá.
##
## Vũng hồn cũ chưa nhặt thì MẤT. Không có ngoại lệ — tha một lần là hỏng cả
## cơ chế, vì người chơi sẽ tính toán dựa trên việc được tha.

const T_CHO := 2.8
var _da_bao := false

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = false
	nc.bat_tu = true          # xác không ăn thêm đòn nào nữa
	nc.velocity = Vector3.ZERO
	_da_bao = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 40.0)
	if not _da_bao and t >= 0.1:
		_da_bao = true
		TheGioi.chet_tai(TheGioi.vung_hien_tai, nc.global_position)
	if t >= T_CHO:
		TheGioi.hoi_sinh_o_bia()

func cho_doi(_ten: String) -> bool:
	return false
