# Động tác nhân vật — ĐÃ LẮP XONG

43 clip đang chạy: **32 clip cầm kiếm** ở thư mục này, **11 clip tay không** ở
`khong_vu_khi/`. Nguồn: hai thư mục `Downloads/Animation/Great Sword` và
`Downloads/Animation/Normal`.

Model nhân vật là `assets/model/nhan_vat_chinh.fbx` (rig Mixamo, 58 xương), da
là `katz.jpg`. Cùng bộ xương với mọi clip, nên không phải ánh xạ gì cả.

---

## Hai bộ động tác, và vì sao có hai

Cất kiếm rồi mà vẫn chạy bằng dáng ôm kiếm hai tay thì phần thưởng của phím R
(nhanh hơn 30%, tốn ít thể lực hơn) **không có mặt nào để đọc** — người chơi
chỉ thấy con số trong thanh thể lực đổi, mà không ai nhìn thanh thể lực lúc
đang chạy. Đổi hẳn dáng đi thì mắt đọc ra ngay "giờ đang rảnh tay".

Thiếu clip nào ở bộ tay không thì **tự mượn bộ cầm kiếm**, nên bộ đó không cần
đủ. Mượn thì hơi thừa cái dáng ôm kiếm rỗng tay — chấp nhận được với mấy trạng
thái thoáng qua, và đó là lý do bảng dưới lấp `dung` / `di` / `chay` trước hết.

---

## Chọn file bằng SỐ ĐO, không bằng tên

Tên Mixamo nói rất ít, và ba lần nó nói SAI:

| Tên file | Thực ra là gì | Đo bằng |
|---|---|---|
| `great sword run` | chạy **LÙI** (hông trôi −1.37m theo Z) | hướng trôi của hông |
| `great sword walk (2)` | đi **LÙI** — tưởng thừa, hoá ra đúng thứ đang thiếu | như trên |
| `great sword slash (5)` | chém lúc **ĐANG KHOM** (hông 0.33m thay vì 0.67m) | độ cao hông |

Nếu tin tên file thì nhân vật chạy tới trước bằng dáng chạy giật lùi, và một
nhát trong combo ba nhát thì thụp xuống đất. Hai máy đo viết ra để tránh đúng
chuyện đó, chạy lại được bất cứ lúc nào:

```bash
godot --headless --path . tools/soi_dong_tac.tscn   # dài / trôi / xoay / hở
godot --headless --path . tools/soi_quy_dao.tscn    # quỹ đạo bàn tay, cao hông
```

---

## BỘ CẦM KIẾM — 32 clip

### Di chuyển

| Đích | Nguồn | Vì sao cái này |
|---|---|---|
| `dung` | great sword idle | 2.00s, hở 0.12 → lặp liền mạch |
| `di` | great sword walk | trôi **+Z** = tới trước |
| `di_lui` | great sword walk (2) | trôi **−Z** = lùi |
| `di_trai` | great sword strafe | trôi **+X** = trái |
| `di_phai` | great sword strafe (2) | trôi **−X** = phải |
| `chay` | great sword run **(2)** | trôi +Z. Bản không có "(2)" là chạy LÙI |
| `chay_lui` | great sword run | trôi −Z |
| `chay_trai` | great sword strafe (3) | 0.57s, trôi +X |
| `chay_phai` | great sword strafe (4) | 0.63s, trôi −X |
| `nhay` | great sword jump | 0.63s |
| `lan` | Sprinting Forward Roll | 1.17s — lăn né, cơ chế trung tâm của souls-like |

### Đánh — 7 loại đòn, 7 dáng khác nhau

| Đích | Nguồn | Vì sao cái này |
|---|---|---|
| `danh_1` | great sword slash | 1.27s, hở 0.005 → về đúng dáng đứng |
| `danh_2` | great sword slash (3) | 1.83s, quét ngang 0.63m |
| `danh_3` | great sword slash (4) | 1.80s, xoay 179° → kết combo |
| `nang` | **great sword casting** | 4.80s, tay đi DỌC 1.27m — cú bổ dọc thật |
| `nap` | great sword power up | 3.50s, tay gần như đứng yên → **giữ** được, lặp được |
| `danh_chay` | great sword slide attack | hông thụp xuống 0.25m = trượt tới, đúng đòn lúc đang chạy |
| `danh_nhay` | great sword jump attack | 2.17s, tay lên 1.42m |

### Thủ, ăn đòn, chết

| Đích | Nguồn | Vì sao cái này |
|---|---|---|
| `do_don` | great sword blocking (2) | tay **bất động hoàn toàn** (quỹ đạo 0.00m) → dáng giữ, lặp được |
| `do_phan` | great sword blocking | 0.50s, hông 0.67 → 0.52 = dựng thế thủ. Gọn, hợp cửa sổ 0.24s |
| `trung_don` | great sword impact (2) | hở 0.010 → khựng rồi về đúng dáng đứng |
| `vo_the` | great sword impact (3) | hở 6.7 → loạng choạng, kết thúc lệch dáng |
| `chet` | two handed sword death | dự phòng; thường dùng `chet_*` theo hướng |

### Cất / rút (phím R) và đòn thưởng

| Đích | Nguồn | Vì sao cái này |
|---|---|---|
| `rut_vu_khi` | draw a great sword **2** | tay 1.30m → 0.70m: kéo từ lưng xuống thế thủ |
| `cat_vu_khi` | draw a great sword **1** | tay 0.68m → 1.29m: đưa ngược lên lưng |
| `phan_do` | great sword kick (2) | đá — đòn phản đỡ kiểu Souls |
| `ket_lieu` | great sword attack | 1.20s, đâm gọn, biên độ nhỏ → đúng cú kết liễu vào kẻ đang ngây |

Hai clip cất/rút là **một cặp ngược nhau đọc từ cùng một bộ**, đúng yêu cầu
"tất cả vũ khí đều 1 animation thôi".

---

## BỘ TAY KHÔNG — 11 clip

| Đích | Nguồn |
|---|---|
| `dung` | idle |
| `di` | walking |
| `di_lui`, `chay_lui` | Walking Backwards (dùng cho cả hai) |
| `di_trai` / `di_phai` | left / right strafe walk |
| `chay` | running |
| `chay_trai` / `chay_phai` | left / right strafe |
| `nhay` | jump |
| `chet` | **Dying2** — và năm dáng ngã theo hướng, xem dưới |

---

## CÒN THIẾU — 1 thứ

| Thiếu | Hậu quả | Tìm trên Mixamo |
|---|---|---|
| `uong` (uống bình) | Uống bình nhìn y như đứng yên — mà uống bình là lúc **hở sườn**, người chơi cần đọc được là mình đang không thủ được | **"Drinking"** |

Chỉ còn một cái — `uong`. `lan` (lăn né), `nang` (đòn Bổ), năm `chet_*` theo
hướng, và `khong_vu_khi/nhay` đều **đã gán xong**, xem bảng ở trên. (Bản trước
của tài liệu này liệt chúng vào mục "Thêm sau" như thể còn thiếu — sai, đã xoá.)

**Leo thang chưa lắp.** `Climbing Up` và `Climbing Down Wall` đều đo ra là vòng
lặp tại chỗ (2.00s, hông đứng yên ở 0.69m, hở ~0.01) — leo thang, không phải đu
người qua mép đá. Game chưa có cái thang nào; xem mục cuối trang.

---

## THỪA — 31 file không dùng, và vì sao

### Great Sword — 26 file thừa

| Thứ | Vì sao bỏ |
|---|---|
| `180 turn` ×2, `turn` ×2 | Camera game này xoay mượt liên tục, không có kiểu chốt góc như game bắn súng. Nhân vật không bao giờ "quay tại chỗ" |
| `crouching` ×6 | Game không có cơ chế ngồi khom. Đo được hông 0.34m, dùng nhầm là nhân vật lùn đi nửa mét |
| `casting`, `spell cast` | Có MP rồi nhưng CHƯA có phép nào để niệm. Lúc nào làm phép thì đây là clip sẵn |
| `idle` (2)(3)(4)(5) | Bốn bản đứng yên đổi phiên. Đẹp, nhưng người chơi souls gần như không đứng yên bao giờ |
| `impact`, `impact (4)`, `impact (5)` | `impact` là trúng đòn **lúc đang thủ** (hông 0.52 = vẫn ở thế thủ) — game chưa tách state đó. Hai cái kia khom |
| `high spin attack` | Xoay 171° và trôi 1.69m. Hoành tráng, nhưng nó lôi nhân vật đi xa trong khi hộp đòn đứng yên |
| `blocking (3)` | Là clip **hạ** thế thủ (hông 0.52 → 0.67). Godot hoà 0.12s giữa hai dáng là đủ, không cần clip riêng |
| `jump (2)`, `kick`, `slash (5)` | Bản thay thế của cái đã dùng; riêng `slash (5)` thì khom |
| `two handed sword death (2)` | 2.60s, nằm hẳn ở 0.13m — vừa cửa sổ hồi sinh. Là bản DỰ PHÒNG thật sự, không phải thứ vô dụng |

### Normal — 4 file thừa

`left turn` ×2, `right turn` ×2 — cùng lý do với bên trên.

---

## Clip chết: độ dài KHÔNG còn quan trọng

**Ràng buộc cũ đã hết hiệu lực.** Trước đây trạng thái chết tự hồi sinh sau 2.8
giây, nên clip dài hơn thế bị cắt giữa chừng. Giờ màn **BẠN ĐÃ CHẾT** đợi người
chơi bấm phím chứ không đợi đồng hồ, và nhân vật giữ nguyên khung cuối của clip
— nên clip chết dài bao nhiêu cũng được.

Bảng đo ngày trước vẫn để lại, vì bài học thì còn nguyên: **"dự phòng" và
"thừa" là hai thứ khác nhau.** `Dying2` từng bị xếp vào ô "thừa" chỉ vì đã có
một clip chết khác — rồi hoá ra nó mới là cái vừa cửa sổ 2.8 giây.

| Clip | Dài | Hông ở 2.8s | Kết luận |
|---|---|---|---|
| `two handed sword death` | 2.40s | 0.08m (xong từ lâu) | ✅ đang dùng cho bộ cầm kiếm |
| `two handed sword death (2)` | 2.60s | 0.13m (xong) | ✅ dự phòng, dùng được |
| **`Dying2`** | 2.60s | 0.10m (xong) | ✅ **đang dùng cho bộ tay không** |
| `Death1` | 3.90s | **0.35m — CÒN ĐANG RƠI** | ❌ bị cắt ở 72% |

### Năm dáng ngã theo hướng

Người ngã RA XA cú đánh. Hướng ngã của từng clip đo bằng
`tools/soi_dong_tac.tscn`, không đọc theo tên file.

| File | Nguồn | Khi nào |
|---|---|---|
| `chet_sau` | fallback | đòn từ TRƯỚC mặt ⇒ đổ ngửa ra sau |
| `chet_truoc` | fallforward | đòn từ SAU lưng ⇒ úp mặt về trước |
| `chet_trai` | left | đòn từ bên PHẢI |
| `chet_phai` | right | đòn từ bên TRÁI |
| `chet_manh` | hardhit | sát thương ≥ 25% máu tối đa — bỏ qua hướng |
| `chet` | two handed sword death | dự phòng: chết vì rơi, vì độc… |

Bộ tay không dùng chung `khong_vu_khi/chet.fbx` cho mọi hướng; thiếu clip nào
thì tự mượn bộ cầm kiếm.

---

## Ba cái bẫy, và cái nào đã tự xử

**1. "In Place" — KHÔNG phải tick nữa, code tự khử.**

Bộ tải về **chưa** tick ô đó: đo được `chay` tự đi 1.86m một vòng, `di` 1.07m,
strafe tới 1.42m. Cộng với `move_and_slide()` là nhân vật chạy nhanh gần gấp đôi
luật và trượt như đi trên băng — mà **không lỗi nào nổ ra**, vì bộ kiểm tra đo
`velocity` của thân vật lý, thứ vẫn đúng y như cũ.

`ThanMoHinh._khu_troi()` trừ đi một đường thẳng từ khung đầu tới khung cuối, giữ
nguyên trục Y. Trừ đường thẳng chứ không ghim cứng hông, để còn lại cái lắc hông
trong mỗi bước chân — đúng cái làm bước chân ra bước chân. Giữ Y vì nhảy, lăn,
gục chết đều nhấc hoặc hạ cả người thật.

Nên: **tải kiểu nào cũng được.** Tick "In Place" thì code không có gì để trừ.

**2. Clip đánh không cần đúng độ dài — code tự co giãn.**

Hộp đòn bật/tắt theo `t_dam_tu` / `t_dam_den` trong `moveset.csv`, **không theo
animation**. `_toc_do()` kéo giãn clip cho khớp CSV. Cứ tải về, đừng lo dài ngắn.

**3. Cùng BỘ XƯƠNG với model nhân vật.** Điều kiện duy nhất không có đường vòng.

Lưu ý tên: Mixamo đặt `mixamorig:Hips` nhưng trình nhập FBX của Godot đổi dấu
hai chấm thành **gạch dưới** → trong game nó là `mixamorig_Hips`. Tìm theo tên
có dấu hai chấm thì `find_bone()` trả −1 cho MỌI xương, im lặng, và nhân vật
đứng nguyên tư thế chữ T trượt quanh map.

---

## Vũ khí có HAI thế cầm

Clip Mixamo chỉ được dựng cho MỘT thế: mũi kiếm chúc xuống. Dáng đứng yên vì
thế trông như đang kéo lê thanh kiếm.

Lật thế cầm thì **mọi cú chém lật theo** — đo mũi kiếm trong clip `danh_1`:

| | mũi kiếm lúc đứng yên | mũi kiếm lúc chém |
|---|---|---|
| thế chiến đấu (đo từ clip) | y = 0.04m, chạm đất | quét **0.05 → 1.80m** |
| thế vác lên | y = 1.35m | quét **0.73 → 2.18m** — trên đầu quái |

Nên tách hai: `vu_khi_xoay` cho chiến đấu, `vu_khi_xoay_nghi` cho lúc rảnh.
Đổi giữa hai thế mất 0.12 giây, đúng bằng thời gian hoà clip, nên mắt đọc ra là
"dựng kiếm vào thế thủ".

`ThanMoHinh.TRANG_THAI_RANH` chỉ liệt kê `dung`. Đã thử thêm `di` và
`chay_nhanh`: trong hai clip đó bàn tay xoay khác hẳn, nên cùng một thế cầm lại
đẩy thanh kiếm ra SAU LƯNG và nó biến mất khỏi khung hình. Thế cầm bám vào
XƯƠNG BÀN TAY, không bám vào hướng nhìn — đổi clip là đổi luôn hướng kiếm chĩa.

---

## Đòn nặng: giờ đã là cú "Bổ" thật

`moveset.csv` khai đòn nặng của kiếm hai tay tên là **Bổ** — chém từ trên bổ
xuống. Trong cả 52 file Great Sword **không có clip nào bổ dọc thật**: đo quỹ
đạo bàn tay thì cái dọc nhất cũng chỉ 0.91m, và nó là đòn trên không.

**Đã sửa, và chủ dự án chỉ đúng chỗ.** `great sword casting` đo ra bàn tay đi
**dọc 1.27m** — từ 1.37m trên đỉnh xuống 0.10m sát đất. Đó là cú bổ thật. Lựa
chọn cũ (`slash (2)`) chỉ 0.80m và là một cú xoay.

Clip dài 4.80s; `_toc_do()` tự nén về đúng nhịp `moveset.csv` (2.13s) nên nó
phát nhanh gấp 2.25 lần — không phải cắt tay gì cả.

Đòn Bổ giờ cũng **không có siêu giáp**: cột `sieu_giap` về 0 và `huy_duoc` lên
1 cho mọi `nang` / `nang_nap` trong `moveset.csv`. Chạm là gãy.


---

## Leo thang: có clip rồi, chưa có thang

`Climbing_Up.fbx` đo được là **vòng lặp leo thang tại chỗ** (2.00s, hông đứng
yên ở 0.69m, hở 0.011). Không phải cú đu người qua mép đá — nếu là mép đá thì
hông phải dâng lên trong clip.

Thả file vào đây thì **không có gì xảy ra**, vì `DONG_TAC` không có trạng thái
nào tên `leo`, và máy trạng thái cũng không có. Muốn dùng thì phải làm cơ chế,
và cơ chế đó tối thiểu gồm:

1. **Chỗ leo trong bản đồ** — một `Area3D` đánh dấu thang, biết trục dọc và hai
   đầu. Bản đồ hiện sinh tự động từ CSV, nên đây là cột mới trong `vung.csv`.
2. **Trạng thái `leo`** — khoá di chuyển vào đúng trục thang, W/S đổi thành lên
   xuống, và `cho_doi()` phải chặn `lan` / `danh` / `nhay`: lăn giữa lưng chừng
   thang là rơi xuyên sàn.
3. **Vào và ra** — Elden Ring có clip riêng cho lúc bám vào và lúc trèo lên tới
   đỉnh. Thiếu hai clip đó thì nhân vật dính vào thang bằng một cú giật.
4. **Camera** — leo thang là lúc duy nhất camera không được xoay tự do, nếu
   không người chơi mất phương hướng giữa chừng.

Tức là một mốc riêng, không phải một file. Clip đã có sẵn ở đây khi nào làm tới.
