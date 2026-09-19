extends TTNguoiChoi

## Đỡ phản (parry). Hụt thì đứng ngây.
##
## Đây là kỹ năng cao nhất người chơi học được, nên phần thưởng phải lớn (mở
## đòn kết liễu ×4) và hình phạt phải thật (0.45s đứng ngây, đủ để ăn trọn
## một đòn nặng). Cân bằng nó bằng cách đổi mấy con số trong souls_like.gd.
##
## HAI BẬC, lồng nhau chứ không tách rời:
##
##   0 ────── cua_so_perfect ────── cua_so_do_phan ────── + hoi_do_phan
##   │  HOÀN HẢO                │  parry thường      │  đứng ngây, hở
##   │  quái ngây 3.4s          │  quái ngây 2.2s    │
##   │  hoàn lại thể lực        │                    │
##
## Lồng nhau là cố ý: bấm sớm quá thì vẫn rơi vào parry thường chứ không hụt
## hẳn, nên tập bấm sớm KHÔNG bị phạt. Người chơi tiến từ "parry được" lên
## "parry hoàn hảo" bằng cách siết dần thời điểm, chứ không phải bằng cách
## đánh cược giữa hai cửa sổ rời nhau.
##
## KHÔNG cần khiên. Elden Ring cấm parry tay không; chủ dự án chốt cho được —
## xem mục "Cố ý KHÁC" trong TIEN_DO.md.
##
## MỘT NÚT GÁNH CẢ ĐỠ LẪN PARRY (chuột phải). Bấm ra là vào đây; còn GIỮ
## nguyên ngón tay khi hết `cua_so_do_phan` thì đi thẳng sang `do_don` —
## KHÔNG qua khung ngây. Đó là chỗ cây gậy đổi đầu: gõ nhanh là đánh cược,
## hụt thì đứng ngây `hoi_do_phan` giây; giữ là chơi an toàn, hụt thì khiên
## lên đỡ.
##
## Giữ KHÔNG phải là parry miễn phí, và chỗ thi hành nằm ở `an_don()` chứ
## không ở đây: `do_don` chỉ chặn được khi tay trái CÓ khiên, mà vũ khí hai
## tay (刃 — đúng cây khởi đầu) làm `Tui.tay_trai_dang_cam()` trả null. Với
## họ, giữ tiếp nghĩa là đứng nguyên đó ăn gần trọn đòn và mất thêm thể lực.

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	nc.dang_do_phan = true
	nc.do_phan_hoan_hao = true
	nc.ton_the_luc(SoulsLike.THE_LUC_DO_PHAN)

func ra() -> void:
	nc.dang_do_phan = false
	nc.do_phan_hoan_hao = false

func chay(delta: float) -> void:
	nc.dung_lai(delta, 20.0)
	# Tắt bậc HOÀN HẢO trước, bậc thường sau. Thứ tự này là cả cơ chế hai bậc:
	# giữa hai mốc thì dang_do_phan còn bật mà do_phan_hoan_hao đã tắt.
	if t >= SoulsLike.cua_so_perfect:
		nc.do_phan_hoan_hao = false
	if t >= SoulsLike.cua_so_do_phan:
		nc.dang_do_phan = false
		# CÒN GIỮ NÚT ⇒ LÊN KHIÊN NGAY, bỏ qua khung ngây.
		#
		# Hỏi phím ĐANG GIỮ chứ không hỏi bộ đệm: đệm chỉ có nội dung khi có
		# một cú BẤM mới, mà ở đây ngón tay chưa hề rời nút kể từ cú bấm đã
		# mở ra chính cú parry này.
		if Input.is_action_pressed("do_phan"):
			di("do_don")
			return
	if t >= SoulsLike.cua_so_do_phan + SoulsLike.hoi_do_phan:
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "ket_lieu", "dung"]
