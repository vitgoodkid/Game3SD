# Game3SD — ghi chú cho agent

Đọc file này trước khi sửa bất cứ thứ gì. `TIEN_DO.md` cho biết đang ở mốc nào.

## Dự án này là gì

Souls-like 3D trong Godot 4.7, GDScript thuần, giao diện tiếng Việt.
Combat **thuần né/lăn/timing** — không có thao tác ngôn ngữ nào trong lúc đánh.
Toàn bộ phần học tiếng Trung nằm ở **tầng trang bị**.

Bản yêu cầu gốc: `PROMPT_3D.md` ở gốc repo. Mọi comment trong code dẫn "mục 4.2",
"mục 5.1"… là dẫn tới file đó.

Kế thừa từ bản 2D (`E:\Gamez\han-tu-fixed` trên máy chủ dự án — **không có trên
cloud**): 993 chữ Hán trong `data/`, và hai script luật `chien_dau.gd`,
`do_hiem.gd`. Mọi thứ đã copy vào repo này rồi; không cần bản 2D để làm việc nữa.

Hai file nữa từng được chép sang rồi **xoá hẳn**: `battle.gd` (màn đánh theo
lượt, hỏi đáp trắc nghiệm — đá thẳng luật 3) và `crafting_manager.gd` (bàn chế
đồ kéo–thả 2D, đã bị thẻ *Khắc chữ* ở bia đá thay thế). Cả hai nằm im 1187 dòng
không ai gọi, nên Godot chưa từng biên dịch chúng. Đừng chép lại.

## Bốn luật không được phá

1. **KHÔNG hardcode từ vựng / công thức / khu vực trong code.** Thêm nội dung =
   sửa CSV. Code không được biết chữ 火 tồn tại.
   *Ngoại lệ duy nhất:* `scripts/luat/ngu_hanh.gd` biết năm hành, vì năm hành là
   hằng số văn hoá chứ không phải nội dung game.
2. **Giao diện tiếng Việt.** Tên biến, tên hàm, comment đều tiếng Việt.
3. **Combat không bị ngôn ngữ chen vào.** Không gõ chữ, không câu hỏi, không
   pause khi đang đánh.
4. **Phai chữ chỉ ăn vào phần CỘNG THÊM, không bao giờ ăn vào chỉ số gốc.**
   Người chơi không bao giờ bị yếu tới mức không qua nổi chỗ đã qua.
   Chỗ thi hành: `TenDoVat.sat_thuong_thuc()`. Có test canh.

## Phép thử phải luôn qua

> Thay hết chữ Hán trong game bằng icon vô nghĩa. Game có hỏng không?
> Hỏng → thiết kế đúng. Vẫn chơi bình thường → làm lại.

Chỗ làm cho nó hỏng là `scripts/luat/ten_do_vat.gd`: tên món đồ đọc như ngữ pháp
thật, đổi thứ tự chữ là đổi món đồ, chữ chưa đọc được thì chỉ số hiện `???`.
Sửa file đó thì chạy lại test ngay.

## Chạy và kiểm tra

Cần Godot 4.7 (trên máy chủ dự án: `E:\Gamez\Godot_v4.7.2-stable_win64.exe`).

```bash
# kiểm tầng luật — 197 test trong một khung hình, thoát mã 1 nếu hỏng
godot --headless --path . tools/kiem_tra.tscn

# kiểm vòng lặp souls + combat + giao diện — 379 test, nạp phòng thử thật:
# đánh, thể lực, cam kết đòn, i-frame, siêu giáp, đòn phản đỡ, vỡ đỡ, đỡ phản
# hai bậc, MỘT NÚT đỡ+parry và parry cắt đòn/cắt lăn, bộ nút (Space lăn/nhảy, Shift chạy), đòn nhảy,
# state machine quái, chết, rơi vũng hồn, đứng dậy ở bia, quái sống lại,
# MP, tuỳ chọn, minimap, màn tạm dừng, theme và font.
# Chạy mất ~45 giây vì phải đợi thật.
godot --headless --path . tools/thu_vong_lap.tscn

# kiểm màn đầu game — 39 test: Chơi mới / Chơi tiếp / Tải ván. Đây là bộ DUY
# NHẤT đụng tới việc ĐỔI CẢNH, thứ ba bộ kia không với tới vì mỗi bộ bị buộc
# vào một cảnh. Nó GHI ĐĨA nhưng cất save của người thật đi rồi trả lại.
godot --headless --path . tools/thu_dau_game.tscn

# kiểm thế giới + nội dung — 67 test, sinh một vùng thật từ CSV rồi đi lại:
# địa hình, rải cây đá, streaming ô, bảy bảng màu, vùng bị xoá, chuỗi du hành,
# NPC và cốt truyện, âm thanh, 18 loài, boss ẩn 无
godot --headless --path . tools/thu_the_gioi.tscn

# chạy thử game 10 giây, bắt lỗi lúc chạy. Trỏ THẲNG vào cảnh chơi: từ khi có
# màn hình đầu game thì `main_scene` là cái menu, chạy nó 600 khung hình không
# bắt được gì.
godot --headless --path . scenes/the_gioi/phong_thu.tscn --quit-after 600

# kiểm CSV, KHÔNG cần Godot — chạy được ở bất cứ đâu có Python
python tools/kiem_csv.py

# kiểm ĐỢT NHẬP đã chạy TRỌN hay chưa, cũng không cần Godot. Chạy sau
# `--import`; mọi file .import phải có đủ file đích trong .godot/imported/.
python tools/kiem_nhap.py

# ĐO NHỊP ĐÒN TỪ CLIP — sinh ra mấy con số của moveset.csv. Chạy sau mỗi lần
# đổi file .fbx trong assets/model/dong_tac/, rồi chép bảng nó in ra.
godot --headless --path . tools/do_nhip_don.tscn

# CHỤP ẢNH giao diện. Không chạy được với --headless (headless không vẽ gì).
# Chín ảnh ra user://: hud, hud lúc vơi, menu tạm dừng, tuỳ chọn, điều khiển,
# hành trang, hud cửa sổ nhỏ, MÀN ĐẦU GAME, màn đầu game trang Tải ván.
godot --path . tools/chup_man_hinh.tscn
```

GitHub Actions chạy cả bảy mỗi lần đẩy code (`.github/workflows/kiem_tra.yml`).
**Không có Godot thì vẫn sửa được CSV và tầng luật** — đẩy lên rồi đọc kết quả
Actions.

Sáu cái bẫy đã gặp:

- Nếu script của scene chính không biên dịch được, Godot headless **treo vô hạn**
  chứ không báo lỗi. Luôn bọc lệnh chạy bằng `timeout`.
- **Script không gắn vào scene nào thì Godot không biên dịch nó.** CI xanh không
  có nghĩa là file đó chạy được — `cau_hoi.gd` từng nằm trong repo cả một mốc
  với một lỗi biên dịch mà CI không thấy. Viết file mới xong thì phải nối nó vào
  scene hoặc gọi nó trong bộ kiểm tra, không thì coi như chưa viết.
- **Kéo code mới về xong phải `--import` trước khi chạy test.** Cache lớp toàn
  cục (`.godot/`) không nằm trong git, nên `class_name` mới kéo về Godot chưa
  biết — và nó treo đúng như bẫy đầu tiên, không báo gì cả:
  `timeout 300 godot --headless --path . --import`
- **Đợt nhập ĐỔ GIỮA CHỪNG trông y hệt đợt nhập thành công.** Trình nhập của
  Godot có lúc tự đổ (`Index p_index = -1 is out of bounds`, signal 4 — lỗi
  trong engine, không trong repo), để lại một `.godot/` mới dựng được vài
  file. Không lỗi nào của repo nổ ra, nhưng thiếu font và thiếu clip thì mấy
  phép thử phần NHÌN đỏ lên, và đọc ra giống hệt vừa làm hỏng gameplay. Đã
  dính đúng vậy trên CI, còn bị `| tee` nuốt mất mã thoát nên bước nhập báo
  xanh. Hai chỗ canh: `set -o pipefail` trong workflow, và
  `tools/kiem_nhap.py` — phép kiểm DƯƠNG, đếm đủ file đích chứ không tin vào
  mã thoát.
- **Autoload KHÔNG được nhắc tên một `class_name` mà file của lớp đó gọi
  ngược lại autoload.** Godot phải phân giải lớp ngay lúc nạp autoload, mà
  autoload thì chưa đăng ký xong ⇒ gãy, và gãy rồi thì **mọi autoload sau nó
  cũng mất**, cả game đỏ rực. Đã dính: `du_hanh.gd` ép kiểu `as VungDat`, mà
  `vung_dat.gd` gọi `DuHanh`. Cách né: dùng `set("thuoc_tinh", ...)` thay vì ép
  kiểu. **Chạy headless KHÔNG tái hiện được** — chỉ chạy thật mới thấy, nên
  `tools/kiem_csv.py` có phép kiểm tĩnh canh đúng chuyện này.
- **`.tres` và `project.godot` do Godot sở hữu.** Chạy Godot một lần là nó viết
  lại theo định dạng chuẩn của nó: xoá comment `;`, xoá dòng trùng giá trị mặc
  định, tự thêm `uid`. Đừng đặt tài liệu vào đó — comment sẽ biến mất, mà uid
  thì sinh lại NGẪU NHIÊN mỗi lần ai đó khôi phục file, nên cây làm việc bẩn
  mãi không sạch. Ghi chú thiết kế để ở `.md` hoặc trong `.gd`.

Danh sách bẫy đầy đủ nằm cuối `TIEN_DO.md`.

## Bản đồ code

```
data/            CSV — nguồn sự thật của mọi nội dung
scripts/
  luat/          luật thuần, không đụng node:
                   chien_dau.gd   sát thương/giáp/nguyên tố (port từ 2D)
                   do_hiem.gd     5 bậc độ hiếm (port nguyên)
                   souls_like.gd  thể lực, i-frame, poise, tư thế, thiên can
                   ngu_hanh.gd    vòng tương sinh tương khắc
                   ten_do_vat.gd  NGỮ PHÁP TÊN MÓN ĐỒ — cơ chế xương sống
                   mon_do.gd      một món đồ = một mảng chữ
                   cau_hoi.gd     10 dạng câu hỏi — KHÔNG màn nào gọi nữa
                   sinh_mon_do.gd sinh đồ rơi từ CSV, không biết chữ nào tồn tại
  he_thong/      autoload có trạng thái: vocab_db, tui, tri_nho, the_gioi
                   am_thanh.gd    IM LẶNG. Giữ bản kê 15 tên tiếng + 18 chỗ
                                  gọi; thả .wav vào assets/tieng/ là chạy
                   giao_dien.gd   font, bảng màu, kho ảnh, theme chung
                   cai_dat.gd     tuỳ chọn người chơi, ghi user://cai_dat.json
  nhan_vat/      người chơi, camera ba chế độ, khoá mục tiêu, máy trạng thái
                   than_mo_hinh.gd  THÂN ĐANG DÙNG — model + animation thật
                   than_khoi.gd     thân khối hộp cũ, quái vẫn theo khuôn này
    trang_thai/  mỗi state một file
  quai/          quái + boss hai giai đoạn, state machine riêng
  the_gioi/      phòng thử, VÙNG THẬT (địa hình + streaming + du hành),
                   bia đá, đồ rơi, vũng hồn, vòng hồi sinh
                   tuong_tac_duoc.gd  lớp gốc mọi thứ bấm F được
  giao_dien/     HUD + màn che toàn màn (hành trang, bia đá, tạm dừng)
                   man_dau_game.gd  MÀN ĐẦU GAME — kế thừa man_cai_dat.gd
                   minimap.gd     bản đồ tròn, quét NHÓM chứ không đọc địa hình
assets/ui/       bộ asset giao diện (PNG), chép từ ngoài vào
assets/font/     font chữ Latin — KHÔNG có chữ Hán, xem mục Font
scenes/          .tscn
tools/           kiểm tra + sinh dữ liệu
```

## Quy ước

- **Máy trạng thái là bắt buộc.** Người chơi lẫn quái. Không viết chuỗi `if` để
  hỏi "đang làm gì". Mỗi state là một node con có `vao()` / `ra()` / `chay(delta)`.
- **Cam kết đòn đánh** đứng trên HAI chân, cần cả hai:
  1. state đang đánh không đọc phím nào — bấm gì giữa đòn cũng chỉ vào bộ đệm;
  2. `cho_doi()` của nó từ chối gần hết mọi chuyển tiếp từ ngoài vào.
  Chân thứ hai chỉ có tác dụng khi bên gọi dùng **`may.xin_doi()`** chứ không
  phải `may.doi()`. Luật: chuyển tiếp do **ngoại cảnh ép** (ăn đòn, bị đỡ
  phản) thì `xin_doi()`; chỉ CHẾT và chuyển tiếp do chính state tự quyết lúc
  nó kết thúc mới được `doi()` thẳng. Đây là thứ phân biệt souls-like với
  hack-n-slash. Đừng nới.
- **Mọi con số cảm giác** nằm trong `souls_like.gd` và `data/moveset.csv`.
  Đừng rải hằng số vào state.
- **Sát thương người chơi nhân `SoulsLike.HS_SAT_THUONG_NGUOI_CHOI`** ở
  `Tui.sat_thuong_don()` — quy thang điểm bản 2D sang thang máu bản 3D. Đổi số
  đó là đổi nhịp cả game; quái thường nên chết trong 4–8 đòn nhẹ.
- **Combat làm theo Elden Ring.** Chủ dự án yêu cầu bám ER. Xem mục "Combat
  kiểu Elden Ring" ở cuối `TIEN_DO.md` để biết chỗ nào giống, chỗ nào cố ý
  khác và vì sao. Đổi gì trong combat thì đối chiếu lại mục đó trước.
- **Thể lực (ER):** đánh, lăn, nhảy, chạy, và đỡ một đòn đều TỐN. Cái quyết
  định không phải là "tốn hay không" mà là CÁCH HỒI: đang bận hành động thì
  không hồi (`TrangThaiMay.cho_hoi_the_luc()`), xong việc rồi chờ
  `tre_hoi_the_luc` giây là hồi nhanh. **Đừng bao giờ đặt lại mốc trễ ở chỗ
  TIÊU** — làm thế thì mỗi nhát chém đẩy lùi mốc hồi thêm một lần, ba nhát
  liên tiếp là thanh thể lực đứng hình. Đó đúng là lỗi từng làm combat khựng.
- **HAI nút gánh hai việc, cùng một khuôn "gõ nhanh / giữ".** Đây là chỗ dễ
  hiểu nhầm nhất của bộ điều khiển, và cả hai đều KHÔNG còn action riêng:
  - **Chuột trái**: nhả trước `NguoiChoi.NGUONG_GIU_NANG` (0.18s) là đòn nhẹ,
    giữ lâu hơn là đòn nặng (giữ tiếp nữa thành đòn nạp). Không còn action
    `don_nang` trong input map.
  - **Space** (`lan_nhay`): bấm HAI lần trong `NguoiChoi.NGUONG_BAM_DOI`
    (0.22s) là **lăn**, bấm một lần là **nhảy**. Không còn action `nhay` trong
    input map — `_dem["nhay"]` do `NguoiChoi._process()` nạp vào khi hết cửa sổ
    bấm đôi mà không có cú bấm thứ hai.

  Cái giá của chuột trái không tránh được: đòn nhẹ chỉ bắn ra lúc NHẢ, còn đòn
  nặng bắn ngay lúc chạm ngưỡng giữ. Đừng đổi đòn nặng sang đợi nhả — đợi nhả
  thì nó trễ theo đúng thời gian giữ nút.

  Cái giá của Space nằm ở chiều ngược lại: **lăn** bắn ra ngay ở cú bấm thứ
  hai, còn **nhảy** phải đợi hết cửa sổ mới dám gọi là nhảy — trước đó chưa ai
  biết người chơi có bấm tiếp không. Nhảy vì thế trễ 0.22s, và đó là đánh đổi
  có chủ ý: lăn là thứ cứu mạng, nhảy thì không.
- **Shift giữ là chạy** (`chay_nhanh`). Nút giữ thuần, không ngưỡng, không chia
  sẻ với ai — nên chạy là thứ duy nhất trong bộ điều khiển này không có độ trễ.
- **CHUỘT PHẢI là CẢ đỡ LẪN đỡ phản — một nút, khuôn "gõ nhanh / giữ" thứ ba.**
  Chủ dự án chốt gộp; E và Q giờ **không gán gì**, và action `do_don` đã bị
  **xoá hẳn** khỏi input map (còn state tên `do_don` thì giữ nguyên — đừng lẫn
  hai thứ đó). Mọi chỗ code từng hỏi `is_action_pressed("do_don")` giờ hỏi
  `"do_phan"`.
  - **Bấm ra là parry, HAI BẬC lồng nhau**: `cua_so_perfect` (0.10s đầu) là
    **hoàn hảo** — quái ngây `NGAY_SAU_PERFECT`, hoàn lại thể lực; hết khoảng
    đó tới `cua_so_do_phan` (0.24s) là parry thường. Lồng nhau chứ không tách
    rời là cố ý: bấm sớm quá vẫn ăn parry thường, nên tập bấm sớm không bị
    phạt. `an_don()` trả **-2** cho hoàn hảo, **-1** cho thường; chỗ nào không
    quan tâm bậc cứ kiểm tra `< 0` như cũ.
  - **Còn GIỮ khi hết `cua_so_do_phan` thì đi thẳng sang `do_don`, KHÔNG qua
    khung ngây** (`do_phan.gd`). Đó là chỗ cây gậy đổi đầu: gõ nhanh là đánh
    cược — hụt thì đứng ngây `hoi_do_phan` (0.45s), đủ ăn trọn một đòn nặng;
    giữ là chơi chắc — hụt thì khiên lên đỡ.
    Giữ **không phải** parry miễn phí, và chỗ thi hành nằm ở `an_don()` chứ
    không ở `do_phan.gd`: đỡ chỉ chặn được khi tay trái CÓ khiên, mà vũ khí
    hai tay (刃 — đúng cây khởi đầu) làm `Tui.tay_trai_dang_cam()` trả null.
    Với họ, giữ tiếp nghĩa là đứng đó ăn gần trọn đòn và mất thêm thể lực.
  - **Ngón tay giữ SẴN từ trước không được tặng một cửa sổ parry.** Phân xử
    bằng thứ tự trong `thu_hanh_dong()`: cú BẤM mới bị `lay_dem("do_phan")`
    bắt ở bậc phòng thủ, nên xuống tới bậc cuối (`is_action_pressed`) thì chỉ
    còn trường hợp đã giữ từ trước ⇒ vào thẳng `do_don`.
  - **KHÔNG cần khiên để parry** — ER cấm parry tay không, chủ dự án chốt cho
    được. Đỡ trúng rồi bấm đòn nặng trong `cua_so_phan_do` giây là ra **đòn
    phản đỡ** (cái này vẫn cần khiên).
- **Parry CẮT được đòn đánh và CẮT được cú lăn.** Hai chỗ, hai luật khác nhau:
  - **Đòn đánh: chỉ từ đoạn 4** (`cho_ne()`), ngang hàng lăn và khiên, qua
    `TrangThaiDanh._huy_sang_thu()`. Cam kết đòn đánh KHÔNG bị nới: đoạn 1–3
    vẫn khoá cứng. Trước đây parry không có mặt trong hàm đó, và đấy là lỗ
    thật chứ không phải lựa chọn — `cho_doi()` vẫn liệt `do_phan` vào danh
    sách cho phép nhưng không ai gọi `xin_doi("do_phan")`, nên cú parry nằm
    trong đệm tới khi đòn hết hẳn: **trễ 0.20s (nhe_1) tới 0.47s (nang)**,
    trong khi cả cửa sổ parry chỉ 0.24s. Tức là parry bấm đúng nhịp luôn bung
    ra SAU khi đòn quái đã trúng.
  - **Cú lăn: bất cứ đoạn nào**, kể cả giữa i-frame (`lan.gd`). Cắt sớm là tự
    bỏ phần bất tử còn lại để đổi lấy cửa sổ parry — quyết định có giá, không
    phải lỗ hổng. Thứ chặn nó thành "bất tử miễn phí" đã nằm sẵn: `hoi_lan`
    đặt ở `vao()` chứ không ở `ra()`, nên cắt giữa chừng không cho lăn lại
    sớm hơn một phần trăm giây nào.
- **Đòn nhảy hai bậc**: đánh lúc `NguoiChoi.tren_khong()` ra `nhay` (bấm) hoặc
  `nhay_nang` (giữ) thay cho đòn thường. **Mỗi lần rời đất đúng MỘT đòn** —
  `con_don_tren_khong()` / `dung_don_tren_khong()`, đặt lại khi chạm đất. Không
  có luật đó thì rơi từ vách cao chém được cả chuỗi, mà đòn nhảy nặng phá thế
  gấp 4 đòn thường. Cờ nằm ở `NguoiChoi` chứ không ở state `nhay`, vì rơi khỏi
  mép vách cũng đánh được đòn nhảy mà lúc đó state là `dung`/`di`.
- **LEO TƯỜNG (state `leo`).** Hai clip `leo_len` / `leo_xuong` là **vòng lặp
  TẠI CHỖ** (2.00s, hông đứng yên 0.69m), nên ở đây **code đẩy người, clip chỉ
  quay vòng tay chân** — ngược hẳn luật "animation làm chủ" của đòn đánh, và
  ngược có lý do: clip tại chỗ không chứa quãng đường nào để đo ra tốc độ.
  Tốc độ là `NguoiChoi.toc_do_leo` (chỉnh sống được), còn clip co giãn theo
  vận tốc dọc thật (`ThanMoHinh._toc_leo()`) — treo im thì vận tốc 0, clip
  đứng hình, và đó là dáng "treo" có sẵn không cần clip thứ ba.
  - **HAI cửa vào**, cả hai nằm ngoài `leo.gd`: ép phím vào tường liên tục
    `NguoiChoi.T_EP_TUONG` (0.5s) từ `di`/`chay_nhanh`, hoặc nhảy đâm vào
    tường từ `nhay`. Cú nhảy chỉ bám khi **còn đang bay LÊN** — xét cả lúc
    rơi thì chạy khỏi mép vách là dính tường lủng lẳng ngoài ý muốn.
  - **Mọi tường đều leo được, TRỪ nhóm `NguoiChoi.NHOM_CAM_LEO`** — danh sách
    CẤM, ngược chiều với `TRANG_THAI_TUONG_TAC`. Chủ dự án chốt. Chỗ BẮT BUỘC
    phải đánh dấu là **tường biên của map**: không đánh dấu thì người chơi
    trèo thẳng ra ngoài thế giới. Phòng thử đã đánh dấu (`TuongBien`).
  - Tường phải **cao hơn `CAO_LEO_TOI_THIEU` (1.5m)** mới bám. Nhờ vậy cái
    tường thấp 0.9m dựng ra để thử động tác NHẢY không bị biến thành thang.
  - **Tới đỉnh thì TỰ TRÈO lên mặt trên** (`_chay_treo`, 0.35s). Không có clip
    đu người qua mép — đoạn này là code dịch thân, đi hai chặng lên-rồi-vào
    chứ không nội suy thẳng một đường, vì đường thẳng thì nửa người lút vào
    trong khối đá suốt cú trèo.
  - Giá phải trả: **tốn thể lực theo giây** (cạn thì tuột), và **ăn đòn thì
    rơi** — không có vế sau thì bám tường thành chỗ trốn an toàn giữa trận.
    `cho_doi()` chặn `lan` / `danh`: lăn giữa lưng chừng tường là rơi xuyên sàn.
- **Bấm F đi qua `NguoiChoi.TRANG_THAI_TUONG_TAC`** — danh sách CHO PHÉP, nên
  trạng thái mới mặc định là không tương tác được. Chiều an toàn: vũng hồn mọc
  ngay dưới cái xác, và nếu xác bấm F được thì chết chẳng mất gì.
  (Action vẫn tên `tuong_tac`; phím đổi từ E sang F hồi E còn là parry.
  Giờ E trống hẳn — nhưng F ở lại, đổi ngược là lại một đợt đi sửa
  dòng mời.)
- **Hình vũ khí đọc từ CỘT `mo_hinh` của `nguyen_lieu.csv`**, không từ bảng
  gán cứng trong code. Bảng cũ `ThanKhoi.HINH_VU_KHI` gán chết năm chữ 剑刀斧弓拳
  và phá luật 1; nó còn đó làm khối hộp dự phòng cho vũ khí CHƯA có model, nhưng
  đường đi chính giờ là CSV. Thêm vũ khí mới = thêm một dòng CSV + thả file
  `.fbx` vào `assets/model/vu_khi/`, không đụng file `.gd` nào.
  `_chuan_hoa_vu_khi()` tự đo và tự đặt vào tay, nên không phải dò toạ độ cho
  từng cây.
- **Vũ khí HAI TAY: cột `hai_tay` của `nguyen_lieu.csv`.** Cầm hai tay thì
  `Tui.tay_trai_dang_cam()` trả **null dù khe có đồ** — mất khiên, mất đòn phản
  đỡ, mất chỉ số chặn. Đó là chỗ THI HÀNH cái giá của vũ khí lớn, và mọi bên gọi
  thấy đúng như vậy mà không cần biết vì sao.
- **Đang NẠP đòn nặng thì LẾT ĐƯỢC**, tốc độ × `SoulsLike.TOC_DO_KHI_NAP`.
  Đây là chỗ cam kết đòn được nới có chủ ý — cú vung chưa bắt đầu, nên cam kết
  tính từ lúc NHẢ, và lúc nhả thì nhắm lại theo hướng đang đứng. Mọi đòn khác
  vẫn bám chân tại chỗ; đừng nới thêm.
- **Siêu giáp (hyperarmor)** là cột `sieu_giap` của `moveset.csv`, cộng vào
  `NguoiChoi.the_dung()` chỉ trong khung vung tay rồi TẮT ở khung hồi. Gỡ chỗ
  tắt đi là vũ khí nặng thành bất khả xâm phạm và trận đánh mất hết rủi ro.
- **Bốn con số quyết định** (mục 5.2 của bản yêu cầu), có test canh khoảng:
  i-frame lăn 0.30–0.40s · **trễ hồi** thể lực 0.25–0.60s · hồi đòn nặng
  0.45–1.4s tuỳ vũ khí · `HS_SAT_THUONG_NGUOI_CHOI` (quái thường chết trong
  4–8 đòn nhẹ). Trần thứ ba nới từ 1.2 lên 1.4 khi nhịp đòn chuyển sang đo từ
  clip: 刃 là cây nặng nhất game và khung thu tay THẬT của nó là 1.33s. Con số thứ hai từng ghi là "khựng 0.6–1.0s tính mỗi lần tiêu"
  và cách tính đó chính là chỗ làm combat khựng cứng — xem mục Thể lực ở trên.
- **Khi bản yêu cầu và Elden Ring đá nhau thì CẢM GIÁC CHƠI thắng cả hai.**
  Chủ dự án chốt như vậy. `PROMPT_3D.md` mục 5.1/5.2 đã sửa theo con số thật;
  gặp chỗ nào tài liệu lệch code thì sửa TÀI LIỆU, đừng sửa ngược.
- **NGƯỜI CHƠI có model thật VÀ animation thật** (`than_mo_hinh.gd`;
  `assets/model/nhan_vat_chinh.fbx`, rig Mixamo 58 xương, da `katz.jpg`).
  Quái vẫn là khối hộp (`than_quai.gd`).
  43 clip đang chạy, **hai bộ**: cầm kiếm ở `assets/model/dong_tac/` (32 clip),
  tay không ở `dong_tac/khong_vu_khi/` (11 clip, dùng khi đã cất vũ khí).
  Trạng thái nào thiếu clip thì tự quay về dáng gõ tay trong file — hiện chỉ
  còn `uong` (uống bình).
  `NguoiChoi._dien_hinh()` hỏi thân theo HÀM `dien()` chứ không ép kiểu, nên
  hai thân thay nhau được mà không phải sửa gì.
  Ba cửa cho bộ kiểm tra — `goc_tay_phai()`, `khien_hien()`,
  `dong_tac_dang_phat()` — đừng bỏ. Cái thứ ba có vì khi đã có clip thật thì
  `dien()` KHÔNG xoay xương nữa, nên `goc_tay_phai()` đứng im và mọi phép thử
  canh theo góc tay đều mù.
  **Vũ khí có BA thế cầm: TRÊN TAY, ĐI/CHẠY, SAU LƯNG** (`CAM_TAY` / `CAM_CHAY`
  / `CAM_LUNG`). Cần ba vì thế cầm bám vào XƯƠNG BÀN TAY mà mỗi clip xoay bàn
  tay một kiểu — clip chạy dựng thanh kiếm xuyên qua đầu trong khi đúng thế ấy
  ở dáng đứng lại đẹp. Thêm nhóm mới: thêm một bộ ba `@export` và một dòng
  trong `TT_DI_CHUYEN` kiểu đó. Đổi giữa hai thế TRÊN TAY thì nội suy 0.12s;
  dính tới thế SAU LƯNG thì SNAP — hai bên neo vào hai xương khác nhau. Mỗi thế có đủ bộ ba
  `xoay` / `lech` / `lan` riêng — **đừng dùng chung `lan`**. Bản trước dùng chung,
  trong khi bàn chỉnh bày nó thành một dòng của TẮNG thế, nên chỉnh lăn lưỡi ở
  thế này là đổi luôn thế kia, im lặng.
  Chỉ có MỘT thế trên tay, dùng cho mọi tư thế còn cầm kiếm — chủ dự án chốt
  như vậy sau khi tự chỉnh bằng `tools/chinh_kiem.tscn`.
  Kiểm bằng `tools/soi_luoi_kiem.tscn`: nó đo lưỡi kiếm đi qua khoảng cao nào
  trong từng clip. Cú chém nào không phủ quãng 0.3–1.6m là lướt trên đầu con
  quái — sát thương vẫn đúng vì hộp đòn theo CSV, nhưng mắt đọc ra là chém hụt.
  Đổi model khác thì phải đo lại nhóm "Cầm trên tay" — trục xương mỗi rig một
  khác. Đo được, không phải đoán: clip kiếm hai tay giữ CẢ HAI bàn tay trên
  chuôi, nên vector tay phải → tay trái CHÍNH LÀ trục thanh kiếm. Rồi chạy
  `tools/chup_tu_the.tscn` và NHÌN.
- **ANIMATION LÀM CHỦ, CODE CHẠY THEO.** Chủ dự án chốt đổi chiều ở mốc này.
  Trước đây `moveset.csv` khai nhịp rồi `ThanMoHinh._toc_do()` co giãn clip cho
  vừa — cú Bổ bị ép chạy nhanh **2.25 lần**, cú đâm lướt 1.32 lần, mỗi đòn một
  hệ số — nên động tác đọc ra như tua nhanh mà không con số nào trong repo nói
  ra điều đó. Giờ ngược lại: nhịp trong CSV được **đo ra từ clip**.
  - Đo bằng `tools/do_nhip_don.tscn`, **đừng gõ tay**. Nó quét vận tốc tâm lưỡi
    kiếm dọc clip, tìm quãng lưỡi bổ TỚI TRƯỚC / XUỐNG DƯỚI qua tầm cao thân
    quái, rồi in ra đúng bốn cột `t_vung` / `t_dam_tu` / `t_dam_den` / `t_hoi`
    cộng `tam_voi`. Đổi một file `.fbx` thì chạy lại và chép đè.
  - **Luật sở hữu clip:** vũ khí nào có clip của chính nó — cột `animation` của
    `moveset.csv` trỏ tới một file có thật — thì clip phát nguyên tốc 1.0×.
    Vũ khí đang ĐI MƯỢN clip của vũ khí khác thì vẫn bị co giãn như cũ, vì nó
    có nhịp riêng mà không có dáng riêng. Hiện cả `assets/model/dong_tac/` là
    clip great sword, tức là của 刃; năm cây kia đang mượn. Thả
    `kiem_nhe_1.fbx` vào thư mục là 剑 tự đứng ra khỏi diện đi mượn, **không
    sửa dòng `.gd` nào** — và đó cũng là luật 1: code không biết vũ khí nào tồn
    tại.
  - **`ThanMoHinh.CAT_CHET` — phần chết bị NHẢY QUA.** Clip mua sẵn dựng cho
    phim: clip Bổ nằm chết dí ở đáy cú bổ hơn nửa giây, rồi khép vòng thêm một
    quãng ở dáng đứng. Nhảy qua chứ không cắt cụt tại đó — đoạn thu tay nằm SAU
    quãng chết, mà thu tay chính là khung hồi đòn, chỗ đối phương phản công.
    Mốc trong bảng này tính bằng giây CỦA CLIP GỐC, còn CSV ghi theo giây ĐÃ
    CẮT; `_clip_tu_don()` là chỗ đổi qua lại.
  - Clip nào có quãng cắt thì **bám hẳn vào đồng hồ của state mỗi khung** —
    thả tự chạy là nó bò thẳng vào đoạn nằm im.
  - Lăn, rút/cất vũ khí cũng lấy số từ clip: `thoi_gian_lan` 0.62 → **1.17s**,
    `T_RUT_VU_KHI` 0.55 → 0.53s, `T_CAT_VU_KHI` 0.65 → **0.33s**.
    **Cái chưa theo clip là mấy cửa sổ CHỒNG LÊN động tác** — `iframe_lan`,
    `cua_so_do_phan`, `cua_so_perfect`, `hoi_lan`. Chúng là con số thiết kế,
    không phải độ dài của một file. Hệ quả phải biết: cú lăn dài gần gấp đôi mà
    i-frame giữ nguyên 0.35s, nên phần bất tử tụt từ 56% xuống 30% quãng lăn —
    lăn cam kết nặng hơn hẳn. Đó là thứ phải chơi thử rồi mới chỉnh.
- **Cú NẠP dùng CHUNG clip với đòn nặng, không có clip riêng.** Nạp không phải
  một động tác khác — nó là ĐÚNG cú vung ấy bị giữ lại ở đỉnh. Cho nó clip
  riêng là bắt người chơi xem hai động tác cho một nhát chém: clip giữ chạy
  xong, rồi clip vung chạy LẠI TỪ ĐẦU và giơ kiếm lên lần thứ hai, trong khi
  hộp đòn đã bật từ đầu cú thứ hai. Đã hỏng đúng vậy — `nap.fbx` hoá ra là một
  clip ĐỨNG THỞ (tay quanh quẩn ở độ cao nghỉ 0.70m suốt 3.5s, kiếm không hề
  giơ lên), nên gồng đòn nặng là thấy nhân vật đứng thở. `DONG_TAC_DON["nap"]`
  giờ trỏ vào `"nang"`, và `_ghim_clip()` ghim con trỏ clip lại đúng chỗ
  `may.t` đang đứng.
  **`_t_nap` đếm từ lúc TỚI ĐỈNH, không từ lúc bấm** — cú vung tay lên không
  phải là nạp, và tính nó vào `T_NAP_TOI_DA` thì vũ khí nào vung càng lâu càng
  nạp được ít. Với 刃 (vung 0.89s trên ngân sách 1.1s) cú gồng gần như không
  tồn tại.
- **`than_khoi.gd` thuần là chỗ để NHÌN — giữ cho đúng như vậy.** Đừng gắn hộp
  đòn (hay bất cứ thứ gì tầng luật đọc) vào khớp bị `dien()` xoay. Đã dính một
  lần: hộp đòn bám theo cánh tay, và một thay đổi thuần trang trí làm cả game
  hết trúng đòn mà không báo lỗi gì. Xem mục bẫy cuối `TIEN_DO.md`.

- **Một cú đánh có NĂM ĐOẠN** (`TrangThaiDanh.giai_doan()`) và bốn cờ
  `bi_khoa()` / `cho_noi()` / `cho_ne()` / `cho_di()`. Mốc lấy từ `moveset.csv`,
  và **`moveset.csv` thì ĐO RA TỪ CLIP** — xem mục "Animation làm chủ" bên dưới.
  Vẫn không gắn mốc vào Call Method Track của file `.fbx`: chỗ giữ sự thật là
  CSV, vì nó đọc được, sửa được và có test canh; animation là chỗ số ấy được
  đo ra, không phải chỗ nó được cất.
  **`ti_le_cua_so_noi` (0.40) phải NHỎ HƠN `ti_le_cua_so_thu` (0.65)** — quãng
  giữa hai mốc là chỗ chỉ nối được combo chứ chưa né được, và nó là cả quyết
  định "đánh tiếp hay rút ra". Bằng nhau thì lăn luôn thắng vì nó an toàn hơn.
  Đoạn 2 kéo dài HƠN khung hộp đòn: phần sau là cú thu chiêu, bỏ nó thì lưỡi
  kiếm nhảy cóc từ cuối nhát này sang đầu nhát sau.
- **Bộ đệm phím giữ ĐÚNG MỘT lệnh** (`_dem_ten` / `_dem_con`), lệnh sau ĐÈ lệnh
  trước. Ba cửa: `ghi_dem()` ghi, `lay_dem()` lấy ra, `xoa_dem()` vứt sạch.
  **`lay_dem()` KHÔNG được gọi `xoa_dem()`** — `xoa_dem()` reset cả hai bộ đếm
  GIỮ phím, mà lệnh `don_nang` bắn ra lúc chạm ngưỡng giữ trong khi ngón tay
  vẫn còn đang giữ, và `TrangThaiDanh.vao()` hỏi đúng cái đang-giữ đó để biết
  có vào cú NẠP hay không. Gộp hai việc là cú nạp chết ngay khi vừa bắt đầu,
  im lặng. Đã dính một lần; dùng `_bo_lenh_cho()` cho việc chỉ-dọn-ô-đệm.
  Đệm bị vứt khi trúng đòn / vỡ thế / chết, và lệnh TỐN THỂ LỰC bị vứt khi cạn
  thể lực (`DEM_TON_THE_LUC`) — nhưng uống bình thì không.
- **`thu_hanh_dong()` là MA TRẬN ƯU TIÊN**, thứ tự xét chính là thứ tự ưu tiên:
  ngắt bắt buộc → phòng thủ → tấn công → vật phẩm → di chuyển. Đừng chèn thứ
  gì vào giữa mà không hỏi bậc nào; bản trước để uống bình ngay sau né, nên
  một cú bấm bình lỡ tay nuốt mất cú bấm đánh.
- **Khựng hình đếm bằng THỜI GIAN THẬT** (`KhungDung`, `Time.get_ticks_msec`).
  `Engine.time_scale` nhân thẳng vào `delta` và vào mọi `SceneTreeTimer`, nên
  hẹn giờ tự gỡ băng bằng chúng là tự khoá mình: càng dừng sâu thì đồng hồ gỡ
  băng càng chạy chậm. Phòng thử tắt nó (`KhungDung.bat = false`) trừ nhóm đi
  kiểm chính nó — bật suốt thì mọi phép chờ sau một cú đánh đều dài ra.
- **Camera bám ở `_physics_process`, KHÔNG ở `_process`.** Nhân vật là
  `CharacterBody3D`: vị trí chỉ đổi ở nhịp vật lý. Camera chạy theo nhịp màn
  hình thì nhân vật GIẬT so với khung hình — và quay màn hình lại thì không
  thấy, vì bản quay lấy mẫu ở nhịp khác. `process_physics_priority = 10` để nó
  chạy SAU `move_and_slide()` trong cùng một tick.
- **Save nằm ở `LuuGame`, ba ô tay + một ô tự lưu TÁCH RIÊNG.** Tự lưu (bia đá,
  hạ boss, thoát menu) không bao giờ đụng ba ô tay — ô tay tồn tại chính vì
  người chơi muốn một mốc máy không sờ vào. File save KHÔNG chứa nội dung game;
  nội dung ở `data/*.csv` và thuộc về bản game, không thuộc về người chơi.
  **`tu_luu()` từ chối khi trong cảnh không có người chơi** — không có nó thì
  bấm Thoát ở màn đầu game ghi đè ô tự lưu bằng một ván rỗng trỏ vào chính cái
  menu, và "Chơi tiếp" lần sau nạp lại đúng cái menu ấy.
- **VÁN MỚI đi qua đúng một cửa: `LuuGame.choi_moi()`.** Nó gọi `ban_moi()` của
  cả bốn autoload giữ trạng thái (`Tui` · `TheGioi` · `DuHanh`, và `TriNho` đi
  theo `Tui`) rồi vào vùng đầu chuỗi. Lý do phải có: **autoload sống qua việc
  đổi cảnh**, nên chơi một ván rồi bấm "Chơi mới" mà thiếu một lời gọi là ván
  mới mang theo đúng mảnh đó của ván cũ — túi đồ, hoặc vốn chữ, hoặc bảy vùng
  vẫn mở sẵn. Không lỗi nào nổ ra. Thêm trường mới vào save thì thêm luôn chỗ
  xoá nó trong `ban_moi()` tương ứng.
- **`run/main_scene` là MÀN ĐẦU GAME**, không phải cảnh chơi. Bước "chạy thử
  game 600 khung hình" của CI vì thế trỏ THẲNG vào `phong_thu.tscn` — chạy 600
  khung hình một cái menu đứng yên thì không bắt được lỗi nào.
- **`man_dau_game.gd` KẾ THỪA `man_cai_dat.gd`**, không chép. Nó lấy nguyên hai
  trang Tuỳ chọn và Điều khiển; ba cửa để nó khác đi là `ten_nhom()`,
  `ten_trang_chinh()` (ở `man_cai_dat.gd`) và `dong_chan()` (ở `man_chung.gd`).
  Màn đầu game **không đóng được** — `dong()` rỗng, vì đóng ra thì phía sau là
  cảnh trống. Nó cũng KHÔNG nằm trong nhóm `man_cai_dat`: bộ kiểm tra và
  `chup_man_hinh` tìm "màn tạm dừng" bằng nhóm đó.

## Phòng thử (`phong_thu.gd`)

- **CHỈNH SỐNG combat, y hệt khuôn HUD.** F5 chạy game → dock Scene tab
  **Remote** → chọn node `NguoiChoi` → kéo số. `toc_do_di` / `toc_do_chay` đã
  export sẵn từ lâu; `he_so_toc_do_danh` (0.2–3.0) và `he_so_toc_do_lan`
  (0.4–2.5) là hai nút mới. Mặc định cả hai đều 1.0 = không đổi gì, nên không
  ảnh hưởng game thật hay bộ test nào.
  `he_so_toc_do_danh` nhân/chia CÙNG một số vào cả bốn mốc t_vung/t_dam_tu/
  t_dam_den/t_hoi (`TrangThaiDanh._moc()`) LẪN tốc độ phát clip
  (`ThanMoHinh._toc_do()`), nên hộp đòn và hình luôn khớp nhau ở MỌI mức tốc
  độ — nhân một chỗ mà quên chia chỗ kia là tái lập đúng lỗi hộp đòn lệch
  hình đã sửa một lần (cú gồng phát hai animation cho một nhát chém). Đây là
  nút "cảm giác combat chung nhanh/chậm cỡ nào" để dò nhanh trong lúc chơi;
  tinh chỉnh RIÊNG từng đòn vẫn đi qua `tools/do_nhip_don.tscn` +
  `data/moveset.csv` như cũ.
  `toc_do_leo` (0.5–6.0 m/s) là tốc độ LEO TƯỜNG. Clip leo tự co giãn theo
  nó (`ThanMoHinh._toc_leo()`), nên kéo lên thì tay chân khua nhanh lên theo —
  không có cảnh trèo vèo vèo mà tay khua thong thả.
  `he_so_toc_do_lan` chỉ đổi tốc độ TRƯỢT (mét/giây) của cú lăn, tách khỏi
  THỜI LƯỢNG (`SoulsLike.thoi_gian_lan`, cũng @export, chỉnh cạnh đó qua node
  `SoulsLike`). Nhân tiện sửa luôn một chỗ trước đây không ai để ý: clip
  `lan.fbx` từng LUÔN phát nguyên tốc 1.0× bất kể `thoi_gian_lan` là bao
  nhiêu — đúng một cách tình cờ vì hai số cùng đo ra 1.17s từ chính clip.
  Giờ `ThanMoHinh._toc_lan()` co giãn clip theo `thoi_gian_lan` mỗi khung, nên
  đổi thời lượng qua Remote thấy ngay trên hình.
- **Hai bù nhìn tập, khác nhau ĐÚNG MỘT CỘT trong `quai.csv`.** Cả hai đứng
  yên tuyệt đối (toc_do_di = toc_do_duoi = 0.0):
    - `bu_nhin` — `tam_danh=2.2` → vào tầm là ĐÁNH TRẢ (đòn `bo_cham`). Dùng
      để cảm nhịp qua lại thật: né, đỡ, parry, vỡ đỡ.
    - `hinh_nom` — `tam_phat_hien=0`, `tam_danh=0` → không bao giờ để ý người
      chơi, không bao giờ đánh trả. `mau=999999` nên không lo đấm chết giữa
      buổi tune. Dùng để đo sát thương/tốc độ đánh thuần, không có gì chen
      vào (né/đỡ/phản đòn của NÓ, không phải của mình).
  `ten_chu` bỏ trống ở cả hai dòng thì `ten_hien()` hiện thẳng tên, không qua
  cơ chế □ — hợp lý cho một món đồ nghề debug, không phải nội dung game thật.
- **Bốn thứ để thử chiều CAO, và chúng cố ý cao khác nhau.** Đặt cạnh nhau thì
  trả lời được "ngưỡng có đúng chỗ không" mà không phải mở code ra đọc:

  | Thứ | Cao | Để làm gì |
  |---|---|---|
  | `ThapLeo` | 5.2m, mặt trên 4×4m | leo được, và có nóc để thử cú TRÈO QUA MÉP |
  | bệ cạnh tháp | 1.2m | DƯỚI `CAO_LEO_TOI_THIEU` ⇒ không bám, bước lên là xong |
  | `TuongThap` | 0.9m | dựng ra để NHẢY qua (dưới đỉnh vòng nhảy ~1.33m) |
  | `TuongBien` | 4m | nhóm `khong_leo` ⇒ không trèo ra ngoài map được |

  `ThapLeo` trước đây là một cây trụ gỗ mảnh (bán kính 0.35m) làm mốc tỉ lệ khi
  soi clip, vì hồi đó chưa có cơ chế leo. Trụ mảnh KHÔNG leo được cho ra hồn:
  mặt cong nên pháp tuyến đổi liên tục, và đỉnh chỉ rộng 0.7m — trèo lên xong
  không đứng nổi. Đổi sang khối vuông là vì vậy.

## Giao diện

- **Tuỳ chọn và phím đi qua TẦNG CHỜ, không áp ngay.** `CaiDat` có hai tầng:
  `_gt` (đang áp dụng, game đọc tầng này) và `_nhap` (đang chờ xác nhận, chỉ màn
  Tuỳ chọn đọc). Màn hình ghi bằng `dat_nhap()` / `dat_phim_nhap()` và đọc bằng
  `lay_nhap()` / `lay_phim_nhap()`; `ap_thay_doi()` đổ xuống và ghi đĩa,
  `bo_thay_doi()` vứt đi. Nút "Áp dụng" bật/tắt theo `co_thay_doi()` — TỐI khi
  chưa đổi, SÁNG khi có. `dat()` vẫn áp NGAY: nó dành cho code gọi thẳng và cho
  bộ kiểm tra, **đừng dùng nó trong màn Tuỳ chọn**.
- **Gán lại phím dựng lại InputMap TỪ BẢNG GỐC.** `CaiDat._phim_goc` chụp sự
  kiện của mọi action lúc khởi động, trước khi áp bất cứ override nào — không có
  bản chụp đó thì "về mặc định" không dựng lại được, vì InputMap lúc ấy đã bị ghi
  đè. Override thay CHỖ ĐẦU và giữ nguyên phím thay thế (`do_phan` có cả E lẫn
  chuột phải). Action `ui_*` bị chừa ra: đó là phím điều hướng giao diện của
  chính Godot, đổi chúng là cách nhanh nhất làm menu không bấm được nữa.
- **Cất / rút vũ khí (phím R) có PHẦN THƯỞNG thật, không phải animation suông.**
  Cất rồi thì `he_so_toc_do()` = 1.30 và `he_so_ton_the_luc()` = 0.55 — một hơi
  chạy dài gần gấp đôi (đo được: 5.42s so với 2.93s). Cái giá: **không đánh
  được**; bấm đánh lúc đang cất thì tự vào `rut_vu_khi` trước và cú bấm nằm chờ
  trong bộ đệm.
  Không có phần thưởng thì không ai bấm và nó thành nút trang trí — đúng loại
  thứ đã bị bỏ đi ở màn tạm dừng (LOGOUT). Muốn tắt: để cả hai hằng số về 1.0.
  Hai state `rut_vu_khi` / `cat_vu_khi` CAM KẾT như mọi hành động khác: lăn
  không cắt được. Cho huỷ giữa chừng thì cất kiếm hết rủi ro, mà hết rủi ro thì
  phần thưởng thành miễn phí.
  Vũ khí chuyển giữa tay và LƯNG (`ThanMoHinh.dat_da_rut()`, bám xương sống).
  Chỉ ẩn nó đi thì thanh kiếm biến mất giữa không khí — người chơi đọc ra là lỗi.
- **Âm thanh đang IM LẶNG có chủ ý.** Bản trước tổng hợp mọi tiếng bằng code;
  chủ dự án chơi thử và bảo chói tới mức nhức đầu, nên phần tổng hợp đã bị xoá
  sạch — **đừng chép lại**. Cái giữ lại là bản kê `AmThanh.TIENG` (danh sách
  việc cho người thu âm) và 18 chỗ gọi `AmThanh.phat()` (đánh dấu đúng khoảnh
  khắc mỗi tiếng phải vang lên). Thêm tiếng thật = thả file vào
  `assets/tieng/<tên>.wav`, tên khớp khoá trong `TIENG`; không sửa dòng code nào.
- **KHÔNG BAO GIỜ gõ tên phím vào một chuỗi.** Mọi dòng chữ nói tên phím đi qua
  `GiaoDien.ten_phim(action)` (một phím) hoặc `ten_moi_phim()` (bảng Điều
  khiển); `TuongTacDuoc.phim()` là lối tắt cho dòng mời trên màn chơi. Đã hỏng
  một lần: phím tương tác dọn từ E sang F mà bốn dòng mời vẫn mời bấm E, nên
  người chơi đứng trên món đồ bấm E và không có gì xảy ra. Không test nào bắt
  được — `"E — nhặt"` vẫn là một chuỗi hợp lệ. Giờ có test so với InputMap.
- **`Minimap_Mask.png` KHÔNG phải khung viền.** Cái tên đánh lừa: nó là một MẶT
  NẠ, xám đều (104,104,104) ở alpha ~0.8 trên TOÀN BỘ mặt đĩa, để làm mask cho
  shader. Vẽ đè lên bản đồ là phủ một lớp voan xám kín mít, và càng phóng to
  càng rõ. Vành minimap vẽ bằng `draw_arc` — sắc ở mọi cỡ, không ăn mất chút
  sáng nào của mặt bản đồ. Có test canh.
- **Font là một CHUỖI, không phải một file.** Không font nào trong
  `assets/font/` có chữ Hán (Cambria 3265 glyph, Palatino 1063, Ringbearer chỉ
  153 và thiếu cả dấu tiếng Việt). `GiaoDien._nap_font()` gắn một `SystemFont`
  chữ Hán vào làm `fallbacks`. **Gỡ phần dự phòng đi là mọi tên món đồ thành ô
  vuông** — mà ô vuông trông y hệt cơ chế `???` của game, nên hỏng kiểu đó
  không ai nhận ra bằng mắt. Có test canh.
- **Theme gán ở root KHÔNG ăn** (đo trong Godot 4.7: `root.theme` nhận resource,
  `has_stylebox` trả true, mà Button vẫn resolve ra StyleBoxFlat mặc định).
  Phải gán thẳng vào một Control tổ tiên: `GiaoDien.ap_theme(node)`. `ManChung`
  đã gọi sẵn cho mọi màn hình — màn mới kế thừa nó là xong; dựng Control ngoài
  ManChung thì phải tự gọi.
- **Hai kiểu nút, tách nhau có lý do.** `Button` trần là kiểu DANH SÁCH (nền
  phẳng, chìm). Vệt cọ đỏ của bản mẫu nằm sau biến thể
  `GiaoDien.NUT_MENU`. Để vệt cọ thành kiểu của mọi Button thì màn hành trang —
  mỗi món đồ một Button — biến thành bức tường vệt sơn. Đã hỏng đúng vậy một
  lần, và **bộ test không thấy; ảnh chụp mới thấy.**
- **Mọi con số bố cục HUD là `@export`, không phải `const`.** HUD vẽ bằng
  `_draw()` nên Godot không hiện nó thành cây node kéo thả được; nhóm export
  trên node `HUD` là cách duy nhất chỉnh tay mà không mở file code. Chỉnh SỐNG:
  F5 chạy game → dock Scene tab **Remote** → chọn `HUD` → kéo số trong
  Inspector → thấy đổi ngay. Ưng thì chép sang tab **Local**, vì sửa ở Remote
  chỉ sống trong phiên chạy đó.
  `Minimap` tạo bằng code nên KHÔNG có mặt trong Inspector — nút vặn của nó
  nằm ở nhóm "Minimap" của HUD và HUD đẩy xuống mỗi khung.
- **Minimap khai bán kính ở CHIỀU CAO THAM CHIẾU 1080**, rồi HUD nhân với
  `_he_so_man()` = cao_thật / 1080. Nhờ vậy nó chiếm đúng một phần màn hình như
  nhau ở mọi cỡ cửa sổ; khai bằng pixel cứng thì kéo cửa sổ nhỏ lại là bản đồ
  nuốt mất góc màn hình. Lấy theo CHIỀU CAO chứ không phải chiều rộng: màn siêu
  rộng thì bề ngang nhảy vọt mà chiều cao gần như không đổi.
  `minimap_tam_quet` KHÔNG co giãn — nó là mét của thế giới, không phải pixel.
- **Ba cụm HUD có nhóm export RIÊNG**, cố ý: "Thanh máu boss", "Khung nhân vật"
  và cụm dưới (Quả cầu + Thanh kỹ năng). Chúng nằm ba góc màn hình khác nhau và
  không ràng buộc gì nhau, nên gộp chung một `le` như bản trước là đổi cái này
  xê dịch cái kia. Khung nhân vật nhân MỌI con số với `khung_nv_co`, **kể cả cỡ
  chữ** — phóng to mà chữ đứng yên thì chữ tràn ra ngoài khung.
- **Dáng nhân vật: có ĐƯỜNG NẠP ANIMATION THẬT, ưu tiên hơn dáng gõ tay.**
  Thả `.fbx` có animation vào `assets/model/dong_tac/`, tên file theo bảng
  `ThanMoHinh.DONG_TAC` / `DONG_TAC_DON` (đọc `assets/model/dong_tac/DOC_TRUOC.md`).
  Trạng thái nào có file thì `dien()` nhường hẳn cho `AnimationPlayer` và
  **không xoay xương chồng lên** — xoay chồng là vừa phát animation vừa bẻ
  khớp, ra thứ tệ hơn cả hai. Trạng thái nào thiếu file thì tự quay về dáng gõ
  tay, nên tải được tới đâu đẹp tới đó.
  Điều kiện DUY NHẤT: file động tác phải CÙNG BỘ XƯƠNG với model nhân vật.
  Bảng `XUONG` nhận ba kiểu tên: Unreal (`Upperarm_L`), Mixamo gốc
  (`mixamorig:LeftArm`) và Mixamo SAU KHI Godot nhập (`mixamorig_LeftArm` —
  trình nhập FBX đổi dấu hai chấm thành gạch dưới). Thiếu kiểu thứ ba thì
  `find_bone()` trả −1 cho MỌI xương, im lặng, và nhân vật đứng nguyên tư thế
  chữ T trượt quanh map.
- **Ba thứ của file động tác phải sửa lúc NẠP, không phải lúc tải về.**
  `_sua_duong()` bẻ đường dẫn rãnh về đúng bộ xương (rãnh Mixamo ghi theo cây
  của chính file đó); `_khu_troi()` trừ phần tự di chuyển của clip (bộ tải về
  chưa tick "In Place" — `chay` tự đi 1.86m một vòng, cộng với
  `move_and_slide()` là trượt như đi trên băng); `_toc_do()` co giãn clip đánh
  cho khớp `moveset.csv`. Cả ba đều IM LẶNG khi hỏng: không lỗi nào nổ, và bộ
  kiểm tra vẫn xanh vì nó đo `velocity` của thân vật lý, thứ không đổi.
  Hai máy đo để soi file trước khi gán: `tools/soi_dong_tac.tscn` (dài / trôi /
  xoay / hở) và `tools/soi_quy_dao.tscn` (quỹ đạo bàn tay, độ cao hông).
  **Chọn file theo SỐ ĐO, đừng theo tên** — `great sword run` là chạy LÙI.
- **Chết thì ĐỢI NGƯỜI CHƠI, không đợi đồng hồ.** `TrangThaiChet` rơi hồn, chọn
  dáng ngã theo hướng đòn chí mạng, rồi nằm im. `ManChet` hiện "BẠN ĐÃ CHẾT" và
  gọi `hoi_sinh()` khi bấm phím — nên độ dài clip chết không còn là ràng buộc.
  `san_sang()` chặn 1.2 giây đầu: người chơi lúc chết thường đang giữ phím.
- **Tốc độ phát clip đi/chạy KHỚP VỚI VẬN TỐC THẬT** (`_toc_theo_van_toc`).
  Clip Mixamo dựng cho người đi ~0.8 m/s, game này đi 4.45 m/s — chênh 5 lần ra
  mặt thành BÀN CHÂN TRƯỢT. `he_so_phat()` chạm đúng `TOC_CLIP_MAX` nghĩa là
  đang bị kẹp, tức là clip quá chậm; có phép thử canh chuyện đó.
- **Giao diện là thứ duy nhất bộ kiểm tra không với tới.** Test đọc được "HUD có
  gắn minimap", không đọc được "quả cầu vẽ đè lên thanh kỹ năng". Sửa gì ở
  `hud.gd` / `minimap.gd` / theme thì **chạy `tools/chup_man_hinh.tscn` và NHÌN**.
- **Toạ độ cụm dưới màn hình tính MỘT chỗ** — `_khung_duoi()`. Cầu, thanh kỹ
  năng, thanh thể lực và thanh máu boss đều canh theo nó. Đổi cỡ quả cầu mà
  thanh kỹ năng không biết thì chúng rời nhau ra, và không test nào bắt được.
- **Màu tô quả cầu KHÁC màu muốn thấy.** Ảnh nước của bộ asset là xám ~0.52 mà
  modulate thì NHÂN, nên `MAU_CAU_MAU` / `MAU_CAU_MP` đã chia sẵn cho 0.52 và
  có thành phần > 1.0. Chép màu từ bảng `MAU_*` xuống là ra màu tối hơn một
  nửa — quả cầu trông như máu khô.
- **Thứ tự vẽ quả cầu: nền trước, nước sau.** `ActionBar_Globe_Background.png`
  là cái ly tối màu và nó ĐỤC — vẽ nó sau cùng là nó phủ kín mực, quả cầu lúc
  nào cũng trông như đang cạn.
- **Minimap tự đặt chỗ mỗi khung**, không dùng anchor preset: preset ghi đè
  offset nên `position` gán một lần lúc dựng bị nuốt, bản đồ lọt ra ngoài mép
  phải màn hình. Đã dính.
- **MP có thật nhưng CHƯA CÓ PHÉP NÀO tiêu nó.** `NguoiChoi.tieu_mp()` là cái
  móc để cắm hệ phép vào; 心 quyết định trần, 智 quyết định sức mạnh phép (hai
  chữ này đã khai trong `Tui.TEN_CHI_SO` từ đầu). Hồi chậm vì chưa có bình
  xanh — có rồi thì hạ `SoulsLike.MP_HOI_MOI_GIAY` về 0.

## Lớp va chạm

| Lớp | Dùng cho |
|---|---|
| 1 | địa hình, tường |
| 2 | thân người chơi |
| 3 | thân quái |

Hộp đòn người chơi bắt lớp 3; hộp đòn quái bắt lớp 2.

## Khi thêm nội dung

| Muốn thêm | Sửa file |
|---|---|
| chữ mới | `data/tu_vung.csv` |
| loại vũ khí mới | `data/nguyen_lieu.csv` (vi_tri=trung_tam) + `data/moveset.csv` |
| khiên mới | `data/nguyen_lieu.csv` với `loai=khien`, `bo_phan=tay_trai` |
| quái mới | `data/quai.csv`, đòn của nó vào `data/don_quai.csv` |
| boss mới | `data/boss.csv` |
| vùng mới | `data/vung.csv` |
| NPC / thoại cốt truyện | `data/npc.csv` |
| tiếng động mới | file `assets/tieng/<tên>.wav` + một dòng trong `AmThanh.TIENG` |

Thêm xong chạy `python tools/kiem_csv.py` — nó bắt được đòn trỏ hụt, vùng không
tồn tại, thang chồng bộ đứt bậc.
