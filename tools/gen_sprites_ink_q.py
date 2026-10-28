#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《一念成仙》像素水墨 Q 版素材生成器

设计要点：
1. 水墨感：不用纯黑描边，用墨色深浅层次（焦/浓/重/淡/清）
2. 像素感：32x32 等小尺寸，硬边，最近邻放大
3. Q 版：头身比约 1:1.5，大头小身，眼睛占脸部 1/3
4. 抖动：Bayer 4x4 矩阵做墨色渐变（像素画颜色有限，靠点阵密度模拟过渡）

运行：python3 tools/gen_sprites.py
"""

import os
import math
from PIL import Image, ImageDraw

# ============================================================
# 调色板
# ============================================================

# 墨色系：五色层次
INK_BLACK = (0x1A, 0x1A, 0x1A, 255)   # 焦墨：眼睛、核心轮廓
INK_DARK = (0x2D, 0x2D, 0x2D, 255)    # 浓墨：主要描边
INK_MID = (0x45, 0x45, 0x45, 255)     # 重墨：阴影
INK_LIGHT = (0x6B, 0x6B, 0x6B, 255)   # 淡墨：中间调
INK_PALE = (0x9A, 0x9A, 0x9A, 255)    # 清墨：高光过渡
PAPER = (0xF5, 0xF0, 0xE8, 255)       # 留白：宣纸底色

# 点缀色（饱和度压低，符合"色不压墨"）
C_PLAYER = (0x5B, 0xA8, 0x9C, 255)    # 玩家·青
C_WOLF = (0x8B, 0x5A, 0x8C, 255)      # 妖狼·紫
C_BIRD = (0xC9, 0xA2, 0x27, 255)      # 疾风雀·金
C_GOLEM = (0xA0, 0x52, 0x2D, 255)     # 岩甲兽·赭
C_CULTIVATOR = (0x5F, 0x4B, 0x8B, 255)  # 邪修·靛
C_LEECH = (0x9B, 0x2D, 0x30, 255)     # 血蛭·绛
C_SPIDER = (0xB5, 0x65, 0x1D, 255)    # 噬魂蛛·褐
C_HEALER = (0x4A, 0x7A, 0x5C, 255)    # 尸巫·苍
C_BOSS = (0x9B, 0x22, 0x26, 255)      # 首领·赤
C_SWORD = (0x7F, 0xD4, 0xC8, 255)     # 飞剑·青白
C_SHOT = (0x8B, 0x6F, 0xC4, 255)      # 幽火·靛紫
C_ORB = (0xA8, 0xE6, 0xD8, 255)       # 晶石·青光

TRANSPARENT = (0, 0, 0, 0)

# ============================================================
# Bayer 4x4 抖动矩阵
# 用于在两色之间做点阵过渡，模拟水墨渐变
# ============================================================

BAYER_4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def dither_ratio(x, y, ratio):
    """返回该像素是否应使用第二个颜色。ratio: 0.0~1.0"""
    threshold = (BAYER_4[y % 4][x % 4] + 0.5) / 16.0
    return ratio > threshold


def dither_fill(img, box, color_a, color_b, ratio_a):
    """在 box 区域内用抖动填充两色混合。
    ratio_a 越大，color_a 占比越高。
    """
    x0, y0, x1, y1 = box
    px = img.load()
    for y in range(y0, y1):
        for x in range(x0, x1):
            if x < 0 or y < 0 or x >= img.width or y >= img.height:
                continue
            if dither_ratio(x, y, ratio_a):
                px[x, y] = color_a
            else:
                px[x, y] = color_b


def shade(base, factor):
    """按亮度系数调整颜色（0.0 全黑 ~ 1.0 原色）"""
    r, g, b, a = base
    return (
        max(0, min(255, int(r * factor))),
        max(0, min(255, int(g * factor))),
        max(0, min(255, int(b * factor))),
        a,
    )


def ink_outline(img, mask_func, base_color):
    """墨色描边：在 mask 边缘画三层墨，由外到内依次变浅。
    mask_func(x, y) -> bool 表示该像素属于实体本体。
    """
    px = img.load()
    w, h = img.size
    # 找出所有"实体外但紧邻实体"的像素
    ring1 = []
    for y in range(h):
        for x in range(w):
            if mask_func(x, y):
                continue
            # 检查 4 邻域
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and mask_func(nx, ny):
                    near = True
                    break
            if near:
                ring1.append((x, y))
    for (x, y) in ring1:
        px[x, y] = INK_DARK
    return ring1


# ============================================================
# Q 版人物基础：大头小身
# 头占约 55% 高度，身体 45%
# ============================================================

def draw_chibi_body(img, draw, cx, cy, body_h, body_w, robe_color, head_r):
    """画 Q 版身体（袍子）+ 头。
    cx, cy: 身体底部中心
    body_h: 身体高度
    body_w: 身体宽度
    head_r: 头半径
    """
    # --- 身体（袍子）：梯形，下宽上窄 ---
    top_y = cy - body_h
    top_w = int(body_w * 0.62)
    bot_w = body_w
    for i in range(body_h):
        t = i / max(1, body_h - 1)
        half_w = int(top_w / 2 + (bot_w - top_w) / 2 * t)
        y = top_y + i
        x0 = cx - half_w
        x1 = cx + half_w
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                # 左侧稍暗（光从右上来）
                if x < cx - half_w * 0.35:
                    img.putpixel((x, y), shade(robe_color, 0.78))
                else:
                    img.putpixel((x, y), robe_color)

    # --- 腰带（一道深色横带）---
    belt_y = top_y + int(body_h * 0.42)
    for x in range(cx - top_w // 2 - 1, cx + top_w // 2 + 2):
        for dy in (0, 1):
            y = belt_y + dy
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), INK_MID)

    # --- 头：圆形，坐在身体上方 ---
    head_cy = top_y - head_r + 2
    draw.ellipse(
        [cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r],
        fill=PAPER,
    )
    return head_cy, head_r


def draw_chibi_face(img, draw, cx, head_cy, head_r, eye_color=INK_BLACK):
    """Q 版脸：大眼睛占脸部 1/3，简单表情。"""
    # 眼睛：两颗大黑点
    eye_dx = max(2, head_r // 2)
    eye_y = head_cy
    eye_size = max(1, head_r // 3)
    for sign in (-1, 1):
        ex = cx + sign * eye_dx
        draw.ellipse(
            [ex - eye_size, eye_y - eye_size, ex + eye_size, eye_y + eye_size],
            fill=eye_color,
        )
        # 眼睛高光
        if eye_size >= 2:
            img.putpixel((ex - 1, eye_y - 1), PAPER)

    # 嘴：一道小横线
    mouth_y = head_cy + head_r // 2
    for dx in range(-1, 2):
        x = cx + dx
        if 0 <= x < img.width and 0 <= mouth_y < img.height:
            img.putpixel((x, mouth_y), INK_MID)


# ============================================================
# 各实体绘制
# ============================================================

def make_player():
    """玩家：青衫修士，Q 版。头身比约 1:1.2（头 12 行，身 15 行）。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    # ---- 头：y=3~14，半径 6（12 行高）----
    head_cy = 9
    head_r = 6
    draw.ellipse([cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r], fill=PAPER)

    # 头发：盖 y=3~7（额头上方），不遮眼睛
    for y in range(head_cy - head_r, head_cy - 1):
        for x in range(cx - head_r, cx + head_r + 1):
            if (x - cx) ** 2 + (y - head_cy) ** 2 <= head_r ** 2:
                if 0 <= x < S and 0 <= y < S:
                    img.putpixel((x, y), INK_BLACK)

    # 发髻（头顶）
    draw.ellipse([cx - 2, head_cy - head_r - 2, cx + 2, head_cy - head_r + 2], fill=INK_DARK)

    # 眼睛：y=10，两颗 2x1，间距 2
    eye_y = 10
    for sign in (-1, 1):
        ex = cx + sign * 2
        for dx in (0, 1):
            if 0 <= ex + dx < S:
                img.putpixel((ex + dx, eye_y), INK_BLACK)

    # 嘴：y=13，三像素
    for dx in range(-1, 2):
        x = cx + dx
        if 0 <= x < S:
            img.putpixel((x, 13), INK_MID)

    # ---- 身体：y=15~29（15 行高）----
    body_top = 15
    body_bot = 29
    for y in range(body_top, body_bot + 1):
        t = (y - body_top) / max(1, body_bot - body_top)
        half = int(5 + 4 * t)
        for x in range(cx - half, cx + half + 1):
            if 0 <= x < S and 0 <= y < S:
                # 左侧暗部（清墨过渡，补上第五色）
                if x < cx - half * 0.45:
                    img.putpixel((x, y), shade(C_PLAYER, 0.72))
                elif x < cx - half * 0.15:
                    img.putpixel((x, y), shade(C_PLAYER, 0.88))
                else:
                    img.putpixel((x, y), C_PLAYER)

    # 衣襟 V 领
    for i in range(4):
        y = body_top + i
        for dx in range(-2 + i, 3 - i):
            x = cx + dx
            if 0 <= x < S and 0 <= y < S:
                img.putpixel((x, y), PAPER)

    # 腰带
    for x in range(cx - 8, cx + 9):
        for y in (23, 24):
            if 0 <= x < S and 0 <= y < S:
                img.putpixel((x, y), INK_MID)

    # 下摆清墨（模拟水墨晕染）
    dither_fill(img, (cx - 9, 26, cx + 10, 30), shade(C_PLAYER, 0.6), C_PLAYER, 0.4)

    # 墨色描边
    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_PLAYER)
    return img


def make_wolf():
    """妖狼：紫墨狼形，尖耳，四足。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 2

    # 身体（椭圆）
    draw.ellipse([cx - 9, cy - 5, cx + 9, cy + 6], fill=C_WOLF)
    # 头（大，Q 版）
    draw.ellipse([cx - 6, cy - 11, cx + 6, cy - 1], fill=C_WOLF)
    # 耳朵（两个三角）
    draw.polygon([(cx - 6, cy - 10), (cx - 8, cy - 15), (cx - 3, cy - 11)], fill=INK_DARK)
    draw.polygon([(cx + 6, cy - 10), (cx + 8, cy - 15), (cx + 3, cy - 11)], fill=INK_DARK)
    # 四足
    for dx in (-6, -3, 3, 6):
        draw.rectangle([cx + dx - 1, cy + 5, cx + dx + 1, cy + 9], fill=INK_MID)
    # 尾巴
    draw.polygon([(cx + 8, cy), (cx + 13, cy - 4), (cx + 10, cy + 2)], fill=shade(C_WOLF, 0.8))

    # 眼睛（狼眼，凶）
    for sign in (-1, 1):
        ex = cx + sign * 3
        img.putpixel((ex, cy - 7), INK_BLACK)
        img.putpixel((ex, cy - 6), INK_BLACK)

    # 抖动阴影（腹部）
    dither_fill(img, (cx - 8, cy + 2, cx + 9, cy + 6), shade(C_WOLF, 0.7), C_WOLF, 0.5)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_WOLF)
    return img


def make_bird():
    """疾风雀：金墨飞鸟，展翅。"""
    S = 24
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    # 身体
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=C_BIRD)
    # 翅膀（两侧三角，展开）
    draw.polygon([(cx - 4, cy - 2), (cx - 11, cy - 6), (cx - 5, cy + 2)], fill=shade(C_BIRD, 0.85))
    draw.polygon([(cx + 4, cy - 2), (cx + 11, cy - 6), (cx + 5, cy + 2)], fill=shade(C_BIRD, 0.85))
    # 头
    draw.ellipse([cx - 3, cy - 8, cx + 3, cy - 2], fill=C_BIRD)
    # 喙
    draw.polygon([(cx - 1, cy - 6), (cx + 1, cy - 6), (cx, cy - 4)], fill=INK_DARK)
    # 尾羽
    draw.polygon([(cx - 2, cy + 3), (cx + 2, cy + 3), (cx, cy + 8)], fill=shade(C_BIRD, 0.75))

    # 眼睛
    img.putpixel((cx - 1, cy - 6), INK_BLACK)
    img.putpixel((cx + 1, cy - 6), INK_BLACK)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_BIRD)
    return img


def make_golem():
    """岩甲兽：赭墨厚甲，方形块面。"""
    S = 48
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 2

    # 身体（大方块，厚重）
    draw.rectangle([cx - 14, cy - 10, cx + 14, cy + 12], fill=C_GOLEM)
    # 头（小方块，缩在肩膀里）
    draw.rectangle([cx - 7, cy - 17, cx + 7, cy - 8], fill=shade(C_GOLEM, 1.1))
    # 四足（粗短）
    for dx in (-11, -5, 5, 11):
        draw.rectangle([cx + dx - 2, cy + 10, cx + dx + 2, cy + 16], fill=INK_MID)
    # 甲片纹路
    for i in range(-12, 13, 6):
        draw.line([(cx + i, cy - 8), (cx + i, cy + 10)], fill=shade(C_GOLEM, 0.65), width=1)

    # 眼睛（发光小点）
    for sign in (-1, 1):
        ex = cx + sign * 3
        draw.rectangle([ex - 1, cy - 15, ex + 1, cy - 13], fill=C_BIRD)

    # 抖动阴影（下半身）
    dither_fill(img, (cx - 13, cy + 4, cx + 14, cy + 12), shade(C_GOLEM, 0.6), C_GOLEM, 0.55)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_GOLEM)
    return img


def make_cultivator():
    """邪修：靛墨，持符，戴斗笠。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    head_r = 6
    body_h = 10
    body_bottom = S - 3
    head_cy, hr = draw_chibi_body(
        img, draw, cx, body_bottom, body_h, 12, C_CULTIVATOR, head_r
    )

    # 斗笠（宽三角）
    draw.polygon(
        [(cx - 11, head_cy - 2), (cx + 11, head_cy - 2), (cx, head_cy - 11)],
        fill=INK_MID,
    )
    # 斗笠边缘
    draw.line([(cx - 11, head_cy - 2), (cx + 11, head_cy - 2)], fill=INK_DARK, width=1)

    # 脸（斗笠下只露下半）
    draw.ellipse([cx - hr, head_cy - 1, cx + hr, head_cy + hr], fill=PAPER)
    for sign in (-1, 1):
        ex = cx + sign * 2
        img.putpixel((ex, head_cy + 2), INK_BLACK)

    # 手持符箓（右手黄色小方块）
    draw.rectangle([cx + 7, body_bottom - body_h + 4, cx + 10, body_bottom - body_h + 8], fill=C_BIRD)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_CULTIVATOR)
    return img


def make_leech():
    """血蛭：绛墨软体，环节。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    # 身体（椭圆软体）
    draw.ellipse([cx - 11, cy - 7, cx + 11, cy + 7], fill=C_LEECH)
    # 环节（横向弧线）
    for i in range(-8, 9, 4):
        draw.arc([cx + i - 3, cy - 6, cx + i + 3, cy + 6], 0, 180, fill=shade(C_LEECH, 0.6), width=1)
    # 头部（前端稍大）
    draw.ellipse([cx + 6, cy - 5, cx + 13, cy + 5], fill=shade(C_LEECH, 1.1))
    # 吸盘口
    draw.ellipse([cx + 9, cy - 2, cx + 12, cy + 2], fill=INK_DARK)

    # 眼睛
    img.putpixel((cx + 7, cy - 2), INK_BLACK)
    img.putpixel((cx + 7, cy + 2), INK_BLACK)

    # 抖动高光
    dither_fill(img, (cx - 10, cy - 6, cx + 5, cy - 1), shade(C_LEECH, 1.25), C_LEECH, 0.4)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_LEECH)
    return img


def make_spider():
    """噬魂蛛：褐墨八足，圆腹。"""
    S = 28
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 1

    # 腹部
    draw.ellipse([cx - 6, cy - 4, cx + 6, cy + 7], fill=C_SPIDER)
    # 头胸部
    draw.ellipse([cx - 4, cy - 7, cx + 4, cy + 1], fill=shade(C_SPIDER, 1.1))
    # 八足（四对，折线）
    for sign in (-1, 1):
        for i, (dy, ext) in enumerate([(-3, 9), (-1, 10), (2, 9), (4, 7)]):
            x0 = cx + sign * 4
            y0 = cy + dy
            x1 = cx + sign * ext
            y1 = cy + dy - 2
            x2 = cx + sign * (ext + 1)
            y2 = cy + dy + 2
            draw.line([(x0, y0), (x1, y1)], fill=INK_MID, width=1)
            draw.line([(x1, y1), (x2, y2)], fill=INK_MID, width=1)

    # 眼睛（多个小点，蜘蛛特征）
    for dx, dy in [(-2, -4), (2, -4), (-1, -6), (1, -6)]:
        img.putpixel((cx + dx, cy + dy), C_BIRD)

    # 腹部斑点
    for dx, dy in [(-2, 2), (2, 2), (0, 4)]:
        img.putpixel((cx + dx, cy + dy), INK_MID)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_SPIDER)
    return img


def make_healer():
    """尸巫：苍墨枯瘦，长袍，持杖。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    head_r = 6
    body_h = 12
    body_bottom = S - 3
    head_cy, hr = draw_chibi_body(
        img, draw, cx, body_bottom, body_h, 12, C_HEALER, head_r
    )

    # 兜帽（罩住头）
    draw.polygon(
        [(cx - 9, head_cy + 2), (cx + 9, head_cy + 2), (cx + 7, head_cy - 9), (cx - 7, head_cy - 9)],
        fill=INK_MID,
    )
    # 脸（阴影中，只露眼睛）
    draw.ellipse([cx - hr + 1, head_cy - 2, cx + hr - 1, head_cy + hr - 1], fill=INK_DARK)
    for sign in (-1, 1):
        ex = cx + sign * 2
        img.putpixel((ex, head_cy + 1), C_ORB)

    # 法杖（左侧竖线 + 顶端球）
    sx = cx - 8
    draw.line([(sx, body_bottom - body_h + 2), (sx, body_bottom - 2)], fill=INK_DARK, width=1)
    draw.ellipse([sx - 2, body_bottom - body_h - 1, sx + 2, body_bottom - body_h + 3], fill=C_ORB)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_HEALER)
    return img


def make_boss():
    """魔道老祖：赤墨巨躯，双角，长袍。"""
    S = 64
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    head_r = 12
    body_h = 24
    body_bottom = S - 4
    head_cy, hr = draw_chibi_body(
        img, draw, cx, body_bottom, body_h, 26, C_BOSS, head_r
    )

    # 双角
    draw.polygon([(cx - 10, head_cy - 6), (cx - 16, head_cy - 18), (cx - 6, head_cy - 10)], fill=INK_BLACK)
    draw.polygon([(cx + 10, head_cy - 6), (cx + 16, head_cy - 18), (cx + 6, head_cy - 10)], fill=INK_BLACK)

    # 头发（深色覆盖上半头）
    for y in range(head_cy - hr, head_cy):
        for x in range(cx - hr, cx + hr + 1):
            if (x - cx) ** 2 + (y - head_cy) ** 2 <= hr ** 2:
                if y < head_cy - hr // 3:
                    img.putpixel((x, y), INK_BLACK)

    draw_chibi_face(img, draw, cx, head_cy, hr, eye_color=C_BIRD)

    # 披风（两侧外扩）
    for i in range(body_h):
        t = i / max(1, body_h - 1)
        y = body_bottom - body_h + i
        half = int(14 + 8 * t)
        for x in (cx - half, cx + half):
            if 0 <= x < S and 0 <= y < S:
                img.putpixel((x, y), shade(C_BOSS, 0.6))

    # 抖动阴影
    dither_fill(img, (cx - 12, body_bottom - 10, cx + 13, body_bottom - 2),
                shade(C_BOSS, 0.55), C_BOSS, 0.5)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, C_BOSS)
    return img


def make_sword():
    """飞剑弹幕：青白剑形，指向右上。加粗保证游戏里可见。"""
    S = 16
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # 剑身：粗三角（3-4px 宽）
    draw.polygon([(1, 14), (14, 1), (14, 5), (5, 14)], fill=C_SWORD)
    # 剑脊高光
    draw.polygon([(3, 12), (12, 3), (12, 5), (5, 12)], fill=PAPER)
    # 剑格（护手）
    draw.line([(2, 10), (6, 14)], fill=INK_DARK, width=2)
    # 剑柄
    draw.line([(1, 12), (4, 15)], fill=INK_MID, width=2)

    return img


def make_enemy_shot():
    """敌方幽火弹：靛紫火球。"""
    S = 16
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=C_SHOT)
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=shade(C_SHOT, 1.4))
    draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=PAPER)

    return img


def make_orb():
    """修为晶石：青光菱形，留白高光。"""
    S = 16
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2

    draw.polygon([(cx, cy - 6), (cx + 5, cy), (cx, cy + 6), (cx - 5, cy)], fill=C_ORB)
    draw.polygon([(cx, cy - 3), (cx + 2, cy), (cx, cy + 3), (cx - 2, cy)], fill=PAPER)

    return img


def make_rock():
    """岩石：焦墨块面，不规则多边形。"""
    S = 32
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 2

    pts = [
        (cx - 12, cy + 6), (cx - 13, cy - 2), (cx - 7, cy - 10),
        (cx + 2, cy - 12), (cx + 10, cy - 7), (cx + 13, cy + 1),
        (cx + 9, cy + 8), (cx - 4, cy + 9),
    ]
    draw.polygon(pts, fill=INK_MID)

    # 亮面：清墨（水墨"石分三面"的受光面）
    draw.polygon(
        [(cx - 7, cy - 10), (cx + 2, cy - 12), (cx + 3, cy - 6), (cx - 5, cy - 4)],
        fill=INK_PALE,
    )
    # 中间面：淡墨
    draw.polygon(
        [(cx - 5, cy - 4), (cx + 3, cy - 6), (cx + 4, cy + 1), (cx - 4, cy + 2)],
        fill=INK_LIGHT,
    )
    draw.polygon(
        [(cx + 10, cy - 7), (cx + 13, cy + 1), (cx + 9, cy + 8), (cx + 5, cy + 2)],
        fill=shade(INK_MID, 0.6),
    )

    # 抖动阴影
    dither_fill(img, (cx - 11, cy + 2, cx + 10, cy + 9), INK_DARK, INK_MID, 0.5)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, INK_MID)
    return img


def make_tree():
    """古木：墨树干 + 淡墨树冠。"""
    S = 32
    img = Image.new("RGBA", (S, 48), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx = S // 2

    # 树干（左侧清墨受光，右侧重墨背光）
    for y in range(28, 46):
        half = 3 + (y - 28) // 8
        for x in range(cx - half, cx + half + 1):
            if x == cx - half:
                img.putpixel((x, y), INK_PALE)
            elif x >= cx + half - 1:
                img.putpixel((x, y), INK_MID)
            else:
                img.putpixel((x, y), (0x4A, 0x35, 0x20, 255))

    # 树冠（三层，由深到浅）
    draw.ellipse([cx - 14, 4, cx + 14, 26], fill=shade((0x2E, 0x5C, 0x34, 255), 0.75))
    draw.ellipse([cx - 11, 2, cx + 11, 20], fill=(0x2E, 0x5C, 0x34, 255))
    draw.ellipse([cx - 7, 1, cx + 7, 14], fill=shade((0x2E, 0x5C, 0x34, 255), 1.35))

    # 树冠抖动（边缘松散感）
    dither_fill(img, (cx - 14, 18, cx + 14, 27), TRANSPARENT, (0x2E, 0x5C, 0x34, 255), 0.45)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, (0x2E, 0x5C, 0x34, 255))
    return img


def make_herb():
    """灵草：青墨草叶，三片，加粗保证可见。"""
    S = 24
    img = Image.new("RGBA", (S, S), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = S // 2, S - 3

    GREEN = (0x2E, 0x6B, 0x3A, 255)

    # 中间叶（最粗）
    draw.polygon([(cx - 2, cy), (cx + 2, cy), (cx + 1, cy - 13), (cx, cy - 15), (cx - 1, cy - 13)], fill=GREEN)
    # 左叶
    draw.polygon([(cx - 1, cy), (cx - 3, cy), (cx - 8, cy - 10), (cx - 7, cy - 12), (cx - 6, cy - 10)], fill=shade(GREEN, 0.8))
    # 右叶
    draw.polygon([(cx + 1, cy), (cx + 3, cy), (cx + 8, cy - 11), (cx + 7, cy - 13), (cx + 6, cy - 11)], fill=shade(GREEN, 1.2))

    # 顶部灵光点
    for dx, dy in [(0, -16), (-1, -15), (1, -15)]:
        px, py = cx + dx, cy + dy
        if 0 <= px < S and 0 <= py < S:
            img.putpixel((px, py), C_ORB)

    ink_outline(img, lambda x, y: img.getpixel((x, y))[3] > 0, GREEN)
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
        # 统计不透明像素
        opaque = sum(1 for p in img.getdata() if p[3] > 0)
        print("  %-46s %2dx%-2d  不透明 %4d" % (rel_path, w, h, opaque))
        total += 1
    print("\n共生成 %d 张素材" % total)


if __name__ == "__main__":
    main()
