extends Node

## KHỰNG HÌNH khi trúng đòn (hitlag / freeze-frame).
##
## Dừng cả game 0.03–0.08 giây đúng lúc lưỡi kiếm chạm vào thịt. Nghe như trang
## trí, nhưng nó là thứ duy nhất phân biệt **trúng** với **quét trượt qua** khi
## nhìn: hộp đòn thì vô hình, máu thì tụt tận trên HUD, còn con quái ở gần thì
## chẳng có gì báo là cú vừa rồi có ăn hay không.
##
## Nặng nhẹ theo SÁT THƯƠNG, không theo loại đòn. Nhờ vậy nó tự đúng cho vũ khí
## mới, cho đòn chí mạng, cho hệ khắc chế ngũ hành — mọi thứ làm sát thương lớn
## đều tự nghe nặng tay hơn mà không phải khai thêm ở đâu.
##
## ĐẾM BẰNG THỜI GIAN THẬT (`Time.get_ticks_msec`), không bằng `delta`.
## `Engine.time_scale` nhân thẳng vào `delta` và vào mọi `SceneTreeTimer`, nên
## hẹn giờ bằng chúng để tự gỡ băng là tự khoá mình lại: càng dừng sâu thì đồng
## hồ gỡ băng càng chạy chậm, và ở `time_scale` đủ nhỏ thì game treo vĩnh viễn.
## Đó không phải lỗi giả định — đó là cách khựng hình hay được viết sai nhất.
##
## Nó cũng là móc treo cho RUNG CAMERA: `da_khung` phát ra kèm độ mạnh 0→1.

signal da_khung(giay: float, do_manh: float)

## Tắt hẳn cơ chế. Có để phòng thử đo nhịp mà không bị đồng hồ chung xê dịch.
var bat := true

## Mốc thời gian THẬT (ms) phải trả `Engine.time_scale` về 1.0. 0 = không khựng.
var _han := 0
## Giữ lại để trả về đúng giá trị cũ, phòng khi chỗ khác cũng chỉnh time_scale.
var _cu := 1.0

func _ready() -> void:
	# Phải chạy cả lúc game dừng: mở hành trang giữa lúc đang khựng mà node này
	# cũng dừng theo thì `time_scale` kẹt ở 0.05 cho tới khi đóng màn.
	process_mode = Node.PROCESS_MODE_ALWAYS

## Khựng theo SÁT THƯƠNG của cú đánh. Đây là cửa nên gọi.
func theo_sat_thuong(sat_thuong: float) -> void:
	var k := clampf(sat_thuong / SoulsLike.SAT_THUONG_KHUNG_DUNG_MAX, 0.0, 1.0)
	dung(lerpf(SoulsLike.KHUNG_DUNG_NHE, SoulsLike.KHUNG_DUNG_NANG, k), k)

## Khựng đúng bấy nhiêu giây THẬT.
##
## Cú khựng đang chạy mà có cú mới: lấy cái DÀI HƠN, không cộng dồn. Cộng dồn
## thì một đòn quét trúng bốn con quái là bốn lần khựng nối nhau — gần nửa giây
## đứng hình, và người chơi đọc ra là game lag.
func dung(giay: float, do_manh := 1.0) -> void:
	if not bat or giay <= 0.0:
		return
	var toi := Time.get_ticks_msec() + int(giay * 1000.0)
	if toi <= _han:
		return
	if _han == 0:
		_cu = Engine.time_scale
	_han = toi
	Engine.time_scale = 0.02
	da_khung.emit(giay, clampf(do_manh, 0.0, 1.0))

func dang_khung() -> bool:
	return _han != 0

func _process(_delta: float) -> void:
	if _han == 0:
		return
	if Time.get_ticks_msec() >= _han:
		_han = 0
		Engine.time_scale = _cu

## Gỡ băng ngay. Gọi khi đổi màn hay nạp lại — không thì một cú khựng dở dang
## đi theo sang scene mới.
func thoi() -> void:
	if _han == 0:
		return
	_han = 0
	Engine.time_scale = _cu
