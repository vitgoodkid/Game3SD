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
| 6 | Thế giới — 7 vùng, địa hình, streaming, du hành, "vùng bị xoá" | ✅ xong |
| 7 | Nội dung & đánh bóng — NPC, cốt truyện, âm thanh, 18 loài, boss ẩn 无 | 🟡 người chơi có model + 43 clip động tác thật; quái vẫn khối hộp |
| — | **Giao diện** — HUD hai quả cầu, minimap, menu tạm dừng, tuỳ chọn, font | ✅ xong (ngoài bảy mốc, chủ dự án đặt thêm) |

## ĐANG LÀM DỞ — đọc trước khi viết gì mới

Không còn file nào treo lơ lửng. Mọi thứ trong repo đều nối vào một cảnh chạy
được và có test canh.

## Việc tiếp theo, theo thứ tự

Bảy mốc của mục 12 đã hết bảng. Cái còn lại là những lỗ hổng lộ ra KHI GHÉP
mọi thứ vào nhau — không mốc nào sở hữu chúng, nên không mốc nào làm.

### 1. `HINH_VU_KHI` — đã hết là đường chính, còn lại là dọn rác

**Phần lớn đã sửa.** Vũ khí có model thật đọc hình từ cột `mo_hinh` của
`nguyen_lieu.csv` rồi (đợt "Model thật, 43 clip động tác"). `than_khoi.gd` vẫn
còn gán cứng `剑 刀 斧 弓 拳`, nhưng giờ nó chỉ là **khối hộp dự phòng cho vũ khí
CHƯA có file `.fbx`** — không còn là đường đi chính, không còn phá luật 1 theo
kiểu nghiêm trọng như trước. Việc còn lại (không gấp): vũ khí mới thêm vào CSV
mà chưa có model thì vẫn hiện nhầm hình kiếm ở khối hộp dự phòng — chấp nhận
được vì đằng nào cũng là hình tạm.

### 2. Hai nút "gõ nhanh / giữ" còn đờ (nếu chủ dự án muốn)

Cùng một bệnh ở hai chỗ, vì cùng một khuôn:

- **Chuột trái.** Bấm nhanh thì đòn nhẹ nổ lúc NHẢ (trễ 0.18s); giữ thì 0.18s
  đầu nhân vật đứng im rồi mới giơ tay. Cách game khác chữa: **khung giơ tay
  dùng chung** — bấm là vào `danh` ngay, tới cuối khung giơ mới xem còn giữ nút
  không rồi phân nhánh. Đòi `danh.gd` cho đổi `_don` giữa chừng (file đó đang
  cố tình khoá cứng), và đòi `nhe_1` với `nang` của mỗi vũ khí có `t_vung`
  bằng nhau.
- **Space.** Khuôn đã đổi từ "gõ/giữ" sang **BẤM ĐÔI = lăn, BẤM ĐƠN = nhảy**
  (`NGUONG_BAM_DOI` 0.22s). Chiều trễ vì thế lật ngược so với chuột trái: LĂN
  bắn ra ngay ở cú bấm thứ hai, còn NHẢY phải đợi hết cửa sổ mới dám gọi là
  nhảy. Đổi như vậy là cố ý — lăn là thứ cứu mạng, nhảy thì không.
  Cái còn lại đáng lo: nhảy trễ 0.22s mà nhảy là để né đòn quét ngang của
  boss. Chưa có đòn quét ngang nào của boss để đo thật, nên **đo được rồi mới
  quyết**. Chữa rẻ nhất là hạ con số; chữa hẳn thì tách nhảy sang nút riêng.

### 3. Tune bốn con số của mục 5.2

**Phải làm bằng tay, trên máy có màn hình** — không agent nào thay được. Xem
mục "Cần người" bên dưới.

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

- vào phòng là **đã cầm sẵn kiếm hai tay 刃** + một khiên trong túi (hiện `□`
  — phát đồ sẵn không tắt cơ chế ???). Cầm hai tay thì khiên trong túi KHÔNG
  dùng được (`Tui.tay_trai_dang_cam()` trả null) — đó là cái giá của vũ khí
  lớn. Đổi `CHU_VU_KHI_DAU`/`HAT_VU_KHI` trong `phong_thu.gd` là đổi vũ khí
  khởi đầu.
- chạy quanh, đổi camera F5, khoá mục tiêu, đánh quái và một boss. Phím đánh:
  **bấm chuột trái** = đòn nhẹ, **giữ chuột trái** = đòn nặng rồi đòn nạp,
  **chuột phải bấm** = đỡ phản (bấm sớm = **đỡ phản hoàn hảo**),
  **chuột phải giữ** = giơ khiên → đỡ trúng rồi giữ chuột trái = **đòn phản
  đỡ**. Một nút gánh cả hai, E và Q trống hẳn.
  Space = lăn (giữ = **nhảy**), **Shift** giữ = chạy,
  R = cất/rút vũ khí (chạy nhanh hơn, tốn ít thể lực hơn, nhưng không đánh được)
- **đòn nhảy**: đánh lúc đang ở trên không ra một moveset riêng, bấm = nhẹ,
  giữ = nặng. Mỗi lần rời đất đúng một đòn.
- nhặt đồ dưới đất (bấm **F**), mở hành trang (bấm **I**) — chữ chưa đọc được
  hiện `□`, chỉ số hiện `???`
- bấm **F** ở bia đá: bật bia, hồi đầy máu và bình, quái sống lại hết (boss
  KHÔNG sống lại), mở màn **bốn thẻ** — **ghép chữ / khắc chữ / nâng chỉ số /
  du hành** (du hành đi sang vùng khác, mốc 6)
- chết: dáng ngã theo hướng đòn tới, màn **BẠN ĐÃ CHẾT** đợi bấm phím chứ
  không đợi đồng hồ. Rơi hết hồn chưa tiêu thành **vũng hồn** tại chỗ, đứng
  dậy ở bia đá, về nhặt lại được. Chết lần nữa trước khi nhặt là mất vĩnh viễn.
- nghỉ bia / hạ boss / thoát game đều **tự lưu** (`LuuGame`) — xem README.md
  mục "Lưu game".

### Màn hình đầu game và đường vào ván
Mở game lên là vào **màn hình đầu game** (`scenes/giao_dien/man_dau_game.tscn`,
cũng là `run/main_scene`), không còn rơi thẳng vào phòng thử.

| Nút | Làm gì |
|---|---|
| Chơi tiếp | nạp ô mới nhất, kể cả ô tự lưu. TỐI khi chưa có save nào |
| Chơi mới | `LuuGame.choi_moi()` — quên sạch rồi vào **vùng đầu chuỗi** (`thi_tran`) |
| Tải ván | từng ô kèm thời gian, giờ chơi, tên vùng. Tên vùng đọc từ `vung.csv` |
| Tuỳ chọn · Điều khiển | **dùng lại nguyên** hai trang của menu tạm dừng |
| Thoát | thoát, **không** tự lưu |

Ba quyết định đáng nhớ:

- **`man_dau_game.gd` kế thừa `man_cai_dat.gd`** chứ không chép. Hai trang con
  kia là 130 dòng có tầng chờ, nút Áp dụng sáng/tối và bảng gán phím; chép sang
  là từ đó mỗi lần thêm một tuỳ chọn phải nhớ sửa hai chỗ, mà quên sửa thì
  **không test nào bắt được** vì cả hai bản đều chạy. Lớp cha mở ba cửa cho
  việc đó: `ten_nhom()`, `ten_trang_chinh()`, `ManChung.dong_chan()`.
- **Màn này không đóng được** (`dong()` rỗng). Đóng ra thì phía sau là một cảnh
  trống trơn và người chơi nhìn vào màn hình đen. Chặn ở `dong()` chứ không chỉ
  chặn phím Esc, để mọi đường gọi tới đều chịu chung một luật.
- **`tu_luu()` từ chối khi không có người chơi trong cảnh.** Đây là cái bẫy
  thật của màn đầu game: bấm "Thoát" ở đó mà cũng tự lưu thì file save ghi
  `canh` = cái menu và `nguoi_choi` rỗng — lần sau bấm "Chơi tiếp" là nạp lại
  đúng cái menu ấy, ván chơi thật biến mất. Ghi đè im lặng một file save là thứ
  không sửa lại được.

**Ván mới bắt đầu tay không**, và đó là câu còn để ngỏ — xem mục "Việc tiếp
theo" phía trên.

### Giao diện
- **Bộ asset** chép vào `assets/ui/` (12 MB PNG) và `assets/font/` (1.5 MB).
  File `.psd` gốc 377 MB **không** đưa vào repo.
- **HUD**: giữa dưới là một CỤM LIỀN — cầu đỏ (máu) · thanh kỹ năng 10 ô ·
  cầu xanh (MP), cùng một tâm ngang, **thanh thể lực ngay trên thanh kỹ năng**.
  Khung nhân vật góc trái trên, minimap góc phải trên, **thanh máu boss ở ĐỈNH
  màn hình, giữa, rộng 44% bề ngang**.
- **Quả cầu kẹp hai đầu thanh kỹ năng, không ở góc màn hình.** Bản đầu ném
  chúng ra hai góc; chủ dự án chỉ lại bản mẫu. Cụm liền nằm đúng chỗ mắt đã
  phải nhìn để chọn ô kỹ năng, nên đọc máu không phải rời mắt khỏi con quái —
  trong một game né-đòn thì đó là cái giá thật. Không có con số trong cầu, mức
  nước chính là số liệu.
- **Cụm dưới canh theo MỘT TÂM CHUNG**, và ảnh nền cao bằng quả cầu.
  Chuyện này sửa ba lượt mới đúng, đáng ghi lại cả ba:
  1. canh theo TÂM quả cầu ⇒ cầu cao hơn hàng ô nên nó đẩy hàng ô lên, hàng ô
     treo lơ lửng cách đáy gần trăm pixel;
  2. canh theo ĐÁY ⇒ đo ra thì ba thứ chung một đáy thật, mà nhìn vẫn sai —
     cầu cao gấp ba hàng ô nên dồn hết lên trên, đọc ra như hai quả bóng treo
     cạnh một cái thanh thấp;
  3. **kéo ảnh nền cao bằng quả cầu và cho cả ba chung một tâm** ⇒ đúng.

  Bài học: **"khớp toạ độ" không phải là "nhìn ra một khối".** Lượt 2 đo bằng
  code thì hoàn hảo — cả ba cột đều kết thúc ở đúng một dòng pixel — và vẫn
  sai, vì thứ mắt đọc là KHỐI chứ không phải mép dưới. Chỉ có cắt ảnh ra phóng
  to mới thấy.
- **Minimap bán kính 215 là PIXEL CỐ ĐỊNH**, không co theo cỡ cửa sổ. Ở màn
  hình rộng 2000px thì vừa mắt; ở 1280×720 thì vẫn ngần ấy pixel, tức là gần
  sáu phần mười chiều cao. Chơi cửa sổ nhỏ mà thấy bản đồ nuốt góc màn hình thì
  đó là chỗ sửa — chưa ai gặp vì máy chủ dự án chạy màn rộng.
- **Thanh máu boss chuyển từ đáy lên đỉnh.** Souls để nó sát đáy, và bản này
  từng làm vậy — nhưng đáy giờ là cụm cầu–thanh–cầu, nên mỗi lần nới bán kính
  quả cầu là thanh boss lại cắt ngang đỉnh hai quả cầu. Đưa lên đỉnh gỡ hẳn
  ràng buộc đó: hai cụm thôi tranh chỗ, đổi cỡ cụm dưới không đụng gì tới thanh
  boss. Rộng 44% bề ngang — đủ dài để đọc ra mình vừa ăn được bao nhiêu, chưa
  dài tới mức một nhát chém trông như không ăn thua (boss nào cũng vài trăm máu).
- **Thanh thể lực trước đây không ai thấy**: nó nằm chồng dưới thanh máu ở góc
  trái trên, mà mắt người chơi souls bám giữa màn hình và bám con quái, không
  bám góc trái. Đưa xuống giữa dưới là đưa vào đúng chỗ mắt đã nhìn sẵn.
- **Minimap** quét theo NHÓM trong cây scene, không đọc địa hình — nên chạy y
  hệt ở phòng thử lẫn bảy vùng thật, không phải nối vào `VungDat`.
- **Menu tạm dừng** (Esc): Tiếp tục / Tuỳ chọn / Điều khiển / Thoát. Bỏ nút
  LOGOUT của bản mẫu — game chơi một mình, không có tài khoản để đăng xuất.
  Trang **Điều khiển** đọc tên phím thẳng từ `InputMap`, nên đổi phím trong
  `project.godot` là bảng đó tự đúng.
- **Tuỳ chọn** ghi `user://cai_dat.json` NGAY mỗi lần đổi, tách khỏi file save
  của ván chơi — xoá save chơi lại không phải chỉnh lại âm lượng.
- **MP thành thật.** 心 (trần) và 智 (sức mạnh phép) đã khai trong
  `Tui.TEN_CHI_SO` từ đầu và màn bia đá đã cho nâng, nhưng không gì tiêu, không
  gì hồi, không màn nào hiện — thanh MP đứng yên ở mức đầy suốt cả game. Giờ có
  hồi, có `NguoiChoi.tieu_mp()`, có quả cầu. **Chưa có phép nào tiêu nó** — đó
  cố ý là cái khung trống cho đợt sau.
- **Font là một CHUỖI.** Không font nào trong bộ asset có chữ Hán; font chính
  (Cambria) gắn `SystemFont` chữ Hán làm dự phòng. Trước đợt này mọi Label
  trong game dùng font mặc định của Godot, vốn **không có chữ Hán** — nghĩa là
  chữ Hán ở các màn Label xưa nay vẫn là ô vuông.

### Kiểm tra
Bảy bước, GitHub Actions chạy cả bảy mỗi lần đẩy code (**691** phép thử tự động
cộng một lần chạy game thật) — lệnh đầy đủ ở `CLAUDE.md`, tóm tắt ở đây:

| Lệnh | Kiểm gì |
|---|---|
| `godot --headless --path . tools/do_nhip_don.tscn` | KHÔNG phải test — máy ĐO nhịp đòn từ clip, in ra mấy con số của `moveset.csv`. Chạy sau mỗi lần đổi file `.fbx` |
| `godot --headless --path . tools/kiem_tra.tscn` | tầng luật, 197 test trong một khung hình |
| `godot --headless --path . tools/thu_vong_lap.tscn` | vòng lặp souls + combat + GIAO DIỆN trong phòng thử thật, 379 test theo thời gian |
| `godot --headless --path . tools/thu_dau_game.tscn` | màn đầu game + ĐỔI CẢNH: Chơi mới / Chơi tiếp / Tải ván — 39 test. Bộ duy nhất GHI ĐĨA (cất save của người thật đi rồi trả lại) |
| `godot --headless --path . tools/thu_the_gioi.tscn` | thế giới + nội dung: địa hình, streaming, 7 vùng, vùng bị xoá, NPC/cốt truyện, âm thanh, boss 无, HÀNG CHỜ dựng ô — 76 test |
| `godot --headless --path . scenes/the_gioi/phong_thu.tscn --quit-after 600` | chạy cảnh chơi thật 10 giây, bắt lỗi lúc chạy mà bốn bộ trên không với tới (vòng tròn autoload chẳng hạn). Trỏ THẲNG vào phòng thử vì `main_scene` giờ là cái menu |
| `python tools/kiem_csv.py` | CSV, không cần Godot |
| `python tools/kiem_nhap.py` | đợt `--import` đã chạy TRỌN chưa — mọi file `.import` phải có đủ file đích. Không cần Godot. Có vì một đợt nhập đổ giữa chừng trông y hệt một đợt nhập xong |

Mỗi bộ sinh ra vì bộ trước không với tới: tầng luật chạy trong một khung hình
và không nạp cảnh nào; `thu_vong_lap` nạp được một cảnh nhưng bị buộc vào đúng
cảnh đó; `thu_dau_game` là bộ duy nhất ĐỔI CẢNH được, thứ mà trạng thái nằm
trong autoload nên nó sống qua cú đổi ấy.

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
| Chặn đỡ (guard boost) | khiên tốt thì đỡ đỡ tốn thể lực | `_chi_so_chan_do()` |
| Đòn nhảy | moveset riêng, phá thế rất mạnh, một đòn mỗi lần rời đất | `nhay` / `nhay_nang` trong `moveset.csv`, `con_don_tren_khong()` |

### Cố ý KHÁC, và vì sao

- **Parry KHÔNG cần khiên.** ER cấm hẳn parry tay không (phải có khiên nhỏ/vừa
  hoặc Ash of War "Parry"); chủ dự án chốt cho parry tay không được. Cái mất:
  khe tay trái yếu đi một lý do tồn tại. Cái còn giữ cho khiên đáng cầm —
  chặn sát thương (40–95 so với 35 của tay không), chặn đỡ, và **đòn phản đỡ
  thì vẫn cần khiên**. Nếu sau này thấy tay không parry mạnh quá thì chỗ siết
  là `cua_so_perfect` theo có khiên hay không, đừng cấm lại từ đầu.
- **Đỡ phản có HAI BẬC**, ER chỉ có một. `cua_so_perfect` (0.10s đầu của
  `cua_so_do_phan` 0.24s) là parry hoàn hảo: quái ngây `NGAY_SAU_PERFECT` 3.4s
  thay vì 2.2s, và hoàn lại trọn phần thể lực đã tiêu — đủ để parry liên tiếp
  cả một chuỗi đòn boss. Hai cửa sổ **lồng nhau** chứ không tách rời, nên bấm
  sớm quá vẫn rơi vào parry thường: tập bấm sớm không bị phạt, người chơi tiến
  lên bằng cách siết dần thời điểm chứ không bằng cách đánh cược.
  `an_don()` trả -2 cho hoàn hảo, -1 cho thường.
- **CHUỘT PHẢI gánh cả đỡ lẫn đỡ phản — một nút, kiểu Sekiro chứ không phải
  ER.** ER tách hẳn: giữ L1 là đỡ, gõ L2 là parry, hai nút hai tay. Chủ dự án
  chốt gộp vào một, và nhận luôn cái đi kèm: parry HỤT mà còn giữ nút thì
  khiên lên NGAY, không qua khung ngây `hoi_do_phan` (0.45s).
  Nghe thì như bỏ mất hình phạt của parry hụt, nhưng không: hình phạt chỉ
  ĐỔI HÌNH, và chỗ thi hành nằm ở `an_don()` — đỡ chỉ chặn được khi tay trái
  CÓ khiên, mà vũ khí hai tay (刃, đúng cây khởi đầu) làm
  `Tui.tay_trai_dang_cam()` trả null. Ai cầm hai tay mà parry hụt rồi giữ
  tiếp thì đứng đó ăn gần trọn đòn và mất thêm thể lực — nặng ngang, có khi
  hơn, đứng ngây. Còn ai có khiên thì đúng là mua được cái mượt ấy bằng một
  khe tay trái.
  Chỗ phân xử "bấm mới" với "giữ sẵn" là THỨ TỰ trong `thu_hanh_dong()`, không
  phải một cái cờ: cú bấm mới bị `lay_dem("do_phan")` bắt ở bậc phòng thủ, nên
  xuống tới bậc cuối (`is_action_pressed`) thì chỉ còn ngón tay đã giữ từ
  trước — và ngón tay giữ sẵn không đáng được một cửa sổ parry.
  E và Q vì thế trống hẳn, action `do_don` bị xoá khỏi input map (state vẫn
  tên `do_don`, đừng lẫn).
- **Parry cắt được cả đòn đánh lẫn cú lăn**, và hai chỗ hai luật:
  đòn đánh chỉ cắt từ đoạn 4 (`cho_ne()`) — cam kết đòn không bị nới; cú lăn
  cắt được ở bất cứ đoạn nào, kể cả giữa i-frame. Vế sau là chủ dự án chốt:
  cắt sớm là tự bỏ phần bất tử còn lại để đổi lấy cửa sổ parry, một quyết định
  có giá chứ không phải lỗ hổng, và `hoi_lan` đặt ở `vao()` nên cắt giữa chừng
  vẫn không cho lăn lại sớm hơn.
- **Space gánh lăn + nhảy, Shift gánh chạy.** ER trên PC gộp lăn/chạy vào một
  nút và để nhảy riêng; ở đây gộp lăn/nhảy và tách chạy ra. Phân biệt bằng
  **số lần bấm**, không bằng thời gian giữ: bấm hai lần trong
  `NGUONG_BAM_DOI` (0.22s) là LĂN, bấm một lần là NHẢY.
  Cái giá vì thế rơi vào nhảy chứ không vào lăn — lăn nổ ngay ở cú bấm thứ
  hai, còn nhảy phải đợi hết cửa sổ mới biết người chơi có bấm tiếp không.
  Đặt cái giá ở đó là cố ý: lăn là thứ cứu mạng, nhảy thì không. Nhảy vốn để
  né đòn quét ngang của boss, nên nếu tune thấy vướng thì đây là con số đầu
  tiên phải đụng tới.
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

## Mốc 7 — làm được tới đâu

**Xong:**

- **NPC + cốt truyện** (`npc.csv`, 7 NPC, mỗi vùng một). Thoại tiếng Trung hiện
  theo luật ???; **bản dịch chỉ lộ khi đã đọc được ≥60% câu**. Chưa hiểu thì
  màn thoại nói rõ THIẾU CHỮ NÀO — người chơi ra về với một việc cụ thể, không
  phải một lời từ chối. Đây là mục 13 được thi hành: phần thưởng của việc học
  là hiểu được cốt truyện.
- **Âm thanh** — 15 tiếng tổng hợp bằng code. **ĐÃ XOÁ ở đợt dọn giao diện**,
  xem mục dưới.
- **18 loài quái** (mục 12). Thêm 5 loài, vùng nào cũng có quái.
- **Boss ẩn 无** (mục 14.8) — không hành nên ngũ hành vô dụng, và **vũ khí càng
  nhiều chữ khắc càng yếu** trước nó. Đo được: cây trần ăn trọn 100, cây khắc
  ba chữ còn 17. Cả game dạy "thêm chữ là mạnh thêm"; con cuối đảo ngược đúng
  câu đó, và chỉ ai HIỂU cơ chế mới giải được. Nhận ra nó bằng cột `ngu_hanh`
  trống chứ không bằng mã — luật 1.
- **Từ vựng 1011 → 1040 chữ.** Thêm 29 chữ, phần lớn là hư từ ngữ pháp cần cho
  thoại (是 不 有 这 那 们 的 了 在 什 么 吗...). Kèm theo sửa một lỗi dữ liệu:
  `无` và `毒` được dùng ở `boss.csv` và `vung.csv` mà **không có trong
  `tu_vung.csv`** — nghĩa là tên boss cuối và tên vùng Đầm lầy không bao giờ
  đọc được, dù người chơi học hết mọi chữ trong game.

**KHÔNG làm được, và vì sao:**

- **Animation thật.** Cần file `.glb` với skeleton humanoid (mục 11). Repo
  chưa có model nào — nhân vật và quái vẫn là khối hộp sinh trong code. Đây là
  việc cần người làm art, không phải việc thiếu code. Phần hoạt ảnh tạm trong
  `than_khoi.gd` đã tách riêng từng loại đòn nên thay bằng `AnimationPlayer`
  không phải viết lại luật nào.
- **Âm thanh thu thật / lồng tiếng.** Cùng lý do.
- **Thiết kế màn bằng tay** (đường tắt, mai phục, vòng lặp). Mục 7.1 của bản
  yêu cầu nói thẳng là AI làm dở việc này. `VungDat.CHOT_BIA` và `CHOT_BOSS`
  cố tình để là một bảng toạ độ thưa, dễ sửa tay.

## Menu tạm dừng: xác nhận trước khi áp

Bản đầu áp mọi tuỳ chọn NGAY lúc kéo thanh trượt. Chủ dự án yêu cầu thêm nút
xác nhận, và yêu cầu đó đúng: chỉnh độ nhạy chuột thì phải kéo qua kéo lại mới
tìm được con số đúng, mà áp ngay thì mỗi nhích giữa chừng là một lần ghi đĩa và
một lần đổi cảm giác — người chơi mất luôn cái mốc cũ để so.

`CaiDat` vì thế có **hai tầng**: `_gt` (đang áp dụng, game đọc tầng này) và
`_nhap` (đang chờ xác nhận, chỉ màn Tuỳ chọn đọc). Nút **Áp dụng** TỐI khi
`co_thay_doi()` false và SÁNG khi true — nó vừa là nút bấm vừa là câu trả lời
cho "mình đã đổi gì chưa". Rời trang là vứt tầng chờ.

**Trang Điều khiển thành gán lại phím được.** Không có nó thì nút Áp dụng ở
trang đó là đồ trang trí, mà nút bấm vào không ra gì thì tệ hơn là không có nút
— đúng lý do đã bỏ LOGOUT của bản mẫu. Bấm một hàng phím là vào chế độ bắt phím,
Esc để bỏ. Hai điều cố ý:

- **Esc không gán được.** Nó là đường thoát; gán nhầm một lần là mất luôn cách
  mở menu để sửa lại.
- **Override thay CHỖ ĐẦU, giữ nguyên phím thay thế.** `khoa_muc_tieu` có cả
  chuột giữa lẫn Tab; đổi cái đầu mà xoá luôn cái sau là lấy mất thứ người
  chơi không hề yêu cầu. (Phép thử này từng canh trên `do_phan` vì nó có cả E
  lẫn chuột phải — từ khi đỡ và đỡ phản gộp vào một nút thì `do_phan` chỉ còn
  một phím, nên phép thử dọn sang action khác chứ không bỏ đi.) Cài được nhờ `_phim_goc` — bản chụp sự kiện gốc của mọi action lúc
  khởi động. Không có nó thì "về mặc định" không dựng lại được gì, vì InputMap
  lúc ấy đã bị ghi đè mất rồi.

Hàng gộp nhiều action ("Đi" = bốn phím) chỉ để xem: gán một phím cho cả bốn
hướng là vô nghĩa, và cho gán thì lại phải giải thích vì sao nó không ăn.

## Âm thanh: đã xoá, cố ý

Mốc 7 tổng hợp 15 tiếng bằng code lúc khởi động — lý do lúc đó là mục 14.6:
game thiếu HẲN chiều nghe, mà thiếu hẳn thì tệ hơn là có mà chưa hay.

**Chủ dự án chơi thử và bác bỏ đúng cái tiền đề đó**: tiếng tổng hợp chói và ồn
tới mức nghe nhức đầu, nên im lặng tốt hơn. Phần tổng hợp đã bị xoá sạch —
đừng chép lại.

Cái giữ lại, và vì sao:

| Giữ | Vì sao |
|---|---|
| `AmThanh.TIENG` — 15 tên kèm mô tả | chính là danh sách việc cho người thu âm. Xoá đi là mất thông tin "game cần những tiếng nào", chỉ moi lại được bằng cách đọc 18 chỗ gọi |
| 18 chỗ gọi `AmThanh.phat()` | đánh dấu ĐÚNG khoảnh khắc mỗi tiếng phải vang. Thông tin đó đắt hơn code phát tiếng nhiều |
| kênh phát, `cao`/`to`, âm lượng trong Tuỳ chọn | nguyên vẹn, chờ file thật |

**Thêm tiếng thật**: thả file vào `assets/tieng/<tên>.wav` (hoặc `.ogg`/`.mp3`),
tên khớp khoá trong `TIENG`. Khởi động là nó tự nạp và tự phát — không sửa một
dòng code nào. Thiếu file thì im, không nổ và không cảnh báo.

Nhóm test "Âm thanh" vì thế KHÔNG canh "có phát ra tiếng" nữa; nó canh ba thứ
phải đúng để việc thả file kia chạy được: bản kê còn nguyên và tên nào cũng có
mô tả, `phat()` không bao giờ nổ, và đếm được bao nhiêu tiếng thật đã có.

## Model nhân vật: đã có

> **Đã thay lần hai.** Model elf dưới đây là bản đầu; bản đang chạy là
> `nhan_vat_chinh.fbx` (rig Mixamo) — xem mục "Model mới + 43 clip động tác" ở
> cuối trang. Giữ lại đoạn này vì ba bài học về rig thì không đổi.

Người chơi từng là một **elf nữ thật** (`assets/model/_elf_commoner_2.fbx`),
không còn là khối hộp. Bộ model có 14 con elf; chọn con này vì nó mặc đồ đi lại
được — mấy con `upper_class` mặc váy dài, mà váy dài thì lăn và vung kiếm trông
phi lý.

Ba thứ đo được TRƯỚC khi chọn, bằng `tools/soi_model.tscn`:

| | |
|---|---|
| xương | **41 khớp**, tên kiểu Unreal (`Pelvis` / `Spine_01..03` / `Upperarm_L` / `Calf_R`…) |
| animation | **KHÔNG CÓ CON NÀO** |
| cao / gốc | 1.66–1.82m, gốc toạ độ **dưới chân** — khớp luật của repo |

Không có animation nghĩa là **vẫn phải xoay xương bằng tay**. `than_mo_hinh.gd`
làm đúng việc `than_khoi.gd` từng làm, chỉ khác là xoay xương thật nên ra hình
người. `NguoiChoi._dien_hinh()` giờ hỏi thân theo HÀM `dien()` chứ không ép kiểu
`ThanKhoi`, nên hai thân thay nhau được mà không sửa gì.

Ba thứ **không đoán được, phải đo hoặc phải nhìn**:

- **Texture.** Vật liệu trong FBX trỏ tới đường dẫn không còn tồn tại nên 9/14
  model nạp lên đen thui. Cả bộ dùng chung một atlas 64×64; ép thẳng vào là xong.
- **Chiều xoay của xương vai.** Hai vai đối xứng gương nhau, nên cùng một góc
  hạ tay bên này mà GIƠ bên kia. Bản đầu tay phải chỉ thẳng lên trời suốt mọi
  tư thế. Chỗ sửa: `DAU_TAY_PHAI`.
- **Trục của xương bàn tay.** Đo ra: trục Y của khớp trỏ RA SAU LƯNG, nên hướng
  ra trước là −Y, và kiếm/khiên phải xoay +90° quanh X. Đo bằng cách in
  `global_transform.basis` của `BoneAttachment3D`; đoán thì ba lượt vẫn sai.

**Trục xoay cả thân phải ở HÔNG, không ở bàn chân.** Gốc model nằm dưới chân nên
xoay thẳng nó là cú lăn hất cả người văng ra xa cả mét rồi mất hút khỏi khung
hình. Node `_truc` ở 0.52 chiều cao lo việc đó.

**Một bug mà chỉ bộ kiểm tra thấy.** Cuối hàm dáng đánh có một lời gọi
`_tay_buong()` để vung tay trái cho cân — nhưng hàm đó đặt CẢ HAI tay, nên nó
kéo tay phải về tư thế buông và xoá sạch cú chém vừa vẽ ngay dòng trên. Mắt chỉ
thấy "hơi giật lúc nhả nạp"; test đo góc thì thấy cánh tay **nhảy 41°** và báo
đỏ. Đúng loại lỗi mà nhóm test "Phần nhìn" sinh ra để bắt.

### Vũ khí: kiếm hai tay 刃

Người chơi cầm **kiếm hai tay** (`_sword_23.fbx`), moveset riêng dưới chữ **刃**
(nhận — lưỡi). Chữ này mới thêm vào `tu_vung.csv`; chọn nó vì nó là DANH TỪ vũ
khí thật, nên tên món đồ đọc ra vẫn đúng ngữ pháp (火刃 = Hoả Nhận).

Ba việc, đều nằm ở CSV chứ không ở code:

| Muốn | Sửa |
|---|---|
| hình vũ khí | cột `mo_hinh` của `nguyen_lieu.csv` (tên file trong `assets/model/vu_khi/`) |
| hai tay hay một tay | cột `hai_tay` |
| nhanh chậm, mạnh yếu | 9 dòng 刃 trong `moveset.csv` |

**Đây là lúc trả món nợ `HINH_VU_KHI`.** Bảng gán cứng năm chữ trong
`than_khoi.gd` đã ghi nợ ở đây từ lâu ("thêm loại vũ khí mới vào CSV thì nó hiện
nhầm hình kiếm"). Giờ hình đọc từ CSV; bảng cũ chỉ còn làm khối hộp dự phòng cho
vũ khí chưa có model.

**Cầm hai tay = không có khiên.** `Tui.tay_trai_dang_cam()` trả null dù khe tay
trái có đồ. Mất parry bằng khiên, mất đòn phản đỡ, mất chỉ số chặn — đó là cái
giá, và thi hành ở MỘT chỗ nên không bên gọi nào quên được.

**Chậm hơn, mạnh hơn — nhưng có trần.** Bản đầu để `cong` 14 và `he_so` 2.30:
một nhát nhẹ HẠ GỌN một con quái thường. Bộ kiểm tra bắt ngay (ngưỡng 2–14 nhát
kiểu Elden Ring), và nó đúng — một nhát một mạng thì không còn trận đánh nào.
Hạ về `cong` 11 / `he_so` 1.75: mỗi nhát đau hơn 斧 chừng một phần tư, mà vung
chậm hơn hẳn, nên DPS thấp hơn. Đó mới là "vũ khí nặng".
Khung hồi đòn nặng cũng phải kéo về 1.15s — mục 5.2 chốt 0.45–1.2s và có test canh.

**Bộ kiểm tra phải GHIM vũ khí.** Đổi vũ khí khởi đầu của phòng thử làm tám phép
thử đỏ cùng lúc, mà không phép nào sai — chúng chỉ đang đo một cây kiếm khác.
Giờ có `_dat_vu_khi()` và mọi phép thử đo NHỊP đều ghim về 剑 trước.
Cạm bẫy trong đó: `mac_vao()` không truyền ô thì nhét vào khe TRỐNG đầu tiên,
nên vũ khí mới rơi xuống ô 1 trong khi tay vẫn cầm ô 0. Ghim mà không đổi tay
là không ghim gì cả.

### Cất / rút vũ khí (phím R)

Chủ dự án yêu cầu thêm, kiểu Elden Ring, **một động tác cho mọi vũ khí**.

Làm nó thành cơ chế thật chứ không phải hai cái animation, vì cất kiếm phải
ĐƯỢC cái gì đó — không thì không ai bấm, và nó thành nút trang trí đúng loại đã
bị bỏ đi ở màn tạm dừng.

| | |
|---|---|
| được | chạy nhanh hơn ×1.30, chạy tốn thể lực ×0.55 |
| giá | **không đánh được**; bấm đánh là tự rút ra trước, mất 0.55s |

Hai phần thưởng chứ không một, và chúng **nhân vào nhau**: nhanh hơn 30% mà vẫn
hết hơi sau đúng ngần ấy giây thì quãng đường chỉ nhích chút ít. Có cả hai thì
một hơi chạy dài gần gấp đôi — **đo thật: 5.42s so với 2.93s**. Lúc đó mới đáng
bấm R trước khi băng qua một vùng.

Ba điều cố ý:

- **Bấm đánh lúc đang cất thì TỰ RÚT**, và cú bấm nằm chờ trong bộ đệm để nổ
  ngay khi rút xong. Bắt người chơi bấm R rồi mới bấm đánh là một bước thừa mà
  họ sẽ chửi — và họ đúng.
- **Hai state có CAM KẾT**: lăn không cắt được. Cho huỷ giữa chừng thì cất kiếm
  hết rủi ro, mà hết rủi ro thì phần thưởng thành miễn phí.
- **Vũ khí chuyển ra sau LƯNG**, không phải ẩn đi. Ẩn thì thanh kiếm biến mất
  giữa không khí và người chơi đọc ra là lỗi, không phải "đã cất".

Cần thêm hai file động tác: `rut_vu_khi.fbx` và `cat_vu_khi.fbx`. Thiếu thì
vẫn chạy, chỉ là không có dáng riêng.

**Một bẫy trong chính bộ kiểm tra.** Phép thử "một hơi chạy được bao xa" lúc
đầu đo QUÃNG ĐƯỜNG và ra 32.5m cho cả hai lượt — vì nhân vật đâm vào rìa phòng
thử chứ không phải vì hết thể lực. Phép đo phụ thuộc cỡ căn phòng thì nó đang
đo căn phòng, không đo cơ chế. Đổi sang đo THỜI GIAN thì đúng ngay.
Kèm theo: quên trả nhân vật về chỗ cũ sau khi chạy 30m làm **bốn phép thử sau
đó đánh vào khoảng không** — phép thử nào xê dịch nhân vật thì phải dọn sau mình.

### Dáng nhân vật: gõ tay là hết trần, cần animation thật

Chủ dự án xem và nói thẳng: nhìn cứng và ngược. Đúng, và đây là lý do kỹ thuật
chứ không phải tune chưa tới:

1. **Bàn chân trượt trên đất** — chân đung đưa theo `sin()` mà không bám mặt
   đất. Đây là tín hiệu "sai" mạnh nhất mắt người bắt được.
2. **Hông đứng chết** — người đi thật thì xương chậu nhấp nhô và xoay mỗi bước.
3. **Chỉ 14 khớp, gần như mỗi khớp một trục.** Animation thật xoay 20–30 khớp
   trên cả ba trục.
4. **Mọi chuyển tiếp cùng một kiểu giảm tốc** — không lấy đà, không đà thừa,
   không độ trễ giữa các bộ phận.
5. **Vòng kiểm là ẢNH TĨNH.** Agent gõ góc rồi nhìn một khung đông cứng mà
   đoán. Một dáng đi sai nhịp thì từng khung vẫn có thể trông ổn.

Điểm 5 đáng nhớ nhất: **thứ gì chỉ sai khi CHUYỂN ĐỘNG thì ảnh tĩnh không bắt
được**, y như chuyện bố cục HUD chỉ sai khi nhìn tổng thể.

Nên đã dựng sẵn **đường nạp animation thật**: thả `.fbx` vào
`assets/model/dong_tac/` với tên theo bảng, trạng thái nào có file thì
`AnimationPlayer` giành quyền, thiếu thì quay về dáng gõ tay. Hướng dẫn đầy đủ
ở `assets/model/dong_tac/DOC_TRUOC.md`.

**Việc này CẦN NGƯỜI**: Mixamo đòi tài khoản Adobe, agent không đăng nhập được.
Chủ dự án đã tải về, và mục dưới là chuyện lắp chúng vào.

## Model mới + 43 clip động tác

Nhân vật giờ là `assets/model/nhan_vat_chinh.fbx` (rig Mixamo, 58 xương, da
`katz.jpg`), và **mọi dáng đều là animation thật** trừ một cái còn thiếu
(`uong`). Bảng gán clip nào cho trạng thái nào, kèm lý do từng cái, ở
`assets/model/dong_tac/DOC_TRUOC.md`.

### Hai bộ clip, vì phím R phải nhìn thấy được

Cất kiếm rồi mà vẫn chạy bằng dáng ôm kiếm hai tay thì phần thưởng của phím R
không có mặt nào để đọc — thanh thể lực tụt chậm hơn, nhưng không ai nhìn thanh
thể lực lúc đang chạy. Nên có hai bộ: cầm kiếm ở `dong_tac/`, tay không ở
`dong_tac/khong_vu_khi/`, và `_co()` chọn bộ theo `da_rut`. Thiếu clip nào ở bộ
tay không thì tự mượn bộ cầm kiếm, nên bộ đó không cần đủ.

### Năm thứ hỏng IM LẶNG, và cách bắt được chúng

Không cái nào trong năm cái này làm test đỏ. Bốn cái đầu bắt được bằng máy đo,
cái thứ năm bắt được bằng mắt.

| Hỏng | Triệu chứng | Đo bằng |
|---|---|---|
| Tên xương có dấu **hai chấm** | Godot đổi `mixamorig:Hips` thành `mixamorig_Hips` lúc nhập. Tìm theo tên cũ thì `find_bone()` trả −1 cho MỌI xương, mỗi xương một `push_warning` rồi thôi — nhân vật đứng nguyên tư thế chữ T trượt quanh map | in tên xương ra |
| Đường dẫn rãnh | Rãnh Mixamo ghi theo cây của CHÍNH file đó (`Armature/Skeleton3D:...`). Sai gốc thì Godot in "couldn't resolve track" rồi phát clip RỖNG — nhìn ra ngoài y hệt cảnh chưa có file nào | `_sua_duong()` |
| **Chiều cao đo bằng mesh** | Mesh có skin thì hộp bao của nó vô nghĩa: model này ra **7,6mm**. Phóng cho "vừa 1.8m" từ số đó là nhân nhân vật lên **236 lần** | `_cao_mo_hinh()` đo bằng XƯƠNG, bỏ xương lá tên `_end` |
| **"In Place" chưa tick** | `chay` tự đi 1.86m một vòng, cộng với `move_and_slide()` là chạy gần gấp đôi luật và trượt như đi trên băng. Test vẫn xanh vì nó đo `velocity` của thân vật lý, thứ không đổi | `_khu_troi()` trừ đường thẳng đầu→cuối, giữ nguyên trục Y |
| Kiếm dài 1.55m | Nhân vật mới là kiểu chibi: cao 1.8m nhưng bàn tay lúc buông chỉ ở 1.04m. Nửa mét lưỡi cắm xuyên sàn | ảnh `tools/chup_tu_the.tscn` |

### Máy đo lại chính nó cũng sai

Lượt đo "In Place" đầu tiên báo **mọi clip đều 0.00m** — tức là đã tick sẵn.
Sai: hằng tên xương trong máy đo vẫn còn dấu hai chấm, nên nó không tìm thấy
rãnh hông và trả về 0 cho tất cả. Một máy đo không tìm thấy thứ cần đo trông y
hệt một máy đo báo "không có vấn đề gì".

Sửa rồi đo lại thì ra `chay` 1.86m, `di` 1.07m, strafe tới 1.42m — ngược hẳn
kết luận cũ. **Số 0 đẹp quá thì phải hỏi lại xem phép đo có chạm được vào thứ
nó đo không.**

### Tên file nói SAI ba lần

Chọn clip theo số đo, không theo tên. Đo hướng trôi của hông thì ra:

- `great sword run` là chạy **LÙI**; bản chạy tới là `great sword run (2)`
- `great sword walk (2)` là đi **LÙI** — tưởng thừa, hoá ra đúng thứ đang thiếu
- `great sword slash (5)` là chém lúc **ĐANG KHOM** (hông 0.33m thay vì 0.67m)

Tin tên file thì nhân vật chạy tới trước bằng dáng chạy giật lùi, và một nhát
trong combo ba nhát thì thụp xuống đất.

### Góc cầm kiếm: đo được, không phải dò

Ghi chú cũ bảo bốn con số nhóm "Cầm trên tay" phải chỉnh bằng mắt. Không đúng
nữa: **clip kiếm hai tay giữ CẢ HAI bàn tay trên chuôi** (đo được hai tay cách
nhau 13,7cm), nên vector tay phải → tay trái CHÍNH LÀ trục thanh kiếm. Đổi sang
hệ của khớp bàn tay phải thì ra `(-0.67, 0.38, 0.64)`, và đó là góc mặc định.

Vẫn để chỉnh tay được, vì phép đo không nói được VÒNG XOAY quanh chính trục ấy
— bề dẹt của lưỡi quay hướng nào thì vẫn phải nhìn.

Kèm một lỗi cũ: `_chuan_hoa_vu_khi()` ghim cứng `rotation_degrees = (180,0,0)`,
nên `vu_khi_xoay` chỉ ăn vào khối hộp dự phòng còn model thật thì mặc kệ. Chỉnh
mỏi tay trong editor mà thanh kiếm không nhúc nhích một độ nào.

### Một phép thử phải đổi ngôn ngữ

Phép thử "nạp đòn không được vung hụt một nhát trước" canh bằng **góc tay**. Có
clip thật thì `dien()` nhường hẳn cho `AnimationPlayer` và không xoay xương nữa
— góc tay đứng im, phép thử đỏ, dù game đúng hơn trước.

Sửa bằng cách hỏi cùng một câu bằng thứ tiếng mà phần nhìn đang nói: thêm cửa
`dong_tac_dang_phat()`, và suốt cú nạp thì clip đang chạy phải là `nap`, không
được là clip vung nào. Còn không có clip thì vẫn đo góc tay như cũ.

### Clip chết dài quá thì người chơi biến mất lúc đang rơi

`TrangThaiChet.T_CHO = 2.8` — đúng giây đó nhân vật bị bốc về bia đá. Lượt gán
đầu tôi chọn `Death1` cho bộ tay không vì nó dài hơn (3.90s), tưởng là đầy đặn
hơn. Đo độ cao hông ở đúng giây 2.8 thì hông vẫn ở **0.35m**: cái xác còn đang
đổ xuống thì màn hình đã cắt. Đổi sang `Dying2` (2.60s, xong ở 0.10m).

Bài học rộng hơn: **"dự phòng" và "thừa" là hai thứ khác nhau**, và tôi đã gộp
chúng vào một ô trong bảng. `Dying2` không thừa — nó là bản ĐÚNG. Ràng buộc này
nằm giữa một hằng số trong code và độ dài một file `.fbx`, không có chỗ nào ghi
nó và không công cụ nào tự bắt được.

### Còn thiếu một clip — `uong` (uống bình)

**`lan` (lăn né) đã có** (Sprinting Forward Roll, 1.17s) — đoạn "còn thiếu hai
clip" của bản trước đã lỗi thời, xoá đi. Chỉ còn `uong` đang dùng dáng gõ tay.
Tìm chữ "Drinking" trên Mixamo.

**Đòn nặng đã đúng là Bổ** — xem mục "Đợt sửa lớn" phía dưới ("Chủ dự án chỉ
đúng clip"): đổi sang `great sword casting`, đo ra tay đi dọc 1.27m, cú bổ thật
chứ không còn là cú xoay.

### Còn dở

- **Khiên chưa có model** — vẫn là khối hộp. Chủ dự án chốt tạm bỏ qua vì
  vũ khí hiện tại cầm hai tay nên không dùng khiên. Bộ asset ngoài repo có
  sẵn 20 cái khiên, cùng thư mục với đám kiếm.
- **Quái vẫn là khối hộp.** Bộ model elf cũ còn nguyên 14 con dùng được, giờ
  không còn chỗ nào trỏ tới.

  (Hai bullet cũ ở đây — "bề dẹt lưỡi kiếm chưa canh" và "kiếm lúc cất chưa
  chéo qua vai" — đã xoá vì đã fix: xem `vu_khi_lan` = 90°, `vu_khi_lech_lung`
  / `vu_khi_xoay_lung` đã có số thật, ở mục "Kiếm cầm sai" phía dưới.)

## Đợt sửa lớn: điều khiển, combat, save

Chủ dự án liệt kê chín việc sau khi chơi thử bản có model thật. Ghi lại ở đây
những chỗ mà **đọc code không ra, phải đo mới thấy**.

### Lăn ngược 180°: không phải lỗi hướng, là backstep tự mâu thuẫn

Đọc code thì mọi thứ tự nhất quán — `xoay_ve()` và `lan.gd` cùng dùng
`atan2(h.x, h.z)`. Đo bằng `tools/soi_lan.tscn` mới ra: lăn CÓ bấm phím lệch
hướng mặt 0–1°, lăn ĐỨNG YÊN lệch đúng 180°.

Thủ phạm là hai dòng cạnh nhau tự cãi nhau: `_huong = -huong_mat()` (định làm
backstep kiểu souls) rồi ngay dưới lại xoay cả người VỀ hướng đó. Cái ra được
không phải backstep mà là **quay ngoắt 180° rồi lăn tới**. Backstep thật đòi
giữ nguyên hướng mặt, tức là một dáng riêng — chưa có thì lăn tới là thứ đọc ra
đúng.

### Bàn chân trượt: hai con số, chỉnh một mình con nào cũng không hết

Đo ra đi bộ **4.45 m/s** trong khi clip `di` tự đi **0.84 m/s** — chậm hơn 5.3
lần. Dạt ngang còn tệ hơn: 5.6 lần, và đó đúng là hướng chủ dự án báo.

Sửa hai đầu:
- `_toc_theo_van_toc()` khớp tốc độ phát clip với vận tốc thật của thân vật lý.
- Gán lại `di` / `di_lui` / `di_trai` / `di_phai` sang các clip CHẠY, vì 4.45
  m/s vốn đã là tốc độ chạy chứ không phải đi bộ.

Kết quả: hệ số phát 1.33 (có kiếm) và 1.77 (tay không), không cái nào chạm trần
2.6. `he_so_phat()` công khai để phép thử canh đúng chuyện đó — đổi một file
`.fbx` sang clip chậm hơn là test đỏ trước khi ai kịp nhìn thấy trượt.

Ngưỡng chia hướng lúc khoá mục tiêu cũng sai: 0.5 (60°) làm tiến/lùi nuốt 120°
mỗi cái, nên đi chéo vẫn phát clip đi thẳng. Đổi về 0.70711 = bốn phần tư đều.

### Giật hình: quay màn hình lại thì không thấy

Chủ dự án chẩn đoán đúng. Camera bám nhân vật ở `_process` (nhịp màn hình) còn
`CharacterBody3D` chỉ đổi vị trí ở `_physics_process` (60 lần/giây). Hai nhịp
khác nhau ⇒ nhân vật giật so với khung hình.

Và đó là lý do bản quay màn hình sạch: nó lấy mẫu ở một nhịp khác, thường trùng
nhịp vật lý, nên nó "sửa" luôn cái giật trong lúc ghi. **Bằng chứng vắng mặt ở
bản ghi không phải bằng chứng không có lỗi.**

Chuyển camera sang `_physics_process` với `process_physics_priority = 10` (chạy
SAU `move_and_slide()` cùng tick), và nâng nhịp vật lý 60 → 120.

### Kiếm cầm sai: phép đo cho được trục, không cho được vòng xoay

Góc cầm đo từ vector tay phải → tay trái là ĐÚNG, nhưng nó chỉ nói thanh kiếm
nằm dọc theo hướng nào — không nói nó xoay bao nhiêu quanh chính hướng đó. Bề
dẹt của lưỡi quay ra trước thì thanh greatsword nhìn thành cái que.

Thêm `vu_khi_lan` (một con số, xoay quanh trục kiếm), quét 0/45/90/135° rồi
nhìn ảnh: 90° đúng. Cũng phát hiện `_chuan_hoa_vu_khi()` ghim cứng
`rotation_degrees = (180,0,0)`, nên `vu_khi_xoay` chỉ ăn vào khối hộp dự phòng
— chỉnh mỏi tay trong editor mà model thật không nhúc nhích một độ.

### Đòn "Bổ": chủ dự án chỉ đúng clip

Tôi chọn `slash (2)` (tay đi dọc 0.80m, thực chất là cú xoay 179°). Chủ dự án
chỉ sang `casting` — đo ra **1.27m dọc**, từ 1.37m trên đỉnh xuống 0.10m sát
đất. Cú bổ thật.

### Năm đoạn của một cú đánh

Mốc lấy từ `moveset.csv`, KHÔNG từ Call Method Track. Gắn mốc vào file `.fbx`
là chuyển cân bằng game sang cho một file animation giữ.

Đoạn 4 mở cửa sổ THỦ — lăn cắt ngang được. Cửa sổ NỐI mở TRƯỚC: mở cùng lúc thì
lăn luôn thắng combo vì nó an toàn hơn, và người chơi hết phải chọn.

Một phép thử của tôi đỏ vì lý do hay: cú lăn bị chặn ở đoạn 1 nằm lại trong
đệm rồi **nổ ra đúng lúc cửa sổ mở**. Đó là bộ đệm làm đúng việc; phép thử mới
là cái sai, vì nó bấm sớm hơn hạn dùng 0.35 giây của đệm.

### Combo "khựng": hai lỗi chồng nhau, cái thứ hai mới là chính

Chủ dự án báo: "đòn thứ nhất chưa hết là bấm tiếp đc rồi, hiện tại khựng quá".
Đo ra hai nguyên nhân độc lập, và cái thứ hai là cái tôi đã bỏ sót khi dựng
cửa sổ huỷ đòn lần trước.

**1. Cú bấm bị NUỐT.** Bộ đệm giữ 0.35 giây, nhưng code chỉ hỏi tới nó từ
`t_dam_den` trở đi. Với kiếm hai tay `t_dam_den` = 0.66s — bấm ở nhịp tự nhiên
(~0.2s) là lệnh hết hạn trước khi có ai hỏi. Bấm, không thấy gì, bấm lại.

**2. Nối đòn vẫn đợi TRỌN khung hồi.** Bắt được lệnh rồi thì nó nằm chờ tới
`t_dam_den + t_hoi` mới nổ. Hai nhát cách nhau 1.56 giây. Đó không phải nối
combo, đó là xếp hàng.

Sửa: cửa sổ NỐI mở ở 40% khung hồi và **cắt** phần còn lại. Đo lại bằng
`tools/soi_combo.tscn` (đo lúc HỘP ĐÒN BẬT, vì đó mới là lúc người chơi cảm
nhận một nhát):

| | trước | sau | Elden Ring |
|---|---|---|---|
| kiếm một tay 剑 | ~0.60s | **0.42–0.46s** | ~0.45s |
| kiếm hai tay 刃 | ~1.56s | **1.04–1.22s** | ~1.0–1.3s |

Một con số (`ti_le_cua_so_noi`) nhân với `t_hoi` của từng đòn, nên vũ khí nặng
tự nối chậm hơn vũ khí nhẹ mà không phải khai riêng dòng nào.

### Bộ đệm sức chứa 1, và một lỗi tôi tự gây ra

Chủ dự án viết lại spec đầy đủ: bộ đệm giữ **đúng một** lệnh, lệnh sau đè lệnh
trước. Bản cũ của tôi là một Dictionary nhiều khoá — spam ba nút lúc đang vung
thì ra ba hành động nối nhau sau khi đòn kết thúc.

Lúc chuyển sang một ô, tôi cho `lay_dem()` gọi thẳng `xoa_dem()`. Nhưng
`xoa_dem()` reset cả `_giu_danh` — bộ đếm GIỮ chuột. Mà lệnh `don_nang` bắn ra
lúc CHẠM ngưỡng giữ, trong khi ngón tay vẫn còn đang giữ, và `TrangThaiDanh`
hỏi đúng cái đang-giữ đó để biết có vào cú NẠP hay không.

Kết quả: cú nạp chết ngay khi vừa bắt đầu. Năm phép thử đỏ cùng lúc, tất cả về
dáng nạp — đủ để thấy ngay, nhưng nếu không có nhóm phép thử đó thì đây là loại
lỗi sống sót rất lâu. Tách `_bo_lenh_cho()` (chỉ dọn ô đệm) khỏi `xoa_dem()`
(dọn cả bộ đếm giữ phím).

### Nâng nhịp vật lý lên 120Hz làm bộ thử chập chờn

`_hai_khung()` đợi hai nhịp vật lý — 33ms ở 60Hz, đủ phủ một khung hình. Ở
120Hz nó còn 16ms, ngắn hơn một khung hình, mà sự kiện phím đi qua
`_unhandled_input` chạy theo khung hình chứ không theo nhịp vật lý.

Hỏng kiểu đó **không đỏ đều**: một lần trong vài chục lượt, ở một phép thử khác
nhau mỗi lần. Trông y hệt "bộ thử vốn chập chờn" — và đó là cách nó sống sót.
Thêm một `process_frame` vào đầu là hết.

### Cứu một clip khỏi ô "thừa"

Câu hỏi "tại sao mấy animation dying lại thừa?" làm lộ một chỗ tôi phân loại
ẩu. `TrangThaiChet.T_CHO` khi đó là 2.8 giây; đo độ cao hông ở đúng giây đó thì
`Death1` (3.90s) vẫn ở 0.35m — **cái xác còn đang rơi thì màn hình đã cắt**.
`Dying2` (2.60s) mới là bản vừa.

Bài học không phải "đo kỹ hơn" mà là: **"dự phòng" và "thừa" là hai loại khác
nhau**, và tôi gộp chúng vào một ô trong bảng. Thứ thừa vì game không có cơ chế
đó thì tải thêm cũng vô dụng; thứ thừa vì "đã có một cái đủ dùng" thì phụ thuộc
vào một phán đoán — và phán đoán thì sai được.

(Ràng buộc 2.8 giây giờ đã bỏ: màn "BẠN ĐÃ CHẾT" đợi phím, không đợi đồng hồ.)

## Cần người, agent không làm thay được

1. **Tune bốn con số của mục 5.2.** Mốc 2 là điểm quyết định của cả dự án và nó
   chỉ tune được bằng cách CHƠI. Bốn con số: `SoulsLike.iframe_lan`,
   `SoulsLike.tre_hoi_the_luc`, cột `t_hoi` của đòn nặng trong `moveset.csv`,
   và `SoulsLike.HS_SAT_THUONG_NGUOI_CHOI`. Test chỉ canh được khoảng hợp lệ,
   không canh được "đã đã tay chưa".
2. **Thiết kế màn.** Đường tắt, mai phục, vòng lặp — mục 7.1 của bản yêu cầu nói
   thẳng là AI làm dở việc này. Vùng hoang dã thì sinh tự động được.
3. **Model quái + khiên.** Người chơi đã có model thật (`nhan_vat_chinh.fbx`,
   43 clip); quái vẫn khối hộp, khiên vẫn khối hộp. Chuẩn cần đạt — cùng bộ
   xương với `nhan_vat_chinh.fbx` nếu muốn dùng chung animation, hoặc rig
   humanoid riêng cho quái. Mixamo đòi tài khoản Adobe, agent không đăng nhập
   được — việc tải file vẫn cần người.
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
  `NguoiChoi.NGUONG_GIU_NANG` (0.18s) là nhẹ, giữ lâu hơn là nặng, giữ tiếp nữa
  thành đòn nạp. Action `don_nang` đã gỡ khỏi input map; cái tên chỉ còn sống
  trong bộ đệm phím.
- **Bộ nút đã dọn lại một lượt** (chủ dự án chốt). Bảng cũ → mới:

  | Việc | Cũ | Nay |
  |---|---|---|
  | lăn | Space gõ nhanh | Space gõ nhanh |
  | chạy | Space giữ | **Shift giữ** |
  | nhảy | F | **Space giữ** |
  | đỡ phản | chuột phải / R | **chuột phải bấm** |
  | giơ khiên | Q | **chuột phải giữ** |
  | tương tác | E | **F** |

  Hai action đổi tên theo: `lan_chay` → **`lan_nhay`**, và action `nhay` bị gỡ
  hẳn (nhảy giờ là kết quả của việc GIỮ Space, nạp vào `_dem["nhay"]` từ
  `NguoiChoi._process()`). Thêm action mới `chay_nhanh` = Shift.
  Bộ test gọi action theo TÊN nên đổi phím không làm đỏ test nào — đó đúng là
  chỗ nguy hiểm, nên nhóm "Nút mới" trong `thu_vong_lap.gd` canh riêng việc này.
- **Không dùng Terrain3D / ProtonScatter** (mục 7.3). Chủ dự án chọn tự viết —
  repo sạch, không phụ thuộc phiên bản addon. Địa hình sinh tự động, viết ở
  mốc 6 (xong).
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

- **Bộ kiểm tra mà ngồi ở `current_scene` thì nó tự huỷ chính mình.** Hàm đổi
  cảnh (`DuHanh._doi_that`, `LuuGame._doi_that`) gỡ và huỷ đúng `current_scene`.
  `thu_dau_game.gd` bấm "Chơi mới" — tức là đổi cảnh — nên nó phải NẰM NGOÀI:
  dựng màn đầu game rồi `get_tree().current_scene = màn đó`, còn node kiểm tra
  ở lại root. Bản đầu không làm thế và nó **treo vô hạn**, vì mọi `await` sau
  đó không bao giờ tiếp tục. Cái treo ấy trông y hệt "test chạy xong rồi đứng".

- **`add_child()` trong `_ready()` bị từ chối thẳng** ("Parent node is busy
  setting up children"). Bộ kiểm tra dựng cảnh trong `_ready` nên phải
  `await get_tree().process_frame` một cái trước đã. Không await thì cảnh không
  vào được cây, `current_scene` vẫn là bộ kiểm tra, và nó rơi đúng vào bẫy ở
  trên — hai lỗi khác nhau dẫn tới cùng một cái treo.

- **`ManChung.chu()` căn TRÁI, và ở màn căn giữa thì đó là sai.**
  `BoxContainer.alignment` chỉ căn theo chiều DỌC, nên một dòng chữ trong
  VBox căn giữa vẫn dính sát mép trái màn hình — cách đám nút ở giữa cả ngàn
  pixel trên màn rộng. Không test nào bắt được: dòng chữ vẫn ở đó, vẫn đúng
  nội dung, chỉ nằm sai chỗ. **Ảnh chụp mới thấy** — lại đúng bài học cũ.

- **Tự lưu lúc không có người chơi ghi đè save thật bằng một ván rỗng.**
  `LuuGame.thu_thap()` ghi `canh` = cảnh hiện tại và `nguoi_choi` = {} nếu
  không tìm thấy ai. Bấm "Thoát" ở màn đầu game mà cũng tự lưu thì ô tự lưu trỏ
  vào chính cái menu, và "Chơi tiếp" lần sau nạp lại đúng cái menu ấy — ván
  chơi thật biến mất, không có đường lùi. Giờ `tu_luu()` tự từ chối, và màn đầu
  game còn chặn thêm một lớp nữa ở `_thoat_game()`.

- **HUD nối tín hiệu hai lần.** `_tim_nguoi_choi()` gọi từ cả `_ready()` (sau
  một khung `await`) lẫn `_process()`, và hai đường đó đua nhau được — `_process`
  chạy trước phần sau `await` của `_ready` là chuyện thường. Mỗi lần nạp cảnh
  mới là Godot đổ "Signal is already connected" ra log. Không gãy gì, nhưng một
  dòng đỏ quen mắt là một dòng đỏ không ai đọc nữa.

- **Autoload → lớp `class_name` → autoload là vòng tròn chết, và headless
  không thấy.** `du_hanh.gd` (autoload) ép kiểu `as VungDat`; `vung_dat.gd`
  gọi `DuHanh`. Godot phải phân giải lớp `VungDat` ngay lúc nạp autoload
  `DuHanh`, mà lúc đó `DuHanh` chưa đăng ký xong. Kết quả: `DuHanh` không đăng
  ký được, **kéo theo mọi autoload đứng sau nó** (`AmThanh`) cũng mất, và hơn
  ba chục dòng `Identifier not declared` đổ ra khắp nơi.

  Đáng sợ nhất là **cả bốn bộ kiểm tra đều xanh**: headless phân giải lớp theo
  đường khác nên không tái hiện. Chỉ chạy game thật mới thấy. Giờ
  `tools/kiem_csv.py` có `kiem_autoload()` canh tĩnh — và nó chỉ báo khi lớp
  gọi ngược về CHÍNH autoload đó hoặc một autoload đăng ký sau, vì gọi autoload
  đăng ký trước thì vô hại (`Tui` nhắc `MonDo`, `mon_do.gd` gọi `VocabDB` —
  vẫn chạy tốt bao lâu nay).

  Bài học rộng hơn: **bộ kiểm tra chạy trong một môi trường khác môi trường
  chơi thật thì có những lớp lỗi nó không bao giờ với tới.**

- **Cái xác nhặt được hồn của chính nó.** `TuongTacDuoc` chỉ hỏi "có phải thứ
  gần nhất không", không hỏi "người chơi còn đứng được không". Mà vũng hồn mọc
  ĐÚNG chỗ ngã xuống, nên cái xác nằm trọn trong tầm với của nó suốt 2.8 giây
  trước khi đứng dậy ở bia — bấm phím tương tác lúc đó là nhặt lại sạch, mất trắng thành ra
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

- **Theme gán ở root Window KHÔNG ăn.** Đo trong Godot 4.7:
  `get_tree().root.theme = t` nhận resource thật, `t.has_stylebox("normal",
  "Button")` trả `true`, mà một Button bất kỳ vẫn resolve ra `StyleBoxFlat` mặc
  định của engine. Phải gán thẳng vào một Control tổ tiên — `GiaoDien.ap_theme()`.

  Đáng sợ ở chỗ hệ quả: font mặc định của Godot không có chữ Hán, nên màn nào
  không ăn theme thì tên món đồ hiện ô vuông — **trông y hệt cơ chế `???` của
  chính game này**. Một lỗi font giả dạng thành một cơ chế đang chạy đúng.

- **Bộ test không nhìn được giao diện.** Vệt cọ đỏ của bản mẫu bị đặt làm kiểu
  của MỌI `Button`, nên màn hành trang — vốn dựng mỗi món đồ thành một Button —
  biến thành một bức tường vệt sơn với chữ bị bóp không đọc nổi. 216 test vẫn
  xanh: không test nào hỏi "cái này trông thế nào". Bắt được bằng cách chạy
  `tools/chup_man_hinh.tscn` và NHÌN vào ảnh.

  Bài học: **thứ gì chỉ sai ở phần NHÌN thì chỉ có nhìn mới bắt được.** Bốn bộ
  test canh được luật, không canh được bố cục. Sửa giao diện thì chụp ảnh.

- **Đặt vị trí Control bằng anchor preset rồi gán `position` là mất.** Preset
  ghi đè cả offset, nên `position` gán một lần lúc dựng bị nó nuốt. Minimap vì
  thế nằm lọt hẳn ngoài mép phải màn hình, và không lỗi nào nổ ra — chỉ là góc
  phải trên trống trơn. Cách né: tự tính vị trí theo `get_viewport_rect()` mỗi
  khung, và như thế đổi cỡ cửa sổ cũng theo kịp.

- **Đợt nhập tài nguyên đổ giữa chừng, mà CI báo xanh.** Trình nhập của Godot
  tự đổ trên máy CI (`ERROR: FATAL: Index p_index = -1 is out of bounds
  (size() = 44)` ở `cowdata.h`, kèm một lời than `propagate_notification()`
  gọi từ thread sai, rồi signal 4). Lỗi nằm trong engine chứ không trong repo:
  nhập nguội ba lần liên tiếp trên máy khác đều sạch 84/84 cảnh, và đúng cây
  code ấy đã qua CI ở lần đẩy trước.

  Cái đáng ghi không phải cú đổ, mà là **nó trôi qua được**. Lệnh trong
  workflow là `godot ... --import 2>&1 | tee nhap.log`, và mã thoát của một
  ống dẫn là mã của lệnh CUỐI — tức là của `tee`, luôn 0. Godot đổ lõi
  (`timeout: the monitored command dumped core` nằm ngay trong log) mà bước
  vẫn xanh, nên bốn bộ kiểm tra chạy tiếp trên một dự án mới nhập được vài
  file CSV.

  Đọc ra thì đánh lừa hoàn toàn: ba phép thử đỏ lên, cả ba đều ở PHẦN NHÌN —
  "mặc khiên vào thì thân VẼ khiên ra", "dạt ngang thì phát clip đi ngang"
  (trả về chuỗi rỗng), "nạp đòn: giơ tay lên tới đỉnh (0°)". Ba thứ đó trông
  y hệt một thay đổi vừa làm hỏng phần hình, trong khi thật ra chỉ là không
  có font và không có clip nào được nhập. Tổng số phép thử cũng tụt 360 → 300
  mà không ai để ý.

  Hai chỗ vá, cả hai đều cần: `set -o pipefail` để mã thoát đi được ra ngoài,
  và `tools/kiem_nhap.py` — phép kiểm **dương**, đếm rằng mọi file `.import`
  có đủ file đích trong `.godot/imported/`. Phép kiểm dương là thứ quan
  trọng hơn: mã thoát nói "tôi không báo lỗi", còn đếm file thì nói "tài
  nguyên có thật ở đó".


- **Một `await get_tree().process_frame` KHÔNG đủ để `_process` chạy.** Tín
  hiệu `process_frame` bắn ra TRƯỚC khi SceneTree gọi `_process` của các node,
  nên await một lần rồi đo là đo đúng cái trạng thái chưa đổi. Dính lúc viết
  phép thử cho hàng chờ dựng ô: dịch người chơi sang ô bên cạnh, await một
  khung, thấy `_o_cuoi` vẫn là ô cũ và hàng chờ rỗng — đọc ra y hệt "streaming
  không chạy", trong khi nó chỉ chưa tới lượt. Mất một vòng đi dò mới thấy.
  Cách né: `_khung()` trong `thu_the_gioi.gd` await HAI lần. `thu_vong_lap.gd`
  đã có sẵn `_hai_khung()` cùng lý do — nhưng nó await một `process_frame` rồi
  hai `physics_frame`, nên bài học ấy chưa từng được viết ra thành chữ.

- **Dựng ô địa hình: 33 ms mỗi 64m, và không ai để ý suốt mấy mốc.** Bản đầu
  của `_cap_nhat_o()` dựng thẳng mọi ô còn thiếu ngay trong `_process`. Băng
  qua một ranh giới ô là năm ô mới — đo được 33 ms (đất 3.1 ms + rải prop
  3.5 ms mỗi ô), tức BỐN tick vật lý 120Hz bị nuốt trong một khung hình.

  Vì sao trôi lâu thế: vùng hiện tại chỉ rộng 320m nên người chơi hiếm khi
  băng ranh giới, mà bộ kiểm tra thì DỊCH CHUYỂN người chơi chứ không đi bộ —
  cả hai đường đều không bày cái khựng ra. Nó chỉ thành vấn đề khi map rộng
  ra, lúc đó cứ mươi giây chạy là một cú.

  Sửa bằng hàng chờ + ngân sách mỗi khung (`VungDat.NGAN_SACH_MS`), khung tệ
  nhất còn **3.7 ms**. Chỗ tinh tế là ranh giới ĐI BỘ / DỊCH CHUYỂN: đi bộ thì
  ô mới gần nhất cách ≥64m nên hoãn là miễn phí, còn dịch chuyển thì ô dưới
  chân biến mất ngay và hoãn là rơi xuyên sàn. Một dòng `if not
  _o_dang_co.has(o): nap_het()` gánh cả phân biệt đó.

  KHÔNG dùng thread: `WorkerThreadPool` nhanh hơn nữa, nhưng cây node của
  Godot không đụng được từ thread phụ, mà hỏng kiểu đó thì im lặng — đúng loại
  bẫy cả file này đang đi ghi lại.
