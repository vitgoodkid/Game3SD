# -*- coding: utf-8 -*-
"""Sinh data/ cho ban 3D tu data/ cua ban 2D.

Chay:  python tools/sinh_du_lieu.py <duong_dan_ban_2D>

Nguyen tac (muc 10 cua PROMPT_3D):
  - KHONG doi cot cu. Chi them cot moi, de file cu van doc duoc.
  - Chay lai nhieu lan cho ra cung ket qua (idempotent).

Cho de trong la CO Y: `so_net` va `tan_suat` chi dien cho nhung chu da
tra chac chan. Chu chua co thi de rong, code tu lui ve dung cot `cap`
(xem VocabDB.do_kho_cua). Dien bua 993 dong so net con te hon de trong.
"""
import csv
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
GOC = sys.argv[1] if len(sys.argv) > 1 else r"E:\Gamez\han-tu-fixed"
DICH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")

# --- Thang chong bo thu (muc 4.3) ------------------------------------
# bac 1 -> bac 2 -> bac 3. Chuoi rong nghia la thang do khong co bac giua.
# CANH BAO da ghi trong prompt: khong them thang chu hiem.
THANG = [
    ("\u6728", "\u6797", "\u68ee"),   # moc  -> lam  -> sam
    ("\u4eba", "\u4ece", "\u4f17"),   # nhan -> tung -> chung
    ("\u706b", "\u708e", "\u7131"),   # hoa  -> viem -> diem
    ("\u65e5", "\u660c", "\u6676"),   # nhat -> xuong-> tinh
    ("\u571f", "\u572d", "\u579a"),   # tho  -> khue -> nghieu
    ("\u6c34", "",       "\u6dfc"),   # thuy ->      -> mieu
    ("\u91d1", "",       "\u946b"),   # kim  ->      -> ham
    ("\u77f3", "",       "\u78ca"),   # thach->      -> loi
    ("\u53e3", "\u5415", "\u54c1"),   # khau -> lu   -> pham
]

# --- Ngu hanh (muc 4.4) ----------------------------------------------
# Gan theo bo thu / nghia. Chi ap len chu CO trong CSV; chu khong nam o
# day thi cot ngu_hanh de rong = khong thuoc vong tuong sinh tuong khac.
NGU_HANH = {
    "\u6728": "\u6728\u6797\u68ee\u6811\u82b1\u8349\u7af9\u53f6\u6839\u679d\u672c\u672b\u79be\u7c73"
              "\u68a8\u6843\u82f9\u679c\u83dc\u8336\u836f\u7b77\u684c\u6905\u7eb8\u7b14\u4e66\u5e8a"
              "\u95e8\u690d\u79cd",
    "\u706b": "\u706b\u708e\u7131\u65e5\u660c\u6676\u5149\u660e\u70ed\u70e7\u706f\u7ea2\u590f\u9633"
              "\u6625\u6696\u7167\u6674\u661f",
    "\u571f": "\u571f\u572d\u579a\u77f3\u78ca\u5c71\u5730\u7530\u57ce\u5899\u5854\u5761\u5ca9\u6c99"
              "\u5c18\u9ec4\u58e4\u8c37",
    "\u91d1": "\u91d1\u946b\u5200\u5251\u65a7\u94b1\u94f6\u94c1\u94dc\u9488\u949f\u9505\u94e0\u7532"
              "\u94a5\u955c\u8f66",
    "\u6c34": "\u6c34\u6dfc\u51b0\u96e8\u6cb3\u6d77\u6c5f\u6e56\u96ea\u4e91\u6c41\u9152\u6c64\u6d17"
              "\u6e38\u6cf3\u8239\u9c7c\u51ac\u5bd2\u51b7\u6e7f",
}

# --- Vi tri trong ten mon do (muc 4.2) -------------------------------
# trung_tam : chu quyet dinh moveset, luon dung CUOI ten
# bo_nghia  : chu dung truoc trung tam, cang gan cang manh
VI_TRI = {c: "trung_tam" for c in
          "\u5251\u5200\u5f13\u65a7\u76d4\u7532\u94e0\u5957\u978b\u88e4\u5e3d\u51a0\u836f"}

SO_NET = {
    "\u6728": 4, "\u6797": 8, "\u68ee": 12, "\u4eba": 2, "\u4ece": 4, "\u4f17": 6,
    "\u706b": 4, "\u708e": 8, "\u7131": 12, "\u65e5": 4, "\u660c": 8, "\u6676": 12,
    "\u571f": 3, "\u572d": 6, "\u579a": 9, "\u6c34": 4, "\u6dfc": 12,
    "\u91d1": 8, "\u946b": 24, "\u77f3": 5, "\u78ca": 15,
    "\u53e3": 3, "\u5415": 6, "\u54c1": 9,
    "\u4f53": 7, "\u97e7": 12, "\u529b": 2, "\u5de7": 5, "\u667a": 12, "\u5fc3": 4,
    "\u7532": 5, "\u4e59": 1, "\u4e19": 5, "\u4e01": 2, "\u620a": 5,
    "\u5251": 9, "\u5200": 2, "\u5f13": 3, "\u65a7": 8, "\u76d4": 11, "\u94e0": 13,
    "\u5957": 10, "\u978b": 15, "\u88e4": 12, "\u5e3d": 12, "\u51a0": 9, "\u836f": 9,
    "\u51b0": 6, "\u6bd2": 9, "\u9b54": 20, "\u7ea2": 6, "\u5b9d": 8, "\u6781": 7,
    "\u6700": 12, "\u957f": 4, "\u624b": 4, "\u5934": 5, "\u76ae": 5, "\u6218": 9,
    "\u7bad": 15, "\u73e0": 10,
    "\u5927": 3, "\u5c0f": 3, "\u4e2d": 4, "\u4e0a": 3, "\u4e0b": 3,
    "\u5c71": 3, "\u7530": 5, "\u6708": 4, "\u5929": 4, "\u5e74": 6, "\u96e8": 8,
    "\u4e00": 1, "\u4e8c": 2, "\u4e09": 3, "\u56db": 5, "\u4e94": 4, "\u516d": 4,
    "\u4e03": 2, "\u516b": 2, "\u4e5d": 2, "\u5341": 2,
}

# Bac pho bien: 1 = trong ~500 chu hay dung nhat, 5 = hiem gap.
# KHONG phai thu hang chinh xac -- chi la bac, de xep day chu nao truoc.
TAN_SUAT = {
    1: "\u4eba\u5927\u5c0f\u4e2d\u4e0a\u4e0b\u4e00\u4e8c\u4e09\u56db\u4e94\u516d\u4e03\u516b\u4e5d"
       "\u5341\u65e5\u6708\u6c34\u706b\u6728\u91d1\u571f\u5c71\u5929\u5e74\u624b\u53e3\u5fc3\u529b"
       "\u5973\u5b50\u4e0d\u4e86\u6211\u4f60\u4ed6\u7684\u662f\u5728\u6709\u8fd9\u90a3\u4e2a\u4eec"
       "\u6765\u53bb\u8bf4\u597d\u5f88\u591a\u5c11\u65f6",
    2: "\u7530\u96e8\u77f3\u957f\u7ea2\u5934\u76ae\u6218\u6700\u8f66\u95e8\u4e66\u82b1\u8349\u9c7c"
       "\u7c73\u8336\u9152\u6811\u5149\u660e\u70ed\u51b7\u94f6\u94c1\u5200\u7532",
    3: "\u6797\u4f17\u708e\u660c\u572d\u54c1\u667a\u97e7\u4f53\u5de7\u5b9d\u5251\u5f13\u7bad\u5957"
       "\u978b\u5e3d\u51a0\u836f\u6bd2\u51b0\u9b54\u6781\u76d4\u88e4\u73e0\u94e0\u65a7",
    4: "\u68ee\u4ece\u6676\u579a\u78ca\u5415\u6dfc\u946b\u4e59\u4e19\u4e01\u620a",
    5: "\u7131",
}

# chu, pinyin, pinyin_go, thanh, han_viet, nghia, nghia_khac, bo_thu, nhieu,
# chu_de, cap, vi_du, vi_du_nghia
CHU_MOI = [
    ("\u708e", "y\u00e1n", "yan", 2, "vi\u00eam", "n\u00f3ng r\u1ef1c",
     "vi\u00eam|b\u1ed1c l\u1eeda", "\u706b|\u706b", "\u7131|\u8c08|\u6de1",
     "thien_nhien", 3, "\u708e\u70ed\u7684\u590f\u5929\u3002", "M\u00f9a h\u00e8 n\u00f3ng r\u1ef1c."),
    ("\u7131", "y\u00e0n", "yan", 4, "di\u1ec5m", "l\u1eeda ng\u00f9n ng\u1ee5t",
     "ng\u1ecdn l\u1eeda l\u1edbn", "\u706b|\u706b|\u706b", "",
     "thien_nhien", 3, "\u7131\u662f\u4e09\u4e2a\u706b\u3002", "Di\u1ec5m l\u00e0 ba ch\u1eef ho\u1ea3."),
    ("\u660c", "ch\u0101ng", "chang", 1, "x\u01b0\u01a1ng", "h\u01b0ng th\u1ecbnh",
     "s\u00e1ng s\u1ee7a|ph\u1ed3n vinh", "\u65e5|\u65e5", "\u6676|\u5531",
     "thien_nhien", 3, "\u751f\u610f\u660c\u76db\u3002", "Bu\u00f4n b\u00e1n h\u01b0ng th\u1ecbnh."),
    ("\u6676", "j\u012bng", "jing", 1, "tinh", "tinh th\u1ec3",
     "trong su\u1ed1t|l\u1ea5p l\u00e1nh", "\u65e5|\u65e5|\u65e5", "\u660c",
     "thien_nhien", 3, "\u6c34\u6676\u5f88\u4eae\u3002", "Pha l\u00ea r\u1ea5t s\u00e1ng."),
    ("\u572d", "gu\u012b", "gui", 1, "khu\u00ea", "ng\u1ecdc khu\u00ea",
     "th\u1ebb ng\u1ecdc l\u1ec5 kh\u00ed", "\u571f|\u571f", "\u579a|\u4f73|\u8857",
     "do_vat", 3, "\u572d\u662f\u7389\u5668\u3002", "Khu\u00ea l\u00e0 \u0111\u1ed3 ng\u1ecdc."),
    ("\u579a", "y\u00e1o", "yao", 2, "nghi\u00eau", "n\u00fai \u0111\u1ea5t cao",
     "\u0111\u1ea5t ch\u1ed3ng ch\u1ea5t", "\u571f|\u571f|\u571f", "\u5c27",
     "thien_nhien", 3, "\u579a\u662f\u4e09\u4e2a\u571f\u3002", "Nghi\u00eau l\u00e0 ba ch\u1eef th\u1ed5."),
    ("\u6dfc", "mi\u1ea3o", "miao", 3, "mi\u1ec3u", "m\u00eanh m\u00f4ng",
     "n\u01b0\u1edbc r\u1ed9ng l\u1edbn", "\u6c34|\u6c34|\u6c34", "\u6e3a",
     "thien_nhien", 3, "\u6c34\u6dfc\u6dfc\u3002", "N\u01b0\u1edbc m\u00eanh m\u00f4ng."),
    ("\u946b", "x\u012bn", "xin", 1, "h\u00e2m", "th\u1ecbnh v\u01b0\u1ee3ng",
     "nhi\u1ec1u v\u00e0ng|ph\u00e1t \u0111\u1ea1t", "\u91d1|\u91d1|\u91d1", "",
     "thien_nhien", 3, "\u946b\u662f\u4e09\u4e2a\u91d1\u3002", "H\u00e2m l\u00e0 ba ch\u1eef kim."),
    ("\u5415", "l\u01da", "lv", 3, "l\u1eef", "lu\u1eadt l\u1eef",
     "\u00e2m lu\u1eadt|h\u1ecd L\u1eef", "\u53e3|\u53e3", "\u54c1|\u5bab",
     "hoc", 3, "\u5415\u662f\u97f3\u5f8b\u3002", "L\u1eef l\u00e0 \u00e2m lu\u1eadt."),
    ("\u54c1", "p\u01d0n", "pin", 3, "ph\u1ea9m", "ph\u1ea9m ch\u1ea5t",
     "h\u00e0ng ho\u00e1|n\u1ebfm", "\u53e3|\u53e3|\u53e3", "\u5415",
     "hoc", 2, "\u8fd9\u4e2a\u54c1\u8d28\u5f88\u597d\u3002", "Ph\u1ea9m ch\u1ea5t c\u00e1i n\u00e0y r\u1ea5t t\u1ed1t."),
    ("\u97e7", "r\u00e8n", "ren", 4, "nh\u1eadn", "d\u1ebbo dai",
     "b\u1ec1n b\u1ec9|dai s\u1ee9c", "\u97e6", "\u5203|\u8ba4",
     "tinh_tu", 3, "\u4ed6\u5f88\u575a\u97e7\u3002", "Anh \u1ea5y r\u1ea5t b\u1ec1n b\u1ec9."),
    ("\u667a", "zh\u00ec", "zhi", 4, "tr\u00ed", "tr\u00ed tu\u1ec7",
     "kh\u00f4n ngoan|m\u01b0u tr\u00ed", "\u77e5|\u65e5", "\u77e5",
     "tinh_tu", 2, "\u4ed6\u5f88\u6709\u667a\u6167\u3002", "Anh \u1ea5y r\u1ea5t c\u00f3 tr\u00ed tu\u1ec7."),
    ("\u4e59", "y\u01d0", "yi", 3, "\u1ea5t", "can th\u1ee9 hai",
     "b\u1eadc hai", "\u4e59", "\u7532|\u4e19",
     "so", 3, "\u7532\u4e59\u4e19\u4e01\u3002", "Gi\u00e1p \u1ea5t b\u00ednh \u0111inh."),
    ("\u4e19", "b\u01d0ng", "bing", 3, "b\u00ednh", "can th\u1ee9 ba",
     "b\u1eadc ba", "\u4e00", "\u7532|\u4e59",
     "so", 3, "\u4e19\u7b49\u3002", "H\u1ea1ng b\u00ednh."),
    ("\u4e01", "d\u012bng", "ding", 1, "\u0111inh", "can th\u1ee9 t\u01b0",
     "b\u1eadc b\u1ed1n|\u0111inh \u1ed1c", "\u4e00", "\u7532|\u4e59|\u4e19",
     "so", 3, "\u4eba\u4e01\u5174\u65fa\u3002", "Nh\u00e2n \u0111inh h\u01b0ng v\u01b0\u1ee3ng."),
    ("\u620a", "w\u00f9", "wu", 4, "m\u1eadu", "can th\u1ee9 n\u0103m",
     "b\u1eadc n\u0103m", "\u6208", "\u620c|\u6210",
     "so", 3, "\u620a\u662f\u7b2c\u4e94\u3002", "M\u1eadu l\u00e0 th\u1ee9 n\u0103m."),
    ("\u65a7", "f\u01d4", "fu", 3, "ph\u1ee7", "c\u00e1i r\u00ecu",
     "b\u00faa|r\u00ecu ch\u1eb7t", "\u65a4|\u7236", "\u65a4|\u91dc",
     "do_vat", 2, "\u7528\u65a7\u5934\u780d\u6811\u3002", "D\u00f9ng r\u00ecu ch\u1eb7t c\u00e2y."),
    ("\u76d4", "ku\u012b", "kui", 1, "kh\u00f4i", "m\u0169 gi\u00e1p",
     "m\u0169 s\u1eaft|n\u00f3n b\u1ea3o h\u1ed9", "\u76bf", "\u7532|\u94e0",
     "do_vat", 2, "\u6234\u4e0a\u5934\u76d4\u3002", "\u0110\u1ed9i m\u0169 gi\u00e1p l\u00ean."),
]

COT_CHU_MOI = ["chu", "pinyin", "pinyin_go", "thanh", "han_viet", "nghia",
               "nghia_khac", "bo_thu", "nhieu", "chu_de", "cap", "vi_du", "vi_du_nghia"]


def doc(ten):
    with open(os.path.join(GOC, "data", ten), encoding="utf-8") as f:
        return list(csv.DictReader(f))


def ghi(ten, cot, dong):
    duong = os.path.normpath(os.path.join(DICH, ten))
    with open(duong, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cot, lineterminator="\n")
        w.writeheader()
        for d in dong:
            w.writerow({c: d.get(c, "") for c in cot})
    print("  %-18s %4d dong  %2d cot" % (ten, len(dong), len(cot)))


def hanh_cua(chu):
    for hanh, ds in NGU_HANH.items():
        if chu in ds:
            return hanh
    return ""


def tan_suat_cua(chu):
    for bac, ds in TAN_SUAT.items():
        if chu in ds:
            return bac
    return ""


def lam_tu_vung():
    rows = doc("tu_vung.csv")
    cot_cu = list(rows[0].keys())
    co = set(r["chu"] for r in rows)
    for m in CHU_MOI:
        if m[0] in co:
            continue
        r = dict(zip(COT_CHU_MOI, m))
        r["dong_nghia"] = ""
        r["trai_nghia"] = ""
        rows.append(r)

    bac_cua, goc_cua = {}, {}
    for thang in THANG:
        for i, chu in enumerate(thang):
            if chu:
                bac_cua[chu] = i + 1
                goc_cua[chu] = thang[0]

    for r in rows:
        chu = r["chu"]
        r["so_net"] = SO_NET.get(chu, "")
        r["ngu_hanh"] = hanh_cua(chu)
        r["thang_goc"] = goc_cua.get(chu, "")
        r["thang_bac"] = bac_cua.get(chu, "")
        r["tan_suat"] = tan_suat_cua(chu)

    ghi("tu_vung.csv",
        cot_cu + ["so_net", "ngu_hanh", "thang_goc", "thang_bac", "tan_suat"], rows)
    return set(r["chu"] for r in rows)


def lam_nguyen_lieu():
    rows = doc("nguyen_lieu.csv")
    cot_cu = list(rows[0].keys())
    for r in rows:
        r["ngu_hanh"] = hanh_cua(r["chu"])
        # Chu nao la "nen" trong ban 2D thi chinh la trung tam cua ten mon do.
        r["vi_tri"] = VI_TRI.get(
            r["chu"], "trung_tam" if r.get("khe") == "nen" else "bo_nghia")
    ghi("nguyen_lieu.csv", cot_cu + ["vi_tri", "ngu_hanh"], rows)


def sao_nguyen(ten):
    rows = doc(ten)
    ghi(ten, list(rows[0].keys()), rows)


if __name__ == "__main__":
    print("Sinh data/ tu %s" % GOC)
    co_chu = lam_tu_vung()
    lam_nguyen_lieu()
    for t in ["ngu_phap.csv", "ky_nang.csv", "trang_bi.csv", "khu_vuc.csv"]:
        sao_nguyen(t)
    thieu = [c for t in THANG for c in t if c and c not in co_chu]
    print("Thieu chu thang:", thieu if thieu else "khong")
