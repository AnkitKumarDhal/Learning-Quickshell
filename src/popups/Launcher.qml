// ─────────────────────────────────────────────────────────────────────────────
// src/popups/Launcher.qml — App launcher (Rofi replacement)
//
// Wire up:
//   • src/popups/qmldir      → add: Launcher 1.0 Launcher.qml
//   • src/state/Popups.qml   → see diff below
//   • shell.qml              → see diff below
//   • hyprland.conf          → bind = SUPER, D, global, quickshell:launcherToggle
// ─────────────────────────────────────────────────────────────────────────────

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.src.theme
import qs.src.state

PanelWindow {
    id: root
    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; left: true; right: true; bottom: true }

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── Delayed visibility (lets close animation finish) ──────────────────
    property bool _shouldShow: false
    visible: _shouldShow

    Connections {
        target: Popups
        function onLauncherOpenChanged() {
            if (Popups.launcherOpen) {
                root._shouldShow = true
            } else {
                closeDelay.start()
            }
        }
    }
    Timer { id: closeDelay; interval: Theme.animDuration + 30; onTriggered: root._shouldShow = false }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            root.selectedIndex = 0
            appLoader.reload()
            searchInput.forceActiveFocus()
        }
    }

    // ── State ─────────────────────────────────────────────────────────────
    property int selectedIndex: 0
    property var allApps:       []
    property var filteredApps:  []

    function filterApps() {
        const q = searchInput.text.toLowerCase().trim()
        if (q === "") {
            root.filteredApps = root.allApps.slice(0, 48)
        } else {
            root.filteredApps = root.allApps.filter(a => {
                const name    = (a.name    || "").toLowerCase()
                const comment = (a.comment || "").toLowerCase()
                // Rank: starts-with > contains
                return name.startsWith(q) || name.includes(q) || comment.includes(q)
            }).sort((a, b) => {
                const an = (a.name || "").toLowerCase()
                const bn = (b.name || "").toLowerCase()
                const aS = an.startsWith(q) ? 0 : 1
                const bS = bn.startsWith(q) ? 0 : 1
                return aS - bS || an.localeCompare(bn)
            }).slice(0, 48)
        }
        root.selectedIndex = 0
    }

    function launch(idx) {
        const app = root.filteredApps[idx]
        if (!app || !app.exec) return
        const exe = app.exec
            .replace(/%[uUfFdDnNickvm]/g, "")  // strip desktop entry field codes
            .trim()
        launchProc.command = ["sh", "-c", exe]
        launchProc.running = true
        Popups.launcherOpen = false
    }

    // ── App loader ────────────────────────────────────────────────────────
    QtObject {
        id: appLoader

        property string _buf: ""

        function reload() {
            _buf = ""
            loaderProc.running = true
        }

        property Process loaderProc: Process {
            command: ["python3", "-c",
                "import os,json,configparser,glob\n" +
                "\n" +
                "def find_icon(name,size=48):\n" +
                "  if not name: return ''\n" +
                "  if os.path.isabs(name):\n" +
                "    if os.path.exists(name): return name\n" +
                "    for e in ['.png','.svg','.xpm']:\n" +
                "      if os.path.exists(name+e): return name+e\n" +
                "    return ''\n" +
                "  base=name\n" +
                "  for s in ['.png','.svg','.xpm']:\n" +
                "    if base.endswith(s): base=base[:-len(s)]; break\n" +
                "  roots=[os.path.expanduser('~/.local/share/icons'),'/usr/share/icons']\n" +
                "  themes=['hicolor']\n" +
                "  for cfg in [os.path.expanduser('~/.config/gtk-4.0/settings.ini'),\n" +
                "              os.path.expanduser('~/.config/gtk-3.0/settings.ini')]:\n" +
                "    try:\n" +
                "      for line in open(cfg):\n" +
                "        if 'gtk-icon-theme-name' in line:\n" +
                "          themes.insert(0,line.split('=',1)[1].strip()); break\n" +
                "    except: pass\n" +
                "  for root in roots:\n" +
                "    for theme in themes:\n" +
                "      for sz in [str(size)+'x'+str(size),'scalable','48x48','32x32','64x64','128x128','256x256','22x22']:\n" +
                "        for cat in ['apps','applications']:\n" +
                "          for ext in ['svg','png','xpm']:\n" +
                "            p=root+'/'+theme+'/'+sz+'/'+cat+'/'+base+'.'+ext\n" +
                "            if os.path.exists(p): return p\n" +
                "  for d in ['/usr/share/pixmaps',os.path.expanduser('~/.local/share/pixmaps')]:\n" +
                "    for ext in ['svg','png','xpm']:\n" +
                "      p=d+'/'+base+'.'+ext\n" +
                "      if os.path.exists(p): return p\n" +
                "  return ''\n" +
                "\n" +
                "apps=[]\n" +
                "seen=set()\n" +
                "dirs=['/usr/share/applications',os.path.expanduser('~/.local/share/applications')]\n" +
                "for d in dirs:\n" +
                "  for f in sorted(glob.glob(d+'/*.desktop')):\n" +
                "    c=configparser.RawConfigParser()\n" +
                "    try: c.read(f)\n" +
                "    except: continue\n" +
                "    if 'Desktop Entry' not in c: continue\n" +
                "    e=c['Desktop Entry']\n" +
                "    if e.get('Type')!='Application': continue\n" +
                "    if e.get('NoDisplay','').lower()=='true': continue\n" +
                "    n=e.get('Name','')\n" +
                "    if not n or n in seen: continue\n" +
                "    seen.add(n)\n" +
                "    ic=find_icon(e.get('Icon',''))\n" +
                "    apps.append({'name':n,'exec':e.get('Exec',''),'icon':ic,'comment':e.get('Comment','')})\n" +
                "apps.sort(key=lambda x:x['name'].lower())\n" +
                "print(json.dumps(apps))"
            ]
            running: false

            stdout: SplitParser {
                onRead: (line) => { appLoader._buf += line }
            }

            onExited: {
                try {
                    root.allApps = JSON.parse(appLoader._buf)
                } catch(e) {
                    root.allApps = []
                }
                root.filterApps()
            }
        }
    }

    // ── Launch process (fire-and-forget) ──────────────────────────────────
    Process {
        id: launchProc
        command: []
        running: false
    }

    // ── Dim overlay ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: Popups.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: Popups.launcherOpen = false
        }
    }

    // ── Center card ───────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.top
        anchors.topMargin:        Math.max(72, (parent.height - cardHeight) * 0.28)

        // ── Deterministic height: avoids binding loops on contentHeight ───
        readonly property int itemH:     54
        readonly property int inputH:    56
        readonly property int dividerH:  1
        readonly property int emptyH:    72
        readonly property int maxListH:  416
        readonly property int listH:     root.filteredApps.length > 0
                                             ? Math.min(root.filteredApps.length * itemH, maxListH)
                                             : emptyH
        readonly property int cardHeight: inputH + dividerH + listH

        width:  620
        height: cardHeight
        radius: Theme.popupRadius + 6
        color:  Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip: true

        // ── Entrance / exit animation ─────────────────────────────────────
        property real yOffset: Popups.launcherOpen ? 0 : -18
        Behavior on yOffset { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        transform: Translate { y: card.yOffset }

        opacity: Popups.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

        // ── Search row ────────────────────────────────────────────────────
        RowLayout {
            id: searchRow
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: card.inputH
            spacing: 0

            // Search icon
            Text {
                text:             "󰍉"
                color:            Colors.primary
                font.pixelSize:   20
                font.family:      Fonts.font
                leftPadding:      18
                Layout.alignment: Qt.AlignVCenter
            }

            // Text input — handles ALL keyboard nav
            TextInput {
                id: searchInput
                Layout.fillWidth:  true
                Layout.leftMargin: 10
                Layout.alignment:  Qt.AlignVCenter

                color:          Colors.on_Surface
                selectionColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
                font.pixelSize: 16
                font.family:    Fonts.fontM
                clip:           true

                // Placeholder
                Text {
                    anchors.fill:       parent
                    verticalAlignment:  Text.AlignVCenter
                    text:               "Search applications…"
                    color:              Colors.on_SurfaceVariant
                    font:               parent.font
                    visible:            parent.text === "" && !parent.activeFocus
                    opacity:            0.5
                }

                onTextChanged: root.filterApps()

                // Navigation — handled here so TextInput keeps focus
                Keys.onEscapePressed: { Popups.launcherOpen = false; event.accepted = true }
                Keys.onReturnPressed: { root.launch(root.selectedIndex); event.accepted = true }
                Keys.onEnterPressed:  { root.launch(root.selectedIndex); event.accepted = true }
                Keys.onUpPressed: {
                    if (root.selectedIndex > 0) {
                        root.selectedIndex--
                        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                    }
                    event.accepted = true
                }
                Keys.onDownPressed: {
                    if (root.selectedIndex < root.filteredApps.length - 1) {
                        root.selectedIndex++
                        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                    }
                    event.accepted = true
                }
                Keys.onTabPressed: {
                    if (root.selectedIndex < root.filteredApps.length - 1)
                        root.selectedIndex++
                    else
                        root.selectedIndex = 0
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                    event.accepted = true
                }
            }

            // Result count — shown when searching
            Text {
                visible:          searchInput.text !== ""
                text:             root.filteredApps.length + " result" + (root.filteredApps.length === 1 ? "" : "s")
                color:            Colors.on_SurfaceVariant
                font.pixelSize:   11
                font.family:      Fonts.font
                rightPadding:     14
                Layout.alignment: Qt.AlignVCenter
                opacity:          0.7
            }
        }

        // Divider
        Rectangle {
            id: divider
            anchors { top: searchRow.bottom; left: parent.left; right: parent.right }
            height:  card.dividerH
            color:   Colors.outlineVariant
            opacity: 0.5
        }

        // ── Empty / loading state ─────────────────────────────────────────
        Item {
            anchors { top: divider.bottom; left: parent.left; right: parent.right }
            height: card.emptyH
            visible: root.filteredApps.length === 0

            Text {
                anchors.centerIn: parent
                text:    searchInput.text === ""
                             ? "Loading applications…"
                             : "No results for  " + searchInput.text + ""
                color:   Colors.on_SurfaceVariant
                font.pixelSize: 13
                font.family:    Fonts.font
                opacity: 0.6
            }
        }

        // ── Results list ──────────────────────────────────────────────────
        ListView {
            id: resultsList
            anchors { top: divider.bottom; left: parent.left; right: parent.right }
            height:   card.listH
            visible:  root.filteredApps.length > 0

            model:           root.filteredApps
            clip:            true
            boundsBehavior:  Flickable.StopAtBounds
            // key nav handled in TextInput — don't let ListView steal it
            keyNavigationEnabled: false

            ScrollBar.vertical: ScrollBar {
                policy: resultsList.contentHeight > resultsList.height
                            ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    implicitWidth:  3
                    implicitHeight: 40
                    radius:         1.5
                    color:          Qt.rgba(1, 1, 1, 0.25)
                }
                background: Item {}
            }

            delegate: Item {
                required property var modelData
                required property int index

                width:  resultsList.width - (resultsList.contentHeight > resultsList.height ? 10 : 0)
                height: card.itemH

                // Selection background
                Rectangle {
                    anchors.fill: parent
                    color: index === root.selectedIndex
                               ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                               : hov.containsMouse
                                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
                                   : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                // Left accent bar (selected)
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width:   3
                    radius:  1.5
                    color:   Colors.primary
                    opacity: index === root.selectedIndex ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 14 }
                    spacing: 12

                    // App icon — real icon with letter fallback
                    Rectangle {
                        width:  36
                        height: 36
                        radius: 9
                        // background only visible when icon fails / hasn't loaded
                        color: iconImg.status === Image.Ready
                                   ? "transparent"
                                   : (index === root.selectedIndex
                                       ? Colors.primaryContainer
                                       : Colors.surfaceContainerHigh)
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Real icon
                        Image {
                            id:           iconImg
                            anchors.fill: parent
                            anchors.margins: 3
                            source:       modelData.icon ? ("file://" + modelData.icon) : ""
                            fillMode:     Image.PreserveAspectFit
                            smooth:       true
                            mipmap:       true
                            visible:      status === Image.Ready
                            asynchronous: true
                        }

                        // Letter fallback — shown while loading or when no icon found
                        Text {
                            anchors.centerIn: parent
                            visible:     iconImg.status !== Image.Ready
                            text:        (modelData.name || "?").charAt(0).toUpperCase()
                            color:       index === root.selectedIndex
                                             ? Colors.on_PrimaryContainer
                                             : Colors.on_SurfaceVariant
                            font.pixelSize: 15
                            font.bold:   true
                            font.family: Fonts.fontM
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    // Name + comment
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing:          2

                        Text {
                            text:             modelData.name || ""
                            color:            index === root.selectedIndex
                                                  ? Colors.on_Surface
                                                  : Colors.on_SurfaceVariant
                            font.pixelSize:   13
                            font.weight:      index === root.selectedIndex ? Font.Medium : Font.Normal
                            font.family:      Fonts.fontM
                            elide:            Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Text {
                            visible:          modelData.comment !== "" && modelData.comment !== undefined
                            text:             modelData.comment || ""
                            color:            Colors.on_SurfaceVariant
                            font.pixelSize:   11
                            font.family:      Fonts.font
                            elide:            Text.ElideRight
                            Layout.fillWidth: true
                            opacity:          0.65
                        }
                    }

                    // Enter hint on selected row
                    Text {
                        visible:  index === root.selectedIndex
                        text:     "↵"
                        color:    Colors.primary
                        font.pixelSize: 14
                        font.family:    Fonts.font
                        opacity:  0.7
                    }
                }

                MouseArea {
                    id:           hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.launch(index)
                    onEntered:    root.selectedIndex = index
                }
            }
        }
    }
}
