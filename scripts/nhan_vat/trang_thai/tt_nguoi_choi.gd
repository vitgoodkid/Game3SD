class_name TTNguoiChoi
extends TrangThaiMay

## Gốc chung của mọi trạng thái người chơi. Gom hai thứ mà state nào cũng cần:
## truy cập nhân vật đã ép kiểu, và bảng chuyển tiếp chung.
##
## Vì sao gom: mười hai state mà state nào cũng chép lại "bấm đánh thì sang
## state đánh" là mười hai chỗ để quên sửa. Ở đây một chỗ.

var nc: NguoiChoi:
	get:
		return chu as NguoiChoi

## Những hành động người chơi có thể khởi động từ trạng thái "rảnh" (đứng, đi,
## chạy). Gọi ở đầu chay() của các state đó; trả true nghĩa là đã đổi state,
## state gọi phải return ngay.
##
## Thứ tự xét là thứ tự ƯU TIÊN, và nó có chủ ý:
##   lăn trước đánh — lúc hoảng người chơi bấm cả hai, cho lăn thắng
##   đánh trước đỡ — bấm đánh mà ra giơ khiên là lỗi cảm giác nặng nhất
func thu_hanh_dong() -> bool:
	if nc.lay_dem("lan") and nc.hoi_lan <= 0.0 and nc.du_the_luc():
		di("lan")
		return true
	if nc.lay_dem("uong_binh"):
		di("uong")
		return true
	if nc.lay_dem("don_nhe"):
		di("danh", {"don": _don_dau("nhe")})
		return true
	if nc.lay_dem("don_nang"):
		di("danh", {"don": _don_dau("nang")})
		return true
	if nc.lay_dem("do_phan"):
		di("do_phan")
		return true
	if nc.lay_dem("nhay") and nc.is_on_floor():
		di("nhay")
		return true
	if Input.is_action_pressed("do_don"):
		di("do_don")
		return true
	return false

## Tên đòn đầu chuỗi. Đang chạy thì ra đòn chạy — đó là moveset riêng, không
## phải đòn thường, và người chơi souls trông đợi điều đó.
func _don_dau(kieu: String) -> String:
	if nc.dang_giu_chay() and nc.huong_nhap != Vector3.ZERO:
		return "chay"
	return "nhe_1" if kieu == "nhe" else "nang"
