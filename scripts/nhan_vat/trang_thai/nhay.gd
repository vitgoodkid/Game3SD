extends TTNguoiChoi

## Nhảy. Elden Ring có, và nó có việc thật: né đòn quét ngang của boss —
## thứ mà lăn không né nổi vì đòn quét phủ cả vòng.
##
## Đòn nhảy (bấm đánh khi đang trên không) phá thế rất mạnh, xem cột pha_the
## của dòng "nhay" trong moveset.csv.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.velocity.y = NguoiChoi.LUC_NHAY
	nc.ton_the_luc(SoulsLike.THE_LUC_NHAY)
	nc.dang_do = false

func chay(delta: float) -> void:
	# Bẻ lái trên không được, nhưng yếu — nhảy không phải là cách di chuyển.
	if nc.huong_nhap != Vector3.ZERO:
		var toc := nc.toc_do_di * float(Tui.muc_tai()["toc_do"])
		nc.velocity.x = move_toward(nc.velocity.x, nc.huong_nhap.x * toc, 9.0 * delta)
		nc.velocity.z = move_toward(nc.velocity.z, nc.huong_nhap.z * toc, 9.0 * delta)
		nc.xoay_ve(nc.huong_nhap, delta)

	if nc.lay_dem("don_nhe"):
		di("danh", {"don": "nhay"})
		return
	# Chờ qua khung hình đầu rồi mới xét chạm đất, không thì vừa nhảy đã hạ.
	if t > 0.12 and nc.is_on_floor():
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "danh", "dung"]
