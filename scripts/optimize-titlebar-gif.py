#!/usr/bin/env python3
"""Downscale pixel-art GIFs for title bar CSS embed (nearest-neighbor, integer scale).

Pixel art must use integer scale factors only (e.g. 1000px -> 50px = /20).
Bilinear/bicubic scaling blurs pixels; non-integer ratios stretch pixels unevenly.

Usage:
  python scripts/optimize-titlebar-gif.py
  python scripts/optimize-titlebar-gif.py --max-size 64
  python scripts/optimize-titlebar-gif.py --input assets/aemeath/Aemeath_GLASS.gif --output assets/aemeath/Aemeath_GLASS_titlebar.gif
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow is required: pip install pillow", file=sys.stderr)
    sys.exit(1)


def pick_integer_output_size(source_size: int, max_size: int) -> tuple[int, int]:
    """Return (output_px, scale_factor) — largest output <= max_size with integer scale."""
    best_out = None
    best_scale = None
    for scale in range(1, source_size + 1):
        out = source_size // scale
        if out <= max_size and (best_out is None or out > best_out):
            best_out = out
            best_scale = scale
    if best_out is None:
        raise ValueError(f"cannot fit source size {source_size} into max {max_size}")
    return best_out, best_scale


def resize_gif_nearest(input_path: Path, output_path: Path, max_size: int) -> None:
    with Image.open(input_path) as source:
        width, height = source.size
        if width != height:
            print(f"warning: non-square source {width}x{height}, using width for scale", file=sys.stderr)

        out_size, scale = pick_integer_output_size(width, max_size)
        frame_count = getattr(source, "n_frames", 1)

        frames: list[Image.Image] = []
        durations: list[int] = []

        for index in range(frame_count):
            source.seek(index)
            frame = source.convert("RGBA").resize((out_size, out_size), Image.NEAREST)
            frames.append(frame)
            durations.append(int(source.info.get("duration", 80)))

        output_path.parent.mkdir(parents=True, exist_ok=True)
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            duration=durations,
            loop=0,
            disposal=2,
            optimize=True,
        )

        out_bytes = output_path.stat().st_size
        print(f"{input_path.name}: {width}x{width} x{frame_count} -> {out_size}x{out_size} (/{scale})")
        print(f"written {output_path} ({out_bytes:,} bytes)")


def main() -> int:
    project_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description="Optimize pixel-art GIF for title bar embed")
    parser.add_argument(
        "--input",
        type=Path,
        default=project_root / "assets" / "aemeath" / "Aemeath_GLASS.gif",
        help="Source GIF (default: assets/aemeath/Aemeath_GLASS.gif)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=project_root / "assets" / "aemeath" / "Aemeath_GLASS_titlebar.gif",
        help="Output GIF (default: assets/aemeath/Aemeath_GLASS_titlebar.gif)",
    )
    parser.add_argument(
        "--max-size",
        type=int,
        default=50,
        help="Max edge length in px; uses integer downscale (default: 50, fits 20px title bar at ~2.5x)",
    )
    args = parser.parse_args()

    if not args.input.is_file():
        print(f"input not found: {args.input}", file=sys.stderr)
        return 1
    if args.max_size < 8:
        print("--max-size must be >= 8", file=sys.stderr)
        return 1

    resize_gif_nearest(args.input.resolve(), args.output.resolve(), args.max_size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
