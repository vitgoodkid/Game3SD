extends TTNguoiChoi

## Leo tường. Bám vào mặt tường, W lên S xuống, A/D dạt ngang.
##
## Hai clip `leo_len` / `leo_xuong` là VÒNG LẶP TẠI CHỖ (2.00s, hông đứng yên
## ở 0.69m). Đúng khuôn thang: **code đẩy người, clip chỉ quay vòng tay chân**.
## Nên tốc độ leo là một con số trong code (`NguoiChoi.toc_do_leo`, chỉnh sống
## được), không phải thứ đọc ra từ file animation — ngược hẳn với đòn đánh.
##
## Vào bằng HAI cửa (chủ dự án chốt), cả hai nằm ngoài file này:
##   `di` / `chay_nhanh`  ép phím vào tường liên tục `T_EP_TUONG` giây
##   `nhay`               đang bay LÊN mà đâm vào tường
##
## Ra bằng năm cửa, và cả năm đều ở trong đây:
##   tới đỉnh     tự trèo lên mặt trên (`_treo`)
##   chạm đất     về `dung`
##   bấm nhảy     đạp tường bật ngược ra
##   cạn thể lực  tuột xuống
##   hết tường    mất điểm bám thì rơi
##
## CÒN ĂN ĐÒN thì `cho_doi()` cho qua `trung_don` — chủ dự án chốt: bám tường
## không được là chỗ trốn an toàn giữa trận.

## Thể lực tiêu mỗi giây khi di chuyển trên tường; bám yên không tiêu.
## Cùng thang với chạy
## (`SoulsLike.THE_LUC_CHAY_MOI_GIAY`), rẻ hơn một chút vì leo vốn đã chậm.
const THE_LUC_MOI_GIAY := 9.0
## Dạt ngang chậm hơn leo dọc bấy nhiêu lần — người thật bò ngang bao giờ cũng
## chậm hơn trèo thẳng.
const HS_DAT_NGANG := 0.55
## Đạp tường bật ra mạnh cỡ nào khi bấm nhảy.
const DAY_KHI_NHAY := 4.5
## Cú trèo qua mép dài bấy nhiêu giây.
##
## KHÔNG có clip đu người qua mép (xem `chua_dung/DOC.md`), nên đoạn này là
## code dịch thân đi. Ngắn thôi: kéo dài ra thì cái sự thiếu clip càng lộ.
const T_TREO := 0.35

## Hướng leo lần cuối, cho phần nhìn chọn clip. "len" hoặc "xuong".
var _bac := "len"
## Pháp tuyến của mặt tường đang bám (chỉ RA NGOÀI tường).
var _phap := Vector3.FORWARD
## Đang trong cú trèo qua mép.
var _dang_treo := false
var _t_treo := 0.0
var _treo_tu := Vector3.ZERO
var _treo_den := Vector3.ZERO

func vao(du_lieu: Dictionary = {}) -> void:
	_bac = "len"
	_dang_treo = false
	_t_treo = 0.0
	nc.dang_do = false
	nc.velocity = Vector3.ZERO
	# Quên đồng hồ ép tường, không thì vừa nhảy ra khỏi tường là bám lại ngay.
	nc.quen_ep_tuong()
	var p = du_lieu.get("phap", Vector3.ZERO)
	_phap = (p as Vector3) if p is Vector3 else Vector3.ZERO
	if _phap.length_squared() < 0.001:
		_phap = -nc.huong_mat()
	_phap.y = 0.0
	_phap = _phap.normalized()
	_ap_vao_tuong()
	AmThanh.phat("lan")

func ra() -> void:
	nc.quen_ep_tuong()

## Quay mặt VÀO tường và giữ đúng khoảng cách với nó.
##
## Phải gọi mỗi khung: leo dọc một bức tường cong (cái trụ trong phòng thử) thì
## pháp tuyến đổi liên tục, và không ép lại thì người trôi dần ra khỏi mặt
## tường rồi rơi giữa chừng mà chẳng vì lý do gì người chơi thấy được.
func _ap_vao_tuong() -> void:
	nc.than.rotation.y = atan2(-_phap.x, -_phap.z)

func chay(delta: float) -> void:
	if _dang_treo:
		_chay_treo(delta)
		return

	# --- Cạn thể lực thì tuột ---
	if nc.the_luc <= 0.0:
		_roi()
		return

	# --- Bấm nhảy thì đạp tường bật ra ---
	#
	# Nhận cả `nhay` lẫn `lan`: Space gánh hai việc (bấm đôi ra lăn), mà lăn
	# giữa lưng chừng tường thì vô nghĩa — cả hai đều quy về "rời tường".
	if nc.lay_dem("nhay") or nc.lay_dem("lan"):
		nc.velocity = _phap * DAY_KHI_NHAY + Vector3.UP * (NguoiChoi.LUC_NHAY * 0.55)
		di("nhay", {"roi": true})
		return

	# --- Còn tường để bám không ---
	var va := nc.tuong_leo_duoc(-_phap)
	if va.is_empty():
		# Mất điểm bám ở ngang ngực. Hai khả năng, và chúng khác hẳn nhau:
		# tới ĐỈNH tường (có mặt trên để trèo lên) hay tường hết ngang
		# (không có gì cả, rơi).
		if _co_mep_de_treo():
			_bat_dau_treo()
		else:
			_roi()
		return
	_phap = (va["normal"] as Vector3)
	_phap.y = 0.0
	_phap = _phap.normalized()
	_ap_vao_tuong()
	_giu_khoang_cach(va["position"] as Vector3)

	# --- Đi lên / xuống / dạt ngang ---
	#
	# Phím di chuyển ĐỔI NGHĨA khi đã bám: `huong_nhap` là hướng trong thế giới
	# theo camera, nên chiếu nó lên mặt tường là ra ý định thật. Đi VÀO tường
	# (ngược pháp tuyến) là LÊN, đi ra là XUỐNG.
	var vao_tuong := -nc.huong_nhap.dot(_phap)
	var ngang := _phap.cross(Vector3.UP).normalized()
	var doc := nc.huong_nhap.dot(ngang)

	var toc := nc.toc_do_leo
	nc.velocity.y = vao_tuong * toc
	if absf(vao_tuong) > 0.05:
		_bac = "len" if vao_tuong > 0.0 else "xuong"
	var v_ngang := ngang * doc * toc * HS_DAT_NGANG
	nc.velocity.x = v_ngang.x
	nc.velocity.z = v_ngang.z

	# Chỉ tiêu khi leo lên / xuống / dạt ngang. Xét SAU khi đặt đủ ba trục
	# vận tốc để không tính nhầm trọng lực hay chuyển động của khung trước.
	if not nc.velocity.is_zero_approx():
		nc.the_luc = maxf(0.0, nc.the_luc - THE_LUC_MOI_GIAY * delta)
		nc.doi_the_luc.emit(nc.the_luc, nc.the_luc_max)
		if nc.the_luc <= 0.0:
			_roi()
			return

	# --- Chạm đất trong lúc đang tụt xuống thì thôi bám ---
	if nc.is_on_floor() and vao_tuong <= 0.0:
		di("dung")

## Giữ thân cách mặt tường đúng `CACH_TUONG`, không cho trôi ra cũng không cho
## lún vào.
func _giu_khoang_cach(diem: Vector3) -> void:
	var toi := diem + _phap * NguoiChoi.CACH_TUONG
	nc.global_position.x = toi.x
	nc.global_position.z = toi.z

## Trên đầu có mặt phẳng nào để trèo lên không.
##
## Bắn một tia XUỐNG từ phía trước-trên đầu. Trúng nghĩa là có cái mép, và chỗ
## trúng chính là chỗ sẽ đứng.
func _co_mep_de_treo() -> bool:
	return not _diem_treo().is_empty()

func _diem_treo() -> Dictionary:
	var cao := nc.global_position.y + NguoiChoi.CAO_LEO_TOI_THIEU + 0.4
	var goc := Vector3(nc.global_position.x, cao, nc.global_position.z) \
		- _phap * (NguoiChoi.CACH_TUONG + 0.35)
	var ts := PhysicsRayQueryParameters3D.create(goc, goc + Vector3.DOWN * 1.4)
	ts.exclude = [nc.get_rid()]
	ts.collision_mask = 1
	return nc.get_world_3d().direct_space_state.intersect_ray(ts)

func _bat_dau_treo() -> void:
	var m := _diem_treo()
	if m.is_empty():
		_roi()
		return
	_dang_treo = true
	_t_treo = 0.0
	_treo_tu = nc.global_position
	# Nhích thêm một chút vào trong, không thì đứng đúng mép rồi trượt ngược
	# xuống ngay khung sau.
	_treo_den = (m["position"] as Vector3) - _phap * 0.25
	nc.velocity = Vector3.ZERO

## Cú trèo qua mép: dịch thân theo đường cong lên-rồi-vào.
##
## Đi hai chặng chứ không nội suy thẳng một đường: đường thẳng thì thân cắt
## chéo qua khối đá, và ở tường dày thì nửa người lút vào trong đá suốt cú
## trèo. Lên hết chiều cao TRƯỚC, rồi mới tiến vào — đó cũng đúng thứ tự một
## người thật đu lên mép.
func _chay_treo(delta: float) -> void:
	_t_treo += delta
	var k := clampf(_t_treo / T_TREO, 0.0, 1.0)
	var cao := _treo_tu.lerp(Vector3(_treo_tu.x, _treo_den.y, _treo_tu.z),
		minf(k * 2.0, 1.0))
	var toi := cao.lerp(_treo_den, clampf(k * 2.0 - 1.0, 0.0, 1.0))
	nc.global_position = toi
	nc.velocity = Vector3.ZERO
	if k >= 1.0:
		di("dung")

func _roi() -> void:
	nc.velocity = _phap * 1.2
	di("nhay", {"roi": true})

## Phần nhìn chọn clip theo hướng đang leo — xem `ThanMoHinh.DONG_TAC`.
func ten_dien() -> String:
	return _bac

func tien_do() -> float:
	return clampf(_t_treo / T_TREO, 0.0, 1.0) if _dang_treo else 0.0

## Bám tường thì không hồi thể lực, kể cả lúc bám yên: nghỉ tay chỉ giữ
## nguyên lượng còn lại, không nạp lại thể lực giữa chừng.
func cho_hoi_the_luc() -> bool:
	return false

## CAM KẾT: đang bám tường thì chỉ NGOẠI CẢNH mới gỡ ra được.
##
## Không có `lan` / `danh` / `nhay` trong danh sách — lăn giữa lưng chừng
## tường là rơi xuyên sàn, còn vung kiếm một tay trong khi hai tay đang bám
## thì không có clip nào diễn nổi. Muốn rời tường thì bấm nhảy, và cú đó do
## `chay()` xử, không đi qua đây.
func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung", "nhay"]
