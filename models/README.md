# models/

Chưa có model nào. Nhân vật và quái đang dựng bằng khối hộp sinh trong code
(`scripts/nhan_vat/than_khoi.gd`, `scripts/quai/than_quai.gd`).

Chuẩn model cần đạt để thay vào đây (mục 11 của `PROMPT_3D.md`):

| Yêu cầu | Chi tiết |
|---|---|
| Định dạng | `.glb` (glTF 2.0) |
| Rig | skeleton humanoid chuẩn — cùng một chuẩn cho mọi nhân vật để dùng chung animation |
| Điểm gắn vũ khí | bone rỗng ở bàn tay phải, đặt tên **`GanTayPhai`** |
| Cỡ | đơn vị mét, nhân vật cao **1.8** — sai cỡ là hỏng toàn bộ tune combat |
| Gốc toạ độ | dưới chân, giữa hai bàn chân |
| Va chạm | không nhét mesh va chạm vào model, code tự sinh `CapsuleShape3D` |

Animation đòn đánh phải chia ba khung: vung tay → gây sát thương → hồi.
Khung sát thương khai trong `data/moveset.csv`, không nằm trong file model.
