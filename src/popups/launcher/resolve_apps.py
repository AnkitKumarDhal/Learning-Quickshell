"""Application launcher icon resolver and .desktop file parser.

This module scans system and user application directories for .desktop files,
parses them, and resolves icon paths according to the GTK icon theme specification.
"""

import os
import json
import configparser
from pathlib import Path


ICON_EXTENSIONS = (".png", ".svg", ".xpm")
ICON_CATEGORIES = ("apps", "applications")
ICON_SIZES = ["48x48", "scalable", "32x32", "64x64", "128x128", "256x256", "22x22"]
ICON_ROOTS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
]
PIXMAP_DIRS = [
    Path("/usr/share/pixmaps"),
    Path.home() / ".local/share/pixmaps",
]
APP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local/share/applications",
]


def _get_gtk_icon_themes() -> list[str]:
    """Detect active GTK icon themes from config files."""
    themes = ["hicolor"]
    config_paths = [
        Path.home() / ".config/gtk-4.0/settings.ini",
        Path.home() / ".config/gtk-3.0/settings.ini",
    ]

    for cfg_path in config_paths:
        try:
            with open(cfg_path) as f:
                for line in f:
                    if "gtk-icon-theme-name" in line:
                        theme = line.split("=", 1)[1].strip()
                        if theme and theme not in themes:
                            themes.insert(0, theme)
                        break
        except OSError:
            continue

    return themes


def find_icon(name: str, size: int = 48) -> str:
    """Find the full path to an icon given its name.

    Args:
        name: Icon name or absolute path
        size: Preferred icon size in pixels

    Returns:
        Full path to icon file, or empty string if not found
    """
    if not name:
        return ""

    # Already an absolute path
    if os.path.isabs(name):
        icon_path = Path(name)
        if icon_path.exists():
            return str(icon_path)
        for ext in ICON_EXTENSIONS:
            candidate = icon_path.with_suffix(icon_path.suffix + ext)
            if candidate.exists():
                return str(candidate)
        return ""

    # Strip known extensions to get bare name
    base_name = name
    for ext in ICON_EXTENSIONS:
        if base_name.endswith(ext):
            base_name = base_name[: -len(ext)]
            break

    themes = _get_gtk_icon_themes()

    # Search in themed icon directories
    for root in ICON_ROOTS:
        for theme in themes:
            theme_dir = root / theme
            if not theme_dir.exists():
                continue

            for size_dir in ICON_SIZES:
                for category in ICON_CATEGORIES:
                    for ext in ICON_EXTENSIONS:
                        icon_path = theme_dir / size_dir / category / f"{base_name}{ext}"
                        if icon_path.exists():
                            return str(icon_path)

    # Fallback: search pixmaps directories
    for pixmap_dir in PIXMAP_DIRS:
        if not pixmap_dir.exists():
            continue
        for ext in ICON_EXTENSIONS:
            icon_path = pixmap_dir / f"{base_name}{ext}"
            if icon_path.exists():
                return str(icon_path)

    return ""


def load_apps() -> list[dict]:
    """Load and parse .desktop files from standard application directories.

    Returns:
        List of application dictionaries with name, exec, icon, and comment fields,
        sorted alphabetically by name.
    """
    apps = []
    seen = set()

    for app_dir in APP_DIRS:
        if not app_dir.exists():
            continue

        desktop_files = sorted(app_dir.glob("*.desktop"))
        for desktop_file in desktop_files:
            parser = configparser.RawConfigParser(strict=False)
            try:
                parser.read(desktop_file)
            except Exception:
                continue

            if "Desktop Entry" not in parser:
                continue

            entry = parser["Desktop Entry"]

            if entry.get("Type") != "Application":
                continue
            if entry.get("NoDisplay", "").lower() == "true":
                continue

            name = entry.get("Name", "")
            if not name or name in seen:
                continue

            seen.add(name)
            apps.append({
                "name": name,
                "exec": entry.get("Exec", ""),
                "icon": find_icon(entry.get("Icon", "")),
                "comment": entry.get("Comment", ""),
            })

    apps.sort(key=lambda x: x["name"].lower())
    print(json.dumps(apps))


if __name__ == "__main__":
    load_apps()
