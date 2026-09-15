# Tiến độ

Sổ tiến độ theo 7 mốc ở mục 12 của `PROMPT_3D.md`.
**Cập nhật file này mỗi khi xong một mốc** — đây là thứ session mới đọc đầu tiên
để biết đang ở đâu.

| # | Mốc | Trạng thái |
|---|---|---|
| 1 | Đi lại — nhân vật 3D, state machine, camera F5 ba chế độ, một phòng thử | ✅ xong |
| 2 | **Combat lõi** — thể lực, lăn i-frame, đòn nhẹ/nặng, cam kết đòn, khoá mục tiêu, quái đánh trả | ✅ xong + có test hành vi, **chưa tune** |
| 3 | Trang bị + đọc chữ — khe, tải trọng, cơ chế `???`, nối VocabDB | ✅ xong — màn hành trang bấm I là mở |
| 4 | Vòng lặp souls — bia đá, chết rơi chữ, nhặt lại, hồi sinh quái, ghép chữ | ✅ xong trong phòng thử |
| 5 | Ngũ hành + boss — tương sinh tương khắc, thang chồng bộ, boss hai giai đoạn | ✅ xong |
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
  **Không màn nào gọi nữa** từ khi bỏ thẻ Ngồi thiền; ở lại repo vì nhóm test
  "Mười dạng câu hỏi" là thứ duy nhất bắt Godot biên dịch nó.
- `sinh_mon_do.gd` — sinh đồ rơi từ CSV, không một chữ Hán nào nằm trong code.
  Trung tâm lấy từ `nguyen_lieu.csv`, bổ nghĩa trộn thêm chữ theo chủ đề vùng,
  nên đi sâu là gặp chữ khó hơn.

### Chơi được
Chạy `godot --path .` là vào thẳng phòng thử. Làm được trọn vòng souls:

- vào phòng là **đã cầm sẵn 长剑 và 长盾** (hiện `□□` — phát đồ sẵn không tắt
  cơ chế ???). Đổi `HAT_VU_KHI` trong `phong_thu.gd` là đổi vũ khí khởi đầu.
- chạy quanh, đổi camera F5, khoá mục tiêu, đánh bốn con quái. Phím đánh:
  **bấm chuột trái** = đòn nhẹ, **giữ chuột trái** = đòn nặng rồi đòn nạp,
  **chuột phải** = đỡ phản (cần khiên), Space = lăn (giữ = chạy),
  Q = giơ khiên → đỡ trúng rồi giữ chuột trái = **đòn phản đỡ**
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
| `godot --headless --path . tools/kiem_tra.tscn` | tầng luật, 196 test trong một khung hình |
| `godot --headless --path . tools/thu_vong_lap.tscn` | vòng lặp souls + combat + boss trong phòng thử thật, 147 test theo thời gian |
| `python tools/kiem_csv.py` | CSV, không cần Godot |

Bộ thứ hai mới thêm ở mốc 4: mốc này là một chuỗi việc diễn ra **theo thời gian
qua nhiều node**, tầng luật không với tới được.

## Combat kiểu Elden Ring

Chủ dự án yêu cầu bám ER. Đây là bảng đối chiếu — **đọc trước khi đổi gì trong
combat**, vì mấy chỗ "cố ý khác" rất dễ bị sửa nhầm về ER rồi hỏng thứ khác.

### Đã làm y hệt

| Cơ chế | Elden Ring | Ở đây |
|---|---|---|
| Ngưỡng tải trọng | 30% / 70% / 100% | `SoulsLike.NGUONG_TAI`, đúng ba mốc |
| i-frame theo tải | gần như PHẲNG (13/13/12 khung) | 1.00 / 1.00 / 0.92, quá tải = 0 |
| Phạt giáp nặng | ở HỒI LĂN (8 khung → 16 khung) | `HOI_LAN_TAI`, nặng ×2 |
| Quãng lăn theo tải | 4.09 / 3.21 / 2.66 / 0.51 m | cột `xa`: 1.00 / 0.78 / 0.65 / 0.12 |
| Cái gì tốn thể lực | đánh, lăn, nhảy, chạy, đỡ một đòn | y hệt |
| Hồi thể lực | không hồi lúc bận, xong việc chờ ngắn rồi hồi nhanh | `cho_hoi_the_luc()` + `tre_hoi` |
| Không hồi khi giơ khiên | có | `do_don.cho_hoi_the_luc()` |
| Siêu giáp (hyperarmor) | thế đứng tạm trong khung vung, đòn nặng/vũ khí to mới có | cột `sieu_giap` của `moveset.csv` |
| Tỉ lệ phá thế | nhẹ 5 · nhảy-nhẹ 8 · nặng 10 · nhảy-nặng 20 · nạp 30 · phản đỡ 30 | ×1 / ×1.6 / ×2 / ×4 / ×6 / ×6 trên nền đòn nhẹ |
| Đòn phản đỡ (guard counter) | đỡ trúng rồi bấm đòn nặng, phá thế ngang đòn nạp | đòn `phan_do`, `cua_so_phan_do` |
| Vỡ đỡ (guard break) | đỡ tới cạn thể lực → choáng, ăn kết liễu | `NguoiChoi.an_don()` |
| Parry cần khiên | không parry tay không được | `NguoiChoi.co_khien()`, khe `tay_trai` chỉ nhận `loai=khien` |
| Chặn đỡ (guard boost) | khiên tốt thì đỡ đỡ tốn thể lực | `_chi_so_chan_do()` |

### Cố ý KHÁC, và vì sao

- **Một nút chuột trái ra cả đòn nhẹ lẫn đòn nặng**, thay vì R1/R2 như ER và
  như bản yêu cầu đầu. Chủ dự án chốt, và chấp nhận cái giá đi kèm: đòn nhẹ
  chỉ bắn ra lúc NHẢ chuột chứ không phải lúc bấm, vì phải đợi mới biết người
  chơi định bấm hay định giữ. Đó là 0.18s trễ trên mọi cú chém thường
  (`NguoiChoi.NGUONG_GIU_NANG`). Muốn hết trễ thì phải tách hai nút.
- **Nạp đòn nặng thì lết được** (tốc độ ×0.30). ER không cho đi lúc nạp —
  đứng im là cả cái giá của đòn nạp. Chủ dự án chốt cho đi, nên cái giá chuyển
  sang tốc độ: chậm hơn cả giơ khiên (×0.45). Có test canh cả ba vế — lết được,
  chậm hơn hẳn đi thường, và đòn nhẹ thì vẫn bám chân tại chỗ.
- **Sai hệ ngũ hành KHÔNG làm quái hồi máu nữa** — sàn 0.25×. ER không có cơ
  chế này, mà bản 2D thì để hệ số âm. Bỏ vì luật 4 của `CLAUDE.md`: gặp boss
  sai hệ mà chỉ có một vũ khí là tắc hẳn. 0.25× vẫn đủ đau (đánh lâu gấp bốn).

- **i-frame 0.35s chứ không phải 0.217s.** ER cho 13 khung ở 60fps = 0.217s.
  Mục 5.2 của `PROMPT_3D.md` lại bắt i-frame nằm trong **0.30–0.40s**, và có
  test canh. Hai bên đá nhau; chọn theo bản yêu cầu của chính dự án. Muốn đúng
  ER thì đổi `SoulsLike.iframe_lan` về 0.22 và sửa khoảng trong `kiem_tra.gd`.
- **Không có cầm hai tay.** ER cho cầm hai tay để đỡ bằng vũ khí và +30% phá
  thế. Ở đây tay trái là khe khiên riêng; tay không vẫn đỡ được nhưng chặn
  chỉ 35 (khiên tệ nhất là 40), coi như thay cho "đỡ bằng vũ khí".
- **Thế đứng và phá thế dùng CHUNG một con số** (`pha_the`). ER tách đôi:
  poise damage quyết định có khựng không, stance damage mới tích vào thanh vỡ
  thế. Gộp lại để `moveset.csv` khỏi có hai cột phải cân riêng — tách ra là
  việc làm sau nếu thấy thiếu.
- **Không có Ash of War.** ER cho gắn kỹ năng lên vũ khí, gồm cả Parry lên dao
  và nắm đấm. Ở đây parry buộc phải có khiên, không có đường vòng.
- **Nhảy né đòn quét** có, nhưng chưa có đòn quét ngang nào của boss để né.

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
  không ai đọc — giữ lại phòng khi đổi ý. **(Đã đổi ý ở đợt làm combat kiểu
  Elden Ring: đánh tốn thể lực trở lại, cột `the_luc` được đọc lại rồi.)**
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

- **Cái xác nhặt được hồn của chính nó.** `TuongTacDuoc` chỉ hỏi "có phải thứ
  gần nhất không", không hỏi "người chơi còn đứng được không". Mà vũng hồn mọc
  ĐÚNG chỗ ngã xuống, nên cái xác nằm trọn trong tầm với của nó suốt 2.8 giây
  trước khi đứng dậy ở bia — bấm E lúc đó là nhặt lại sạch, mất trắng thành ra
  không mất gì, cả mục 4.5 sụp theo. Bộ test cũ không bắt được vì nó gọi thẳng
  `vung.tuong_tac()`, đi vòng qua đúng chỗ hỏng. Bài học: **test đường tắt thì
  không bắt được lỗi ở đường chính** — muốn canh phím thì phải bơm phím thật.

- **Hai thang số chưa bao giờ được quy về nhau.** Điểm `cong` của
  `nguyen_lieu.csv` là thang bản 2D (đánh theo lượt, đúng một câu = quái mất
  MỘT máu), còn máu quái trong `quai.csv` (120–300) và máu người chơi (390) là
  thang hành động thời gian thực. Chồng hai thang lên nhau thì một nhát kiếm
  10 điểm đập vào con quái 300 máu: **đo thật là 48–50 nhát** mới hạ nổi một
  con thường, trong khi nó giết mình trong 13. Người chơi đọc ra là "máu quái
  vô hạn" và họ đúng. Sửa bằng một hằng số
  `SoulsLike.HS_SAT_THUONG_NGUOI_CHOI`, không sửa 38 nguyên liệu — giá trị của
  bản 2D đã cân với nhau rồi, chỉ sai thang. Có test canh khoảng 2–14 đòn.

- **Hộp đòn từng bị kéo theo cánh tay diễn hoạt ảnh.** `than_khoi.gd` tự nhận
  là "thuần chỗ để nhìn", nhưng nó gắn một `RemoteTransform3D` kéo `GanTayPhai`
  — node mang hộp đòn — theo `_tay_phai`. Nghĩa là HỘP ĐÒN nằm ở đâu do dáng
  vung tay quyết định. Thêm một cái nghiêng người 4° cho đòn nặng trông nặng
  hơn là **cả game hết trúng đòn**: không lỗi nào, không cảnh báo nào, 112 test
  vẫn xanh vì tầng luật có sai đâu. Giờ điểm gắn đứng yên ở ngực và chỉ quay
  theo thân, nên `tam_voi` / `goc_quet` của `moveset.csv` mới thật sự là tầm
  với. Có test canh ở `_phan_nhin()`: đòn phải trúng thật và đòn giữ phải đau
  hơn đòn bấm nhanh.

- **`cho_doi()` từng là đồ trang trí.** Sáu state cài nó cẩn thận, `CLAUDE.md`
  gọi nó là cơ chế xương sống của cam kết đòn — mà `xin_doi()`, hàm duy nhất
  hỏi tới nó, **không chỗ nào gọi**. Cam kết đòn vẫn đúng, nhưng đúng do tình
  cờ (state đánh không đọc phím), không phải do luật. Hậu quả thật: một đòn
  vặt cắt được người chơi ra khỏi `vo_the` sang `trung_don` — biến hình phạt
  nặng nhất của game thành nhẹ hơn cả trúng đòn thường. Bài học: **một cơ chế
  không có test thì không tồn tại**, dù nó được viết và được ghi vào tài liệu.

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
