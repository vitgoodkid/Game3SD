extends TTNguoiChoi

## Rút vũ khí ra. Cùng khuôn với `cat_vu_khi.gd`, chỉ ngược chiều.
##
## CAM KẾT như mọi hành động khác: đã rút là rút xong mới làm được việc tiếp.
## Cho huỷ giữa chừng thì việc cất kiếm hết rủi ro, mà hết rủi ro thì cái lợi
## đi kèm (chạy nhanh hơn) thành miễn phí.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false

func chay(delta: float) -> void:
	# Đi lại được trong lúc rút, chậm. Đứng chôn chân giữa lúc con quái đang
	# lao tới là cái giá quá đắt cho một thao tác người chơi buộc phải làm.
	if nc.huong_nhap != Vector3.ZERO:
		nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_di * NguoiChoi.TOC_DO_KHI_DOI_VU_KHI)
		nc.xoay_ve(nc.huong_nhap, delta)
	else:
		nc.dung_lai(delta)

	if t >= NguoiChoi.T_RUT_VU_KHI:
		nc.da_rut = true
		di("dung")

func tien_do() -> float:
	return clampf(t / NguoiChoi.T_RUT_VU_KHI, 0.0, 1.0)

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung"]
