# -*- coding: utf-8 -*-
"""Kiem tra data/*.csv ma khong can Godot.

Chay:  python tools/kiem_csv.py

Thoat ma 0 neu on, 1 neu co cai hong.

Vi sao tach khoi tools/kiem_tra.gd: sua CSV la viec lam duoc tu dien thoai,
khong can mo Godot. Script nay chay bang Python thuan, khong phu thuoc gi, nen
kiem duoc ngay tai cho.

Chi kiem nhung BAT BIEN ma tay nguoi de pha nhat khi them noi dung moi:
  - dong thua/thieu cot (o co dau phay ma quen boc nhay kep)
  - chu trung nhau
  - thang chong bo bi dut bac
  - quai/boss tro toi vung hoac don khong ton tai
"""
import csv
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")

loi = []
canh = []


def doc(ten):
    p = os.path.normpath(os.path.join(D, ten))
    with open(p, encoding="utf-8", newline="") as f:
        r = csv.reader(f)
        cot = next(r)
        rows = []
        for i, dong in enumerate(r, start=2):
            if not dong:
                continue
            if len(dong) != len(cot):
                loi.append("%s dong %d: co %d o, tieu de co %d — o nao co dau "
                           "phay thi phai boc nhay kep" % (ten, i, len(dong), len(cot)))
                continue
            rows.append(dict(zip(cot, dong)))
    return cot, rows


def kiem_tu_vung():
    cot, rows = doc("tu_vung.csv")
    for c in ["chu", "pinyin", "han_viet", "nghia", "bo_thu", "chu_de", "cap",
              "so_net", "ngu_hanh", "thang_goc", "thang_bac", "tan_suat"]:
        if c not in cot:
            loi.append("tu_vung.csv thieu cot '%s'" % c)

    thay = {}
    for r in rows:
        c = r["chu"]
        if c in thay:
            loi.append("tu_vung.csv: chu '%s' bi trung" % c)
        thay[c] = r
        if len(c) != 1:
            canh.append("tu_vung.csv: '%s' khong phai mot ky tu" % c)

    # Thang chong bo: bac 1 phai ton tai, bac phai tang dan, khong dut giua.
    thang = {}
    for r in rows:
        goc = r["thang_goc"].strip()
        if not goc:
            continue
        bac = r["thang_bac"].strip()
        if not bac.isdigit():
            loi.append("tu_vung.csv: '%s' co thang_goc nhung thang_bac rong" % r["chu"])
            continue
        thang.setdefault(goc, {})[int(bac)] = r["chu"]
    for goc, bac in sorted(thang.items()):
        if 1 not in bac:
            loi.append("thang '%s' khong co bac 1" % goc)
        elif bac[1] != goc:
            loi.append("thang '%s' bac 1 phai la chinh no, dang la '%s'" % (goc, bac[1]))
        if max(bac) < 2:
            loi.append("thang '%s' chi co mot bac — khong nang cap duoc" % goc)
    if len(thang) != 9:
        canh.append("co %d thang chong bo (muon 9)" % len(thang))

    # Chu hiem / xuc pham: canh bao muc 4.3 cua ban yeu cau.
    for xau in "奷姦瞑刊當勦孖沝晀":
        if xau in thang:
            loi.append("chu hiem '%s' khong duoc dua vao thang chong bo" % xau)

    hanh_hop_le = set("木火土金水")
    for r in rows:
        h = r["ngu_hanh"].strip()
        if h and h not in hanh_hop_le:
            loi.append("tu_vung.csv: '%s' co ngu_hanh '%s' khong thuoc nam hanh"
                       % (r["chu"], h))
    return thay


def kiem_nguyen_lieu(co_chu):
    cot, rows = doc("nguyen_lieu.csv")
    for c in ["chu", "khe", "cong", "vi_tri", "ngu_hanh"]:
        if c not in cot:
            loi.append("nguyen_lieu.csv thieu cot '%s'" % c)
    co_tt = False
    for r in rows:
        if r["vi_tri"] not in ("trung_tam", "bo_nghia", ""):
            loi.append("nguyen_lieu.csv: '%s' co vi_tri la '%s'" % (r["chu"], r["vi_tri"]))
        if r["vi_tri"] == "trung_tam":
            co_tt = True
    if not co_tt:
        loi.append("nguyen_lieu.csv khong co chu trung_tam nao — khong che duoc mon nao")


def kiem_quai_boss():
    _, vung = doc("vung.csv")
    _, dq = doc("don_quai.csv")
    ma_vung = {v["ma"] for v in vung}
    ten_don = {d["don"] for d in dq}

    for ten_file, cot_mv in [("quai.csv", ["moveset"]),
                             ("boss.csv", ["moveset_1", "moveset_2"])]:
        _, rows = doc(ten_file)
        for r in rows:
            if r["vung"] not in ma_vung:
                loi.append("%s: '%s' tro toi vung '%s' khong ton tai"
                           % (ten_file, r["ma"], r["vung"]))
            for c in cot_mv:
                for don in filter(None, r[c].split("|")):
                    if don not in ten_don:
                        loi.append("%s: '%s' dung don '%s' khong co trong don_quai.csv"
                                   % (ten_file, r["ma"], don))

    # DON PHAI DOC DUOC (muc 5.4): khong don quai nao vung nhanh hon 0.5s.
    for d in dq:
        t = float(d["t_dam_tu"])
        if t < 0.5:
            loi.append("don_quai.csv: '%s' vung trong %.2fs — duoi 0.5s la khong ne kip"
                       % (d["don"], t))
        if float(d["t_dam_den"]) <= t:
            loi.append("don_quai.csv: '%s' co khung sat thuong nguoc" % d["don"])


def kiem_moveset():
    _, rows = doc("moveset.csv")
    theo_chu = {}
    for r in rows:
        theo_chu.setdefault(r["chu"], []).append(r)
        if float(r["t_dam_den"]) <= float(r["t_dam_tu"]):
            loi.append("moveset.csv: %s/%s co khung sat thuong nguoc"
                       % (r["chu"], r["don"]))
    for chu, ds in theo_chu.items():
        don = {d["don"] for d in ds}
        if not any(x.startswith("nhe_") for x in don):
            loi.append("moveset.csv: vu khi '%s' khong co don nhe nao" % chu)
    # Tay khong la moveset lui ve khi khong cam gi — thieu la nhan vat dung im.
    if "拳" not in theo_chu:
        loi.append("moveset.csv thieu moveset tay khong (拳)")


if __name__ == "__main__":
    co_chu = kiem_tu_vung()
    kiem_nguyen_lieu(co_chu)
    kiem_quai_boss()
    kiem_moveset()

    for c in canh:
        print("  canh bao: %s" % c)
    for l in loi:
        print("  HONG: %s" % l)
    print("")
    if loi:
        print("====== %d LOI ======" % len(loi))
        sys.exit(1)
    print("====== data/ on (%d canh bao) ======" % len(canh))
