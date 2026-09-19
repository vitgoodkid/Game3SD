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
	if _bam_tuong():
		return

	# Tiêu theo delta chứ không theo mốc. Không đụng tới mốc trễ hồi: state này
	# đã khai cho_hoi_the_luc() = false, nên chừng nào còn chạy là còn không
	# hồi, và mốc trễ chỉ bắt đầu đếm từ lúc thôi chạy.
	# Cất vũ khí thì tốn ít hơn — xem NguoiChoi.HS_THE_LUC_KHI_CAT. Đây là nửa
	# sau của phần thưởng cho việc cất kiếm; nửa đầu là tốc độ.
	nc.the_luc = maxf(0.0, nc.the_luc
		- SoulsLike.THE_LUC_CHAY_MOI_GIAY * nc.he_so_ton_the_luc() * delta)
	nc.doi_the_luc.emit(nc.the_luc, nc.the_luc_max)

	nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_chay * float(tai["toc_do"]))
	nc.xoay_ve(nc.huong_nhap, delta)

## Chạy thì không hồi — nếu không thì chạy là miễn phí và thanh thể lực vô nghĩa.
func cho_hoi_the_luc() -> bool:
	return false
