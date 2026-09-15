# Game3SD — ghi chú cho agent

Đọc file này trước khi sửa bất cứ thứ gì. `TIEN_DO.md` cho biết đang ở mốc nào.

## Dự án này là gì

Souls-like 3D trong Godot 4.7, GDScript thuần, giao diện tiếng Việt.
Combat **thuần né/lăn/timing** — không có thao tác ngôn ngữ nào trong lúc đánh.
Toàn bộ phần học tiếng Trung nằm ở **tầng trang bị**.

Bản yêu cầu gốc: `PROMPT_3D.md` ở gốc repo. Mọi comment trong code dẫn "mục 4.2",
"mục 5.1"… là dẫn tới file đó.

Kế thừa từ bản 2D (`E:\Gamez\han-tu-fixed` trên máy chủ dự án — **không có trên
cloud**): 993 chữ Hán trong `data/`, và ba script luật `chien_dau.gd`,
`do_hiem.gd`, `crafting_manager.gd`. Mọi thứ đã copy vào repo này rồi; không cần
bản 2D để làm việc nữa.

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
# kiểm tầng luật — 171 test trong một khung hình, thoát mã 1 nếu hỏng
godot --headless --path . tools/kiem_tra.tscn

# kiểm vòng lặp souls + combat — 117 test, nạp phòng thử thật và diễn lại:
# đánh, thể lực, cam kết đòn, i-frame, siêu giáp, đòn phản đỡ, vỡ đỡ, đỡ phản,
# state machine quái, chết, rơi vũng hồn, đứng dậy ở bia, quái sống lại.
# Chạy mất ~45 giây vì phải đợi thật.
godot --headless --path . tools/thu_vong_lap.tscn

# chạy thử game 10 giây, bắt lỗi lúc chạy
godot --headless --path . --quit-after 600

# kiểm CSV, KHÔNG cần Godot — chạy được ở bất cứ đâu có Python
python tools/kiem_csv.py
```

GitHub Actions chạy cả bốn mỗi lần đẩy code (`.github/workflows/kiem_tra.yml`).
**Không có Godot thì vẫn sửa được CSV và tầng luật** — đẩy lên rồi đọc kết quả
Actions.

Bốn cái bẫy đã gặp:

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
  nhan_vat/      người chơi, camera ba chế độ, khoá mục tiêu, máy trạng thái
    trang_thai/  mỗi state một file
  quai/          quái + state machine riêng
  the_gioi/      phòng thử, bia đá, đồ rơi, vũng hồn, vòng hồi sinh
                   tuong_tac_duoc.gd  lớp gốc mọi thứ bấm E được
  giao_dien/     HUD + màn che toàn màn (hành trang, bia đá)
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
- **Chuột trái ra cả hai đòn**: nhả trước `NguoiChoi.NGUONG_GIU_NANG` là đòn
  nhẹ, giữ lâu hơn là đòn nặng (giữ tiếp nữa thành đòn nạp). Chuột phải là đỡ
  phản, **cần khiên ở tay trái** (ER không cho parry tay không). Q giơ khiên;
  đỡ trúng rồi bấm đòn nặng trong `cua_so_phan_do` giây là ra **đòn phản đỡ**.
  Không còn action `don_nang` trong input map.
- **Siêu giáp (hyperarmor)** là cột `sieu_giap` của `moveset.csv`, cộng vào
  `NguoiChoi.the_dung()` chỉ trong khung vung tay rồi TẮT ở khung hồi. Gỡ chỗ
  tắt đi là vũ khí nặng thành bất khả xâm phạm và trận đánh mất hết rủi ro.
- **Ba con số quyết định** (mục 5.2 của bản yêu cầu), có test canh khoảng:
  i-frame lăn 0.30–0.40s · khựng thể lực 0.6–1.0s · hồi đòn nặng 0.7–1.2s.
- Chưa có model nào. Nhân vật và quái dựng bằng khối hộp sinh trong code
  (`than_khoi.gd`, `than_quai.gd`). Thay bằng `.glb` sau: giữ tên điểm gắn
  `GanTayPhai`, nhân vật cao 1.8m, gốc toạ độ dưới chân.
- **`than_khoi.gd` thuần là chỗ để NHÌN — giữ cho đúng như vậy.** Đừng gắn hộp
  đòn (hay bất cứ thứ gì tầng luật đọc) vào khớp bị `dien()` xoay. Đã dính một
  lần: hộp đòn bám theo cánh tay, và một thay đổi thuần trang trí làm cả game
  hết trúng đòn mà không báo lỗi gì. Xem mục bẫy cuối `TIEN_DO.md`.

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

Thêm xong chạy `python tools/kiem_csv.py` — nó bắt được đòn trỏ hụt, vùng không
tồn tại, thang chồng bộ đứt bậc.
