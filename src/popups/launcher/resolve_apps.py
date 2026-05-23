import os
import json
import configparser
import glob


def find_icon(name, size=48):
    if not name:
        return ""

    # Already an absolute path
    if os.path.isabs(name):
        if os.path.exists(name):
            return name
        for ext in (".png", ".svg", ".xpm"):
            if os.path.exists(name + ext):
                return name + ext
        return ""

    # Strip known extensions to get bare name
    base = name
    for ext in (".png", ".svg", ".xpm"):
        if base.endswith(ext):
            base = base[: -len(ext)]
            break

    # Detect active GTK icon theme
    themes = ["hicolor"]
    for cfg in [
        os.path.expanduser("~/.config/gtk-4.0/settings.ini"),
        os.path.expanduser("~/.config/gtk-3.0/settings.ini"),
    ]:
        try:
            for line in open(cfg):
                if "gtk-icon-theme-name" in line:
                    themes.insert(0, line.split("=", 1)[1].strip())
                    break
        except OSError:
            pass

    roots = [
        os.path.expanduser("~/.local/share/icons"),
        "/usr/share/icons",
    ]
    sizes = [
        f"{size}x{size}",
        "scalable",
        "48x48",
        "32x32",
        "64x64",
        "128x128",
        "256x256",
        "22x22",
    ]
    categories = ["apps", "applications"]
    extensions = ["svg", "png", "xpm"]

    for root in roots:
        for theme in themes:
            for sz in sizes:
                for cat in categories:
                    for ext in extensions:
                        path = os.path.join(root, theme, sz, cat, f"{base}.{ext}")
                        if os.path.exists(path):
                            return path

    # Fallback: pixmaps
    for d in ["/usr/share/pixmaps", os.path.expanduser("~/.local/share/pixmaps")]:
        for ext in extensions:
            path = os.path.join(d, f"{base}.{ext}")
            if os.path.exists(path):
                return path

    return ""


def load_apps():
    apps = []
    seen = set()
    dirs = [
        "/usr/share/applications",
        os.path.expanduser("~/.local/share/applications"),
    ]

    for d in dirs:
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            parser = configparser.RawConfigParser()
            try:
                parser.read(f)
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
            apps.append(
                {
                    "name": name,
                    "exec": entry.get("Exec", ""),
                    "icon": find_icon(entry.get("Icon", "")),
                    "comment": entry.get("Comment", ""),
                }
            )

    apps.sort(key=lambda x: x["name"].lower())
    print(json.dumps(apps))


if __name__ == "__main__":
    load_apps()
