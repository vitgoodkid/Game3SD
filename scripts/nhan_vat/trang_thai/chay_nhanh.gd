extends TTNguoiChoi

## Chạy. Tốn thể lực LIÊN TỤC, không theo mốc — nên chạy dài là hết hơi, và
## chạy tới chỗ quái xong không đủ thể lực đánh là lỗi của người chơi.
##
## Quá tải thì không chạy được, chỉ lết (mục 6.1).

func chay(delta: float) -> void:
	if thu_hanh_dong():
		return
	if nc.huong_nhap == Vector3.ZERO or not nc.dang_giu_chay():
		di("di")
		return
	if not nc.du_the_luc():
		di("di")
		return

	var tai := Tui.muc_tai()
	if String(tai["muc"]) == "qua_tai":
		di("di")
		return

	# Tiêu theo delta chứ không theo mốc, nhưng KHÔNG đặt lại khựng mỗi khung
	# hình — nếu không thì chạy một bước rồi dừng cũng phải chờ trọn 0.8s.
	nc.the_luc = maxf(0.0, nc.the_luc - SoulsLike.THE_LUC_CHAY_MOI_GIAY * delta)
	nc.khung_tl = maxf(nc.khung_tl, SoulsLike.khung_the_luc)
	nc.doi_the_luc.emit(nc.the_luc, nc.the_luc_max)

	nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_chay * float(tai["toc_do"]))
	nc.xoay_ve(nc.huong_nhap, delta)
