#!/usr/bin/env python
"""PNG -> 墨水屏 XIC 流水线（与 Studio 导入同一算法）。

流程：裁剪/留白 -> Lanczos 缩到最终像素 -> 亮度 0.2126R+0.7152G+0.0722B ->
Floyd-Steinberg（强度 0.65、阈值 128）2 阶或 4 阶 -> 写预览 PNG -> png2xic 编码。

用法：
  python tools/make_xic.py art/raw/emp_y.png --size 160x210 --mode gray4 --out project-files/assets/emp_y.xic
  可选：--fit cover|contain（默认 cover）、--trim（先裁掉近白边）、--preview art/out/emp_y.png
"""
import argparse
import os
import subprocess
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG2XIC = os.path.join(os.path.dirname(ROOT), "png2xic-kit", "png2xic.py")

FS = [(1, 0, 7 / 16), (-1, 1, 3 / 16), (0, 1, 5 / 16), (1, 1, 1 / 16)]


def parse_size(text):
    w, _, h = text.lower().partition("x")
    return int(w), int(h)


def trim_white(img, threshold=246):
    """裁掉近白边（Seedream 常带白边/角标）。"""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    left, right, top, bottom = w, -1, h, -1
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if 0.2126 * r + 0.7152 * g + 0.0722 * b < threshold:
                if x < left:
                    left = x
                if x > right:
                    right = x
                if y < top:
                    top = y
                if y > bottom:
                    bottom = y
    if right < left or bottom < top:
        return img
    pad = 2
    box = (max(0, left - pad), max(0, top - pad),
           min(w, right + 1 + pad), min(h, bottom + 1 + pad))
    return img.crop(box)


def fit(img, size, mode):
    """按目标尺寸缩放：cover 裁切铺满，contain 白底留边。"""
    tw, th = size
    w, h = img.size
    scale = max(tw / w, th / h) if mode == "cover" else min(tw / w, th / h)
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    resized = img.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (255, 255, 255, 255))
    if mode == "cover":
        left = (nw - tw) // 2
        top = (nh - th) // 2
        resized = resized.crop((left, top, left + tw, top + th))
        canvas.alpha_composite(resized)
    else:
        canvas.alpha_composite(resized, ((tw - nw) // 2, (th - nh) // 2))
    return canvas


def luminance(img):
    """与 processImage.js 一致：alpha 合成到白底后的浮点亮度。"""
    rgba = img.convert("RGBA").tobytes()
    n = img.width * img.height
    out = [0.0] * n
    for i in range(n):
        o = i * 4
        a = rgba[o + 3] / 255.0
        gray = 0.2126 * rgba[o] + 0.7152 * rgba[o + 1] + 0.0722 * rgba[o + 2]
        out[i] = gray * a + 255.0 * (1.0 - a)
    return out


def dither_1bpp(lum, w, h, threshold=128, strength=0.65):
    buf = lum[:]
    px = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            i = y * w + x
            old = buf[i]
            value = 0 if old < threshold else 255
            px[i] = 0 if value == 0 else 255
            err = (old - value) * strength
            for dx, dy, wt in FS:
                tx, ty = x + dx, y + dy
                if 0 <= tx < w and ty < h:
                    buf[ty * w + tx] += err * wt
    return px, [0, 255]


def dither_4level(lum, w, h, threshold=128, strength=0.65):
    buf = lum[:]
    step = 255 / 3
    bias = 128 - threshold
    px = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            i = y * w + x
            old = buf[i]
            level = min(3, max(0, int((old + bias) / step + 0.5)))
            value = round(level * step)
            px[i] = value
            err = (old - value) * strength
            for dx, dy, wt in FS:
                tx, ty = x + dx, y + dy
                if 0 <= tx < w and ty < h:
                    buf[ty * w + tx] += err * wt
    return px, [0, 85, 170, 255]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("--size", required=True)
    ap.add_argument("--mode", choices=["bw", "gray4"], default="bw")
    ap.add_argument("--fit", choices=["cover", "contain"], default="cover")
    ap.add_argument("--trim", action="store_true")
    ap.add_argument("--preview")
    ap.add_argument("--out", required=True)
    ap.add_argument("--threshold", type=int, default=128)
    ap.add_argument("--strength", type=float, default=0.65)
    args = ap.parse_args()

    size = parse_size(args.size)
    img = Image.open(args.input).convert("RGBA")
    if args.trim:
        img = trim_white(img)
    img = fit(img, size, args.fit)
    lum = luminance(img)
    if args.mode == "bw":
        px, levels = dither_1bpp(lum, size[0], size[1], args.threshold, args.strength)
    else:
        px, levels = dither_4level(lum, size[0], size[1], args.threshold, args.strength)

    out = Image.new("L", size)
    out.putdata(list(px))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)) or ".", exist_ok=True)
    stem = os.path.splitext(os.path.basename(args.out))[0]
    stage = os.path.join(ROOT, ".tmp", "xic-in")
    os.makedirs(stage, exist_ok=True)
    xic_png = os.path.join(stage, stem + ".png")
    out.save(xic_png)
    if args.preview:
        os.makedirs(os.path.dirname(os.path.abspath(args.preview)) or ".", exist_ok=True)
        out.save(args.preview)

    subprocess.run([
        sys.executable, PNG2XIC, "--mode", "bw" if args.mode == "bw" else "gray4",
        "--out-dir", stage, xic_png,
    ], check=True)
    import shutil
    shutil.move(os.path.join(stage, stem + ".xic"), args.out)
    os.remove(xic_png)
    hist = {v: list(out.getdata()).count(v) for v in levels}
    print(f"{args.out}  {size[0]}x{size[1]}  {args.mode}  {hist}")


if __name__ == "__main__":
    main()
