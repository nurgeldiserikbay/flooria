"""Turn one blank floor illustration into three transparent reusable floor skins.

No game-specific numbers, names, or status icons are baked into the images.
Run with: python tools/prepare_floor_art.py
"""
from collections import deque
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "art"
BASE = ART / "floor_current.webp"


def remove_connected_dark_background(image):
    image = image.convert("RGBA")
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    queue = deque()

    def consider(x, y):
        idx = y * width + x
        if visited[idx]:
            return
        visited[idx] = 1
        r, g, b, a = pixels[x, y]
        if a and max(r, g, b) <= 88 and r + g + b <= 164:
            queue.append((x, y))

    for x in range(width):
        consider(x, 0)
        consider(x, height - 1)
    for y in range(height):
        consider(0, y)
        consider(width - 1, y)

    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        # Feather almost-black anti-aliased edges, without touching the
        # separate dark plaque enclosed by stone.
        brightness = max(r, g, b)
        opacity = max(0, min(255, int((brightness - 15) * 255 / 70)))
        pixels[x, y] = (r, g, b, opacity)
        if x > 0:
            consider(x - 1, y)
        if x + 1 < width:
            consider(x + 1, y)
        if y > 0:
            consider(x, y - 1)
        if y + 1 < height:
            consider(x, y + 1)

    return image


def tint(image, target):
    if target == "current":
        return image
    tinted = image.copy()
    source = tinted.load()
    w, h = tinted.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = source[x, y]
            if not a:
                continue
            if target == "completed":
                # Keep natural golden stone; slightly soften the gold and
                # enhance leaves, rather than painting the whole block green.
                source[x, y] = (
                    int(.84 * r + .16 * min(255, g)),
                    min(255, int(.92 * g + .08 * 175)),
                    int(.83 * b + .17 * g), a)
            else:
                gray = int(.28 * r + .59 * g + .13 * b)
                source[x, y] = (
                    int(.62 * r + .38 * gray),
                    int(.57 * g + .43 * gray),
                    min(255, int(.52 * b + .48 * gray + 12)), a)
    return tinted


def main():
    image = Image.open(BASE).convert("RGBA")
    # A previously processed current sprite is already transparent. Keep
    # reruns idempotent while retaining the blank base image.
    if image.getpixel((0, 0))[3] > 0:
        image = remove_connected_dark_background(image)
    for state in ("current", "completed", "locked"):
        result = tint(image, state)
        result.save(ART / f"floor_{state}.webp",
                    format="WEBP", quality=88, method=6)
        print(f"Saved transparent floor_{state}.webp")


if __name__ == "__main__":
    main()
