# Tiến độ

Sổ tiến độ theo 7 mốc ở mục 12 của `PROMPT_3D.md`.
**Cập nhật file này mỗi khi xong một mốc** — đây là thứ session mới đọc đầu tiên
để biết đang ở đâu.

| # | Mốc | Trạng thái |
|---|---|---|
| 1 | Đi lại — nhân vật 3D, state machine, camera F5 ba chế độ, một phòng thử | ✅ xong |
| 2 | **Combat lõi** — thể lực, lăn i-frame, đòn nhẹ/nặng, cam kết đòn, khoá mục tiêu, quái đánh trả | ✅ xong, **chưa tune** |
| 3 | Trang bị + đọc chữ — khe, tải trọng, cơ chế `???`, nối VocabDB | 🟡 tầng luật xong, chưa có giao diện |
| 4 | Vòng lặp souls — bia đá, chết rơi chữ, nhặt lại, hồi sinh quái, ghép chữ, ngồi thiền | 🟡 tầng luật xong, chưa có bia đá trong scene |
| 5 | Ngũ hành + boss — tương sinh tương khắc, thang chồng bộ, boss hai giai đoạn | 🟡 ngũ hành + thang xong, chưa có boss |
| 6 | Thế giới — 7 vùng, địa hình, streaming, đường tắt, shader "vùng bị xoá" | ⬜ chưa |
| 7 | Nội dung & đánh bóng — NPC, cốt truyện, âm thanh, animation thật | ⬜ chưa |

## ĐANG LÀM DỞ — đọc trước khi viết gì mới

Ba file vừa thêm, **chưa nối vào scene nào**, nên chạy game chưa thấy:

| File | Trạng thái |
|---|---|
| `scripts/giao_dien/man_chung.gd` | xong — lớp gốc cho màn che toàn màn |
| `scripts/giao_dien/man_hanh_trang.gd` | xong — màn hành trang với cơ chế `???` |
| `scripts/luat/cau_hoi.gd` | xong — sinh đủ 10 dạng câu hỏi cho ngồi thiền |

Việc còn thiếu để ba file trên sống được:

1. `scripts/giao_dien/man_bia_da.gd` — bốn thẻ: ghép chữ / ngồi thiền (dùng
   `CauHoi`) / khắc chữ / nâng chỉ số.
2. `scripts/the_gioi/bia_da.gd` + `scenes/the_gioi/bia_da.tscn` — Area3D, bấm E
   để nghỉ, gọi `TheGioi.nghi(ma)`.
3. Nhét `ManHanhTrang` vào `phong_thu.tscn` và nối phím `hanh_trang` (I) để mở.
4. `scripts/the_gioi/vat_roi.gd` — món đồ rơi ngoài đất, nhặt được.
5. `scripts/the_gioi/vung_hon.gd` — vũng hồn chỗ chết, về nhặt lại (mục 4.5).

## Việc tiếp theo, theo thứ tự

1. **Bia đá** (`scenes/the_gioi/bia_da.tscn` + giao diện bốn việc của mục 4.6:
   ghép chữ / ngồi thiền / khắc chữ / nâng chỉ số). Đây là chỗ việc học thật sự
   diễn ra — không có nó thì mốc 4 chỉ là nửa vời.
2. **Màn hành trang** — hiện `???` cho chữ chưa đọc được (mục 4.1). Tầng luật đã
   xong (`TenDoVat.dong_mo_ta`), chỉ thiếu phần vẽ.
3. **Boss hai giai đoạn** — dữ liệu đã có trong `data/boss.csv`, thiếu scene và
   state machine riêng (đổi moveset khi máu dưới `nguong_gd2`).
4. **Tune ba con số của mục 5.2.** Việc này **phải làm bằng tay, trên máy có màn
   hình** — không agent nào thay được. Xem mục "Cần người" bên dưới.

## Đã làm được gì (chi tiết)

### Dữ liệu
- 993 chữ của bản 2D + 18 chữ mới = **1011 chữ**. Chữ mới là bậc trên của thang
  chồng bộ (炎焱昌晶圭垚淼鑫吕品), hai chỉ số còn thiếu (韧智), bốn thiên can
  (乙丙丁戊), và hai chữ có trong `nguyen_lieu.csv` mà thiếu ở `tu_vung.csv`
  (斧盔).
- Năm cột mới ở `tu_vung.csv`: `so_net` `ngu_hanh` `thang_goc` `thang_bac`
  `tan_suat`. Cột cũ **không đụng**.
- `so_net` và `tan_suat` **cố ý để trống** với phần lớn chữ — chỉ điền cho những
  chữ đã tra chắc. Code tự lùi về cột `cap` (`VocabDB.do_kho_cua`). Điền bừa
  1011 dòng số nét còn tệ hơn để trống.
- Năm file mới: `moveset.csv` `don_quai.csv` `quai.csv` `boss.csv` `vung.csv`.

### Tầng luật (xong, có test)
- `chien_dau.gd` `do_hiem.gd` port gần nguyên từ bản 2D.
- `souls_like.gd` — thể lực, i-frame theo tải trọng và 韧, thế đứng, tư thế, đỡ
  phản, thanh trạng thái tích dần, thiên can 甲乙丙丁戊.
- `ngu_hanh.gd` — cả vòng suy ra từ một mảng năm phần tử, không có bảng khai tay.
- `ten_do_vat.gd` — **cơ chế xương sống**. 冰金剑 và 金冰剑 ra hai món khác nhau.
- `tri_nho.gd` — bốn mức thuần thục, lịch ôn SM-2 rút gọn (1→3→7→16→35 ngày).

### Chơi được
Chạy `godot --path .` là vào thẳng phòng thử: chạy quanh, đổi camera bằng F5,
khoá mục tiêu, đánh bốn con quái. Quái đuổi, đánh trả, vỡ tư thế, chết, rơi hồn.

## Cần người, agent không làm thay được

1. **Tune ba con số của mục 5.2.** Mốc 2 là điểm quyết định của cả dự án và nó
   chỉ tune được bằng cách CHƠI. Ba con số: `SoulsLike.iframe_lan`,
   `SoulsLike.khung_the_luc`, và cột `t_hoi` của đòn nặng trong `moveset.csv`.
   Test chỉ canh được khoảng hợp lệ, không canh được "đã đã tay chưa".
2. **Thiết kế màn.** Đường tắt, mai phục, vòng lặp — mục 7.1 của bản yêu cầu nói
   thẳng là AI làm dở việc này. Vùng hoang dã thì sinh tự động được.
3. **Kho model.** Chưa có file `.glb` nào. Xem mục "Quy ước" trong `CLAUDE.md`
   về chuẩn cần đạt.

## Đã đổi so với bản yêu cầu

Ghi lại để không ai tưởng là quên:

- **Không dùng Terrain3D / ProtonScatter** (mục 7.3). Chủ dự án chọn tự viết —
  repo sạch, không phụ thuộc phiên bản addon. Địa hình sẽ viết ở mốc 6.
- **Điểm chỉ số của chữ ngoài `nguyen_lieu.csv`** suy từ độ khó của chữ, không
  chỉnh tay. 38 nguyên liệu của bản 2D giữ nguyên giá trị đã cân bằng, nhưng bản
  3D cho khắc bất kỳ chữ nào đã học lên vũ khí, mà 1011 chữ thì không gán tay
  được. Chữ càng hiếm càng góp nhiều — đúng tinh thần "độ hiếm = độ khó".
- **Đòn của quái tách thành `don_quai.csv`** riêng, không gộp vào `moveset.csv`.
  Hai bảng có cột khác nhau (quái không tốn thể lực, người chơi không lao tới).
- **Hành của món đồ lấy từ chữ BỔ NGHĨA gần trung tâm nhất**, chỉ dùng hành của
  chữ trung tâm khi không bổ nghĩa nào có hành. Nếu để trung tâm tham gia cùng
  vòng quét thì nó luôn thắng (nó gần trung tâm nhất — nó *là* trung tâm) và mọi
  cây kiếm đều thành hệ Kim bất kể khắc chữ gì. Test bắt được đúng lỗi này.
