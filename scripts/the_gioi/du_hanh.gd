extends Node

## Du hành giữa các vùng (mốc 6). Autoload: gọi bằng "DuHanh".
##
## Bảy vùng nối nhau thành một CHUỖI, khai ở cột `mo_khi` của vung.csv: vùng B
## mở khi đã tới được vùng A. Không có bản đồ nhánh, không có cửa khoá cần
## chìa — chuỗi là đủ cho bản đầu, và nó đọc được thẳng từ CSV nên thêm vùng
## thứ tám chỉ là thêm một dòng.
##
## Vì sao du hành từ BIA ĐÁ chứ không phải đi bộ qua ranh giới: mỗi vùng là một
## scene riêng với địa hình riêng, streaming riêng, môi trường riêng. Nối liền
## chúng trong một không gian toạ độ đòi phải quản lý cả bảy bộ streaming cùng
## lúc — việc của một dự án có người làm tối ưu, không phải của mốc 6. Souls
## cũng đi bằng bia đá; người chơi không thấy thiếu.
##
## KHÔNG hardcode tên vùng nào ở đây. Tất cả đọc từ `vung.csv`.

const CANH_VUNG := "res://scenes/the_gioi/vung_dat.tscn"

signal da_du_hanh(ma_vung: String)

## Những vùng người chơi đã đặt chân tới. Vùng đầu chuỗi luôn mở sẵn.
var da_toi := {}

func _ready() -> void:
	mo_vung_dau()

## Vùng đầu chuỗi: vùng không có `mo_khi`. Suy ra chứ không viết tên vào code.
func vung_dau() -> String:
	for v in VocabDB.vung:
		if String(v.get("mo_khi", "")) == "":
			return String(v["ma"])
	return "" if VocabDB.vung.is_empty() else String(VocabDB.vung[0]["ma"])

func mo_vung_dau() -> void:
	var d := vung_dau()
	if d != "":
		da_toi[d] = true

## Vùng này đã mở chưa. Mở khi vùng ghi ở `mo_khi` đã tới được.
func da_mo(ma: String) -> bool:
	if da_toi.has(ma):
		return true
	var v := VocabDB.vung_cua(ma)
	if v.is_empty():
		return false
	var truoc := String(v.get("mo_khi", ""))
	return truoc == "" or da_toi.has(truoc)

## Danh sách vùng hiện ở bia đá: mã, tên, đã mở chưa, đang ở đó không.
func danh_sach() -> Array:
	var ds: Array = []
	for v in VocabDB.vung:
		var ma := String(v["ma"])
		ds.append({
			"ma": ma,
			"ten": String(v.get("ten", ma)),
			"ten_chu": String(v.get("ten_chu", "")),
			"mo": da_mo(ma),
			"dang_o": ma == TheGioi.vung_hien_tai,
			"cap": int(v.get("cap", 0)),
		})
	return ds

## Đi tới một vùng. Đổi scene, nên mọi thứ đang mở phải đóng trước.
func di_toi(ma: String) -> bool:
	if not da_mo(ma) or ma == TheGioi.vung_hien_tai:
		return false
	var v := VocabDB.vung_cua(ma)
	if v.is_empty():
		return false
	da_toi[ma] = true
	TheGioi.vung_hien_tai = ma
	# Quên bảng "quái đã hạ" của vùng cũ? KHÔNG. Souls-like: đi rồi quay lại
	# thì quái sống lại, nhưng đó là việc của lúc nghỉ ở bia / chết, không phải
	# của việc đổi vùng. Giữ nguyên bảng ở đây là cố ý.
	da_du_hanh.emit(ma)
	_doi_canh(ma)
	return true

func _doi_canh(ma: String) -> void:
	var cay := get_tree()
	var canh := load(CANH_VUNG) as PackedScene
	if canh == null:
		return
	# Đổi scene phải hoãn: hàm này gọi từ trong một nút bấm của màn bia đá, mà
	# màn đó là con của scene sắp bị huỷ.
	cay.paused = false
	_doi_that.call_deferred(canh, ma)

func _doi_that(canh: PackedScene, ma: String) -> void:
	var cay := get_tree()
	var cu := cay.current_scene
	var moi := canh.instantiate() as VungDat
	if moi == null:
		return
	moi.ma_vung = ma
	if cu != null:
		cay.root.remove_child(cu)
		cu.queue_free()
	cay.root.add_child(moi)
	cay.current_scene = moi

func thanh_du_lieu() -> Dictionary:
	return {"da_toi": da_toi.keys()}

func tu_du_lieu(d: Dictionary) -> void:
	da_toi.clear()
	for m in d.get("da_toi", []):
		da_toi[String(m)] = true
	mo_vung_dau()
