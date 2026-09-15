# PROMPT — Dựng lại HanTu thành game 3D souls-like

> Bản yêu cầu đầy đủ để đưa cho AI coding agent (hoặc người) bắt tay vào làm.
> Đọc hết mục 0-3 trước khi gõ dòng code đầu tiên.
>
> **Chốt thiết kế:** combat **thuần souls-like** (né, lăn, đánh, timing) —
> KHÔNG có thao tác ngôn ngữ nào trong lúc đánh nhau. Toàn bộ phần học tiếng
> Trung nằm ở **tầng trang bị**.

---

## 0. Cách dùng tài liệu này

Đây **không phải** "port game 2D sang 3D". Đây là **game mới**, thừa kế đúng hai thứ:

1. **Tầng dữ liệu** — 993 chữ Hán trong `data/*.csv`, không sửa cột cũ
2. **Tầng luật** — `chien_dau.gd`, `do_hiem.gd`, `crafting_manager.gd`

Mọi thứ còn lại viết lại từ đầu. **Tạo project Godot mới**, copy sang `data/`
và ba script luật. Đừng cố sửa dần project 2D — `CharacterBody2D`, `TileMapLayer`,
`y_sort`, hệ toạ độ pixel không cái nào dùng lại được.

---

## 1. Hiện trạng

### Dùng lại được

| Tài sản | Số lượng | Ghi chú |
|---|---|---|
| `data/tu_vung.csv` | **993 chữ**, 15 cột | ✅ nguyên vẹn |
| `data/ngu_phap.csv` | 41 câu | ✅ nguyên vẹn |
| `data/ky_nang.csv` | 19 phép | ✅ mở rộng thêm cột |
| `data/nguyen_lieu.csv` | 38 nguyên liệu + 盾 (khiên) = 39 | ✅ giữ nguyên 38 giá trị cũ |
| `data/trang_bi.csv` | 18 công thức | ✅ nguyên vẹn |
| `scripts/chien_dau.gd` | sát thương/giáp/nguyên tố | ✅ port gần nguyên |
| `scripts/do_hiem.gd` | 5 bậc độ hiếm | ✅ nguyên vẹn |
| `scripts/vocab_db.gd` | đọc CSV | ✅ port nguyên |
| `scripts/crafting_manager.gd` | ngữ pháp ghép 4 ô | ✅ port logic, mở rộng nhiều |
| `scripts/battle.gd` | 10 dạng câu hỏi | ✅ đổi vai trò → mục 4.6 |

### Không dùng lại được

- Toàn bộ `assets/` là sprite pixel 2D (~10 MB): 198 animation quái bốn hướng,
  52 animation nhân vật, tile 2D. **Vô nghĩa trong 3D.**
- Map: ảnh 4720×5440 px + 973 hình chữ nhật va chạm + Voronoi 7 khu.
  Tham khảo được **bố cục**, địa hình phải dựng lại.

### Về model — chủ dự án đã có sẵn kho model

Điều này gỡ được nút thắt lớn nhất. Nhưng phải nói rõ một chỗ: **có model không
có nghĩa là có animation**. Souls-like sống chết bằng animation đòn đánh — mỗi đòn
cần khung vung tay đọc được, khung gây sát thương, khung hồi. Mixamo và đa số kho
animation không có bộ này; chúng làm cho hack-n-slash chứ không cho souls.

Xem mục 11 để biết model cần đạt chuẩn gì mới dùng được, và chỗ nào vẫn phải làm tay.

---

## 2. Nguyên tắc bất di bất dịch

1. **KHÔNG hardcode từ vựng / công thức / khu vực trong code.** Thêm nội dung =
   sửa CSV. Code không được biết chữ 火 tồn tại.
2. **Dữ liệu không biết chế độ chơi.** Một chữ giữ nguyên nghĩa ở mọi nơi.
3. **Giao diện tiếng Việt.** Tên biến, tên hàm, comment tiếng Việt như code cũ.
4. **Combat không bị ngôn ngữ chen vào.** Không gõ chữ, không câu hỏi, không
   pause khi đang đánh. Đánh nhau là đánh nhau.

---

## 3. Bài toán trung tâm

Combat thuần souls + học tiếng Trung ở trang bị → nguy cơ rõ ràng: **tiếng Trung
thành lớp sơn**. Kiểu "kiếm 火, +20% sát thương lửa" — đổi 火 thành icon ngọn lửa
thì chẳng mất gì. Thế là thất bại: người chơi chơi 40 tiếng mà không học được chữ nào.

### Phép thử bắt buộc

> **Thay hết chữ Hán trong game bằng icon vô nghĩa. Game có hỏng không?**
>
> - Hỏng → thiết kế đúng
> - Vẫn chơi bình thường → làm lại

Để qua được phép thử này, chữ phải nắm **thông tin** chứ không phải **chỉ số**.
Bốn cơ chế dưới đây làm việc đó. Cả bốn đều nằm ngoài trận đánh.

---

## 4. Tiếng Trung sống ở tầng trang bị

### 4.1 Đọc được mới biết món đồ làm gì — **cơ chế xương sống**

Đây là cái làm game qua được phép thử ở mục 3.

**Không có bảng chỉ số bằng số cho món đồ chưa đọc được.** Món đồ hiện đúng tên
chữ Hán của nó. Chỉ số hiện ra theo đúng những chữ người chơi **đã biết**:

```
Nhặt được:  极冰金剑

Chưa biết chữ nào:
  极冰金剑
  ???  ·  ???  ·  ???            [ Mặc thử ]

Đã biết 冰 (băng) và 剑 (kiếm):
  极冰金剑
  ???  ·  Sát thương băng 34  ·  Kiếm — đòn nhẹ nhanh, đâm được
  còn 2 chữ chưa đọc được       [ Mặc thử ]

Biết hết:
  极冰金剑  (Cực Băng Kim Kiếm)
  极 Cực — bậc cường hoá cao nhất, +40% mọi chỉ số
  冰 Băng — 15% né trọn một đòn
  金 Kim — hệ số theo 力 bậc 甲, khắc 木
  剑 Kiếm — moveset kiếm thẳng
```

Hệ quả:
- **Người chơi mù chữ vẫn chơi được**, nhưng chơi mò. Mặc thử để đoán.
- **Biết chữ = biết trước món đồ làm gì.** Đó là lợi thế thật, cảm nhận được ngay.
- Mỗi chữ học được **mở khoá lại toàn bộ kho đồ cũ** — cảm giác "à hoá ra cái kiếm
  bỏ xó đấy làm được thế này".
- Đây là điều Dark Souls vốn đã làm (giấu thông tin, bắt người chơi tự suy luận),
  chỉ khác là ở đây **chìa khoá giải mã là vốn từ thật**.

**Làm cách nào để biết chữ:** đánh quái rơi bộ thủ → ghép ở bia đá (mục 4.6). Ghép
xong là "biết", chữ đó lộ ra ở mọi món đồ từ đó về sau.

### 4.2 Tên món đồ là một câu — thứ tự chữ đổi thì món đồ đổi

Giữ **ngữ pháp ghép 4 ô** của bản 2D, nhưng đẩy mạnh hơn: game **đọc tên từ trái
sang phải và phân tích như ngữ pháp thật**.

Tiếng Trung: **bổ nghĩa đứng trước, trung tâm đứng sau**. Chữ càng gần trung tâm
thì bổ nghĩa càng chặt. Áp thẳng vào cơ chế:

| Tên | Cách đọc | Kết quả trong game |
|---|---|---|
| 冰金剑 | băng [kim kiếm] | Kiếm kim loại **phủ** băng — Kim là chính, Băng là lớp phủ. Sát thương vật lý cao, băng nhẹ |
| 金冰剑 | kim [băng kiếm] | Kiếm băng **đúc bằng** kim — Băng là chính. Sát thương băng cao, vật lý nhẹ |

Cùng ba chữ, hai món đồ khác nhau. **Người chơi học được trật tự từ tiếng Trung
bằng cách chế đồ**, không phải bằng cách đọc bài giảng.

Quy tắc cài đặt:
- Chữ ở **sát trung tâm nhất** đóng góp **×1.0**
- Lùi ra một bậc: **×0.6**
- Lùi ra hai bậc: **×0.35**
- Chữ trung tâm (剑 甲 弓...) quyết định **moveset**, không bao giờ đổi

→ 13 trung tâm × các tổ hợp bổ nghĩa × **hoán vị thứ tự** = số build thật lớn hơn
4160 tổ hợp của bản 2D rất nhiều.

### 4.3 Thang nâng cấp = chồng bộ thủ

Cơ chế nâng cấp +0 → +10 của souls-like, nhưng bậc nâng cấp **hiện ra ngay trong
mặt chữ**:

```
木  (mộc — cây)      →  林  (lâm — rừng)      →  森  (sâm — rừng rậm)
一cây                  hai cây                   ba cây
gậy gỗ thường          gậy gỗ cứng               gậy gỗ cổ thụ
```

Người chơi **nhìn thấy vũ khí mạnh lên** vì chữ dày đặc thêm. Đây là chữ Hán thật,
không phải bịa — và nó dạy đúng nguyên lý cấu tạo chữ: **bộ thủ chồng lên nhau tạo
nghĩa mạnh hơn**.

Tao đã dò CSV hiện có: **16/17 chữ gốc đã có sẵn**, chỉ cần thêm chữ bậc trên.

**Thang nên dùng** (chữ thông dụng, dạy được):

| Bậc 1 | Bậc 2 | Bậc 3 | Nghĩa | Có trong CSV? |
|---|---|---|---|---|
| 木 | 林 | 森 | cây → rừng → rừng rậm | ✅ đủ cả ba |
| 人 | 从 | 众 | người → đi theo → đám đông | ✅ đủ cả ba |
| 火 | 炎 | 焱 | lửa → nóng rực → lửa ngùn ngụt | thêm 2 chữ |
| 日 | 昌 | 晶 | mặt trời → hưng thịnh → tinh thể | thêm 2 chữ |
| 土 | 圭 | 垚 | đất → ngọc khuê → núi đất | thêm 2 chữ |
| 水 | — | 淼 | nước → mênh mông | thêm 1 chữ |
| 金 | — | 鑫 | vàng → thịnh vượng | thêm 1 chữ |
| 石 | — | 磊 | đá → đá chồng chất | ✅ đủ |
| 口 | 吕 | 品 | miệng → luật lữ → phẩm chất | thêm 2 chữ |

**Cảnh báo — đừng tham:** một số chữ chồng bộ khác (奻 姦 瞐 刕 畾 劦 孖 沝 眀) là
chữ **hiếm, gần như không dùng trong tiếng Trung hiện đại**, và 姦 còn mang nghĩa
xúc phạm. **Không đưa vào.** Game này để dạy tiếng, không phải để khoe chữ lạ.
Chín thang ở bảng trên là đủ cho toàn bộ hệ vũ khí.

### 4.4 Ngũ hành — tương sinh tương khắc

Thay bảng kháng nguyên tố tuỳ tiện bằng **ngũ hành thật**:

```
TƯƠNG SINH (nuôi nhau):   木 → 火 → 土 → 金 → 水 → 木
TƯƠNG KHẮC (chế nhau):    木克土  土克水  水克火  火克金  金克木
```

| Cơ chế | Hiệu ứng |
|---|---|
| Vũ khí **khắc** hành của quái | ×1.5 sát thương |
| Vũ khí **bị khắc** bởi hành của quái | ×0.6 sát thương |
| Vũ khí **sinh** ra hành của quái | quái **hồi máu** — dùng sai là tự hại |
| Hai món trang bị **tương sinh** | cộng hưởng, +10% cả hai |

Người chơi buộc phải thuộc vòng ngũ hành để đổi vũ khí đúng lúc — đó là **kiến
thức văn hoá Trung thật**, dùng được ngoài đời, không phải luật bịa cho game.

Sáu nguyên tố hiện có của bản 2D (火水毒冰石魔) giữ nguyên hiệu ứng, xếp lại:
火/水/石(土) vào ngũ hành, bổ sung 木/金; còn 毒/冰/魔 thành **hiệu ứng phụ** không
thuộc vòng khắc.

### 4.5 Chữ là hồn — tiền tệ souls-like

Chữ Hán của "linh hồn" là **魂 (hún)**. Nên tiền tệ của game chính là chữ:

- Đánh quái rơi **bộ thủ** → ghép thành **chữ** → tiêu chữ để nâng chỉ số
- **Chết → rơi hết chữ chưa tiêu** tại chỗ chết, về nhặt lại được
- **Chết lần nữa trước khi nhặt → mất vĩnh viễn**

Vừa là cơ chế souls kinh điển, vừa là động lực học thật: mất chữ đau hơn mất điểm,
vì đó là thứ vừa học xong.

**Sáu chỉ số cũng là sáu chữ** người chơi học ngay từ giờ đầu:

| Chữ | Pinyin | Hán Việt | Việc |
|---|---|---|---|
| 体 | tǐ | Thể | Máu tối đa |
| 韧 | rèn | Nhận | Thể lực, sức chứa trang bị |
| 力 | lì | Lực | Sát thương vũ khí nặng |
| 巧 | qiǎo | Xảo | Sát thương vũ khí nhẹ, tốc độ |
| 智 | zhì | Trí | Sức mạnh phép |
| 心 | xīn | Tâm | MP, kháng trạng thái |

**Hệ số nhân (scaling) dùng thiên can** thay cho S/A/B/C/D:
甲 (jiǎ) > 乙 (yǐ) > 丙 (bǐng) > 丁 (dīng) > 戊 (wù). Nhìn bảng chỉ số là học luôn.

### 4.6 Bia đá — nơi việc học thật sự diễn ra

Bia đá (bonfire) có bốn việc, **tất cả đều là học**:

| Việc | Nội dung |
|---|---|
| **Ghép chữ** | Ghép bộ thủ nhặt được thành chữ. Ghép xong = "biết chữ" → lộ chỉ số ở mọi món đồ (mục 4.1). Đây chính là lò rèn |
| **Ngồi thiền** | Mở đúng màn hỏi-đáp của bản 2D — **giữ trọn 10 dạng câu hỏi và 41 câu ngữ pháp**. Trả lời đúng → tăng **độ thuần thục** chữ |
| **Khắc chữ** | Lắp/tháo chữ trên vũ khí, đổi thứ tự (mục 4.2), nâng bậc chồng bộ (mục 4.3) |
| **Nâng chỉ số** | Tiêu chữ để tăng 体韧力巧智心 |

**Không bắt buộc ngồi thiền.** Nhưng độ thuần thục cao thì:
- Chỉ số món đồ hiện chi tiết hơn (biết cả `nghia_khac`, ví dụ, từ trái nghĩa)
- Nâng bậc chồng bộ rẻ hơn
- Chống lại cơ chế phai ở 4.7

### 4.7 Trí nhớ phai — chữ quên thì món đồ mờ đi

Đây là chỗ khớp cơ chế với cốt truyện **"chữ bị xoá khỏi thế giới"**.

Game ghi lại với mỗi chữ: học lúc nào, gặp lại lúc nào, trả lời đúng/sai bao nhiêu.
Chữ lâu không gặp thì **phai dần**:

| Độ thuần thục | Món đồ mang chữ đó |
|---|---|
| Thuộc | Hiện đủ chỉ số, hiệu lực 100% |
| Mờ | Chỉ số hiện mờ, **phần cộng thêm giảm còn 70%** |
| Phai | Chữ hiện thành `□`, chỉ số về `???`, **mất toàn bộ phần cộng thêm** |

**Quan trọng — không được ác:** phai chỉ ăn vào **phần cộng thêm của chữ**, không
bao giờ ăn vào **chỉ số gốc của vũ khí**. Người chơi không bao giờ bị yếu đi đến
mức không qua được chỗ đã qua. Ngồi thiền một lượt là hồi lại hết.

Lịch ôn dùng khoảng cách tăng dần (SM-2 rút gọn: 1 → 3 → 7 → 16 → 35 ngày).
Bia đá hiện "**12 chữ sắp phai**". Lưu trong file save, **không** lưu trong CSV.

**Đồ rơi cũng theo lịch ôn**: quái ưu tiên rơi bộ thủ của chữ sắp phai. Người chơi
được đưa đúng thứ mình cần ôn mà không cảm thấy bị bắt học.

---

## 5. Combat — thuần souls-like

**Không có thao tác ngôn ngữ nào ở mục này.** Vào trận là quên hết chữ nghĩa.

### 5.1 Nền tảng bắt buộc

| Cơ chế | Yêu cầu |
|---|---|
| **Thể lực** | Đánh / lăn / nhảy / chạy / đỡ một đòn đều tốn. Đang BẬN thì không hồi; xong việc chờ **~0.4s** rồi hồi nhanh (mô hình Elden Ring). Cạn = không hành động được (không chết ngay) |
| **Lăn né** | i-frame thật ~0.35s giữa cú lăn, **tăng theo 韧**. Theo tải trọng thì gần như KHÔNG đổi (ER cho 13/13/12 khung) — chỗ phạt giáp nặng là **hồi lăn** (×2) và **quãng lăn** |
| **Cam kết đòn đánh** | **Quan trọng nhất.** Đã vung là không huỷ. Đây là thứ phân biệt souls-like với hack-n-slash. Không có nó thì mọi thứ khác vô nghĩa |
| **Khoá mục tiêu** | Chuột giữa / R3. Nhân vật đi vòng quanh mục tiêu. Hất chuột để đổi mục tiêu |
| **Đòn nhẹ / nặng** | **MỘT nút chuột trái**: bấm nhanh = nhẹ (combo 3 nhát), giữ = nặng, giữ tiếp = nạp. Không phải R1/R2 như bản yêu cầu đầu — chủ dự án chốt một nút, và chấp nhận cái giá: đòn nhẹ chỉ bắn ra lúc NHẢ, tức trễ `NguoiChoi.NGUONG_GIU_NANG` (0.18s) |
| **Nạp đòn nặng** | Lết được trong lúc nạp, tốc độ ×`SoulsLike.TOC_DO_KHI_NAP` (0.30). Nhả ra thì nhắm lại theo hướng đang đứng — cam kết đòn tính từ lúc NHẢ, không phải lúc bắt đầu nạp |
| **Siêu giáp** | Cột `sieu_giap` của `moveset.csv`, cộng vào thế đứng chỉ trong khung vung tay rồi TẮT ở khung hồi. Thiếu nó thì vũ khí nặng vô dụng |
| **Đỡ** | Giảm sát thương theo chỉ số khiên, tốn thể lực. Đỡ tới cạn thể lực → **vỡ đỡ**, đứng ngây cho ăn kết liễu |
| **Đòn phản đỡ** | Đỡ trúng xong bấm đòn nặng trong `cua_so_phan_do` (0.6s) → đòn riêng, phá thế gấp 6 lần đòn nhẹ |
| **Đỡ phản (parry)** | Cửa sổ **0.24s** → mở **đòn kết liễu**. **Cần khiên ở tay trái** — tay không không parry được (như ER) |
| **Đòn sau lưng** | Backstab ×2.5-3 |
| **Thế đứng (poise)** | Giáp nặng → không khựng khi trúng đòn nhỏ |
| **Vỡ tư thế** | Đánh dồn vào quái → thanh tư thế vỡ → **đòn kết liễu** (kiểu Sekiro/Elden Ring) |
| **Nhảy + đòn nhảy** | Elden Ring có, dùng để né đòn quét ngang |

> **Con số trong mục này đã được chỉnh theo thực tế chơi.** Chủ dự án chốt:
> khi bản yêu cầu này và Elden Ring đá nhau thì **cảm giác chơi thắng cả hai**.
> Ai đọc mục này về sau đừng "sửa ngược" code về con số cũ — code mới là bản
> đúng, tài liệu chạy theo nó.

### 5.2 Ba con số quyết định cảm giác

Chỉnh được trong Inspector, tune bằng tay ở mốc 2:

- **i-frame của lăn**: 0.30 – 0.40s. Dưới 0.28 là ức chế, trên 0.45 là quá dễ.
  (Elden Ring thật ra chỉ 13 khung ≈ 0.217s — cố ý để rộng hơn ER.)
- **Trễ hồi thể lực**: 0.25 – 0.60s, tính từ lúc hành động KẾT THÚC.
  Bản yêu cầu đầu ghi "khựng 0.6 – 1.0s tính mỗi lần tiêu" và đó là một cái
  bẫy: đặt lại mốc ở chỗ TIÊU thì mỗi nhát chém đẩy lùi mốc hồi thêm một lần,
  ba nhát liên tiếp là thanh thể lực đứng hình. Đã dính một lần, combat khựng
  cứng. Xem `TrangThaiMay.cho_hoi_the_luc()`.
- **Khung hồi của đòn nặng**: 0.45 – 1.2s tuỳ vũ khí (kiếm 0.74 · rìu 0.95 ·
  dao 0.59 · quyền 0.49). Đây là "giá" của việc đánh mạnh.

Thêm một con số thứ tư, không có trong bản đầu nhưng quan trọng ngang ba cái
trên: **`SoulsLike.HS_SAT_THUONG_NGUOI_CHOI`** quy thang điểm của bản 2D sang
thang máu của bản 3D. Không có nó thì một nhát kiếm 10 điểm đập vào con quái
300 máu — đo thật là 48–50 nhát mới hạ nổi một con thường. Quái thường nên
chết trong 4–8 đòn nhẹ.

### 5.3 Công thức — dùng lại `chien_dau.gd`

Port gần nguyên văn. Giữ đúng quy tắc phân tầng đã ghi ở đầu file đó:

> *"Cái này còn nghĩa gì không nếu không có câu hỏi nào?"*

Bản 3D có ba tầng (đã có tiền lệ `hanh_dong.gd`):

| Tầng | File | Nội dung |
|---|---|---|
| `ChienDau` | `chien_dau.gd` | Sát thương, giáp, ngũ hành, nguyên tố — **dùng chung** |
| `SoulsLike` | `souls_like.gd` (mới) | Thể lực, i-frame, poise, tư thế, parry — đo bằng giây |
| `battle.gd` | giữ nguyên | Chỉ có nghĩa khi đang có câu hỏi (ngồi thiền) |

Trạng thái độc/băng đổi từ "ăn ngay" sang **tích dần thành thanh, đầy mới bùng** —
đúng chuẩn souls.

### 5.4 Quái và boss

- **Đòn phải đọc được.** Mỗi đòn có khung vung tay rõ ràng, nhìn là biết né hướng
  nào. Đây là linh hồn của souls-like, quan trọng hơn mọi thứ khác.
- 18 loài hiện có → mỗi loài tối thiểu: idle, đi, chạy, 2-3 đòn, trúng đòn, chết
- **Boss hai giai đoạn**: dưới 50% máu đổi moveset
- **Quái mang hành** (ngũ hành) — người chơi đổi vũ khí theo, mục 4.4

---

## 6. Trang bị

### 6.1 Tải trọng

| Mức | Kiểu lăn | Ngưỡng |
|---|---|---|
| Nhẹ | lăn xa, nhiều i-frame | < 30% |
| Vừa | lăn thường | 30-70% |
| Nặng | lăn ngắn | 70-100% |
| Quá tải | **lết**, không chạy được | > 100% |

Sức chứa tăng theo **韧 (Nhận)**.

### 6.2 Khe

| Khe | Số |
|---|---|
| Vũ khí tay phải | 3 (đổi trong trận) |
| Tay trái (khiên / vũ khí phụ / bùa) | 3 |
| Giáp | 4 — đầu, thân, tay, chân |
| Nhẫn / ngọc bội | 4 |
| **Chữ mang theo** | 7 — **giữ đúng 7 ô của bản 2D** |
| Bình thuốc | hồi máu / hồi MP, **chung quota** kiểu Elden Ring |

### 6.3 Nâng cấp

- **5 bậc độ hiếm** của `do_hiem.gd` giữ nguyên
- Nâng bậc = **chồng bộ thủ** (mục 4.3), tốn bộ thủ cùng loại
- **Đổi khắc chữ được** — tháo chữ ra lắp chữ khác, đổi cả thứ tự. Cái này vá đúng
  món nợ ghi trong `TONG_QUAN.md` mục 10 ("chưa có đường nâng cấp món đã chế")

---

## 7. Map — nên làm kiểu gì

Chủ dự án hỏi "cái nào AI làm được tốt nhất, đẹp nhất". Trả lời thẳng.

### 7.1 AI làm tốt cái gì, dở cái gì

| Việc | AI làm được? |
|---|---|
| Địa hình heightmap + xói mòn + rải cây cỏ theo luật | ✅ **Rất tốt.** Thuần thuật toán |
| Ánh sáng, sương mù, màu phim, hậu kỳ | ✅ **Rất tốt.** Và đây là 80% của chữ "đẹp" |
| Shader nhận diện riêng (vùng bị xoá, nước, băng) | ✅ **Rất tốt** |
| Lắp phòng/hành lang từ **bộ kit modular** có lưới snap | 🟡 Khá — nếu kit tốt và có luật rõ |
| Thiết kế màn souls-like: đường tắt, mai phục, vòng lặp | ❌ **Dở.** Cần người, cần chơi thử, cần trực giác không gian |
| Đặt từng mesh bằng toạ độ trong file text | ❌ **Rất dở.** Ra không gian vô hồn |

### 7.2 Khuyến nghị: **lai — hoang dã sinh tự động, chốt chặn dựng tay**

Đúng cấu trúc Elden Ring, và trùng khít với bảng trên:

```
VÙNG HOANG DÃ (70% diện tích)          CHỐT CHẶN (30% diện tích, 80% thời gian chơi)
─────────────────────────────          ──────────────────────────────────────────
Địa hình sinh tự động                   Dựng tay trong editor
Rải cây/đá/tàn tích theo luật           Đường tắt, thang máy, cửa khoá
Quái lang thang, miniboss               Boss, kho báu lớn, bia đá chính
AI làm trọn gói                         Người thiết kế, AI hỗ trợ lắp kit
```

Người chơi đi qua vùng hoang dã để tới chốt chặn. Vùng hoang dã rộng — thoả yêu cầu
"map rộng đầy đủ" — mà không tốn công thiết kế từng mét vuông.

### 7.3 Công cụ cụ thể

| Việc | Dùng gì |
|---|---|
| Địa hình | **Terrain3D** (addon Godot 4) — clipmap, chịu được map lớn, có sculpt trong editor |
| Rải vật thể | **ProtonScatter** (addon) — rải theo luật, theo độ dốc, theo cao độ |
| Sinh heightmap | Script Python/GDScript: noise + mô phỏng xói mòn thuỷ lực. Xuất PNG 16-bit nạp vào Terrain3D |
| Nav cho quái | `NavigationRegion3D`, bake theo từng ô |
| Che khuất | `OccluderInstance3D` — bắt buộc với map liên thông nhiều tầng |

### 7.4 Nơi đầu tư để "đẹp" — ánh sáng, không phải hình khối

Đây là lời khuyên quan trọng nhất của mục này. Một quả đồi đơn giản + ánh sáng tốt
**đẹp hơn hẳn** một quả đồi chi tiết + ánh sáng mặc định. Và ánh sáng là thứ AI
chỉnh được bằng số, hình khối thì không.

Godot 4 Forward+ bật hết:
- **SDFGI** (chiếu sáng gián tiếp động) — thứ tạo ra chiều sâu
- **Sương mù thể tích** — tạo lớp xa gần, che rìa map, cực hợp không khí souls
- **SSAO + SSIL**, **Glow**, **tonemap ACES**
- **WorldEnvironment riêng cho từng vùng** — 7 khu, 7 bảng màu. Đây là cách rẻ nhất
  để bảy vùng trông khác hẳn nhau

### 7.5 Nhận diện hình ảnh: "chữ bị xoá khỏi thế giới"

Cốt truyện đã thống nhất từ bản 2D, và nó cho **ngôn ngữ hình ảnh rẻ mà mạnh**:

> Nơi nào mất tên thì mất luôn hình dạng.

- Vùng bị xoá: vật thể **trắng bệch, mất vân, mờ dần ở rìa**, như giấy chưa viết
- Khôi phục tên ở bia đá → **màu và chi tiết trở lại**
- Quái vô danh: thanh máu hiện `□□`, hạ rồi mới lộ tên

Vừa là art direction, vừa **giảm khối lượng art thật** — vùng chưa khôi phục dùng
shader trắng, không cần texture đầy đủ. Và nó nối thẳng vào cơ chế phai ở mục 4.7.

### 7.6 Quy mô — đừng rộng vô ích

Dark Souls 1 đi xuyên map mất ~15 phút. Mục tiêu:

- Mỗi khu: **8-15 phút** đi bộ nếu không đánh
- **3-5 bia đá**, **1 boss + 1-2 miniboss** mỗi khu
- Tổng **20-30 giờ** lượt đầu

Rộng hơn mà không có nội dung thì chỉ là đất trống — lỗi bản 2D đã mắc một lần
(xem ghi chú "map trống" trong `world.gd`).

---

## 8. Camera — kiểu Minecraft

Phím **F5** xoay vòng ba chế độ:

1. **Thứ ba, sau lưng** (mặc định) — lệch vai
2. **Thứ nhất** — trong mắt, không thấy thân
3. **Thứ ba, trước mặt** — nhìn vào mặt nhân vật

### Xử lý xung đột với souls-like

| Vấn đề | Cách giải |
|---|---|
| Khoá mục tiêu ở góc nhìn thứ nhất | Vẫn khoá, camera **không tự xoay**; **mũi tên rìa màn hình** chỉ hướng mục tiêu |
| Không thấy đòn từ sau lưng ở F1 | **Chỉ báo hướng bị đánh** (vệt đỏ rìa màn hình). Bắt buộc |
| Khó đọc tầm với vũ khí ở F1 | **Chấm ngắm mờ** ở đúng tầm với vũ khí đang cầm |
| Backstab / kết liễu ở F1 | **Tự chuyển tạm sang thứ ba** lúc diễn hoạt ảnh, xong trả về |
| Lăn ở F1 gây chóng mặt | Cài đặt "giảm xoay camera khi lăn", bật mặc định |

Góc nhìn thứ ba dùng `SpringArm3D` — bắt buộc, không thì camera xuyên tường.

---

## 9. Kiến trúc kỹ thuật

- **Godot 4.x**, GDScript thuần
- **Renderer: Forward+** (không phải GL Compatibility như bản 2D)
- **Physics: Jolt** (đã bật sẵn trong `project.godot` cũ)

### Autoload

Giữ tên của bản 2D để người quen code cũ đọc được ngay:

| Tên | Việc | Trạng thái |
|---|---|---|
| `VocabDB` | Đọc CSV | port nguyên |
| `Tui` | Túi đồ, trang bị, lưu/nạp | mở rộng nhiều |
| `ChienDau` | Sát thương, giáp, ngũ hành | port + thêm ngũ hành |
| `DoHiem` | 5 bậc độ hiếm | port nguyên |
| `SoulsLike` | Thể lực, i-frame, poise, tư thế | **mới** |
| `TriNho` | Độ thuần thục, lịch ôn, phai chữ | **mới** (mục 4.7) |
| `TheGioi` | Streaming ô, bia đá, hồi sinh quái | **mới** |

### Cây thư mục

```
data/            # CSV — copy nguyên, thêm cột
scripts/
  he_thong/      # autoload
  nhan_vat/      # di chuyển, combat, camera
  quai/          # AI, state machine, boss
  the_gioi/      # streaming, bia đá, cửa
  giao_dien/     # HUD, hành trang, khắc chữ, ngồi thiền
  luat/          # chien_dau.gd, do_hiem.gd, souls_like.gd
scenes/          # nhan_vat/ quai/ the_gioi/ giao_dien/ vung/
models/          # .glb
```

### State machine — bắt buộc

Cả người chơi lẫn quái phải dùng state machine tường minh, **không** phải chuỗi
`if` như `player.gd` cũ. Souls-like có quá nhiều trạng thái loại trừ nhau: đứng,
đi, chạy, lăn, đánh 1/2/3, đánh nặng, nạp, đỡ, parry, trúng đòn, vỡ thế, uống
thuốc, kết liễu, chết.

Mỗi state là một node con có `vao()`, `ra()`, `chay(delta)`. Đầu tư bắt buộc ở
mốc 1 — không làm thì mốc 5 phải viết lại hết.

### Hitbox

- Vũ khí: `Area3D` gắn vào **xương bàn tay**, bật/tắt theo **animation track**
  (không phải đồng hồ đếm như bản 2D — 3D phải khớp hình)
- Hurtbox: nhiều `Area3D` (đầu / thân / chân) để làm được đòn chí mạng

---

## 10. Dữ liệu — cột cần thêm

**Không đổi cột cũ.** Chỉ thêm, để file cũ vẫn đọc được.

### `tu_vung.csv`

| Cột | Ý nghĩa |
|---|---|
| `so_net` | Số nét — xếp độ khó |
| `ngu_hanh` | 木火土金水 hoặc rỗng — cho mục 4.4 |
| `thang_goc` | Chữ gốc nếu đây là bậc chồng bộ (林 → 木) |
| `thang_bac` | Bậc 1/2/3 trong thang |
| `tan_suat` | Thứ hạng phổ biến thật — xếp chữ nào dạy trước |

### `nguyen_lieu.csv`

| Cột | Ý nghĩa |
|---|---|
| `vi_tri` | Chữ này đứng ở tầng bổ nghĩa nào được (mục 4.2) |
| `ngu_hanh` | Hành của chữ |

### File mới

| File | Nội dung |
|---|---|
| `boss.csv` | Khu, máu, moveset, hành, phần thưởng |
| `vung.csv` | 7 vùng: bia đá, cửa nối, điều kiện mở, bảng màu môi trường |
| `npc.csv` | NPC và thoại (cốt truyện "chữ bị xoá") |
| `moveset.csv` | Mỗi loại vũ khí: tên animation, khung gây sát thương, thể lực tốn |

---

## 11. Model — chuẩn cần đạt

Chủ dự án có sẵn kho model. Để dùng được trong Godot 4, mỗi model cần:

### Nhân vật và quái

| Yêu cầu | Chi tiết |
|---|---|
| Định dạng | **.glb** (glTF 2.0). FBX phải convert, Blender làm được hàng loạt |
| Rig | Skeleton chuẩn **humanoid** (Mixamo hoặc Rigify). Cùng một chuẩn cho mọi nhân vật → **animation dùng chung được** |
| Điểm gắn vũ khí | Bone rỗng ở bàn tay phải/trái, đặt tên thống nhất (`gan_vukhi_phai`) |
| Cỡ | Đơn vị mét, nhân vật cao ~1.8. **Sai cỡ là hỏng toàn bộ tune combat** |
| Gốc toạ độ | Dưới chân, giữa hai bàn chân, hướng mặt về **−Z** (chuẩn Godot) |
| Va chạm | Không nhét mesh va chạm trong model — code sinh `CapsuleShape3D` |

### Animation — chỗ thật sự thiếu

Đây là chỗ kho model **không** giải quyết được. Souls-like cần mỗi đòn chia ba khung:

```
│─── vung tay ───│── gây sát thương ──│──── hồi ────│
   người chơi        hitbox bật          không huỷ được
   nhìn và né                            → cửa sổ phản đòn
```

Animation từ Mixamo/kho chung thường **vung tay quá nhanh** (làm cho hack-n-slash).
Phải chỉnh lại timing trong Blender hoặc Godot AnimationPlayer. Kế hoạch:

- **Mốc 1-4**: dùng animation có sẵn, chỉnh timing bằng cách **kéo giãn keyframe**
  trong Godot. Xấu nhưng chơi được, đủ để tune cảm giác
- **Mốc 5+**: làm lại animation đòn đánh cho boss và các moveset chính

`moveset.csv` ở mục 10 tồn tại chính vì việc này: khung sát thương khai trong CSV,
chỉnh không cần sửa code.

---

## 12. Lộ trình — 7 mốc

Mỗi mốc phải **chơi được** mới sang mốc sau.

| # | Mốc | Nội dung | Xong là thấy gì |
|---|---|---|---|
| **1** | Đi lại | Nhân vật 3D, state machine, camera F5 ba chế độ, một phòng thử | Chạy quanh phòng, đổi góc nhìn |
| **2** | **Combat lõi** | Thể lực, lăn i-frame, đòn nhẹ/nặng, cam kết đòn, khoá mục tiêu, 1 quái biết đánh trả | **Điểm quyết định — đánh nhau có ra chất souls không** |
| **3** | Trang bị + đọc chữ | Khe trang bị, tải trọng, cơ chế `???` của mục 4.1, nối `VocabDB` | Nhặt đồ, thấy chữ lạ, muốn học |
| **4** | Vòng lặp souls | Bia đá, chết rơi chữ, nhặt lại, hồi sinh quái, ghép chữ, ngồi thiền | Một vùng chơi trọn vẹn |
| **5** | Ngũ hành + boss | Tương sinh tương khắc, thang chồng bộ, 1 boss hai giai đoạn | Build có chiều sâu |
| **6** | Thế giới | 7 vùng, Terrain3D, streaming, đường tắt, shader "vùng bị xoá" | Game đủ dài |
| **7** | Nội dung & đánh bóng | 18 loài, NPC, cốt truyện, lịch ôn, âm thanh, animation làm lại | Bản phát hành |

**Mốc 2 là điểm quyết định.** Combat không đã thì mọi thứ sau đó vô nghĩa. Dành
thời gian tune ba con số ở mục 5.2 cho tới khi thấy sướng rồi mới đi tiếp.

---

## 13. Những gì KHÔNG làm

- ❌ Không multiplayer/PvP trong bảy mốc này
- ❌ Không thế giới voxel phá huỷ được (xem mục 15)
- ❌ Không hệ crafting mới — dùng lại ngữ pháp bổ nghĩa đã có
- ❌ Không class nhân vật — build quyết định bằng trang bị và chỉ số
- ❌ Không thao tác ngôn ngữ trong trận đánh (đã chốt)
- ❌ Không dạy chữ hiếm chỉ vì nó hợp cơ chế (mục 4.3)
- ❌ Không dịch sang tiếng Anh giai đoạn này

---

## 14. Ý tưởng phát triển thêm

### Rất đáng làm

**1. Lời nhắn người chơi — chỉ viết bằng chữ đã học**

Souls game cho để lại lời nhắn ghép từ mẫu câu có sẵn. Ở đây người chơi chỉ được
dùng **chữ mình đã biết**. Tự nhiên thành bài tập đặt câu; người mới đọc lời nhắn
của người giỏi thì gặp chữ mới trong ngữ cảnh. Không cần server — gói sẵn vài trăm
lời nhắn dựng sẵn cũng đủ.

**2. Vũ khí có ký ức — mang tên người đã dùng nó**

Mỗi vũ khí huyền thoại có **một câu mô tả bằng tiếng Trung**, đọc được bao nhiêu
tuỳ vốn từ. Chữ nào chưa biết hiện `□`. Đây là chỗ kể chuyện mà **phần thưởng của
việc học là hiểu được cốt truyện** — không cần cơ chế gì thêm.

**3. Âm hồn chữ — quái từng hạ triệu lại được**

Hạ đủ số lần một loài → thu "hồn" nó → triệu ra đánh cùng. Hồn mạnh theo **độ thuần
thục của chữ gắn với nó**. Học nhiều → bạn đồng hành khoẻ.

**4. Tân thủ nghịch chuyển (NG+) tăng cấp từ vựng**

Lượt 2 không phải quái nhiều máu hơn, mà **chữ khó hơn**: tên món đồ chuyển từ chữ
cấp 1 sang cấp 2 rồi cấp 3. Cùng một game, độ khó ngôn ngữ leo thang.

**5. Tên quái hiện trên đầu bằng chữ Hán**

Đi qua là thấy, lặp lại thụ động. Học mà không bị bắt học.

### Đáng làm, khó hơn

**6. Âm thanh — boss gầm tên nó**

Dự án hiện **chưa có âm thanh gì cả**. Làm mảng này là mở hướng mới hoàn toàn, và
thêm được chiều **nghe** mà game đang thiếu hẳn.

**7. Ba phái học — 形 / 音 / 义**

形 (Hình — qua mặt chữ), 音 (Âm — qua phát âm), 义 (Nghĩa — qua nghĩa). Vào phái nào
thì đồ rơi và câu hỏi thiên về mặt đó. Cho chơi lại nhiều lần.

**8. Boss ẩn: 无 (Vô)**

Boss cuối ẩn, không tên, vì nó chính là **sự trống rỗng**. Không có hành nên không
khắc được bằng ngũ hành; vũ khí càng nhiều chữ càng yếu trước nó. Cách thắng là
**cởi hết trang bị khắc chữ** — một câu đố về chính cơ chế của game.

### Sau này

- Chế độ chụp ảnh khung thư pháp
- Boss rush + xếp hạng
- Báo cáo học tập: chữ đã thuộc, chữ hay sai, thời gian chơi
- Mod: nạp bộ CSV riêng để học ngôn ngữ khác (Nhật, Hàn)

---

## 15. Cần chốt trước khi bắt đầu

**1. "Kiểu Minecraft" là camera hay thế giới?** Tài liệu này hiểu là **camera**
(F5, thứ ba ↔ thứ nhất), thế giới là địa hình 3D bình thường. Nếu ý là **thế giới
khối vuông voxel đào được** thì đổi rất nhiều — phải làm hệ chunk, greedy meshing,
và combat souls trên địa hình voxel là bài toán khác hẳn. **Mặc định: camera.**

**2. Kho model có những gì?** Cần biết: người? quái? vũ khí? địa hình? Đã rig chưa,
rig theo chuẩn nào? Câu này quyết định mốc 1 mất một tuần hay một tháng.

**3. Bản 2D còn sống không?** Giữ song song hay bản 3D thay hẳn? Giữ song song thì
`data/` nên tách thành submodule dùng chung.

**4. Ai chơi thử?** Souls-like chỉ tune được bằng cách chơi. Cần ít nhất một người
chơi lại mốc 2 nhiều lần và nói thẳng "chưa đã".

---

## 16. Tóm tắt một câu

> Một game souls-like 3D trong Godot 4 — combat thuần né/lăn/timing, không chữ
> nghĩa gì chen vào. **Chữ Hán nằm hết ở trang bị**: tên món đồ là một câu tiếng
> Trung có ngữ pháp thật, **đọc được chữ nào thì thấy chỉ số đó**, chữ không đọc
> được hiện `???`. Nâng cấp vũ khí bằng cách chồng bộ thủ (木 → 林 → 森), khắc chế
> nhau bằng ngũ hành, và chữ học được chính là linh hồn — chết thì rơi mất. Thế
> giới đang mất dần tên gọi và phai thành màu trắng; người chơi đi khôi phục từng
> cái tên một, và mỗi cái tên khôi phục được là một chữ học thật.
