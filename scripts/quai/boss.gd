class_name Boss
extends Quai

## Boss hai giai đoạn (mốc 5). Mọi thông số đọc từ data/boss.csv.
##
## Vì sao kế thừa Quai chứ không viết lại: boss KHÁC quái thường đúng ba chỗ —
## đọc bảng dữ liệu khác, đổi moveset giữa trận, và chết thì dạy chữ. Mọi thứ
## còn lại (máy trạng thái, hộp đòn, tư thế, vỡ thế, kết liễu) phải giống hệt,
## vì người chơi học cách đọc đòn ở quái thường rồi mang kiến thức đó vào cửa
## boss. Viết riêng một cây state machine cho boss là tự tay phá bài học đó.
##
## GIAI ĐOẠN HAI là toàn bộ điểm của mốc này. Máu tụt dưới `nguong_gd2` thì:
##   · đứng ngây một nhịp — đây là khung BÁO TRƯỚC, không phải khung tặng đòn
##     miễn phí, nên nó bất tử; đánh vào lúc này không ăn gì
##   · đổi sang `moveset_2`, dài hơn `moveset_1` một hai đòn
##   · đổi màu thân, HUD nháy tên
##
## Không có giai đoạn ba, và đừng thêm: hai giai đoạn là đủ để người chơi phải
## học lại giữa trận, ba giai đoạn thì thành bài kiểm tra trí nhớ.

signal doi_giai_doan(gd: int)
signal bat_dau_tran(b: Boss)
signal ket_thuc_tran(b: Boss, thang: bool)

## Đứng ngây bấy nhiêu giây lúc chuyển giai đoạn. Đủ dài để NHÌN THẤY là nó
## đang đổi, đủ ngắn để không thành nghỉ giải lao.
const NGAY_DOI_GIAI_DOAN := 2.0

var giai_doan := 1
var _da_doi := false
var _da_chao := false

func _ready() -> void:
	add_to_group("boss")
	super()

## Đọc boss.csv thay vì quai.csv. Phần còn lại của Quai._nap_du_lieu() dùng
## chung được vì hai bảng cố ý trùng tên cột ở những chỗ quan trọng.
func _nap_du_lieu() -> void:
	d = VocabDB.boss_cua(ma).duplicate()
	if d.is_empty():
		push_warning("Khong co boss '%s' trong boss.csv" % ma)
	_bu_cot_thieu()
	mau_toi_da = float(d.get("mau", 1000))
	mau = mau_toi_da
	tu_the_max = float(d.get("the_dung", 60)) * 2.2 + 40.0
	ngu_hanh = String(d.get("ngu_hanh", ""))
	_dung_than()
	Tui.doi_trang_bi.connect(_cap_nhat_nhan)
	doi_mau.emit(mau, mau_toi_da)

## boss.csv cố ý ngắn hơn quai.csv: nó không khai `tam_phat_hien`, `tam_danh`,
## `toc_do_di`, `toc_do_duoi`, `hon`. Suy ra từ mấy cột nó CÓ, thay vì bắt
## người điền lại năm cột nữa cho sáu con boss.
##
## Đây là chỗ sửa một lỗi thật: cột `toc_do` của boss.csv trước đây KHÔNG AI
## ĐỌC — `Quai.di_ve()` tìm `toc_do_duoi`, mà boss không có cột đó, nên mọi
## boss đều chạy ở tốc độ mặc định 4.0 bất kể bảng ghi gì. Thần Băng lẽ ra
## chậm chạp (2.7) thì đuổi nhanh hơn cả Mẹ Làng.
##
## Ghi vào bản sao `d`, không vào hàng gốc trong VocabDB — hàng đó dùng chung
## cho mọi con cùng mã.
func _bu_cot_thieu() -> void:
	var toc := float(d.get("toc_do", 3.0))
	var bk := float(d.get("ban_kinh", 0.9))
	d["toc_do_duoi"] = toc
	d["toc_do_di"] = toc * 0.6
	# Cửa boss là phòng kín: bước vào là nó thấy. Để tầm ngắn như quái thường
	# thì người chơi đi lại được nửa phòng mà boss vẫn đứng ngủ.
	d["tam_phat_hien"] = 32.0
	# Tầm đánh theo VÓC DÁNG nó: con to tay dài hơn, và người chơi đọc được
	# điều đó bằng mắt trước khi ăn đòn đầu tiên.
	d["tam_danh"] = bk * 2.2 + 1.8
	d["hon"] = d.get("thuong_hon", 500)
	d["rot_bo_thu"] = []

func _dung_than() -> void:
	var cao := float(d.get("cao", 2.4))
	var bk := float(d.get("ban_kinh", 0.9))
	var c := hinh.shape as CapsuleShape3D
	if c != null:
		c.height = cao
		c.radius = bk
	hinh.position.y = cao * 0.5
	var tk := than as ThanQuai
	if tk != null:
		tk.dung_theo(cao, bk, ngu_hanh, ten_hien())
		tk.cap_nhat(ten_hien(), 1.0)

# --- Hai giai đoạn ---------------------------------------------------

## Moveset theo giai đoạn đang ở. Quai.cac_don() đọc cột `moveset`; boss có hai
## cột nên phải cài đè.
func cac_don() -> Array:
	var cot := "moveset_2" if giai_doan == 2 else "moveset_1"
	var m: Array = d.get(cot, [])
	if m.is_empty():
		m = d.get("moveset_1", [])
	return m if not m.is_empty() else ["bo_cham"]

func nguong_gd2() -> float:
	return float(d.get("nguong_gd2", 0.5))

## Ăn đòn. Chặn đúng hai chỗ so với quái thường: bất tử lúc đang đổi giai đoạn,
## và kiểm ngưỡng sau khi trừ máu.
func an_don(sat_thuong: int, pha_the: float, tu_dau: Vector3, hanh: String = "") -> int:
	if may.ten_hien_tai == "boss_doi_gd":
		# Khung chuyển giai đoạn là khung BÁO TRƯỚC. Cho ăn đòn ở đây thì người
		# chơi học được rằng cứ thấy boss đổi dạng là xông vào chém miễn phí,
		# và cả đoạn dựng không khí thành ra tự phạt mình.
		return 0
	var st := super(_sat_thuong_that(sat_thuong), pha_the, tu_dau, hanh)
	_thu_doi_giai_doan()
	return st

## BOSS 无 — câu đố về chính cơ chế của game (mục 14.8 của bản yêu cầu).
##
## Nó không có hành, nên ngũ hành không cắn được. Và luật riêng của nó: **vũ
## khí càng nhiều chữ càng yếu trước nó.** Cách thắng là CỞI HẾT chữ khắc ra —
## đánh nó bằng một cây vũ khí trần.
##
## Vì sao luật này đáng có: cả game dạy người chơi rằng thêm chữ là mạnh thêm.
## Con cuối đảo ngược đúng câu đó, và người chơi chỉ giải được nếu đã HIỂU cơ
## chế chứ không chỉ làm theo. Nó cũng khớp cốt truyện: 无 là sự trống rỗng,
## thứ ăn chữ — càng đưa chữ cho nó càng nuôi nó.
##
## Nhận biết bằng CỘT `ngu_hanh` TRỐNG trong boss.csv, không phải bằng mã 'vo'.
## Luật 1: code không được biết con boss nào tên gì.
func _sat_thuong_that(st: int) -> int:
	if String(d.get("ngu_hanh", "")) != "":
		return st
	var vk = Tui.vu_khi_dang_cam()
	if vk == null:
		return st
	# Mỗi chữ BỔ NGHĨA khắc trên vũ khí ăn mất một phần sát thương. Chữ trung
	# tâm không tính — cởi hết thì vẫn còn cây kiếm trần, và đó là đáp án.
	var them := maxi(0, vk.ten.size() - 1)
	if them <= 0:
		return st
	return maxi(1, int(round(float(st) * pow(HS_MOI_CHU_KHAC, float(them)))))

## Mỗi chữ khắc thừa nhân sát thương với ngần này khi đánh boss không hành.
## 0.55 nghĩa là ba chữ còn 17% — đủ đau để người chơi phải nghĩ, chưa tới mức
## không bao giờ thắng nổi nếu cứ cố.
const HS_MOI_CHU_KHAC := 0.55

func _thu_doi_giai_doan() -> void:
	if _da_doi or giai_doan != 1 or not con_song():
		return
	if mau / maxf(mau_toi_da, 1.0) > nguong_gd2():
		return
	_da_doi = true
	giai_doan = 2
	tu_the = 0.0
	may.doi("boss_doi_gd")
	AmThanh.phat("gam_boss", 0.8, 1.2)
	doi_giai_doan.emit(2)

## Đổi màu thân khi sang giai đoạn hai — người chơi phải NHÌN ra là luật vừa
## đổi, không phải đọc được trên thanh máu.
func to_lai_than() -> void:
	var tk := than as ThanQuai
	if tk != null and tk.has_method("to_lai"):
		tk.call("to_lai", NguHanh.mau_cua(ngu_hanh).lerp(Color(0.95, 0.30, 0.25), 0.55))

# --- Vào trận / hết trận ---------------------------------------------

func _physics_process(delta: float) -> void:
	super(delta)
	if not _da_chao and thay_nguoi_choi():
		_da_chao = true
		AmThanh.phat("gam_boss")
		_noi_hud(self)
		if khong_hanh():
			_bao("Nó không có hành. Chữ khắc trên vũ khí đang nuôi nó.")
		bat_dau_tran.emit(self)

## Chết. Boss dạy chữ — đó là phần thưởng thật của cả trận, hơn cả hồn.
func roi_do() -> void:
	Tui.them_hon(int(d.get("thuong_hon", 500)))
	TheGioi.danh_dau_ha(id_on_dinh)
	# Cột `thuong_chu` là danh sách chữ HỌC ĐƯỢC ngay, không phải bộ thủ phải
	# ghép. Hạ boss là mở khoá luôn mấy chữ đó ở mọi món đồ cũ trong túi —
	# khoảnh khắc "cả kho đồ sáng lên" của mục 4.1, đặt đúng chỗ đáng nhớ nhất.
	var chu_moi: Array[String] = []
	for c in d.get("thuong_chu", []):
		var s := String(c)
		if s == "" or TriNho.doc_duoc(s):
			continue
		TriNho.hoc(s)
		chu_moi.append(s)
	if not chu_moi.is_empty():
		Tui.doi_trang_bi.emit()
		_bao("Học được " + " ".join(chu_moi))
	_noi_hud(null)
	ket_thuc_tran.emit(self, true)

## Bật / tắt thanh máu boss ở đáy màn hình. Tìm HUD bằng nhóm, để boss đặt ở
## bản đồ nào cũng nối được mà không cần ai đi dây tay.
func _noi_hud(b: Boss) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("theo_doi_boss"):
		h.call("theo_doi_boss", b)

func _bao(dong: String) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h != null and h.has_method("bao"):
		h.call("bao", dong)

## Boss này có phải con không hành không — con mà ngũ hành vô dụng và chữ khắc
## phản chủ. Giao diện dùng để nhắc người chơi một câu.
func khong_hanh() -> bool:
	return String(d.get("ngu_hanh", "")) == ""

## Câu boss nói lúc vào trận. Nằm ở cột `loi_thoai` của boss.csv.
func loi_thoai() -> String:
	return String(d.get("loi_thoai", ""))
