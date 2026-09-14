extends TTQuai

## Một đòn của quái. Ba khung đọc từ data/don_quai.csv, y hệt người chơi.
##
## ĐÒN PHẢI ĐỌC ĐƯỢC (mục 5.4) — đó là linh hồn của souls-like. Ở đây điều đó
## có nghĩa cụ thể:
##   1. t_vung của mọi đòn đều >= 0.5s. Không đòn nào ra nhanh hơn phản xạ.
##   2. ThanQuai ngả người rõ rệt trong khung vung tay, nhìn là biết sắp có.
##   3. Đòn lao tới (cột lao_toi) chỉ lao TRONG khung gây sát thương, không
##      lao trong khung vung — nếu không thì né đúng lúc vẫn ăn đòn.

var _don := "bo_cham"
var _m := {}
var _da_bat := false
var _da_tat := false

func vao(du_lieu: Dictionary = {}) -> void:
	_don = String(du_lieu.get("don", "bo_cham"))
	_m = VocabDB.don_quai_cua(_don)
	_da_bat = false
	_da_tat = false
	# Khoá hướng ngay lúc bắt đầu vung. Quái bám theo người chơi suốt cả đòn
	# thì né thành vô nghĩa — đó là lỗi thiết kế hay gặp nhất ở game bắt chước
	# souls.
	q.xoay_ve(q.huong_toi_nguoi_choi(), 1.0, 999.0)

func ra() -> void:
	q.hop_don.monitoring = false

func chay(delta: float) -> void:
	var t_tu := float(_m.get("t_dam_tu", 0.8))
	var t_den := float(_m.get("t_dam_den", t_tu + 0.16))
	var het := t_den + float(_m.get("t_hoi", 0.8))
	var lao := float(_m.get("lao_toi", 0.0))

	if t < t_tu:
		q.dung_lai(delta, 12.0)
	elif t < t_den and lao > 0.0:
		q.velocity.x = q.than.global_transform.basis.z.x * lao
		q.velocity.z = q.than.global_transform.basis.z.z * lao
	else:
		q.dung_lai(delta, 18.0)

	if not _da_bat and t >= t_tu:
		_da_bat = true
		var hd := q.hop_don as QuaiHopDon
		hd.dat_don(_don, q)
		q.hop_don.monitoring = true
	if _da_bat and not _da_tat and t >= t_den:
		_da_tat = true
		q.hop_don.monitoring = false

	if t >= het:
		di("quai_duoi")

func tien_do() -> float:
	var t_den := float(_m.get("t_dam_den", 1.0))
	return clampf(t / maxf(t_den + float(_m.get("t_hoi", 0.8)), 0.01), 0.0, 1.0)

## Khung vung tay đã tới đâu (0→1). ThanQuai dùng để ngả người.
func tien_do_vung() -> float:
	return clampf(t / maxf(float(_m.get("t_dam_tu", 0.8)), 0.01), 0.0, 1.0)

## Cam kết: quái cũng không huỷ đòn được. Đối xứng với người chơi — nếu quái
## huỷ được mà người chơi không, trận đánh thành bất công chứ không thành khó.
func cho_doi(ten: String) -> bool:
	return ten in ["quai_trung_don", "quai_chet", "quai_vo_the", "quai_duoi"]
