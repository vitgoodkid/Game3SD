extends TTNguoiChoi

## Lăn né. Cơ chế quan trọng nhất của cả game (mục 5.2).
##
## Ba giai đoạn trong một cú lăn:
##   0 → iframe_thuc   BẤT TỬ. Số giây này tăng theo 韧, giảm theo tải trọng.
##   iframe → cuối     còn trượt nhưng ăn đòn bình thường
##   cuối              đứng dậy, mới lăn tiếp được sau hoi_lan giây
##
## Đứng yên mà lăn thì lăn THEO HƯỚNG MẶT.
##
## Bản trước lấy hướng NGƯỢC lại, định làm backstep kiểu souls. Nhưng nó vẫn
## xoay cả người về hướng lăn ở dòng dưới — nên cái ra được không phải backstep
## mà là **quay ngoắt 180° rồi lăn tới**. Đo bằng `tools/soi_lan.tscn`: lăn
## đứng yên lệch hướng mặt đúng 180°, còn lăn có phím thì lệch 0–1°.
##
## Muốn backstep thật thì phải GIỮ NGUYÊN hướng mặt và lùi người ra — tức là
## một dáng riêng, không dùng chung clip lăn tới được. Chưa có dáng đó thì lăn
## tới là thứ đọc ra đúng.

var _huong := Vector3.ZERO
var _iframe := 0.0
var _dai := 0.0
## Tốc độ lăn. Nhân theo "xa" của mức tải: nhẹ thì lăn xa, nặng thì lăn ngắn.
var _toc := 0.0

func vao(_du_lieu: Dictionary = {}) -> void:
	var tai := Tui.muc_tai()
	_iframe = SoulsLike.iframe_thuc(nc.ti_le_tai(), Tui.cs("韧"))
	_dai = SoulsLike.thoi_gian_lan
	# `he_so_toc_do_lan` — mục "CHỈNH SỐNG" của NguoiChoi — chỉ đổi TỐC ĐỘ
	# TRƯỢT, tách khỏi THỜI LƯỢNG (`_dai`, ở trên). Hai cái là hai cảm giác
	# khác nhau: lăn xa/gần do thời lượng × tốc độ, còn lăn "gấp" hay "nặng nề"
	# ở TỪNG KHUNG HÌNH là do tốc độ một mình.
	_toc = 9.5 * float(tai["xa"]) * nc.he_so_toc_do_lan

	_huong = nc.huong_nhap
	if _huong == Vector3.ZERO:
		_huong = nc.huong_mat()   # đứng yên mà lăn = lăn thẳng theo hướng mặt
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
