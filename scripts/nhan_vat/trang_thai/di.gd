extends TTNguoiChoi

## Đi bộ. Tốc độ nhân theo mức tải (mục 6.1) — mặc nặng thì ì thấy rõ, quá
## tải thì lết.

func chay(delta: float) -> void:
	if thu_hanh_dong():
		return
	if nc.huong_nhap == Vector3.ZERO:
		di("dung")
		return
	if nc.dang_giu_chay() and nc.du_the_luc():
		di("chay_nhanh")
		return

	var hs := float(Tui.muc_tai()["toc_do"])
	nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_di * hs)
	nc.xoay_ve(nc.huong_nhap, delta)
