#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《一念成仙》像素素材生成器 · 元气骑士画法 + 水墨黑金白（v0.25.0）

技法来源（参考《元气骑士》）：
1. 粗黑描边：统一 2px 墨黑外框，轮廓清晰锐利
2. 平涂色块：每块一色，不做渐变，最多一层硬边暗面
3. 高对比：黑 / 金 / 白三主色，点缀色高饱和
4. 干净轮廓：不破损、不毛边

配色来源（水墨修仙）：
黑 = 墨，金 = 仙气/修为，白 = 宣纸留白

运行：python3 tools/gen_sprites.py
旧版：gen_sprites_berserk.py（剑风）、gen_sprites_ink_q.py（水墨Q版）
"""

import os
import math
import random
from PIL import Image, ImageDraw

random.seed(20261028)

# ============================================================
# 黑金白主色板
# ============================================================

INK = (0x0D, 0x0B, 0x08, 255)        # 墨黑：描边、最暗
INK_D = (0x1C, 0x18, 0x14, 255)      # 浓墨：暗部
INK_M = (0x2E, 0x28, 0x22, 255)      # 淡墨：次暗

GOLD = (0xC9, 0xA2, 0x27, 255)       # 赤金：主点缀
GOLD_D = (0x8B, 0x6F, 0x1A, 255)     # 暗金
GOLD_B = (0x6B, 0x4E, 0x12, 255)     # 古铜

PAPER = (0xF2, 0xED, 0xE3, 255)      # 宣白：主留白
WHITE = (0xFF, 0xFF, 0xFF, 255)      # 亮白：纯高光

# 实体点缀色（压进黑金白体系，高饱和但低明度）
C_PLAYER = (0x4A, 0x8C, 0x82, 255)   # 玉青
C_WOLF = (0x5E, 0x3A, 0x66, 255)     # 暗紫
C_BIRD = (0xC9, 0xA2, 0x27, 255)     # 金（复用主金）
C_GOLEM = (0x8B, 0x4A, 0x28, 255)    # 赭
C_CULT = (0x3D, 0x32, 0x66, 255)     # 靛
C_LEECH = (0x8B, 0x1A, 0x22, 255)    # 绛
C_SPIDER = (0x7A, 0x4A, 0x18, 255)   # 褐
C_HEALER = (0x3A, 0x5C, 0x42, 255)   # 苍
C_BOSS = (0xA8, 0x18, 0x20, 255)     # 赤

TRANSPARENT = (0, 0, 0, 0)

OUTLINE_W = 2   # 统一描边宽度


def shade(c, f):
    """按系数明暗调整（只用于生成暗面，不做渐变）"""
    return (
        max(0, min(255, int(c[0] * f))),
        max(0, min(255, int(c[1] * f))),
        max(0, min(255, int(c[2] * f))),
        c[3],
    )


# ============================================================
# 元气骑士核心：粗黑描边
# ============================================================

def outline(img, width=OUTLINE_W, color=INK):
    """统一粗黑描边：沿不透明区域向外扩 width 像素，涂墨黑。
    这是元气骑士最标志性的视觉特征。
    """
    px = img.load()
    w, h = img.size
    for _ in range(width):
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
            px[x, y] = color


def rect(img, x0, y0, x1, y1, base):
    """平涂矩形"""
    px = img.load()
    for y in range(max(0, y0), min(img.height, y1 + 1)):
        for x in range(max(0, x0), min(img.width, x1 + 1)):
            px[x, y] = base


def hard_shadow(img, box, dark):
    """硬边阴影：把 box 内已有不透明像素替换为暗色（无过渡）"""
    x0, y0, x1, y1 = box
    px = img.load()
    for y in range(max(0, y0), min(img.height, y1)):
        for x in range(max(0, x0), min(img.width, x1)):
            if px[x, y][3] != 0 and px[x, y] != INK:
                px[x, y] = dark


# ============================================================
# Q 版人形（头身比约 1:1.5，元气骑士式）
# ============================================================

def chibi(img, draw, cx, top_y, total_h, body_w, color,
          head_ratio=0.38, shoulder=1.0):
    """画 Q 版人形，返回 (头中心y, 头半径)"""
    head_h = max(6, int(total_h * head_ratio))
    head_r = max(3, head_h // 2)
    head_cy = top_y + head_r

    body_top = top_y + head_h
    body_h = total_h - head_h

    draw.ellipse(
        [cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r],
        fill=PAPER,
    )

    for i in range(body_h):
        t = i / max(1, body_h - 1)
        half = int(body_w * shoulder * (1.0 - t * 0.3))
        half = max(2, half)
        y = body_top + i
        for x in range(cx - half, cx + half + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), color)

    return head_cy, head_r


def chibi_face(img, draw, cx, head_cy, head_r, eye_color=INK):
    """Q 版脸：两只大眼睛 + 小嘴"""
    eye_y = head_cy
    eye_dx = max(2, head_r // 2)
    eye_size = max(1, head_r // 3)

    for sign in (-1, 1):
        ex = cx + sign * eye_dx
        draw.ellipse(
            [ex - eye_size, eye_y - eye_size, ex + eye_size, eye_y + eye_size],
            fill=eye_color,
        )
        if eye_size >= 2:
            img.putpixel((ex - 1, eye_y - 1), WHITE)

    mouth_y = head_cy + head_r // 2
    for dx in range(-1, 2):
        x = cx + dx
        if 0 <= x < img.width and 0 <= mouth_y < img.height:
            img.putpixel((x, mouth_y), INK_M)


# ============================================================
# 各实体
# ============================================================

def make_player():
    """玩家：Q 版修士，青袍，束发，持剑。"""
    S = 34
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 28
    top_y = 3
    head_cy, head_r = chibi(img, draw, cx, top_y, total_h, 7, C_PLAYER,
                            head_ratio=0.40, shoulder=1.0)

    # 头发
    for y in range(head_cy - head_r, head_cy - 1):
        for x in range(cx - head_r, cx + head_r + 1):
            if (x - cx) ** 2 + (y - head_cy) ** 2 <= head_r ** 2:
                if 0 <= x < S and 0 <= y < S:
                    img.putpixel((x, y), INK_D)
    draw.ellipse([cx - 2, head_cy - head_r - 3, cx + 2, head_cy - head_r + 1], fill=INK)

    chibi_face(img, draw, cx, head_cy, head_r)

    # 腰带（金）
    belt_y = head_cy + head_r + 6
    rect(img, cx - 7, belt_y, cx + 7, belt_y + 1, GOLD)

    # 手中剑
    sx = cx + 9
    rect(img, sx, top_y + 8, sx + 1, top_y + 22, PAPER)
    rect(img, sx, top_y + 8, sx, top_y + 22, WHITE)
    rect(img, sx - 1, top_y + 20, sx + 2, top_y + 21, GOLD)

    # 衣襟留白
    for i in range(4):
        y = head_cy + head_r + i
        for dx in range(-2 + i, 3 - i):
            x = cx + dx
            if 0 <= x < S and 0 <= y < S and img.getpixel((x, y))[3] != 0:
                img.putpixel((x, y), PAPER)

    # 袍子暗面
    hard_shadow(img, (cx + 2, head_cy + head_r, S, S), shade(C_PLAYER, 0.65))

    outline(img)
    return img


def make_wolf():
    """妖狼：Q 版狼，暗紫，尖耳，红眼。头身分明。"""
    S = 46
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 3

    # ---- 身体：横椭圆，占下半部 ----
    draw.ellipse([cx - 14, cy - 2, cx + 6, cy + 11], fill=C_WOLF)

    # ---- 头：独立圆，放在身体右上方，与身体留出间隙 ----
    hx, hy, hr = cx + 7, cy - 7, 8
    draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=C_WOLF)

    # ---- 耳朵：两只三角，长在头顶 ----
    draw.polygon([(hx - 6, hy - 6), (hx - 7, hy - 17), (hx - 1, hy - 8)], fill=C_WOLF)
    draw.polygon([(hx + 1, hy - 8), (hx + 6, hy - 17), (hx + 7, hy - 6)], fill=C_WOLF)
    # 耳内暗色
    draw.polygon([(hx - 5, hy - 7), (hx - 6, hy - 14), (hx - 3, hy - 8)], fill=INK_M)
    draw.polygon([(hx + 2, hy - 8), (hx + 5, hy - 14), (hx + 6, hy - 7)], fill=INK_M)

    # ---- 吻部：向右突出的小圆 ----
    draw.ellipse([hx + 4, hy - 2, hx + 13, hy + 5], fill=shade(C_WOLF, 1.3))
    img.putpixel((hx + 11, hy + 1), INK)

    # ---- 四条腿：从身体下缘伸出，间距拉开 ----
    for dx in (-11, -5, 1, 6):
        rect(img, cx + dx - 2, cy + 9, cx + dx + 2, cy + 18, shade(C_WOLF, 0.7))
        # 脚掌
        rect(img, cx + dx - 3, cy + 17, cx + dx + 3, cy + 19, INK_M)

    # ---- 尾巴：向左上方翘 ----
    draw.polygon([
        (cx - 13, cy + 2), (cx - 22, cy - 4), (cx - 21, cy + 6), (cx - 14, cy + 7),
    ], fill=C_WOLF)

    # ---- 眼睛：红色两点 ----
    img.putpixel((hx + 1, hy - 2), C_BOSS)
    img.putpixel((hx + 2, hy - 2), C_BOSS)
    img.putpixel((hx + 1, hy - 1), C_BOSS)
    img.putpixel((hx + 2, hy - 1), C_BOSS)

    # ---- 暗面：身体下半 ----
    hard_shadow(img, (cx - 12, cy + 5, cx + 6, cy + 12), shade(C_WOLF, 0.6))

    outline(img)
    return img


def make_bird():
    """疾风雀：Q 版鸟，金羽，展翅。"""
    S = 34
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 7], fill=C_BIRD)
    draw.polygon([(cx - 5, cy - 3), (cx - 15, cy - 8), (cx - 6, cy + 3)], fill=shade(C_BIRD, 0.8))
    draw.polygon([(cx + 5, cy - 3), (cx + 15, cy - 8), (cx + 6, cy + 3)], fill=shade(C_BIRD, 0.8))
    draw.ellipse([cx - 5, cy - 13, cx + 5, cy - 3], fill=C_BIRD)
    draw.polygon([(cx - 2, cy - 9), (cx + 2, cy - 9), (cx, cy - 5)], fill=GOLD_D)
    draw.polygon([(cx - 4, cy + 6), (cx + 4, cy + 6), (cx, cy + 13)], fill=shade(C_BIRD, 0.7))

    img.putpixel((cx - 2, cy - 9), INK)
    img.putpixel((cx + 2, cy - 9), INK)

    hard_shadow(img, (cx, cy + 1, cx + 15, cy + 8), shade(C_BIRD, 0.65))

    outline(img)
    return img


def make_golem():
    """岩甲兽：Q 版厚甲兽，赭色，方块躯体。"""
    S = 70
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 3

    rect(img, cx - 20, cy - 12, cx + 20, cy + 16, C_GOLEM)
    rect(img, cx - 10, cy - 24, cx + 10, cy - 11, shade(C_GOLEM, 1.25))
    for dx in (-14, -6, 6, 14):
        rect(img, cx + dx - 4, cy + 14, cx + dx + 4, cy + 26, shade(C_GOLEM, 0.7))
    for y in range(cy - 8, cy + 14, 6):
        rect(img, cx - 19, y, cx + 19, y, GOLD_D)

    rect(img, cx - 7, cy - 19, cx - 4, cy - 16, GOLD)
    rect(img, cx + 4, cy - 19, cx + 7, cy - 16, GOLD)

    hard_shadow(img, (cx + 2, cy - 12, cx + 21, cy + 17), shade(C_GOLEM, 0.6))

    outline(img)
    return img


def make_cultivator():
    """邪修：Q 版，兜帽，靛袍，持符。"""
    S = 40
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 33
    top_y = 3
    head_cy, head_r = chibi(img, draw, cx, top_y, total_h, 7, C_CULT,
                            head_ratio=0.38, shoulder=1.0)

    draw.polygon([
        (cx - head_r - 2, head_cy + 2), (cx + head_r + 2, head_cy + 2),
        (cx + head_r, head_cy - head_r - 3), (cx - head_r, head_cy - head_r - 3),
    ], fill=shade(C_CULT, 0.75))
    draw.ellipse([cx - head_r + 1, head_cy - 1, cx + head_r - 1, head_cy + head_r], fill=INK_D)
    for sign in (-1, 1):
        img.putpixel((cx + sign * 2, head_cy + 1), GOLD)

    fx = cx + head_r + 3
    rect(img, fx, head_cy + 8, fx + 3, head_cy + 14, GOLD)
    img.putpixel((fx + 1, head_cy + 10), INK)

    hard_shadow(img, (cx + 2, head_cy + head_r, S, S), shade(C_CULT, 0.6))

    outline(img)
    return img


def make_leech():
    """血蛭：Q 版软体，绛色，环节。"""
    S = 48
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 18, cy - 9, cx + 18, cy + 9], fill=C_LEECH)
    for x in range(cx - 14, cx + 15, 6):
        rect(img, x, cy - 8, x, cy + 8, GOLD_B)
    draw.ellipse([cx + 12, cy - 7, cx + 21, cy + 7], fill=shade(C_LEECH, 1.25))
    draw.ellipse([cx + 15, cy - 3, cx + 20, cy + 3], fill=INK)
    for i in range(3):
        img.putpixel((cx + 17 + i, cy - 1), WHITE)

    img.putpixel((cx + 14, cy - 5), GOLD)
    img.putpixel((cx + 14, cy + 5), GOLD)

    hard_shadow(img, (cx - 16, cy + 3, cx + 20, cy + 10), shade(C_LEECH, 0.6))

    outline(img)
    return img


def make_spider():
    """噬魂蛛：Q 版，褐身，八足，金眼。"""
    S = 38
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 1

    draw.ellipse([cx - 9, cy - 2, cx + 9, cy + 12], fill=C_SPIDER)
    draw.ellipse([cx - 7, cy - 9, cx + 7, cy + 2], fill=shade(C_SPIDER, 1.25))
    for sign in (-1, 1):
        for (dy, ext) in [(-4, 14), (-1, 15), (3, 14), (6, 11)]:
            x0 = cx + sign * 6
            y0 = cy + dy
            x1 = cx + sign * (ext - 2)
            y1 = cy + dy - 5
            x2 = cx + sign * ext
            y2 = cy + dy + 3
            draw.line([(x0, y0), (x1, y1)], fill=INK_D, width=2)
            draw.line([(x1, y1), (x2, y2)], fill=INK_D, width=2)

    for dx, dy in [(-3, -6), (3, -6), (-1, -8), (1, -8)]:
        img.putpixel((cx + dx, cy + dy), GOLD)

    draw.ellipse([cx - 4, cy + 2, cx + 4, cy + 9], outline=GOLD_D, width=1)

    hard_shadow(img, (cx - 8, cy + 4, cx + 9, cy + 12), shade(C_SPIDER, 0.6))

    outline(img)
    return img


def make_healer():
    """尸巫：Q 版，苍袍，兜帽，持杖。"""
    S = 46
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 38
    top_y = 3
    head_cy, head_r = chibi(img, draw, cx, top_y, total_h, 6, C_HEALER,
                            head_ratio=0.34, shoulder=0.95)

    draw.polygon([
        (cx - head_r - 3, head_cy + 3), (cx + head_r + 3, head_cy + 3),
        (cx + head_r - 1, head_cy - head_r - 4), (cx - head_r + 1, head_cy - head_r - 4),
    ], fill=shade(C_HEALER, 0.7))
    draw.ellipse([cx - head_r + 1, head_cy - 1, cx + head_r - 1, head_cy + head_r], fill=INK_D)
    for sign in (-1, 1):
        img.putpixel((cx + sign * 2, head_cy + 2), GOLD)

    sx = cx - head_r - 5
    rect(img, sx, top_y + 10, sx + 1, S - 3, GOLD_D)
    draw.ellipse([sx - 3, top_y + 4, sx + 4, top_y + 12], fill=GOLD)
    img.putpixel((sx, top_y + 8), WHITE)

    hard_shadow(img, (cx + 2, head_cy + head_r, S, S), shade(C_HEALER, 0.6))

    outline(img)
    return img


def make_boss():
    """魔道老祖：Q 版巨大魔躯，赤袍，双角。"""
    S = 148
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    total_h = 118
    top_y = 12
    head_cy, head_r = chibi(img, draw, cx, top_y, total_h, 26, C_BOSS,
                            head_ratio=0.32, shoulder=1.15)

    draw.polygon([
        (cx - head_r + 3, head_cy - head_r + 5),
        (cx - head_r - 16, head_cy - head_r - 16),
        (cx - head_r - 4, head_cy - head_r + 12),
    ], fill=INK)
    draw.polygon([
        (cx + head_r - 3, head_cy - head_r + 5),
        (cx + head_r + 16, head_cy - head_r - 16),
        (cx + head_r + 4, head_cy - head_r + 12),
    ], fill=INK)

    for y in range(head_cy - head_r, head_cy - 2):
        for x in range(cx - head_r, cx + head_r + 1):
            if (x - cx) ** 2 + (y - head_cy) ** 2 <= head_r ** 2:
                if 0 <= x < S and 0 <= y < S:
                    img.putpixel((x, y), INK)

    chibi_face(img, draw, cx, head_cy, head_r, eye_color=GOLD)

    for i in range(int(total_h * 0.7)):
        y = head_cy + head_r + i
        if y >= S:
            break
        t = i / max(1, total_h * 0.7)
        half = int(26 + 20 * t)
        rect(img, cx - half, y, cx - half + 2, y, shade(C_BOSS, 0.55))
        rect(img, cx + half - 2, y, cx + half, y, shade(C_BOSS, 0.55))

    rect(img, cx - 16, head_cy + head_r + 22, cx + 16, head_cy + head_r + 25, GOLD)

    hard_shadow(img, (cx + 4, head_cy + head_r, S, S), shade(C_BOSS, 0.6))

    outline(img)
    return img


# ============================================================
# 弹幕与道具
# ============================================================

def make_sword():
    """飞剑：金白剑形，粗轮廓。"""
    S = 26
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    draw.polygon([(3, 22), (22, 3), (22, 9), (9, 22)], fill=PAPER)
    draw.line([(6, 19), (19, 6)], fill=GOLD, width=2)
    rect(img, 4, 17, 8, 21, GOLD_D)
    rect(img, 2, 20, 5, 23, INK_M)

    outline(img, width=1)
    return img


def make_enemy_shot():
    """幽火弹：金心紫晕火球。"""
    S = 20
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=C_CULT)
    draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=GOLD_D)
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=GOLD)
    draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=WHITE)

    return img


def make_orb():
    """修为晶石：金菱形，白高光。"""
    S = 18
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.polygon([(cx, cy - 7), (cx + 6, cy), (cx, cy + 7), (cx - 6, cy)], fill=GOLD)
    draw.polygon([(cx, cy - 4), (cx + 3, cy), (cx, cy + 4), (cx - 3, cy)], fill=PAPER)
    img.putpixel((cx - 1, cy - 2), WHITE)

    outline(img, width=1)
    return img


# ============================================================
# 障碍物
# ============================================================

def make_rock():
    """岩石：墨灰块面，金裂纹。"""
    S = 76
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 3

    pts = [
        (cx - 30, cy + 14), (cx - 33, cy - 5), (cx - 18, cy - 24),
        (cx + 5, cy - 29), (cx + 26, cy - 17), (cx + 33, cy + 4),
        (cx + 22, cy + 19), (cx - 9, cy + 22),
    ]
    draw.polygon(pts, fill=INK_M)

    draw.polygon([
        (cx - 18, cy - 24), (cx + 5, cy - 29), (cx + 9, cy - 12), (cx - 14, cy - 9),
    ], fill=INK_D)

    draw.polygon([
        (cx + 9, cy - 12), (cx + 26, cy - 17), (cx + 33, cy + 4), (cx + 22, cy + 19),
        (cx + 10, cy + 10),
    ], fill=shade(INK_M, 0.65))

    draw.line([(cx - 12, cy - 14), (cx - 2, cy - 2), (cx - 5, cy + 12)], fill=GOLD_D, width=1)
    draw.line([(cx + 10, cy - 8), (cx + 14, cy + 4)], fill=GOLD_D, width=1)

    outline(img)
    return img


def make_tree():
    """古木：墨色树干，金叶点缀。"""
    W, H = 66, 100
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = W // 2

    for y in range(30, H - 3):
        t = (y - 30) / max(1, H - 33)
        half = int(6 + 7 * t)
        rect(img, cx - half, y, cx + half, y, INK_M)

    for y in range(30, H - 3):
        t = (y - 30) / max(1, H - 33)
        half = int(6 + 7 * t)
        rect(img, cx + half // 2, y, cx + half, y, INK_D)

    branches = [
        [(cx, 44), (cx - 20, 26), (cx - 28, 14)],
        [(cx + 2, 50), (cx + 21, 32), (cx + 27, 20)],
        [(cx - 2, 60), (cx - 17, 44)],
        [(cx + 3, 38), (cx + 14, 22)],
    ]
    for b in branches:
        for i in range(len(b) - 1):
            draw.line([b[i], b[i + 1]], fill=INK_M, width=3)

    for (bx, by) in [(cx - 28, 14), (cx + 27, 20), (cx - 17, 44), (cx + 14, 22)]:
        rect(img, bx - 4, by - 3, bx + 4, by + 3, GOLD_D)
        rect(img, bx - 2, by - 2, bx + 2, by + 1, GOLD)

    outline(img)
    return img


def make_herb():
    """灵草：金绿细叶，顶端金光。"""
    S = 40
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S - 3

    GREEN = (0x3A, 0x5C, 0x42, 255)

    leaves = [
        (0, -30), (-9, -23), (9, -24), (-16, -14), (16, -15),
    ]
    for (dx, dy) in leaves:
        draw.polygon([
            (cx - 2, cy), (cx + 2, cy),
            (cx + dx + 2, cy + dy), (cx + dx, cy + dy - 3), (cx + dx - 2, cy + dy),
        ], fill=GREEN)

    for (dx, dy) in leaves:
        draw.line([(cx, cy), (cx + dx, cy + dy)], fill=shade(GREEN, 0.6), width=1)

    for (dx, dy) in leaves[:3]:
        img.putpixel((cx + dx, cy + dy - 3), GOLD)

    outline(img, width=1)
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
    print("\n共生成 %d 张素材（元气骑士画法 + 黑金白）" % total)


if __name__ == "__main__":
    main()
