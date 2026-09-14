extends TTQuai

## Chết: rơi hồn và bộ thủ, đổ xuống, rồi biến mất.

const T_TAN := 1.6
var _da_roi := false

func vao(_du_lieu: Dictionary = {}) -> void:
	q.velocity = Vector3.ZERO
	q.hop_don.monitoring = false
	# Tắt va chạm để xác không chặn đường người chơi.
	q.set_collision_layer_value(3, false)
	_da_roi = false

func chay(delta: float) -> void:
	q.dung_lai(delta, 40.0)
	if not _da_roi and t >= 0.05:
		_da_roi = true
		q.roi_do()
		q.chet_roi.emit(q)
	if t >= T_TAN:
		q.queue_free()

func tien_do() -> float:
	return clampf(t / T_TAN, 0.0, 1.0)

func cho_doi(_ten: String) -> bool:
	return false
