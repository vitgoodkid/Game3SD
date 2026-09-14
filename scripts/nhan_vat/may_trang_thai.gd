class_name MayTrangThai
extends Node

## Máy trạng thái tường minh. Dùng chung cho người chơi và quái.
##
## Vì sao BẮT BUỘC (mục 9 của bản yêu cầu): souls-like có quá nhiều trạng thái
## loại trừ nhau — đứng, đi, chạy, lăn, đánh 1/2/3, đánh nặng, nạp, đỡ, parry,
## trúng đòn, vỡ thế, uống thuốc, kết liễu, chết. Viết bằng chuỗi `if` như
## player.gd của bản 2D thì tới mốc 5 phải đập đi viết lại toàn bộ.
##
## Quy ước: mỗi state là một node con, script kế thừa TrangThaiMay, tên node
## chính là tên state (viết thường, không dấu).

signal doi_trang_thai(cu: String, moi: String)

## State bắt đầu. Để trống thì lấy node con đầu tiên.
@export var trang_thai_dau := ""

var chu: Node = null           ## chủ nhân (CharacterBody3D)
var hien_tai: TrangThaiMay = null
var ten_hien_tai := ""
var _bang := {}
## Bao lâu rồi ở trong state này. Nhiều luật souls tính theo mốc thời gian
## trong một đòn nên state nào cũng cần, để đây khỏi mỗi state tự đếm.
var t := 0.0

func khoi_dong(chu_nhan: Node) -> void:
	chu = chu_nhan
	for con in get_children():
		if con is TrangThaiMay:
			_bang[con.name.to_lower()] = con
			con.may = self
			con.chu = chu_nhan
	var dau := trang_thai_dau.to_lower()
	if dau == "" or not _bang.has(dau):
		dau = String(_bang.keys()[0]) if not _bang.is_empty() else ""
	if dau != "":
		doi(dau)

func co(ten: String) -> bool:
	return _bang.has(ten.to_lower())

## Đổi sang state khác. `du_lieu` truyền thẳng cho vao() — dùng để nói cho
## state đánh biết đang đánh đòn nào, cho state trúng đòn biết hướng nào.
func doi(ten: String, du_lieu: Dictionary = {}) -> void:
	var k := ten.to_lower()
	if not _bang.has(k):
		push_warning("Khong co trang thai '%s'" % ten)
		return
	var cu := ten_hien_tai
	if hien_tai != null:
		hien_tai.ra()
	hien_tai = _bang[k]
	ten_hien_tai = k
	t = 0.0
	hien_tai.vao(du_lieu)
	doi_trang_thai.emit(cu, k)

func chay(delta: float) -> void:
	if hien_tai == null:
		return
	t += delta
	hien_tai.chay(delta)

func nhap(su_kien: InputEvent) -> void:
	if hien_tai != null:
		hien_tai.nhap(su_kien)

## Chuyển tiếp có điều kiện — state chỉ đổi nếu state hiện tại CHO PHÉP.
## Đây là chỗ cài "cam kết đòn đánh" (mục 5.1): state đánh trả về false cho
## mọi thứ trừ trúng đòn, nên đã vung là không huỷ được.
func xin_doi(ten: String, du_lieu: Dictionary = {}) -> bool:
	if hien_tai != null and not hien_tai.cho_doi(ten):
		return false
	doi(ten, du_lieu)
	return true
