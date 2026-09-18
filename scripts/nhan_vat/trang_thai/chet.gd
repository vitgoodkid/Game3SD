extends TTNguoiChoi

## Chết. Rơi hết hồn chưa tiêu tại chỗ (mục 4.5), rồi về bia đá.
##
## Vũng hồn cũ chưa nhặt thì MẤT. Không có ngoại lệ — tha một lần là hỏng cả
## cơ chế, vì người chơi sẽ tính toán dựa trên việc được tha.
##
## State này KHÔNG tự đứng dậy, và cũng KHÔNG tự hồi sinh nữa. Nó rơi hồn, chọn
## dáng ngã, rồi NẰM IM chờ người chơi bấm phím. `ManChet` gọi `hoi_sinh()`.
##
## Vì sao đổi: hồi sinh theo đồng hồ thì màn "BẠN ĐÃ CHẾT" chỉ hiện được đúng
## khoảng thời gian cố định rồi tự tắt, mà đó là khoảnh khắc người chơi cần
## ngồi nhìn bao lâu tuỳ họ. Elden Ring đợi người chơi, không đợi đồng hồ.
##
## Ai đưa nhân vật về bia là việc của VongHoiSinh — chỗ đứng dậy là chuyện của
## bản đồ chứ không phải của cái xác.

## Bao lâu sau khi ngã thì mới cho bấm phím đứng dậy.
##
## Không cho bấm ngay: người chơi đang giữ phím lúc chết sẽ vô tình hồi sinh
## trước cả khi kịp đọc dòng chữ, và họ sẽ tưởng game nuốt mất màn hình chết.
const T_HIEN := 1.2

## Dáng ngã theo hướng đòn tới. Khoá theo tên clip trong `assets/model/dong_tac/`.
##
## Người ngã RA XA cú đánh: đòn tới từ trước mặt thì đổ ngửa ra sau, từ sau
## lưng thì úp mặt về trước. Hướng ngã của từng clip đo bằng
## `tools/soi_dong_tac.tscn` chứ không đọc theo tên file — tên Mixamo từng nói
## sai ba lần trong dự án này.
const NGA_TRUOC := "truoc"   ## đòn từ SAU lưng ⇒ úp mặt về trước
const NGA_SAU := "sau"       ## đòn từ TRƯỚC mặt ⇒ đổ ngửa
const NGA_TRAI := "trai"     ## đòn từ bên PHẢI ⇒ đổ sang trái
const NGA_PHAI := "phai"     ## đòn từ bên TRÁI ⇒ đổ sang phải
const NGA_MANH := "manh"     ## đòn chí mạng, hất tung ra sau

var _da_bao := false
var _da_hoi_sinh := false
var _dang := NGA_SAU

func vao(du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = false
	nc.bat_tu = true          # xác không ăn thêm đòn nào nữa
	nc.velocity = Vector3.ZERO
	nc.xoa_dem()
	_da_bao = false
	_da_hoi_sinh = false
	_dang = _chon_dang(du_lieu)

## Chọn dáng ngã. Đòn mạnh thì bỏ qua hướng — cú chí mạng hất người bay ra sau
## bất kể nó tới từ đâu, và đó là thứ đáng đọc hơn cả hướng.
func _chon_dang(du_lieu: Dictionary) -> String:
	if bool(du_lieu.get("manh", false)):
		return NGA_MANH
	var tu = du_lieu.get("tu_dau", Vector3.INF)
	if not (tu is Vector3) or (tu as Vector3).x == INF:
		return NGA_SAU        # chết vì rơi, vì độc… không có hướng thì đổ ngửa
	var v: Vector3 = (tu as Vector3) - nc.global_position
	v.y = 0.0
	if v.length_squared() < 0.001:
		return NGA_SAU
	v = v.normalized()
	var truoc := nc.huong_mat()
	var phai := truoc.cross(Vector3.UP)
	var t := v.dot(truoc)
	var p := v.dot(phai)
	if absf(t) >= absf(p):
		return NGA_SAU if t > 0.0 else NGA_TRUOC
	return NGA_TRAI if p > 0.0 else NGA_PHAI

func ra() -> void:
	# Sống lại thì hết bất tử. Để sót cờ này là người chơi đi lại bình thường
	# mà không con quái nào chạm được vào — lỗi im lặng, khó thấy nhất.
	nc.bat_tu = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 40.0)
	if not _da_bao and t >= 0.1:
		_da_bao = true
		TheGioi.chet_tai(TheGioi.vung_hien_tai, nc.global_position)

## Đã nằm đủ lâu để cho bấm phím đứng dậy chưa.
func san_sang() -> bool:
	return t >= T_HIEN

## Đứng dậy ở bia đá. `ManChet` gọi khi người chơi bấm phím; bộ kiểm tra gọi
## thẳng vào đây, tức là đi đúng con đường mà giao diện đi.
##
## Một lần thôi: `hoi_sinh_o_bia()` xoá sạch bảng quái đã hạ và đổ đầy máu, gọi
## lại mỗi khung hình thì quái sống lại 60 lần một giây.
func hoi_sinh() -> void:
	if _da_hoi_sinh or not san_sang():
		return
	_da_hoi_sinh = true
	TheGioi.hoi_sinh_o_bia()

## Dáng ngã đang diễn — phần nhìn đọc cái này để chọn clip `chet_<dáng>`.
func ten_dien() -> String:
	return _dang

func cho_doi(_ten: String) -> bool:
	return false
