# Game3SD

Souls-like 3D học chữ Hán. Godot 4.7, GDScript thuần, giao diện tiếng Việt.

> Combat thuần né / lăn / timing — không chữ nghĩa gì chen vào lúc đánh nhau.
> **Chữ Hán nằm hết ở trang bị**: tên món đồ là một câu tiếng Trung có ngữ pháp
> thật, **đọc được chữ nào thì thấy chỉ số đó**, chữ không đọc được hiện `???`.
> Nâng cấp vũ khí bằng cách chồng bộ thủ (木 → 林 → 森), khắc chế nhau bằng ngũ
> hành, và chữ học được chính là linh hồn — chết thì rơi mất.

## Chơi thử

Cần [Godot 4.7](https://godotengine.org/download) trở lên.

```bash
godot --path .
```

Mở lên là vào **màn hình đầu game**: Chơi tiếp · Chơi mới · Tải ván · Tuỳ chọn ·
Điều khiển · Thoát. "Chơi mới" vào thẳng thị trấn đầu chuỗi và **quên sạch ván
cũ**; "Chơi tiếp" nạp ô mới nhất, kể cả ô tự lưu.

Phòng thử (căn phòng phẳng để tune combat) không còn là chỗ bắt đầu, nhưng vẫn
mở thẳng được:

```bash
godot --path . scenes/the_gioi/phong_thu.tscn
```

| Phím | Việc |
|---|---|
| WASD | đi |
| Chuột | xoay camera |
| Space | **bấm 1 lần = nhảy** · **bấm 2 lần = lăn** |
| Shift | giữ = **chạy** |
| Chuột trái | **bấm** = đòn nhẹ (combo 3 nhát) · **giữ** = đòn nặng → đòn nạp |
| Chuột trái **khi đang ở trên không** | **đòn nhảy** — bấm = nhẹ, giữ = nặng. Mỗi lần rời đất một đòn |
| E / chuột phải | **đỡ phản** · bấm sớm trong cửa sổ hẹp hơn = **đỡ phản hoàn hảo** |
| Q | giơ khiên · đỡ trúng rồi giữ chuột trái = **đòn phản đỡ** |
| R | **cất / rút vũ khí** — cất rồi thì chạy nhanh hơn và tốn ít thể lực hơn |
| F | tương tác |
| J / L | đổi mục tiêu trái / phải |
| K | đổi vũ khí |
| 1 | uống bình |
| Tab / chuột giữa | **khoá mục tiêu** — mặt và camera luôn hướng về con quái, chân đi bốn hướng riêng |
| **F5** | đổi camera: sau lưng → thứ nhất → trước mặt |
| Esc | thả chuột · mở **menu tạm dừng** |

Một nút gánh hai việc thì luôn có một việc phải chờ. Ở Space, **lăn** bắn ra
ngay ở lần bấm thứ hai còn **nhảy** chịu 0.22 giây chờ hết cửa sổ bấm đôi — xếp
vậy vì lăn là nút bấm nhiều nhất trong souls-like, còn nhảy thì hiếm hơn nhiều.

Đỡ phản **không cần khiên**. Khiên vẫn đáng cầm: nó chặn sát thương (40–95 so
với 35 của tay không), đỡ đỡ tốn thể lực, và là điều kiện của **đòn phản đỡ**.

## Combat

Một cú đánh chia **năm đoạn**, và người chơi được làm gì phụ thuộc đang ở đoạn
nào. Mốc lấy từ `moveset.csv` chứ không từ file animation — animation co giãn
theo CSV, không ngược lại.

| Đoạn | Khi nào | Cờ | Làm được gì |
|---|---|---|---|
| 1 Khởi | 0 → `t_dam_tu` | `bi_khoa` | khoá cứng, phím chỉ vào đệm |
| 2 Chạm | → 40% khung hồi | `bi_khoa` | hộp đòn bật rồi thu chiêu, vẫn khoá |
| 3 Nối | → 65% khung hồi | `cho_noi` | **nối combo — chưa né được** |
| 4 Thủ | → hết | `cho_ne` | **lăn / đỡ / đỡ phản cắt ngang** |
| 5 Xong | | `cho_di` | về đứng |

Cửa sổ nối mở **trước** cửa sổ thủ, và quãng ở giữa là chỗ người chơi phải
chọn: đánh tiếp hay rút ra. Mở cùng lúc thì lăn luôn thắng vì nó an toàn hơn.

Nhịp đo được: kiếm một tay **0.42–0.46s** giữa hai nhát, kiếm hai tay
**1.04–1.22s** — cùng khoảng với Elden Ring, và tự khác nhau theo `t_hoi` của
từng vũ khí mà không phải khai riêng dòng nào.

**Bộ đệm phím giữ ĐÚNG MỘT lệnh**, sống 0.35 giây. Lệnh sau **đè** lệnh trước,
nên cái sống sót luôn là ý định mới nhất. Quá hạn mà cửa sổ chưa mở thì lệnh
rơi — đó là lý do người chơi souls hay chết: bấm né lúc mình còn đang khoá
cứng, lệnh nằm chờ, đánh xong mới cuộn, mà lúc đó đòn boss đã hạ xuống rồi.

Đệm bị vứt khi **trúng đòn / vỡ thế / chết**, và lệnh tốn thể lực bị vứt khi
**cạn thể lực** (uống bình thì không — cạn thể lực mà mất luôn cú bấm bình là
phạt hai lần cho một sai lầm).

**Ma trận ưu tiên** khi nhiều thứ cùng đòi chạy:

1. **Ngắt bắt buộc** — trúng đòn, vỡ thế, chết, cạn thể lực
2. **Phòng thủ** — né > đỡ phản
3. **Tấn công** — đòn nặng > đòn nhẹ
4. **Vật phẩm** — uống bình, cất/rút vũ khí
5. **Di chuyển** — nhảy, giơ khiên

**Khựng hình** 0.03–0.08 giây mỗi lần đánh trúng, dài ngắn theo sát thương THỰC
ăn vào. Đánh vào con giáp dày thì cú chạm nghe nhẹ hều, và đó là cách đọc ra
mình đang đánh sai hệ mà không cần nhìn con số nào.

**Đòn nặng (Bổ) không có siêu giáp** — chạm là gãy. Sát thương ×2.95 đổi lấy
0.72 giây không ai chạm được. Chỉnh ở cột `sieu_giap` / `huy_duoc` của
`moveset.csv`, không phải trong code.

## Lưu game

Ba ô tay (`user://saves/slot_1.json`…) và một ô **tự lưu** riêng
(`autosave.json`). Tự lưu chạy khi **nghỉ/bật bia đá**, **hạ boss**, và khi
**thoát bằng menu**; nó không bao giờ đụng vào ba ô tay.

```gdscript
LuuGame.luu("1")        # lưu tay
LuuGame.nap("1")        # nạp
LuuGame.choi_tiep()     # nạp bản MỚI NHẤT, kể cả bản tự lưu
LuuGame.danh_sach()     # tóm tắt mọi ô: thời gian, giờ chơi, vùng
```

File save giữ chỗ đứng / máu / thể lực / MP, thế giới (bia đã bật, boss đã hạ,
vũng hồn, vùng đã tới), túi đồ và trí nhớ chữ. **Không** giữ nội dung game —
cái đó nằm trong `data/*.csv` và là của bản game, không của người chơi.

`LuuGame.choi_moi()` là cửa duy nhất của ván mới: nó gọi `ban_moi()` của cả bốn
autoload giữ trạng thái rồi vào vùng đầu chuỗi. Cần thế vì **autoload sống qua
việc đổi cảnh** — thiếu một lời gọi là ván "mới" mang theo túi đồ hoặc vốn chữ
của ván cũ, và không lỗi nào nổ ra.

Tự lưu **từ chối khi trong cảnh không có người chơi**. Không có luật đó thì bấm
Thoát ở màn đầu game ghi đè ô tự lưu bằng một ván rỗng trỏ vào chính cái menu,
và "Chơi tiếp" lần sau nạp lại đúng cái menu ấy.

## Kiểm tra

```bash
godot --headless --path . tools/kiem_tra.tscn      # 197 test tầng luật
godot --headless --path . tools/thu_vong_lap.tscn  # 360 test vòng lặp + combat + giao diện
godot --headless --path . tools/thu_dau_game.tscn  # 39 test màn đầu game + đổi cảnh
godot --headless --path . tools/thu_the_gioi.tscn  # 67 test thế giới + nội dung
godot --headless --path . scenes/the_gioi/phong_thu.tscn --quit-after 600
python tools/kiem_csv.py                           # kiểm CSV, không cần Godot
```

**663 phép thử**, phải xanh hết trước khi commit. `--quit-after` là bước không
bỏ được: nhiều lỗi của Godot chỉ nổ ra lúc chạy thật (vòng tròn autoload chẳng
hạn), và chúng không làm phép thử nào đỏ. Nó trỏ thẳng vào phòng thử chứ không
dựa vào `main_scene` — `main_scene` giờ là cái menu, chạy 600 khung hình một
cái menu đứng yên thì không bắt được gì.

`thu_dau_game` là bộ duy nhất ghi đĩa (`user://saves/`). Nó cất save của bạn đi
trước và trả lại nguyên vẹn lúc xong.

Kéo code mới về thì chạy `godot --headless --path . --import` TRƯỚC, không thì
Godot chưa biết `class_name` mới và nó **treo** chứ không báo lỗi.

## Giao diện

Bộ asset UI nằm ở `assets/ui/`, font ở `assets/font/`.

| Chỗ | Hiện gì |
|---|---|
| trái trên | khung nhân vật — vũ khí, tải trọng, hồn, thanh **tư thế** |
| giữa trên | thanh máu **boss**, rộng 44% bề ngang |
| phải trên | **minimap** — quái đỏ, boss, NPC xanh, bia đá vàng, bán kính 55m |
| giữa dưới | quả cầu **đỏ** (máu) · thanh kỹ năng 10 ô · quả cầu **xanh** (MP) — một cụm liền, cùng tâm ngang |
| trên thanh kỹ năng | **thanh thể lực** |

Hai quả cầu **kẹp hai đầu thanh kỹ năng** chứ không nằm ở góc màn hình, đúng
như bản mẫu: cụm đó nằm ngay chỗ mắt đã phải nhìn để chọn ô kỹ năng, nên liếc
một cái là đọc luôn máu và MP. Không có con số trong cầu — mức nước chính là
số liệu.

**Esc** mở menu tạm dừng: Tiếp tục / Tuỳ chọn / Điều khiển / Thoát.

Hai trang con đều **phải bấm "Áp dụng"** mới ăn — kéo thanh trượt hay gán phím
mới chỉ ghi vào tầng chờ, game chưa đổi gì. Nút Áp dụng **tối khi chưa có thay
đổi, sáng khi có**, nên nó vừa là nút bấm vừa là câu trả lời cho "mình đã đổi gì
chưa". Rời trang mà chưa bấm thì thay đổi bị vứt.

- **Tuỳ chọn** — âm lượng, độ nhạy chuột, đảo trục Y, ẩn/hiện minimap và chấm ngắm
- **Điều khiển** — bấm vào một phím để **gán lại**; Esc để bỏ. Hàng gộp nhiều
  phím (Đi) chỉ để xem. Gán lại thay phím CHÍNH và giữ nguyên phím thay thế.

Tất cả ghi ra `user://cai_dat.json`, tách hẳn khỏi file save của ván chơi.

Muốn xem giao diện mà không phải chơi:

```bash
godot --path . tools/chup_man_hinh.tscn   # chụp 6 ảnh ra user://, KHÔNG chạy được với --headless
godot --path . tools/chup_tu_the.tscn     # chụp nhân vật ở 17 tư thế
godot --path . tools/chinh_kiem.tscn      # CHỈNH thế cầm vũ khí bằng tay
```

Trong Godot thì mở `tools/chinh_kiem.tscn` rồi bấm **F6** (Run Current Scene).
Mở ra XEM thì nó rỗng — nhân vật, đèn và camera đều dựng lúc chạy. F5 là
chạy scene chính của game, không phải cái này.

Bàn chỉnh, mọi việc đều có hai phím:

| | |
|---|---|
| **Space** | đổi tư thế — đứng · đi · chạy · đòn nhẹ · Bổ · thủ · đã cất |
| **1 / 2 / 3** | đổi thế cầm — trên tay · đi/chạy · sau lưng |
| **W S** hoặc **↑↓** | chọn dòng |
| **A D** hoặc **←→** | giảm / tăng dòng đang chọn |
| **[ ]** | bước nhảy nhỏ · vừa · lớn |
| **Z X** hoặc **lăn chuột** | phóng to / thu nhỏ |
| **giữ chuột trái + rê** | xoay quanh nhân vật |
| **P** | in ra mấy dòng để dán vào `than_mo_hinh.gd` |
| **Esc** | thoát |

Bảng phím hiện ngay trên danh sách ô trong chính màn đó, không phải tra ở đây.

Tư thế và thế cầm **luôn đi cùng nhau** ở màn này — đổi tư thế là nó tự chuyển
sang thế cầm mà tư thế đó dùng. Không có luật đó thì có lúc kéo số mỏi tay mà
thanh kiếm đứng im, vì cái đang sửa không phải cái đang hiện.

Mọi ô `@export` của vũ khí cũng **ăn ngay** khi đổi, nên chỉnh trong tab Remote
của Godot lúc game đang chạy cũng được.

## Nhân vật

Model `assets/model/nhan_vat_chinh.fbx` (rig Mixamo, 58 xương, da `katz.jpg`) với
**43 clip động tác**: 32 clip cầm kiếm và 11 clip **tay không** — cất vũ khí là
đổi hẳn dáng đi, chứ không chỉ đổi con số. Bảng gán clip nào cho trạng thái
nào, kèm lý do từng cái, ở `assets/model/dong_tac/DOC_TRUOC.md`.

**Chết có năm dáng ngã** theo hướng đòn chí mạng — người đổ RA XA cú đánh, và
đòn ≥ 25% máu tối đa thì dùng dáng bị hất tung. Nằm nguyên khung cuối, màn
**BẠN ĐÃ CHẾT** đợi bấm phím chứ không đợi đồng hồ.

**Vũ khí có ba thế cầm** — trên tay, đi/chạy, sau lưng. Cần ba vì thế cầm bám
vào xương bàn tay mà mỗi clip xoay bàn tay một kiểu: clip chạy dựng thanh kiếm
xuyên qua đầu trong khi đúng thế ấy ở dáng đứng lại đẹp.

Thêm động tác: thả `.fbx` cùng bộ xương vào `assets/model/dong_tac/`, đặt tên
theo bảng trong tài liệu đó. Không cần tick "In Place", không cần đúng độ dài —
code tự khử phần trôi và tự co giãn cho khớp `moveset.csv`.

Soi file trước khi gán — **tên Mixamo nói sai ba lần** trong dự án này
(`great sword run` là chạy LÙI, `great sword walk (2)` là đi LÙI,
`great sword slash (5)` là chém lúc đang khom). Chọn clip theo SỐ ĐO:

```bash
godot --headless --path . tools/soi_dong_tac.tscn   # dài / trôi / xoay / hở
godot --headless --path . tools/soi_quy_dao.tscn    # quỹ đạo bàn tay, cao hông
```

## Công cụ

Ba nhóm. Nhóm đầu chạy headless được, hai nhóm sau thì không — chúng cần dựng
hình.

| Công cụ | Trả lời câu hỏi gì |
|---|---|
| `kiem_tra` `thu_vong_lap` `thu_dau_game` `thu_the_gioi` | 663 phép thử — xem mục Kiểm tra |
| `soi_dong_tac` | clip dài bao lâu, tự trôi bao xa, lặp được không |
| `soi_quy_dao` | bàn tay đi đường nào — phân biệt cú bổ với cú chém ngang |
| `soi_combo` | hai nhát liên tiếp cách nhau mấy giây (đo lúc hộp đòn bật) |
| `soi_lan` | cú lăn đi đúng hướng mặt hay ngược |
| `soi_model` | model có xương không, cao bao nhiêu, gốc ở đâu |
| `soi_luoi_kiem` | lưỡi kiếm quét qua khoảng cao nào — có phủ thân con quái không |
| `chup_man_hinh` | 6 ảnh giao diện |
| `chup_tu_the` | nhân vật ở 17 tư thế |
| `chup_model` | bảng ảnh mọi model trong `assets/model/` |
| `chinh_kiem` | **bàn chỉnh thế cầm vũ khí** |

Mấy cái `soi_*` sinh ra vì cùng một lý do: **bộ kiểm tra không nhìn được.** Test
đọc được "state đang là đánh", không đọc được "lưỡi kiếm lướt trên đầu con
quái". Mỗi công cụ ở đây biến một câu hỏi thị giác thành một con số.

## Kiến trúc

```
scripts/
  luat/        tầng LUẬT — không biết gì về Node3D, test được trong một khung hình
  he_thong/    autoload: Tui, TheGioi, TriNho, LuuGame, KhungDung, CaiDat, GiaoDien…
  nhan_vat/    NguoiChoi + máy trạng thái + thân (khối hộp / model thật)
  the_gioi/    địa hình, bia đá, NPC, đồ rơi, du hành giữa vùng
  giao_dien/   HUD, minimap, các màn che, màn BẠN ĐÃ CHẾT
data/          CSV — toàn bộ NỘI DUNG game
assets/        model, động tác, ảnh giao diện, font
tools/         phép thử và công cụ soi
```

Bốn luật của dự án, vi phạm là hỏng thứ không nhìn thấy được:

1. **Không viết cứng chữ Hán trong code.** Nội dung ở `data/*.csv`.
2. **Giao diện, tên hàm, tên biến, ghi chú đều tiếng Việt.**
3. **Không chen chữ nghĩa vào lúc đánh nhau.** Học chữ ở bia đá, không ở trận.
4. **Chữ phai chỉ ăn vào PHẦN CỘNG THÊM**, không bao giờ ăn vào chỉ số gốc —
   người chơi không được yếu đi tới mức không qua nổi chỗ đã qua.

## Tài liệu

- `PROMPT_3D.md` — bản yêu cầu gốc, mọi comment trong code dẫn về đây
- `CLAUDE.md` — quy ước và bản đồ code
- `TIEN_DO.md` — đang ở mốc nào, việc tiếp theo là gì, và **những thứ đã hỏng
  âm thầm** — đọc trước khi đụng vào phần nhìn
- `assets/model/dong_tac/DOC_TRUOC.md` — clip nào dùng cho trạng thái nào, kèm
  lý do từng cái, và cái gì còn thiếu

## Dữ liệu

Toàn bộ nội dung nằm trong `data/*.csv`. Thêm chữ, quái, vùng, vũ khí đều là sửa
CSV — không đụng file `.gd` nào. 1040 chữ Hán, 41 câu ngữ pháp, 39 nguyên liệu,
18 loài quái, 6 boss, 7 vùng, 7 NPC.
