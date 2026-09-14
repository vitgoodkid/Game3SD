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
# kiểm tầng luật — 129 test, thoát mã 1 nếu hỏng
godot --headless --path . tools/kiem_tra.tscn

# chạy thử game 10 giây, bắt lỗi lúc chạy
godot --headless --path . --quit-after 600

# kiểm CSV, KHÔNG cần Godot — chạy được ở bất cứ đâu có Python
python tools/kiem_csv.py
```

GitHub Actions chạy cả ba mỗi lần đẩy code (`.github/workflows/kiem_tra.yml`).
**Không có Godot thì vẫn sửa được CSV và tầng luật** — đẩy lên rồi đọc kết quả
Actions.

Một cái bẫy đã gặp: nếu script của scene chính không biên dịch được, Godot
headless **treo vô hạn** chứ không báo lỗi. Luôn bọc lệnh chạy bằng `timeout`.

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
  he_thong/      autoload có trạng thái: vocab_db, tui, tri_nho, the_gioi
  nhan_vat/      người chơi, camera ba chế độ, khoá mục tiêu, máy trạng thái
    trang_thai/  mỗi state một file
  quai/          quái + state machine riêng
  the_gioi/      phòng thử, (sau này) địa hình và streaming
  giao_dien/     HUD
scenes/          .tscn
tools/           kiểm tra + sinh dữ liệu
```

## Quy ước

- **Máy trạng thái là bắt buộc.** Người chơi lẫn quái. Không viết chuỗi `if` để
  hỏi "đang làm gì". Mỗi state là một node con có `vao()` / `ra()` / `chay(delta)`.
- **Cam kết đòn đánh** cài ở `TrangThaiMay.cho_doi()`. `danh.gd` chặn gần như
  mọi chuyển tiếp — đó là thứ phân biệt souls-like với hack-n-slash. Đừng nới.
- **Mọi con số cảm giác** nằm trong `souls_like.gd` và `data/moveset.csv`.
  Đừng rải hằng số vào state.
- **Ba con số quyết định** (mục 5.2 của bản yêu cầu), có test canh khoảng:
  i-frame lăn 0.30–0.40s · khựng thể lực 0.6–1.0s · hồi đòn nặng 0.7–1.2s.
- Chưa có model nào. Nhân vật và quái dựng bằng khối hộp sinh trong code
  (`than_khoi.gd`, `than_quai.gd`). Thay bằng `.glb` sau: giữ tên điểm gắn
  `GanTayPhai`, nhân vật cao 1.8m, gốc toạ độ dưới chân.

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
| quái mới | `data/quai.csv`, đòn của nó vào `data/don_quai.csv` |
| boss mới | `data/boss.csv` |
| vùng mới | `data/vung.csv` |

Thêm xong chạy `python tools/kiem_csv.py` — nó bắt được đòn trỏ hụt, vùng không
tồn tại, thang chồng bộ đứt bậc.
