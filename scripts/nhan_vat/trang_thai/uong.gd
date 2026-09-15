extends TTNguoiChoi

## Uống bình. Chậm và không huỷ được — uống sai lúc là chết, đúng chuẩn souls.
## Bình hồi máu và hồi MP dùng CHUNG quota kiểu Elden Ring (mục 6.2).

const T_HOI_MAU := 0.55   ## uống tới đây mới thật sự hồi
const T_XONG := 1.05
var _da_hoi := false

func vao(_du_lieu: Dictionary = {}) -> void:
	nc.dang_do = false
	_da_hoi = false
	if Tui.binh_con <= 0:
		di("dung")

func chay(delta: float) -> void:
	# Uống thì đi chậm được, không đứng chôn chân — Elden Ring cho, và nó làm
	# cho việc uống là quyết định về KHOẢNG CÁCH chứ không phải về may rủi.
	if nc.huong_nhap != Vector3.ZERO:
		nc.dat_toc_ngang(nc.huong_nhap, nc.toc_do_di * 0.35)
	else:
		nc.dung_lai(delta)

	if not _da_hoi and t >= T_HOI_MAU:
		_da_hoi = true
		Tui.binh_con -= 1
		nc.hoi_mau(nc.mau_toi_da * 0.45)
		AmThanh.phat("uong")

	if t >= T_XONG:
		di("dung")

func cho_doi(ten: String) -> bool:
	return ten in ["trung_don", "chet", "vo_the", "dung"]
