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

| Phím | Việc |
|---|---|
| WASD | đi |
| Chuột | xoay camera |
| Space | gõ nhanh = **lăn**, giữ = **chạy** |
| Chuột trái | **bấm** = đòn nhẹ (combo 3 nhát) · **giữ** = đòn nặng → đòn nạp |
| Chuột phải | đỡ phản — **cần khiên ở tay trái** |
| Q | giơ khiên · đỡ trúng rồi giữ chuột trái = **đòn phản đỡ** |
| F | nhảy |
| Chuột giữa / Tab | khoá mục tiêu |
| J / L | đổi mục tiêu trái / phải |
| K | đổi vũ khí |
| 1 | uống bình |
| E | tương tác |
| **F5** | đổi camera: sau lưng → thứ nhất → trước mặt |
| Esc | thả chuột |

## Kiểm tra

```bash
godot --headless --path . tools/kiem_tra.tscn      # 196 test tầng luật
godot --headless --path . tools/thu_vong_lap.tscn  # 123 test vòng lặp + combat
godot --headless --path . --quit-after 600         # chạy thử, bắt lỗi lúc chạy
python tools/kiem_csv.py                           # kiểm CSV, không cần Godot
```

Kéo code mới về thì chạy `godot --headless --path . --import` TRƯỚC, không thì
Godot chưa biết `class_name` mới và nó **treo** chứ không báo lỗi.

## Tài liệu

- `PROMPT_3D.md` — bản yêu cầu gốc, mọi comment trong code dẫn về đây
- `CLAUDE.md` — quy ước và bản đồ code
- `TIEN_DO.md` — đang ở mốc nào, việc tiếp theo là gì

## Dữ liệu

Toàn bộ nội dung nằm trong `data/*.csv`. Thêm chữ, quái, vùng, vũ khí đều là sửa
CSV — không đụng file `.gd` nào. 1011 chữ Hán, 41 câu ngữ pháp, 39 nguyên liệu.
