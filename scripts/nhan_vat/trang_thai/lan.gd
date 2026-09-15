extends TTNguoiChoi

## Lăn né. Cơ chế quan trọng nhất của cả game (mục 5.2).
##
## Ba giai đoạn trong một cú lăn:
##   0 → iframe_thuc   BẤT TỬ. Số giây này tăng theo 韧, giảm theo tải trọng.
##   iframe → cuối     còn trượt nhưng ăn đòn bình thường
##   cuối              đứng dậy, mới lăn tiếp được sau hoi_lan giây
##
## Đứng yên mà lăn thì lăn về sau — kiểu backstep của souls. Không phải chi
## tiết thừa: đó là cách duy nhất lùi ra mà vẫn có i-frame.

var _huong := Vector3.ZERO
var _iframe := 0.0
var _dai := 0.0
## Tốc độ lăn. Nhân theo "xa" của mức tải: nhẹ thì lăn xa, nặng thì lăn ngắn.
var _toc := 0.0

func vao(_du_lieu: Dictionary = {}) -> void:
	var tai := Tui.muc_tai()
	_iframe = SoulsLike.iframe_thuc(nc.ti_le_tai(), Tui.cs("韧"))
	_dai = SoulsLike.thoi_gian_lan
	_toc = 9.5 * float(tai["xa"])

	_huong = nc.huong_nhap
	if _huong == Vector3.ZERO:
		_huong = -nc.huong_mat()   # đứng yên mà lăn = lùi lại
	nc.ton_the_luc(SoulsLike.THE_LUC_LAN)
	AmThanh.phat("lan")
	nc.bat_tu = true
	nc.dang_do = false
	# Lăn xong mới được lăn tiếp — chặn ngay từ lúc vào, không đợi lúc ra,
	# để thoát state giữa chừng (trúng đòn) cũng không lách được.
	# ER phạt giáp nặng ở ĐÂY chứ không ở i-frame: lăn xong đứng ì gấp đôi
	# (8 khung hồi ở tải nhẹ/vừa, 16 khung ở tải nặng).
	nc.hoi_lan = SoulsLike.hoi_lan_thuc(nc.ti_le_tai()) + _dai

func ra() -> void:
	nc.bat_tu = false

func chay(delta: float) -> void:
	if t >= _iframe:
		nc.bat_tu = false

	# Chậm dần về cuối cú lăn — lăn với tốc độ đều trông như trượt băng.
	var giam := clampf(1.0 - (t / _dai) * 0.65, 0.2, 1.0)
	nc.dat_toc_ngang(_huong, _toc * giam)
	# Lăn KHÔNG bẻ lái được. Đây là một phần của "cam kết": chọn hướng lăn
	# là một quyết định, không phải thứ sửa được giữa chừng.
	nc.than.rotation.y = lerp_angle(nc.than.rotation.y, atan2(_huong.x, _huong.z),
		minf(1.0, 18.0 * delta))

	if t >= _dai:
		di("dung")

func tien_do() -> float:
	return clampf(t / maxf(_dai, 0.01), 0.0, 1.0)

## Cam kết: đang lăn thì chỉ trúng đòn / chết mới cắt được. Không cho huỷ lăn
## bằng cách bấm đánh — nếu cho thì lăn thành nút "bất tử miễn phí".
func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung"]

func cho_hoi_the_luc() -> bool:
	return false
