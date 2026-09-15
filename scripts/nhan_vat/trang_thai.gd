class_name TrangThaiMay
extends Node

## Lớp gốc của mọi trạng thái. Mỗi state có vao() / ra() / chay(delta).

var may: MayTrangThai = null
var chu: Node = null

## Bao lâu rồi ở trong state này — lấy thẳng từ máy, khỏi mỗi state tự đếm.
var t: float:
	get:
		return may.t if may != null else 0.0

func vao(_du_lieu: Dictionary = {}) -> void:
	pass

func ra() -> void:
	pass

func chay(_delta: float) -> void:
	pass

func nhap(_su_kien: InputEvent) -> void:
	pass

## Đã đi được bao nhiêu phần của trạng thái này (0→1). Phần hiển thị dùng con
## số này để diễn hoạt ảnh; state nào không có khái niệm "xong" thì để 0.
func tien_do() -> float:
	return 0.0

## Tên chi tiết của thứ đang diễn, cho phần NHÌN. Tên state là "danh" với cả
## bảy loại đòn, mà đòn nhẹ và đòn nạp phải trông khác hẳn nhau — không thì
## người chơi giữ chuột mà không biết mình vừa ra đòn gì.
func ten_dien() -> String:
	return ""

## State này có cho hồi thể lực trong lúc nó đang chạy không.
##
## MẶC ĐỊNH LÀ CHO. Bốn state nói không: đánh, lăn, chạy, giơ khiên — đúng như
## Elden Ring. Đây là nửa đầu của mô hình hồi thể lực kiểu ER; nửa sau là
## `NguoiChoi.tre_hoi`, đếm lùi SAU KHI state bận kết thúc.
##
## Vì sao phải là state tự khai chứ không phải đặt cờ lúc tiêu: đặt lúc tiêu
## thì mỗi nhát chém lại đẩy lùi mốc hồi thêm một lần, và ba nhát liên tiếp là
## thanh thể lực đứng hình. Đó đúng là lỗi từng làm combat game này khựng cứng.
func cho_hoi_the_luc() -> bool:
	return true

## Có cho đổi sang state `ten` không.
##
## MẶC ĐỊNH LÀ CHO. State nào muốn khoá thì tự chặn — cam kết đòn đánh nằm ở
## đây (mục 5.1: "đã vung là không huỷ"). Đây là thứ phân biệt souls-like với
## hack-n-slash; không có nó thì mọi cơ chế khác đều vô nghĩa.
func cho_doi(_ten: String) -> bool:
	return true

## Tiện tay: đổi state qua máy.
func di(ten: String, du_lieu: Dictionary = {}) -> void:
	if may != null:
		may.doi(ten, du_lieu)
