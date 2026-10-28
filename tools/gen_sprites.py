#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《一念成仙》像素素材生成器 · 剑风传奇风格（v0.24.0）

风格要点（参考三浦建太郎《剑风传奇》）：
1. 写实壮硕比例：头身比约 1:2.5，宽肩厚躯
2. 密集排线：单向 + 交叉斜线做阴影，不用柔和渐变
3. 高对比：近黑底色 + 1px 亮边（rim light）
4. 暗调配色：整体压暗，血红作为强点缀
5. 粗粝轮廓：外轮廓不规则，有破损感

运行：python3 tools/gen_sprites.py
旧版（水墨Q版）保留在 tools/gen_sprites_ink_q.py
"""

import os
import math
import random
from PIL import Image, ImageDraw

random.seed(20261028)

# ============================================================
# 调色板：暗黑高对比
# ============================================================

BLACK = (0x08, 0x08, 0x0A, 255)      # 极黑（最深）
DARK = (0x16, 0x16, 0x1A, 255)       # 暗部
MID = (0x28, 0x28, 0x2E, 255)        # 中间调
GREY = (0x42, 0x42, 0x4A, 255)       # 灰
LIGHT = (0x6A, 0x6A, 0x74, 255)      # 亮灰
HILITE = (0xA8, 0xA8, 0xB4, 255)     # 高光
WHITE = (0xE4, 0xE4, 0xEC, 255)      # 纯白高光

BLOOD = (0x8B, 0x0F, 0x12, 255)      # 血红（主点缀）
BLOOD_B = (0xC4, 0x1E, 0x22, 255)    # 鲜血（亮）

# 各类实体的暗调识别色（压低明度，保证战斗中能分辨）
A_PLAYER = (0x3A, 0x4A, 0x52, 255)   # 钢青
A_WOLF = (0x3D, 0x2A, 0x3F, 255)     # 暗紫
A_BIRD = (0x4A, 0x3D, 0x18, 255)     # 暗金
A_GOLEM = (0x4A, 0x2A, 0x18, 255)    # 暗赭
A_CULT = (0x2E, 0x26, 0x40, 255)     # 暗靛
A_LEECH = (0x4A, 0x12, 0x15, 255)    # 暗绛
A_SPIDER = (0x3F, 0x24, 0x10, 255)   # 暗褐
A_HEALER = (0x1F, 0x35, 0x24, 255)   # 暗苍
A_BOSS = (0x5C, 0x0A, 0x0C, 255)     # 血赤

TRANSPARENT = (0, 0, 0, 0)


def shade(c, f):
    """按系数明暗调整"""
    return (
        max(0, min(255, int(c[0] * f))),
        max(0, min(255, int(c[1] * f))),
        max(0, min(255, int(c[2] * f))),
        c[3],
    )


# ============================================================
# 排线（剑风的核心视觉语言）
# ============================================================

def hatch(img, box, color, density=4, direction=1, only_dark=True):
    """单向斜线排线。density 越大越稀（4 中等，6 稀疏）。
    only_dark=True 时只压暗已有较暗像素，避免把亮部糊成噪点。
    """
    x0, y0, x1, y1 = box
    px = img.load()
    for y in range(max(0, y0), min(img.height, y1)):
        for x in range(max(0, x0), min(img.width, x1)):
            if px[x, y][3] == 0:
                continue
            if only_dark and px[x, y][0] > 0x55:
                continue          # 亮部不排线
            v = (x * direction + y) % density
            if v == 0:
                px[x, y] = color


def cross_hatch(img, box, color, density=6):
    """交叉排线：两个方向叠加。density 越大越稀，默认 6 保证结构可辨。"""
    hatch(img, box, color, density, 1)
    hatch(img, box, color, density, -1)


def rim_light(img, light_color=HILITE):
    """轮廓光：给不透明区域的左上边缘加 1px 亮线（光源在左上）"""
    px = img.load()
    w, h = img.size
    marks = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            up_empty = (y == 0) or (px[x, y - 1][3] == 0)
            left_empty = (x == 0) or (px[x - 1, y][3] == 0)
            if up_empty or left_empty:
                marks.append((x, y))
    for (x, y) in marks:
        px[x, y] = light_color


def ink_edge(img, base_color=BLACK):
    """外轮廓加深：紧贴实体的外圈像素涂深色，形成粗粝边缘"""
    px = img.load()
    w, h = img.size
    marks = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] != 0:
                    marks.append((x, y))
                    break
    for (x, y) in marks:
        px[x, y] = base_color


def rough_edge(img, amount=0.25):
    """边缘破损：随机挖掉一些边缘像素，制造粗粝感"""
    px = img.load()
    w, h = img.size
    to_clear = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0:
                    edge = True
                    break
            if edge and random.random() < amount:
                to_clear.append((x, y))
    for (x, y) in to_clear:
        px[x, y] = TRANSPARENT


# ============================================================
# 写实比例人形（头身比 1:2.5）
# ============================================================

def humanoid(img, draw, cx, top_y, total_h, body_w, robe_color,
             head_ratio=0.28, shoulder_w=1.0):
    """画写实比例人形，返回 (头中心y, 头半径)。"""
    head_h = max(4, int(total_h * head_ratio))
    head_r = max(2, head_h // 2)
    head_cy = top_y + head_r

    body_top = top_y + head_h
    body_h = total_h - head_h

    # ---- 头：略扁的椭圆（写实人脸不是正圆）----
    draw.ellipse(
        [cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r + 1],
        fill=shade(robe_color, 1.15),
    )

    # ---- 躯干：肩部最宽，向下收窄 ----
    for i in range(body_h):
        t = i / max(1, body_h - 1)
        if t < 0.15:
            half = int(body_w * shoulder_w * (0.72 + t / 0.15 * 0.28))
        else:
            half = int(body_w * shoulder_w * (1.0 - (t - 0.15) / 0.85 * 0.42))
        half = max(2, half)
        y = body_top + i
        for x in range(cx - half, cx + half + 1):
            if not (0 <= x < img.width and 0 <= y < img.height):
                continue
            rel = (x - (cx - half)) / max(1, 2 * half)
            if rel < 0.25:
                c = shade(robe_color, 1.25)
            elif rel < 0.55:
                c = robe_color
            elif rel < 0.8:
                c = shade(robe_color, 0.65)
            else:
                c = shade(robe_color, 0.4)
            img.putpixel((x, y), c)

    return head_cy, head_r


def face_guts(img, cx, head_cy, head_r, eye_color=WHITE, blood=False):
    """剑风式面孔：暗部 + 单点眼神光，五官几乎不可见。"""
    px = img.load()
    for y in range(head_cy - head_r, head_cy + head_r + 1):
        for x in range(cx - head_r, cx + head_r + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                if px[x, y][3] != 0:
                    px[x, y] = shade(px[x, y], 0.55)

    # 眼睛：1px 亮点（黑暗中一点凶光）
    eye_y = head_cy - max(0, head_r // 3)
    for sign in (-1, 1):
        ex = cx + sign * max(1, head_r // 2)
        if 0 <= ex < img.width and 0 <= eye_y < img.height:
            img.putpixel((ex, eye_y), eye_color)

    if blood:
        bx = cx + head_r // 2
        for dy in range(0, head_r):
            if 0 <= bx < img.width and 0 <= head_cy + dy < img.height:
                if img.getpixel((bx, head_cy + dy))[3] != 0:
                    img.putpixel((bx, head_cy + dy), BLOOD)


# ============================================================
# 各实体
# ============================================================

def make_player():
    """玩家：写实壮硕剑士，暗袍，背负大剑，血围巾。"""
    S = 34
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 31
    top_y = 2
    head_cy, head_r = humanoid(img, draw, cx, top_y, total_h, 6, A_PLAYER,
                               head_ratio=0.29, shoulder_w=1.15)

    face_guts(img, cx, head_cy, head_r)

    # 头发：短硬
    for y in range(head_cy - head_r, head_cy - head_r // 2):
        for x in range(cx - head_r, cx + head_r + 1):
            if (x - cx) ** 2 + (y - head_cy) ** 2 <= (head_r + 1) ** 2:
                if 0 <= x < S and 0 <= y < S:
                    img.putpixel((x, y), BLACK)

    # 背负大剑：斜插在背后右侧，不穿脸
    sword_top = (cx + head_r + 3, top_y + 4)
    sword_bot = (cx + head_r + 8, top_y + 26)
    draw.line([sword_top, sword_bot], fill=LIGHT, width=2)
    draw.line([sword_top, sword_bot], fill=WHITE, width=1)
    # 剑格
    draw.line([(cx + head_r + 1, top_y + 7), (cx + head_r + 5, top_y + 5)], fill=DARK, width=2)

    # 血围巾
    for x in range(cx - head_r - 1, cx + head_r + 2):
        y = head_cy + head_r
        if 0 <= x < S and 0 <= y < S:
            if img.getpixel((x, y))[3] != 0:
                img.putpixel((x, y), BLOOD)
    draw.line([(cx + head_r, head_cy + head_r), (cx + head_r + 4, head_cy + head_r + 5)],
              fill=BLOOD, width=1)

    # 排线阴影
    cross_hatch(img, (cx, top_y + 12, S, top_y + 30), BLACK, 6)
    hatch(img, (0, top_y + 20, S, top_y + 31), BLACK, 4, 1)

    rough_edge(img, 0.18)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_wolf():
    """妖狼：写实四足兽，暗紫，红眼。结构优先，排线只做点缀。"""
    S = 46
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 2

    # ---- 躯干：横向椭圆（狼的体态是长条）----
    draw.ellipse([cx - 14, cy - 6, cx + 10, cy + 6], fill=A_WOLF)

    # ---- 颈部 + 头：向右前方 ----
    draw.polygon([
        (cx + 4, cy - 7), (cx + 12, cy - 9), (cx + 13, cy + 2),
        (cx + 6, cy + 5),
    ], fill=shade(A_WOLF, 1.1))
    # 头（楔形）
    draw.polygon([
        (cx + 10, cy - 9), (cx + 18, cy - 6), (cx + 19, cy - 1),
        (cx + 13, cy + 2), (cx + 9, cy - 3),
    ], fill=shade(A_WOLF, 1.25))
    # 吻部（前端突出）
    draw.polygon([
        (cx + 17, cy - 5), (cx + 21, cy - 3), (cx + 20, cy + 1), (cx + 16, cy),
    ], fill=shade(A_WOLF, 1.35))

    # ---- 耳朵（两只尖三角）----
    draw.polygon([(cx + 10, cy - 9), (cx + 11, cy - 15), (cx + 14, cy - 8)], fill=DARK)
    draw.polygon([(cx + 14, cy - 8), (cx + 16, cy - 14), (cx + 18, cy - 6)], fill=DARK)

    # ---- 四条腿：细长，间距拉开，脚掌略宽 ----
    legs = [(-12, 9), (-7, 10), (2, 10), (7, 9)]
    for dx, length in legs:
        x0 = cx + dx
        # 大腿（粗）
        draw.rectangle([x0 - 2, cy + 4, x0 + 1, cy + 7], fill=shade(A_WOLF, 0.75))
        # 小腿（细）
        draw.rectangle([x0 - 1, cy + 7, x0 + 1, cy + 4 + length], fill=shade(A_WOLF, 0.6))
        # 脚掌
        draw.rectangle([x0 - 2, cy + 4 + length, x0 + 2, cy + 5 + length], fill=DARK)

    # ---- 尾巴（向下垂，粗）----
    draw.polygon([
        (cx - 14, cy - 3), (cx - 20, cy + 2), (cx - 21, cy + 8), (cx - 16, cy + 4),
    ], fill=shade(A_WOLF, 0.7))

    # ---- 红眼（两点）----
    img.putpixel((cx + 14, cy - 5), BLOOD_B)
    img.putpixel((cx + 15, cy - 5), BLOOD_B)
    # 獠牙
    img.putpixel((cx + 19, cy + 1), WHITE)

    # ---- 排线：只压背部与腹侧的暗部，密度 6 稀疏 ----
    cross_hatch(img, (cx - 12, cy + 1, cx + 8, cy + 6), BLACK, 6)
    # 脊背高光（不压暗）
    hatch(img, (cx - 10, cy - 6, cx + 4, cy - 3), HILITE, 5, -1, False)

    rough_edge(img, 0.15)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_bird():
    """疾风雀：暗金猛禽，展翼。"""
    S = 34
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 5, cy - 5, cx + 6, cy + 6], fill=A_BIRD)
    draw.polygon([(cx - 3, cy - 3), (cx - 16, cy - 9), (cx - 5, cy + 3)], fill=shade(A_BIRD, 0.85))
    draw.polygon([(cx + 4, cy - 3), (cx + 16, cy - 10), (cx + 6, cy + 3)], fill=shade(A_BIRD, 0.7))
    draw.ellipse([cx - 4, cy - 11, cx + 4, cy - 3], fill=shade(A_BIRD, 1.2))
    # 钩喙
    draw.polygon([(cx + 3, cy - 8), (cx + 8, cy - 6), (cx + 3, cy - 4)], fill=LIGHT)
    # 尾羽
    draw.polygon([(cx - 3, cy + 5), (cx + 3, cy + 5), (cx, cy + 13)], fill=shade(A_BIRD, 0.6))
    draw.line([(cx - 3, cy + 5), (cx, cy + 13)], fill=DARK)
    draw.line([(cx + 3, cy + 5), (cx, cy + 13)], fill=DARK)

    img.putpixel((cx + 2, cy - 8), BLOOD_B)

    hatch(img, (cx - 16, cy - 6, cx - 4, cy + 4), BLACK, 4, 1)
    hatch(img, (cx + 5, cy - 7, cx + 16, cy + 3), BLACK, 4, -1)
    img.putpixel((cx - 15, cy - 9), HILITE)
    img.putpixel((cx + 15, cy - 10), HILITE)

    rough_edge(img, 0.22)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_golem():
    """岩甲兽：巨大岩块躯体，裂隙透光。"""
    S = 70
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 4

    pts = [
        (cx - 22, cy + 10), (cx - 24, cy - 6), (cx - 16, cy - 18),
        (cx - 2, cy - 22), (cx + 14, cy - 18), (cx + 23, cy - 5),
        (cx + 22, cy + 12), (cx + 8, cy + 18), (cx - 10, cy + 17),
    ]
    draw.polygon(pts, fill=A_GOLEM)
    draw.polygon([
        (cx - 9, cy - 20), (cx + 9, cy - 20), (cx + 11, cy - 10), (cx - 11, cy - 10),
    ], fill=shade(A_GOLEM, 1.25))
    for dx in (-16, -6, 6, 16):
        draw.rectangle([cx + dx - 3, cy + 15, cx + dx + 3, cy + 25], fill=shade(A_GOLEM, 0.55))

    # 裂纹透光
    cracks = [
        [(cx - 16, cy - 14), (cx - 6, cy - 6), (cx - 8, cy + 6)],
        [(cx + 4, cy - 16), (cx + 10, cy - 4), (cx + 6, cy + 10)],
        [(cx - 2, cy + 2), (cx + 4, cy + 8)],
    ]
    for c in cracks:
        for i in range(len(c) - 1):
            draw.line([c[i], c[i + 1]], fill=BLOOD_B, width=1)

    for sign in (-1, 1):
        img.putpixel((cx + sign * 4, cy - 15), BLOOD_B)

    cross_hatch(img, (cx, cy - 18, cx + 24, cy + 18), BLACK, 6)
    hatch(img, (cx - 22, cy + 6, cx + 22, cy + 18), BLACK, 4, 1)
    hatch(img, (cx - 20, cy - 16, cx - 4, cy - 6), HILITE, 5, -1, False)

    rough_edge(img, 0.24)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_cultivator():
    """邪修：兜帽暗袍，手持符箓。"""
    S = 40
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 36
    top_y = 2
    head_cy, head_r = humanoid(img, draw, cx, top_y, total_h, 6, A_CULT,
                               head_ratio=0.27, shoulder_w=1.0)

    draw.polygon([
        (cx - head_r - 3, head_cy + 3), (cx + head_r + 3, head_cy + 3),
        (cx + head_r, head_cy - head_r - 3), (cx - head_r, head_cy - head_r - 3),
    ], fill=shade(A_CULT, 0.8))
    draw.ellipse([cx - head_r, head_cy - 2, cx + head_r, head_cy + head_r], fill=BLACK)
    for sign in (-1, 1):
        img.putpixel((cx + sign * 2, head_cy + 1), BLOOD_B)

    # 符箓
    fx, fy = cx + head_r + 4, head_cy + 8
    draw.rectangle([fx, fy, fx + 3, fy + 5], fill=A_BIRD)
    draw.rectangle([fx, fy, fx + 3, fy + 5], outline=LIGHT)
    img.putpixel((fx + 1, fy + 2), BLOOD_B)

    cross_hatch(img, (cx, head_cy + 6, S, S), BLACK, 6)
    hatch(img, (0, head_cy + 14, S, S), BLACK, 4, 1)

    rough_edge(img, 0.2)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_leech():
    """血蛭：暗绛环节软体，湿滑高光。"""
    S = 48
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    segs = [
        (cx - 16, cy + 2, 8, 6),
        (cx - 8, cy - 1, 9, 7),
        (cx + 1, cy - 3, 9, 8),
        (cx + 10, cy - 1, 8, 7),
        (cx + 17, cy + 3, 6, 5),
    ]
    for (sx, sy, rw, rh) in segs:
        draw.ellipse([sx - rw, sy - rh, sx + rw, sy + rh], fill=A_LEECH)

    for (sx, sy, rw, rh) in segs[:-1]:
        draw.arc([sx - rw, sy - rh, sx + rw, sy + rh], 250, 290, fill=BLACK)

    draw.ellipse([cx + 17, cy, cx + 24, cy + 8], fill=shade(A_LEECH, 1.3))
    draw.ellipse([cx + 19, cy + 2, cx + 22, cy + 6], fill=BLACK)
    for i in range(3):
        img.putpixel((cx + 20 + i, cy + 3), WHITE)

    for (sx, sy, rw, rh) in segs:
        img.putpixel((sx, sy - rh + 1), HILITE)
        img.putpixel((sx - 1, sy - rh + 2), LIGHT)

    cross_hatch(img, (cx - 20, cy + 2, cx + 22, cy + 9), BLACK, 6)

    rough_edge(img, 0.18)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_spider():
    """噬魂蛛：暗褐球腹，长足带刺。"""
    S = 38
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 1

    draw.ellipse([cx - 8, cy - 3, cx + 8, cy + 11], fill=A_SPIDER)
    draw.ellipse([cx - 6, cy - 8, cx + 6, cy + 2], fill=shade(A_SPIDER, 1.25))

    for sign in (-1, 1):
        for i, (dy, ext) in enumerate([(-5, 12), (-2, 14), (2, 13), (5, 10)]):
            x0 = cx + sign * 5
            y0 = cy + dy
            x1 = cx + sign * (ext - 2)
            y1 = cy + dy - 4
            x2 = cx + sign * ext
            y2 = cy + dy + 4
            draw.line([(x0, y0), (x1, y1)], fill=DARK, width=1)
            draw.line([(x1, y1), (x2, y2)], fill=BLACK, width=1)
            img.putpixel((x1, y1 - 1), LIGHT)

    for dx, dy in [(-3, -6), (3, -6), (-1, -8), (1, -8)]:
        img.putpixel((cx + dx, cy + dy), BLOOD_B)

    draw.ellipse([cx - 4, cy + 1, cx + 4, cy + 7], outline=BLOOD, width=1)

    cross_hatch(img, (cx - 8, cy + 3, cx + 8, cy + 11), BLACK, 6)

    rough_edge(img, 0.22)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_healer():
    """尸巫：枯瘦长袍，持杖，兜帽。"""
    S = 46
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 41
    top_y = 2
    head_cy, head_r = humanoid(img, draw, cx, top_y, total_h, 5, A_HEALER,
                               head_ratio=0.25, shoulder_w=0.9)

    draw.polygon([
        (cx - head_r - 3, head_cy + 4), (cx + head_r + 3, head_cy + 4),
        (cx + head_r - 1, head_cy - head_r - 4), (cx - head_r + 1, head_cy - head_r - 4),
    ], fill=shade(A_HEALER, 0.7))
    draw.ellipse([cx - head_r, head_cy - 1, cx + head_r, head_cy + head_r], fill=BLACK)
    for sign in (-1, 1):
        img.putpixel((cx + sign * 2, head_cy + 2), (0x6F, 0xD8, 0xA0, 255))

    # 法杖
    sx = cx - head_r - 6
    draw.line([(sx, top_y + 8), (sx, S - 2)], fill=DARK, width=2)
    draw.line([(sx, top_y + 8), (sx, S - 2)], fill=GREY, width=1)
    draw.ellipse([sx - 3, top_y + 2, sx + 3, top_y + 9], fill=(0x2E, 0x6B, 0x3A, 255))
    img.putpixel((sx, top_y + 5), (0x6F, 0xD8, 0xA0, 255))

    cross_hatch(img, (cx, head_cy + 8, S, S), BLACK, 6)
    hatch(img, (0, head_cy + 18, S, S), BLACK, 4, 1)
    for dx in (-4, 2, 7):
        for y in range(head_cy + 12, S - 1):
            x = cx + dx
            if 0 <= x < S and img.getpixel((x, y))[3] != 0:
                img.putpixel((x, y), shade(img.getpixel((x, y)), 0.6))

    rough_edge(img, 0.22)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_boss():
    """魔道老祖：巨大魔躯，双角，血披风。"""
    S = 148
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 138
    top_y = 4
    head_cy, head_r = humanoid(img, draw, cx, top_y, total_h, 22, A_BOSS,
                               head_ratio=0.22, shoulder_w=1.25)

    # 双角
    draw.polygon([
        (cx - head_r + 2, head_cy - head_r + 4),
        (cx - head_r - 22, head_cy - head_r - 20),
        (cx - head_r - 8, head_cy - head_r + 10),
    ], fill=BLACK)
    draw.polygon([
        (cx + head_r - 2, head_cy - head_r + 4),
        (cx + head_r + 22, head_cy - head_r - 20),
        (cx + head_r + 8, head_cy - head_r + 10),
    ], fill=BLACK)
    draw.line([(cx - head_r - 20, head_cy - head_r - 18), (cx - head_r - 14, head_cy - head_r - 12)],
              fill=HILITE, width=1)
    draw.line([(cx + head_r + 20, head_cy - head_r - 18), (cx + head_r + 14, head_cy - head_r - 12)],
              fill=HILITE, width=1)

    # 血眼
    eye_y = head_cy - head_r // 4
    for sign in (-1, 1):
        ex = cx + sign * (head_r // 2)
        draw.rectangle([ex - 2, eye_y - 1, ex + 2, eye_y + 1], fill=BLOOD_B)
        img.putpixel((ex, eye_y), WHITE)

    # 血披风
    for i in range(int(total_h * 0.6)):
        y = head_cy + head_r + i
        if y >= S:
            break
        t = i / max(1, total_h * 0.6)
        half = int(22 + 26 * t)
        for x in (cx - half, cx + half, cx - half + 1, cx + half - 1):
            if 0 <= x < S and 0 <= y < S:
                img.putpixel((x, y), BLOOD if (i % 7) < 5 else shade(BLOOD, 0.5))

    cross_hatch(img, (cx, head_cy, S, S), BLACK, 7)
    cross_hatch(img, (cx - 10, head_cy + 40, S, S), BLACK, 6)
    hatch(img, (0, head_cy + 70, S, S), BLACK, 4, 1)
    hatch(img, (cx - 20, head_cy + head_r, cx - 4, head_cy + head_r + 14), HILITE, 5, -1, False)

    rough_edge(img, 0.26)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


# ============================================================
# 弹幕与道具
# ============================================================

def make_sword():
    """飞剑：细长剑形，高对比。"""
    S = 26
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    draw.polygon([(2, 23), (23, 2), (23, 7), (7, 23)], fill=LIGHT)
    draw.line([(4, 21), (21, 4)], fill=WHITE, width=1)
    draw.line([(6, 20), (20, 6)], fill=DARK, width=1)
    draw.line([(3, 16), (9, 22)], fill=DARK, width=2)
    draw.line([(1, 20), (5, 24)], fill=MID, width=2)

    return img


def make_enemy_shot():
    """幽火弹：暗紫火球，中心高亮。"""
    S = 20
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=(0x3A, 0x1F, 0x5C, 255))
    draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(0x6B, 0x3F, 0xA8, 255))
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(0xA8, 0x7F, 0xD8, 255))
    draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=WHITE)

    return img


def make_orb():
    """修为晶石：暗底 + 冷光菱形。"""
    S = 18
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.polygon([(cx, cy - 7), (cx + 5, cy), (cx, cy + 7), (cx - 5, cy)], fill=(0x1F, 0x4A, 0x42, 255))
    draw.polygon([(cx, cy - 5), (cx + 3, cy), (cx, cy + 5), (cx - 3, cy)], fill=(0x3F, 0xA8, 0x92, 255))
    draw.polygon([(cx, cy - 3), (cx + 1, cy), (cx, cy + 3), (cx - 1, cy)], fill=(0xA8, 0xE6, 0xD8, 255))

    return img


# ============================================================
# 障碍物
# ============================================================

def make_rock():
    """岩石：暗灰巨块，密集排线。尺寸=碰撞直径×1.1"""
    S = 76
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 3

    pts = [
        (cx - 30, cy + 14), (cx - 33, cy - 5), (cx - 18, cy - 24),
        (cx + 5, cy - 29), (cx + 26, cy - 17), (cx + 33, cy + 4),
        (cx + 22, cy + 19), (cx - 9, cy + 22),
    ]
    draw.polygon(pts, fill=MID)

    draw.polygon([
        (cx - 18, cy - 24), (cx + 5, cy - 29), (cx + 9, cy - 12), (cx - 14, cy - 9),
    ], fill=GREY)
    draw.polygon([
        (cx - 14, cy - 9), (cx + 9, cy - 12), (cx + 11, cy + 3), (cx - 12, cy + 5),
    ], fill=shade(GREY, 0.7))

    cross_hatch(img, (cx + 4, cy - 14, cx + 34, cy + 22), BLACK, 6)
    cross_hatch(img, (cx - 30, cy + 5, cx + 24, cy + 22), BLACK, 5)
    hatch(img, (cx - 18, cy - 24, cx + 9, cy - 10), HILITE, 5, -1, False)

    rough_edge(img, 0.25)
    rim_light(img)
    ink_edge(img, BLACK)
    return img


def make_tree():
    """古木：扭曲枯树干，稀疏枝叶。"""
    W, H = 66, 100
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = W // 2

    for y in range(32, H - 2):
        t = (y - 32) / max(1, H - 34)
        half = int(5 + 7 * t)
        wobble = int(math.sin(t * 6) * 1.5)
        for x in range(cx - half + wobble, cx + half + wobble + 1):
            if 0 <= x < W:
                rel = (x - (cx - half + wobble)) / max(1, 2 * half)
                if rel < 0.3:
                    img.putpixel((x, y), (0x5A, 0x42, 0x28, 255))
                elif rel < 0.7:
                    img.putpixel((x, y), (0x3F, 0x2E, 0x1C, 255))
                else:
                    img.putpixel((x, y), (0x24, 0x1A, 0x10, 255))

    branches = [
        [(cx, 42), (cx - 20, 26), (cx - 28, 16)],
        [(cx + 2, 48), (cx + 21, 32), (cx + 26, 21)],
        [(cx - 2, 58), (cx - 16, 45)],
        [(cx + 3, 36), (cx + 13, 20)],
    ]
    for b in branches:
        for i in range(len(b) - 1):
            draw.line([b[i], b[i + 1]], fill=(0x2E, 0x22, 0x14, 255), width=1)

    for (bx, by) in [(cx - 17, 10), (cx + 16, 13), (cx - 10, 28), (cx + 8, 12)]:
        draw.ellipse([bx - 4, by - 3, bx + 4, by + 3], fill=(0x1A, 0x2E, 0x1C, 255))

    hatch(img, (cx - 7, 24, cx + 7, H - 2), BLACK, 4, 1)
    for y in range(32, H - 2):
        t = (y - 32) / max(1, H - 34)
        half = int(5 + 7 * t)
        wobble = int(math.sin(t * 6) * 1.5)
        x = cx - half + wobble
        if 0 <= x < W:
            img.putpixel((x, y), (0x8A, 0x6A, 0x42, 255))

    rough_edge(img, 0.2)
    ink_edge(img, BLACK)
    return img


def make_herb():
    """灵草：暗绿细叶，顶端幽光。尺寸=碰撞直径×1.1"""
    S = 40
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S - 3

    G = (0x1F, 0x4A, 0x28, 255)

    leaves = [
        (0, -30, 2), (-9, -23, 3), (9, -24, 3), (-16, -14, 4), (16, -15, 4),
    ]
    for (dx, dy, w) in leaves:
        draw.polygon([
            (cx - 1, cy), (cx + 1, cy),
            (cx + dx + 1, cy + dy), (cx + dx, cy + dy - 2), (cx + dx - 1, cy + dy),
        ], fill=G)

    for (dx, dy, w) in leaves:
        draw.line([(cx, cy), (cx + dx, cy + dy)], fill=shade(G, 0.5), width=1)

    for (dx, dy, w) in leaves[:3]:
        px_, py_ = cx + dx, cy + dy - 2
        if 0 <= px_ < S and 0 <= py_ < S:
            img.putpixel((px_, py_), (0x6F, 0xD8, 0xA0, 255))

    rough_edge(img, 0.15)
    ink_edge(img, BLACK)
    return img


# ============================================================
# 主流程
# ============================================================

OUTPUTS = [
    ("assets/sprites/player/player_idle.png", make_player),
    ("assets/sprites/enemies/wolf.png", make_wolf),
    ("assets/sprites/enemies/bird.png", make_bird),
    ("assets/sprites/enemies/golem.png", make_golem),
    ("assets/sprites/enemies/cultivator.png", make_cultivator),
    ("assets/sprites/enemies/leech.png", make_leech),
    ("assets/sprites/enemies/spider.png", make_spider),
    ("assets/sprites/enemies/healer.png", make_healer),
    ("assets/sprites/enemies/boss.png", make_boss),
    ("assets/sprites/projectiles/sword.png", make_sword),
    ("assets/sprites/projectiles/enemy_shot.png", make_enemy_shot),
    ("assets/sprites/obstacles/rock.png", make_rock),
    ("assets/sprites/obstacles/tree.png", make_tree),
    ("assets/sprites/obstacles/herb.png", make_herb),
    ("assets/sprites/items/orb.png", make_orb),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    total = 0
    for rel_path, fn in OUTPUTS:
        full = os.path.join(base, rel_path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        img = fn()
        img.save(full)
        w, h = img.size
        px = img.load()
        opaque = 0
        colors = set()
        for y in range(h):
            for x in range(w):
                p = px[x, y]
                if p[3] > 0:
                    opaque += 1
                    colors.add((p[0], p[1], p[2]))
        fill = opaque / (w * h) * 100
        print("  %-44s %3dx%-3d  不透明%3d%%  色数%2d" % (rel_path, w, h, int(fill), len(colors)))
        total += 1
    print("\n共生成 %d 张素材（剑风传奇风格）" % total)


if __name__ == "__main__":
    main()
