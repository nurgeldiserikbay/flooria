"""Build Flooria production assets from the approved, existing design source.

No external image fetches and no UI screenshot as a full-screen background.
The source board contains an independent EMPTY architectural tower (bottom
'Tower Parts' sheet), so we cut that structure rather than flattening a UI.
Dynamic floor numbers, icons, badges, actions stay in Flutter.
"""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "design"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / "assets" / "a_clean_colorful_ui_ux_concept_presentation_board.png"

# Source PNGs were already uploaded to the project's assets directory.
BACKGROUNDS = {
    "sky": "ChatGPT Image Oct 22, 2026, 09_26_57 PM-1.png",
    "ruins": "ChatGPT Image Oct 22, 2026, 09_26_59 PM-2.png",
    "clouds-mid": "ChatGPT Image Oct 22, 2026, 09_27_00 PM-3.png",
    "clouds-front": "ChatGPT Image Oct 22, 2026, 09_27_02 PM-4.png",
    "ruins-sides": "ChatGPT Image Oct 22, 2026, 09_27_03 PM-5.png",
}

# Coordinates belong to EMPTY artwork in the Tower Parts section, not the
# home screen with baked numbers, labels or logo.
# Each floor keeps its original roof and its immediate lower cornice.
TOWER_RECTS = {
    "locked":    (338, 727, 552, 800),
    "current":   (338, 794, 552, 862),
    "completed": (338, 857, 552, 913),
    "base":      (332, 906, 554, 985),
}


def export_webp(img: Image.Image, name: str, *, quality: int = 88) -> None:
    img.save(OUT / (name + ".webp"), "WEBP", quality=quality, method=6)
    print(name, img.size, (OUT / (name + ".webp")).stat().st_size)


def alpha_silhouette(image: Image.Image) -> Image.Image:
    """Remove the near-white paper around the contiguous tower.

    Each row's two outermost foreground points give the silhouette span,
    retaining pale stone highlights in the *interior* without a white card.
    Antialias the two silhouette boundaries. Transparent outside artwork.
    """
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    brightness = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    colored = (brightness < 234) | (saturation > 22)
    h, w = colored.shape
    alpha = np.zeros((h, w), dtype=np.uint8)
    for y in range(h):
        xs = np.flatnonzero(colored[y])
        if len(xs) < 4:
            continue
        left = max(0, int(xs[0]) - 2)
        right = min(w - 1, int(xs[-1]) + 2)
        alpha[y, left:right + 1] = 255
        for j in range(2):
            alpha[y, left + j] = int(255 * (j + 1) / 3)
            alpha[y, right - j] = int(255 * (j + 1) / 3)
    rgba = image.convert("RGBA")
    rgba.putalpha(Image.fromarray(alpha, "L"))
    return rgba


def main() -> None:
    image = Image.open(SOURCE).convert("RGB")
    for state, rectangle in TOWER_RECTS.items():
        part = alpha_silhouette(image.crop(rectangle))
        # Two-pixel original edge goes to 8 on export. No raster upscale at
        # runtime larger than 2x on regular phone screens.
        part = part.resize((856, part.height * 4), Image.Resampling.LANCZOS)
        export_webp(part, "tower-" + state, quality=91)

    # My Mind hero comes from the same approved scene artwork as the tower.
    # Feather the card edges so the garden grows naturally out of the sky.
    garden = image.crop((1035, 115, 1262, 305)).convert("RGBA")
    pixels = np.asarray(garden).copy()
    height, width = pixels.shape[:2]
    ys = np.minimum(np.arange(height), height - 1 - np.arange(height))
    xs = np.minimum(np.arange(width), width - 1 - np.arange(width))
    edge = np.minimum(ys[:, None], xs[None, :])
    pixels[:, :, 3] = np.uint8(np.minimum(1.0, edge / 17.0) * 255)
    garden = Image.fromarray(pixels, "RGBA")
    garden = garden.resize((681, 570), Image.Resampling.LANCZOS)
    export_webp(garden, "mind-garden", quality=89)

    for name, filename in BACKGROUNDS.items():
        source = Image.open(ROOT / "assets" / filename).convert("RGBA")
        source.thumbnail((720, 1280), Image.Resampling.LANCZOS)
        export_webp(source, name, quality=83)


if __name__ == "__main__":
    main()
