# -*- coding: utf-8 -*-
"""Kiem tra dot nhap tai nguyen cua Godot da chay TRON hay chua.

Chay:  python tools/kiem_nhap.py      (sau khi da chay godot --import)

Thoat ma 0 neu du, 1 neu thieu.

VI SAO CAN: `godot --headless --path . --import` co the DO GIUA CHUNG ma van
de lai mot cai `.godot/` trong coi nhu binh thuong. Da dinh that tren CI —
trinh nhap cua Godot tu do o giua dot nhap nguoi ("Index p_index = -1 is out
of bounds", signal 4), va vi lenh trong workflow co ong dan sang `tee` nen ma
thoat bi nuot, CI di tiep voi mot du an moi nhap duoc vai file.

Hau qua doc ra rat kho: bo kiem tra van chay, nhung may phep thu phan NHIN do
len (khong co font, khong co clip dong tac, khien khong ve ra) — trong y nhu
mot loi gameplay vua lam hong, trong khi that ra khong file nao trong repo sai.

Script nay bien cai do thanh mot cau tra loi thang: MOI file `.import` phai co
du file dich trong `.godot/imported/`. Chay bang Python thuan, khong can Godot.
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
GOC = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

# Duong dan dich nam trong `path=` va `dest_files=[...]` cua file .import.
DICH = re.compile(r'"?(res://\.godot/imported/[^"\s]+)"?')


def duong_that(res):
    return os.path.join(GOC, res[len("res://"):])


def quet():
    thieu = []
    so_file = 0
    so_dich = 0
    for thu_muc, con, files in os.walk(GOC):
        con[:] = [c for c in con if c not in (".godot", ".git")]
        for ten in files:
            if not ten.endswith(".import"):
                continue
            p = os.path.join(thu_muc, ten)
            with open(p, encoding="utf-8") as f:
                noi_dung = f.read()
            # Tai nguyen khai importer="keep"/"skip" thi khong sinh file dich
            # nao — khong co gi de kiem, bo qua.
            dich = sorted(set(DICH.findall(noi_dung)))
            if not dich:
                continue
            so_file += 1
            for d in dich:
                so_dich += 1
                if not os.path.exists(duong_that(d)):
                    thieu.append((os.path.relpath(p, GOC), d))
    return so_file, so_dich, thieu


if __name__ == "__main__":
    if not os.path.isdir(os.path.join(GOC, ".godot", "imported")):
        print("  HONG: chua co .godot/imported/ — dot nhap chua chay lan nao")
        sys.exit(1)

    so_file, so_dich, thieu = quet()
    for p, d in thieu:
        print("  HONG: %s tro toi %s — khong co tren dia" % (p, d))
    print("")
    if thieu:
        print("====== NHAP DO DANG: %d/%d file dich con thieu ======"
              % (len(thieu), so_dich))
        print("Chay lai: godot --headless --path . --import")
        sys.exit(1)
    print("====== nhap du (%d file nguon, %d file dich) ======" % (so_file, so_dich))
