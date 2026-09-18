extends TTNguoiChoi

## Cất vũ khí đi. Xem `rut_vu_khi.gd` — cùng khuôn, ngược chiều.
##
## Cất xong thì đi nhanh hơn (`NguoiChoi.TOC_DO_KHI_CAT`) nhưng KHÔNG đánh được:
## bấm đánh lúc đang cất kiếm thì nhân vật tự rút ra trước đã, và cú đánh nằm
## chờ trong bộ đệm. Đó là chỗ trả giá — đổi lấy tốc độ đi đường bằng một nhịp
## chậm lúc chạm trán.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false

func chay(delta: float) -> void:
	if nc.huong_nhap != Vector3.ZERO:
		nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_di * NguoiChoi.TOC_DO_KHI_DOI_VU_KHI)
		nc.xoay_ve(nc.huong_nhap, delta)
	else:
		nc.dung_lai(delta)

	if t >= NguoiChoi.T_CAT_VU_KHI:
		nc.da_rut = false
		di("dung")

func tien_do() -> float:
	return clampf(t / NguoiChoi.T_CAT_VU_KHI, 0.0, 1.0)

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung"]
