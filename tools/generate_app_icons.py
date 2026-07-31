from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]


def make_base_icon(size: int = 1024) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    for y in range(size):
      t = y / max(size - 1, 1)
      r = int(14 + (38 - 14) * t)
      g = int(96 + (166 - 96) * t)
      b = int(42 + (96 - 42) * t)
      draw.line((0, y, size, y), fill=(r, g, b, 255))

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (size * 0.14, size * 0.08, size * 0.86, size * 0.80),
        fill=(151, 255, 197, 85),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.04))
    image.alpha_composite(glow)

    pitch = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pitch_draw = ImageDraw.Draw(pitch)
    pitch_draw.rounded_rectangle(
        (size * 0.13, size * 0.14, size * 0.87, size * 0.88),
        radius=size * 0.14,
        fill=(44, 138, 66, 255),
    )
    pitch_draw.rounded_rectangle(
        (size * 0.13, size * 0.14, size * 0.87, size * 0.88),
        radius=size * 0.14,
        outline=(218, 255, 227, 220),
        width=max(10, size // 48),
    )
    pitch_draw.line(
        (size * 0.50, size * 0.20, size * 0.50, size * 0.82),
        fill=(232, 255, 237, 180),
        width=max(8, size // 64),
    )
    pitch_draw.ellipse(
        (size * 0.37, size * 0.33, size * 0.63, size * 0.59),
        outline=(232, 255, 237, 180),
        width=max(8, size // 64),
    )
    image.alpha_composite(pitch)

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        (size * 0.27, size * 0.32, size * 0.77, size * 0.82),
        fill=(0, 0, 0, 135),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=size * 0.035))
    image.alpha_composite(shadow)

    ball = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ball_draw = ImageDraw.Draw(ball)
    ball_box = (size * 0.24, size * 0.22, size * 0.74, size * 0.72)
    ball_draw.ellipse(ball_box, fill=(251, 253, 255, 255))
    ball_draw.ellipse(
        ball_box,
        outline=(28, 33, 36, 255),
        width=max(12, size // 50),
    )

    pentagon = [
        (0.0, -0.16),
        (0.15, -0.05),
        (0.10, 0.13),
        (-0.10, 0.13),
        (-0.15, -0.05),
    ]
    cx = size * 0.49
    cy = size * 0.46
    scale = size * 0.30
    center_patch = [(cx + px * scale, cy + py * scale) for px, py in pentagon]
    ball_draw.polygon(center_patch, fill=(33, 35, 39, 255))

    seam_width = max(10, size // 64)
    seam_color = (33, 35, 39, 245)
    seam_targets = [
        (size * 0.50, size * 0.22),
        (size * 0.69, size * 0.36),
        (size * 0.63, size * 0.63),
        (size * 0.36, size * 0.63),
        (size * 0.28, size * 0.36),
    ]
    for start, end in zip(center_patch, seam_targets):
        ball_draw.line((start, end), fill=seam_color, width=seam_width)

    for x, y in seam_targets:
        ball_draw.ellipse(
            (x - seam_width, y - seam_width, x + seam_width, y + seam_width),
            fill=seam_color,
        )

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse(
        (size * 0.32, size * 0.27, size * 0.56, size * 0.47),
        fill=(255, 255, 255, 120),
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(radius=size * 0.03))
    ball.alpha_composite(highlight)
    image.alpha_composite(ball)

    return image


def save_png(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path, format="PNG")


def main() -> None:
    base = make_base_icon()

    png_targets = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png": 20,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png": 40,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png": 60,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png": 29,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png": 58,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png": 87,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png": 40,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png": 80,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png": 120,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png": 120,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png": 180,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png": 76,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png": 152,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png": 167,
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": 1024,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png": 16,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png": 32,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png": 64,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png": 128,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png": 256,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png": 512,
        "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png": 1024,
        "web/favicon.png": 32,
        "web/icons/Icon-192.png": 192,
        "web/icons/Icon-512.png": 512,
        "web/icons/Icon-maskable-192.png": 192,
        "web/icons/Icon-maskable-512.png": 512,
        "assets/icons/app_icon_source.png": 1024,
    }

    for rel_path, size in png_targets.items():
        save_png(base, ROOT / rel_path, size)

    ico_path = ROOT / "windows/runner/resources/app_icon.ico"
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    base.save(ico_path, format="ICO", sizes=ico_sizes)


if __name__ == "__main__":
    main()
