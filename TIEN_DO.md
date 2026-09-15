# Tiến độ

Sổ tiến độ theo 7 mốc ở mục 12 của `PROMPT_3D.md`.
**Cập nhật file này mỗi khi xong một mốc** — đây là thứ session mới đọc đầu tiên
để biết đang ở đâu.

| # | Mốc | Trạng thái |
|---|---|---|
| 1 | Đi lại — nhân vật 3D, state machine, camera F5 ba chế độ, một phòng thử | ✅ xong |
| 2 | **Combat lõi** — thể lực, lăn i-frame, đòn nhẹ/nặng, cam kết đòn, khoá mục tiêu, quái đánh trả | ✅ xong, **chưa tune** |
| 3 | Trang bị + đọc chữ — khe, tải trọng, cơ chế `???`, nối VocabDB | ✅ xong — màn hành trang bấm I là mở |
| 4 | Vòng lặp souls — bia đá, chết rơi chữ, nhặt lại, hồi sinh quái, ghép chữ | ✅ xong trong phòng thử |
| 5 | Ngũ hành + boss — tương sinh tương khắc, thang chồng bộ, boss hai giai đoạn | 🟡 ngũ hành + thang xong, chưa có boss |
| 6 | Thế giới — 7 vùng, địa hình, streaming, đường tắt, shader "vùng bị xoá" | ⬜ chưa |
| 7 | Nội dung & đánh bóng — NPC, cốt truyện, âm thanh, animation thật | ⬜ chưa |

## ĐANG LÀM DỞ — đọc trước khi viết gì mới

Không còn file nào treo lơ lửng. Mọi thứ trong repo đều nối vào phòng thử và có
test canh.

## Việc tiếp theo, theo thứ tự

1. **Boss hai giai đoạn** (mốc 5). Dữ liệu đã có trong `data/boss.csv`, thiếu
   scene và state machine riêng — đổi moveset khi máu dưới `nguong_gd2`. Đây là
   việc lớn tiếp theo làm được mà không cần máy có màn hình.
2. **Địa hình vùng đầu** (mốc 6). Tự viết, không dùng Terrain3D — xem mục "Đã
   đổi so với bản yêu cầu" bên dưới. Bắt đầu bằng `ria_bien`: `vung.csv` đã khai
   sẵn hạt giống, cao độ, độ gồ ghề, mật độ cây đá.
   Kèm theo: mỗi vùng một `WorldEnvironment` riêng sinh từ `vung.csv` lúc chạy
   (`scripts/the_gioi/moi_truong_vung.gd`, **chưa viết**), lấy
   `scenes/the_gioi/moi_truong_mac_dinh.tres` làm nền chung. Mục 7.4 của bản
   yêu cầu nói thẳng: chỗ đáng đầu tư để "đẹp" là **ÁNH SÁNG**, không phải hình
   khối — một quả đồi đơn giản + ánh sáng tốt đẹp hơn hẳn quả đồi chi tiết +
   ánh sáng mặc định. Và ánh sáng là thứ chỉnh được bằng số.
3. **Đổi phòng thử thành vùng thật.** `phong_thu.gd` đặt quái bằng một mảng
   hằng; vùng thật phải đọc `quai.csv` theo cột `vung`.
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
  Thêm phần khắc chữ: lắp / tháo / giá khắc tăng theo độ dài tên.
- `tri_nho.gd` — bốn mức thuần thục, lịch ôn SM-2 rút gọn (1→3→7→16→35 ngày).
- `cau_hoi.gd` — mười dạng câu hỏi, 41 câu ngữ pháp, tách hẳn khỏi giao diện.
- `sinh_mon_do.gd` — sinh đồ rơi từ CSV, không một chữ Hán nào nằm trong code.
  Trung tâm lấy từ `nguyen_lieu.csv`, bổ nghĩa trộn thêm chữ theo chủ đề vùng,
  nên đi sâu là gặp chữ khó hơn.

### Chơi được
Chạy `godot --path .` là vào thẳng phòng thử. Làm được trọn vòng souls:

- chạy quanh, đổi camera F5, khoá mục tiêu, đánh bốn con quái. Phím đánh:
  **bấm chuột trái** = đòn nhẹ, **giữ chuột trái** = đòn nặng rồi đòn nạp,
  **chuột phải** = đỡ phản, Space = lăn (giữ = chạy), Q = giơ khiên
- nhặt đồ dưới đất (bấm **E**), mở hành trang (bấm **I**) — chữ chưa đọc được
  hiện `□`, chỉ số hiện `???`
- bấm **E** ở bia đá: bật bia, hồi đầy máu và bình, quái sống lại hết, mở màn
  ba thẻ — **ghép chữ / khắc chữ / nâng chỉ số**
- chết: rơi hết hồn chưa tiêu thành **vũng hồn** tại chỗ, đứng dậy ở bia đá, về
  nhặt lại được. Chết lần nữa trước khi nhặt là mất vĩnh viễn.

### Kiểm tra
Ba bộ, GitHub Actions chạy cả ba mỗi lần đẩy code:

| Lệnh | Kiểm gì |
|---|---|
| `godot --headless --path . tools/kiem_tra.tscn` | tầng luật, 170 test trong một khung hình |
| `godot --headless --path . tools/thu_vong_lap.tscn` | vòng lặp souls + nút đánh trong phòng thử thật, 56 test theo thời gian |
| `python tools/kiem_csv.py` | CSV, không cần Godot |

Bộ thứ hai mới thêm ở mốc 4: mốc này là một chuỗi việc diễn ra **theo thời gian
qua nhiều node**, tầng luật không với tới được.

## Cần người, agent không làm thay được

1. **Tune ba con số của mục 5.2.** Mốc 2 là điểm quyết định của cả dự án và nó
   chỉ tune được bằng cách CHƠI. Ba con số: `SoulsLike.iframe_lan`,
   `SoulsLike.khung_the_luc`, và cột `t_hoi` của đòn nặng trong `moveset.csv`.
   Test chỉ canh được khoảng hợp lệ, không canh được "đã đã tay chưa".
2. **Thiết kế màn.** Đường tắt, mai phục, vòng lặp — mục 7.1 của bản yêu cầu nói
   thẳng là AI làm dở việc này. Vùng hoang dã thì sinh tự động được.
3. **Kho model.** Chưa có file `.glb` nào. Xem mục "Quy ước" trong `CLAUDE.md`
   về chuẩn cần đạt.
4. **Đọc thử tên đồ rơi ra.** Bộ sinh đồ ghép chữ theo đúng ngữ pháp, nhưng
   nghĩa thì có cái hay (战斧 chiến phủ) có cái ngô nghê. Cần người đọc một loạt
   rồi quyết xem có cần lọc chữ nào ra khỏi kho bổ nghĩa không.

## Đã đổi so với bản yêu cầu

Ghi lại để không ai tưởng là quên:

- **Bỏ thẻ "Ngồi thiền" ở bia đá.** Chủ dự án chơi thử và thấy ngồi trả lời hết
  câu trắc nghiệm này tới câu khác quá mất thì giờ so với thứ nhận lại được.
  Việc học giờ nằm trọn trong hai thẻ CHẾ ĐỒ: **ghép chữ và khắc chữ đều tính
  là ôn tập** (`TriNho.on_tap`), nên chữ được ôn bằng việc DÙNG nó chứ không
  bằng việc bị hỏi về nó — và cơ chế phai vẫn có đường hồi phục, không thành
  một chiều. `cau_hoi.gd` + `ngu_phap.csv` vẫn ở lại repo và vẫn có test canh
  (nhóm "Mười dạng câu hỏi"), vì test đó là thứ duy nhất bắt Godot biên dịch
  `cau_hoi.gd`; chỉ là không màn nào gọi tới nữa.
- **Chỉ lăn / đỡ phản / chạy tốn thể lực.** Trước đây mọi đòn đánh đều tốn, mà
  `ton_the_luc()` đặt lại 0.8s khựng mỗi lần tiêu — nên đánh năm nhát là đứng
  ngây giữa trận. Đánh, nhảy, đỡ đòn giờ miễn phí. Hai thứ trước kia do thể lực
  ghìm phải đổi tay, đừng gỡ mất: nhịp đòn đánh giờ do **cam kết đòn + `t_hoi`**
  ghìm, và "đứng giơ khiên" giờ do **tư thế** ghìm (đỡ mãi thì vỡ thế kiểu
  Sekiro) chứ không do cạn thể lực. Cột `the_luc` của `moveset.csv` vì vậy hiện
  không ai đọc — giữ lại phòng khi đổi ý.
- **Một nút chuột trái ra cả đòn nhẹ lẫn đòn nặng.** Nhả trước
  `NguoiChoi.NGUONG_GIU_NANG` (0.22s) là nhẹ, giữ lâu hơn là nặng, giữ tiếp nữa
  thành đòn nạp. Chuột phải chuyển thành **đỡ phản** (phím R vẫn dùng được).
  Action `don_nang` đã gỡ khỏi input map; cái tên chỉ còn sống trong bộ đệm phím.
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
- **Đổi thứ tự chữ ở bàn khắc là MIỄN PHÍ.** Đó là bài học của mục 4.2, mà bài
  học thì không được bắt trả tiền để thử. Khắc thêm chữ mới thì tốn hồn.
- **Xác suất quái rơi đồ suy từ cột `hon`** chứ không thêm cột mới: con cho nhiều
  hồn là con hiếm, con hiếm thì hay rơi đồ. Thêm quái vào `quai.csv` là có ngay
  tỉ lệ hợp lý, không phải khai thêm gì.

## Bẫy đã dính, ghi lại cho đỡ dính lần nữa

- **`sinh()` là hàm có sẵn của GDScript** (sin hyperbol). Hàm tĩnh tên `sinh`
  trong class của mình sẽ bị hàm có sẵn ăn mất mọi lời gọi không có tiền tố,
  *trong chính file đó*. Lỗi này nằm im trong `cau_hoi.gd` cả một mốc vì chưa
  file nào dùng tới `CauHoi` nên Godot chưa từng biên dịch nó. Giờ tên là
  `CauHoi.sinh_cau()` và `SinhMonDo.sinh_mon()`.
- **`Array.shuffle()` bốc từ RNG toàn cục**, không từ `RandomNumberGenerator`
  đã gieo hạt. Trộn hai thứ vào một hàm là mất tính tất định của hạt giống.
- **Script không gắn vào scene nào thì Godot không biên dịch.** CI xanh không có
  nghĩa là file đó chạy được. Cách duy nhất để chắc: nối nó vào scene, hoặc gọi
  nó trong bộ kiểm tra.
- **`queue_free()` chỉ đánh dấu**, node vẫn nằm trong cây tới hết khung hình. Dựng
  lại danh sách giao diện thì phải `remove_child()` trước, không thì container
  xếp cả hàng cũ lẫn hàng mới.
