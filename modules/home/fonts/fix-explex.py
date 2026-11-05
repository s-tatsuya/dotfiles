"""Explex v0.0.3 の macOS での不具合を直す（yuru7/Explex#1）。

1. BoldItalic の m 系グリフに、2 点の off-curve だけからなる退化した輪郭が混入している。
   CoreText はこれを含むグリフを丸ごと描画しないため m が消える。3 点未満の輪郭を削除する。
2. BoldItalic の usWeightClass が 400、macStyle が italic のみになっていて、CoreText からは
   Italic と同じ「400 の斜体」に見える。結果、ただの斜体でも BoldItalic が選ばれてしまう。
   weight 700 / bold+italic に直す。

使い方: fix-explex.py <ttf>...（その場で上書き）
"""

import sys

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import ttProgram


def drop_degenerate_contours(font):
    glyf = font["glyf"]
    fixed = []
    for name in font.getGlyphOrder():
        g = glyf[name]
        if g.isComposite() or g.numberOfContours <= 0:
            continue
        coords, ends, flags = g.getCoordinates(glyf)
        keep, start = [], 0
        for end in ends:
            if end - start + 1 >= 3:
                keep.append((start, end))
            start = end + 1
        if len(keep) == len(ends):
            continue
        new_coords, new_flags, new_ends = [], [], []
        for s, e in keep:
            new_coords.extend(coords[s : e + 1])
            new_flags.extend(flags[s : e + 1])
            new_ends.append(len(new_coords) - 1)
        g.coordinates = type(coords)(new_coords)
        g.flags = type(flags)(new_flags)
        g.endPtsOfContours = new_ends
        g.numberOfContours = len(new_ends)
        # 点の番号がずれるので、そのグリフのヒンティング命令は捨てる。
        g.program = ttProgram.Program()
        g.program.fromBytecode(b"")
        g.recalcBounds(glyf)
        fixed.append(name)
    return fixed


for path in sys.argv[1:]:
    font = TTFont(path, recalcTimestamp=False)
    fixed = drop_degenerate_contours(font)
    sub = font["name"].getDebugName(2) or ""
    if sub.replace(" ", "") == "BoldItalic":
        font["OS/2"].usWeightClass = 700
        font["head"].macStyle |= 0b11
    font.save(path, reorderTables=True)
    print(f"{path}: {len(fixed)} glyphs fixed {fixed[:8]}")
