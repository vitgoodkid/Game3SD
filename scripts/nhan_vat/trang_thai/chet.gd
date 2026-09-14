extends TTNguoiChoi

## Chết. Rơi hết hồn chưa tiêu tại chỗ (mục 4.5), rồi về bia đá.
##
## Vũng hồn cũ chưa nhặt thì MẤT. Không có ngoại lệ — tha một lần là hỏng cả
## cơ chế, vì người chơi sẽ tính toán dựa trên việc được tha.
##
## State này KHÔNG tự đứng dậy. Nó gọi `TheGioi.hoi_sinh_o_bia()` đúng một lần
## rồi nằm im; ai đưa nhân vật về bia là việc của VongHoiSinh, vì chỗ đứng dậy
## là chuyện của bản đồ chứ không phải của cái xác.

const T_CHO := 2.8
var _da_bao := false
var _da_hoi_sinh := false

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = false
	nc.bat_tu = true          # xác không ăn thêm đòn nào nữa
	nc.velocity = Vector3.ZERO
	_da_bao = false
	_da_hoi_sinh = false

func ra() -> void:
	# Sống lại thì hết bất tử. Để sót cờ này là người chơi đi lại bình thường
	# mà không con quái nào chạm được vào — lỗi im lặng, khó thấy nhất.
	nc.bat_tu = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 40.0)
	if not _da_bao and t >= 0.1:
		_da_bao = true
		TheGioi.chet_tai(TheGioi.vung_hien_tai, nc.global_position)
	# Một lần thôi: hàm này xoá sạch bảng quái đã hạ và đổ đầy máu, gọi lại
	# mỗi khung hình thì quái sống lại 60 lần một giây.
	if not _da_hoi_sinh and t >= T_CHO:
		_da_hoi_sinh = true
		TheGioi.hoi_sinh_o_bia()

func cho_doi(_ten: String) -> bool:
	return false
