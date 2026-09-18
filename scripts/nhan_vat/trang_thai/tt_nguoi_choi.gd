class_name TTNguoiChoi
extends TrangThaiMay

## Gốc chung của mọi trạng thái người chơi. Gom hai thứ mà state nào cũng cần:
## truy cập nhân vật đã ép kiểu, và bảng chuyển tiếp chung.
##
## Vì sao gom: mười hai state mà state nào cũng chép lại "bấm đánh thì sang
## state đánh" là mười hai chỗ để quên sửa. Ở đây một chỗ.

var nc: NguoiChoi:
	get:
		return chu as NguoiChoi

## Những hành động người chơi có thể khởi động từ trạng thái "rảnh" (đứng, đi,
## chạy). Gọi ở đầu chay() của các state đó; trả true nghĩa là đã đổi state,
## state gọi phải return ngay.
##
## MA TRẬN ƯU TIÊN HÀNH ĐỘNG. Thứ tự xét CHÍNH LÀ thứ tự ưu tiên.
##
## Năm bậc, xét từ trên xuống (chủ dự án chốt, theo khuôn Elden Ring):
##
##   1 NGẮT BẮT BUỘC   trúng đòn, vỡ thế, chết, cạn thể lực
##                     — KHÔNG nằm ở đây. Chúng đi qua `an_don()` / `mat_mau()`
##                       và ép đổi state thẳng, không thèm hỏi bộ đệm.
##   2 PHÒNG THỦ       né > đỡ > đỡ phản
##   3 TẤN CÔNG        kỹ năng > đòn nặng > đòn nhẹ
##   4 VẬT PHẨM        uống bình, cất/rút vũ khí
##   5 DI CHUYỂN       nhảy, chạy — state tự lo
##
## Vì sao PHÒNG THỦ trên TẤN CÔNG: lúc hoảng người chơi bấm cả hai, và cho né
## thắng là chiều đúng — né sai thì mất một nhịp, đánh sai thì mất một mạng.
##
## Vì sao VẬT PHẨM xuống dưới TẤN CÔNG: bản trước để uống bình ngay sau né, nên
## một cú bấm bình lỡ tay nuốt mất cú bấm đánh. Uống bình là hành động chậm và
## chủ ý; nó không có lý do gì để tranh với đòn đánh.
##
## Bộ đệm chỉ giữ MỘT lệnh nên phần lớn thời gian chỉ có một ứng viên. Thứ tự
## này quyết định lúc lệnh trong đệm đụng với phím đang GIỮ (giơ khiên).
func thu_hanh_dong() -> bool:
	# --- 2. PHÒNG THỦ ---
	if nc.lay_dem("lan") and nc.hoi_lan <= 0.0 and nc.du_the_luc():
		di("lan")
		return true
	# Parry KHÔNG cần khiên. Elden Ring cấm parry tay không; chủ dự án chốt cho
	# được — xem mục "Cố ý KHÁC" trong TIEN_DO.md.
	if nc.lay_dem("do_phan"):
		di("do_phan")
		return true

	# --- 3. TẤN CÔNG ---
	# Đang CẤT mà bấm đánh thì tự rút ra trước, và GIỮ LẠI cú bấm trong bộ đệm
	# để nó nổ ngay khi rút xong. Bắt người chơi bấm R rồi mới bấm đánh là một
	# bước thừa mà họ sẽ chửi — và họ đúng.
	if not nc.da_rut and (nc.co_dem("don_nhe") or nc.co_dem("don_nang")):
		di("rut_vu_khi")
		return true
	# Nặng trước nhẹ: bộ đệm chỉ giữ một lệnh, nhưng thứ tự vẫn phải đúng bậc.
	# `_don_dau()` trả "" nghĩa là đang trên không mà đã tiêu đòn nhảy rồi —
	# phím vẫn bị ăn khỏi đệm dù không ra đòn nào, để nó không dồn lại rồi nổ
	# ra đúng lúc vừa chạm đất.
	if nc.lay_dem("don_nang"):
		var dn := _don_dau("nang")
		if dn != "":
			di("danh", {"don": dn})
			return true
	if nc.lay_dem("don_nhe"):
		var d := _don_dau("nhe")
		if d != "":
			di("danh", {"don": d})
			return true

	# --- 4. VẬT PHẨM / TIỆN ÍCH ---
	if nc.lay_dem("uong_binh"):
		di("uong")
		return true
	if nc.lay_dem("cat_rut"):
		di("cat_vu_khi" if nc.da_rut else "rut_vu_khi")
		return true

	# --- 5. DI CHUYỂN ---
	if nc.lay_dem("nhay") and nc.is_on_floor():
		di("nhay")
		return true
	# ĐỠ đứng cuối vì nó không đọc từ đệm mà đọc phím ĐANG GIỮ: giơ khiên là
	# một trạng thái duy trì, không phải một cú bấm.
	if Input.is_action_pressed("do_don"):
		di("do_don")
		return true
	return false

## Tên đòn đầu chuỗi. Đang chạy thì ra đòn chạy, đang ở trên không thì ra ĐÒN
## NHẢY — cả hai đều là moveset riêng, không phải đòn thường, và người chơi
## souls trông đợi điều đó.
##
## Xét TRÊN KHÔNG trước: rơi khỏi mép vách trong lúc đang giữ Shift thì vẫn phải
## ra đòn nhảy chứ không phải đòn chạy — chân không chạm đất thì không có cú lao
## nào để mà lao.
## Trả "" nghĩa là KHÔNG ra đòn nào: đang trên không mà đã tiêu đòn nhảy của
## lần rời đất này rồi. Đòn nhảy phá thế gấp 4 đòn thường, nên rơi từ vách cao
## mà chém được cả chuỗi là phá vỡ mọi trận đánh.
func _don_dau(kieu: String) -> String:
	if nc.tren_khong():
		if not nc.con_don_tren_khong():
			return ""
		nc.dung_don_tren_khong()
		return "nhay" if kieu == "nhe" else "nhay_nang"
	if nc.dang_giu_chay() and nc.huong_nhap != Vector3.ZERO:
		return "chay"
	return "nhe_1" if kieu == "nhe" else "nang"
