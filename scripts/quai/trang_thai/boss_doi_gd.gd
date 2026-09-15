extends TTQuai

## Khung chuyển giai đoạn của boss. Đứng ngây, bất tử, đổi màu, rồi đánh tiếp.
##
## Vì sao nó phải BẤT TỬ (xử ở Boss.an_don): đây là khung báo trước, không phải
## khung tặng đòn miễn phí. Cho ăn đòn ở đây thì người chơi học được đúng một
## điều — cứ thấy boss đổi dạng là xông vào chém — và cả đoạn dựng không khí
## thành ra tự phạt chính nó.
##
## Vì sao nó phải NHÌN THẤY ĐƯỢC: người chơi vừa mất một phút học thuộc moveset
## một, giờ luật đổi. Không báo thì họ chết vì một đòn chưa từng thấy và đổ cho
## game ăn gian — mà họ sẽ đúng.

func vao(_du_lieu: Dictionary = {}) -> void:
	q.dang_ngay = true
	q.velocity = Vector3.ZERO
	var b := q as Boss
	if b != null:
		b.to_lai_than()
		var h := get_tree().get_first_node_in_group("hud")
		if h != null and h.has_method("bao"):
			h.call("bao", "%s — giai đoạn hai" % q.ten_hien())

func ra() -> void:
	q.dang_ngay = false

func chay(delta: float) -> void:
	q.dung_lai(delta, 30.0)
	if t >= Boss.NGAY_DOI_GIAI_DOAN:
		di("quai_duoi")

func tien_do() -> float:
	return clampf(t / Boss.NGAY_DOI_GIAI_DOAN, 0.0, 1.0)

## Không gì cắt được khung này trừ cái chết — mà boss bất tử ở đây nên cả cái
## chết cũng không tới được. Đúng chủ ý.
func cho_doi(ten: String) -> bool:
	return ten in ["quai_chet", "quai_duoi"]
