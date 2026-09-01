#!/usr/bin/env python3

from __future__ import annotations

import colorsys
import json
import math
import shutil
import subprocess
import sys
import time
from pathlib import Path


DURATION = 1.5
PYWAL_COLORS = Path.home() / ".cache/wal/colors.json"

EXIT_USAGE = 10
EXIT_MISSING_AWWW = 11
EXIT_MISSING_WAL = 12
EXIT_MISSING_MATUGEN = 13
EXIT_INVALID_WALLPAPER = 15
EXIT_AWWW_FAILED = 16
EXIT_WAL_FAILED = 17
EXIT_ANALYSIS_FAILED = 18
EXIT_MATUGEN_FAILED = 19


def error(message: str) -> None:
    print(f"velox-wallpaper: {message}", file=sys.stderr)


def require_command(name: str, exit_code: int) -> None:
    if shutil.which(name) is None:
        error(f"required dependency '{name}' was not found in PATH")
        raise SystemExit(exit_code)


def run_command(command: list[str], exit_code: int, label: str) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    except OSError as exc:
        error(f"failed to start {label}: {exc}")
        raise SystemExit(exit_code) from exc

    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        if detail:
            error(f"{label} failed (exit code {result.returncode}): {detail}")
        else:
            error(f"{label} failed (exit code {result.returncode})")
        raise SystemExit(exit_code)

    return result


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    if len(value) != 6:
        return (0, 0, 0)
    try:
        return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)
    except ValueError:
        return (0, 0, 0)


def hsv(value: str) -> tuple[float, float, float]:
    r, g, b = rgb(value)
    return colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)


def chroma(value: str) -> int:
    r, g, b = rgb(value)
    return max(r, g, b) - min(r, g, b)


def luminance(value: str) -> float:
    r, g, b = rgb(value)
    r, g, b = r / 255.0, g / 255.0, b / 255.0

    def linear(channel: float) -> float:
        return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4

    r, g, b = linear(r), linear(g), linear(b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hue_distance(a: float, b: float) -> float:
    distance = abs(a - b)
    return min(distance, 1.0 - distance)


def analyze_palette() -> tuple[str, str, str]:
    try:
        with PYWAL_COLORS.open(encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"failed to read pywal palette at {PYWAL_COLORS}: {exc}") from exc

    special = data.get("special", {})
    colors = data.get("colors", {})
    background = special.get("background", "#000000")

    palette = []
    for i in range(16):
        key = f"color{i}"
        if key not in colors:
            continue
        value = colors[key]
        h, s, v = hsv(value)
        palette.append({"index": i, "hex": value, "h": h, "s": s, "v": v, "c": chroma(value), "y": luminance(value)})

    if not palette:
        raise RuntimeError("pywal produced an empty color palette")

    mean_saturation = sum(p["s"] for p in palette) / len(palette)
    mean_chroma = sum(p["c"] for p in palette) / len(palette)
    mean_luminance = sum(p["y"] for p in palette) / len(palette)

    strong_colors = [p for p in palette if p["s"] >= 0.30 and p["c"] >= 45]
    strong_color_ratio = len(strong_colors) / len(palette)

    bin_count = 24
    bins = [0.0] * bin_count

    for p in palette:
        if p["s"] < 0.10 or p["c"] < 12:
            continue
        index = int(p["h"] * bin_count) % bin_count
        bins[index] += 0.5 + (p["s"] * 0.5)

    total_hue_weight = sum(bins)

    if total_hue_weight > 0:
        dominant_bin = max(range(bin_count), key=lambda i: bins[i])
        dominant_hue = (dominant_bin + 0.5) / bin_count
    else:
        dominant_bin = 0
        dominant_hue = 0.0

    dominant_weight = 0.0
    if total_hue_weight > 0:
        for offset in (-1, 0, 1):
            dominant_weight += bins[(dominant_bin + offset) % bin_count]

    dominant_hue_ratio = dominant_weight / total_hue_weight if total_hue_weight > 0 else 0.0

    occupied_bins = sum(1 for value in bins if value > total_hue_weight * 0.04) if total_hue_weight > 0 else 0

    source_candidates = []
    background_rgb = rgb(background)

    for p in palette:
        if p["s"] < 0.08 or p["v"] < 0.08 or (p["v"] > 0.97 and p["s"] < 0.60):
            continue

        hue_score = max(0.0, 1.0 - (hue_distance(p["h"], dominant_hue) / 0.50))
        saturation_score = min(p["s"], 1.0)
        value_score = 1.0 - abs(p["v"] - 0.55)
        palette_rgb = rgb(p["hex"])
        background_distance = math.sqrt(sum((palette_rgb[i] - background_rgb[i]) ** 2 for i in range(3))) / 441.67
        score = hue_score * 4.0 + saturation_score * 2.5 + value_score + background_distance * 1.5

        source_candidates.append((score, p))

    source = max(source_candidates, key=lambda item: item[0])[1] if source_candidates else palette[0]
    source_color = source["hex"]

    if mean_saturation < 0.12 and mean_chroma < 22 and strong_color_ratio < 0.20:
        classification = "monochrome"
    elif mean_saturation < 0.18 and mean_chroma < 30 and mean_luminance < 0.20:
        classification = "dark-neutral"
    elif mean_saturation < 0.28 and mean_chroma < 55 and strong_color_ratio < 0.45:
        classification = "muted"
    elif dominant_hue_ratio >= 0.62 and occupied_bins <= 4:
        classification = "single-hue"
    elif dominant_hue_ratio >= 0.40 and occupied_bins <= 7:
        classification = "dual-hue"
    elif mean_saturation >= 0.50 and strong_color_ratio >= 0.50 and occupied_bins >= 7:
        classification = "highly-colorful"
    elif mean_saturation >= 0.38 and strong_color_ratio >= 0.40 and max(p["y"] for p in palette) - min(p["y"] for p in palette) >= 0.65:
        classification = "high-contrast"
    else:
        classification = "balanced"

    schemes = {
        "monochrome": "scheme-monochrome",
        "dark-neutral": "scheme-monochrome",
        "muted": "scheme-neutral",
        "single-hue": "scheme-tonal-spot",
        "dual-hue": "scheme-fidelity",
        "high-contrast": "scheme-fidelity",
        "highly-colorful": "scheme-fruit-salad",
        "balanced": "scheme-expressive",
    }

    return schemes.get(classification, "scheme-fidelity"), source_color, classification


def apply_wallpaper(wallpaper: Path) -> None:
    try:
        wallpaper = wallpaper.expanduser().resolve(strict=True)
    except FileNotFoundError:
        error(f"wallpaper does not exist: {wallpaper}")
        raise SystemExit(EXIT_INVALID_WALLPAPER)

    if not wallpaper.is_file():
        error(f"wallpaper is not a file: {wallpaper}")
        raise SystemExit(EXIT_INVALID_WALLPAPER)

    require_command("awww", EXIT_MISSING_AWWW)
    require_command("wal", EXIT_MISSING_WAL)
    require_command("matugen", EXIT_MISSING_MATUGEN)

    run_command(["awww", "img", str(wallpaper), "--transition-type", "any", "--transition-duration", str(DURATION), "--transition-fps", "120"], EXIT_AWWW_FAILED, "awww")
    time.sleep(DURATION)

    run_command(["wal", "-i", str(wallpaper), "-n", "-b", "000000"], EXIT_WAL_FAILED, "pywal")

    try:
        scheme, source_color, classification = analyze_palette()
    except RuntimeError as exc:
        error(str(exc))
        raise SystemExit(EXIT_ANALYSIS_FAILED) from exc

    print()
    print("Wallpaper theme:")
    print(f"  Classification : {classification}")
    print(f"  Matugen scheme : {scheme}")
    print(f"  Source color   : {source_color}")
    print()

    run_command(["matugen", "color", "hex", source_color, "-m", "dark", "-t", scheme], EXIT_MATUGEN_FAILED, "matugen")


def main() -> int:
    if len(sys.argv) != 2:
        error(f"usage: {Path(sys.argv[0]).name} <wallpaper>")
        return EXIT_USAGE

    apply_wallpaper(Path(sys.argv[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
