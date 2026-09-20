class_name ThanMoHinh
extends Node3D

## Thân người chơi bằng MODEL THẬT, thay cho khối hộp của `than_khoi.gd`.
##
## Cùng một hàm `dien()` với ThanKhoi, cùng chữ ký — nên `NguoiChoi._dien_hinh()`
## gọi cái nào cũng được, và tầng luật không biết là đã đổi gì.
##
## LÀ CHỖ ĐỂ NHÌN, KHÔNG HƠN. Luật này chép nguyên từ `than_khoi.gd` vì nó đã
## cắn một lần: hộp đòn từng bị gắn vào khớp bị hoạt ảnh xoay, và một thay đổi
## thuần trang trí làm cả game hết trúng đòn mà không lỗi nào nổ ra.
##   - `GanTayPhai` (mang hộp đòn) là node ANH EM trong scene, không phải con
##     của bộ xương. Đừng bao giờ gắn nó vào `BoneAttachment3D`.
##   - Vũ khí và khiên thì ngược lại: chúng CHỈ để nhìn, nên gắn vào xương bàn
##     tay là đúng, và phải gắn thế mới cầm ra hình cầm.
##
## MODEL KHÔNG CÓ ANIMATION NÀO. Đã đo bằng `tools/soi_model.tscn`: 41 xương,
## tên kiểu Unreal (Pelvis / Spine_01..03 / Upperarm_L / Calf_R ...), không một
## AnimationPlayer nào. Nên vẫn phải xoay khớp bằng tay y như hồi còn khối hộp
## — chỉ khác là giờ xoay xương thật nên ra hình người.
##
## Model đứng ở tư thế chữ T. Tư thế nghỉ THẬT của nhân vật phải hạ tay xuống
## trước đã, xem `GOC_HA_TAY`.

## Cao bấy nhiêu mét. Model gốc cao 1.68m, phóng lên cho khớp luật của repo
## (CLAUDE.md: nhân vật cao 1.8m, gốc toạ độ dưới chân).
const CAO := 1.8

## Tên xương cần tới, và tên THAY THẾ cho từng kiểu rig.
##
## Ba bộ tên vì ba nguồn model. Bộ asset elf dùng kiểu Unreal (`Upperarm_L`).
## Mixamo dùng `mixamorig:LeftArm` — NHƯNG trình nhập FBX của Godot đổi dấu
## hai chấm thành gạch dưới, nên trong game nó là `mixamorig_LeftArm`.
##
## Chi tiết một ký tự đó đã suýt nuốt cả buổi: tìm theo tên có dấu hai chấm
## thì `find_bone()` trả -1 cho MỌI xương, mỗi xương đẩy ra một push_warning
## rồi thôi — không lỗi nào nổ, nhân vật chỉ đứng nguyên tư thế chữ T trượt
## quanh map. Nhận cả ba kiểu thì đổi model không còn là canh bạc.
const XUONG := {
	"chau":   ["Pelvis", "mixamorig:Hips", "mixamorig_Hips"],
	"song":   ["Spine_02", "mixamorig:Spine1", "mixamorig_Spine1"],
	"nguc":   ["Spine_03", "mixamorig:Spine2", "mixamorig_Spine2"],
	"dau":    ["Head", "mixamorig:Head", "mixamorig_Head"],
	"vai_t":  ["Upperarm_L", "mixamorig:LeftArm", "mixamorig_LeftArm"],
	"khuyu_t": ["Lowerarm_L", "mixamorig:LeftForeArm", "mixamorig_LeftForeArm"],
	"ban_t":  ["Hand_L", "mixamorig:LeftHand", "mixamorig_LeftHand"],
	"vai_p":  ["Upperarm_R", "mixamorig:RightArm", "mixamorig_RightArm"],
	"khuyu_p": ["Lowerarm_R", "mixamorig:RightForeArm", "mixamorig_RightForeArm"],
	"ban_p":  ["Hand_R", "mixamorig:RightHand", "mixamorig_RightHand"],
	"dui_t":  ["Thigh_L", "mixamorig:LeftUpLeg", "mixamorig_LeftUpLeg"],
	"goi_t":  ["Calf_L", "mixamorig:LeftLeg", "mixamorig_LeftLeg"],
	"dui_p":  ["Thigh_R", "mixamorig:RightUpLeg", "mixamorig_RightUpLeg"],
	"goi_p":  ["Calf_R", "mixamorig:RightLeg", "mixamorig_RightLeg"],
}

## Thư mục chứa file động tác tải từ Mixamo. Tên file quyết định động tác đó
## dùng cho trạng thái nào — xem `DONG_TAC`.
const THU_MUC_DONG_TAC := "res://assets/model/dong_tac/"
## Bộ động tác thứ hai: lúc ĐÃ CẤT hoặc CHƯA TRANG BỊ vũ khí.
##
## Cất kiếm rồi mà vẫn chạy bằng dáng ôm kiếm hai tay thì phần thưởng của phím
## R (nhanh hơn 30%, tốn ít thể lực hơn) không có mặt nào để đọc — người chơi
## chỉ thấy con số trong thanh thể lực đổi, mà không ai nhìn thanh thể lực lúc
## đang chạy. Đổi hẳn dáng đi thì mắt đọc ra ngay "giờ đang rảnh tay".
##
## Khi đã trang bị nhưng đang cất, thiếu file nào ở đây thì tạm mượn bộ cầm
## kiếm. Còn chưa trang bị gì thì KHÔNG được mượn: chỉ có vũ khí thật sự mới
## được dùng dáng cầm kiếm; thiếu clip tay không thì rơi về dáng gõ bằng code.
const THU_MUC_KHONG_VU_KHI := "res://assets/model/dong_tac/khong_vu_khi/"
## Tiền tố cho clip của bộ không vũ khí, để hai bộ ở chung một thư viện.
const TIEN_TO_KVK := "kvk_"

## Trạng thái của máy trạng thái -> tên file động tác (không đuôi).
##
## Thiếu file nào thì trạng thái đó tự quay về dáng gõ tay trong file này. Nhờ
## vậy tải được động tác nào là đẹp ngay động tác đó, không phải đợi đủ bộ.
const DONG_TAC := {
	"dung": "dung", "di": "di", "chay_nhanh": "chay",
	"lan": "lan", "nhay": "nhay",
	"do_don": "do_don", "do_phan": "do_phan",
	"trung_don": "trung_don", "vo_the": "vo_the",
	"chet": "chet", "uong": "uong", "ket_lieu": "ket_lieu",
	"rut_vu_khi": "rut_vu_khi", "cat_vu_khi": "cat_vu_khi",
	# Mặc định của `leo` là dáng LEO LÊN. Leo xuống có clip riêng, chọn theo
	# `TrangThaiLeo.ten_dien()` ở `_dong_tac_cho()` — khuôn giống `chet_*`.
	"leo": "leo_len",
}
## Động tác nào phải LẶP.
##
## Mixamo xuất ra clip không lặp, nên đứng yên / đi / chạy / thủ sẽ chạy hết
## một vòng rồi ĐỨNG CHẾT ở khung cuối. Không lỗi nào nổ ra — nhân vật chỉ đơ
## ra giữa lúc đang đi, và trông y như game bị treo.
const DONG_TAC_LAP := ["dung", "di", "di_lui", "di_trai", "di_phai",
	"chay", "chay_lui", "chay_trai", "chay_phai", "do_don",
	# Hai clip leo là VÒNG LẶP TẠI CHỖ (2.00s, hông đứng yên ở 0.69m — đo bằng
	# `tools/do_nhip_don.tscn`). Đúng khuôn thang: code đẩy người lên, clip chỉ
	# quay vòng tay chân. Không lặp thì leo quá 2 giây là đứng chết ở khung
	# cuối trong khi người vẫn đang trôi lên.
	"leo_len", "leo_xuong"]

## Đòn đánh tra theo TÊN ĐÒN chứ không theo trạng thái — bảy loại đòn dùng
## chung một state `danh`, mà chúng phải nhìn khác nhau.
## **`nap` dùng CHUNG clip với `nang`, không có clip riêng.** Cú nạp không
## phải một động tác khác — nó là ĐÚNG cú vung ấy, bị giữ lại ở đỉnh. Cho nó
## một clip riêng là bắt người chơi xem HAI động tác cho MỘT nhát chém: clip
## giữ chạy xong, rồi clip vung chạy LẠI TỪ ĐẦU và giơ kiếm lên lần thứ hai.
##
## Đã hỏng đúng như vậy: `nap.fbx` vốn là một clip ĐỨNG THỞ — đo bằng
## `tools/soi_dong_tac.tscn`, tay phải quanh quẩn ở độ cao NGHỈ 0.70–0.80m
## suốt 3.5 giây, thanh kiếm không hề giơ lên. Nên gồng đòn nặng là thấy nhân
## vật đứng thở, nhả ra mới thấy vung. Xem `_ghim_clip()`.
const DONG_TAC_DON := {
	"nhe_1": "danh_1", "nhe_2": "danh_2", "nhe_3": "danh_3",
	"nang": "nang", "nang_nap": "nang", "nap": "nang",
	"chay": "danh_chay", "nhay": "danh_nhay", "nhay_nang": "danh_nhay",
	"phan_do": "phan_do",
}

## QUÃNG CHẾT TRONG CLIP — phần bị NHẢY QUA khi phát.
##
## Clip mua sẵn dựng cho phim chứ không cho game, nên giữa chừng chúng nằm
## chờ. Clip Bổ nằm chết dí ở đáy cú bổ **0.77 giây** trước khi thu tay về, và
## nếu để nguyên thì mỗi nhát Bổ người chơi đứng hình gần một nhịp thở.
##
## Nhảy qua chứ KHÔNG cắt cụt ở đó: đoạn thu tay về thế đứng nằm SAU quãng
## chết, mà đoạn thu tay chính là khung hồi đòn — chỗ đối phương phản đòn.
## Cắt cụt là mất luôn khung hồi, và đòn nặng thành không có cái giá nào.
##
## Đo bằng `tools/do_nhip_don.tscn`, đừng gõ tay: nó quét vận tốc tâm lưỡi
## kiếm dọc clip và in ra đúng bảng này. Đổi một file `.fbx` thì chạy lại.
##
## Mốc tính bằng giây CỦA CLIP GỐC. `moveset.csv` thì ghi theo giây ĐÃ CẮT —
## hai hệ quy chiếu khác nhau, `_clip_tu_don()` là chỗ đổi qua lại.
const CAT_CHET := {
	# Quãng đầu là chỗ clip tự GIỮ Ở ĐỈNH giữa cú giơ lên và cú bổ xuống.
	# Nó gánh hai việc: đánh thường thì nhảy qua, còn gồng thì ghim vào đúng
	# đó (`moveset.csv` khai `t_vung` = 0.89 cho dòng này).
	# Quãng sau là chỗ thanh kiếm nằm chết dí ở đáy cú bổ hơn nửa giây.
	# Quãng ba là đuôi clip: lưỡi kiếm đã về đúng chỗ nó đứng ở khung đầu và
	# đã dừng hẳn, phần còn lại chỉ là clip khép vòng cho ghép lặp được.
	"nang": [[0.89, 1.17], [2.90, 3.43], [4.24, 4.80]],
	"phan_do": [[1.70, 1.73]],
}

## Hạ tay từ tư thế chữ T xuống cạnh sườn, tính bằng độ.
##
## Không có bước này thì nhân vật chạy quanh map với hai tay dang ngang — và
## mọi dáng đánh về sau đều tính sai gốc, vì chúng cộng lên tư thế nghỉ.
const GOC_HA_TAY := 72.0
## Hạ tay PHẢI dùng dấu ngược với tay trái hay không.
##
## Hai xương vai đối xứng gương nhau, nên cùng một góc trong hệ của cha có thể
## hạ bên này mà GIƠ bên kia. Không đoán được từ tên rig — phải chạy
## `tools/chup_tu_the.tscn` rồi nhìn. Bản đầu để -1 và tay phải chỉ thẳng lên
## trời suốt mọi tư thế.
const DAU_TAY_PHAI := 1.0
## Trục xoay cả thân nằm ở bấy nhiêu phần chiều cao, tính từ chân lên. 0.52 là
## quãng ngang hông — chỗ người thật cuộn quanh khi lăn.
const CHO_XOAY := 0.52

## Ba CÁCH CẦM, và trạng thái nào dùng cách nào.
##
## Thế cầm bám vào XƯƠNG BÀN TAY, mà mỗi clip xoay bàn tay một kiểu — nên MỘT
## thế không thể đúng cho mọi clip. Clip chạy đẩy thanh kiếm dựng đứng xuyên qua
## đầu trong khi đúng thế ấy ở dáng đứng lại đẹp.
##
## Thêm nhóm mới thì thêm một bộ ba `@export` và một dòng ở đây; không phải
## sửa chỗ nào khác.
const CAM_TAY := 0
const CAM_CHAY := 1
const CAM_LUNG := 2
## Trạng thái dùng thế cầm ĐI/CHẠY. Danh sách CHO PHÉP: state mới mặc định
## dùng thế trên tay, và đó là chiều an toàn.
const TT_DI_CHUYEN := ["di", "chay_nhanh"]
## Đổi giữa hai thế cầm TRÊN TAY mất bấy nhiêu giây. Bằng đúng thời gian hoà
## clip (0.12s) để hai chuyển động đi cùng nhau. Chuyển tay ⇄ lưng thì SNAP:
## hai bên neo vào hai xương khác nhau, nội suy giữa chúng là vô nghĩa.
const T_DOI_THE_CAM := 0.12

## Kẹp hệ số phát clip đi/chạy trong khoảng này.
##
## Clip Mixamo được dựng cho người đi ~0.8 m/s, còn game này cho nhân vật đi
## 4.45 m/s và chạy 8.01 m/s (đo được). Chênh tới 5 lần, và chênh đó ra mặt
## thành BÀN CHÂN TRƯỢT: chân bước một nhịp trong khi cả người đã đi hết năm
## nhịp đường. Mắt bắt ra ngay dù không gọi tên được — chủ dự án báo là "trôi",
## và báo đúng ở hướng dạt ngang, nơi chênh lệch tệ nhất (5.6 lần).
##
## Kẹp trên 2.6 vì trên nữa thì chân đảo nhanh tới mức thành hoạt hình tua.
## Kẹp dưới 0.5 để lúc đi rón rén không thành phim quay chậm.
const TOC_CLIP_MIN := 0.5
const TOC_CLIP_MAX := 2.6

@export var duong_model := "res://assets/model/nhan_vat_chinh.fbx"
@export var duong_texture := "res://assets/model/katz.jpg"
## Thư mục chứa model vũ khí, và atlas của chúng.
@export var thu_muc_vu_khi := "res://assets/model/vu_khi/"
@export var texture_vu_khi := "res://assets/model/vu_khi/Texture_MAp_sword.png"
## Model vũ khí cao bao nhiêu mét. Model gốc mỗi con một cỡ, phóng về đây cho
## thống nhất — kiếm hai tay dài hơn thì để số lớn hơn.
##
## 1.25 chứ không phải 1.55 vì nhân vật mới là kiểu chibi: cao 1.8m nhưng gần
## nửa số đó là cái đầu, nên bàn tay lúc buông chỉ ở 1.04m. Kiếm 1.55m cầm
## chúc xuống là nửa mét lưỡi cắm xuyên qua sàn — đo trong ảnh chụp tư thế,
## không phải đoán.
@export var vu_khi_dai := 1.50:
	set(v):
		vu_khi_dai = v
		_ap_lai_vu_khi(true)
## Nhân thêm vào cỡ vũ khí sau khi đã chuẩn hoá. Y là chiều DÀI, X là bề rộng
## (lưỡi + chắn tay), Z là bề DÀY.
##
## Tách khỏi `vu_khi_dai` để phóng to cây kiếm mà không phải tính lại chỗ đặt
## chuôi: muốn kiếm to hơn hẳn thì kéo cả ba lên, muốn bản lưỡi rộng ra mà
## không dài thêm thì chỉ kéo X.
@export var vu_khi_ti_le := Vector3.ONE:
	set(v):
		vu_khi_ti_le = v
		_ap_lai_vu_khi(true)
@export var mau_vu_khi := Color(0.80, 0.82, 0.86)

@export_group("Cầm trên tay")
## Vũ khí và khiên nằm ĐÂU trong lòng bàn tay, và quay hướng nào.
##
## Góc cầm thì ĐO ĐƯỢC, không phải đoán — và cách đo nằm ngay trong động tác.
##
## Clip kiếm hai tay giữ CẢ HAI bàn tay trên chuôi: đo được hai bàn tay cách
## nhau 13,7cm trong dáng `dung`. Nghĩa là trục thanh kiếm chính là vector từ
## bàn tay phải sang bàn tay trái, và đổi sang hệ toạ độ của khớp bàn tay phải
## thì ra `(-0.67, 0.38, 0.64)` — tức là góc mặc định ở dưới.
##
## Đo kiểu đó thì đổi model là chạy lại phép đo, không phải dò mò từng độ. Vẫn
## để chỉnh tay được vì phép đo không nói được VÒNG XOAY quanh chính trục ấy
## (bề dẹt của lưỡi quay hướng nào) — chỗ đó vẫn phải nhìn.
##
## Chạy `tools/chup_tu_the.tscn` rồi nhìn: kiếm phải chĩa ra khỏi nắm tay, và
## khiên phải dựng đứng che trước người chứ không nằm ngang như cái khay.
## Đo được, không đoán: trục Y của khớp bàn tay trỏ RA SAU LƯNG nhân vật, nên
## hướng ra trước là −Y của khớp. Xoay mesh +90° quanh X đưa trục dài của nó
## (local Z) về đúng −Y đó. Lệch cũng tính trong hệ khớp, nên "ra trước" là Y âm.
@export var vu_khi_lech := Vector3(-0.237, -0.003, 0.033):
	set(v):
		vu_khi_lech = v
		_ap_lai_vu_khi(false)
@export var vu_khi_xoay := Vector3(-114.9, 42.6, -134.4):
	set(v):
		vu_khi_xoay = v
		_ap_lai_vu_khi(false)
## THẾ CẦM LÚC ĐI / CHẠY.
##
## Mặc định bằng đúng thế trên tay, tức là thêm bộ này KHÔNG đổi gì cho tới
## khi có người vặn nó. Để nguyên thì game y như cũ; vặn bằng
## `tools/chinh_kiem.tscn`, chọn thế "ĐI / CHẠY".
@export var vu_khi_xoay_chay := Vector3(-114.9, 42.6, -134.4):
	set(v):
		vu_khi_xoay_chay = v
		_ap_lai_vu_khi(false)
@export var vu_khi_lech_chay := Vector3(-0.237, -0.003, 0.033):
	set(v):
		vu_khi_lech_chay = v
		_ap_lai_vu_khi(false)
@export var vu_khi_lan_chay := 95.0:
	set(v):
		vu_khi_lan_chay = v
		_ap_lai_vu_khi(false)
## LĂN quanh chính trục thanh kiếm, tính bằng độ — bề dẹt của lưỡi quay hướng nào.
##
## Tách riêng vì đây đúng là bậc tự do mà phép đo KHÔNG cho được: vector tay
## phải → tay trái nói được thanh kiếm nằm dọc theo hướng nào, nhưng không nói
## được nó xoay bao nhiêu quanh hướng đó. Chỉnh `vu_khi_xoay` để dò chỗ này là
## sai cách — đổi một thành phần Euler là lệch luôn cả trục kiếm.
@export var vu_khi_lan := 95.0:
	set(v):
		vu_khi_lan = v
		_ap_lai_vu_khi(false)
## Lăn lưỡi RIÊNG cho lúc treo sau lưng.
##
## Phải tách. Bản trước dùng CHUNG một con số cho cả hai thế, trong khi bàn
## chỉnh lại bày nó thành một dòng của TỪNG thế — nên chỉnh lăn lưỡi lúc đang
## xem thế "sau lưng" là đổi luôn thế trên tay, im lặng, và cái thế trên tay
## vừa chỉnh xong bị hỏng sau lưng người chỉnh. Chủ dự án dính đúng bẫy đó:
## hai ảnh gửi về ghi 95° và 39° cho cùng một con số.
@export var vu_khi_lan_lung := 39.0:
	set(v):
		vu_khi_lan_lung = v
		_ap_lai_vu_khi(false)
## Vũ khí nằm đâu trên LƯNG lúc đã cất, trong hệ xương sống.
##
## Treo ở ngang VAI PHẢI và lùi hẳn ra sau 20cm, không phải ngay giữa lưng.
## Bản trước để sát xương sống nên thanh kiếm chìm vào mông và hai chân — nhìn
## ra là lỗi dựng hình, không phải "đã cất". Lưỡi chĩa xuống chéo sang trái,
## mũi dừng ở khoảng 0.14m so với mặt đất (tính được, không phải dò).
@export var vu_khi_lech_lung := Vector3(-0.210, 0.540, -0.540):
	set(v):
		vu_khi_lech_lung = v
		_ap_lai_vu_khi(false)
@export var vu_khi_xoay_lung := Vector3(-28.3, 28.1, -173.9):
	set(v):
		vu_khi_xoay_lung = v
		_ap_lai_vu_khi(false)
@export var khien_lech := Vector3(0.0, -0.12, 0.0)
@export var khien_xoay := Vector3(90, 0, 0)
## Cỡ khiên: rộng × cao × dày, tính bằng mét.
@export var khien_co := Vector3(0.52, 0.62, 0.05)

var _xuong: Skeleton3D = null
var _id := {}            ## tên ngắn -> chỉ số xương
var _ten_xuong := {}     ## tên ngắn -> tên THẬT trong rig đang dùng
var _nghi := {}          ## tên ngắn -> quaternion nghỉ (gốc để cộng vào)
var _goc := {}           ## tên ngắn -> góc đang áp, để nội suy cho mượt
var _mo_hinh: Node3D = null
## Node trung gian để xoay cả thân QUANH HÔNG.
##
## Xoay thẳng `_mo_hinh` là xoay quanh gốc toạ độ của nó, mà gốc nằm dưới BÀN
## CHÂN — nên cú lăn hất cả người văng ra xa cả mét rồi mất hút khỏi khung
## hình. Người thật cuộn quanh bụng, không quanh gót chân.
var _truc: Node3D = null
## Node giữ vũ khí, gắn vào xương bàn tay phải. Model thật nạp vào đây; không
## có model thì rơi về khối hộp (`_vu_khi_hop`).
var _tay_cam: Node3D = null
var _vu_khi: Node3D = null
var _vu_khi_hop: MeshInstance3D = null
var _mo_hinh_dang_cam := ""
## Chỗ treo vũ khí khi đã cất — bám xương sống, nên nó nằm sau lưng.
var _sau_lung: Node3D = null
var _da_rut := true
## Thế cầm ĐANG ĐƯỢC ÁP, sau khi đã nội suy. Không phải lúc nào cũng bằng
## bộ số của `_cach_cam` — giữa hai thế nó nằm ở lơ lửng.
var _cach_cam := CAM_TAY
var _q_cam := Quaternion.IDENTITY
var _lech_cam := Vector3.ZERO
var _lan_cam := 0.0
var _cam_san := false
## Cỡ và chỗ chuôi của vũ khí đang cầm — đo một lần lúc chuẩn hoá.
var _vk_co := Vector3.ONE
var _vk_chuoi := 0.0
var _khien: MeshInstance3D = null

var _nhip := 0.0
var _nhip_nap := 0.0
var _muc_nap := 0.0
## Xoay cả thân (lăn, gục chết) — tách khỏi xương vì nó xoay TOÀN BỘ người.
var _xoay_than := 0.0
var _cao_than := 0.0
## Máy phát động tác thật. null nghĩa là chưa có file nào — dùng dáng gõ tay.
var _may_dt: AnimationPlayer = null
var _dt_dang_phat := ""
## Tên clip -> clip đó TỰ đi được bao nhiêu mét mỗi giây (trước khi khử trôi).
## Đây là thứ để so với vận tốc thật mà tính ra hệ số phát.
var _toc_goc := {}
## Model bị phóng bấy nhiêu lần. Sải chân trên màn hình dài ra theo đúng số này.
var _ti_le := 1.0

func _ready() -> void:
	_nap_mo_hinh()
	_nap_dong_tac()
	_gan_vu_khi()
	Tui.doi_trang_bi.connect(_cap_nhat_do)
	_cap_nhat_do()

func _nap_mo_hinh() -> void:
	var canh := load(duong_model) as PackedScene
	if canh == null:
		push_error("Khong nap duoc model %s" % duong_model)
		return
	_truc = Node3D.new()
	_truc.position.y = CAO * CHO_XOAY
	add_child(_truc)
	_mo_hinh = canh.instantiate() as Node3D
	_mo_hinh.position.y = -CAO * CHO_XOAY
	_truc.add_child(_mo_hinh)
	_ep_texture(_mo_hinh)
	_xuong = _tim_xuong(_mo_hinh)
	if _xuong == null:
		push_error("Model %s khong co Skeleton3D" % duong_model)
		return

	# Phóng cho đúng chiều cao quy ước. Đo bằng hộp bao của mesh chứ không tin
	# con số khai sẵn: mười bốn model trong bộ cao từ 1.66 tới 1.82m.
	var cao_that := _cao_mo_hinh()
	if cao_that > 0.1:
		_ti_le = CAO / cao_that
		_mo_hinh.scale = Vector3.ONE * _ti_le

	for ten in XUONG.keys():
		var i := -1
		for ten_that in XUONG[ten]:
			i = _xuong.find_bone(String(ten_that))
			if i >= 0:
				break
		if i < 0:
			push_warning("Model thieu xuong '%s'" % ten)
			continue
		_id[ten] = i
		_ten_xuong[ten] = _xuong.get_bone_name(i)
		_nghi[ten] = _xuong.get_bone_rest(i).basis.get_rotation_quaternion()
		_goc[ten] = Vector3.ZERO

## Ép atlas chung vào mọi mesh.
##
## Vật liệu trong FBX trỏ tới một đường dẫn texture không còn tồn tại, nên model
## nạp lên là đen thui. Cả bộ dùng chung một atlas nên ép thẳng vào là xong.
func _ep_texture(n: Node) -> void:
	var tex := load(duong_texture) as Texture2D
	if tex == null:
		return
	# Lọc điểm hay lọc mượt là do CỠ atlas, không phải do sở thích.
	#
	# Atlas của bộ elf là 64×64, mỗi mảng màu vài pixel: lọc mượt thì màu da lem
	# sang màu áo ngay trong một pixel. Atlas của model Mixamo là 2048×2048 và
	# có vân thật; lọc điểm ở cỡ đó thì mọi cạnh trong vân răng cưa hết.
	# Ngưỡng 256 chia đúng hai thế giới đó.
	var diem := tex.get_width() <= 256
	for m in _moi_mesh(n):
		var vl := StandardMaterial3D.new()
		vl.albedo_texture = tex
		vl.texture_filter = (BaseMaterial3D.TEXTURE_FILTER_NEAREST if diem
			else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		m.material_override = vl

## Model cao bao nhiêu mét THẬT, đo trước khi phóng.
##
## Đo bằng XƯƠNG, không bằng hộp bao của mesh. Mesh có skin thì hộp bao của nó
## là hộp ở không gian bind, và với model Mixamo nó ra 7,6 MILIMÉT — phóng cho
## "vừa 1.8m" từ con số đó là nhân nhân vật lên 236 lần. Bộ kiểm tra không thấy
## gì cả: luật vẫn chạy đúng, chỉ có màn hình đầy một mảng da người.
##
## Bỏ xương tên tận cùng `_end`. Đó là xương lá Godot tự sinh khi nhập FBX, nó
## nối dài thêm một đoạn bằng xương cha — đỉnh đầu thật ở 1.68m mà xương lá
## nằm ở 2.24m, tức là dôi ra hơn nửa mét không có thịt nào bám vào.
func _cao_mo_hinh() -> float:
	if _xuong != null and _xuong.get_bone_count() > 0:
		var tren := -1e9
		var duoi := 1e9
		for i in _xuong.get_bone_count():
			if _xuong.get_bone_name(i).ends_with("_end"):
				continue
			var y: float = _xuong.get_bone_global_pose(i).origin.y
			tren = maxf(tren, y)
			duoi = minf(duoi, y)
		if tren - duoi > 0.1:
			return tren - duoi
	var ra := 0.0
	for m in _moi_mesh(_mo_hinh):
		var h: AABB = (m as MeshInstance3D).get_aabb()
		ra = maxf(ra, h.position.y + h.size.y)
	return ra

func _moi_mesh(n: Node) -> Array:
	var ra: Array = []
	if n is MeshInstance3D:
		ra.append(n)
	for c in n.get_children():
		ra.append_array(_moi_mesh(c))
	return ra

func _tim_xuong(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var k := _tim_xuong(c)
		if k != null:
			return k
	return null

# --- Động tác thật ---------------------------------------------------
#
# Model của bộ asset KHÔNG có animation nào (đo bằng tools/soi_model.tscn), nên
# mọi dáng trong file này là góc gõ tay. Gõ tay thì trần của nó là "đọc được
# nhưng cứng": chân trượt vì không bám đất, hông đứng chết vì không ai xoay nó,
# và mọi chuyển tiếp cùng một kiểu giảm tốc.
#
# Thả file `.fbx` có animation vào `assets/model/dong_tac/` là thay được. Tên
# file quyết định nó dùng cho trạng thái nào (bảng `DONG_TAC`). Thiếu file nào
# thì trạng thái đó tự quay về dáng gõ tay — nên tải được tới đâu đẹp tới đó,
# không phải đợi đủ bộ.
#
# ĐIỀU KIỆN DUY NHẤT: file động tác phải cùng BỘ XƯƠNG với model nhân vật. Cách
# chắc chắn nhất là tải cả hai từ cùng một chỗ (Mixamo: tải model lên, nó tự
# gắn xương, rồi tải động tác về — tất cả dùng chung rig `mixamorig:`).

func _nap_dong_tac() -> void:
	if _xuong == null:
		return
	_may_dt = AnimationPlayer.new()
	add_child(_may_dt)
	# Phát lên chính bộ xương của model, không phải lên cây của file động tác.
	# `_sua_duong()` bẻ mọi rãnh về đúng bộ xương này, nên gốc ở đâu cũng được
	# miễn là CHA của bộ xương.
	_may_dt.root_node = _may_dt.get_path_to(_xuong.get_parent())
	var thu := AnimationLibrary.new()
	_nap_thu_muc(thu, THU_MUC_DONG_TAC, "")
	_nap_thu_muc(thu, THU_MUC_KHONG_VU_KHI, TIEN_TO_KVK)
	if thu.get_animation_list().is_empty():
		_may_dt.queue_free()
		_may_dt = null
		return
	_may_dt.add_animation_library("", thu)

func _nap_thu_muc(thu: AnimationLibrary, duong: String, tien_to: String) -> void:
	if not DirAccess.dir_exists_absolute(duong):
		return
	var d := DirAccess.open(duong)
	if d == null:
		return
	for f in d.get_files():
		var ten := f.trim_suffix(".import")
		if not (ten.ends_with(".fbx") or ten.ends_with(".glb")
				or ten.ends_with(".gltf")):
			continue
		var goc := ten.get_basename()
		if thu.has_animation(tien_to + goc):
			continue
		var a := _rut_animation(duong + ten)
		if a != null:
			_toc_goc[tien_to + goc] = _khu_troi(a)
			if goc in DONG_TAC_LAP:
				a.loop_mode = Animation.LOOP_LINEAR
			thu.add_animation(tien_to + goc, a)

## Lấy animation ĐẦU TIÊN trong một file. Mixamo xuất mỗi file một động tác,
## nên "đầu tiên" là "cái duy nhất"; lấy theo tên thì phải đoán tên Mixamo đặt.
func _rut_animation(duong: String) -> Animation:
	if not ResourceLoader.exists(duong):
		return null
	var canh := load(duong) as PackedScene
	if canh == null:
		return null
	var g := canh.instantiate()
	var ap := _tim_may(g)
	var ra: Animation = null
	if ap != null:
		for ten in ap.get_animation_list():
			var a := ap.get_animation(ten)
			if a != null and a.length > 0.01:
				ra = a.duplicate()
				break
	g.queue_free()
	if ra != null:
		_sua_duong(ra)
	return ra

## Bỏ phần TỰ DI CHUYỂN của clip — làm bằng code cái việc mà ô "In Place" của
## Mixamo làm lúc tải về.
##
## Game tự đẩy nhân vật bằng `move_and_slide()`. Clip nào CŨNG tự đẩy nữa thì
## hai bên cộng dồn: đo được clip `chay` tự đi 1.86m một vòng, tức là nhân vật
## chạy nhanh gấp đôi con số trong luật và trượt xuyên qua chỗ nó vừa đứng.
## Tệ hơn là nó âm thầm — không lỗi nào nổ, và bộ kiểm tra thì đo `velocity`
## của thân vật lý, thứ vẫn đúng y như cũ.
##
## Trừ đi một đường THẲNG từ khung đầu tới khung cuối, chứ không ghim cứng
## hông về một chỗ. Ghim cứng thì mất luôn cái lắc hông tự nhiên trong mỗi bước
## chân — đúng cái làm bước chân ra bước chân. Trừ đường thẳng chỉ lấy đi phần
## trôi đều, để lại phần dao động.
##
## GIỮ NGUYÊN trục Y. Nhảy, lăn, gục chết đều nhấc hoặc hạ cả người, và đó là
## chuyển động thật của động tác chứ không phải chỗ đứng.
## Trả về clip TỰ đi bao nhiêu mét mỗi giây trước khi bị khử — con số đó là
## thứ duy nhất cho biết clip này được dựng cho ai đi nhanh cỡ nào.
func _khu_troi(a: Animation) -> float:
	var ten := String(_ten_xuong.get("chau", ""))
	if ten == "":
		return 0.0
	for i in a.get_track_count():
		if a.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(i)).ends_with(ten):
			continue
		var n := a.track_get_key_count(i)
		if n < 2 or a.length < 0.01:
			continue
		var dau: Vector3 = a.track_get_key_value(i, 0)
		var cuoi: Vector3 = a.track_get_key_value(i, n - 1)
		var troi := Vector3(cuoi.x - dau.x, 0.0, cuoi.z - dau.z)
		if troi.length() < 0.02:
			return 0.0
		for k in n:
			var t := a.track_get_key_time(i, k) / a.length
			var v: Vector3 = a.track_get_key_value(i, k)
			a.track_set_key_value(i, k, v - troi * t)
		return troi.length() / a.length
	return 0.0

## Bẻ mọi rãnh của clip về đúng bộ xương của NHÂN VẬT.
##
## Rãnh trong file Mixamo ghi đường dẫn theo cây của CHÍNH FILE ĐÓ —
## `Armature/Skeleton3D:mixamorig_Hips`. Cây của nhân vật có thể tên khác, lồng
## khác, và khi đó Godot không kêu lỗi: nó in một dòng WARNING "couldn't
## resolve track" cho mỗi xương rồi phát một clip rỗng. Nhìn ra ngoài là nhân
## vật đứng chôn chân tư thế chữ T — y hệt cảnh chưa có file động tác nào.
##
## Tên xương thì trùng (cùng rig Mixamo), nên bẻ đường dẫn về
## `<tên bộ xương>:<tên xương>` là xong, và không còn phụ thuộc cây thư mục
## của file tải về nữa.
##
## Rãnh nào trỏ tới thứ không phải xương của model thì VỨT, đừng để lại —
## giữ lại chỉ để Godot in thêm một dòng cảnh báo mỗi khung hình.
func _sua_duong(a: Animation) -> void:
	var ten_xuong := _xuong.name
	for i in range(a.get_track_count() - 1, -1, -1):
		var x := a.track_get_path(i).get_concatenated_subnames()
		if x == "" or _xuong.find_bone(x) < 0:
			a.remove_track(i)
			continue
		a.track_set_path(i, NodePath("%s:%s" % [ten_xuong, x]))

func _tim_may(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var k := _tim_may(c)
		if k != null:
			return k
	return null

## Tên đòn trong CSV cho một `kieu` của phần nhìn.
##
## Cú NẠP không có dòng riêng trong `moveset.csv` — nó là đòn `nang` đang bị
## giữ lại. Không quy về `nang` thì `VocabDB.don_cua()` không tìm thấy "nap"
## và **âm thầm trả về dòng `nhe_1`**, nên clip giữ bị co giãn theo nhịp của
## đòn NHẸ: với 刃 là nhanh gấp 2.3 lần, với 拳 thì đụng trần 4.0 lần và clip
## chạy hết một vòng rồi lặp lại ngay giữa lúc người chơi còn đang gồng.
## Không lỗi nào nổ ra — chỉ là cú nạp tự vung thêm một nhát.
func _don_csv(kieu: String) -> String:
	return "nang" if kieu == "nap" else kieu

## Phát đòn đánh NHANH/CHẬM bao nhiêu lần để khớp `moveset.csv`.
##
## Đây là thứ quyết định "mượt" hơn cả số lượng clip, và cũng là chỗ dễ sai
## nhất khi ghép animation mua sẵn vào một game có timing riêng.
##
## Hộp đòn bật/tắt theo `t_dam_tu` / `t_dam_den` của CSV, KHÔNG theo animation.
## Nên một clip chém dài 1.5s phát nguyên tốc trong một cú vung mà CSV khai
## 0.72s sẽ cho ra cảnh: quái mất máu lúc lưỡi kiếm còn đang giơ lên trời. Mắt
## đọc ra là "đánh trúng từ xa", và không có cách nào tune cho hết — sai ở nhịp
## chứ không sai ở con số.
##
## Kéo giãn clip cho vừa khung thời gian của CSV thì lưỡi kiếm và hộp đòn đi
## cùng nhau. CSV vẫn là nguồn sự thật; animation bám theo nó.
func _toc_do(trang_thai: String, kieu: String, dt: String) -> float:
	if _may_dt == null:
		return 1.0
	# Đi / chạy khớp theo VẬN TỐC THẬT, không theo CSV. Xem TOC_CLIP_MAX.
	if trang_thai == "di" or trang_thai == "chay_nhanh":
		return _toc_theo_van_toc(dt)
	if trang_thai == "lan":
		return _toc_lan(dt)
	if trang_thai == "leo":
		return _toc_leo()
	if trang_thai != "danh":
		return 1.0
	# Đo trên clip SẮP phát, không trên clip đang phát: khung hình đổi clip thì
	# hai cái đó khác nhau, và lấy nhầm cái cũ là hệ số sai đúng một khung —
	# vừa đủ để cú vung giật một nhát lúc bắt đầu.
	var a := _may_dt.get_animation(dt)
	if a == null or a.length < 0.05:
		return 1.0
	var m := VocabDB.don_cua(Tui.moveset_dang_dung(), _don_csv(kieu))
	if m.is_empty():
		return 1.0
	# VŨ KHÍ SỞ HỮU CLIP THÌ KHÔNG CO GIÃN GÌ HẾT.
	#
	# Đây là chiều đi đúng, và nó ngược hẳn với bản trước. Trước đây CSV khai
	# nhịp rồi clip bị kéo cho vừa — cú Bổ bị ép chạy nhanh 2.25 lần, cú đâm
	# lướt 1.32 lần, mỗi đòn một hệ số — nên động tác đọc ra như tua nhanh mà
	# không ai nhìn con số mà biết được. Giờ nhịp trong `moveset.csv` ĐƯỢC ĐO
	# RA TỪ clip (`tools/do_nhip_don.tscn`), nên hai bên vốn đã khớp, và việc
	# phải làm là để yên.
	#
	# Chỉ vũ khí ĐI MƯỢN clip của vũ khí khác mới còn bị co giãn: nó có nhịp
	# riêng mà không có dáng riêng, nên đành kéo dáng của người khác cho vừa
	# nhịp của mình. Xem `_clip_don()`.
	# NHÂN THÊM `he_so_toc_do_danh` (mục "CHỈNH SỐNG" của NguoiChoi) vào MỌI
	# nhánh bên dưới — kể cả nhánh "để yên" 1.0 ở trên. `TrangThaiDanh._moc()`
	# chia CÙNG hệ số này vào bốn mốc t_vung/t_dam_tu/t_dam_den/t_hoi, nên hộp
	# đòn (đọc theo mốc đã chia) và hình (phát theo tốc độ đã nhân) luôn khớp
	# nhau bất kể hệ số là bao nhiêu — nhân một mình chỗ này mà quên chia bên
	# `danh.gd`, hoặc ngược lại, là tái lập đúng lỗi hộp đòn lệch hình đã sửa.
	var hs := _hs_danh()
	if _co(String(m.get("animation", ""))) == dt:
		return hs
	var lau := float(m.get("t_dam_den", 0.3)) + float(m.get("t_hoi", 0.5))
	if lau < 0.05:
		return hs
	return clampf(a.length / lau, 0.25, 4.0) * hs

## Hệ số tốc độ đánh do `NguoiChoi` giữ (mục "CHỈNH SỐNG Ở PHÒNG THỬ").
##
## Đọc qua `get()` chứ không ép kiểu: thân chỉ cần MỘT thuộc tính tên đúng
## vậy tồn tại trên node cha, không cần biết cha là lớp gì — cùng tinh thần
## với `dien()` được gọi qua hàm chứ không ép kiểu ở NguoiChoi._dien_hinh().
func _hs_danh() -> float:
	var nc := get_parent()
	if nc == null:
		return 1.0
	var v = nc.get("he_so_toc_do_danh")
	return clampf(float(v), 0.2, 3.0) if v != null else 1.0

## Tốc độ phát clip lăn, khớp theo THỜI LƯỢNG thật của cú lăn
## (`SoulsLike.thoi_gian_lan`, cũng ở mục "CHỈNH SỐNG") thay vì phát nguyên
## tốc mặc định.
##
## Trước đây "lan" rơi vào nhánh "khác 'danh'" ở trên và luôn trả 1.0 — đúng
## MỘT CÁCH TÌNH CỜ vì `lan.fbx` dài 1.17s và `thoi_gian_lan` cũng đo ra
## 1.17s từ chính clip đó. Đổi `thoi_gian_lan` qua tab Remote để dò cảm giác
## lăn mà không có hàm này thì THỜI LƯỢNG đổi trong khi HÌNH lăn vẫn chạy y
## tốc cũ — chân tay đứng yên khi cuộn nhanh, hoặc cuộn xong rồi hình mới
## chạy hết khi cuộn chậm.
func _toc_lan(dt: String) -> float:
	var a := _may_dt.get_animation(dt)
	if a == null or a.length < 0.05:
		return 1.0
	return clampf(a.length / maxf(SoulsLike.thoi_gian_lan, 0.05), 0.25, 4.0)

## Clip leo tự nó "trèo" bao nhiêu mét mỗi giây trên màn hình.
##
## KHÔNG đo được, và đó là chỗ khác hẳn mọi clip khác trong file này. Clip leo
## là vòng lặp TẠI CHỖ: hông đứng yên ở 0.69m suốt 2.00s, nên không có quãng
## đường nào để đo ra tốc độ như `_khu_troi()` làm với clip đi/chạy. Con số
## dưới đây là ƯỚC LƯỢNG: một vòng 2.00s của dáng leo thang bắt được khoảng
## một thân người, tức ~1.7m, ra ~0.85 m/s.
##
## Sai số ở đây chỉ làm tay chân trượt nhanh/chậm hơn thanh ngang một chút,
## không đụng tới luật nào. Thấy trượt thì chỉnh thẳng số này.
const TOC_CLIP_LEO := 0.85

## Tốc độ phát clip leo, bám theo VẬN TỐC DỌC THẬT của thân vật lý.
##
## Cùng khuôn với `_toc_theo_van_toc()` của clip đi/chạy, và có cùng một lý do:
## `NguoiChoi.toc_do_leo` chỉnh sống được (mục "CHỈNH SỐNG"), nên phát nguyên
## tốc là kéo tốc độ leo lên gấp đôi mà tay chân vẫn khua y như cũ.
##
## Treo im một chỗ thì vận tốc bằng 0 ⇒ hệ số 0 ⇒ clip đứng hình ở đúng tư thế
## đang bám. Đó là dáng "treo" miễn phí, không cần clip thứ ba.
func _toc_leo() -> float:
	var nc := get_parent()
	if nc == null or not (nc is CharacterBody3D):
		return 1.0
	return clampf(absf((nc as CharacterBody3D).velocity.y) / TOC_CLIP_LEO,
		0.0, 4.0)

## Hệ số phát cho clip đi/chạy, tính từ vận tốc thật của thân vật lý.
##
## Sải chân trên màn hình = (clip tự đi bao nhiêu m/s) × (model phóng mấy lần).
## Chia vận tốc thật cho nó là ra số lần phải phát nhanh lên để bàn chân bám
## đất. Đây là cách duy nhất đúng: bàn chân trượt hay không là quan hệ giữa HAI
## con số, chỉnh một mình con nào cũng không hết.
func _toc_theo_van_toc(dt: String) -> float:
	var goc: float = float(_toc_goc.get(dt, 0.0))
	if goc <= 0.05:
		return 1.0
	var nc := get_parent()
	if nc == null or not (nc is CharacterBody3D):
		return 1.0
	var v: Vector3 = (nc as CharacterBody3D).velocity
	var toc := Vector2(v.x, v.z).length()
	if toc < 0.15:
		return 1.0
	return clampf(toc / (goc * _ti_le), TOC_CLIP_MIN, TOC_CLIP_MAX)

## Tên clip THẬT cho một động tác, "" nếu không có file nào.
##
## Đây là chỗ bộ KHÔNG VŨ KHÍ chen vào. Hai trường hợp dùng nó:
## - Có vũ khí nhưng đã cất: thử clip tay không trước; thiếu thì được mượn clip
##   cầm kiếm, vì món đồ vẫn đang trang bị và các động tác rút/cất cần thấy nó.
## - Không trang bị vũ khí: chỉ dùng clip tay không; thiếu thì trả "" để rơi
##   về dáng gõ bằng code. Tuyệt đối không mượn dáng cầm một thanh kiếm không
##   tồn tại trên người.
func _co(goc: String) -> String:
	if _may_dt == null or goc == "":
		return ""
	var co_vu_khi := Tui.vu_khi_dang_cam() != null
	if not _da_rut or not co_vu_khi:
		var tay_khong := TIEN_TO_KVK + goc
		if _may_dt.has_animation(tay_khong):
			return tay_khong
		if not co_vu_khi:
			return ""
	return goc if _may_dt.has_animation(goc) else ""

## Clip cho một đòn. **Cột `animation` của `moveset.csv` nói trước.**
##
## Đây là chỗ thi hành luật "vũ khí nào CÓ clip của chính nó thì clip làm chủ".
## Vũ khí khai một tên clip có file thật thì dùng đúng clip đó và phát nguyên
## tốc; khai một tên chưa có file thì rơi về bộ clip chung và bị co giãn cho
## vừa nhịp của nó (xem `_toc_do()`).
##
## Vì sao phải qua CSV chứ không tra bảng trong code: cả `assets/model/dong_tac/`
## hiện là clip great sword, tức là clip của MỘT vũ khí. Năm vũ khí kia đang
## mượn. Thả `kiem_nhe_1.fbx` vào thư mục là 剑 tự đứng ra khỏi diện đi mượn,
## không phải sửa dòng `.gd` nào — và đó cũng là luật 1 của dự án: code không
## được biết vũ khí nào tồn tại.
func _clip_don(kieu: String) -> String:
	var m := VocabDB.don_cua(Tui.moveset_dang_dung(), _don_csv(kieu))
	var rieng := _co(String(m.get("animation", "")))
	if rieng != "":
		return rieng
	return _co(String(DONG_TAC_DON.get(kieu, "")))

## Tên động tác cho trạng thái hiện tại, "" nếu chưa có file nào hợp.
func _dong_tac_cho(trang_thai: String, kieu: String) -> String:
	if _may_dt == null:
		return ""
	if trang_thai == "danh":
		return _clip_don(kieu)
	# Đi/chạy khi ĐANG KHOÁ MỤC TIÊU là đi NGANG hoặc đi LÙI: mặt luôn quay về
	# con quái (đó là cả điểm của việc khoá), còn chân thì đi theo phím. Phát
	# clip đi tới cho một người đang lùi là hai chân bước ngược chiều thân —
	# thứ mắt bắt ra ngay dù không gọi tên được.
	# `vo_the` thiếu clip riêng thì mượn `trung_don` — thà ngắn còn hơn đơ.
	# Chết có dáng ngã riêng theo hướng đòn chí mạng (`TrangThaiChet.ten_dien()`).
	# Thiếu clip nào thì rơi về `chet` chung — nên thêm bớt dáng ngã là chuyện
	# của thư mục file, không phải của file này.
	if trang_thai == "chet" and kieu != "":
		var nga := _co("chet_" + kieu)
		if nga != "":
			return nga
	# Leo lên và leo xuống là HAI clip, chọn theo hướng đang đi
	# (`TrangThaiLeo.ten_dien()` trả "len" / "xuong"). Treo im một chỗ thì
	# `ten_dien()` giữ nguyên hướng cuối, còn việc đứng hình là do tốc độ phát
	# rơi về 0 — xem `_toc_leo()`.
	if trang_thai == "leo" and kieu != "":
		var bac := _co("leo_" + kieu)
		if bac != "":
			return bac
	if trang_thai == "vo_the" and _co("vo_the") == "":
		return _co("trung_don")
	if trang_thai == "di" or trang_thai == "chay_nhanh":
		var h := _huong_di_tuong_doi()
		if h != "":
			var rieng := _co("%s_%s" % [String(DONG_TAC.get(trang_thai, "")), h])
			if rieng != "":
				return rieng
	return _co(String(DONG_TAC.get(trang_thai, "")))

## Đang đi về phía nào SO VỚI HƯỚNG MẶT: "" là tới trước (hoặc không khoá),
## còn lại là "lui" / "trai" / "phai".
func _huong_di_tuong_doi() -> String:
	var nc := get_parent() as Node3D
	if nc == null or nc.get("muc_tieu") == null:
		return ""
	var h: Vector3 = nc.get("huong_nhap")
	if h.length_squared() < 0.01:
		return ""
	var truoc: Vector3 = nc.call("huong_mat")
	var phai := truoc.cross(Vector3.UP)
	var t := h.normalized().dot(truoc)
	var p := h.normalized().dot(phai)
	# Chia BỐN PHẦN TƯ ĐỀU NHAU: cos 45° = 0.7071, nên mỗi hướng ôm đúng 90°.
	#
	# Bản trước dùng 0.5 (tức 60°): tiến và lùi mỗi cái nuốt 120°, còn dạt
	# ngang chỉ còn 60° mỗi bên. Hậu quả là đi chéo lên trước-trái vẫn phát
	# clip ĐI THẲNG trong khi thân đang trượt ngang — đúng cái "trôi khi di
	# chuyển trái" mà chủ dự án báo, và nó chỉ xảy ra lúc đang khoá mục tiêu
	# nên rất dễ tưởng là ngẫu nhiên.
	const CHEO := 0.70711
	if t > CHEO:
		return ""
	if t < -CHEO:
		return "lui"
	return "phai" if p > 0.0 else "trai"

# --- Cửa hỏi cho bộ kiểm tra ----------------------------------------
#
# Hai thứ dưới đây là CÔNG KHAI có chủ ý. Bộ kiểm tra cần đo dáng tay và xem
# khiên có hiện không, mà thân có HAI bản (khối hộp và model thật) với cấu
# trúc trong ruột khác hẳn nhau. Không có cửa chung thì test phải ép kiểu một
# bản cụ thể — và đổi thân là test đỏ, dù game chẳng hỏng gì.

## Góc vung của tay phải, tính bằng độ, âm là ra sau. Bộ kiểm tra canh cú nạp
## đòn bằng con số này: suốt cú nạp tay chỉ được đi MỘT CHIỀU ra sau.
func goc_tay_phai() -> float:
	return float((_goc.get("vai_p", Vector3.ZERO) as Vector3).x)

## Hệ số phát clip đang áp. Bằng đúng TOC_CLIP_MAX nghĩa là ĐANG BỊ KẸP — clip
## quá chậm so với tốc độ đi của game, và bàn chân đang trượt.
##
## Công khai vì đây là thứ duy nhất đo được "chân có bám đất không" mà không
## cần nhìn. Đổi một file `.fbx` trong `dong_tac/` sang clip đi chậm hơn là số
## này chạm trần ngay, và phép thử đỏ trước khi ai kịp nhìn thấy nhân vật trượt.
func he_so_phat() -> float:
	return _may_dt.speed_scale if _may_dt != null else 1.0

## Clip `ten` tự đi bao nhiêu mét mỗi giây trên màn hình (đã tính cỡ model).
func toc_goc_clip(ten: String) -> float:
	return float(_toc_goc.get(ten, 0.0)) * _ti_le

## Bàn tay phải đang ở độ cao nào, tính bằng mét trong hệ của thân.
##
## Công khai vì đây là cách DUY NHẤT hỏi "thanh kiếm có thật sự giơ lên không"
## khi đã có clip thật. `goc_tay_phai()` đứng im trong trường hợp đó —
## `dien()` nhường hẳn cho `AnimationPlayer` và không xoay khớp nữa — nên mọi
## phép thử canh theo góc tay đều mù, và một clip ĐỨNG THỞ gán nhầm vào cú nạp
## vẫn qua được hết. Đã dính đúng vậy với `nap.fbx`.
##
## Mốc đo của model hiện tại: nghỉ ~0.70m, đỉnh cú bổ ~1.37m, đáy ~0.11m.
func cao_tay_phai() -> float:
	if _xuong == null or not _id.has("ban_p"):
		return 0.0
	return _xuong.get_bone_global_pose(int(_id["ban_p"])).origin.y

## Clip đang chạy tới giây thứ mấy CỦA CHÍNH NÓ.
##
## Công khai để bộ kiểm tra bắt được cú NHẢY LÙI của con trỏ clip: `play()`
## luôn chạy lại từ khung 0, nên đổi clip giữa một cú đánh là người chơi xem
## lại đoạn vung tay lần thứ hai. Tên clip thì vẫn đúng, dáng thì vẫn đẹp,
## chỉ có thứ tự là sai — không có cửa này thì không phép thử nào hỏi được.
func vi_tri_dong_tac() -> float:
	return _may_dt.current_animation_position if _may_dt != null else 0.0

## Clip động tác đang phát, "" nghĩa là đang dùng dáng gõ tay.
##
## Công khai vì bộ kiểm tra cần canh cú NẠP ĐÒN, mà cách canh phải đổi theo
## việc có file động tác hay không: không có file thì đo GÓC TAY, có file thì
## đo xem clip nào đang chạy. Cùng một câu hỏi — "cú nạp có vung hụt một nhát
## trước không" — nhưng hỏi bằng hai thứ tiếng.
func dong_tac_dang_phat() -> String:
	return _dt_dang_phat

## Khiên có đang được vẽ không.
func khien_hien() -> bool:
	return _khien != null and _khien.visible

# --- Vũ khí và khiên -------------------------------------------------

## Gắn vũ khí vào xương BÀN TAY.
##
## Đây là chỗ DUY NHẤT được phép bám xương, vì nó thuần để nhìn. Hộp đòn thì
## không — nó ở `GanTayPhai`, node anh em trong scene, và phải ở yên đó.
## Chuyển vũ khí giữa TAY và LƯNG.
##
## Cất kiếm mà chỉ ẩn nó đi thì thanh kiếm biến mất giữa không khí — người chơi
## đọc ra là lỗi, không phải là "đã cất". Cho nó bám xương sống thì nó nằm sau
## lưng, đúng như mắt chờ đợi.
func dat_da_rut(rut: bool) -> void:
	if _da_rut == rut:
		return
	_da_rut = rut
	var cha := _tay_cam if rut else _sau_lung
	if cha == null:
		return
	for m in [_vu_khi, _vu_khi_hop]:
		if m == null or not is_instance_valid(m):
			continue
		m.get_parent().remove_child(m)
		cha.add_child(m)
	if _vu_khi != null:
		_chuan_hoa_vu_khi(_vu_khi)
	if _vu_khi_hop != null:
		# Hộp dự phòng có gốc ở GIỮA, nên phải đẩy ra nửa chiều dài; model thật
		# thì gốc ở chuôi và `_chuan_hoa_vu_khi()` tự lo.
		var nua := Vector3(0, -0.4, 0)
		_vu_khi_hop.position = (vu_khi_lech_lung if rut == false else vu_khi_lech) + nua
		_vu_khi_hop.rotation_degrees = vu_khi_xoay_lung if rut == false else vu_khi_xoay

func _gan_vu_khi() -> void:
	if _xuong == null:
		return
	# Khối hộp lệch khác model: hộp có gốc ở GIỮA nên phải đẩy ra nửa chiều dài,
	# còn model thì gốc ở chuôi và `_chuan_hoa_vu_khi()` tự lo.
	_vu_khi_hop = _hop_vao_tay(String(_ten_xuong.get("ban_p", "Hand_R")),
		vu_khi_lech + Vector3(0, -0.4, 0), vu_khi_xoay)
	_tay_cam = _vu_khi_hop.get_parent() if _vu_khi_hop != null else null
	_khien = _hop_vao_tay(String(_ten_xuong.get("ban_t", "Hand_L")),
		khien_lech, khien_xoay)
	_sau_lung = _diem_gan(String(_ten_xuong.get("song", "Spine_02")))
	if _khien != null:
		_khien.mesh = _hinh_hop(khien_co)

## Một điểm gắn rỗng trên một xương. Dùng cho chỗ treo vũ khí sau lưng.
func _diem_gan(ten_xuong: String) -> Node3D:
	var i := _xuong.find_bone(ten_xuong)
	if i < 0:
		return null
	var gan := BoneAttachment3D.new()
	gan.bone_name = ten_xuong
	_xuong.add_child(gan)
	return gan

func _hop_vao_tay(ten_xuong: String, lech: Vector3, xoay: Vector3) -> MeshInstance3D:
	var i := _xuong.find_bone(ten_xuong)
	if i < 0:
		return null
	var gan := BoneAttachment3D.new()
	gan.bone_name = ten_xuong
	_xuong.add_child(gan)
	var m := MeshInstance3D.new()
	m.position = lech
	m.rotation_degrees = xoay
	m.mesh = _hinh_hop(Vector3(0.07, 0.07, 1.15))
	gan.add_child(m)
	return m

func _hinh_hop(co: Vector3) -> BoxMesh:
	var h := BoxMesh.new()
	h.size = co
	return h

func _vat_lieu(mau: Color) -> StandardMaterial3D:
	var v := StandardMaterial3D.new()
	v.albedo_color = mau
	v.roughness = 0.62
	return v

## Vũ khí đổi hình theo chữ trung tâm, khiên hiện khi tay trái có món `khien`.
## Dùng chung bảng `ThanKhoi.HINH_VU_KHI` — bảng đó phá luật 1 và đã ghi nợ ở
## TIEN_DO.md; chép thêm một bản nữa ở đây là nhân đôi món nợ.
func _cap_nhat_do() -> void:
	var chu := Tui.moveset_dang_dung()
	_cap_nhat_vu_khi(chu)
	# Khiên: cầm HAI TAY thì không có khiên, và `Tui.tay_trai_dang_cam()` đã
	# trả null sẵn cho mọi bên gọi — ở đây không phải biết luật đó.
	if _khien != null:
		var kh = Tui.tay_trai_dang_cam()
		_khien.visible = kh != null
		if kh != null:
			_khien.material_override = _vat_lieu(_mau_mon(kh))

## Vũ khí: ưu tiên MODEL THẬT, không có thì rơi về khối hộp.
##
## Tên file model đọc từ cột `mo_hinh` của nguyen_lieu.csv — KHÔNG phải từ một
## bảng gán cứng trong code. Bảng cũ (`ThanKhoi.HINH_VU_KHI`) gán chết năm chữ
## 剑刀斧弓拳 và vì thế phá luật 1: thêm loại vũ khí mới vào CSV thì nó hiện
## nhầm hình kiếm. Giờ thêm vũ khí là thêm một dòng CSV, không đụng file .gd.
func _cap_nhat_vu_khi(chu: String) -> void:
	if _tay_cam == null:
		return
	var ten := VocabDB.mo_hinh_cua(chu)
	if ten != _mo_hinh_dang_cam:
		_mo_hinh_dang_cam = ten
		if _vu_khi != null:
			_vu_khi.queue_free()
			_vu_khi = null
		if ten != "":
			_vu_khi = _nap_vu_khi(ten)
	var co_model := _vu_khi != null
	if _vu_khi_hop != null:
		# Khối hộp chỉ hiện khi KHÔNG có model. Hiện cả hai thì thanh kiếm thật
		# có một que gỗ xuyên qua giữa.
		var co: Vector3 = ThanKhoi.HINH_VU_KHI.get(chu, ThanKhoi.HINH_VU_KHI["剑"])
		_vu_khi_hop.visible = not co_model and co.length_squared() > 0.0
		if _vu_khi_hop.visible:
			_vu_khi_hop.mesh = _hinh_hop(co)
			_vu_khi_hop.material_override = _vat_lieu(_mau_mon(Tui.vu_khi_dang_cam()))

## Nạp một model vũ khí và phóng về đúng chiều dài quy ước.
func _nap_vu_khi(ten: String) -> Node3D:
	var duong := thu_muc_vu_khi + ten + ".fbx"
	if not ResourceLoader.exists(duong):
		push_warning("Khong co model vu khi '%s'" % duong)
		return null
	var canh := load(duong) as PackedScene
	if canh == null:
		return null
	var g := canh.instantiate() as Node3D
	_tay_cam.add_child(g)
	_ep_texture_vu_khi(g)
	_chuan_hoa_vu_khi(g)
	return g

## Đưa một model vũ khí bất kỳ về đúng cỡ và đúng thế cầm.
##
## Tự tính, KHÔNG dùng số gõ tay, vì ba lý do đã cắn:
##
##   1. `get_aabb()` của mesh trả cỡ trong hệ của CHÍNH nó. File FBX hay có một
##      node trung gian mang tỉ lệ (cm→m), nên cỡ đó lệch hẳn cỡ thật — đo kiểu
##      ấy thì thanh kiếm ra dài gấp đôi người. Phải quy về hệ của gốc model.
##   2. Model dựng đứng theo trục Y, mà bàn tay cần lưỡi chĩa RA TRƯỚC — tức
##      −Y trong hệ của khớp (đo được, xem `vu_khi_xoay`). Nên phải lật 180°.
##   3. Gốc toạ độ của model nằm ở CHUÔI, không ở giữa. Đặt nguyên là bàn tay
##      nắm vào giữa lưỡi.
##
## Làm tự động thì thả model mới vào `assets/model/vu_khi/` là cầm được ngay,
## không phải dò lại ba con số cho từng cây.
func _chuan_hoa_vu_khi(g: Node3D) -> void:
	g.transform = Transform3D.IDENTITY
	var h := _hop_trong(g)
	var dai := maxf(h.size.x, maxf(h.size.y, h.size.z))
	if dai <= 0.001:
		return
	var ti := vu_khi_dai / dai
	g.scale = Vector3(ti, ti, ti) * vu_khi_ti_le
	# Xoay theo góc cầm ĐÃ ĐO (xem `vu_khi_xoay`), rồi đẩy sao cho CHUÔI nằm
	# đúng trong nắm tay.
	#
	# Bản trước ghim cứng 180° quanh X ở đây, nên `vu_khi_xoay` chỉ ăn vào khối
	# hộp dự phòng còn model thật thì mặc kệ. Kết quả: chỉnh mỏi tay trong
	# editor mà thanh kiếm không nhúc nhích một độ nào.
	# Nhớ lại để `_dat_the_cam()` dựng lại transform mỗi khung mà không phải đo
	# hộp bao lần nữa — đo hộp bao là việc đắt, và nó không đổi.
	_vk_co = g.scale
	_vk_chuoi = h.position.y
	_keo_the_cam(CAM_LUNG if g.get_parent() == _sau_lung else _cach_cam, 99.0)

## Áp lại mọi nút vặn của vũ khí NGAY LẬP TỨC.
##
## Có để chỉnh được bằng tay lúc game đang chạy — tab Remote của Godot, hoặc
## `tools/chinh_kiem.tscn`. Không có nó thì mấy ô `@export` chỉ ăn lúc nạp
## scene, và người chỉnh kéo số mỏi tay mà thanh kiếm đứng im.
##
## `do_lai_co` = true khi đổi thứ ảnh hưởng tới CỠ (dài, tỉ lệ): lúc đó phải đo
## lại hộp bao và tính lại chỗ chuôi. Đổi góc hay lệch thì không cần.
func _ap_lai_vu_khi(do_lai_co := false) -> void:
	if _vu_khi == null or not is_instance_valid(_vu_khi):
		return
	if do_lai_co:
		_chuan_hoa_vu_khi(_vu_khi)
	else:
		# SNAP (delta lớn) chứ không nội suy: người đang vặn số muốn thấy ngay
		# con số mình vừa gõ, không muốn đợi nó bò tới trong 0.12 giây.
		_keo_the_cam(_cach_cam, 99.0)

## Dựng transform của vũ khí từ thế cầm đang áp.
##
## Tách khỏi `_chuan_hoa_vu_khi()` vì nó phải chạy MỖI KHUNG trong lúc đang đổi
## thế cầm, còn đo hộp bao thì chỉ một lần.
## Ba bộ số của một cách cầm: [xoay (độ), lệch (m), lăn lưỡi (độ)].
func _bo_the_cam(cach: int) -> Array:
	match cach:
		CAM_LUNG:
			return [vu_khi_xoay_lung, vu_khi_lech_lung, vu_khi_lan_lung]
		CAM_CHAY:
			return [vu_khi_xoay_chay, vu_khi_lech_chay, vu_khi_lan_chay]
		_:
			return [vu_khi_xoay, vu_khi_lech, vu_khi_lan]

## Trạng thái này cầm kiếm theo cách nào.
func _cach_cho(trang_thai: String) -> int:
	if not _da_rut:
		return CAM_LUNG
	return CAM_CHAY if trang_thai in TT_DI_CHUYEN else CAM_TAY

## Kéo thế cầm về phía `cach`, rồi dựng lại transform của vũ khí.
##
## Nội suy giữa hai thế TRÊN TAY, nhưng SNAP khi có dính tới thế sau lưng: hai
## bên neo vào hai xương khác nhau (bàn tay và xương sống), nên nội suy giữa
## chúng là nội suy giữa hai hệ toạ độ không liên quan — thanh kiếm sẽ bay một
## đường vòng qua giữa người.
##
## Dùng quaternion chứ không nội suy Euler: nội suy Euler qua một quãng lớn thì
## thanh kiếm lượn một vòng cung lạ mắt thay vì quay thẳng.
func _keo_the_cam(cach: int, delta: float) -> void:
	var bo := _bo_the_cam(cach)
	var q := Quaternion(Basis.from_euler((bo[0] as Vector3) * PI / 180.0))
	var snap := not _cam_san or cach == CAM_LUNG or _cach_cam == CAM_LUNG
	var k := 1.0 if snap else minf(1.0, delta / T_DOI_THE_CAM)
	_q_cam = q if not _cam_san else _q_cam.slerp(q, k)
	_lech_cam = (bo[1] as Vector3) if not _cam_san else _lech_cam.lerp(bo[1], k)
	_lan_cam = float(bo[2]) if not _cam_san else lerpf(_lan_cam, float(bo[2]), k)
	_cach_cam = cach
	_cam_san = true
	if _vu_khi != null and is_instance_valid(_vu_khi):
		_dat_the_cam(_vu_khi)

## Dựng transform của vũ khí từ thế cầm đang áp.
##
## Tách khỏi `_chuan_hoa_vu_khi()` vì nó phải chạy MỖI KHUNG trong lúc đang đổi
## thế cầm, còn đo hộp bao thì chỉ một lần.
func _dat_the_cam(g: Node3D) -> void:
	# LĂN trước, XOAY sau. Lăn quanh +Y của chính model — tức quanh trục thanh
	# kiếm, vì model dựng đứng theo Y — nên nó chỉ đổi hướng bề dẹt của lưỡi
	# mà không động gì tới hướng thanh kiếm chĩa.
	var lan := Basis(Vector3.UP, deg_to_rad(_lan_cam))
	g.basis = Basis(_q_cam) * lan * Basis().scaled(_vk_co)
	# Bù chuôi theo hệ ĐÃ XOAY: `_vk_chuoi` là chỗ chuôi trong hệ của model,
	# mà sau khi xoay thì hướng đó không còn là trục Y nữa.
	g.position = _lech_cam - g.basis * Vector3(0, _vk_chuoi, 0)

## Hộp bao của cả model, quy về hệ toạ độ của chính nó.
func _hop_trong(g: Node3D) -> AABB:
	var ra := AABB()
	var co := false
	var nguoc := g.global_transform.affine_inverse()
	for m in _moi_mesh(g):
		var mi := m as MeshInstance3D
		var b: AABB = (nguoc * mi.global_transform) * mi.get_aabb()
		ra = b if not co else ra.merge(b)
		co = true
	return ra

func _ep_texture_vu_khi(n: Node) -> void:
	var tex := load(texture_vu_khi) as Texture2D
	if tex == null:
		return
	for m in _moi_mesh(n):
		var vl := StandardMaterial3D.new()
		vl.albedo_texture = tex
		vl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.material_override = vl

## Tô theo ĐỘ HIẾM, pha màu ngũ hành nếu có hành. Nhìn món đồ là đoán được nó
## hệ gì — thêm một chỗ chữ Hán nắm thông tin.
func _mau_mon(mon) -> Color:
	if mon == null:
		return mau_vu_khi
	var mau: Color = mon.mau()
	var h: String = mon.ngu_hanh()
	return mau if h == "" else mau.lerp(NguHanh.mau_cua(h), 0.55)

# --- Xoay xương ------------------------------------------------------

## Đặt góc cho một khớp, tính bằng ĐỘ, trong hệ toạ độ của XƯƠNG CHA.
##
## Nhân TRƯỚC quaternion nghỉ (`q * nghi`) chứ không nhân sau: nhân trước là
## xoay trong hệ của cha, nơi các trục còn đoán được — X là trục ngang (vung
## tay tới/lui), Z là trục dọc theo hướng nhìn (dang tay ra/vào). Nhân sau là
## xoay trong hệ của chính cái xương đó, mà hệ ấy mỗi rig một khác và không
## có cách nào biết trước ngoài thử.
func _dat(ten: String, goc: Vector3) -> void:
	if not _id.has(ten):
		return
	_goc[ten] = goc
	var q := Quaternion.from_euler(Vector3(deg_to_rad(goc.x), deg_to_rad(goc.y),
		deg_to_rad(goc.z)))
	_xuong.set_bone_pose_rotation(_id[ten], q * _nghi[ten])

## Nội suy về một góc. Dùng cho mọi chuyển tiếp mượt — đặt thẳng thì khớp giật.
func _toi(ten: String, goc: Vector3, k: float) -> void:
	if not _id.has(ten):
		return
	_dat(ten, (_goc[ten] as Vector3).lerp(goc, clampf(k, 0.0, 1.0)))

## Tư thế nghỉ: hai tay buông xuống cạnh sườn. Model đứng chữ T nên đây KHÔNG
## phải tư thế gốc — phải hạ tay xuống trước rồi mọi dáng khác mới cộng lên
## đúng chỗ.
func _tay_buong(k: float, them_t := Vector3.ZERO, them_p := Vector3.ZERO) -> void:
	_toi("vai_t", Vector3(0, 0, GOC_HA_TAY) + them_t, k)
	_toi("vai_p", Vector3(0, 0, GOC_HA_TAY * DAU_TAY_PHAI) + them_p, k)

# --- Hoạt ảnh --------------------------------------------------------

## Kéo clip đòn đánh về đúng mốc mà MÁY TRẠNG THÁI đang đứng.
##
## `AnimationPlayer.play()` luôn chạy từ khung 0, và với đòn thường thì đúng —
## `may.t` cũng bắt đầu từ 0. Cú NẠP là chỗ duy nhất `may.t` vào state ở giữa
## chừng: `TrangThaiDanh._chay_nap()` đẩy thẳng `may.t` tới `t_vung` lúc nhả,
## vì tay đã giơ lên xong rồi. Không kéo clip theo thì nó giơ kiếm lên LẦN NỮA
## trong khi hộp đòn đã bật — quái mất máu lúc lưỡi kiếm còn đang đi lên.
##
## Hai lúc phải kéo, và chỉ hai lúc:
##
##   ĐỔI CLIP    đặt clip vào đúng chỗ rồi thả cho nó tự chạy. Kéo tiếp mỗi
##               khung là giết luôn 0.12s hoà clip, cú vung giật cục.
##   ĐANG NẠP    `may.t` bị ghim ở `t_vung` nên clip cũng phải ghim theo. Đây
##               là chỗ thi hành "vung lên rồi GIỮ Ở ĐỈNH": thả cho clip tự
##               chạy thì thanh kiếm cứ thế bổ xuống trong khi người chơi vẫn
##               đang giữ chuột.
##   CLIP CÓ CẮT clip phải NHẢY QUA quãng chết (xem `CAT_CHET`), mà nhảy thì
##               phải có người đẩy — thả tự chạy là nó bò thẳng vào đoạn nằm
##               im. Mấy clip này vì vậy bám hẳn vào đồng hồ của state, và đó
##               cũng là cách chắc nhất để lưỡi kiếm và hộp đòn không bao giờ
##               lệch nhau.
##
## Đổi `nang` → `nang_nap` lúc nhả KHÔNG đổi clip (cả hai cùng trỏ vào
## `nang`), nên không có cú kéo nào ở đó — clip chảy thẳng từ chỗ đang ghim
## vào cú bổ, liền một mạch.
func _ghim_clip(trang_thai: String, kieu: String, dt: String, t_don: float,
		toc: float, doi_clip: bool) -> void:
	if trang_thai != "danh" or _may_dt == null:
		return
	if not doi_clip and kieu != "nap" and not CAT_CHET.has(dt):
		return
	_may_dt.seek(_clip_tu_don(dt, maxf(t_don, 0.0) * toc), true)

## Giây ĐÃ CẮT của state → giây THẬT trong file clip.
##
## Hai hệ quy chiếu, và phải tách bạch: `moveset.csv` đếm thời gian của cú
## đánh như người chơi cảm nhận — không có quãng nằm chờ nào — còn file `.fbx`
## thì vẫn còn nguyên mấy quãng ấy. Hàm này cộng trả lại phần đã cắt.
##
## Duyệt theo thứ tự và cộng dồn: sau mỗi lần cộng thì `t` đã nằm trong hệ của
## clip gốc, nên so thẳng được với mốc của quãng cắt kế tiếp.
func _clip_tu_don(dt: String, t_don: float) -> float:
	var t := t_don
	for c in CAT_CHET.get(dt, []):
		if t >= float(c[0]):
			t += float(c[1]) - float(c[0])
	return t

## Cùng chữ ký với `ThanKhoi.dien()` — xem ghi chú đầu file.
func dien(trang_thai: String, tien_do: float, dang_di: bool, delta: float,
		kieu: String = "", muc_nap: float = 0.0, t_don: float = 0.0) -> void:
	if _xuong == null:
		return
	_muc_nap = muc_nap
	if kieu == "nap":
		_nhip_nap += delta * 34.0
	var k := minf(1.0, 16.0 * delta)

	# Thế cầm đổi theo trạng thái: clip chạy xoay bàn tay khác clip đứng, nên
	# một thế cầm không thể đúng cho cả hai. Xem `TT_DI_CHUYEN`.
	_keo_the_cam(_cach_cho(trang_thai), delta)

	# CÓ ĐỘNG TÁC THẬT thì nhường hẳn cho nó — đừng xoay xương chồng lên, vì
	# xoay chồng là vừa phát animation vừa bẻ khớp, ra một thứ tệ hơn cả hai.
	var dt := _dong_tac_cho(trang_thai, kieu)
	if dt != "":
		var toc := _toc_do(trang_thai, kieu, dt)
		var doi_clip := dt != _dt_dang_phat
		if doi_clip:
			_dt_dang_phat = dt
			_may_dt.play(dt, 0.12)
		# Đặt MỖI KHUNG chứ không chỉ lúc đổi clip: tốc độ đi thay đổi liên
		# tục trong khi vẫn là một clip, nên đặt một lần lúc vào là sai ngay
		# khi người chơi tăng hay giảm tốc.
		_may_dt.speed_scale = toc
		_ghim_clip(trang_thai, kieu, dt, t_don, toc, doi_clip)
		_xoay_than = 0.0
		_cao_than = 0.0
		if _truc != null:
			_truc.rotation_degrees.x = 0.0
			_truc.position.y = CAO * CHO_XOAY
		return
	if _dt_dang_phat != "":
		_dt_dang_phat = ""
		if _may_dt != null:
			_may_dt.stop()

	match trang_thai:
		"danh":
			_dien_danh(kieu, tien_do, k)
		"lan":
			# Lăn xoay CẢ THÂN, không xoay khớp: cuộn người là chuyển động của
			# cả khối, và cố diễn nó bằng khớp thì ra hình gập bụng.
			var vong := clampf(tien_do, 0.0, 1.0)
			_xoay_than = vong * 360.0
			_cao_than = sin(vong * PI) * 0.30
			_tay_buong(k, Vector3(-40, 0, 0), Vector3(-40, 0, 0))
			_toi("dui_t", Vector3(-70, 0, 0), k)
			_toi("dui_p", Vector3(-70, 0, 0), k)
			_toi("goi_t", Vector3(80, 0, 0), k)
			_toi("goi_p", Vector3(80, 0, 0), k)
		"do_don", "do_phan":
			_xoay_than = lerpf(_xoay_than, 0.0, k)
			_cao_than = lerpf(_cao_than, 0.0, k)
			# Khiên đưa lên che mặt, vũ khí thu về sau — đọc ra là "đang thủ".
			_tay_buong(k, Vector3(-85, 0, -35), Vector3(-25, 0, 20))
			_toi("khuyu_t", Vector3(-55, 0, 0), k)
			_toi("song", Vector3(6, 0, 0), k)
		"trung_don", "vo_the":
			_xoay_than = lerpf(_xoay_than, 0.0, k)
			_cao_than = lerpf(_cao_than, 0.0, k)
			_toi("song", Vector3(-22, 0, 0), k)
			_toi("dau", Vector3(-16, 0, 0), k)
			_tay_buong(k, Vector3(-30, 0, -18), Vector3(-30, 0, 18))
		"chet":
			# Gục về phía trước, chậm. Xoay cả thân chứ không gập xương: nằm
			# xuống là cả người nằm.
			_xoay_than = lerpf(_xoay_than, 0.0, minf(1.0, 4.0 * delta))
			_cao_than = lerpf(_cao_than, -0.72, minf(1.0, 3.0 * delta))
			_toi("song", Vector3(-70, 0, 0), minf(1.0, 3.0 * delta))
			_toi("dau", Vector3(-25, 0, 0), minf(1.0, 3.0 * delta))
			_tay_buong(minf(1.0, 3.0 * delta), Vector3(-20, 0, 0), Vector3(-20, 0, 0))
		"nhay":
			_xoay_than = lerpf(_xoay_than, 0.0, k)
			_cao_than = lerpf(_cao_than, 0.0, k)
			_tay_buong(k, Vector3(-55, 0, 0), Vector3(-55, 0, 0))
			_toi("dui_t", Vector3(-38, 0, 0), k)
			_toi("dui_p", Vector3(-14, 0, 0), k)
			_toi("goi_t", Vector3(58, 0, 0), k)
			_toi("goi_p", Vector3(24, 0, 0), k)
		"uong":
			_xoay_than = lerpf(_xoay_than, 0.0, k)
			_cao_than = lerpf(_cao_than, 0.0, k)
			_tay_buong(k, Vector3(0, 0, 0), Vector3(-118, 0, 26))
			_toi("khuyu_p", Vector3(-95, 0, 0), k)
			_toi("dau", Vector3(14, 0, 0), k)
		_:
			_dung_yen(delta, k)

	_buoc_chan(trang_thai, dang_di, kieu, delta, k)
	if _truc != null:
		_truc.rotation_degrees.x = _xoay_than
		_truc.position.y = CAO * CHO_XOAY + _cao_than

func _dung_yen(delta: float, k: float) -> void:
	_xoay_than = lerpf(_xoay_than, 0.0, k)
	_cao_than = lerpf(_cao_than, 0.0, k)
	# Thở: ngực nhô rất nhẹ. Đứng cứng đờ tuyệt đối trông như đã treo máy.
	_nhip_nap += delta
	var tho := sin(_nhip_nap * 1.6) * 1.4
	_toi("song", Vector3(tho * 0.5, 0, 0), k)
	_toi("dau", Vector3(0, 0, 0), k)
	_tay_buong(k, Vector3(tho, 0, 4), Vector3(tho, 0, -4))
	_toi("khuyu_t", Vector3(-12, 0, 0), k)
	_toi("khuyu_p", Vector3(-12, 0, 0), k)

## Nhịp chân. Tách khỏi `match` ở trên vì nó chạy ĐÈ lên mọi trạng thái đi lại
## được — kể cả lúc đang lết giữa cú nạp đòn, không thì nhân vật trượt băng.
func _buoc_chan(trang_thai: String, dang_di: bool, kieu: String, delta: float,
		k: float) -> void:
	if trang_thai in ["lan", "chet", "nhay"]:
		return
	if dang_di and (trang_thai in ["di", "chay_nhanh", "do_don"] or kieu == "nap"):
		var nhanh := trang_thai == "chay_nhanh"
		_nhip += delta * (11.0 if nhanh else 7.0)
		var b := sin(_nhip) * (34.0 if nhanh else 20.0)
		_dat("dui_p", Vector3(b, 0, 0))
		_dat("dui_t", Vector3(-b, 0, 0))
		# Đầu gối chỉ gập một chiều — duỗi ngược là khớp gãy ngược.
		_dat("goi_p", Vector3(maxf(-b, 0.0) * 1.1, 0, 0))
		_dat("goi_t", Vector3(maxf(b, 0.0) * 1.1, 0, 0))
		if trang_thai == "di" or trang_thai == "chay_nhanh":
			_tay_buong(k, Vector3(-b * 0.5, 0, 4), Vector3(b * 0.5, 0, -4))
	else:
		_toi("dui_p", Vector3.ZERO, k)
		_toi("dui_t", Vector3.ZERO, k)
		_toi("goi_p", Vector3.ZERO, k)
		_toi("goi_t", Vector3.ZERO, k)

## Dáng đánh, khác nhau theo LOẠI đòn.
##
## Bảy loại đòn dùng chung một cung vung thì đòn nặng nhìn y hệt đòn nhẹ, chỉ
## chậm hơn — người chơi giữ chuột mà không thấy gì khác thì tưởng giữ không ăn
## thua, dù sát thương thật đã gấp rưỡi. Ở souls-like, ĐỌC ĐƯỢC ĐÒN là nửa cơ
## chế; nửa kia là con số.
func _dien_danh(kieu: String, tien_do: float, k: float) -> void:
	var t := clampf(tien_do, 0.0, 1.0)
	_xoay_than = lerpf(_xoay_than, 0.0, k)
	_cao_than = lerpf(_cao_than, 0.0, k)
	if _vu_khi_hop != null:
		_vu_khi_hop.scale = Vector3.ONE

	if kieu == "nap":
		# ĐANG NẠP: giơ vũ khí lên qua đầu rồi GIỮ, rung dần theo mức nạp.
		# Người chơi phải thấy mình đang nạp tới đâu, và đối phương cũng phải
		# thấy — nạp có rủi ro đọc được mới là nạp.
		var rung := sin(_nhip_nap) * 2.2 * _muc_nap
		_tay_buong(k, Vector3(-40, 0, -20), Vector3(-165 + rung, 0, 18))
		_toi("khuyu_p", Vector3(-58, 0, 0), k)
		_toi("song", Vector3(-8, 0, -12), k)
		# Phình to dần theo mức nạp — người chơi phải thấy mình nạp tới đâu.
		var phinh := Vector3.ONE * (1.0 + _muc_nap * 0.32)
		if _vu_khi_hop != null:
			_vu_khi_hop.scale = phinh
		if _vu_khi != null:
			_vu_khi.scale = _ti_le_vu_khi() * (1.0 + _muc_nap * 0.32)
		return

	if kieu == "phan_do":
		# ĐÒN PHẢN ĐỠ: thúc thẳng từ sau khiên ra, không vung vòng. Khiên vẫn
		# giơ gần hết đòn — đó là cả ý của đòn này, phản mà không bỏ thủ.
		_tay_buong(1.0, Vector3(-85, 0, -32), Vector3(lerpf(-40.0, 26.0, t), 0, 8))
		_toi("khuyu_t", Vector3(-55, 0, 0), k)
		_dat("khuyu_p", Vector3(lerpf(-70.0, -8.0, t), 0, 0))
		_toi("song", Vector3(0, lerpf(-14.0, 10.0, t), 0), k)
		return

	# Vung từ sau đầu ra trước. Vung ngược lên trước là chỗ người chơi ĐỌC được
	# "nó sắp chém" — khung quan trọng nhất của cả đòn đánh.
	#
	# HAI trục cùng chạy, và cần cả hai:
	#   X   cung vung, từ sau gáy xuống trước mặt
	#   Z   kéo tay VÀO trước người. Thiếu nó thì tay vung trong lúc vẫn dạng
	#       ngang sườn, và nhìn ra như đang vẫy tay chứ không phải chém.
	var nang := "nang" in kieu
	var nhay := kieu.begins_with("nhay")
	var tu := -168.0 if nang else -148.0
	var den := 88.0 if nang else 70.0
	if nhay:
		tu = -195.0
		den = 105.0
	# TĂNG TỐC DẦN rồi hãm lại ở cuối, không đi đều.
	#
	# Hai lý do, và lý do thứ hai mới là lý do bắt buộc:
	#   1. lưỡi kiếm ngoài đời tăng tốc từ trạng thái nghỉ, đi đều trông như
	#      quét chổi;
	#   2. nhả cú NẠP ra thì cung vung bắt đầu chạy ngay, mà đi đều thì chỉ hai
	#      khung hình sau cánh tay đã nhảy 41° khỏi chỗ đang giữ — mắt đọc ra
	#      là một cú giật. Bộ kiểm tra canh đúng chỗ này (ngưỡng 25°).
	var e := t * t * (3.0 - 2.0 * t)
	_dat("vai_p", Vector3(lerpf(tu, den, e), 0,
		GOC_HA_TAY * DAU_TAY_PHAI * lerpf(0.62, 0.06, e)))
	# Khuỷu duỗi dần: co lúc lấy đà, thẳng đúng lúc chạm — đó là chỗ cú chém
	# có lực. Duỗi sẵn từ đầu thì cả đòn trông như quét chổi.
	_dat("khuyu_p", Vector3(lerpf(-62.0, 2.0, e), 0, 0))
	# Thân xoay theo cú vung, và đòn NẶNG xoay gấp đôi — chém mà thân đứng im
	# thì nhát chém không có lực, mà nặng với nhẹ xoay như nhau thì không phân
	# biệt được bằng mắt.
	var xoay := 34.0 if nang else 20.0
	_toi("song", Vector3(lerpf(-10.0, 12.0, t), lerpf(-xoay, xoay * 0.85, t), 0), k)
	_toi("chau", Vector3(0, lerpf(-xoay * 0.4, xoay * 0.3, t), 0), k)
	# Tay trái vung ngược lại cho cân — người thật không chém bằng một tay mà
	# nửa còn lại đứng im.
	#
	# CHỈ tay trái. Đừng gọi `_tay_buong()` ở đây: hàm đó đặt CẢ HAI tay, nên
	# nó kéo tay phải về tư thế buông và xoá sạch cú chém vừa vẽ ngay dòng
	# trên. Đã dính: nhả cú nạp ra là cánh tay nhảy 41° về phía trước, và bộ
	# kiểm tra bắt được (ngưỡng 25°) trong khi mắt chỉ thấy "hơi giật".
	_toi("vai_t", Vector3(GOC_HA_TAY * 0.0 + lerpf(-10.0, -52.0, t), 0,
		GOC_HA_TAY + 16.0), k)

## Tỉ lệ gốc của model vũ khí đang cầm, để phình lúc nạp rồi trả về đúng chỗ.
func _ti_le_vu_khi() -> Vector3:
	if _vu_khi == null or _mo_hinh_dang_cam == "":
		return Vector3.ONE
	var h := _hop_trong(_vu_khi)
	var dai := maxf(h.size.x, maxf(h.size.y, h.size.z))
	return Vector3.ONE if dai <= 0.001 else Vector3.ONE * (vu_khi_dai / dai)
