<repomix><file_summary>This file is a merged representation of the entire codebase, combined into a single document by Repomix.
The content has been processed where line numbers have been added, content has been formatted for parsing in xml style.<purpose>This file contains a packed representation of the entire repository&apos;s contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.</purpose><file_format>The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Repository files, each consisting of:
  - File path as an attribute
  - Full contents of the file</file_format><usage_guidelines>- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.</usage_guidelines><notes>- Some files may have been excluded based on .gitignore rules and Repomix&apos;s configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Line numbers have been added to the beginning of each line
- Content has been formatted for parsing in xml style
- Files are sorted by Git change count (files with more changes are at the bottom)</notes></file_summary><directory_structure>src/
  components/
    PillBase.qml
    PopupPage.qml
    PopupSlide.qml
    qmldir
    TabBar.qml
    TrayContextMenu.qml
  modules/
    Center/
      ClockDate.qml
      IdleInhibitor.qml
      Media.qml
      qmldir
    Left/
      ArchLogo.qml
      qmldir
      WindowName.qml
      Workspaces.qml
    Right/
      Battery.qml
      Network.qml
      NotificationButton.qml
      qmldir
      SystemMonitor.qml
      Tray.qml
      Volume.qml
  popups/
    launcher/
      LauncherAppLoader.qml
      LauncherResultItem.qml
      LauncherResultsList.qml
      LauncherSearchBar.qml
      qmldir
      resolve_apps.py
    media/
      MediaArt.qml
      MediaControls.qml
      MediaProgress.qml
      MediaTrackInfo.qml
      MediaVolumeRow.qml
      qmldir
    system/
      DiskBar.qml
      NetworkGraph.qml
      qmldir
      Speedometer.qml
    ClipboardPopup.qml
    DeviceRow.qml
    Launcher.qml
    MediaPopup.qml
    NetworkPopup.qml
    NetworkRow.qml
    NotificationPanel.qml
    NotificationToast.qml
    qmldir
    SystemPopup.qml
    ToastItem.qml
    VolumePopup.qml
    VolumeSlider.qml
  services/
    system/
      qmldir
      SystemStats.qml
    BatteryService.qml
    ClipboardService.qml
    NetworkService.qml
    NotificationService.qml
    qmldir
    VolumeService.qml
  state/
    Popups.qml
    qmldir
    ShellState.qml
  theme/
    Colors.json
    Colors.qml
    Fonts.qml
    qmldir
    quickshell.json.hbs
    Theme.qml
  windows/
    PopupDismiss.qml
    qmldir
    TopBar.qml
.gitignore
shell.qml</directory_structure><files>This section contains the contents of the repository&apos;s files.<file path="src/modules/Center/ClockDate.qml"> 1: import QtQuick
 2: import Quickshell
 3: import qs.src.components
 4: import qs.src.theme
 5: import qs.src.state
 6: 
 7: PillBase {
 8:     id: root
 9: 
10:     hoverExpand: true
11: 
12:     property bool showDate: false
13: 
14:     SystemClock {
15:         id: sysClock
16:         precision: SystemClock.Minutes
17:     }
18: 
19:     Text {
20:         text: root.showDate
21:             ? Qt.formatDateTime(sysClock.date, &quot;ddd, MMM d&quot;)
22:             : Qt.formatDateTime(sysClock.date, &quot;hh:mm A&quot;)
23:         color: Colors.primary
24:         font.pointSize: 11
25:         font.bold: true
26:         font.family: Fonts.font
27:         verticalAlignment: Text.AlignVCenter
28:     }
29: 
30:     onClicked:      root.showDate = !root.showDate
31:     onRightClicked: Popups.calendarOpen = !Popups.calendarOpen
32: }</file><file path="src/modules/Center/qmldir">1: ClockDate 1.0 ClockDate.qml
2: Media 1.0 Media.qml
3: IdleInhibitor 1.0 IdleInhibitor.qml</file><file path="src/modules/Left/qmldir">1: ArchLogo 1.0 ArchLogo.qml
2: Workspaces 1.0 Workspaces.qml
3: WindowName 1.0 WindowName.qml</file><file path="src/modules/Right/Volume.qml"> 1: import QtQuick
 2: import Quickshell
 3: import qs.src.components
 4: import qs.src.theme
 5: import qs.src.state
 6: import qs.src.services
 7: 
 8: PillBase {
 9:     id: root
10: 
11:     hoverExpand: true
12: 
13:     function getIcon(): string {
14:         if (VolumeService.muted || VolumeService.volume &lt;= 0.0) return &quot;󰝟&quot;
15:         if (VolumeService.volume &gt;= 0.7) return &quot;󰕾&quot;
16:         if (VolumeService.volume &gt;= 0.3) return &quot;󰖀&quot;
17:         return &quot;󰕿&quot;
18:     }
19: 
20:     Text {
21:         text: root.getIcon() + &quot;  &quot; + Math.round(VolumeService.volume * 100) + &quot;%&quot;
22:         color: VolumeService.muted ? Colors.error : Colors.primary
23:         font.pointSize: 11
24:         font.bold: true
25:         font.family: Fonts.font
26:         verticalAlignment: Text.AlignVCenter
27:     }
28: 
29:     onClicked:      Popups.volumeOpen = !Popups.volumeOpen
30:     onRightClicked: VolumeService.toggleMute()
31:     onScrolled: (wheel) =&gt; {
32:         VolumeService.changeVolume(wheel.angleDelta.y &gt; 0 ? 0.05 : -0.05)
33:     }
34: }</file><file path="src/popups/launcher/LauncherSearchBar.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: Item {
 6:     id: root
 7: 
 8:     height: 56
 9: 
10:     // ── Inputs ────────────────────────────────────────────────────────────
11:     property int  resultCount: 0
12:     property bool showCount:   false
13: 
14:     // ── Outputs ───────────────────────────────────────────────────────────
15:     readonly property alias text: searchInput.text
16: 
17:     signal escapePressed()
18:     signal returnPressed()
19:     signal upPressed()
20:     signal downPressed()
21:     signal tabPressed()
22: 
23:     function clear()            { searchInput.text = &quot;&quot; }
24:     function forceActiveFocus() { searchInput.forceActiveFocus() }
25: 
26:     // ── Layout ────────────────────────────────────────────────────────────
27:     RowLayout {
28:         anchors.fill: parent
29:         spacing: 0
30: 
31:         // Search icon
32:         Text {
33:             text:             &quot;󰍉&quot;
34:             color:            Colors.primary
35:             font.pixelSize:   20
36:             font.family:      Fonts.font
37:             leftPadding:      18
38:             Layout.alignment: Qt.AlignVCenter
39:         }
40: 
41:         // Text input
42:         TextInput {
43:             id: searchInput
44:             Layout.fillWidth:  true
45:             Layout.leftMargin: 10
46:             Layout.alignment:  Qt.AlignVCenter
47: 
48:             color:          Colors.on_Surface
49:             selectionColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
50:             font.pixelSize: 16
51:             font.family:    Fonts.fontM
52:             clip:           true
53: 
54:             Text {
55:                 anchors.fill:      parent
56:                 verticalAlignment: Text.AlignVCenter
57:                 text:              &quot;Search applications…&quot;
58:                 color:             Colors.on_SurfaceVariant
59:                 font:              parent.font
60:                 visible:           parent.text === &quot;&quot; &amp;&amp; !parent.activeFocus
61:                 opacity:           0.5
62:             }
63: 
64:             Keys.onEscapePressed: { root.escapePressed(); event.accepted = true }
65:             Keys.onReturnPressed: { root.returnPressed(); event.accepted = true }
66:             Keys.onEnterPressed:  { root.returnPressed(); event.accepted = true }
67:             Keys.onUpPressed:     { root.upPressed();     event.accepted = true }
68:             Keys.onDownPressed:   { root.downPressed();   event.accepted = true }
69:             Keys.onTabPressed:    { root.tabPressed();    event.accepted = true }
70:         }
71: 
72:         // Result count badge
73:         Text {
74:             visible:          root.showCount
75:             text:             root.resultCount + &quot; result&quot; + (root.resultCount === 1 ? &quot;&quot; : &quot;s&quot;)
76:             color:            Colors.on_SurfaceVariant
77:             font.pixelSize:   11
78:             font.family:      Fonts.font
79:             rightPadding:     14
80:             Layout.alignment: Qt.AlignVCenter
81:             opacity:          0.7
82:         }
83:     }
84: }</file><file path="src/popups/launcher/qmldir">1: LauncherAppLoader   1.0 LauncherAppLoader.qml
2: LauncherSearchBar   1.0 LauncherSearchBar.qml
3: LauncherResultItem  1.0 LauncherResultItem.qml
4: LauncherResultsList 1.0 LauncherResultsList.qml</file><file path="src/popups/media/MediaArt.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Qt5Compat.GraphicalEffects
 4: import qs.src.theme
 5: 
 6: Item {
 7:     id: root
 8: 
 9:     required property var    player
10:     required property bool   hasArt
11: 
12:     Layout.fillWidth:       true
13:     Layout.preferredHeight: width   // always square
14: 
15:     // ── Art (masked) ──────────────────────────────────────────────────────────
16:     Rectangle {
17:         id:           artMask
18:         anchors.fill: parent
19:         radius:       10
20:         visible:      false
21:     }
22: 
23:     Image {
24:         anchors.fill:  parent
25:         source:        root.hasArt ? root.player.trackArtUrl : &quot;&quot;
26:         fillMode:      Image.PreserveAspectCrop
27:         smooth:        true
28:         visible:       root.hasArt
29:         layer.enabled: true
30:         layer.effect:  OpacityMask { maskSource: artMask }
31:     }
32: 
33:     // ── Placeholder ───────────────────────────────────────────────────────────
34:     Rectangle {
35:         anchors.fill: parent
36:         visible:      !root.hasArt
37:         radius:       10
38:         color:        Colors.surfaceContainerHigh
39: 
40:         Text {
41:             anchors.centerIn: parent
42:             text:             &quot;󰎆&quot;
43:             font.family:      Fonts.fontM
44:             font.pointSize:   48
45:             color:            Colors.on_SurfaceVariant
46:         }
47:     }
48: }</file><file path="src/popups/media/MediaControls.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell.Services.Mpris
  4: import qs.src.theme
  5: 
  6: RowLayout {
  7:     id: root
  8: 
  9:     required property var  player
 10:     required property bool isPlaying
 11: 
 12:     Layout.fillWidth: true
 13:     spacing:          0
 14: 
 15:     // ── Helper: icon button ───────────────────────────────────────────────────
 16:     component IconBtn: Item {
 17:         property string icon:      &quot;&quot;
 18:         property color  iconColor: Colors.on_Surface
 19:         property int    iconSize:  16
 20:         property int    btnSize:   36
 21:         property int    bgSize:    28
 22: 
 23:         signal clicked()
 24: 
 25:         Layout.preferredWidth:  btnSize
 26:         Layout.preferredHeight: btnSize
 27: 
 28:         Rectangle {
 29:             anchors.centerIn: parent
 30:             width: bgSize; height: bgSize; radius: bgSize / 2
 31:             color: hov.containsMouse
 32:                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
 33:                    : &quot;transparent&quot;
 34:             Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
 35:         }
 36: 
 37:         Text {
 38:             anchors.centerIn: parent
 39:             text:             parent.icon
 40:             font.family:      Fonts.fontM
 41:             font.pointSize:   parent.iconSize
 42:             color:            parent.iconColor
 43:         }
 44: 
 45:         MouseArea {
 46:             id:           hov
 47:             anchors.fill: parent
 48:             hoverEnabled: true
 49:             cursorShape:  Qt.PointingHandCursor
 50:             onClicked:    parent.clicked()
 51:         }
 52:     }
 53: 
 54:     // Shuffle
 55:     IconBtn {
 56:         icon:      &quot;󰒞&quot;
 57:         iconSize:  13
 58:         iconColor: (root.player?.shuffle ?? false) ? Colors.primary : Colors.on_SurfaceVariant
 59:         onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
 60:     }
 61: 
 62:     Item { Layout.fillWidth: true }
 63: 
 64:     // Prev
 65:     IconBtn {
 66:         icon:      &quot;󰒮&quot;
 67:         iconSize:  16
 68:         onClicked: if (root.player) root.player.previous()
 69:     }
 70: 
 71:     Item { Layout.fillWidth: true }
 72: 
 73:     // Play / Pause — bigger
 74:     Item {
 75:         Layout.preferredWidth:  52
 76:         Layout.preferredHeight: 52
 77: 
 78:         Rectangle {
 79:             anchors.centerIn: parent
 80:             width: 44; height: 44; radius: 22
 81:             color: playHov.containsMouse
 82:                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
 83:                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
 84:             Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
 85:         }
 86: 
 87:         Text {
 88:             anchors.centerIn: parent
 89:             text:             root.isPlaying ? &quot;󰏤&quot; : &quot;󰐊&quot;
 90:             font.family:      Fonts.fontM
 91:             font.pointSize:   20
 92:             color:            Colors.primary
 93:         }
 94: 
 95:         MouseArea {
 96:             id:           playHov
 97:             anchors.fill: parent
 98:             hoverEnabled: true
 99:             cursorShape:  Qt.PointingHandCursor
100:             onClicked:    if (root.player) root.player.togglePlaying()
101:         }
102:     }
103: 
104:     Item { Layout.fillWidth: true }
105: 
106:     // Next
107:     IconBtn {
108:         icon:      &quot;󰒭&quot;
109:         iconSize:  16
110:         onClicked: if (root.player) root.player.next()
111:     }
112: 
113:     Item { Layout.fillWidth: true }
114: 
115:     // Loop
116:     IconBtn {
117:         icon: {
118:             const ls = root.player?.loopState ?? MprisLoopState.None
119:             return ls === MprisLoopState.Track ? &quot;󰑘&quot; : &quot;󰑖&quot;
120:         }
121:         iconSize:  13
122:         iconColor: {
123:             const ls = root.player?.loopState ?? MprisLoopState.None
124:             return ls !== MprisLoopState.None ? Colors.primary : Colors.on_SurfaceVariant
125:         }
126:         onClicked: {
127:             if (!root.player) return
128:             const ls = root.player.loopState
129:             if      (ls === MprisLoopState.None)     root.player.loopState = MprisLoopState.Playlist
130:             else if (ls === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track
131:             else                                     root.player.loopState = MprisLoopState.None
132:         }
133:     }
134: }</file><file path="src/popups/media/MediaProgress.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import qs.src.theme
  4: 
  5: // Scrubber + time labels.
  6: // Parent owns _position and _seeking; we communicate back via signals.
  7: 
  8: ColumnLayout {
  9:     id: root
 10: 
 11:     required property var  player
 12:     required property real position    // seconds (float)
 13:     required property bool seeking
 14: 
 15:     signal seekStarted(real pos)
 16:     signal seekMoved(real pos)
 17:     signal seekReleased(real pos)
 18: 
 19:     Layout.fillWidth: true
 20:     spacing:          4
 21: 
 22:     visible: root.player !== null &amp;&amp; (root.player.positionSupported ?? false)
 23: 
 24:     // ── Scrubber ──────────────────────────────────────────────────────────────
 25:     Item {
 26:         Layout.fillWidth:       true
 27:         Layout.preferredHeight: 16
 28: 
 29:         readonly property real trackLen: root.player?.length ?? 0
 30:         readonly property real fraction: trackLen &gt; 0
 31:                                          ? Math.min(root.position / trackLen, 1.0)
 32:                                          : 0
 33: 
 34:         // Track bg
 35:         Rectangle {
 36:             anchors.verticalCenter: parent.verticalCenter
 37:             width:  parent.width
 38:             height: 4; radius: 2
 39:             color:  Colors.surfaceContainerHighest
 40:         }
 41: 
 42:         // Fill
 43:         Rectangle {
 44:             anchors.verticalCenter: parent.verticalCenter
 45:             anchors.left:           parent.left
 46:             width:  parent.width * parent.fraction
 47:             height: 4; radius: 2
 48:             color:  Colors.primary
 49: 
 50:             Behavior on width {
 51:                 enabled: !root.seeking
 52:                 NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
 53:             }
 54:         }
 55: 
 56:         // Thumb
 57:         Rectangle {
 58:             anchors.verticalCenter: parent.verticalCenter
 59:             x:      parent.width * parent.fraction - width / 2
 60:             width:  12; height: 12; radius: 6
 61:             color:  Colors.primary
 62: 
 63:             Behavior on x {
 64:                 enabled: !root.seeking
 65:                 NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
 66:             }
 67:         }
 68: 
 69:         MouseArea {
 70:             anchors.fill: parent
 71:             enabled:      root.player?.canSeek ?? false
 72:             cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
 73: 
 74:             onPressed: (mouse) =&gt; {
 75:                 root.seekStarted((mouse.x / width) * (root.player?.length ?? 0))
 76:             }
 77:             onPositionChanged: (mouse) =&gt; {
 78:                 if (pressed)
 79:                     root.seekMoved(Math.max(0,
 80:                         Math.min(mouse.x / width, 1.0) * (root.player?.length ?? 0)))
 81:             }
 82:             onReleased: (mouse) =&gt; {
 83:                 root.seekReleased(Math.max(0,
 84:                     Math.min(mouse.x / width, 1.0) * (root.player?.length ?? 0)))
 85:             }
 86:         }
 87:     }
 88: 
 89:     // ── Time labels ───────────────────────────────────────────────────────────
 90:     RowLayout {
 91:         Layout.fillWidth: true
 92: 
 93:         Text {
 94:             text: {
 95:                 const s = Math.floor(root.position)   // position is already seconds
 96:                 return &quot;%1:%2&quot;.arg(Math.floor(s / 60))
 97:                               .arg(String(s % 60).padStart(2, &quot;0&quot;))
 98:             }
 99:             color:          Colors.on_SurfaceVariant
100:             font.family:    Fonts.font
101:             font.pointSize: 9
102:         }
103: 
104:         Item { Layout.fillWidth: true }
105: 
106:         Text {
107:             text: {
108:                 const s = Math.floor(root.player?.length ?? 0)
109:                 return &quot;%1:%2&quot;.arg(Math.floor(s / 60))
110:                               .arg(String(s % 60).padStart(2, &quot;0&quot;))
111:             }
112:             color:          Colors.on_SurfaceVariant
113:             font.family:    Fonts.font
114:             font.pointSize: 9
115:         }
116:     }
117: }</file><file path="src/popups/media/MediaTrackInfo.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: ColumnLayout {
 6:     id: root
 7: 
 8:     required property var player
 9: 
10:     Layout.fillWidth: true
11:     spacing:          2
12: 
13:     Text {
14:         Layout.fillWidth: true
15:         text:             root.player?.trackTitle  || &quot;Nothing Playing&quot;
16:         color:            Colors.on_Surface
17:         font.family:      Fonts.font
18:         font.pointSize:   12
19:         font.bold:        true
20:         elide:            Text.ElideRight
21:     }
22: 
23:     Text {
24:         Layout.fillWidth: true
25:         text:             root.player?.trackArtist ?? &quot;&quot;
26:         color:            Colors.on_SurfaceVariant
27:         font.family:      Fonts.font
28:         font.pointSize:   10
29:         elide:            Text.ElideRight
30:         visible:          text !== &quot;&quot;
31:     }
32: 
33:     Text {
34:         Layout.fillWidth: true
35:         text:             root.player?.trackAlbum  ?? &quot;&quot;
36:         color:            Colors.on_SurfaceVariant
37:         font.family:      Fonts.font
38:         font.pointSize:   9
39:         elide:            Text.ElideRight
40:         visible:          text !== &quot;&quot;
41:         opacity:          0.7
42:     }
43: }</file><file path="src/popups/media/MediaVolumeRow.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: RowLayout {
 6:     id: root
 7: 
 8:     required property var player
 9: 
10:     Layout.fillWidth: true
11:     spacing:          8
12:     visible:          root.player !== null
13: 
14:     Text {
15:         text: {
16:             const v = root.player?.volume ?? 0
17:             if (v === 0)  return &quot;󰝟&quot;
18:             if (v &lt; 0.4)  return &quot;󰕿&quot;
19:             if (v &lt; 0.75) return &quot;󰖀&quot;
20:             return &quot;󰕾&quot;
21:         }
22:         font.family:    Fonts.fontM
23:         font.pointSize: 13
24:         color:          Colors.on_SurfaceVariant
25:     }
26: 
27:     Item {
28:         Layout.fillWidth:       true
29:         Layout.preferredHeight: 16
30: 
31:         readonly property real vol: root.player?.volume ?? 0
32: 
33:         Rectangle {
34:             anchors.verticalCenter: parent.verticalCenter
35:             width: parent.width; height: 4; radius: 2
36:             color: Colors.surfaceContainerHighest
37:         }
38: 
39:         Rectangle {
40:             anchors.verticalCenter: parent.verticalCenter
41:             anchors.left:           parent.left
42:             width:  parent.width * parent.vol
43:             height: 4; radius: 2
44:             color:  Colors.secondary
45:             Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
46:         }
47: 
48:         Rectangle {
49:             anchors.verticalCenter: parent.verticalCenter
50:             x:      parent.width * parent.vol - width / 2
51:             width:  12; height: 12; radius: 6
52:             color:  Colors.secondary
53:             Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
54:         }
55: 
56:         MouseArea {
57:             anchors.fill: parent
58:             cursorShape:  Qt.PointingHandCursor
59:             onPressed: (mouse) =&gt; {
60:                 if (root.player)
61:                     root.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
62:             }
63:             onPositionChanged: (mouse) =&gt; {
64:                 if (pressed &amp;&amp; root.player)
65:                     root.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
66:             }
67:         }
68:     }
69: 
70:     Text {
71:         text:           Math.round((root.player?.volume ?? 0) * 100) + &quot;%&quot;
72:         color:          Colors.on_SurfaceVariant
73:         font.family:    Fonts.font
74:         font.pointSize: 9
75:         Layout.preferredWidth:   30
76:         horizontalAlignment:     Text.AlignRight
77:     }
78: }</file><file path="src/popups/system/DiskBar.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: Item {
 6:     id: root
 7: 
 8:     property string label:      &quot;/&quot;
 9:     property string mountPoint: &quot;/&quot;
10:     property real   usedBytes:  0
11:     property real   totalBytes: 1
12:     property real   freeBytes:  1
13: 
14:     readonly property real fraction: totalBytes &gt; 0 ? usedBytes / totalBytes : 0
15: 
16:     function formatSize(bytes) {
17:         if (bytes &gt;= 1e12) return (bytes / 1e12).toFixed(1) + &quot; TB&quot;
18:         if (bytes &gt;= 1e9)  return (bytes / 1e9).toFixed(1)  + &quot; GB&quot;
19:         if (bytes &gt;= 1e6)  return (bytes / 1e6).toFixed(1)  + &quot; MB&quot;
20:         return bytes + &quot; B&quot;
21:     }
22: 
23:     implicitHeight: 36
24: 
25:     ColumnLayout {
26:         anchors.fill: parent
27:         spacing: 4
28: 
29:         RowLayout {
30:             Layout.fillWidth: true
31: 
32:             Text {
33:                 text:           root.label
34:                 color:          Colors.on_SurfaceVariant
35:                 font.pixelSize: 11
36:                 font.family:    Fonts.font
37:                 Layout.fillWidth: true
38:             }
39: 
40:             Text {
41:                 text:           root.formatSize(root.usedBytes)
42:                               + &quot; / &quot;
43:                               + root.formatSize(root.totalBytes)
44:                 color:          Colors.on_Surface
45:                 font.pixelSize: 11
46:                 font.bold:      true
47:                 font.family:    Fonts.font
48:             }
49: 
50:             Text {
51:                 text:           &quot;(&quot; + root.formatSize(root.freeBytes) + &quot; Free)&quot;
52:                 color:          Colors.on_Surface
53:                 font.pixelSize: 11
54:                 font.bold:      true
55:                 font.family:    Fonts.font
56:             }
57:         }
58: 
59:         // Track
60:         Rectangle {
61:             Layout.fillWidth: true
62:             height:  6
63:             radius:  3
64:             color:   Colors.surfaceContainerHighest
65: 
66:             // Fill
67:             Rectangle {
68:                 width:  parent.width * root.fraction
69:                 height: parent.height
70:                 radius: parent.radius
71:                 color:  root.fraction &gt;= 0.9
72:                             ? Colors.error
73:                             : root.fraction &gt;= 0.7
74:                                 ? Colors.tertiary
75:                                 : Colors.primary
76: 
77:                 Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
78:                 Behavior on color { ColorAnimation  { duration: 300 } }
79:             }
80:         }
81:     }
82: }</file><file path="src/popups/system/NetworkGraph.qml">  1: import QtQuick
  2: import qs.src.theme
  3: 
  4: Canvas {
  5:     id: root
  6: 
  7:     property var upHistory:   []
  8:     property var downHistory: []
  9:     property real slideOffset: 0.0
 10: 
 11:     // Drives the fluid 60FPS scrolling to match the 1000ms data polling
 12:     NumberAnimation {
 13:         id: slideAnim
 14:         target: root
 15:         property: &quot;slideOffset&quot;
 16:         from: 1.0
 17:         to: 0.0
 18:         duration: 1000 
 19:     }
 20: 
 21:     onUpHistoryChanged: slideAnim.restart()
 22:     onSlideOffsetChanged: requestPaint()
 23: 
 24:     onPaint: {
 25:         const ctx = getContext(&quot;2d&quot;)
 26:         ctx.clearRect(0, 0, width, height)
 27: 
 28:         if (!root.upHistory || !root.downHistory ||
 29:             root.upHistory.length &lt; 2 || root.downHistory.length &lt; 2) return
 30: 
 31:         const allVals = root.upHistory.concat(root.downHistory)
 32:         const maxVal  = Math.max(...allVals, 1024) 
 33: 
 34:         // 1. Save state and create a clipping mask so the graph doesn&apos;t bleed out
 35:         ctx.save()
 36:         ctx.beginPath()
 37:         ctx.rect(0, 0, width, height)
 38:         ctx.clip()
 39: 
 40:         // 2. Translate the canvas horizontally to animate the scroll
 41:         const step = width / Math.max(root.upHistory.length - 2, 1)
 42:         ctx.translate(slideOffset * step, 0)
 43: 
 44:         function drawLine(history, color) {
 45:             ctx.beginPath()
 46:             ctx.strokeStyle = color
 47:             ctx.lineWidth   = 2.0
 48:             ctx.lineJoin    = &quot;round&quot;
 49: 
 50:             // Shift initial X coordinate to the left by 1 step (-1) to hide data popping in
 51:             const points = history.map((v, i) =&gt; ({
 52:                 x: (i - 1) * step, 
 53:                 y: height - (v / maxVal) * height * 0.85 
 54:             }))
 55: 
 56:             ctx.moveTo(points[0].x, points[0].y)
 57: 
 58:             for (let i = 0; i &lt; points.length - 1; i++) {
 59:                 const p1 = points[i]
 60:                 const p2 = points[i + 1]
 61:                 const midX = (p1.x + p2.x) / 2
 62:                 const midY = (p1.y + p2.y) / 2
 63: 
 64:                 if (i === points.length - 2) {
 65:                     ctx.quadraticCurveTo(p1.x, p1.y, p2.x, p2.y)
 66:                 } else {
 67:                     ctx.quadraticCurveTo(p1.x, p1.y, midX, midY)
 68:                 }
 69:             }
 70:             ctx.stroke()
 71: 
 72:             // Fill under line safely using Qt.rgba
 73:             ctx.lineTo(points[points.length - 1].x, height)
 74:             ctx.lineTo(points[0].x, height)
 75:             ctx.closePath()
 76:             ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.2)
 77:             ctx.fill()
 78:         }
 79: 
 80:         drawLine(root.upHistory, Colors.tertiary)
 81:         drawLine(root.downHistory, Colors.primary)
 82: 
 83:         // 3. Restore state so the legend doesn&apos;t scroll or get clipped
 84:         ctx.restore()
 85:         const drawRoundedRect = (x, y, w, h, r) =&gt; {
 86:             ctx.beginPath()
 87:             ctx.moveTo(x + r, y)
 88:             ctx.lineTo(x + w - r, y)
 89:             ctx.quadraticCurveTo(x + w, y, x + w, y + r)
 90:             ctx.lineTo(x + w, y + h - r)
 91:             ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
 92:             ctx.lineTo(x + r, y + h)
 93:             ctx.quadraticCurveTo(x, y + h, x, y + h - r)
 94:             ctx.lineTo(x, y + r)
 95:             ctx.quadraticCurveTo(x, y, x + r, y)
 96:             ctx.closePath()
 97:         }
 98:         // 4. Draw a highly visible static legend card on top
 99:         ctx.fillStyle = Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.9)
100:         ctx.beginPath()
101:         drawRoundedRect(8, 8, 76, 44, 8)
102:         ctx.fill()
103:         
104:         ctx.strokeStyle = Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)
105:         ctx.lineWidth = 1
106:         ctx.stroke()
107: 
108:         ctx.font = &quot;bold 11px &apos;&quot; + Fonts.font + &quot;&apos;&quot;
109:         
110:         // Up label
111:         ctx.fillStyle = Colors.tertiary
112:         ctx.beginPath()
113:         ctx.arc(20, 20, 4, 0, 2 * Math.PI)
114:         ctx.fill()
115:         ctx.fillStyle = Colors.on_Surface
116:         ctx.fillText(&quot;Up&quot;, 32, 24)
117: 
118:         // Down label
119:         ctx.fillStyle = Colors.primary
120:         ctx.beginPath()
121:         ctx.arc(20, 36, 4, 0, 2 * Math.PI)
122:         ctx.fill()
123:         ctx.fillStyle = Colors.on_Surface
124:         ctx.fillText(&quot;Down&quot;, 32, 40)
125:     }
126: }</file><file path="src/popups/system/qmldir">1: module qs.src.popups.system
2: DiskBar         1.0    DiskBar.qml
3: NetworkGraph    1.0    NetworkGraph.qml
4: Speedometer     1.0    Speedometer.qml</file><file path="src/popups/system/Speedometer.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: Item {
 6:     id: root
 7: 
 8:     property real   value: 0.0
 9:     property string label: &quot;&quot;
10:     property color  color: Colors.primary
11: 
12:     implicitWidth:  100
13:     implicitHeight: 100
14: 
15:     Canvas {
16:         id: canvas
17:         anchors.fill: parent
18: 
19:         onPaint: {
20:             const ctx        = getContext(&quot;2d&quot;)
21:             const cx         = width  / 2
22:             const cy         = height / 2 + 10
23:             const radius     = Math.min(width, height) / 2 - 10
24:             const startAngle = 150 * Math.PI / 180
25:             const endAngle   = 390 * Math.PI / 180
26:             const valueAngle = startAngle + (endAngle - startAngle) * Math.min(root._animValue, 1.0)
27: 
28:             ctx.clearRect(0, 0, width, height)
29: 
30:             ctx.beginPath()
31:             ctx.arc(cx, cy, radius, startAngle, endAngle)
32:             ctx.strokeStyle = Qt.rgba(
33:                 Colors.outlineVariant.r,
34:                 Colors.outlineVariant.g,
35:                 Colors.outlineVariant.b, 0.4)
36:             ctx.lineWidth = 8
37:             ctx.lineCap   = &quot;round&quot;
38:             ctx.stroke()
39: 
40:             if (root._animValue &gt; 0) {
41:                 ctx.beginPath()
42:                 ctx.arc(cx, cy, radius, startAngle, valueAngle)
43:                 ctx.strokeStyle = root.color
44:                 ctx.lineWidth   = 8
45:                 ctx.lineCap     = &quot;round&quot;
46:                 ctx.stroke()
47:             }
48: 
49:             const ticks = [0.25, 0.5, 0.75]
50:             ticks.forEach(t =&gt; {
51:                 const angle = startAngle + (endAngle - startAngle) * t
52:                 const inner = radius - 12
53:                 const outer = radius - 6
54:                 ctx.beginPath()
55:                 ctx.moveTo(cx + inner * Math.cos(angle), cy + inner * Math.sin(angle))
56:                 ctx.lineTo(cx + outer * Math.cos(angle), cy + outer * Math.sin(angle))
57:                 ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.2)
58:                 ctx.lineWidth   = 1.5
59:                 ctx.stroke()
60:             })
61:         }
62:     }
63: 
64:     property real _animValue: 0.0
65: 
66:     onValueChanged: _animValue = value
67:     on_AnimValueChanged: canvas.requestPaint()
68: 
69:     Behavior on _animValue {
70:         NumberAnimation {
71:             duration:    800
72:             easing.type: Easing.OutCubic
73:         }
74:     }
75: 
76:     ColumnLayout {
77:         anchors.centerIn:            parent
78:         anchors.verticalCenterOffset: 8
79:         spacing: 0
80: 
81:         Text {
82:             Layout.alignment: Qt.AlignHCenter
83:             text:           Math.round(root._animValue * 100) + &quot;%&quot;
84:             color:          root.color
85:             font.pixelSize: 16
86:             font.bold:      true
87:             font.family:    Fonts.font
88:         }
89: 
90:         Text {
91:             Layout.alignment: Qt.AlignHCenter
92:             text:           root.label
93:             color:          Colors.on_SurfaceVariant
94:             font.pixelSize: 10
95:             font.family:    Fonts.font
96:         }
97:     }
98: }</file><file path="src/popups/ClipboardPopup.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import QtQuick.Controls
  4: import Quickshell
  5: import Quickshell.Wayland
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.services
 10: 
 11: PanelWindow {
 12:     id: root
 13: 
 14:     property var screen
 15: 
 16:     color: &quot;transparent&quot;
 17:     exclusionMode: ExclusionMode.Ignore
 18: 
 19:     anchors {
 20:         bottom: true
 21:         right: true
 22:     }
 23: 
 24:     implicitWidth: 720
 25:     implicitHeight: 520
 26: 
 27:     WlrLayershell.layer: WlrLayer.Overlay
 28:     WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
 29: 
 30:     visible: slide.windowVisible
 31: 
 32:     Connections {
 33:         target: Popups
 34: 
 35:         function onClipboardOpenChanged() {
 36:             if (Popups.clipboardOpen) {
 37:                 ClipboardService.refresh()
 38: 
 39:                 ClipboardService.searchQuery = &quot;&quot;
 40: 
 41:                 searchField.text = &quot;&quot;
 42: 
 43:                 listView.currentIndex = 0
 44: 
 45:                 searchField.forceActiveFocus()
 46:             }
 47:         }
 48:     }
 49: 
 50:     PopupSlide {
 51:         id: slide
 52: 
 53:         anchors.fill: parent
 54: 
 55:         edge: &quot;bottom&quot;
 56:         open: Popups.clipboardOpen
 57: 
 58:         onCloseRequested: Popups.clipboardOpen = false
 59: 
 60:         Rectangle {
 61:             anchors {
 62:                 bottom: parent.bottom
 63:                 right: parent.right
 64: 
 65:                 bottomMargin: 18
 66:                 rightMargin: 18
 67:             }
 68: 
 69:             width: 700
 70:             height: 420
 71: 
 72:             radius: Theme.popupRadius
 73: 
 74:             color: Colors.surfaceContainer
 75: 
 76:             border.color: Colors.outlineVariant
 77:             border.width: Theme.popupBorder
 78: 
 79:             clip: true
 80: 
 81:             ColumnLayout {
 82:                 id: mainCol
 83: 
 84:                 anchors {
 85:                     fill: parent
 86:                     margins: 16
 87:                 }
 88: 
 89:                 spacing: 12
 90: 
 91:                 RowLayout {
 92:                     Layout.fillWidth: true
 93: 
 94:                     spacing: 10
 95: 
 96:                     Text {
 97:                         text: &quot;󰆏&quot;
 98: 
 99:                         color: Colors.primary
100: 
101:                         font.pixelSize: 18
102:                         font.family: Fonts.fontM
103:                     }
104: 
105:                     TextField {
106:                         id: searchField
107: 
108:                         Layout.fillWidth: true
109: 
110:                         height: 32
111: 
112:                         placeholderText: &quot;Search clipboard...&quot;
113: 
114:                         font.family: Fonts.font
115:                         font.pixelSize: 12
116: 
117:                         color: Colors.on_Surface
118:                         placeholderTextColor: Colors.outline
119: 
120:                         onTextChanged: {
121:                             ClipboardService.searchQuery = text
122:                             listView.currentIndex = 0
123:                         }
124: 
125:                         Keys.onEscapePressed: {
126:                             Popups.clipboardOpen = false
127:                         }
128: 
129:                         Keys.onDownPressed: (event) =&gt; {
130:                             listView.forceActiveFocus()
131: 
132:                             listView.incrementCurrentIndex()
133: 
134:                             listView.positionViewAtIndex(
135:                                 listView.currentIndex,
136:                                 ListView.Contain
137:                             )
138: 
139:                             event.accepted = true
140:                         }
141: 
142:                         Keys.onUpPressed: (event) =&gt; {
143:                             listView.forceActiveFocus()
144: 
145:                             listView.decrementCurrentIndex()
146: 
147:                             listView.positionViewAtIndex(
148:                                 listView.currentIndex,
149:                                 ListView.Contain
150:                             )
151: 
152:                             event.accepted = true
153:                         }
154: 
155:                         background: Rectangle {
156:                             radius: 8
157: 
158:                             color: Colors.surfaceContainerHigh
159: 
160:                             border.width: 1
161: 
162:                             border.color:
163:                                 searchField.activeFocus
164:                                     ? Colors.primary
165:                                     : Colors.outline
166: 
167:                             Behavior on border.color {
168:                                 ColorAnimation {
169:                                     duration: Theme.hoverFadeDuration
170:                                 }
171:                             }
172:                         }
173:                     }
174: 
175:                     Rectangle {
176:                         width: 32
177:                         height: 32
178: 
179:                         radius: 8
180: 
181:                         color:
182:                             wipeHov.containsMouse
183:                                 ? Colors.errorContainer
184:                                 : &quot;transparent&quot;
185: 
186:                         Behavior on color {
187:                             ColorAnimation {
188:                                 duration: Theme.hoverFadeDuration
189:                             }
190:                         }
191: 
192:                         Text {
193:                             anchors.centerIn: parent
194: 
195:                             text: &quot;󰆴&quot;
196: 
197:                             font.family: Fonts.fontM
198:                             font.pixelSize: 16
199: 
200:                             color:
201:                                 wipeHov.containsMouse
202:                                     ? Colors.on_ErrorContainer
203:                                     : Colors.outline
204:                         }
205: 
206:                         MouseArea {
207:                             id: wipeHov
208: 
209:                             anchors.fill: parent
210: 
211:                             hoverEnabled: true
212: 
213:                             cursorShape: Qt.PointingHandCursor
214: 
215:                             onClicked: ClipboardService.wipe()
216:                         }
217:                     }
218:                 }
219: 
220:                 Rectangle {
221:                     Layout.fillWidth: true
222: 
223:                     height: 1
224: 
225:                     color: Colors.outlineVariant
226:                     opacity: 0.5
227:                 }
228: 
229:                 ListView {
230:                     id: listView
231: 
232:                     Layout.fillWidth: true
233:                     Layout.fillHeight: true
234: 
235:                     focus: true
236: 
237:                     currentIndex: 0
238: 
239:                     clip: true
240: 
241:                     spacing: 4
242: 
243:                     boundsBehavior: Flickable.StopAtBounds
244: 
245:                     flickDeceleration: 2500
246:                     maximumFlickVelocity: 5000
247: 
248:                     ScrollBar.vertical: ScrollBar {
249:                         policy: ScrollBar.AsNeeded
250:                     }
251: 
252:                     model: ClipboardService.filteredHistory
253: 
254:                     Keys.onPressed: (event) =&gt; {
255:                         if (event.key === Qt.Key_Down) {
256:                             incrementCurrentIndex()
257: 
258:                             positionViewAtIndex(
259:                                 currentIndex,
260:                                 ListView.Contain
261:                             )
262: 
263:                             event.accepted = true
264:                         }
265: 
266:                         else if (event.key === Qt.Key_Up) {
267:                             decrementCurrentIndex()
268: 
269:                             positionViewAtIndex(
270:                                 currentIndex,
271:                                 ListView.Contain
272:                             )
273: 
274:                             event.accepted = true
275:                         }
276: 
277:                         else if (
278:                             event.key === Qt.Key_Return ||
279:                             event.key === Qt.Key_Enter
280:                         ) {
281:                             const item =
282:                                 ClipboardService.filteredHistory[currentIndex]
283: 
284:                             if (item) {
285:                                 ClipboardService.copy(item)
286: 
287:                                 Popups.clipboardOpen = false
288:                             }
289: 
290:                             event.accepted = true
291:                         }
292: 
293:                         else if (
294:                             event.text.length &gt; 0 &amp;&amp;
295:                             event.key !== Qt.Key_Space
296:                         ) {
297:                             searchField.forceActiveFocus()
298: 
299:                             searchField.insert(
300:                                 searchField.cursorPosition,
301:                                 event.text
302:                             )
303: 
304:                             event.accepted = true
305:                         }
306:                     }
307: 
308:                     delegate: Rectangle {
309:                         required property var modelData
310:                         required property int index
311:                         readonly property string displayString: {
312:                             const idx = modelData.indexOf(&apos;\t&apos;)
313: 
314:                             return idx &gt;= 0
315:                                 ? modelData.substring(idx + 1)
316:                                 : modelData
317:                         }
318: 
319:                         width: listView.width - 6
320: 
321:                         height: Math.max(
322:                             40,
323:                             itemText.implicitHeight + 16
324:                         )
325: 
326:                         radius: 8
327: 
328:                         color: index === listView.currentIndex ? Colors.surfaceContainerHigh : itemHov.containsMouse ? Colors.background : &quot;transparent&quot;
329: 
330:                         Behavior on color {
331:                             ColorAnimation {
332:                                 duration: 140
333:                                 easing.type: Easing.OutCubic
334:                             }
335:                         }
336: 
337:                         Text {
338:                             id: itemText
339: 
340:                             anchors {
341:                                 left: parent.left
342:                                 right: parent.right
343: 
344:                                 verticalCenter: parent.verticalCenter
345: 
346:                                 margins: 12
347:                             }
348: 
349:                             text: displayString
350: 
351:                             color: Colors.on_Surface
352: 
353:                             font.family: Fonts.font
354:                             font.pixelSize: 12
355: 
356:                             maximumLineCount: 2
357: 
358:                             elide: Text.ElideRight
359: 
360:                             wrapMode: Text.WrapAnywhere
361:                         }
362: 
363:                         MouseArea {
364:                             id: itemHov
365: 
366:                             anchors.fill: parent
367: 
368:                             hoverEnabled: true
369: 
370:                             cursorShape: Qt.PointingHandCursor
371: 
372:                             onEntered: {
373:                                 listView.currentIndex = index
374:                             }
375: 
376:                             onClicked: {
377:                                 ClipboardService.copy(modelData)
378: 
379:                                 Popups.clipboardOpen = false
380:                             }
381:                         }
382:                     }
383:                 }
384: 
385:                 Text {
386:                     visible:
387:                         ClipboardService.filteredHistory.length === 0
388: 
389:                     Layout.alignment: Qt.AlignHCenter
390: 
391:                     text: &quot;Clipboard is empty&quot;
392: 
393:                     font.family: Fonts.font
394:                     font.pixelSize: 12
395: 
396:                     color: Colors.outline
397: 
398:                     topPadding: 16
399:                     bottomPadding: 16
400:                 }
401:             }
402:         }
403:     }
404: }</file><file path="src/popups/DeviceRow.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: // Single device row for the Devices tab
 6: // Shows device name, default indicator chip, and sets default on click
 7: 
 8: Item {
 9:     id: root
10: 
11:     property string deviceName: &quot;&quot;
12:     property bool   isDefault:  false
13:     property string icon:       &quot;󰓃&quot;
14: 
15:     signal activated()
16: 
17:     implicitHeight: 44
18: 
19:     Rectangle {
20:         anchors.fill: parent
21:         radius:       10
22:         color:        rowHov.containsMouse
23:                           ? Colors.surfaceContainerHighest
24:                           : (root.isDefault
25:                               ? Qt.rgba(
26:                                     Colors.primaryContainer.r,
27:                                     Colors.primaryContainer.g,
28:                                     Colors.primaryContainer.b, 0.3)
29:                               : &quot;transparent&quot;)
30:         Behavior on color { ColorAnimation { duration: 120 } }
31: 
32:         RowLayout {
33:             anchors { fill: parent; margins: 12 }
34:             spacing: 10
35: 
36:             // Device icon
37:             Text {
38:                 text:           root.icon
39:                 color:          root.isDefault ? Colors.primary : Colors.on_SurfaceVariant
40:                 font.pixelSize: 16
41:                 font.family:    Fonts.font
42:                 Behavior on color { ColorAnimation { duration: 120 } }
43:             }
44: 
45:             // Device name
46:             Text {
47:                 text:           root.deviceName
48:                 color:          root.isDefault ? Colors.on_Surface : Colors.on_SurfaceVariant
49:                 font.pixelSize: 12
50:                 font.bold:      root.isDefault
51:                 font.family:    Fonts.font
52:                 elide:          Text.ElideRight
53:                 Layout.fillWidth: true
54:                 Behavior on color { ColorAnimation { duration: 120 } }
55:             }
56: 
57:             // Default chip — filled pill with checkmark
58:             Rectangle {
59:                 visible: root.isDefault
60:                 width:   chipRow.implicitWidth + 16
61:                 height:  22
62:                 radius:  11
63:                 color:   Colors.primary
64: 
65:                 Row {
66:                     id:       chipRow
67:                     anchors.centerIn: parent
68:                     spacing:  4
69: 
70:                     Text {
71:                         text:           &quot;󰄵&quot;
72:                         color:          Colors.on_Primary
73:                         font.pixelSize: 10
74:                         font.family:    Fonts.font
75:                         anchors.verticalCenter: parent.verticalCenter
76:                     }
77: 
78:                     Text {
79:                         text:           &quot;Default&quot;
80:                         color:          Colors.on_Primary
81:                         font.pixelSize: 10
82:                         font.bold:      true
83:                         font.family:    Fonts.font
84:                         anchors.verticalCenter: parent.verticalCenter
85:                     }
86:                 }
87:             }
88:         }
89: 
90:         MouseArea {
91:             id:           rowHov
92:             anchors.fill: parent
93:             hoverEnabled: true
94:             cursorShape:  Qt.PointingHandCursor
95:             onClicked:    if (!root.isDefault) root.activated()
96:         }
97:     }
98: }</file><file path="src/popups/VolumeSlider.qml"> 1: import QtQuick
 2: import qs.src.theme
 3: 
 4: // Horizontal volume slider
 5: // Emits onMoved(value) when user drags or clicks
 6: 
 7: Item {
 8:     id: root
 9: 
10:     property real value: 0.0
11:     property bool muted: false
12: 
13:     signal moved(real value)
14: 
15:     implicitHeight: 36
16: 
17:     // Track
18:     Rectangle {
19:         id: track
20:         anchors.verticalCenter: parent.verticalCenter
21:         width:  parent.width
22:         height: 4
23:         radius: 2
24:         color:  Colors.surfaceContainerHighest
25: 
26:         // Fill
27:         Rectangle {
28:             width:  Math.max(handle.width / 2, track.width * root.value)
29:             height: parent.height
30:             radius: parent.radius
31:             color:  root.muted ? Colors.error : Colors.primary
32:             Behavior on width { NumberAnimation { duration: 80 } }
33:             Behavior on color { ColorAnimation  { duration: 120 } }
34:         }
35:     }
36: 
37:     // Handle
38:     Rectangle {
39:         id: handle
40:         width:  16
41:         height: 16
42:         radius: 8
43:         color:  root.muted ? Colors.error : Colors.primary
44:         anchors.verticalCenter: parent.verticalCenter
45:         x: Math.min(track.width - width, Math.max(0, track.width * root.value - width / 2))
46: 
47:         Behavior on color { ColorAnimation { duration: 120 } }
48: 
49:         // Glow when dragging
50:         Rectangle {
51:             anchors.centerIn: parent
52:             width:   parent.width + 8
53:             height:  parent.height + 8
54:             radius:  width / 2
55:             color:   Colors.primary
56:             opacity: dragArea.pressed ? 0.2 : 0
57:             Behavior on opacity { NumberAnimation { duration: 100 } }
58:         }
59:     }
60: 
61:     // Input
62:     MouseArea {
63:         id:           dragArea
64:         anchors.fill: parent
65:         hoverEnabled: true
66:         cursorShape:  Qt.PointingHandCursor
67: 
68:         function valueFromMouse(mouseX) {
69:             return Math.max(0.0, Math.min(1.0, mouseX / track.width))
70:         }
71: 
72:         onPressed:      (mouse) =&gt; root.moved(valueFromMouse(mouse.x))
73:         onPositionChanged: (mouse) =&gt; {
74:             if (pressed) root.moved(valueFromMouse(mouse.x))
75:         }
76: 
77:         onWheel: (wheel) =&gt; {
78:             root.moved(Math.max(0.0, Math.min(1.0,
79:                 root.value + (wheel.angleDelta.y &gt; 0 ? 0.05 : -0.05))))
80:         }
81:     }
82: }</file><file path="src/services/system/qmldir">1: singleton SystemStats 1.0 SystemStats.qml
2: # system submodule is imported as qs.src.services.system</file><file path="src/services/ClipboardService.qml"> 1: pragma Singleton
 2: 
 3: import QtQuick
 4: import Quickshell
 5: import Quickshell.Io
 6: 
 7: Singleton {
 8:     id: root
 9: 
10:     property var history: []
11:     property var filteredHistory: []
12:     property string searchQuery: &quot;&quot;
13: 
14:     onSearchQueryChanged: applyFilter()
15: 
16:     function refresh() {
17:         listProc.running = true
18:     }
19: 
20:     Process {
21:         id: listProc
22:         command: [&quot;cliphist&quot;, &quot;list&quot;]
23:         running: false
24: 
25:         property var _tempHist: []
26: 
27:         stdout: SplitParser {
28:             onRead: (line) =&gt; {
29:                 if (line.trim() !== &quot;&quot;) listProc._tempHist.push(line)
30:             }
31:         }
32:         onExited: {
33:             root.history = listProc._tempHist.slice()
34:             listProc._tempHist = []
35:             root.applyFilter()
36:         }
37:     }
38: 
39:     function applyFilter() {
40:         if (root.searchQuery === &quot;&quot;) {
41:             root.filteredHistory = root.history
42:         } else {
43:             const q = root.searchQuery.toLowerCase()
44:             root.filteredHistory = root.history.filter(item =&gt; {
45:                 const content = item.substring(item.indexOf(&apos;\t&apos;) + 1)
46:                 return content.toLowerCase().includes(q)
47:             })
48:         }
49:     }
50: 
51:     function copy(item) {
52:         copyProc.itemData = item
53:         copyProc.running = true
54:     }
55: 
56:     Process {
57:         id: copyProc
58:         property string itemData: &quot;&quot;
59:         command: [&quot;sh&quot;, &quot;-c&quot;, &quot;printf &apos;%s\n&apos; \&quot;$1\&quot; | cliphist decode | wl-copy&quot;, &quot;--&quot;, itemData]
60:         running: false
61:         onExited: root.refresh()
62:     }
63: 
64:     function wipe() {
65:         wipeProc.running = true
66:     }
67: 
68:     Process {
69:         id: wipeProc
70:         command: [&quot;cliphist&quot;, &quot;wipe&quot;]
71:         running: false
72:         onExited: root.refresh()
73:     }
74: }</file><file path="src/theme/qmldir">1: singleton Colors 1.0 Colors.qml
2: singleton Theme 1.0 Theme.qml
3: singleton Fonts 1.0 Fonts.qml</file><file path="src/theme/quickshell.json.hbs"> 1: {
 2:   &quot;background&quot;: &quot;{{colors.surface.default.hex}}&quot;,
 3:   &quot;on_background&quot;: &quot;{{colors.on_surface.default.hex}}&quot;,
 4:   &quot;primary&quot;: &quot;{{colors.primary.default.hex}}&quot;,
 5:   &quot;on_primary&quot;: &quot;{{colors.on_primary.default.hex}}&quot;,
 6:   &quot;primary_container&quot;: &quot;{{colors.primary_container.default.hex}}&quot;,
 7:   &quot;on_primary_container&quot;: &quot;{{colors.on_primary_container.default.hex}}&quot;,
 8:   &quot;primary_fixed&quot;: &quot;{{colors.primary_fixed.default.hex}}&quot;,
 9:   &quot;primary_fixed_dim&quot;: &quot;{{colors.primary_fixed_dim.default.hex}}&quot;,
10:   &quot;on_primary_fixed&quot;: &quot;{{colors.on_primary_fixed.default.hex}}&quot;,
11:   &quot;on_primary_fixed_variant&quot;: &quot;{{colors.on_primary_fixed_variant.default.hex}}&quot;,
12:   &quot;inverse_primary&quot;: &quot;{{colors.inverse_primary.default.hex}}&quot;,
13:   &quot;secondary&quot;: &quot;{{colors.secondary.default.hex}}&quot;,
14:   &quot;on_secondary&quot;: &quot;{{colors.on_secondary.default.hex}}&quot;,
15:   &quot;secondary_container&quot;: &quot;{{colors.secondary_container.default.hex}}&quot;,
16:   &quot;on_secondary_container&quot;: &quot;{{colors.on_secondary_container.default.hex}}&quot;,
17:   &quot;secondary_fixed&quot;: &quot;{{colors.secondary_fixed.default.hex}}&quot;,
18:   &quot;secondary_fixed_dim&quot;: &quot;{{colors.secondary_fixed_dim.default.hex}}&quot;,
19:   &quot;on_secondary_fixed&quot;: &quot;{{colors.on_secondary_fixed.default.hex}}&quot;,
20:   &quot;on_secondary_fixed_variant&quot;: &quot;{{colors.on_secondary_fixed_variant.default.hex}}&quot;,
21:   &quot;tertiary&quot;: &quot;{{colors.tertiary.default.hex}}&quot;,
22:   &quot;on_tertiary&quot;: &quot;{{colors.on_tertiary.default.hex}}&quot;,
23:   &quot;tertiary_container&quot;: &quot;{{colors.tertiary_container.default.hex}}&quot;,
24:   &quot;on_tertiary_container&quot;: &quot;{{colors.on_tertiary_container.default.hex}}&quot;,
25:   &quot;tertiary_fixed&quot;: &quot;{{colors.tertiary_fixed.default.hex}}&quot;,
26:   &quot;tertiary_fixed_dim&quot;: &quot;{{colors.tertiary_fixed_dim.default.hex}}&quot;,
27:   &quot;on_tertiary_fixed&quot;: &quot;{{colors.on_tertiary_fixed.default.hex}}&quot;,
28:   &quot;on_tertiary_fixed_variant&quot;: &quot;{{colors.on_tertiary_fixed_variant.default.hex}}&quot;,
29:   &quot;error&quot;: &quot;{{colors.error.default.hex}}&quot;,
30:   &quot;on_error&quot;: &quot;{{colors.on_error.default.hex}}&quot;,
31:   &quot;error_container&quot;: &quot;{{colors.error_container.default.hex}}&quot;,
32:   &quot;on_error_container&quot;: &quot;{{colors.on_error_container.default.hex}}&quot;,
33:   &quot;surface&quot;: &quot;{{colors.surface.default.hex}}&quot;,
34:   &quot;on_surface&quot;: &quot;{{colors.on_surface.default.hex}}&quot;,
35:   &quot;surface_variant&quot;: &quot;{{colors.surface_variant.default.hex}}&quot;,
36:   &quot;on_surface_variant&quot;: &quot;{{colors.on_surface_variant.default.hex}}&quot;,
37:   &quot;surface_dim&quot;: &quot;{{colors.surface_dim.default.hex}}&quot;,
38:   &quot;surface_bright&quot;: &quot;{{colors.surface_bright.default.hex}}&quot;,
39:   &quot;surface_container_lowest&quot;: &quot;{{colors.surface_container_lowest.default.hex}}&quot;,
40:   &quot;surface_container_low&quot;: &quot;{{colors.surface_container_low.default.hex}}&quot;,
41:   &quot;surface_container&quot;: &quot;{{colors.surface_container.default.hex}}&quot;,
42:   &quot;surface_container_high&quot;: &quot;{{colors.surface_container_high.default.hex}}&quot;,
43:   &quot;surface_container_highest&quot;: &quot;{{colors.surface_container_highest.default.hex}}&quot;,
44:   &quot;surface_tint&quot;: &quot;{{colors.primary.default.hex}}&quot;,
45:   &quot;inverse_surface&quot;: &quot;{{colors.inverse_surface.default.hex}}&quot;,
46:   &quot;inverse_on_surface&quot;: &quot;{{colors.inverse_on_surface.default.hex}}&quot;,
47:   &quot;outline&quot;: &quot;{{colors.outline.default.hex}}&quot;,
48:   &quot;outline_variant&quot;: &quot;{{colors.outline_variant.default.hex}}&quot;,
49:   &quot;shadow&quot;: &quot;#000000&quot;,
50:   &quot;scrim&quot;: &quot;#000000&quot;,
51:   &quot;source_color&quot;: &quot;{{colors.source_color.default.hex}}&quot;
52: }</file><file path="src/windows/qmldir">1: TopBar 1.0 TopBar.qml
2: PopupDismiss 1.0 PopupDismiss.qml</file><file path=".gitignore">1: quickshell.md</file><file path="src/modules/Center/IdleInhibitor.qml"> 1: import QtQuick
 2: import Quickshell
 3: import Quickshell.Io
 4: import qs.src.components
 5: import qs.src.theme
 6: import qs.src.state
 7: 
 8: PillBase {
 9:     id: root
10: 
11:     hoverExpand: true
12: 
13:     property bool inhibiting: false
14: 
15:     Process {
16:         id: inhibitProc
17:         command: [&quot;systemd-inhibit&quot;,
18:                   &quot;--what=idle&quot;,
19:                   &quot;--who=Quickshell&quot;,
20:                   &quot;--why=User requested&quot;,
21:                   &quot;--mode=block&quot;,
22:                   &quot;sleep&quot;, &quot;infinity&quot;]
23:         running: false
24: 
25:         onExited: root.inhibiting = false
26:     }
27: 
28:     Text {
29:         text:  root.inhibiting ? &quot;󰛨&quot; : &quot;󰾪&quot;
30:         color: root.inhibiting ? Colors.tertiary : Colors.primary
31:         font.pixelSize: 12
32:         font.family:    Fonts.font
33:         verticalAlignment: Text.AlignVCenter
34: 
35:         Behavior on color { ColorAnimation { duration: 150 } }
36:     }
37: 
38:     onClicked: {
39:         if (root.inhibiting) {
40:             inhibitProc.running  = false
41:         } else {
42:             inhibitProc.running  = true
43:         }
44:         root.inhibiting          = !root.inhibiting
45:         Popups.idleInhibitorOpen = !Popups.idleInhibitorOpen
46:     }
47: }</file><file path="src/modules/Right/Battery.qml"> 1: import QtQuick
 2: import Quickshell
 3: import qs.src.components
 4: import qs.src.theme
 5: import qs.src.services
 6: 
 7: PillBase {
 8:     id: root
 9: 
10:     visible: BatteryService.hasBattery
11:     hoverExpand: true
12: 
13:     function getIcon(): string {
14:         if (BatteryService.full)     return &quot;󰁹 &quot;
15:         if (BatteryService.charging) {
16:             if (BatteryService.capacity &gt;= 90) return &quot;󰂅 &quot;
17:             if (BatteryService.capacity &gt;= 80) return &quot;󰂄 &quot;
18:             if (BatteryService.capacity &gt;= 70) return &quot;󰂃 &quot;
19:             if (BatteryService.capacity &gt;= 60) return &quot;󰂂 &quot;
20:             if (BatteryService.capacity &gt;= 50) return &quot;󰂁 &quot;
21:             if (BatteryService.capacity &gt;= 40) return &quot;󰂀 &quot;
22:             if (BatteryService.capacity &gt;= 30) return &quot;󰁿 &quot;
23:             if (BatteryService.capacity &gt;= 20) return &quot;󰁾 &quot;
24:             if (BatteryService.capacity &gt;= 10) return &quot;󰁽 &quot;
25:             return &quot;󰁻 &quot;
26:         }
27:         if (BatteryService.capacity &gt;= 90) return &quot;󰁹 &quot;
28:         if (BatteryService.capacity &gt;= 80) return &quot;󰂀 &quot;
29:         if (BatteryService.capacity &gt;= 60) return &quot;󰁿 &quot;
30:         if (BatteryService.capacity &gt;= 40) return &quot;󰁼 &quot;
31:         if (BatteryService.capacity &gt;= 20) return &quot;󰁻 &quot;
32:         if (BatteryService.capacity &gt;= 10) return &quot;󰁺 &quot;
33:         return &quot;󰂎 &quot;
34:     }
35: 
36:     function getColor(): string {
37:         if (BatteryService.charging || BatteryService.full) return Colors.tertiary
38:         if (BatteryService.capacity &lt;= 10) return Colors.error
39:         return Colors.primary
40:     }
41: 
42:     Text {
43:         id: batteryText
44:         text: root.getIcon() + BatteryService.capacity + &quot;%&quot;
45:         color: root.getColor()
46:         font.pointSize: 11
47:         font.bold: true
48:         font.family: Fonts.font
49:         verticalAlignment: Text.AlignVCenter
50: 
51:         SequentialAnimation on opacity {
52:             running: BatteryService.capacity &lt;= 10 &amp;&amp; !BatteryService.charging
53:             loops:   Animation.Infinite
54: 
55:             NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
56:             NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
57:         }
58:     }
59: }</file><file path="src/modules/Right/NotificationButton.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import qs.src.components
 5: import qs.src.theme
 6: import qs.src.state
 7: import qs.src.services
 8: 
 9: PillBase {
10:     id: root
11: 
12:     hoverExpand: true
13: 
14:     // Highlight border when panel is open
15:     border.color: Colors.primary
16:     border.width: Popups.notificationsOpen ? 1 : 0
17:     Behavior on border.width { NumberAnimation { duration: 150 } }
18: 
19:     Row {
20:         spacing: 8
21: 
22:         Text {
23:             text: &quot;󰂚&quot;
24:             color: Colors.primary
25:             font.pointSize: 11
26:             font.family: Fonts.font
27:             verticalAlignment: Text.AlignVCenter
28:         }
29: 
30:         Text {
31:             visible: NotificationService.notifications.length &gt; 0
32:             text:    NotificationService.notifications.length
33:             color:   Colors.primary
34:             font.pointSize: 11
35:             font.bold: true
36:             font.family: Fonts.font
37:             verticalAlignment: Text.AlignVCenter
38:         }
39:     }
40: 
41:     onClicked: Popups.notificationsOpen = !Popups.notificationsOpen
42: }</file><file path="src/modules/Right/qmldir">1: SystemMonitor 1.0 SystemMonitor.qml
2: Volume 1.0 Volume.qml
3: Battery 1.0 Battery.qml
4: Tray 1.0 Tray.qml
5: NotificationButton 1.0 NotificationButton.qml
6: Network 1.0 Network.qml</file><file path="src/popups/launcher/LauncherAppLoader.qml"> 1: import QtQuick
 2: import Quickshell.Io
 3: 
 4: QtObject {
 5:     id: root
 6: 
 7:     signal loaded(var apps)
 8: 
 9:     property bool   loading: false
10:     property string _buf:    &quot;&quot;
11: 
12:     readonly property string scriptPath:
13:         Qt.resolvedUrl(&quot;resolve_apps.py&quot;).toString().slice(7)
14: 
15:     function reload() {
16:         _buf    = &quot;&quot;
17:         loading = true
18:         loaderProc.running = true
19:     }
20: 
21:     property Process loaderProc: Process {
22:         command: [&quot;python3&quot;, root.scriptPath]
23:         running: false
24: 
25:         stdout: SplitParser {
26:             onRead: (line) =&gt; { root._buf += line }
27:         }
28: 
29:         stderr: SplitParser {
30:             onRead: (line) =&gt; { console.warn(&quot;[resolve_apps]&quot;, line) }
31:         }
32: 
33:         onExited: (code, status) =&gt; {
34:             root.loading = false
35:             if (code !== 0) {
36:                 console.warn(&quot;[resolve_apps] exited with code&quot;, code)
37:                 root.loaded([])
38:                 return
39:             }
40:             try {
41:                 root.loaded(JSON.parse(root._buf))
42:             } catch(e) {
43:                 console.warn(&quot;[resolve_apps] JSON parse failed:&quot;, e, root._buf.slice(0, 120))
44:                 root.loaded([])
45:             }
46:         }
47:     }
48: }</file><file path="src/popups/launcher/LauncherResultItem.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import qs.src.theme
  4: 
  5: Item {
  6:     id: root
  7: 
  8:     // ── Inputs ────────────────────────────────────────────────────────────
  9:     property var  appData:    ({})
 10:     property bool isSelected: false
 11: 
 12:     // ── Outputs ───────────────────────────────────────────────────────────
 13:     signal activated()
 14:     signal hovered()
 15: 
 16:     height: 54
 17: 
 18:     // ── Selection background ──────────────────────────────────────────────
 19:     Rectangle {
 20:         anchors.fill: parent
 21:         topRightRadius: 15
 22:         bottomRightRadius: 15
 23:         color: root.isSelected
 24:                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
 25:                    : hov.containsMouse
 26:                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
 27:                        : &quot;transparent&quot;
 28:         Behavior on color { ColorAnimation { duration: 80 } }
 29:     }
 30: 
 31:     // ── Left accent bar ───────────────────────────────────────────────────
 32:     Rectangle {
 33:         anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
 34:         width:   3
 35:         radius:  1.5
 36:         color:   Colors.primary
 37:         opacity: root.isSelected ? 1 : 0
 38:         Behavior on opacity { NumberAnimation { duration: 120 } }
 39:     }
 40: 
 41:     // ── Row content ───────────────────────────────────────────────────────
 42:     RowLayout {
 43:         anchors { fill: parent; leftMargin: 16; rightMargin: 14 }
 44:         spacing: 12
 45: 
 46:         // App icon — real icon with letter fallback
 47:         Rectangle {
 48:             width:  36
 49:             height: 36
 50:             radius: 9
 51:             color:  iconImg.status === Image.Ready
 52:                         ? &quot;transparent&quot;
 53:                         : (root.isSelected ? Colors.primaryContainer : Colors.surfaceContainerHigh)
 54:             Layout.alignment: Qt.AlignVCenter
 55:             Behavior on color { ColorAnimation { duration: 120 } }
 56: 
 57:             Image {
 58:                 id:              iconImg
 59:                 anchors.fill:    parent
 60:                 anchors.margins: 3
 61:                 source:          root.appData.icon ? (&quot;file://&quot; + root.appData.icon) : &quot;&quot;
 62:                 fillMode:        Image.PreserveAspectFit
 63:                 smooth:          true
 64:                 mipmap:          true
 65:                 visible:         status === Image.Ready
 66:                 asynchronous:    true
 67:             }
 68: 
 69:             Text {
 70:                 anchors.centerIn: parent
 71:                 visible:          iconImg.status !== Image.Ready
 72:                 text:             (root.appData.name || &quot;?&quot;).charAt(0).toUpperCase()
 73:                 color:            root.isSelected ? Colors.on_PrimaryContainer : Colors.on_SurfaceVariant
 74:                 font.pixelSize:   15
 75:                 font.bold:        true
 76:                 font.family:      Fonts.fontM
 77:                 Behavior on color { ColorAnimation { duration: 120 } }
 78:             }
 79:         }
 80: 
 81:         // Name + comment
 82:         ColumnLayout {
 83:             Layout.fillWidth: true
 84:             spacing: 2
 85: 
 86:             Text {
 87:                 text:             root.appData.name || &quot;&quot;
 88:                 color:            root.isSelected ? Colors.on_Surface : Colors.on_SurfaceVariant
 89:                 font.pixelSize:   13
 90:                 font.weight:      root.isSelected ? Font.Medium : Font.Normal
 91:                 font.family:      Fonts.fontM
 92:                 elide:            Text.ElideRight
 93:                 Layout.fillWidth: true
 94:                 Behavior on color { ColorAnimation { duration: 100 } }
 95:             }
 96: 
 97:             Text {
 98:                 visible:          root.appData.comment !== &quot;&quot; &amp;&amp; root.appData.comment !== undefined
 99:                 text:             root.appData.comment || &quot;&quot;
100:                 color:            Colors.on_SurfaceVariant
101:                 font.pixelSize:   11
102:                 font.family:      Fonts.font
103:                 elide:            Text.ElideRight
104:                 Layout.fillWidth: true
105:                 opacity:          0.65
106:             }
107:         }
108: 
109:         // Enter hint on selected row
110:         Text {
111:             visible:        root.isSelected
112:             text:           &quot;↵&quot;
113:             color:          Colors.primary
114:             font.pixelSize: 14
115:             font.family:    Fonts.font
116:             opacity:        0.7
117:         }
118:     }
119: 
120:     // ── Mouse ─────────────────────────────────────────────────────────────
121:     MouseArea {
122:         id:           hov
123:         anchors.fill: parent
124:         hoverEnabled: true
125:         cursorShape:  Qt.PointingHandCursor
126:         onClicked:    root.activated()
127:         onEntered:    root.hovered()
128:     }
129: }</file><file path="src/popups/launcher/LauncherResultsList.qml"> 1: import QtQuick
 2: import QtQuick.Controls
 3: import qs.src.theme
 4: 
 5: Item {
 6:     id: root
 7: 
 8:     // ── Inputs ────────────────────────────────────────────────────────────
 9:     property var   filteredApps:  []
10:     property int   selectedIndex: 0
11:     property string searchText:   &quot;&quot;
12: 
13:     // ── Outputs ───────────────────────────────────────────────────────────
14:     signal launched(int index)
15:     signal selectionChanged(int index)
16: 
17:     function positionAt(idx) {
18:         listView.positionViewAtIndex(idx, ListView.Contain)
19:     }
20: 
21:     // ── Height (deterministic — no binding loops) ─────────────────────────
22:     readonly property int itemH:    54
23:     readonly property int emptyH:   72
24:     readonly property int maxListH: 416
25: 
26:     height: filteredApps.length &gt; 0
27:                 ? Math.min(filteredApps.length * itemH, maxListH)
28:                 : emptyH
29: 
30:     // ── Empty / loading state ─────────────────────────────────────────────
31:     Item {
32:         anchors { top: parent.top; left: parent.left; right: parent.right }
33:         height: root.emptyH
34:         visible: root.filteredApps.length === 0
35: 
36:         Text {
37:             anchors.centerIn: parent
38:             text:             root.searchText === &quot;&quot;
39:                                   ? &quot;Loading applications…&quot;
40:                                   : &quot;No results for &quot; + root.searchText + &quot;&quot;
41:             color:            Colors.on_SurfaceVariant
42:             font.pixelSize:   13
43:             font.family:      Fonts.font
44:             opacity:          0.6
45:         }
46:     }
47: 
48:     // ── Results list ──────────────────────────────────────────────────────
49:     ListView {
50:         id:      listView
51:         anchors.fill:    parent
52:         visible:         root.filteredApps.length &gt; 0
53:         model:           root.filteredApps
54:         clip:            true
55:         boundsBehavior:  Flickable.StopAtBounds
56:         keyNavigationEnabled: false
57: 
58:         ScrollBar.vertical: ScrollBar {
59:             policy: listView.contentHeight &gt; listView.height
60:                         ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
61:             contentItem: Rectangle {
62:                 implicitWidth:  3
63:                 implicitHeight: 40
64:                 radius:         1.5
65:                 color:          Qt.rgba(1, 1, 1, 0.25)
66:             }
67:             background: Item {}
68:         }
69: 
70:         delegate: LauncherResultItem {
71:             required property var modelData
72:             required property int index
73: 
74:             width:      listView.width - (listView.contentHeight &gt; listView.height ? 10 : 0)
75:             appData:    modelData
76:             isSelected: index === root.selectedIndex
77: 
78:             onActivated: root.launched(index)
79:             onHovered:   root.selectionChanged(index)
80:         }
81:     }
82: }</file><file path="src/popups/launcher/resolve_apps.py">  1: import os
  2: import json
  3: import configparser
  4: import glob
  5: 
  6: 
  7: def find_icon(name, size=48):
  8:     if not name:
  9:         return &quot;&quot;
 10: 
 11:     # Already an absolute path
 12:     if os.path.isabs(name):
 13:         if os.path.exists(name):
 14:             return name
 15:         for ext in (&quot;.png&quot;, &quot;.svg&quot;, &quot;.xpm&quot;):
 16:             if os.path.exists(name + ext):
 17:                 return name + ext
 18:         return &quot;&quot;
 19: 
 20:     # Strip known extensions to get bare name
 21:     base = name
 22:     for ext in (&quot;.png&quot;, &quot;.svg&quot;, &quot;.xpm&quot;):
 23:         if base.endswith(ext):
 24:             base = base[: -len(ext)]
 25:             break
 26: 
 27:     # Detect active GTK icon theme
 28:     themes = [&quot;hicolor&quot;]
 29:     for cfg in [
 30:         os.path.expanduser(&quot;~/.config/gtk-4.0/settings.ini&quot;),
 31:         os.path.expanduser(&quot;~/.config/gtk-3.0/settings.ini&quot;),
 32:     ]:
 33:         try:
 34:             for line in open(cfg):
 35:                 if &quot;gtk-icon-theme-name&quot; in line:
 36:                     themes.insert(0, line.split(&quot;=&quot;, 1)[1].strip())
 37:                     break
 38:         except OSError:
 39:             pass
 40: 
 41:     roots = [
 42:         os.path.expanduser(&quot;~/.local/share/icons&quot;),
 43:         &quot;/usr/share/icons&quot;,
 44:     ]
 45:     sizes = [
 46:         f&quot;{size}x{size}&quot;,
 47:         &quot;scalable&quot;,
 48:         &quot;48x48&quot;,
 49:         &quot;32x32&quot;,
 50:         &quot;64x64&quot;,
 51:         &quot;128x128&quot;,
 52:         &quot;256x256&quot;,
 53:         &quot;22x22&quot;,
 54:     ]
 55:     categories = [&quot;apps&quot;, &quot;applications&quot;]
 56:     extensions = [&quot;svg&quot;, &quot;png&quot;, &quot;xpm&quot;]
 57: 
 58:     for root in roots:
 59:         for theme in themes:
 60:             for sz in sizes:
 61:                 for cat in categories:
 62:                     for ext in extensions:
 63:                         path = os.path.join(root, theme, sz, cat, f&quot;{base}.{ext}&quot;)
 64:                         if os.path.exists(path):
 65:                             return path
 66: 
 67:     # Fallback: pixmaps
 68:     for d in [&quot;/usr/share/pixmaps&quot;, os.path.expanduser(&quot;~/.local/share/pixmaps&quot;)]:
 69:         for ext in extensions:
 70:             path = os.path.join(d, f&quot;{base}.{ext}&quot;)
 71:             if os.path.exists(path):
 72:                 return path
 73: 
 74:     return &quot;&quot;
 75: 
 76: 
 77: def load_apps():
 78:     apps = []
 79:     seen = set()
 80:     dirs = [
 81:         &quot;/usr/share/applications&quot;,
 82:         os.path.expanduser(&quot;~/.local/share/applications&quot;),
 83:     ]
 84: 
 85:     for d in dirs:
 86:         for f in sorted(glob.glob(os.path.join(d, &quot;*.desktop&quot;))):
 87:             parser = configparser.RawConfigParser(strict=False)
 88:             try:
 89:                 parser.read(f)
 90:             except Exception:
 91:                 continue
 92: 
 93:             if &quot;Desktop Entry&quot; not in parser:
 94:                 continue
 95: 
 96:             entry = parser[&quot;Desktop Entry&quot;]
 97: 
 98:             if entry.get(&quot;Type&quot;) != &quot;Application&quot;:
 99:                 continue
100:             if entry.get(&quot;NoDisplay&quot;, &quot;&quot;).lower() == &quot;true&quot;:
101:                 continue
102: 
103:             name = entry.get(&quot;Name&quot;, &quot;&quot;)
104:             if not name or name in seen:
105:                 continue
106: 
107:             seen.add(name)
108:             apps.append(
109:                 {
110:                     &quot;name&quot;: name,
111:                     &quot;exec&quot;: entry.get(&quot;Exec&quot;, &quot;&quot;),
112:                     &quot;icon&quot;: find_icon(entry.get(&quot;Icon&quot;, &quot;&quot;)),
113:                     &quot;comment&quot;: entry.get(&quot;Comment&quot;, &quot;&quot;),
114:                 }
115:             )
116: 
117:     apps.sort(key=lambda x: x[&quot;name&quot;].lower())
118:     print(json.dumps(apps))
119: 
120: 
121: if __name__ == &quot;__main__&quot;:
122:     load_apps()</file><file path="src/popups/media/qmldir">1: # module qs.src.popups.media
2: MediaArt        1.0 MediaArt.qml
3: MediaTrackInfo  1.0 MediaTrackInfo.qml
4: MediaProgress   1.0 MediaProgress.qml
5: MediaControls   1.0 MediaControls.qml
6: MediaVolumeRow  1.0 MediaVolumeRow.qml</file><file path="src/popups/NotificationToast.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import Quickshell.Wayland
 5: import Quickshell.Services.Notifications
 6: import qs.src.theme
 7: import qs.src.state
 8: import qs.src.services
 9: 
10: // Fixed-size PanelWindow — surface never resizes, only content animates
11: PanelWindow {
12:     id: root
13: 
14:     property var screen
15: 
16:     color:         &quot;transparent&quot;
17:     exclusionMode: ExclusionMode.Ignore
18: 
19:     anchors {
20:         bottom: true
21:         right:  true
22:     }
23: 
24:     // Fixed dimensions — large enough for max 5 toasts stacked
25:     // Never bind these to content or the surface will jump
26:     implicitWidth:  380
27:     implicitHeight: 500
28: 
29:     mask: Region {
30:         Region {
31:             x: root.width - 360 - 12
32:             y: root.height - 2 - (NotificationService.activeToasts.length * 88)
33:             width: 360
34:             height: NotificationService.activeToasts.length * 88
35:         }
36:     }
37: 
38:     WlrLayershell.layer: WlrLayer.Overlay
39: 
40:     // ── Toast stack ───────────────────────────────────────────────────────────
41:     // Toasts anchor to the bottom, stack upward
42:     // New toast slides in from the right, existing ones animate upward
43: 
44:     Item {
45:         anchors {
46:             bottom: parent.bottom
47:             right:  parent.right
48:             bottomMargin: 12
49:             rightMargin:  12
50:         }
51:         width:  360
52:         height: parent.height - 24
53: 
54:         Repeater {
55:             id: toastRepeater
56:             model: NotificationService.activeToasts
57: 
58:             delegate: ToastItem {
59:                 required property var modelData
60:                 required property int index
61: 
62:                 notifId:     modelData
63:                 toastIndex:  index
64:                 totalToasts: NotificationService.activeToasts.length
65:             }
66:         }
67:     }
68: }</file><file path="src/services/VolumeService.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: import Quickshell.Services.Pipewire
 5: 
 6: Singleton {
 7:     id: root
 8: 
 9:     // ── Output ────────────────────────────────────────────────────────────────
10:     PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
11: 
12:     property var  sink:   Pipewire.defaultAudioSink
13:     property var  audio:  sink?.audio ?? null
14:     property real volume: audio?.volume ?? 0.0
15:     property bool muted:  audio?.muted  ?? false
16: 
17:     function toggleMute() {
18:         if (audio) audio.muted = !audio.muted
19:     }
20: 
21:     function changeVolume(step) {
22:         if (audio)
23:             audio.volume = Math.max(0.0, Math.min(1.0, audio.volume + step))
24:     }
25: 
26:     // ── Input ─────────────────────────────────────────────────────────────────
27:     PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
28: 
29:     property var  source:      Pipewire.defaultAudioSource
30:     property var  inputAudio:  source?.audio ?? null
31:     property real inputVolume: inputAudio?.volume ?? 0.0
32:     property bool inputMuted:  inputAudio?.muted  ?? false
33: 
34:     function toggleInputMute() {
35:         if (inputAudio) inputAudio.muted = !inputAudio.muted
36:     }
37: 
38:     function changeInputVolume(step) {
39:         if (inputAudio)
40:             inputAudio.volume = Math.max(0.0, Math.min(1.0, inputAudio.volume + step))
41:     }
42: }</file><file path="src/state/qmldir">1: singleton Popups Popups.qml
2: singleton ShellState ShellState.qml</file><file path="src/theme/Colors.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: import Quickshell.Io
 5: 
 6: QtObject {
 7:     id: root
 8: 
 9:     property var palette: ({})
10: 
11:     property FileView watcher: FileView {
12:         path: Quickshell.shellPath(&quot;src/theme/Colors.json&quot;)
13:         watchChanges: true
14:         onFileChanged: reload()
15: 
16:         onTextChanged: {
17:             try {
18:                 if (text() !== &quot;&quot;) {
19:                     root.palette = JSON.parse(text())
20:                 }
21:             } catch (e) {}
22:         }
23:     }
24: 
25:     // --- Background &amp; Surface ---
26:     readonly property color background:              palette.background                || &quot;#1a1111&quot;
27:     readonly property color on_Background:           palette.on_background             || &quot;#f1dedd&quot;
28:     readonly property color surface:                 palette.surface                   || &quot;#1a1111&quot;
29:     readonly property color on_Surface:              palette.on_surface                || &quot;#f1dedd&quot;
30:     readonly property color surfaceVariant:          palette.surface_variant           || &quot;#534342&quot;
31:     readonly property color on_SurfaceVariant:       palette.on_surface_variant        || &quot;#d8c2c0&quot;
32:     readonly property color surfaceContainer:        palette.surface_container         || &quot;#271d1d&quot;
33:     readonly property color surfaceContainerHigh:    palette.surface_container_high    || &quot;#322827&quot;
34:     readonly property color surfaceContainerHighest: palette.surface_container_highest || &quot;#3d3231&quot;
35: 
36:     // --- Primary ---
37:     readonly property color primary:                 palette.primary                   || &quot;#ffb3af&quot;
38:     readonly property color on_Primary:              palette.on_primary                || &quot;#571d1c&quot;
39:     readonly property color primaryContainer:        palette.primary_container         || &quot;#733331&quot;
40:     readonly property color on_PrimaryContainer:     palette.on_primary_container      || &quot;#ffdad7&quot;
41: 
42:     // --- Secondary ---
43:     readonly property color secondary:               palette.secondary                 || &quot;#e7bdba&quot;
44:     readonly property color on_Secondary:            palette.on_secondary              || &quot;#442928&quot;
45:     readonly property color secondaryContainer:      palette.secondary_container       || &quot;#5d3f3d&quot;
46:     readonly property color on_SecondaryContainer:   palette.on_secondary_container    || &quot;#ffdad7&quot;
47: 
48:     // --- Tertiary ---
49:     readonly property color tertiary:                palette.tertiary                  || &quot;#e2c28c&quot;
50:     readonly property color on_Tertiary:             palette.on_tertiary               || &quot;#402d05&quot;
51:     readonly property color tertiaryContainer:       palette.tertiary_container        || &quot;#594319&quot;
52:     readonly property color on_TertiaryContainer:    palette.on_tertiary_container     || &quot;#ffdea8&quot;
53: 
54:     // --- Error &amp; Utility ---
55:     readonly property color error:                   palette.error                     || &quot;#ffb4ab&quot;
56:     readonly property color on_Error:                palette.on_error                  || &quot;#690005&quot;
57:     readonly property color errorContainer:          palette.error_container           || &quot;#93000a&quot;
58:     readonly property color on_ErrorContainer:       palette.on_error_container        || &quot;#ffdad6&quot;
59:     readonly property color outline:                 palette.outline                   || &quot;#a08c8b&quot;
60:     readonly property color outlineVariant:          palette.outline_variant           || &quot;#534342&quot;
61:     readonly property color shadow:                  palette.shadow                    || &quot;#000000&quot;
62: }</file><file path="src/components/PopupSlide.qml"> 1: import QtQuick
 2: import qs.src.state
 3: import qs.src.theme
 4: 
 5: // Slide-in/out animation container for all popups.
 6: // Always bind your PopupWindow.visible to slide.windowVisible
 7: 
 8: Item {
 9:     id: root
10: 
11:     // ── Required ──────────────────────────────────────────────────────────────
12:     property string edge: &quot;top&quot; // &quot;top&quot; | &quot;bottom&quot; | &quot;left&quot; | &quot;right&quot;
13:     property bool   open: false
14: 
15:     // ── Hover-to-open (Optional) ──────────────────────────────────────────────
16:     property bool hoverEnabled:   false
17:     property bool triggerHovered: false
18: 
19:     // ── Timing ────────────────────────────────────────────────────────────────
20:     property int slideDuration: Theme.slideInDuration
21:     property int closeDelay:    Theme.hoverCloseDelay
22: 
23:     // ── Output ────────────────────────────────────────────────────────────────
24:     // Bind your PopupWindow.visible to this
25:     property bool windowVisible: false
26: 
27:     signal closeRequested()
28: 
29:     // ── Internal ──────────────────────────────────────────────────────────────
30:     property bool _selfHovered: false
31: 
32:     readonly property bool _effectiveOpen: open || (hoverEnabled &amp;&amp; (triggerHovered || _selfHovered))
33: 
34:     default property alias content: inner.data
35: 
36:     clip: true
37: 
38:     on_EffectiveOpenChanged: {
39:         if (_effectiveOpen) { hoverCloseTimer.stop(); windowVisible = true } 
40:         else { hoverEnabled ? hoverCloseTimer.restart() : slideCloseTimer.restart() }
41:     }
42: 
43:     // Wait for slide animation to finish before hiding the window
44:     Timer {
45:         id:          slideCloseTimer
46:         interval:    root.slideDuration + 20
47:         onTriggered: root.windowVisible = false
48:     }
49: 
50:     // Hover leave — wait then emit closeRequested
51:     Timer {
52:         id:          hoverCloseTimer
53:         interval:    root.closeDelay
54:         onTriggered: {
55:             if (!root.triggerHovered &amp;&amp; !root._selfHovered) {
56:                 root.windowVisible = false
57:                 root.closeRequested()
58:             }
59:         }
60:     }
61: 
62:     // ── Sliding Item ──────────────────────────────────────────────────────────
63:     Item {
64:         id:     inner
65:         width:  parent.width
66:         height: parent.height
67: 
68:         x: root._effectiveOpen ? 0 : (root.edge === &quot;left&quot; ? -width : root.edge === &quot;right&quot; ? width : 0)
69:         y: root._effectiveOpen ? 0 : (root.edge === &quot;top&quot; ? -height : root.edge === &quot;bottom&quot; ? height : 0)
70: 
71:         Behavior on x { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }
72:         Behavior on y { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }
73: 
74:         HoverHandler {
75:             onHoveredChanged: root._selfHovered = hovered
76:         }
77:     }
78: }</file><file path="src/modules/Left/WindowName.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import Quickshell.Hyprland
 5: import qs.src.components
 6: import qs.src.theme
 7: 
 8: PillBase {
 9:     id: root
10: 
11:     hoverExpand: false
12: 
13:     property string windowTitle: Hyprland.activeToplevel
14:         ? Hyprland.activeToplevel.title
15:         : &quot;Desktop&quot;
16: 
17:     Text {
18:         text:              root.windowTitle
19:         color:             Colors.primary
20:         font.pointSize:    11
21:         font.bold:         true
22:         font.family:       Fonts.font
23:         elide:             Text.ElideRight
24:         Layout.fillWidth:  true
25:         Layout.maximumWidth: 250
26:         Layout.alignment:  Qt.AlignVCenter
27:     }
28: }</file><file path="src/modules/Right/Tray.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import Quickshell.Services.SystemTray
 5: import qs.src.components
 6: import qs.src.theme
 7: 
 8: PillBase {
 9:     id: root
10: 
11:     property var window
12: 
13:     hoverExpand: false  // tray expands differently via its own toggle
14:     hoverEnabled: false
15:     mouseEnabled: false
16:     visible: SystemTray.items.values.length &gt; 0
17: 
18:     Row {
19:         id: trayRow
20:         spacing: 10
21: 
22:         Repeater {
23:             model: SystemTray.items.values
24: 
25:             delegate: Item {
26:                 id: trayDelegate
27:                 required property var modelData
28: 
29:                 width:  20
30:                 height: 20
31: 
32:                 Image {
33:                     anchors.fill: parent
34:                     source: modelData.icon || &quot;&quot;
35:                     fillMode: Image.PreserveAspectFit
36:                     smooth: true
37:                 }
38: 
39:                 MouseArea {
40:                     anchors.fill: parent
41:                     hoverEnabled: true
42:                     cursorShape: Qt.PointingHandCursor
43:                     acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
44: 
45:                     onClicked: (mouse) =&gt; {
46:                         if (mouse.button === Qt.LeftButton)
47:                             modelData.activate()
48:                         else if (mouse.button === Qt.MiddleButton)
49:                             modelData.secondaryActivate()
50:                         else if (mouse.button === Qt.RightButton) {
51:                             var pos = mapToItem(null, mouse.x, mouse.y)
52:                             modelData.display(root.window, pos.x, pos.y)
53:                         }
54:                     }
55: 
56:                     onWheel: (wheel) =&gt; {
57:                         modelData.scroll(wheel.angleDelta.y &gt; 0 ? 1 : -1, false)
58:                     }
59:                 }
60:             }
61:         }
62:     }
63: }</file><file path="src/popups/ToastItem.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell.Services.Notifications
  4: import qs.src.theme
  5: import qs.src.services
  6: 
  7: Item {
  8:     id: root
  9: 
 10:     property int notifId:     0
 11:     property int toastIndex:  0
 12:     property int totalToasts: 1
 13: 
 14:     // Find the actual notification object
 15:     property var notif: {
 16:         const all = NotificationService.server.trackedNotifications.values
 17:         for (let i = 0; i &lt; all.length; i++) {
 18:             if (all[i].id === root.notifId) return all[i]
 19:         }
 20:         return null
 21:     }
 22: 
 23:     readonly property int toastHeight: 80
 24:     readonly property int toastSpacing: 8
 25: 
 26:     // Position: bottom of stack = index 0, stacks upward
 27:     // Each toast sits at: bottom - (index * (height + spacing))
 28:     width:  360
 29:     height: toastHeight
 30: 
 31:     anchors {
 32:         bottom:       parent.bottom
 33:         right:        parent.right
 34:         bottomMargin: root.toastIndex * (root.toastHeight + root.toastSpacing)
 35:     }
 36: 
 37:     Behavior on anchors.bottomMargin {
 38:         NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
 39:     }
 40: 
 41:     // ── Slide in from right ───────────────────────────────────────────────────
 42:     property bool _visible: false
 43: 
 44:     Component.onCompleted: {
 45:         slideInTimer.start()
 46:     }
 47: 
 48:     Timer {
 49:         id: slideInTimer
 50:         interval: 16  // one frame delay so anchor is set before animation starts
 51:         onTriggered: root._visible = true
 52:     }
 53: 
 54:     x:       root._visible ? 0 : root.width + 20
 55:     opacity: root._visible ? 1 : 0
 56: 
 57:     Behavior on x {
 58:         NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
 59:     }
 60:     Behavior on opacity {
 61:         NumberAnimation { duration: 250 }
 62:     }
 63: 
 64:     // ── Toast card ────────────────────────────────────────────────────────────
 65:     Rectangle {
 66:         anchors.fill: parent
 67:         radius:       Theme.popupRadius
 68:         color:        Colors.surfaceContainerHigh
 69:         border.color: Colors.outlineVariant
 70:         border.width: Theme.popupBorder
 71: 
 72:         // Drop shadow feel via layered rectangles
 73:         Rectangle {
 74:             anchors {
 75:                 fill:        parent
 76:                 topMargin:   2
 77:                 leftMargin:  2
 78:                 rightMargin: -2
 79:                 bottomMargin: -2
 80:             }
 81:             radius: parent.radius
 82:             color:  Colors.shadow
 83:             opacity: 0.3
 84:             z: -1
 85:         }
 86: 
 87:         RowLayout {
 88:             anchors {
 89:                 fill:    parent
 90:                 margins: 12
 91:             }
 92:             spacing: 10
 93: 
 94:             // App icon
 95:             Rectangle {
 96:                 width:  36
 97:                 height: 36
 98:                 radius: 8
 99:                 color:  Colors.primaryContainer
100:                 Layout.alignment: Qt.AlignTop
101: 
102:                 Image {
103:                     anchors.centerIn: parent
104:                     width:   22
105:                     height:  22
106:                     source:  root.notif &amp;&amp; root.notif.appIcon
107:                                  ? &quot;image://icon/&quot; + root.notif.appIcon
108:                                  : &quot;&quot;
109:                     visible: source !== &quot;&quot;
110:                     fillMode: Image.PreserveAspectFit
111:                     smooth:   true
112:                 }
113: 
114:                 // Fallback icon when no app icon available
115:                 Text {
116:                     anchors.centerIn: parent
117:                     visible:          !(root.notif &amp;&amp; root.notif.appIcon)
118:                     text:             &quot;󰂚&quot;
119:                     font.pixelSize:   16
120:                     font.family:      Fonts.font
121:                     color:            Colors.on_PrimaryContainer
122:                 }
123:             }
124: 
125:             // Text content
126:             ColumnLayout {
127:                 Layout.fillWidth: true
128:                 spacing: 2
129: 
130:                 RowLayout {
131:                     Layout.fillWidth: true
132: 
133:                     Text {
134:                         text:           root.notif ? (root.notif.appName || &quot;&quot;) : &quot;&quot;
135:                         color:          Colors.on_SurfaceVariant
136:                         font.pixelSize: 10
137:                         font.family:    Fonts.font
138:                         Layout.fillWidth: true
139:                         elide: Text.ElideRight
140:                     }
141: 
142:                     // Timestamp — binds to _tick so updates every 30s
143:                     Text {
144:                         text: root.notif
145:                             ? NotificationService.formatTimestamp(
146:                                 NotificationService.getPanelArrivalTime(root.notifId))
147:                             : &quot;&quot;
148:                         color:          Colors.outline
149:                         font.pixelSize: 10
150:                         font.family:    Fonts.font
151:                     }
152:                 }
153: 
154:                 Text {
155:                     text:           root.notif ? (root.notif.summary || &quot;&quot;) : &quot;&quot;
156:                     color:          Colors.on_Surface
157:                     font.pixelSize: 12
158:                     font.bold:      true
159:                     font.family:    Fonts.font
160:                     Layout.fillWidth: true
161:                     elide: Text.ElideRight
162:                 }
163: 
164:                 Text {
165:                     visible:        root.notif ? (root.notif.body !== &quot;&quot;) : false
166:                     text:           root.notif ? root.notif.body : &quot;&quot;
167:                     color:          Colors.on_SurfaceVariant
168:                     font.pixelSize: 11
169:                     font.family:    Fonts.font
170:                     Layout.fillWidth: true
171:                     elide:          Text.ElideRight
172:                     maximumLineCount: 2
173:                     wrapMode:       Text.WordWrap
174:                 }
175:             }
176: 
177:             // Dismiss button
178:             Rectangle {
179:                 width:  20
180:                 height: 20
181:                 radius: 10
182:                 color:  dismissHov.containsMouse
183:                             ? Qt.rgba(1, 1, 1, 0.12)
184:                             : &quot;transparent&quot;
185:                 Layout.alignment: Qt.AlignTop
186: 
187:                 Text {
188:                     anchors.centerIn: parent
189:                     text:             &quot;󰅖&quot;
190:                     font.pixelSize:   11
191:                     font.family:      Fonts.font
192:                     color:            Colors.on_SurfaceVariant
193:                 }
194: 
195:                 MouseArea {
196:                     id:           dismissHov
197:                     anchors.fill: parent
198:                     hoverEnabled: true
199:                     cursorShape:  Qt.PointingHandCursor
200:                     onClicked: {
201:                         if (root.notif) root.notif.dismiss()
202:                         NotificationService.removeToast(root.notifId)
203:                     }
204:                 }
205:             }
206:         }
207:     }
208: }</file><file path="src/services/BatteryService.qml"> 1: pragma Singleton
 2: 
 3: import QtQuick
 4: import Quickshell
 5: import Quickshell.Io
 6: 
 7: Singleton {
 8:     id: root
 9: 
10:     // ── Battery State ─────────────────────────────────────────────────────────
11:     property int    capacity:   0
12:     property bool   charging:   false
13:     property bool   full:       false
14:     property string status:     &quot;Unknown&quot;
15:     property bool   hasBattery: false
16: 
17:     readonly property real fraction: capacity / 100
18: 
19:     // ── Polling Processes ─────────────────────────────────────────────────────
20:     Process {
21:         id: _finder
22:         command: [&quot;sh&quot;, &quot;-c&quot;, &quot;ls /sys/class/power_supply/BAT*/capacity 2&gt;/dev/null | head -n 1&quot;]
23:         running: true
24:         stdout: SplitParser {
25:             onRead: (line) =&gt; {
26:                 const path = line.trim()
27:                 if (path) {
28:                     _capProc.command = [&quot;cat&quot;, path]
29:                     _statProc.command = [&quot;cat&quot;, path.replace(&quot;/capacity&quot;, &quot;/status&quot;)]
30:                     root.hasBattery = true
31:                     _capProc.running = true
32:                     _statProc.running = true
33:                 }
34:             }
35:         }
36:     }
37: 
38:     Process { 
39:         id: _capProc
40:         command: [&quot;cat&quot;, &quot;/dev/null&quot;]
41:         running: false
42:         stdout: SplitParser { 
43:             onRead: (d) =&gt; { 
44:                 const v = parseInt(d)
45:                 if (!isNaN(v)) { 
46:                     root.capacity = v
47:                     root.hasBattery = true 
48:                 } 
49:             } 
50:         } 
51:     }
52: 
53:     Process { 
54:         id: _statProc
55:         command: [&quot;cat&quot;, &quot;/dev/null&quot;]
56:         running: false
57:         stdout: SplitParser { 
58:             onRead: (d) =&gt; { 
59:                 const s = d.trim()
60:                 root.status = s
61:                 root.charging = s === &quot;Charging&quot;
62:                 root.full = s === &quot;Full&quot; 
63:             } 
64:         } 
65:     }
66: 
67:     // ── Polling Timer ─────────────────────────────────────────────────────────
68:     Timer {
69:         interval: 30000
70:         repeat:   true
71:         running:  true
72:         
73:         onTriggered: {
74:             _capProc.running  = true
75:             _statProc.running = true
76:         }
77:     }
78: }</file><file path="src/services/NotificationService.qml">  1: pragma Singleton
  2: import QtQuick
  3: import Quickshell
  4: import Quickshell.Services.Notifications
  5: 
  6: Singleton {
  7:     id: root
  8: 
  9:     property bool panelVisible: false
 10:     property var  activeToasts: []
 11:     property var  _toastData:   []
 12: 
 13:     property NotificationServer server: NotificationServer {
 14:         bodySupported:    true
 15:         actionsSupported: true
 16: 
 17:         onNotification: (notif) =&gt; {
 18:             notif.tracked = true
 19:             let tData = root._toastData.slice()
 20:             tData.push({
 21:                 id:        notif.id,
 22:                 expires:   Date.now() + 4000,
 23:                 arrivedAt: Date.now()        // ← timestamp stored here
 24:             })
 25:             root._toastData = tData
 26:             updateActiveToasts()
 27:         }
 28:     }
 29: 
 30:     // Returns the arrivedAt timestamp for a given notification id
 31:     function getArrivalTime(id) {
 32:         const entry = root._toastData.find(t =&gt; t.id === id)
 33:         return entry ? entry.arrivedAt : Date.now()
 34:     }
 35: 
 36:     // Also expose arrival time for panel — panel uses full tracked list
 37:     // so we keep a separate persistent map that survives toast expiry
 38:     property var _arrivalMap: ({})
 39: 
 40:     onActiveToastsChanged: {
 41:         // Sync arrivals into persistent map
 42:         root._toastData.forEach(t =&gt; {
 43:             if (!root._arrivalMap[t.id])
 44:                 root._arrivalMap[t.id] = t.arrivedAt
 45:         })
 46:     }
 47: 
 48:     function getPanelArrivalTime(id) {
 49:         return root._arrivalMap[id] || Date.now()
 50:     }
 51: 
 52:     function updateActiveToasts() {
 53:         root.activeToasts = root._toastData.map(t =&gt; t.id)
 54:     }
 55: 
 56:     function removeToast(id) {
 57:         let tData = root._toastData.slice()
 58:         let idx   = tData.findIndex(t =&gt; t.id === id)
 59:         if (idx &lt; 0) return
 60:         tData.splice(idx, 1)
 61:         root._toastData = tData
 62:         updateActiveToasts()
 63:     }
 64: 
 65:     function clearAll() {
 66:         // FIX: Copy the live list into a static array before iterating
 67:         // so dismissing an item doesn&apos;t shift the indices underneath us!
 68:         const allNotifs = [...server.trackedNotifications.values]
 69:         allNotifs.forEach(n =&gt; n.dismiss())
 70:         root._arrivalMap = {}
 71:     }
 72: 
 73:     readonly property var notifications: server.trackedNotifications.values
 74: 
 75:     // Expiry timer
 76:     Timer {
 77:         interval:  500
 78:         running:   root._toastData.length &gt; 0
 79:         repeat:    true
 80:         onTriggered: {
 81:             const now   = Date.now()
 82:             let tData   = root._toastData.slice()
 83:             let changed = false
 84:             for (let i = tData.length - 1; i &gt;= 0; i--) {
 85:                 if (now &gt;= tData[i].expires) {
 86:                     tData.splice(i, 1)
 87:                     changed = true
 88:                 }
 89:             }
 90:             if (changed) {
 91:                 root._toastData = tData
 92:                 updateActiveToasts()
 93:             }
 94:         }
 95:     }
 96: 
 97:     // Timestamp refresh timer — drives relative time updates in UI
 98:     // Fires every 30s, fast enough for &quot;just now&quot; → &quot;1 min ago&quot; transitions
 99:     property int _tick: 0
100:     Timer {
101:         interval: 30000
102:         running:  true
103:         repeat:   true
104:         onTriggered: root._tick++
105:     }
106: 
107:     // Formats a timestamp into relative or absolute string
108:     // Any component that needs a timestamp binds to both the timestamp
109:     // AND root._tick so it re-evaluates every 30s
110:     function formatTimestamp(arrivedAt) {
111:         const _ = root._tick  // creates binding dependency
112:         const diff = Date.now() - arrivedAt
113:         const mins = Math.floor(diff / 60000)
114:         const hrs  = Math.floor(diff / 3600000)
115: 
116:         if (mins &lt; 1)   return &quot;just now&quot;
117:         if (mins &lt; 60)  return mins + &quot; min&quot; + (mins &gt; 1 ? &quot;s&quot; : &quot;&quot;) + &quot; ago&quot;
118: 
119:         // Over an hour — show absolute time
120:         const d = new Date(arrivedAt)
121:         let h   = d.getHours()
122:         const m = d.getMinutes().toString().padStart(2, &quot;0&quot;)
123:         const ampm = h &gt;= 12 ? &quot;PM&quot; : &quot;AM&quot;
124:         h = h % 12 || 12
125:         return h + &quot;:&quot; + m + &quot; &quot; + ampm
126:     }
127: }</file><file path="src/state/ShellState.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: import Quickshell.Hyprland
 5: 
 6: Singleton {
 7:     id: root
 8: 
 9:     // ── Top bar notch widths (written by TopBar, read by PopupDismiss) ─────────
10:     property int topBarLWidth: 0
11:     property int topBarCWidth: 0
12:     property int topBarRWidth: 0
13: 
14:     // ── Focus mode ────────────────────────────────────────────────────────────
15:     // true = bar collapses to thin strip
16:     readonly property bool focusMode: (_isFullscreen || _manualHide) &amp;&amp; !_manualOverride
17: 
18:     property bool _isFullscreen:   false
19:     property bool _manualHide:     false
20:     property bool _manualOverride: false
21: 
22:     // Called by keybind via IPC or GlobalShortcut
23:     function toggleManualOverride() {
24:         // Only meaningful when fullscreen is active
25:         if (_isFullscreen || _manualHide)
26:             _manualOverride = !_manualOverride
27:     }
28: 
29:     function toggleManualHide() {
30:         _manualHide = !_manualHide
31:         _manualOverride = false
32:     }
33: 
34:     // Reset override when fullscreen exits so bar returns to full automatically
35:     on_IsFullscreenChanged: {
36:         if (!_isFullscreen)
37:             _manualOverride = false
38:     }
39: 
40:     // ── Hyprland fullscreen detection ─────────────────────────────────────────
41:     Connections {
42:         target: Hyprland
43: 
44:         function onRawEvent(event) {
45:             if (event.name === &quot;fullscreen&quot;) {
46:                 // data is &quot;1&quot; when entering fullscreen, &quot;0&quot; when leaving
47:                 root._isFullscreen = (event.data === &quot;1&quot;)
48:             }
49:         }
50:     }
51: }</file><file path="src/theme/Colors.json"> 1: {
 2:   &quot;background&quot;: &quot;#19120c&quot;,
 3:   &quot;on_background&quot;: &quot;#efe0d5&quot;,
 4:   &quot;primary&quot;: &quot;#feb876&quot;,
 5:   &quot;on_primary&quot;: &quot;#4b2800&quot;,
 6:   &quot;primary_container&quot;: &quot;#6a3b02&quot;,
 7:   &quot;on_primary_container&quot;: &quot;#ffdcbf&quot;,
 8:   &quot;primary_fixed&quot;: &quot;#ffdcbf&quot;,
 9:   &quot;primary_fixed_dim&quot;: &quot;#feb876&quot;,
10:   &quot;on_primary_fixed&quot;: &quot;#2d1600&quot;,
11:   &quot;on_primary_fixed_variant&quot;: &quot;#6a3b02&quot;,
12:   &quot;inverse_primary&quot;: &quot;#86521a&quot;,
13:   &quot;secondary&quot;: &quot;#e2c0a4&quot;,
14:   &quot;on_secondary&quot;: &quot;#412c18&quot;,
15:   &quot;secondary_container&quot;: &quot;#59422d&quot;,
16:   &quot;on_secondary_container&quot;: &quot;#ffdcbf&quot;,
17:   &quot;secondary_fixed&quot;: &quot;#ffdcbf&quot;,
18:   &quot;secondary_fixed_dim&quot;: &quot;#e2c0a4&quot;,
19:   &quot;on_secondary_fixed&quot;: &quot;#291806&quot;,
20:   &quot;on_secondary_fixed_variant&quot;: &quot;#59422d&quot;,
21:   &quot;tertiary&quot;: &quot;#c1cc99&quot;,
22:   &quot;on_tertiary&quot;: &quot;#2b340f&quot;,
23:   &quot;tertiary_container&quot;: &quot;#424b23&quot;,
24:   &quot;on_tertiary_container&quot;: &quot;#dde8b3&quot;,
25:   &quot;tertiary_fixed&quot;: &quot;#dde8b3&quot;,
26:   &quot;tertiary_fixed_dim&quot;: &quot;#c1cc99&quot;,
27:   &quot;on_tertiary_fixed&quot;: &quot;#171e00&quot;,
28:   &quot;on_tertiary_fixed_variant&quot;: &quot;#424b23&quot;,
29:   &quot;error&quot;: &quot;#ffb4ab&quot;,
30:   &quot;on_error&quot;: &quot;#690005&quot;,
31:   &quot;error_container&quot;: &quot;#93000a&quot;,
32:   &quot;on_error_container&quot;: &quot;#ffdad6&quot;,
33:   &quot;surface&quot;: &quot;#19120c&quot;,
34:   &quot;on_surface&quot;: &quot;#efe0d5&quot;,
35:   &quot;surface_variant&quot;: &quot;#51443a&quot;,
36:   &quot;on_surface_variant&quot;: &quot;#d5c3b6&quot;,
37:   &quot;surface_dim&quot;: &quot;#19120c&quot;,
38:   &quot;surface_bright&quot;: &quot;#403830&quot;,
39:   &quot;surface_container_lowest&quot;: &quot;#130d07&quot;,
40:   &quot;surface_container_low&quot;: &quot;#211a14&quot;,
41:   &quot;surface_container&quot;: &quot;#261e18&quot;,
42:   &quot;surface_container_high&quot;: &quot;#312822&quot;,
43:   &quot;surface_container_highest&quot;: &quot;#3c332c&quot;,
44:   &quot;surface_tint&quot;: &quot;#feb876&quot;,
45:   &quot;inverse_surface&quot;: &quot;#efe0d5&quot;,
46:   &quot;inverse_on_surface&quot;: &quot;#372f28&quot;,
47:   &quot;outline&quot;: &quot;#9e8e81&quot;,
48:   &quot;outline_variant&quot;: &quot;#51443a&quot;,
49:   &quot;shadow&quot;: &quot;#000000&quot;,
50:   &quot;scrim&quot;: &quot;#000000&quot;,
51:   &quot;source_color&quot;: &quot;#211912&quot;
52: }</file><file path="src/windows/PopupDismiss.qml"> 1: import QtQuick
 2: import Quickshell
 3: import Quickshell.Wayland
 4: import Quickshell.Hyprland
 5: import qs.src.state
 6: import qs.src.theme
 7: 
 8: // Transparent fullscreen overlay that dismisses all popups when:
 9: //   - User clicks anywhere outside a popup
10: //   - User presses Escape
11: //
12: // Only active when at least one popup is open.
13: 
14: PanelWindow {
15:     id: root
16: 
17:     color: &quot;transparent&quot;
18: 
19:     anchors {
20:         top:    true
21:         left:   true
22:         right:  true
23:         bottom: true
24:     }
25: 
26:     // Carve out the bar and notch regions so clicks pass through to the bar
27:     mask: Region {
28:         // Main screen area below the bar
29:         Region {
30:             x:      0
31:             y:      Theme.barHeight
32:             width:  root.width
33:             height: root.height - Theme.barHeight
34:         }
35:         // Gap between left notch and center
36:         Region {
37:             x:      ShellState.topBarLWidth
38:             y:      0
39:             width:  (root.width - ShellState.topBarCWidth) / 2 - ShellState.topBarLWidth
40:             height: Theme.barHeight
41:         }
42:         // Gap between center and right notch
43:         Region {
44:             x:      (root.width + ShellState.topBarCWidth) / 2
45:             y:      0
46:             width:  (root.width - ShellState.topBarCWidth) / 2 - ShellState.topBarRWidth
47:             height: Theme.barHeight
48:         }
49:     }
50: 
51:     // Don&apos;t push windows away
52:     exclusionMode: ExclusionMode.Ignore
53: 
54:     // Only grab input when a popup is open
55:     visible: Popups.anyOpen
56: 
57:     WlrLayershell.layer:         WlrLayer.Top
58:     WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
59: 
60:     // Click outside → close all
61:     MouseArea {
62:         anchors.fill: parent
63:         onClicked:    Popups.closeAll()
64:     }
65: 
66:     // Escape → close all
67:     Item {
68:         anchors.fill: parent
69:         focus:        root.visible
70: 
71:         Keys.onEscapePressed: Popups.closeAll()
72:     }
73: 
74:     // Workspace/window change → close all
75:     Connections {
76:         target: Hyprland
77: 
78:         function onRawEvent(event) {
79:             const triggers = [&quot;workspace&quot;, &quot;activemonitor&quot;, &quot;activespecial&quot;, &quot;openwindow&quot;]
80:             if (triggers.includes(event.name))
81:                 Popups.closeAll()
82:         }
83:     }
84: }</file><file path="src/components/PopupPage.qml"> 1: import QtQuick
 2: import QtQuick.Controls
 3: import qs.src.theme
 4: 
 5: // Scrollable content container for popup pages.
 6: // Wrap your popup&apos;s inner content in this instead of a plain Column.
 7: //
 8: // Usage:
 9: //   PopupPage {
10: //       anchors.fill: parent
11: //       // children go here
12: //   }
13: 
14: Item {
15:     id: root
16: 
17:     default property alias content: contentCol.data
18: 
19:     property int padH: 8
20:     property int padV: 8
21: 
22:     clip: true
23: 
24:     Flickable {
25:         id: flick
26:         anchors.fill:   parent
27:         contentWidth:   width
28:         contentHeight:  contentCol.implicitHeight + root.padV * 2
29:         boundsBehavior: Flickable.StopAtBounds
30:         clip:           true
31: 
32:         ScrollBar.vertical: ScrollBar {
33:             policy: contentCol.implicitHeight + root.padV * 2 &gt; flick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
34:             
35:             contentItem: Rectangle {
36:                 implicitWidth:  3
37:                 implicitHeight: 40
38:                 radius:         1.5
39:                 color:          Qt.rgba(1, 1, 1, 0.25)
40:             }
41:             background: Item {}
42:         }
43: 
44:         Column {
45:             id: contentCol
46:             spacing: 8
47:             anchors {
48:                 top:         parent.top
49:                 topMargin:   root.padV
50:                 left:        parent.left
51:                 leftMargin:  root.padH
52:                 right:       parent.right
53:                 rightMargin: root.padH + 6
54:             }
55:         }
56:     }
57: }</file><file path="src/components/qmldir">1: PillBase   1.0 PillBase.qml
2: PopupPage  1.0 PopupPage.qml
3: PopupSlide 1.0 PopupSlide.qml
4: TabBar     1.0 TabBar.qml</file><file path="src/components/TrayContextMenu.qml">  1: import Qt5Compat.GraphicalEffects
  2: import QtQuick
  3: import QtQuick.Layouts
  4: import Quickshell
  5: import Quickshell.Hyprland
  6: import Quickshell.Wayland
  7: import qs.src.theme
  8: 
  9: PanelWindow {
 10:     id: root
 11: 
 12:     // ── Properties ────────────────────────────────────────────────────────────
 13:     property var  menuHandle: null
 14:     property real menuX:      0
 15:     property real menuY:      0
 16:     property bool hasCurrent: false
 17:     property int  animLength: 400
 18:     property var  animCurve:  [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
 19: 
 20:     // ── Methods ───────────────────────────────────────────────────────────────
 21:     function open(handle, x, y) {
 22:         menuHandle = handle
 23:         const safeX = Math.max(8, Math.min(x - 120, Screen.width - 248))
 24:         menuX = safeX
 25:         menuY = y - 32
 26:         hasCurrent = true
 27:         grabTimer.restart()
 28:     }
 29: 
 30:     function close() {
 31:         hasCurrent       = false
 32:         focusGrab.active = false
 33:         grabTimer.stop()
 34:     }
 35: 
 36:     // ── Window Config ─────────────────────────────────────────────────────────
 37:     color: &quot;transparent&quot;
 38:     anchors { top: true; bottom: true; left: true; right: true }
 39:     
 40:     WlrLayershell.layer:         WlrLayer.Overlay
 41:     WlrLayershell.keyboardFocus: hasCurrent ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
 42: 
 43:     mask: Region {
 44:         item: hasCurrent ? root.contentItem : null
 45:     }
 46: 
 47:     HyprlandFocusGrab {
 48:         id:        focusGrab
 49:         windows:   [root]
 50:         onCleared: root.close()
 51:     }
 52: 
 53:     Timer {
 54:         id:          grabTimer
 55:         interval:    50
 56:         onTriggered: focusGrab.active = true
 57:     }
 58: 
 59:     // Click outside to close
 60:     MouseArea {
 61:         anchors.fill: parent
 62:         enabled:      root.hasCurrent
 63:         onClicked:    root.close()
 64:     }
 65: 
 66:     // ── Menu Wrapper ──────────────────────────────────────────────────────────
 67:     Item {
 68:         id: wrapper
 69: 
 70:         readonly property real topPad:        8
 71:         readonly property real bottomPad:     8
 72:         readonly property real contentHeight: topPad + menuColumn.implicitHeight + bottomPad
 73: 
 74:         x:              root.menuX
 75:         y:              root.menuY
 76:         width:          240
 77:         visible:        height &gt; 0
 78:         clip:           true
 79:         implicitHeight: root.hasCurrent ? Math.max(contentHeight, 52) : 0
 80: 
 81:         Behavior on implicitHeight {
 82:             NumberAnimation {
 83:                 duration:           root.animLength
 84:                 easing.type:        Easing.BezierSpline
 85:                 easing.bezierCurve: root.animCurve
 86:             }
 87:         }
 88: 
 89:         Rectangle {
 90:             id:                menuBg
 91:             anchors.fill:      parent
 92:             color:             Colors.background
 93:             clip:              true
 94:             bottomLeftRadius:  14
 95:             bottomRightRadius: 14
 96: 
 97:             QsMenuOpener {
 98:                 id:   opener
 99:                 menu: root.menuHandle
100:             }
101: 
102:             Rectangle {
103:                 id: highlight
104: 
105:                 property real targetY: 0
106:                 property bool active:  false
107: 
108:                 x:       8
109:                 y:       menuColumn.y + targetY
110:                 width:   parent.width - 16
111:                 height:  36
112:                 radius:  8
113:                 color:   Colors.primary
114:                 opacity: active ? 0.15 : 0
115: 
116:                 Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
117:                 Behavior on opacity { NumberAnimation { duration: 150 } }
118:             }
119: 
120:             Column {
121:                 id: menuColumn
122:                 spacing: 2
123:                 anchors {
124:                     top:         parent.top
125:                     left:        parent.left
126:                     right:       parent.right
127:                     topMargin:   8
128:                     leftMargin:  8
129:                     rightMargin: 8
130:                 }
131: 
132:                 onChildrenChanged: highlight.active = false
133: 
134:                 Repeater {
135:                     model: opener.children
136: 
137:                     delegate: Item {
138:                         id: menuItem
139: 
140:                         required property var modelData
141:                         required property int index
142: 
143:                         property bool isSeparator: modelData.isSeparator
144:                         property bool hasChildren: modelData.hasChildren
145: 
146:                         width:  menuColumn.width
147:                         height: isSeparator ? 12 : 36
148: 
149:                         // Separator line
150:                         Rectangle {
151:                             visible:          isSeparator
152:                             anchors.centerIn: parent
153:                             width:            parent.width - 16
154:                             height:           1
155:                             color:            Colors.primary
156:                             opacity:          0.5
157:                         }
158: 
159:                         // Active indicator bar
160:                         Rectangle {
161:                             visible: !isSeparator &amp;&amp; highlight.active &amp;&amp; highlight.targetY === menuItem.y
162:                             width:   3
163:                             height:  16
164:                             radius:  2
165:                             color:   Colors.primary
166:                             anchors {
167:                                 left:           parent.left
168:                                 leftMargin:     4
169:                                 verticalCenter: parent.verticalCenter
170:                             }
171:                         }
172: 
173:                         RowLayout {
174:                             visible: !isSeparator
175:                             spacing: 12
176:                             anchors {
177:                                 fill:        parent
178:                                 leftMargin:  12
179:                                 rightMargin: 12
180:                             }
181: 
182:                             Item {
183:                                 Layout.preferredWidth:  20
184:                                 Layout.preferredHeight: 20
185: 
186:                                 Image {
187:                                     anchors.centerIn: parent
188:                                     width:            16
189:                                     height:           16
190:                                     source:           modelData.icon || &quot;&quot;
191:                                     fillMode:         Image.PreserveAspectFit
192:                                     visible:          modelData.icon !== undefined &amp;&amp; modelData.icon !== &quot;&quot;
193:                                     layer.enabled:    true
194:                                     layer.effect:     ColorOverlay { color: Colors.primary }
195:                                 }
196:                             }
197: 
198:                             Text {
199:                                 text:              modelData.text || &quot;&quot;
200:                                 color:             Colors.primary
201:                                 font.pixelSize:    13
202:                                 font.bold:         true
203:                                 font.family:       Fonts.font
204:                                 verticalAlignment: Text.AlignVCenter
205:                                 elide:             Text.ElideRight
206:                                 Layout.fillWidth:  true
207:                             }
208: 
209:                             Text {
210:                                 visible:           menuItem.hasChildren
211:                                 text:              &quot;›&quot;
212:                                 color:             Colors.primary
213:                                 font.pixelSize:    16
214:                                 font.bold:         true
215:                                 opacity:           0.7
216:                                 verticalAlignment: Text.AlignVCenter
217:                             }
218:                         }
219: 
220:                         // QsMenuAnchor for native submenu display
221:                         QsMenuAnchor {
222:                             id:   anchor
223:                             menu: menuItem.hasChildren ? menuItem.modelData : null
224: 
225:                             anchor.window:      root
226:                             anchor.rect.x:      menuItem.x + wrapper.x + menuBg.x + menuColumn.x + menuItem.width
227:                             anchor.rect.y:      menuItem.y + wrapper.y + menuBg.y + menuColumn.y
228:                             anchor.rect.width:  0
229:                             anchor.rect.height: menuItem.height
230:                             anchor.edges:       Edges.Right | Edges.Top
231:                         }
232: 
233:                         MouseArea {
234:                             id:           itemMouse
235:                             anchors.fill: parent
236:                             hoverEnabled: true
237:                             cursorShape:  isSeparator ? Qt.ArrowCursor : Qt.PointingHandCursor
238: 
239:                             onEntered: { if (!menuItem.isSeparator) { highlight.targetY = menuItem.y; highlight.active = true } }
240:                             onClicked: {
241:                                 if (menuItem.isSeparator) return
242:                                 menuItem.hasChildren ? anchor.open() : (menuItem.modelData.triggered(), root.close())
243:                             }
244:                         }
245:                     }
246:                 }
247:             }
248:         }
249:     }
250: }</file><file path="src/modules/Center/Media.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Services.Mpris
  5: import Qt5Compat.GraphicalEffects
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: 
 10: Row {
 11:     id: root
 12: 
 13:     spacing: 6
 14: 
 15:     property var players: Mpris.players.values
 16:     property var _lastActive: null
 17: 
 18:     property var _currentlyPlaying: {
 19:         if (players.length === 0) return null
 20: 
 21:         let bestMatch = null
 22: 
 23:         for (let i = 0; i &lt; players.length; i++) {
 24:             let state = players[i].playbackState
 25: 
 26:             if (state === MprisPlaybackState.Playing &amp;&amp; bestMatch === null) {
 27:                 bestMatch = players[i]
 28:             }
 29:         }
 30:         return bestMatch
 31:     }
 32: 
 33:     on_CurrentlyPlayingChanged: {
 34:         if (_currentlyPlaying) {
 35:             _lastActive = _currentlyPlaying
 36:         }
 37:     }
 38: 
 39:     property var activePlayer: {
 40:         if (players.length === 0) return null
 41: 
 42:         if (_currentlyPlaying) return _currentlyPlaying
 43: 
 44:         if (_lastActive) {
 45:             for (let i = 0; i &lt; players.length; i++) {
 46:                 if (players[i] === _lastActive) return _lastActive
 47:             }
 48:         }
 49: 
 50:         return players[0]
 51:     }
 52:     property bool hasArt:       activePlayer &amp;&amp; activePlayer.trackArtUrl !== &quot;&quot;
 53:     property bool isPlaying:    activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
 54: 
 55:     visible: activePlayer !== null
 56: 
 57:     // ── Prev button ───────────────────────────────────────────────────────────
 58:     PillBase {
 59:         hoverExpand:   true
 60:         implicitWidth: Theme.pillHeight
 61: 
 62:         Text {
 63:             text:             &quot;󰒮&quot;
 64:             color:            Colors.primary
 65:             font.pointSize:   12
 66:             font.family:      Fonts.font
 67:             Layout.alignment: Qt.AlignVCenter
 68:         }
 69: 
 70:         onClicked: if (root.activePlayer) root.activePlayer.previous()
 71:     }
 72: 
 73:     // ── Center pill — art + title ─────────────────────────────────────────────
 74:     PillBase {
 75:         hoverExpand: false
 76: 
 77:         onClicked:      Popups.mediaOpen = !Popups.mediaOpen
 78:         onRightClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
 79: 
 80:         Row {
 81:             spacing: 8
 82: 
 83:             // Rotating disc
 84:             Item {
 85:                 visible: root.hasArt
 86:                 width:   20
 87:                 height:  20
 88: 
 89:                 Rectangle {
 90:                     id:           artMask
 91:                     anchors.fill: parent
 92:                     radius:       width / 2
 93:                     visible:      false
 94:                 }
 95: 
 96:                 Image {
 97:                     anchors.fill: parent
 98:                     source:       root.activePlayer ? root.activePlayer.trackArtUrl : &quot;&quot;
 99:                     fillMode:     Image.PreserveAspectCrop
100:                     layer.enabled: true
101:                     layer.effect: OpacityMask { maskSource: artMask }
102: 
103:                     NumberAnimation on rotation {
104:                         from:     0
105:                         to:       360
106:                         duration: 5000
107:                         loops:    Animation.Infinite
108:                         running:  true
109:                         paused:   !root.isPlaying
110:                     }
111:                 }
112:             }
113: 
114:             Text {
115:                 text:          root.activePlayer
116:                                    ? (root.activePlayer.trackTitle || &quot;Unknown Track&quot;)
117:                                    : &quot;&quot;
118:                 color:         Colors.primary
119:                 font.pointSize: 11
120:                 font.bold:     true
121:                 font.italic:   root.isPlaying
122:                 font.family:   Fonts.font
123:                 elide:         Text.ElideRight
124:                 width:         Math.min(implicitWidth, 150)
125:             }
126:         }
127:     }
128: 
129:     // ── Next button ───────────────────────────────────────────────────────────
130:     PillBase {
131:         hoverExpand:   true
132:         implicitWidth: Theme.pillHeight
133: 
134:         Text {
135:             text:             &quot;󰒭&quot;
136:             color:            Colors.primary
137:             font.pointSize:   12
138:             font.family:      Fonts.font
139:             Layout.alignment: Qt.AlignVCenter
140:         }
141: 
142:         onClicked: if (root.activePlayer) root.activePlayer.next()
143:     }
144: }</file><file path="src/modules/Left/ArchLogo.qml"> 1: import QtQuick
 2: import Quickshell
 3: import qs.src.components
 4: import qs.src.theme
 5: import qs.src.state
 6: 
 7: PillBase {
 8:     id: root
 9: 
10:     hoverExpand: true
11: 
12:     Text {
13:         text: &quot;󰣇&quot;
14:         color: Colors.primary
15:         font.pointSize: 14
16:         font.family: &quot;JetBrains Mono&quot;
17:         verticalAlignment: Text.AlignVCenter
18:     }
19: 
20: // Temporarily hijack the Arch logo click
21: onClicked: Popups.clipboardOpen = !Popups.clipboardOpen
22: }</file><file path="src/modules/Right/Network.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.services
 4: import qs.src.services.system
 5: import qs.src.state
 6: import qs.src.theme
 7: import qs.src.components
 8: 
 9: PillBase {
10:     id: root
11: 
12:     readonly property bool hasWifi: NetworkService.wifiDevice !== null
13:     readonly property bool hasEthernet: SystemStats.activeInterface !== &quot;&quot;
14: 
15:     visible: hasWifi || NetworkService.btAdapter !== null || hasEthernet
16: 
17:     readonly property string _icon: {
18:         if (hasWifi) {
19:             if (!NetworkService.wifiEnabled || !NetworkService.wifiConnected)
20:                 return &quot;󰤭&quot;;
21:             const s = NetworkService.signalStrength;
22:             if (s &lt; 0.25) return &quot;󰤟&quot;;
23:             if (s &lt; 0.50) return &quot;󰤢&quot;;
24:             if (s &lt; 0.75) return &quot;󰤥&quot;;
25:             return &quot;󰤨&quot;;
26:         }
27:         return hasEthernet ? &quot;󰈀&quot; : &quot;󰈂&quot;;
28:     }
29: 
30:     readonly property bool _showLabel: (hasWifi &amp;&amp; NetworkService.wifiEnabled &amp;&amp; NetworkService.wifiConnected) || (!hasWifi &amp;&amp; hasEthernet)
31: 
32:     onClicked: {
33:         Popups.networkOpen = !Popups.networkOpen;
34:         if (Popups.networkOpen) {
35:             Popups.networkTab = hasWifi ? 0 : 1;
36:         }
37:     }
38: 
39:     onRightClicked: {
40:         Popups.networkOpen = true;
41:         Popups.networkTab  = 2;
42:     }
43: 
44:     Text {
45:         text: root._icon
46:         font.family: Fonts.fontM
47:         font.pixelSize: 14
48:         color: (hasWifi &amp;&amp; NetworkService.wifiConnected) || (!hasWifi &amp;&amp; hasEthernet) ? Colors.primary : Colors.outline
49:     }
50: 
51:     Text {
52:         text: hasWifi ? (NetworkService.ssid || &quot;Unknown&quot;) : SystemStats.activeInterface
53:         font.family: Fonts.font
54:         font.pixelSize: 13
55:         font.bold: true
56:         color: Colors.primary
57:         visible: root._showLabel
58:         elide: Text.ElideRight
59:         Layout.maximumWidth: 100
60:     }
61: }</file><file path="src/modules/Right/SystemMonitor.qml"> 1: import QtQuick
 2: import Quickshell
 3: import Quickshell.Io
 4: import qs.src.components
 5: import qs.src.theme
 6: import qs.src.state
 7: import qs.src.services
 8: import qs.src.services.system
 9: 
10: PillBase {
11:     id: root
12: 
13:     hoverExpand: true
14: 
15:     // SystemMonitor.qml — remove all polling, just bind:
16:     property real cpuUsage: SystemStats.cpuUsage * 100
17:     property real memUsed:  SystemStats.memUsedGb
18:     property real memTotal: SystemStats.memTotalGb
19: 
20:     // ── Display ───────────────────────────────────────────────────────────────
21:     Row {
22:         spacing: 8
23: 
24:         Text {
25:             text:           &quot;CPU &quot; + Math.round(root.cpuUsage) + &quot;%&quot;
26:             color:          Colors.primary
27:             font.pointSize: 11
28:             font.bold:      true
29:             font.family:    Fonts.font
30:             verticalAlignment: Text.AlignVCenter
31:         }
32: 
33:         Rectangle {
34:             width:  1
35:             height: 14
36:             color:  Colors.outline
37:             opacity: 0.5
38:             anchors.verticalCenter: parent.verticalCenter
39:         }
40: 
41:         Text {
42:             text:           &quot;MEM &quot; + root.memUsed.toFixed(1) + &quot;G&quot;
43:             color:          Colors.primary
44:             font.pointSize: 11
45:             font.bold:      true
46:             font.family:    Fonts.font
47:             verticalAlignment: Text.AlignVCenter
48:         }
49:     }
50: 
51:     onClicked:      Popups.systemOpen = !Popups.systemOpen
52:     onRightClicked: Popups.systemOpen = !Popups.systemOpen
53: }</file><file path="src/popups/NetworkRow.qml">  1: import QtQuick
  2: import QtQuick.Controls
  3: import QtQuick.Layouts
  4: import Quickshell.Networking
  5: import qs.src.theme
  6: import qs.src.components
  7: 
  8: Item {
  9:     id: root
 10:     required property var network
 11: 
 12:     implicitHeight: innerCol.implicitHeight + 24
 13:     property bool _showPsk: false
 14: 
 15:     Connections {
 16:         target: root.network
 17:         function onConnectionFailed(reason) {
 18:             if (reason === ConnectionFailReason.NoSecrets) {
 19:                 root._showPsk = true;
 20:             }
 21:         }
 22:     }
 23: 
 24:     // Background and full-row click handler (Normal 1-click connect)
 25:     Rectangle {
 26:         anchors.fill: parent
 27:         radius: 10
 28:         color: rowHover.containsMouse
 29:             ? Colors.surfaceContainerHighest
 30:             : (root.network.connected 
 31:                 ? Qt.rgba(Colors.primaryContainer.r, Colors.primaryContainer.g, Colors.primaryContainer.b, 0.3) 
 32:                 : &quot;transparent&quot;)
 33:         
 34:         Behavior on color { ColorAnimation { duration: 120 } }
 35: 
 36:         MouseArea {
 37:             id: rowHover
 38:             anchors.fill: parent
 39:             enabled: !root.network.stateChanging
 40:             hoverEnabled: true
 41:             cursorShape: Qt.PointingHandCursor
 42:             onClicked: {
 43:                 if (root.network.connected) {
 44:                     root.network.disconnect();
 45:                     root._showPsk = false;
 46:                 } else {
 47:                     root._showPsk = false;
 48:                     root.network.connect();
 49:                 }
 50:             }
 51:         }
 52:     }
 53: 
 54:     // Content sits on top so the TextField and Lock button consume clicks safely
 55:     ColumnLayout {
 56:         id: innerCol
 57:         anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
 58:         spacing: 10
 59: 
 60:         RowLayout {
 61:             Layout.fillWidth: true
 62:             spacing: 10
 63: 
 64:             // Signal strength icon
 65:             Text {
 66:                 text: {
 67:                     if (!root.network.connected &amp;&amp; root.network.state === ConnectionState.Connecting) return &quot;󱑤&quot;;
 68:                     const s = root.network.signalStrength ?? 0;
 69:                     if (s &lt; 0.25) return &quot;󰤟&quot;;
 70:                     if (s &lt; 0.50) return &quot;󰤢&quot;;
 71:                     if (s &lt; 0.75) return &quot;󰤥&quot;;
 72:                     return &quot;󰤨&quot;;
 73:                 }
 74:                 color: root.network.connected ? Colors.primary : Colors.on_SurfaceVariant
 75:                 font.pixelSize: 16
 76:                 font.family: Fonts.fontM
 77:                 Behavior on color { ColorAnimation { duration: 120 } }
 78:             }
 79: 
 80:             // SSID
 81:             Text {
 82:                 text: root.network.name
 83:                 color: root.network.connected ? Colors.on_Surface : Colors.on_SurfaceVariant
 84:                 font.pixelSize: 12
 85:                 font.bold: root.network.connected
 86:                 font.family: Fonts.font
 87:                 elide: Text.ElideRight
 88:                 Layout.fillWidth: true
 89:                 Behavior on color { ColorAnimation { duration: 120 } }
 90:             }
 91: 
 92:             // Interactive Lock icon / Manual Password Toggle
 93:             Rectangle {
 94:                 visible: root.network.security !== WifiSecurityType.Open &amp;&amp; !root.network.connected
 95:                 width: 24; height: 24; radius: 12
 96:                 color: lockHover.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1) : &quot;transparent&quot;
 97:                 Behavior on color { ColorAnimation { duration: 120 } }
 98: 
 99:                 Text {
100:                     anchors.centerIn: parent
101:                     text: root._showPsk ? &quot;󰌑&quot; : &quot;󰌾&quot; // Swaps from a lock to a key when open
102:                     font.family: Fonts.fontM
103:                     font.pixelSize: 14
104:                     color: lockHover.containsMouse || root._showPsk ? Colors.primary : Colors.outline
105:                     Behavior on color { ColorAnimation { duration: 120 } }
106:                 }
107: 
108:                 HoverHandler { id: lockHover }
109: 
110:                 MouseArea {
111:                     anchors.fill: parent
112:                     cursorShape: Qt.PointingHandCursor
113:                     onClicked: {
114:                         root._showPsk = !root._showPsk;
115:                         if (root._showPsk) pskField.forceActiveFocus();
116:                     }
117:                 }
118:             }
119: 
120:             // &quot;Connected&quot; chip
121:             Rectangle {
122:                 visible: root.network.connected || root.network.stateChanging
123:                 width: chipRow.implicitWidth + 16
124:                 height: 22
125:                 radius: 11
126:                 color: root.network.connected ? Colors.primary : Colors.surfaceContainerHighest
127: 
128:                 Row {
129:                     id: chipRow
130:                     anchors.centerIn: parent
131:                     spacing: 4
132:                     Text {
133:                         text: root.network.connected ? &quot;󰄵&quot; : &quot;󱑤&quot;
134:                         color: root.network.connected ? Colors.on_Primary : Colors.on_SurfaceVariant
135:                         font.pixelSize: 10
136:                         font.family: Fonts.font
137:                         anchors.verticalCenter: parent.verticalCenter
138:                     }
139:                     Text {
140:                         text: root.network.connected ? &quot;Connected&quot; : &quot;Connecting&quot;
141:                         color: root.network.connected ? Colors.on_Primary : Colors.on_SurfaceVariant
142:                         font.pixelSize: 10
143:                         font.bold: true
144:                         font.family: Fonts.font
145:                         anchors.verticalCenter: parent.verticalCenter
146:                     }
147:                 }
148:             }
149:         }
150: 
151:         // Password Row
152:         RowLayout {
153:             visible: root._showPsk
154:             Layout.fillWidth: true
155:             Layout.topMargin: 4
156:             spacing: 8
157: 
158:             TextField {
159:                 id: pskField
160:                 Layout.fillWidth: true
161:                 height: 32
162:                 placeholderText: &quot;Password&quot;
163:                 echoMode: TextInput.Password
164:                 font.family: Fonts.font
165:                 font.pixelSize: 12
166:                 color: Colors.on_Surface
167:                 placeholderTextColor: Colors.outline
168:                 
169:                 background: Rectangle {
170:                     radius: 8
171:                     color: Colors.surfaceContainerHigh
172:                     border.width: 1
173:                     border.color: pskField.activeFocus ? Colors.primary : Colors.outline
174:                     Behavior on border.color { ColorAnimation { duration: Theme.hoverFadeDuration } }
175:                 }
176:                 Keys.onReturnPressed: {
177:                     if (text.length &gt; 0) {
178:                         root.network.connectWithPsk(text);
179:                         text = &quot;&quot;;
180:                     }
181:                 }
182:             }
183: 
184:             Rectangle {
185:                 width: 32; height: 32; radius: 8
186:                 color: confirmHover.containsMouse 
187:                     ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) 
188:                     : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
189:                 Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
190:                 HoverHandler { id: confirmHover }
191:                 
192:                 Text { anchors.centerIn: parent; text: &quot;󰌑&quot;; font.family: Fonts.fontM; font.pixelSize: 14; color: Colors.primary }
193:                 
194:                 MouseArea {
195:                     anchors.fill: parent
196:                     cursorShape: Qt.PointingHandCursor
197:                     onClicked: {
198:                         if (pskField.text.length &gt; 0) {
199:                             root.network.connectWithPsk(pskField.text);
200:                             pskField.text = &quot;&quot;;
201:                         }
202:                     }
203:                 }
204:             }
205:         }
206:     }
207: }</file><file path="src/popups/VolumePopup.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Wayland
  5: import Quickshell.Services.Pipewire
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.services
 10: 
 11: PanelWindow {
 12:     id: root
 13:     property var screen
 14: 
 15:     PwObjectTracker {
 16:         objects: Pipewire.nodes.values.filter(n =&gt; n.audio !== null &amp;&amp; !n.isStream &amp;&amp; n.isSink)
 17:     }
 18:     PwObjectTracker {
 19:         objects: Pipewire.nodes.values.filter(n =&gt; n.audio !== null &amp;&amp; !n.isStream &amp;&amp; !n.isSink)
 20:     }
 21: 
 22:     color:         &quot;transparent&quot;
 23:     exclusionMode: ExclusionMode.Ignore
 24: 
 25:     anchors {
 26:         top:   true
 27:         right: true
 28:     }
 29: 
 30:     implicitWidth:  380
 31:     implicitHeight: root.screen ? root.screen.height : 800
 32: 
 33:     WlrLayershell.layer: WlrLayer.Overlay
 34:     visible: slidePanel.windowVisible
 35: 
 36:     PopupSlide {
 37:         id: slidePanel
 38:         anchors.fill: parent
 39:         edge: &quot;top&quot;
 40:         open: Popups.volumeOpen
 41:         onCloseRequested: Popups.volumeOpen = false
 42: 
 43:         // ── Popup card ────────────────────────────────────────────────────────────
 44:         Rectangle {
 45:             id: card
 46:             anchors {
 47:                 top:         parent.top
 48:                 right:       parent.right
 49:                 topMargin:   Theme.barHeight + 8
 50:                 rightMargin: Theme.barMargin
 51:             }
 52:             width:        360
 53:             height:       cardCol.implicitHeight + 18
 54:             radius:       Theme.popupRadius
 55:             color:        Colors.surfaceContainer
 56:             border.color: Colors.outlineVariant
 57:             border.width: Theme.popupBorder
 58:             clip:         true
 59: 
 60:             ColumnLayout {
 61:                 id: cardCol
 62:                 anchors {
 63:                     top:     parent.top
 64:                     left:    parent.left
 65:                     right:   parent.right
 66:                     topMargin: 10
 67:                     rightMargin: 16
 68:                     leftMargin: 16
 69:                     bottomMargin: 16
 70:                 }
 71:                 spacing: 12
 72: 
 73:                 // ── Tab bar ───────────────────────────────────────────────────────
 74:                 TabBar {
 75:                     id: tabs
 76:                     Layout.fillWidth: true
 77:                     orientation: &quot;horizontal&quot;
 78: 
 79:                     model: [
 80:                         { key: &quot;output&quot;,  icon: &quot;󰕾&quot;, label: &quot;Output&quot;  },
 81:                         { key: &quot;input&quot;,   icon: &quot;󰍬&quot;, label: &quot;Input&quot;   },
 82:                         { key: &quot;devices&quot;, icon: &quot;󰓃&quot;, label: &quot;Devices&quot; }
 83:                     ]
 84: 
 85:                     currentPage: &quot;output&quot;
 86:                     onPageChanged: (key) =&gt; currentPage = key
 87:                 }
 88: 
 89:                 // ── Output tab ────────────────────────────────────────────────────
 90:                 ColumnLayout {
 91:                     visible:          tabs.currentPage === &quot;output&quot;
 92:                     Layout.fillWidth: true
 93:                     spacing:          12
 94: 
 95:                     // Volume row
 96:                     RowLayout {
 97:                         Layout.fillWidth: true
 98:                         spacing: 10
 99: 
100:                         // Mute button
101:                         Rectangle {
102:                             width:  36
103:                             height: 36
104:                             radius: 18
105:                             color:  VolumeService.muted
106:                                         ? Colors.errorContainer
107:                                         : (muteOutHov.containsMouse
108:                                             ? Qt.rgba(1,1,1,0.08)
109:                                             : Colors.surfaceContainerHighest)
110:                             Behavior on color { ColorAnimation { duration: 120 } }
111: 
112:                             Text {
113:                                 anchors.centerIn: parent
114:                                 text: VolumeService.muted ? &quot;󰝟&quot; : &quot;󰕾&quot;
115:                                 color: VolumeService.muted
116:                                            ? Colors.on_ErrorContainer
117:                                            : Colors.primary
118:                                 font.pixelSize: 16
119:                                 font.family:    Fonts.font
120:                             }
121: 
122:                             MouseArea {
123:                                 id:           muteOutHov
124:                                 anchors.fill: parent
125:                                 hoverEnabled: true
126:                                 cursorShape:  Qt.PointingHandCursor
127:                                 onClicked:    VolumeService.toggleMute()
128:                             }
129:                         }
130: 
131:                         // Slider
132:                         VolumeSlider {
133:                             Layout.fillWidth: true
134:                             value:    VolumeService.volume
135:                             muted:    VolumeService.muted
136:                             onMoved:  (v) =&gt; {
137:                                 if (VolumeService.audio)
138:                                     VolumeService.audio.volume = v
139:                             }
140:                         }
141: 
142:                         // Percentage label
143:                         Text {
144:                             text:           Math.round(VolumeService.volume * 100) + &quot;%&quot;
145:                             color:          Colors.on_Surface
146:                             font.pixelSize: 12
147:                             font.bold:      true
148:                             font.family:    Fonts.font
149:                             horizontalAlignment: Text.AlignRight
150:                             width: 36
151:                         }
152:                     }
153: 
154:                     // Current output device — click to go to devices tab
155:                     Rectangle {
156:                         Layout.fillWidth: true
157:                         Layout.bottomMargin: 8
158:                         height:  44
159:                         radius:  10
160:                         color:   outDevHov.containsMouse
161:                                      ? Colors.surfaceContainerHighest
162:                                      : Colors.surfaceContainerHigh
163:                         Behavior on color { ColorAnimation { duration: 120 } }
164: 
165:                         RowLayout {
166:                             anchors { fill: parent; rightMargin: 12; leftMargin: 12 }
167:                             spacing: 8
168: 
169:                             Text {
170:                                 text:           &quot;󰓃&quot;
171:                                 color:          Colors.primary
172:                                 font.pixelSize: 16
173:                                 font.family:    Fonts.font
174:                             }
175: 
176:                             ColumnLayout {
177:                                 Layout.fillWidth: true
178:                                 spacing:          0
179: 
180:                                 Text {
181:                                     text:              &quot;Output device&quot;
182:                                     color:             Colors.on_SurfaceVariant
183:                                     font.pixelSize:    10
184:                                     font.family:       Fonts.font
185:                                     Layout.fillWidth:  true
186:                                 }
187: 
188:                                 Text {
189:                                     text:             VolumeService.sink
190:                                                           ? (VolumeService.sink.description || &quot;Unknown&quot;)
191:                                                           : &quot;None&quot;
192:                                     color:            Colors.on_Surface
193:                                     font.pixelSize:   12
194:                                     font.bold:        true
195:                                     font.family:      Fonts.font
196:                                     elide:            Text.ElideRight
197:                                     Layout.fillWidth: true
198:                                 }
199:                             }
200: 
201:                             Text {
202:                                 text:           &quot;󰄾&quot;
203:                                 color:          Colors.on_SurfaceVariant
204:                                 font.pixelSize: 14
205:                                 font.family:    Fonts.font
206:                             }
207:                         }
208: 
209:                         MouseArea {
210:                             id:           outDevHov
211:                             anchors.fill: parent
212:                             hoverEnabled: true
213:                             cursorShape:  Qt.PointingHandCursor
214:                             onClicked:    tabs.currentPage = &quot;devices&quot;
215:                         }
216:                     }
217:                 }
218: 
219:                 // ── Input tab ─────────────────────────────────────────────────────
220:                 ColumnLayout {
221:                     visible:          tabs.currentPage === &quot;input&quot;
222:                     Layout.fillWidth: true
223:                     spacing:          12
224: 
225:                     RowLayout {
226:                         Layout.fillWidth: true
227:                         spacing: 10
228: 
229:                         // Mute button
230:                         Rectangle {
231:                             width:  36
232:                             height: 36
233:                             radius: 18
234:                             color:  VolumeService.inputMuted
235:                                         ? Colors.errorContainer
236:                                         : (muteInHov.containsMouse
237:                                             ? Qt.rgba(1,1,1,0.08)
238:                                             : Colors.surfaceContainerHighest)
239:                             Behavior on color { ColorAnimation { duration: 120 } }
240: 
241:                             Text {
242:                                 anchors.centerIn: parent
243:                                 text:  VolumeService.inputMuted ? &quot;󰍭&quot; : &quot;󰍬&quot;
244:                                 color: VolumeService.inputMuted
245:                                            ? Colors.on_ErrorContainer
246:                                            : Colors.primary
247:                                 font.pixelSize: 16
248:                                 font.family:    Fonts.font
249:                             }
250: 
251:                             MouseArea {
252:                                 id:           muteInHov
253:                                 anchors.fill: parent
254:                                 hoverEnabled: true
255:                                 cursorShape:  Qt.PointingHandCursor
256:                                 onClicked:    VolumeService.toggleInputMute()
257:                             }
258:                         }
259: 
260:                         VolumeSlider {
261:                             Layout.fillWidth: true
262:                             value:   VolumeService.inputVolume
263:                             muted:   VolumeService.inputMuted
264:                             onMoved: (v) =&gt; {
265:                                 if (VolumeService.inputAudio)
266:                                     VolumeService.inputAudio.volume = v
267:                             }
268:                         }
269: 
270:                         Text {
271:                             text:           Math.round(VolumeService.inputVolume * 100) + &quot;%&quot;
272:                             color:          Colors.on_Surface
273:                             font.pixelSize: 12
274:                             font.bold:      true
275:                             font.family:    Fonts.font
276:                             horizontalAlignment: Text.AlignRight
277:                             width: 36
278:                         }
279:                     }
280: 
281:                     // Current input device
282:                     Rectangle {
283:                         Layout.fillWidth: true
284:                         Layout.bottomMargin: 8
285:                         height:  44
286:                         radius:  10
287:                         color:   inDevHov.containsMouse
288:                                      ? Colors.surfaceContainerHighest
289:                                      : Colors.surfaceContainerHigh
290:                         Behavior on color { ColorAnimation { duration: 120 } }
291: 
292:                         RowLayout {
293:                             anchors { fill: parent; rightMargin: 12; leftMargin: 12 }
294:                             spacing: 8
295: 
296:                             Text {
297:                                 text:           &quot;󰍬&quot;
298:                                 color:          Colors.primary
299:                                 font.pixelSize: 16
300:                                 font.family:    Fonts.font
301:                             }
302: 
303:                             ColumnLayout {
304:                                 Layout.fillWidth: true
305:                                 spacing: 0
306: 
307:                                 Text {
308:                                     text:           &quot;Input device&quot;
309:                                     color:          Colors.on_SurfaceVariant
310:                                     font.pixelSize: 10
311:                                     font.family:    Fonts.font
312:                                 }
313: 
314:                                 Text {
315:                                     text: VolumeService.source
316:                                               ? (VolumeService.source.description || &quot;Unknown&quot;)
317:                                               : &quot;None&quot;
318:                                     color:          Colors.on_Surface
319:                                     font.pixelSize: 12
320:                                     font.bold:      true
321:                                     font.family:    Fonts.font
322:                                     elide:          Text.ElideRight
323:                                     Layout.fillWidth: true
324:                                 }
325:                             }
326: 
327:                             Text {
328:                                 text:           &quot;󰄾&quot;
329:                                 color:          Colors.on_SurfaceVariant
330:                                 font.pixelSize: 14
331:                                 font.family:    Fonts.font
332:                             }
333:                         }
334: 
335:                         MouseArea {
336:                             id:           inDevHov
337:                             anchors.fill: parent
338:                             hoverEnabled: true
339:                             cursorShape:  Qt.PointingHandCursor
340:                             onClicked:    tabs.currentPage = &quot;devices&quot;
341:                         }
342:                     }
343:                 }
344: 
345:                 // ── Devices tab ───────────────────────────────────────────────────
346:                 ColumnLayout {
347:                     visible:          tabs.currentPage === &quot;devices&quot;
348:                     Layout.fillWidth: true
349:                     spacing:          8
350: 
351:                     // Output devices section
352:                     Text {
353:                         text:           &quot;Output&quot;
354:                         color:          Colors.on_SurfaceVariant
355:                         font.pixelSize: 11
356:                         font.bold:      true
357:                         font.family:    Fonts.font
358:                         leftPadding:    4
359:                     }
360: 
361:                     Repeater {
362:                         model: Pipewire.nodes.values.filter(n =&gt;
363:                             n.audio !== null &amp;&amp;
364:                             !n.isStream &amp;&amp;
365:                             n.isSink
366:                         )
367:                         delegate: DeviceRow {
368:                             required property var modelData
369:                             Layout.fillWidth: true
370:                             deviceName:  modelData.description || modelData.name || &quot;Unknown&quot;
371:                             isDefault:   VolumeService.sink &amp;&amp; VolumeService.sink.id === modelData.id
372:                             icon:        &quot;󰓃&quot;
373:                             onActivated: Pipewire.preferredDefaultAudioSink = modelData
374:                         }
375:                     }
376: 
377:                     // Divider between output and input
378:                     Rectangle {
379:                         Layout.fillWidth: true
380:                         height:  1
381:                         color:   Colors.outlineVariant
382:                         opacity: 0.5
383:                     }
384: 
385:                     // Input devices section
386:                     Text {
387:                         text:           &quot;Input&quot;
388:                         color:          Colors.on_SurfaceVariant
389:                         font.pixelSize: 11
390:                         font.bold:      true
391:                         font.family:    Fonts.font
392:                         leftPadding:    4
393:                     }
394: 
395:                     Repeater {
396:                         model: Pipewire.nodes.values.filter(n =&gt;
397:                             n.audio !== null &amp;&amp;
398:                             !n.isStream &amp;&amp;
399:                             !n.isSink
400:                         )
401:                         delegate: DeviceRow {
402:                             required property var modelData
403:                             Layout.fillWidth: true
404:                             deviceName: modelData.description || modelData.name || &quot;Unknown&quot;
405:                             isDefault:  VolumeService.source &amp;&amp; VolumeService.source.id === modelData.id
406:                             icon:       &quot;󰍬&quot;
407:                             onActivated: Pipewire.preferredDefaultAudioSource = modelData
408:                         }
409:                     }
410: 
411:                     Layout.bottomMargin: 4
412:                 }
413:             }
414:         }
415:     }
416: }</file><file path="src/services/NetworkService.qml"> 1: pragma Singleton
 2: 
 3: import QtQuick
 4: import Quickshell
 5: import Quickshell.Networking
 6: import Quickshell.Bluetooth
 7: 
 8: Singleton {
 9:     id: root
10: 
11:     // ── WiFi ─────────────────────────────────────────────────────────────────
12:     readonly property var wifiHardwareEnabled: Networking.wifiHardwareEnabled
13: 
14:     /// The first WiFi device found, or null
15:     readonly property var wifiDevice: {
16:         const devs = Networking.devices.values;
17:         for (let i = 0; i &lt; devs.length; i++) {
18:             if (devs[i].type === DeviceType.Wifi) return devs[i];
19:         }
20:         return null;
21:     }
22: 
23:     /// The currently connected WifiNetwork, or null
24:     readonly property var activeNetwork: {
25:         if (!root.wifiDevice) return null;
26:         const nets = root.wifiDevice.networks.values;
27:         for (let i = 0; i &lt; nets.length; i++) {
28:             if (nets[i].connected) return nets[i];
29:         }
30:         return null;
31:     }
32: 
33:     readonly property string ssid:          root.activeNetwork?.name         ?? &quot;&quot;
34:     readonly property real   signalStrength: root.activeNetwork?.signalStrength ?? 0.0
35:     readonly property bool   wifiConnected:  root.wifiDevice?.connected       ?? false
36:     readonly property bool   wifiEnabled:    Networking.wifiEnabled
37: 
38:     function setWifiEnabled(val) {
39:         Networking.wifiEnabled = val;
40:     }
41: 
42:     /// Sorted list of all visible networks (connected first, then by signal strength)
43:     readonly property var networks: {
44:         if (!root.wifiDevice) return [];
45:         const nets = root.wifiDevice.networks.values.slice();
46:         nets.sort((a, b) =&gt; {
47:             if (a.connected !== b.connected) return a.connected ? -1 : 1;
48:             return b.signalStrength - a.signalStrength;
49:         });
50:         return nets;
51:     }
52: 
53:     // Enable scanner whenever the popup is open — caller sets this
54:     property bool scannerActive: false
55:     onScannerActiveChanged: {
56:         if (root.wifiDevice) root.wifiDevice.scannerEnabled = root.scannerActive;
57:     }
58:     onWifiDeviceChanged: {
59:         if (root.wifiDevice) root.wifiDevice.scannerEnabled = root.scannerActive;
60:     }
61: 
62:     // ── Bluetooth ─────────────────────────────────────────────────────────────
63: 
64:     readonly property var btAdapter:       Bluetooth.defaultAdapter
65:     readonly property bool btEnabled:      root.btAdapter?.enabled      ?? false
66:     readonly property var btDevices:       root.btAdapter?.devices?.values ?? []
67: 
68:     function setBtEnabled(val) {
69:         if (root.btAdapter) root.btAdapter.enabled = val;
70:     }
71: }</file><file path="src/services/qmldir">1: singleton BatteryService      1.0 BatteryService.qml
2: singleton NotificationService 1.0 NotificationService.qml
3: singleton VolumeService       1.0 VolumeService.qml
4: singleton NetworkService      1.0 NetworkService.qml
5: singleton ClipboardService    1.0 ClipboardService.qml</file><file path="src/theme/Fonts.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: 
 5: QtObject {
 6:     id: root
 7: 
 8:     readonly property string font: &quot;SpaceMono Nerd Font&quot;
 9:     readonly property string fontM: &quot;JetBrains Mono&quot;
10: }</file><file path="src/windows/TopBar.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import Quickshell.Wayland
 5: import Quickshell.Hyprland
 6: import qs.src.components
 7: import qs.src.modules.Left
 8: import qs.src.modules.Center
 9: import qs.src.modules.Right
10: import qs.src.theme
11: import qs.src.state
12: 
13: PanelWindow {
14:     id: root
15: 
16:     property var screen
17: 
18:     color:         &quot;transparent&quot;
19:     exclusionMode: ExclusionMode.Auto
20: 
21:     anchors {
22:         top:   true
23:         left:  true
24:         right: true
25:     }
26: 
27:     // ── Height animates between full bar and thin strip ───────────────────────
28:     implicitHeight: ShellState.focusMode ? Theme.borderWidth : Theme.barHeight
29:     Behavior on implicitHeight {
30:         NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
31:     }
32: 
33:     // ── Write notch widths to ShellState for PopupDismiss ────────────────────
34:     Binding { target: ShellState; property: &quot;topBarLWidth&quot;; value: leftRow.implicitWidth  + Theme.barMargin }
35:     Binding { target: ShellState; property: &quot;topBarCWidth&quot;; value: centerRow.implicitWidth }
36:     Binding { target: ShellState; property: &quot;topBarRWidth&quot;; value: rightRow.implicitWidth + Theme.barMargin }
37: 
38:     // ── Thin strip background — visible only in focus mode ────────────────────
39:     Rectangle {
40:         anchors.fill: parent
41:         color:        Colors.background
42:         opacity:      ShellState.focusMode ? 1 : 0
43:         Behavior on opacity {
44:             NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
45:         }
46:     }
47: 
48:     // ── Full bar content — fades out in focus mode ────────────────────────────
49:     Item {
50:         anchors.fill: parent
51:         opacity: ShellState.focusMode ? 0 : 1
52:         Behavior on opacity {
53:             NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
54:         }
55: 
56:         // Left modules
57:         RowLayout {
58:             id: leftRow
59:             anchors.left:           parent.left
60:             anchors.leftMargin:     Theme.barMargin
61:             anchors.verticalCenter: parent.verticalCenter
62:             spacing: Theme.barSpacing
63: 
64:             ArchLogo    {}
65:             Workspaces  {}
66:             WindowName  {}
67:         }
68: 
69:         // Center modules
70:         RowLayout {
71:             id: centerRow
72:             anchors.centerIn:       parent
73:             anchors.verticalCenter: parent.verticalCenter
74:             spacing: Theme.barSpacing
75: 
76:             ClockDate       {}
77:             Media           {}
78:             IdleInhibitor   {}
79:         }
80: 
81:         // Right modules
82:         RowLayout {
83:             id: rightRow
84:             anchors.right:          parent.right
85:             anchors.rightMargin:    Theme.barMargin
86:             anchors.verticalCenter: parent.verticalCenter
87:             spacing: Theme.barSpacing
88: 
89:             SystemMonitor       {}
90:             Network             {}
91:             Volume              {}
92:             Battery             {}
93:             Tray                { window: root }
94:             NotificationButton  {}
95:         }
96:     }
97: }</file><file path="src/components/TabBar.qml">  1: import QtQuick
  2: import qs.src.theme
  3: 
  4: // Reusable tab switcher — horizontal or vertical.
  5: // Horizontal: icon + label pill row with bottom divider. Used by multi-tab popups.
  6: // Vertical:   icon-only solid pill column. Reserved for future use.
  7: 
  8: Item {
  9:     id: root
 10: 
 11:     property var    model:       []
 12:     property string currentPage: &quot;&quot;
 13:     property string orientation: &quot;horizontal&quot;
 14: 
 15:     signal pageChanged(string key)
 16: 
 17:     property string defaultPage: model.length &gt; 0 ? model[0].key : &quot;&quot;
 18:     function reset() { pageChanged(defaultPage) }
 19: 
 20:     implicitWidth:  orientation === &quot;vertical&quot;   ? 40 : 0
 21:     implicitHeight: orientation === &quot;horizontal&quot; ? 40 : 0
 22: 
 23:     // ── Scroll to Cycle Tabs ──────────────────────────────────────────────────
 24:     property bool _scrollBusy: false
 25: 
 26:     Timer {
 27:         id:          scrollCooldown
 28:         interval:    300
 29:         onTriggered: root._scrollBusy = false
 30:     }
 31: 
 32:     WheelHandler {
 33:         acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
 34:         onWheel: (event) =&gt; {
 35:             if (root._scrollBusy) return
 36:             root._scrollBusy = true; scrollCooldown.restart()
 37:             const keys = root.model.map(m =&gt; m.key)
 38:             const dir  = event.angleDelta.y &lt; 0 ? 1 : -1
 39:             const idx  = (keys.indexOf(root.currentPage) + dir + keys.length) % keys.length
 40:             root.pageChanged(keys[idx])
 41:         }
 42:     }
 43: 
 44:     // ── Horizontal ────────────────────────────────────────────────────────────
 45:     Row {
 46:         id:           hRow
 47:         anchors.fill: parent
 48:         visible:      root.orientation === &quot;horizontal&quot;
 49: 
 50:         Repeater {
 51:             model: root.orientation === &quot;horizontal&quot; ? root.model : []
 52: 
 53:             delegate: Item {
 54:                 id: hTab
 55:                 readonly property bool isActive: root.currentPage === modelData.key
 56: 
 57:                 width:  hRow.width / root.model.length
 58:                 height: hRow.height
 59: 
 60:                 Rectangle {
 61:                     anchors.centerIn: parent
 62:                     width:            Math.min(parent.width - 4, hIcon.implicitWidth + (hLabel.visible ? hLabel.implicitWidth + 8 : 0) + 24)
 63:                     height:           parent.height - 8
 64:                     radius:           height / 2
 65:                     color:            hTab.isActive ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18) 
 66:                                                     : (hHov.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : &quot;transparent&quot;)
 67:                     
 68:                     Behavior on color { ColorAnimation { duration: 120 } }
 69:                 }
 70: 
 71:                 Row {
 72:                     anchors.centerIn: parent
 73:                     spacing:          6
 74: 
 75:                     Text {
 76:                         id:                     hIcon
 77:                         text:                   modelData.icon
 78:                         font.pixelSize:         14
 79:                         font.family:            Fonts.font
 80:                         anchors.verticalCenter: parent.verticalCenter
 81:                         color:                  hTab.isActive ? Colors.primary : (hHov.containsMouse ? Qt.rgba(1,1,1,0.75) : Qt.rgba(1,1,1,0.4))
 82:                         
 83:                         Behavior on color { ColorAnimation { duration: 120 } }
 84:                     }
 85: 
 86:                     Text {
 87:                         id:                     hLabel
 88:                         visible:                modelData.label !== undefined
 89:                         text:                   modelData.label ?? &quot;&quot;
 90:                         font.pixelSize:         12
 91:                         font.bold:              hTab.isActive
 92:                         font.family:            Fonts.font
 93:                         anchors.verticalCenter: parent.verticalCenter
 94:                         color:                  hTab.isActive ? Colors.primary : (hHov.containsMouse ? Qt.rgba(1,1,1,0.75) : Qt.rgba(1,1,1,0.4))
 95:                         
 96:                         Behavior on color { ColorAnimation { duration: 120 } }
 97:                     }
 98:                 }
 99: 
100:                 MouseArea {
101:                     id:           hHov
102:                     anchors.fill: parent
103:                     hoverEnabled: true
104:                     cursorShape:  Qt.PointingHandCursor
105:                     onClicked:    root.pageChanged(modelData.key)
106:                 }
107:             }
108:         }
109:     }
110: 
111:     // Bottom divider — horizontal only
112:     Rectangle {
113:         visible:        root.orientation === &quot;horizontal&quot;
114:         anchors.bottom: parent.bottom
115:         anchors.left:   parent.left
116:         anchors.right:  parent.right
117:         height:         1
118:         color:          Colors.outlineVariant
119:         opacity:        0.5
120:     }
121: 
122:     // ── Vertical ──────────────────────────────────────────────────────────────
123:     Column {
124:         id:               vCol
125:         anchors.centerIn: parent
126:         visible:          root.orientation === &quot;vertical&quot;
127: 
128:         readonly property int tabH: 60
129:         spacing: root.model.length &gt; 1 ? (root.height - root.model.length * tabH) / (root.model.length - 1) : 0
130: 
131:         Repeater {
132:             model: root.orientation === &quot;vertical&quot; ? root.model : []
133: 
134:             delegate: Rectangle {
135:                 id: vTab
136:                 readonly property bool isActive: root.currentPage === modelData.key
137: 
138:                 width:  40
139:                 height: vCol.tabH
140:                 radius: Theme.pillRadius
141:                 color:  vTab.isActive ? Colors.primary : (vHov.containsMouse ? Qt.rgba(1,1,1,0.08) : &quot;transparent&quot;)
142:                 
143:                 Behavior on color { ColorAnimation { duration: 120 } }
144: 
145:                 Text {
146:                     anchors.centerIn: parent
147:                     text:             modelData.icon
148:                     font.pixelSize:   16
149:                     font.family:      Fonts.font
150:                     color:            vTab.isActive ? Colors.on_Primary : Colors.primary
151:                     
152:                     Behavior on color { ColorAnimation { duration: 120 } }
153:                 }
154: 
155:                 MouseArea {
156:                     id:           vHov
157:                     anchors.fill: parent
158:                     hoverEnabled: true
159:                     cursorShape:  Qt.PointingHandCursor
160:                     onClicked:    root.pageChanged(modelData.key)
161:                 }
162:             }
163:         }
164:     }
165: }</file><file path="src/modules/Left/Workspaces.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import Quickshell
 4: import Quickshell.Hyprland
 5: import qs.src.components
 6: import qs.src.theme
 7: 
 8: PillBase {
 9:     id: root
10: 
11:     hoverExpand: false  // fixed width, dots handle their own sizing
12:     hoverEnabled: false
13: 
14:     onClicked: (mouse) =&gt; {
15:         // find which dot was clicked by x position
16:         const dotWidth   = 12
17:         const activeDotW = 30
18:         let x = mouse.x - Theme.pillPadding / 2
19:         for (let i = 0; i &lt; root.dotCount; i++) {
20:             const w = (dotsRow.itemAt(i)?.isActive ? activeDotW : dotWidth)
21:             if (x &lt;= w + 4 || i == root.dotCount - 1) {
22:                 Hyprland.dispatch(&quot;hl.dsp.focus({ workspace = &quot; + (i + 1) + &quot; })&quot;)
23:                 return
24:             }
25:             x -= w + Theme.barSpacing  // 8 = spacing
26:         }
27:     }
28: 
29:     property int dotCount: {
30:         let highest = 3
31:         let wss = Hyprland.workspaces.values
32:         for (let i = 0; i &lt; wss.length; i++) {
33:             if (wss[i].id &gt; highest) highest = wss[i].id
34:         }
35:         return highest
36:     }
37: 
38:     Row {
39:         id: dotsRow
40:         spacing: Theme.barSpacing
41: 
42:         Repeater {
43:             model: root.dotCount
44: 
45:             delegate: Rectangle {
46:                 readonly property int wsId: index + 1
47: 
48:                 property var hyprWs: {
49:                     let wss = Hyprland.workspaces.values
50:                     for (let i = 0; i &lt; wss.length; i++) {
51:                         if (wss[i].id === wsId) return wss[i]
52:                     }
53:                     return null
54:                 }
55: 
56:                 readonly property bool isActive:   hyprWs ? hyprWs.active : false
57:                 readonly property bool isOccupied: hyprWs !== null
58: 
59:                 width:   isActive ? 30 : 12
60:                 height:  12
61:                 radius:  6
62:                 color:   isActive ? Colors.primary : Colors.outline
63:                 opacity: (isActive || isOccupied) ? 1.0 : 0.3
64: 
65:                 Behavior on width  { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
66:                 Behavior on color  { ColorAnimation  { duration: 200 } }
67:                 Behavior on opacity { NumberAnimation { duration: 200 } }
68:             }
69:         }
70:     }
71: }</file><file path="src/popups/Launcher.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Wayland
  5: import Quickshell.Io
  6: import Qt5Compat.GraphicalEffects
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.popups.launcher
 10: 
 11: PanelWindow {
 12:     id: root
 13:     property var screen
 14: 
 15:     color:         &quot;transparent&quot;
 16:     exclusionMode: ExclusionMode.Ignore
 17: 
 18:     anchors { top: true; left: true; right: true; bottom: true }
 19: 
 20:     WlrLayershell.layer:         WlrLayer.Overlay
 21:     WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
 22: 
 23:     // ── Delayed visibility (lets close animation finish) ──────────────────
 24:     property bool _shouldShow: false
 25:     visible: _shouldShow
 26: 
 27:     Connections {
 28:         target: Popups
 29:         function onLauncherOpenChanged() {
 30:             if (Popups.launcherOpen) {
 31:                 root._shouldShow = true
 32:             } else {
 33:                 closeDelay.start()
 34:             }
 35:         }
 36:     }
 37:     Timer {
 38:         id:          closeDelay
 39:         interval:    Theme.animDuration + 30
 40:         onTriggered: root._shouldShow = false
 41:     }
 42: 
 43:     onVisibleChanged: {
 44:         if (visible) {
 45:             searchBar.clear()
 46:             root.selectedIndex = 0
 47:             if (!appLoader.loading) appLoader.reload()
 48:             searchBar.forceActiveFocus()
 49:         }
 50:     }
 51: 
 52:     // ── State ─────────────────────────────────────────────────────────────
 53:     property int selectedIndex: 0
 54:     property var allApps:       []
 55:     property var filteredApps:  []
 56: 
 57:     function filterApps() {
 58:         const q = searchBar.text.toLowerCase().trim()
 59:         if (q === &quot;&quot;) {
 60:             root.filteredApps = root.allApps.slice(0, 48)
 61:         } else {
 62:             root.filteredApps = root.allApps.filter(a =&gt; {
 63:                 const name    = (a.name    || &quot;&quot;).toLowerCase()
 64:                 const comment = (a.comment || &quot;&quot;).toLowerCase()
 65:                 return name.startsWith(q) || name.includes(q) || comment.includes(q)
 66:             }).sort((a, b) =&gt; {
 67:                 const an = (a.name || &quot;&quot;).toLowerCase()
 68:                 const bn = (b.name || &quot;&quot;).toLowerCase()
 69:                 return (an.startsWith(q) ? 0 : 1) - (bn.startsWith(q) ? 0 : 1)
 70:                     || an.localeCompare(bn)
 71:             }).slice(0, 48)
 72:         }
 73:         root.selectedIndex = 0
 74:     }
 75: 
 76:     function launch(idx) {
 77:         const app = root.filteredApps[idx]
 78:         if (!app || !app.exec) return
 79:         launchProc.command = [&quot;sh&quot;, &quot;-c&quot;, app.exec.replace(/%[uUfFdDnNickvm]/g, &quot;&quot;).trim()]
 80:         launchProc.running = true
 81:         Popups.launcherOpen = false
 82:     }
 83: 
 84:     // ── App loader ────────────────────────────────────────────────────────
 85:     LauncherAppLoader {
 86:         id: appLoader
 87:         onLoaded: (apps) =&gt; {
 88:             root.allApps = apps
 89:             root.filterApps()
 90:         }
 91:     }
 92: 
 93:     // ── Launch process (fire-and-forget) ──────────────────────────────────
 94:     Process {
 95:         id:      launchProc
 96:         command: []
 97:         running: false
 98:     }
 99: 
100:     // ── Dim overlay ───────────────────────────────────────────────────────
101:     Rectangle {
102:         anchors.fill: parent
103:         color:        Qt.rgba(0, 0, 0, 0.55)
104:         opacity:      Popups.launcherOpen ? 1 : 0
105:         Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }
106: 
107:         MouseArea {
108:             anchors.fill: parent
109:             onClicked:    Popups.launcherOpen = false
110:         }
111:     }
112: 
113:     // ── Center card ───────────────────────────────────────────────────────
114:     Rectangle {
115:         id: card
116: 
117:         anchors.horizontalCenter: parent.horizontalCenter
118:         anchors.top:              parent.top
119:         anchors.topMargin:        Math.max(72, (parent.height - height) * 0.28)
120: 
121:         width:  620
122:         height: searchBar.height + 1 + resultsList.height
123:         radius: Theme.popupRadius + 6
124:         color:  Colors.surfaceContainer
125:         border.color: Colors.outlineVariant
126:         border.width: Theme.popupBorder
127:         clip:         true
128: 
129:         property real yOffset: Popups.launcherOpen ? 0 : -18
130:         Behavior on yOffset { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
131:         transform: Translate { y: card.yOffset }
132: 
133:         opacity: Popups.launcherOpen ? 1 : 0
134:         Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
135: 
136:         // ── Search bar ────────────────────────────────────────────────────
137:         LauncherSearchBar {
138:             id:          searchBar
139:             anchors { top: parent.top; left: parent.left; right: parent.right }
140:             resultCount: root.filteredApps.length
141:             showCount:   text !== &quot;&quot;
142: 
143:             onTextChanged:  root.filterApps()
144:             onEscapePressed: Popups.launcherOpen = false
145:             onReturnPressed: root.launch(root.selectedIndex)
146:             onUpPressed: {
147:                 if (root.selectedIndex &gt; 0) {
148:                     root.selectedIndex--
149:                     resultsList.positionAt(root.selectedIndex)
150:                 }
151:             }
152:             onDownPressed: {
153:                 if (root.selectedIndex &lt; root.filteredApps.length - 1) {
154:                     root.selectedIndex++
155:                     resultsList.positionAt(root.selectedIndex)
156:                 }
157:             }
158:             onTabPressed: {
159:                 root.selectedIndex = (root.selectedIndex + 1) % Math.max(root.filteredApps.length, 1)
160:                 resultsList.positionAt(root.selectedIndex)
161:             }
162:         }
163: 
164:         // Divider
165:         Rectangle {
166:             id:      divider
167:             anchors { top: searchBar.bottom; left: parent.left; right: parent.right }
168:             height:  1
169:             color:   Colors.outlineVariant
170:             opacity: 0.5
171:         }
172: 
173:         // ── Results list ──────────────────────────────────────────────────
174:         LauncherResultsList {
175:             id:           resultsList
176:             anchors { top: divider.bottom; left: parent.left; right: parent.right }
177:             filteredApps:  root.filteredApps
178:             selectedIndex: root.selectedIndex
179:             searchText:    searchBar.text
180: 
181:             onLaunched:         (idx) =&gt; root.launch(idx)
182:             onSelectionChanged: (idx) =&gt; root.selectedIndex = idx
183: 
184:             layer.enabled: true
185:             layer.effect: OpacityMask {
186:                 maskSource: Rectangle {
187:                     width: resultsList.width
188:                     height: resultsList.height
189:                     bottomLeftRadius: Theme.popupRadius + 6
190:                     bottomRightRadius: Theme.popupRadius + 6
191:                 }
192:             }
193:         }
194:     }
195: 
196:     Timer {
197:         id: focusTimer
198:         interval: 32
199:         onTriggered: searchBar.forceActiveFocus()
200:     }
201: }</file><file path="src/popups/MediaPopup.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Wayland
  5: import Quickshell.Services.Mpris
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.popups.media
 10: 
 11: PanelWindow {
 12:     id: win
 13: 
 14:     property var screen
 15:     WlrLayershell.screen:        screen
 16:     WlrLayershell.layer:         WlrLayer.Overlay
 17:     WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
 18: 
 19:     anchors.top:   true
 20: 
 21:     implicitHeight: win.screen ? win.screen.height : 800
 22:     implicitWidth:  340
 23:     color:          &quot;transparent&quot;
 24:     exclusionMode:  ExclusionMode.Ignore
 25:     visible:        slide.windowVisible
 26: 
 27:     // ── Player resolution ─────────────────────────────────────────────────────
 28:     property var _players:    Mpris.players.values
 29:     property var _lastActive: null
 30: 
 31:     property var _currentlyPlaying: {
 32:         for (let i = 0; i &lt; _players.length; i++) {
 33:             if (_players[i].playbackState === MprisPlaybackState.Playing)
 34:                 return _players[i]
 35:         }
 36:         return null
 37:     }
 38: 
 39:     on_CurrentlyPlayingChanged: {
 40:         if (_currentlyPlaying) _lastActive = _currentlyPlaying
 41:     }
 42: 
 43:     property var player: {
 44:         if (_players.length === 0) return null
 45:         if (_currentlyPlaying)     return _currentlyPlaying
 46:         if (_lastActive) {
 47:             for (let i = 0; i &lt; _players.length; i++)
 48:                 if (_players[i] === _lastActive) return _lastActive
 49:         }
 50:         return _players[0]
 51:     }
 52: 
 53:     property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false
 54:     property bool hasArt:    player !== null &amp;&amp; player.trackArtUrl !== &quot;&quot;
 55: 
 56:     // ── Position tracking (seconds, float) ───────────────────────────────────
 57:     property real _position: 0.0
 58:     property bool _seeking:  false
 59: 
 60:     Timer {
 61:         interval: 1000
 62:         repeat:   true
 63:         running:  win.isPlaying &amp;&amp; !win._seeking
 64:         onTriggered: {
 65:             if (win.player &amp;&amp; win.player.positionSupported)
 66:                 win.player.positionChanged()   // nudge the binding per docs
 67:             win._position = win.player?.position ?? 0
 68:         }
 69:     }
 70: 
 71:     Connections {
 72:         target: win.player ?? null
 73:         function onTrackTitleChanged() { win._position = 0 }
 74:     }
 75: 
 76:     // ── Slide ─────────────────────────────────────────────────────────────────
 77:     PopupSlide {
 78:         id:           slide
 79:         anchors.fill: parent
 80:         open:         Popups.mediaOpen
 81:         edge:         &quot;top&quot;
 82:         onCloseRequested: Popups.mediaOpen = false
 83: 
 84:         // ── Card ──────────────────────────────────────────────────────────────────
 85:         Rectangle {
 86:             width:  340
 87:             anchors.top:              parent.top
 88:             anchors.horizontalCenter: parent.horizontalCenter
 89:             anchors.topMargin:        Theme.barHeight + 8
 90: 
 91:             implicitHeight: cardLayout.implicitHeight + 24
 92:             radius:         Theme.popupRadius
 93:             color:          Colors.surfaceContainer
 94:             border.color:   Colors.outlineVariant
 95:             border.width:   Theme.popupBorder
 96: 
 97:             ColumnLayout {
 98:                 id: cardLayout
 99:                 anchors {
100:                     top:          parent.top
101:                     left:         parent.left
102:                     right:        parent.right
103:                     topMargin:    12
104:                     leftMargin:   16
105:                     rightMargin:  16
106:                     bottomMargin: 12
107:                 }
108:                 spacing: 12
109: 
110:                 MediaArt {
111:                     player: win.player
112:                     hasArt: win.hasArt
113:                 }
114: 
115:                 MediaTrackInfo {
116:                     player: win.player
117:                 }
118: 
119:                 MediaProgress {
120:                     player:   win.player
121:                     position: win._position
122:                     seeking:  win._seeking
123: 
124:                     onSeekStarted: (pos) =&gt; { win._seeking = true;  win._position = pos }
125:                     onSeekMoved:   (pos) =&gt; { win._position = pos }
126:                     onSeekReleased: (pos) =&gt; {
127:                         if (win.player) win.player.position = pos
128:                         win._seeking = false
129:                     }
130:                 }
131: 
132:                 MediaControls {
133:                     player:    win.player
134:                     isPlaying: win.isPlaying
135:                 }
136: 
137:                 MediaVolumeRow {
138:                     player: win.player
139:                 }
140:             }
141:         }
142:     }
143: }</file><file path="src/popups/NotificationPanel.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import QtQuick.Controls
  4: import Quickshell
  5: import Quickshell.Wayland
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.services
 10: 
 11: PanelWindow {
 12:     id: root
 13: 
 14:     property var screen
 15: 
 16:     color:         &quot;transparent&quot;
 17:     exclusionMode: ExclusionMode.Ignore
 18: 
 19:     anchors {
 20:         top:   true
 21:         right: true
 22:     }
 23: 
 24:     implicitWidth:  380
 25:     implicitHeight: root.screen ? root.screen.height : 800
 26: 
 27:     WlrLayershell.layer: WlrLayer.Overlay
 28: 
 29:     visible: slidePanel.windowVisible
 30: 
 31:     PopupSlide {
 32:         id: slidePanel
 33:         anchors.fill: parent
 34:         edge: &quot;right&quot;
 35:         open: Popups.notificationsOpen
 36:         onCloseRequested: Popups.notificationsOpen = false
 37: 
 38:         // ── Panel card ────────────────────────────────────────────────────────────
 39:         Rectangle {
 40:             anchors {
 41:                 top:         parent.top
 42:                 right:       parent.right
 43:                 topMargin:   Theme.barHeight + 2
 44:                 rightMargin: Theme.barMargin
 45:             }
 46:             width:         360
 47:             height:        Math.min(
 48:                                notifCol.implicitHeight + 48,
 49:                                root.implicitHeight - Theme.barHeight - 24
 50:                            )
 51:             radius:        Theme.popupRadius
 52:             color:         Colors.background
 53:             border.color:  Colors.outlineVariant
 54:             border.width:  Theme.popupBorder
 55:             clip:          true
 56: 
 57:             // ── Header ────────────────────────────────────────────────────────────
 58:             Rectangle {
 59:                 id: panelHeader
 60:                 anchors { top: parent.top; left: parent.left; right: parent.right }
 61:                 height: 48
 62:                 color:  &quot;transparent&quot;
 63: 
 64:                 RowLayout {
 65:                     anchors { fill: parent; topMargin: 8; leftMargin: 16; rightMargin: 16; bottomMargin: 8 }
 66: 
 67:                     Text {
 68:                         text:           &quot;Notifications&quot;
 69:                         color:          Colors.on_Surface
 70:                         font.pixelSize: 14
 71:                         font.bold:      true
 72:                         font.family:    Fonts.font
 73:                         Layout.fillWidth: true
 74:                     }
 75: 
 76:                     // Clear all button
 77:                     Rectangle {
 78:                         visible:      NotificationService.notifications.length &gt; 0
 79:                         width:        90
 80:                         height:       26
 81:                         radius:       13
 82:                         color:        &quot;transparent&quot;
 83:                         border.color: Colors.outline
 84:                         border.width: 1
 85: 
 86:                         Rectangle {
 87:                             width: 90
 88:                             height: 26
 89:                             radius: 15
 90:                             color: Colors.primary
 91:                             opacity: clearHov.containsMouse ? 0.25 : 0
 92: 
 93:                             Behavior on opacity { NumberAnimation { duration: 150 } }
 94:                         }
 95: 
 96:                         Text {
 97:                             id:               clearText
 98:                             anchors.centerIn: parent
 99:                             text:             &quot;Clear all&quot;
100:                             color:            Colors.on_Surface
101:                             font.pixelSize:   11
102:                             font.family:      Fonts.font
103:                         }
104: 
105:                         MouseArea {
106:                             id:           clearHov
107:                             anchors.fill: parent
108:                             hoverEnabled: true
109:                             cursorShape:  Qt.PointingHandCursor
110:                             onClicked:    NotificationService.clearAll()
111:                         }
112:                     }
113:                 }
114: 
115:                 // Divider
116:                 Rectangle {
117:                     anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
118:                     height:  1
119:                     color:   Colors.outlineVariant
120:                     opacity: 0.5
121:                 }
122:             }
123: 
124:             // ── Notification list ─────────────────────────────────────────────────
125:             Flickable {
126:                 anchors {
127:                     top:    panelHeader.bottom
128:                     left:   parent.left
129:                     right:  parent.right
130:                     bottom: parent.bottom
131:                 }
132:                 contentHeight: notifCol.implicitHeight
133:                 clip:          true
134:                 boundsBehavior: Flickable.StopAtBounds
135: 
136:                 // ScrollBar.vertical: ScrollBar {
137:                 //     policy: ScrollBar.AsNeeded
138:                 //     contentItem: Rectangle {
139:                 //         implicitWidth:  3
140:                 //         implicitHeight: 40
141:                 //         radius:         1.5
142:                 //         color:          Qt.rgba(1, 1, 1, 0.25)
143:                 //     }
144:                 //     background: Item {}
145:                 // }
146: 
147:                 Column {
148:                     id:       notifCol
149:                     anchors { top: parent.top; left: parent.left; right: parent.right }
150:                     spacing:  4
151:                     padding:  8
152: 
153:                     // Empty state
154:                     Item {
155:                         visible: NotificationService.notifications.length === 0
156:                         width:   parent.width - 16
157:                         height:  80
158: 
159:                         ColumnLayout {
160:                             anchors.centerIn: parent
161:                             spacing: 6
162: 
163:                             Text {
164:                                 Layout.alignment: Qt.AlignHCenter
165:                                 text:             &quot;󰂚&quot;
166:                                 font.pixelSize:   28
167:                                 font.family:      Fonts.font
168:                                 color:            Colors.outline
169:                             }
170: 
171:                             Text {
172:                                 Layout.alignment: Qt.AlignHCenter
173:                                 text:             &quot;No notifications&quot;
174:                                 font.pixelSize:   12
175:                                 font.family:      Fonts.font
176:                                 color:            Colors.outline
177:                             }
178:                         }
179:                     }
180: 
181:                     // Notification items
182:                     Repeater {
183:                         model: NotificationService.notifications
184: 
185:                         delegate: Rectangle {
186:                             id:           notifItem
187:                             required property var modelData
188: 
189:                             width:   notifCol.width - 16
190:                             height:  notifBody.implicitHeight + 24
191:                             radius:  10
192:                             color:   itemHov.containsMouse
193:                                          ? Colors.surfaceContainerHighest
194:                                          : Colors.surfaceContainerHigh
195:                             border.width: 1
196:                             border.color: Colors.outlineVariant
197:                             Behavior on color { ColorAnimation { duration: 120 } }
198: 
199:                             RowLayout {
200:                                 id:      notifBody
201:                                 anchors { fill: parent; margins: 12 }
202:                                 spacing: 10
203: 
204:                                 // App icon
205:                                 Rectangle {
206:                                     width:  36
207:                                     height: 36
208:                                     radius: 8
209:                                     color:  Colors.primaryContainer
210:                                     Layout.alignment: Qt.AlignTop
211: 
212:                                     Image {
213:                                         anchors.centerIn: parent
214:                                         width:   22
215:                                         height:  22
216:                                         source:  notifItem.modelData &amp;&amp; notifItem.modelData.appIcon
217:                                                      ? &quot;image://icon/&quot; + notifItem.modelData.appIcon
218:                                                      : &quot;&quot;
219:                                         visible: source !== &quot;&quot;
220:                                         fillMode: Image.PreserveAspectFit
221:                                         smooth:   true
222:                                     }
223: 
224:                                     // Fallback icon when no app icon available
225:                                     Text {
226:                                         anchors.centerIn: parent
227:                                         visible:          !(notifItem.modelData &amp;&amp; notifItem.modelData.appIcon)
228:                                         text:             &quot;󰂚&quot;
229:                                         font.pixelSize:   16
230:                                         font.family:      Fonts.font
231:                                         color:            Colors.on_PrimaryContainer
232:                                     }
233:                                 }
234: 
235:                                 ColumnLayout {
236:                                     Layout.fillWidth: true
237:                                     spacing: 2
238: 
239:                                     RowLayout {
240:                                         Layout.fillWidth: true
241: 
242:                                         Text {
243:                                             text:           notifItem.modelData.appName || &quot;&quot;
244:                                             color:          Colors.on_SurfaceVariant
245:                                             font.pixelSize: 10
246:                                             font.family:    Fonts.font
247:                                             Layout.fillWidth: true
248:                                             elide:          Text.ElideRight
249:                                         }
250: 
251:                                         Text {
252:                                             text: NotificationService.formatTimestamp(
253:                                                 NotificationService.getPanelArrivalTime(
254:                                                     notifItem.modelData.id))
255:                                             color:          Colors.outline
256:                                             font.pixelSize: 10
257:                                             font.family:    Fonts.font
258:                                         }
259:                                     }
260: 
261:                                     Text {
262:                                         text:           notifItem.modelData.summary || &quot;&quot;
263:                                         color:          Colors.on_Surface
264:                                         font.pixelSize: 12
265:                                         font.bold:      true
266:                                         font.family:    Fonts.font
267:                                         Layout.fillWidth: true
268:                                         elide:          Text.ElideRight
269:                                     }
270: 
271:                                     Text {
272:                                         visible:        notifItem.modelData.body !== &quot;&quot;
273:                                         text:           notifItem.modelData.body || &quot;&quot;
274:                                         color:          Colors.on_SurfaceVariant
275:                                         font.pixelSize: 11
276:                                         font.family:    Fonts.font
277:                                         Layout.fillWidth: true
278:                                         wrapMode:       Text.WordWrap
279:                                         maximumLineCount: 3
280:                                         elide:          Text.ElideRight
281:                                     }
282:                                 }
283: 
284:                                 // Dismiss
285:                                 Rectangle {
286:                                     width:  20
287:                                     height: 20
288:                                     radius: 10
289:                                     color:  dimissItemHov.containsMouse
290:                                                 ? Qt.rgba(1, 1, 1, 0.12)
291:                                                 : &quot;transparent&quot;
292:                                     Layout.alignment: Qt.AlignTop
293: 
294:                                     Text {
295:                                         anchors.centerIn: parent
296:                                         text:             &quot;󰅖&quot;
297:                                         font.pixelSize:   11
298:                                         font.family:      Fonts.font
299:                                         color:            Colors.on_SurfaceVariant
300:                                     }
301: 
302:                                     MouseArea {
303:                                         id:           dimissItemHov
304:                                         anchors.fill: parent
305:                                         hoverEnabled: true
306:                                         cursorShape:  Qt.PointingHandCursor
307:                                         onClicked:    notifItem.modelData.dismiss()
308:                                     }
309:                                 }
310:                             }
311: 
312:                             MouseArea {
313:                                 id:           itemHov
314:                                 anchors.fill: parent
315:                                 hoverEnabled: true
316:                                 cursorShape:  Qt.PointingHandCursor
317:                                 // Clicking item dismisses it
318:                                 onClicked:    notifItem.modelData.dismiss()
319:                             }
320:                         }
321:                     }
322:                 }
323:             }
324:         }
325:     }
326: }</file><file path="src/services/system/SystemStats.qml">  1: pragma Singleton
  2: import QtQuick
  3: import Quickshell
  4: import Quickshell.Io
  5: import qs.src.state
  6: 
  7: Singleton {
  8:     id: root
  9: 
 10:     // ── CPU ───────────────────────────────────────────────────────────────────
 11:     property real cpuUsage: 0.0
 12:     property var  _cpuPrev: ({})
 13: 
 14:     // ── Memory ────────────────────────────────────────────────────────────────
 15:     property real memUsage: 0.0   // 0.0 - 1.0
 16:     property real memUsedGb:  0.0
 17:     property real memTotalGb: 0.0
 18: 
 19:     // ── GPU ───────────────────────────────────────────────────────────────────
 20:     property real gpuUsage: 0.0
 21:     property bool hasGpu:   false
 22: 
 23:     // ── Disk ──────────────────────────────────────────────────────────────────
 24:     // Array of { mount, used, total }
 25:     property var diskPartitions: []
 26: 
 27:     // ── Network ───────────────────────────────────────────────────────────────
 28:     property string activeInterface: &quot;&quot;
 29:     property real   netUpRate:    0.0
 30:     property real   netDownRate:  0.0
 31:     property var    netUpHistory:   []
 32:     property var    netDownHistory: []
 33:     property var    _netPrev: ({})
 34: 
 35:     readonly property int maxNetHistory: 60
 36: 
 37:     // ── Temperature ───────────────────────────────────────────────────────────
 38:     property int temperature: 0
 39: 
 40:     // ── Helpers ───────────────────────────────────────────────────────────────
 41:     function formatBytes(bps) {
 42:         if (bps &gt;= 1e9) return (bps / 1e9).toFixed(1) + &quot; GB/s&quot;
 43:         if (bps &gt;= 1e6) return (bps / 1e6).toFixed(1) + &quot; MB/s&quot;
 44:         if (bps &gt;= 1e3) return (bps / 1e3).toFixed(1) + &quot; KB/s&quot;
 45:         return bps.toFixed(0) + &quot; B/s&quot;
 46:     }
 47: 
 48:     // ── CPU polling ───────────────────────────────────────────────────────────
 49:     Process {
 50:         id: cpuProc
 51:         command: [&quot;cat&quot;, &quot;/proc/stat&quot;]
 52:         running: false
 53: 
 54:         stdout: SplitParser {
 55:             onRead: (line) =&gt; {
 56:                 const m = line.match(/^cpu\s+(.+)/)
 57:                 if (!m) return
 58:                 const parts = m[1].trim().split(/\s+/).map(Number)
 59:                 const idle  = parts[3] + parts[4]
 60:                 const total = parts.reduce((a, b) =&gt; a + b, 0)
 61:                 const prev  = root._cpuPrev
 62:                 const dIdle  = idle  - (prev.idle  || idle)
 63:                 const dTotal = total - (prev.total || total)
 64:                 root._cpuPrev = { idle, total }
 65:                 root.cpuUsage = dTotal &gt; 0
 66:                     ? Math.min((1.0 - dIdle / dTotal), 1.0)
 67:                     : 0.0
 68:             }
 69:         }
 70:     }
 71: 
 72:     // ── Memory polling ────────────────────────────────────────────────────────
 73:     Process {
 74:         id: memProc
 75:         command: [&quot;cat&quot;, &quot;/proc/meminfo&quot;]
 76:         running: false
 77: 
 78:         stdout: SplitParser {
 79:             property int _total: 0
 80: 
 81:             onRead: (line) =&gt; {
 82:                 const val = parseInt(line.split(/\s+/)[1])
 83:                 if      (line.startsWith(&quot;MemTotal:&quot;))     _total = val
 84:                 else if (line.startsWith(&quot;MemAvailable:&quot;)) {
 85:                     const usedKb      = _total - val
 86:                     root.memTotalGb   = _total   / 1024 / 1024
 87:                     root.memUsedGb    = usedKb   / 1024 / 1024
 88:                     root.memUsage     = _total &gt; 0 ? usedKb / _total : 0
 89:                 }
 90:             }
 91:         }
 92:     }
 93: 
 94:     // ── GPU polling ───────────────────────────────────────────────────────────
 95:     // Checks for AMD gpu_busy_percent. If file doesn&apos;t exist, hasGpu = false.
 96:     Process {
 97:         id: gpuCheckProc
 98:         command: [&quot;sh&quot;, &quot;-c&quot;,
 99:             &quot;f=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2&gt;/dev/null | head -1); &quot; +
100:             &quot;[ -n \&quot;$f\&quot; ] &amp;&amp; echo $f || echo NONE&quot;]
101:         running: true
102: 
103:         stdout: SplitParser {
104:             onRead: (line) =&gt; {
105:                 const path = line.trim()
106:                 if (path === &quot;NONE&quot; || path === &quot;&quot;) {
107:                     root.hasGpu = false
108:                 } else {
109:                     root.hasGpu    = true
110:                     gpuReadProc.command = [&quot;cat&quot;, path]
111:                 }
112:             }
113:         }
114:     }
115: 
116:     Process {
117:         id: gpuReadProc
118:         command: []
119:         running: false
120: 
121:         stdout: SplitParser {
122:             onRead: (line) =&gt; {
123:                 const v = parseInt(line.trim())
124:                 if (!isNaN(v)) root.gpuUsage = v / 100.0
125:             }
126:         }
127:     }
128: 
129:     // ── Disk polling ──────────────────────────────────────────────────────────
130:     // df -B1 excludes tmpfs/devtmpfs/overlay/squashfs
131:     Process {
132:         id: diskProc
133:         command: [&quot;sh&quot;, &quot;-c&quot;,
134:             &quot;df -B1 --output=target,used,size -x tmpfs -x devtmpfs -x overlay -x squashfs &quot; +
135:             &quot;| tail -n +2&quot;]
136:         running: false
137: 
138:         property var _diskLines: []
139: 
140:         stdout: SplitParser {
141:             onRead: (line) =&gt; {
142:                 const parts = line.trim().split(/\s+/)
143:                 if (parts.length &lt; 3) return
144:                 const mount = parts[0]
145:                 const used  = parseInt(parts[1])
146:                 const total = parseInt(parts[2])
147:                 if (isNaN(used) || isNaN(total) || total === 0) return
148: 
149:                 // Only show root and physical mounts (skip snap, boot etc.)
150:                 const skip = [&quot;/boot&quot;, &quot;/boot/efi&quot;, &quot;/snap&quot;, &quot;/sys/firmware/efi/efivars&quot;, &quot;/.snapshots&quot;, &quot;/var/cache&quot;, &quot;/home&quot;, &quot;/var/log&quot;]
151:                 if (skip.some(s =&gt; mount.startsWith(s))) return
152: 
153:                 diskProc._diskLines.push({ mount, used, total })
154:             }
155:         }
156: 
157:         onExited: {
158:             root.diskPartitions = diskProc._diskLines.slice()
159:             diskProc._diskLines = []
160:         }
161:     }
162: 
163:     // ── Network polling ───────────────────────────────────────────────────────
164:     Process {
165:         id: netProc
166:         command: [&quot;cat&quot;, &quot;/proc/net/dev&quot;]
167:         running: false
168: 
169:         stdout: SplitParser {
170:             onRead: (line) =&gt; {
171:                 const m = line.match(/^\s*(\w+):\s+(\d+).*\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/)
172:                 if (!m) return
173:                 const iface = m[1]
174: 
175:                 // Skip loopback and virtual interfaces
176:                 if (iface === &quot;lo&quot; || iface.startsWith(&quot;vir&quot;) ||
177:                     iface.startsWith(&quot;docker&quot;) || iface.startsWith(&quot;br-&quot;)) return
178: 
179:                 const rx = parseInt(m[2])
180:                 const tx = parseInt(m[4])
181: 
182:                 const prev = root._netPrev[iface]
183:                 if (prev) {
184:                     const downRate = Math.max(0, rx - prev.rx)
185:                     const upRate   = Math.max(0, tx - prev.tx)
186: 
187:                     // Use the interface with the highest traffic as active
188:                     if (downRate + upRate &gt; (root._netPrev._bestRate || 0)) {
189:                         root._netPrev._bestRate   = downRate + upRate
190:                         root.activeInterface      = iface
191:                         root.netDownRate          = downRate
192:                         root.netUpRate            = upRate
193: 
194:                         // Append to history, cap at maxNetHistory
195:                         let dHist = root.netDownHistory.slice()
196:                         let uHist = root.netUpHistory.slice()
197:                         dHist.push(downRate)
198:                         uHist.push(upRate)
199:                         if (dHist.length &gt; root.maxNetHistory) dHist.shift()
200:                         if (uHist.length &gt; root.maxNetHistory) uHist.shift()
201:                         root.netDownHistory = dHist
202:                         root.netUpHistory   = uHist
203:                     }
204:                 }
205: 
206:                 root._netPrev[iface] = { rx, tx }
207:             }
208:         }
209: 
210:         onExited: {
211:             // Hysteresis: only reset if active interface dropped near-zero
212:             if (root.netDownRate &lt; 512 &amp;&amp; root.netUpRate &lt; 512) {
213:                 root._netPrev._bestRate = 0
214:             }
215:         }
216:     }
217: 
218:     // ── Temperature polling ───────────────────────────────────────────────────
219:     Process {
220:         id: tempProc
221:         command: [&quot;sh&quot;, &quot;-c&quot;,
222:             &quot;cat /sys/class/thermal/thermal_zone*/temp 2&gt;/dev/null | sort -n | tail -1&quot;]
223:         running: false
224: 
225:         stdout: SplitParser {
226:             onRead: (line) =&gt; {
227:                 const v = parseInt(line.trim())
228:                 if (!isNaN(v)) root.temperature = Math.round(v / 1000)
229:             }
230:         }
231:     }
232: 
233:     // ── Main poll timer — 1s interval ─────────────────────────────────────────
234:     Timer {
235:         interval:        1000
236:         running:         true
237:         repeat:          true
238:         triggeredOnStart: true
239: 
240:         onTriggered: {
241:             cpuProc.running  = true
242:             memProc.running  = true
243:             netProc.running  = true
244:             if (Popups.systemOpen) {
245:                 tempProc.running = true
246:                 if (root.hasGpu) gpuReadProc.running = true
247:             }
248:         }
249:     }
250: 
251:     Connections {
252:         target: Popups
253:         function onSystemOpenChanged() {
254:             if (Popups.systemOpen) diskProc.running = true
255:         }
256:     }
257: }</file><file path="src/theme/Theme.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: 
 5: QtObject {
 6:     id: root
 7: 
 8:     // ── Pill geometry ─────────────────────────────────────────────────────────
 9:     readonly property int borderWidth:   3
10:     readonly property int barHeight:     36
11:     readonly property int pillHeight:    30
12:     readonly property int pillRadius:    15
13:     readonly property int pillPadding:   32   // added to content width
14:     readonly property int barSpacing:    8  // spacing between pills
15:     readonly property int barMargin:     8    // outer margin inside bar
16: 
17:     // ── Popup geometry ────────────────────────────────────────────────────────
18:     readonly property int popupRadius:   14
19:     readonly property int popupBorder:   1
20: 
21:     // ── Animation ─────────────────────────────────────────────────────────────
22:     readonly property int animDuration:      250
23:     readonly property int hoverFadeDuration: 150
24:     readonly property int slideInDuration:   400
25:     readonly property int hoverCloseDelay:   300
26: 
27:     // Bezier curve used on popup open/close (matches your SystemPopup)
28:     readonly property var slideCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
29: 
30:     // ── Hover ─────────────────────────────────────────────────────────────────
31:     readonly property real hoverOpacity:     0.15  // primary at 15% for pill hover bg
32:     readonly property int  hoverWidthGain:   10    // pill expands by this on hover
33: }</file><file path="src/popups/NetworkPopup.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Wayland
  5: import Quickshell.Networking
  6: import qs.src.services
  7: import qs.src.state
  8: import qs.src.theme
  9: import qs.src.components
 10: 
 11: PanelWindow {
 12:     id: root
 13: 
 14:     property var screen
 15: 
 16:     color:         &quot;transparent&quot;
 17:     exclusionMode: ExclusionMode.Ignore
 18: 
 19:     anchors {
 20:         top:   true
 21:         right: true
 22:     }
 23: 
 24:     implicitWidth:  380
 25:     implicitHeight: root.screen ? root.screen.height : 800
 26: 
 27:     WlrLayershell.layer: WlrLayer.Overlay
 28:     WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
 29:     visible: slide.windowVisible
 30: 
 31:     Binding {
 32:         target: NetworkService
 33:         property: &quot;scannerActive&quot;
 34:         value: Popups.networkOpen
 35:     }
 36: 
 37:     PopupSlide {
 38:         id: slide
 39:         anchors.fill: parent
 40:         edge: &quot;top&quot;
 41:         open: Popups.networkOpen
 42:         onCloseRequested: Popups.networkOpen = false
 43: 
 44:         // ── Popup card ────────────────────────────────────────────────────────────
 45:         Rectangle {
 46:             anchors {
 47:                 top:        parent.top
 48:                 right:      parent.right
 49:                 topMargin:  Theme.barHeight + 8
 50:                 rightMargin: Theme.barMargin
 51:             }
 52: 
 53:             width:        360
 54:             height:       mainCol.implicitHeight + 18
 55:             radius:       Theme.popupRadius
 56:             color:        Colors.surfaceContainer
 57:             border.color: Colors.outlineVariant
 58:             border.width: Theme.popupBorder
 59:             clip:         true
 60: 
 61:             ColumnLayout {
 62:                 id: mainCol
 63:                 anchors {
 64:                     top:          parent.top
 65:                     left:         parent.left
 66:                     right:        parent.right
 67:                     topMargin:    10
 68:                     leftMargin:   16
 69:                     rightMargin:  16
 70:                     bottomMargin: 16
 71:                 }
 72:                 spacing: 12
 73: 
 74:                 // ── Tab bar ──────────────────────────────────────────────────────
 75:                 TabBar {
 76:                     id: tabs
 77:                     Layout.fillWidth: true
 78:                     orientation: &quot;horizontal&quot;
 79:                     currentPage: [&quot;wifi&quot;, &quot;bluetooth&quot;, &quot;hotspot&quot;][Popups.networkTab]
 80:                     model: [
 81:                         { key: &quot;wifi&quot;,      icon: &quot;󰤨&quot;, label: &quot;Wi-Fi&quot;    },
 82:                         { key: &quot;bluetooth&quot;, icon: &quot;󰂯&quot;, label: &quot;Bluetooth&quot; },
 83:                         { key: &quot;hotspot&quot;,   icon: &quot;󰀂&quot;, label: &quot;Hotspot&quot;   }
 84:                     ]
 85:                     onPageChanged: (key) =&gt; {
 86:                         const idx = [&quot;wifi&quot;, &quot;bluetooth&quot;, &quot;hotspot&quot;].indexOf(key)
 87:                         if (idx &gt;= 0) Popups.networkTab = idx
 88:                     }
 89:                 }
 90: 
 91:                 // ── WiFi tab ─────────────────────────────────────────────────────
 92:                 ColumnLayout {
 93:                     visible: Popups.networkTab === 0
 94:                     Layout.fillWidth: true
 95:                     spacing: 8
 96: 
 97:                     RowLayout {
 98:                         Layout.fillWidth: true
 99:                         Layout.bottomMargin: 4
100: 
101:                         Text {
102:                             text: &quot;Wi-Fi&quot;
103:                             color: Colors.on_SurfaceVariant
104:                             font.pixelSize: 11
105:                             font.bold: true
106:                             font.family: Fonts.font
107:                             leftPadding: 4
108:                             Layout.fillWidth: true
109:                         }
110: 
111:                         Rectangle {
112:                             width: 40; height: 22; radius: 11
113:                             color: NetworkService.wifiEnabled ? Colors.primary : Colors.surfaceContainerHighest
114:                             border.width: NetworkService.wifiEnabled ? 0 : 1
115:                             border.color: Colors.outlineVariant
116:                             opacity: (NetworkService.wifiHardwareEnabled ?? true) ? 1.0 : 0.4
117:                             
118:                             Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
119: 
120:                             Rectangle {
121:                                 width: 16; height: 16; radius: 8
122:                                 color: NetworkService.wifiEnabled ? Colors.on_Primary : Colors.outline
123:                                 anchors.verticalCenter: parent.verticalCenter
124:                                 x: NetworkService.wifiEnabled ? 20 : 4
125:                                 Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
126:                             }
127: 
128:                             MouseArea {
129:                                 anchors.fill: parent
130:                                 enabled: NetworkService.wifiHardwareEnabled ?? true
131:                                 onClicked: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
132:                                 cursorShape: Qt.PointingHandCursor
133:                             }
134:                         }
135:                     }
136: 
137:                     Flickable {
138:                         Layout.fillWidth: true
139:                         Layout.preferredHeight: Math.min(networkCol.implicitHeight, 280)
140:                         contentHeight: networkCol.implicitHeight
141:                         clip: true
142:                         visible: NetworkService.wifiEnabled
143:                         boundsBehavior: Flickable.StopAtBounds
144: 
145:                         ColumnLayout {
146:                             id: networkCol
147:                             width: parent.width
148:                             spacing: 4
149: 
150:                             Repeater {
151:                                 model: NetworkService.networks
152: 
153:                                 delegate: NetworkRow {
154:                                     required property var modelData
155:                                     Layout.fillWidth: true
156:                                     network: modelData
157:                                 }
158:                             }
159: 
160:                             Text {
161:                                 visible: NetworkService.networks.length === 0
162:                                 Layout.alignment: Qt.AlignHCenter
163:                                 text: &quot;Scanning…&quot;
164:                                 font.family: Fonts.font
165:                                 font.pixelSize: 11
166:                                 color: Colors.outline
167:                                 topPadding: 8; bottomPadding: 8
168:                             }
169:                         }
170:                     }
171: 
172:                     Text {
173:                         visible: !NetworkService.wifiEnabled
174:                         Layout.alignment: Qt.AlignHCenter
175:                         text: &quot;Wi-Fi is disabled&quot;
176:                         font.family: Fonts.font
177:                         font.pixelSize: 11
178:                         color: Colors.outline
179:                         topPadding: 8; bottomPadding: 8
180:                     }
181:                 }
182: 
183:                 // ── Bluetooth tab ─────────────────────────────────────────────────
184:                 ColumnLayout {
185:                     visible: Popups.networkTab === 1
186:                     Layout.fillWidth: true
187:                     spacing: 8
188: 
189:                     RowLayout {
190:                         Layout.fillWidth: true
191:                         Layout.bottomMargin: 4
192: 
193:                         Text {
194:                             text: &quot;Bluetooth&quot;
195:                             color: Colors.on_SurfaceVariant
196:                             font.pixelSize: 11
197:                             font.bold: true
198:                             font.family: Fonts.font
199:                             leftPadding: 4
200:                             Layout.fillWidth: true
201:                         }
202: 
203:                         Rectangle {
204:                             width: 40; height: 22; radius: 11
205:                             color: NetworkService.btEnabled ? Colors.primary : Colors.surfaceContainerHighest
206:                             border.width: NetworkService.btEnabled ? 0 : 1
207:                             border.color: Colors.outlineVariant
208:                             opacity: NetworkService.btAdapter ? 1.0 : 0.4
209:                             
210:                             Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
211: 
212:                             Rectangle {
213:                                 width: 16; height: 16; radius: 8
214:                                 color: NetworkService.btEnabled ? Colors.on_Primary : Colors.outline
215:                                 anchors.verticalCenter: parent.verticalCenter
216:                                 x: NetworkService.btEnabled ? 20 : 4
217:                                 Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
218:                             }
219: 
220:                             MouseArea {
221:                                 anchors.fill: parent
222:                                 enabled: NetworkService.btAdapter !== null
223:                                 onClicked: NetworkService.setBtEnabled(!NetworkService.btEnabled)
224:                                 cursorShape: Qt.PointingHandCursor
225:                             }
226:                         }
227:                     }
228: 
229:                     ColumnLayout {
230:                         Layout.fillWidth: true
231:                         spacing: 4
232:                         visible: NetworkService.btEnabled
233: 
234:                         Repeater {
235:                             model: NetworkService.btDevices
236: 
237:                             delegate: Item {
238:                                 required property var modelData
239:                                 Layout.fillWidth: true
240:                                 implicitHeight: 44
241: 
242:                                 // Row hover detection — HoverHandler doesn&apos;t consume click events
243:                                 HoverHandler { id: rowHover }
244: 
245:                                 Rectangle {
246:                                     anchors.fill: parent
247:                                     radius: 10
248:                                     color: rowHover.hovered
249:                                         ? Colors.surfaceContainerHighest
250:                                         : modelData.connected
251:                                             ? Qt.rgba(Colors.primaryContainer.r, Colors.primaryContainer.g, Colors.primaryContainer.b, 0.3)
252:                                             : Colors.surfaceContainerHigh
253:                                     Behavior on color { ColorAnimation { duration: 120 } }
254:                                 }
255: 
256:                                 RowLayout {
257:                                     anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
258:                                     spacing: 10
259: 
260:                                     Text {
261:                                         text: {
262:                                             const ic = modelData.icon ?? &quot;&quot;
263:                                             if (ic.includes(&quot;headphone&quot;) || ic.includes(&quot;headset&quot;)) return &quot;󰋋&quot;
264:                                             if (ic.includes(&quot;phone&quot;))    return &quot;󰄜&quot;
265:                                             if (ic.includes(&quot;keyboard&quot;)) return &quot;󰌌&quot;
266:                                             if (ic.includes(&quot;mouse&quot;))    return &quot;󰍽&quot;
267:                                             if (ic.includes(&quot;speaker&quot;))  return &quot;󰓃&quot;
268:                                             if (ic.includes(&quot;computer&quot;)) return &quot;󰇄&quot;
269:                                             return &quot;󰂯&quot;
270:                                         }
271:                                         font.family: Fonts.fontM
272:                                         font.pixelSize: 16
273:                                         color: modelData.connected ? Colors.primary : Colors.outline
274:                                     }
275: 
276:                                     Text {
277:                                         text: modelData.name
278:                                         font.family: Fonts.font
279:                                         font.pixelSize: 12
280:                                         font.bold: true
281:                                         color: Colors.on_Surface
282:                                         elide: Text.ElideRight
283:                                         Layout.fillWidth: true
284:                                     }
285: 
286:                                     Text {
287:                                         visible: modelData.hasBattery ?? false
288:                                         text: Math.round((modelData.battery ?? 0) * 100) + &quot;%&quot;
289:                                         font.family: Fonts.font
290:                                         font.pixelSize: 10
291:                                         color: Colors.outline
292:                                     }
293: 
294:                                     // Connect / Connected chip button
295:                                     Rectangle {
296:                                         width: chipLabel.implicitWidth + 20
297:                                         height: 24
298:                                         radius: 12
299:                                         color: modelData.connected ? Colors.primary : Colors.surfaceContainerHighest
300:                                         border.width: modelData.connected ? 0 : 1
301:                                         border.color: Colors.outline
302:                                         Behavior on color { ColorAnimation { duration: 120 } }
303: 
304:                                         Text {
305:                                             id: chipLabel
306:                                             anchors.centerIn: parent
307:                                             text: modelData.connected ? &quot;Connected&quot; : &quot;Connect&quot;
308:                                             color: modelData.connected ? Colors.on_Primary : Colors.on_Surface
309:                                             font.pixelSize: 10
310:                                             font.bold: true
311:                                             font.family: Fonts.font
312:                                         }
313: 
314:                                         MouseArea {
315:                                             anchors.fill: parent
316:                                             cursorShape: Qt.PointingHandCursor
317:                                             onClicked: modelData.connected = !modelData.connected
318:                                         }
319:                                     }
320:                                 }
321:                             }
322:                         }
323: 
324:                         Text {
325:                             visible: (NetworkService.btDevices?.length ?? 0) === 0
326:                             Layout.alignment: Qt.AlignHCenter
327:                             text: &quot;No devices connected&quot;
328:                             font.family: Fonts.font
329:                             font.pixelSize: 11
330:                             color: Colors.outline
331:                             topPadding: 8; bottomPadding: 8
332:                         }
333:                     }
334: 
335:                     Text {
336:                         visible: !NetworkService.btEnabled
337:                         Layout.alignment: Qt.AlignHCenter
338:                         text: NetworkService.btAdapter ? &quot;Bluetooth is disabled&quot; : &quot;No Bluetooth adapter found&quot;
339:                         font.family: Fonts.font
340:                         font.pixelSize: 11
341:                         color: Colors.outline
342:                         topPadding: 8; bottomPadding: 8
343:                     }
344:                 }
345: 
346:                 // ── Hotspot tab ───────────────────────────────────────────────────
347:                 ColumnLayout {
348:                     visible: Popups.networkTab === 2
349:                     Layout.fillWidth: true
350:                     spacing: 6
351: 
352:                     Text {
353:                         Layout.alignment: Qt.AlignHCenter
354:                         text: &quot;󰀂&quot;
355:                         font.family: Fonts.fontM
356:                         font.pixelSize: 32
357:                         color: Colors.outline
358:                         topPadding: 12
359:                     }
360: 
361:                     Text {
362:                         Layout.alignment: Qt.AlignHCenter
363:                         text: &quot;Hotspot coming soon&quot;
364:                         font.family: Fonts.font
365:                         font.pixelSize: 11
366:                         color: Colors.outline
367:                         bottomPadding: 12
368:                     }
369:                 }
370:             }
371:         }
372:     }
373: }</file><file path="src/popups/qmldir"> 1: NotificationToast    1.0    NotificationToast.qml
 2: NotificationPanel    1.0    NotificationPanel.qml
 3: ToastItem            1.0    ToastItem.qml
 4: SystemPopup          1.0    SystemPopup.qml
 5: VolumePopup          1.0    VolumePopup.qml
 6: VolumeSlider         1.0    VolumeSlider.qml
 7: DeviceRow            1.0    DeviceRow.qml
 8: NetworkPopup         1.0    NetworkPopup.qml
 9: NetworkRow           1.0    NetworkRow.qml
10: MediaPopup           1.0    MediaPopup.qml
11: Launcher             1.0    Launcher.qml
12: ClipboardPopup       1.0    ClipboardPopup.qml</file><file path="src/popups/SystemPopup.qml">  1: import QtQuick
  2: import QtQuick.Layouts
  3: import Quickshell
  4: import Quickshell.Wayland
  5: import Quickshell.Io
  6: import qs.src.components
  7: import qs.src.theme
  8: import qs.src.state
  9: import qs.src.services.system
 10: import qs.src.services
 11: import qs.src.popups.system
 12: 
 13: PanelWindow {
 14:     id: root
 15: 
 16:     property var screen
 17: 
 18:     color:         &quot;transparent&quot;
 19:     exclusionMode: ExclusionMode.Ignore
 20: 
 21:     anchors {
 22:         top:   true
 23:         right: true
 24:     }
 25: 
 26:     implicitWidth:  420
 27:     implicitHeight: root.screen ? root.screen.height : 800
 28: 
 29:     WlrLayershell.layer: WlrLayer.Overlay
 30:     visible: slidePanel.windowVisible
 31: 
 32:     PopupSlide {
 33:         id: slidePanel
 34:         anchors.fill: parent
 35:         edge: &quot;top&quot;
 36:         open: Popups.systemOpen
 37:         onCloseRequested: Popups.systemOpen = false
 38: 
 39:         // ── Popup card ────────────────────────────────────────────────────────────
 40:         Rectangle {
 41:             anchors {
 42:                 top:         parent.top
 43:                 right:       parent.right
 44:                 topMargin:   Theme.barHeight + 8
 45:                 rightMargin: Theme.barMargin
 46:             }
 47:             width:        400
 48:             height:       cardCol.implicitHeight + 24
 49:             radius:       Theme.popupRadius
 50:             color:        Colors.surfaceContainer
 51:             border.color: Colors.outlineVariant
 52:             border.width: Theme.popupBorder
 53:             clip:         true
 54: 
 55:             ColumnLayout {
 56:                 id: cardCol
 57:                 anchors {
 58:                     top:   parent.top
 59:                     left:  parent.left
 60:                     right: parent.right
 61:                     margins: 16
 62:                 }
 63:                 spacing: 16
 64: 
 65:                 // ── Header ────────────────────────────────────────────────────────
 66:                 Text {
 67:                     text:           &quot;System&quot;
 68:                     color:          Colors.on_Surface
 69:                     font.pixelSize: 14
 70:                     font.bold:      true
 71:                     font.family:    Fonts.font
 72:                     Layout.topMargin: 4
 73:                 }
 74: 
 75:                 // Divider
 76:                 Rectangle {
 77:                     Layout.fillWidth: true
 78:                     height:  1
 79:                     color:   Colors.outlineVariant
 80:                     opacity: 0.5
 81:                 }
 82: 
 83:                 // ── Speedometers row ──────────────────────────────────────────────
 84:                 RowLayout {
 85:                     Layout.fillWidth: true
 86:                     spacing: 8
 87: 
 88:                     Speedometer {
 89:                         label:   &quot;CPU&quot;
 90:                         value:   SystemStats.cpuUsage
 91:                         color:   Colors.primary
 92:                         Layout.fillWidth: true
 93:                     }
 94: 
 95:                     Speedometer {
 96:                         label:   &quot;RAM&quot;
 97:                         value:   SystemStats.memUsage
 98:                         color:   Colors.secondary
 99:                         Layout.fillWidth: true
100:                     }
101: 
102:                     // GPU — only shown on AMD
103:                     Speedometer {
104:                         visible: SystemStats.hasGpu
105:                         label:   &quot;GPU&quot;
106:                         value:   SystemStats.gpuUsage
107:                         color:   Colors.tertiary
108:                         Layout.fillWidth: true
109:                     }
110:                 }
111: 
112:                 // ── Disk bars ─────────────────────────────────────────────────────
113:                 ColumnLayout {
114:                     Layout.fillWidth: true
115:                     spacing: 8
116: 
117:                     Repeater {
118:                         model: SystemStats.diskPartitions
119: 
120:                         delegate: DiskBar {
121:                             required property var modelData
122:                             Layout.fillWidth: true
123: 
124:                             mountPoint: modelData.mount
125:                             usedBytes:  modelData.used
126:                             totalBytes: modelData.total
127:                             freeBytes:  modelData.total - modelData.used
128:                             label:      modelData.mount === &quot;/&quot; ? &quot;Root&quot; : modelData.mount
129:                         }
130:                     }
131:                 }
132: 
133:                 // Divider
134:                 Rectangle {
135:                     Layout.fillWidth: true
136:                     height:  1
137:                     color:   Colors.outlineVariant
138:                     opacity: 0.5
139:                 }
140: 
141:                 // ── Network graph ─────────────────────────────────────────────────
142:                 ColumnLayout {
143:                     Layout.fillWidth: true
144:                     spacing: 6
145: 
146:                     RowLayout {
147:                         Layout.fillWidth: true
148: 
149:                         Text {
150:                             text:           &quot;Network  &quot; + SystemStats.activeInterface
151:                             color:          Colors.on_SurfaceVariant
152:                             font.pixelSize: 11
153:                             font.family:    Fonts.font
154:                             Layout.fillWidth: true
155:                         }
156: 
157:                         Text {
158:                             text:           &quot;↑ &quot; + SystemStats.formatBytes(SystemStats.netUpRate)
159:                                           + &quot;  ↓ &quot; + SystemStats.formatBytes(SystemStats.netDownRate)
160:                             color:          Colors.on_Surface
161:                             font.pixelSize: 11
162:                             font.bold:      true
163:                             font.family:    Fonts.font
164:                         }
165:                     }
166: 
167:                     NetworkGraph {
168:                         Layout.fillWidth: true
169:                         height:           60
170:                         upHistory:        SystemStats.netUpHistory
171:                         downHistory:      SystemStats.netDownHistory
172:                     }
173:                 }
174: 
175:                 // Divider
176:                 Rectangle {
177:                     Layout.fillWidth: true
178:                     height:  1
179:                     color:   Colors.outlineVariant
180:                     opacity: 0.5
181:                 }
182: 
183:                 // ── Temperature ───────────────────────────────────────────────────
184:                 RowLayout {
185:                     Layout.fillWidth: true
186:                     Layout.bottomMargin: 4
187: 
188:                     Text {
189:                         text:           &quot;󰔏  Temperature&quot;
190:                         color:          Colors.on_SurfaceVariant
191:                         font.pixelSize: 11
192:                         font.family:    Fonts.font
193:                         Layout.fillWidth: true
194:                     }
195: 
196:                     Text {
197:                         text: SystemStats.temperature &gt; 0
198:                                   ? SystemStats.temperature + &quot; °C&quot;
199:                                   : &quot;N/A&quot;
200:                         color: SystemStats.temperature &gt;= 80
201:                                    ? Colors.error
202:                                    : SystemStats.temperature &gt;= 60
203:                                        ? Colors.tertiary
204:                                        : Colors.on_Surface
205:                         font.pixelSize: 12
206:                         font.bold:      true
207:                         font.family:    Fonts.font
208: 
209:                         Behavior on color { ColorAnimation { duration: 300 } }
210:                     }
211:                 }
212:             }
213:         }
214:     }
215: }</file><file path="src/components/PillBase.qml"> 1: import QtQuick
 2: import QtQuick.Layouts
 3: import qs.src.theme
 4: 
 5: Rectangle {
 6:     id: root
 7: 
 8:     // ── Content ───────────────────────────────────────────────────────────────
 9:     default property alias contentData: innerLayout.data
10: 
11:     // ── Behaviour Flags ───────────────────────────────────────────────────────
12:     property bool hoverExpand:  true // +10px width on hover
13:     property bool hoverEnabled: true // show bg highlight on hover
14:     property bool mouseEnabled: true
15: 
16:     // ── Signals ───────────────────────────────────────────────────────────────
17:     signal clicked(var mouse)
18:     signal rightClicked(var mouse)
19:     signal scrolled(var wheel)
20: 
21:     // ── Geometry ──────────────────────────────────────────────────────────────
22:     implicitWidth:  innerLayout.implicitWidth + Theme.pillPadding + (hoverExpand &amp;&amp; hov.containsMouse ? Theme.hoverWidthGain : 0)
23:     implicitHeight: Theme.pillHeight
24:     radius:         Theme.pillRadius
25:     color:          Colors.background
26: 
27:     Behavior on implicitWidth {
28:         NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic }
29:     }
30: 
31:     // ── Hover Highlight ───────────────────────────────────────────────────────
32:     Rectangle {
33:         anchors.fill: parent
34:         radius:       parent.radius
35:         color:        Colors.primary
36:         opacity:      hoverEnabled &amp;&amp; hov.containsMouse ? Theme.hoverOpacity : 0
37:         
38:         Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
39:     }
40: 
41:     // ── Content Layout ────────────────────────────────────────────────────────
42:     RowLayout {
43:         id: innerLayout
44:         anchors.centerIn: parent
45:         spacing:          8
46:     }
47: 
48:     // ── Input ─────────────────────────────────────────────────────────────────
49:     MouseArea {
50:         id:              hov
51:         anchors.fill:    parent
52:         enabled:         root.mouseEnabled
53:         hoverEnabled:    true
54:         acceptedButtons: Qt.LeftButton | Qt.RightButton
55:         cursorShape:     Qt.PointingHandCursor
56: 
57:         onClicked: (mouse) =&gt; mouse.button === Qt.RightButton ? root.rightClicked(mouse) : root.clicked(mouse)
58:         onWheel:   (wheel) =&gt; root.scrolled(wheel)
59:     }
60: }</file><file path="src/state/Popups.qml"> 1: pragma Singleton
 2: import QtQuick
 3: import Quickshell
 4: 
 5: Singleton {
 6:     id: root
 7: 
 8:     // ── Timing Constants ──────────────────────────────────────────────────────
 9: 
10:     // ── Popup States ──────────────────────────────────────────────────────────
11:     property bool notificationsOpen: false
12:     property bool systemOpen:        false
13:     property bool archMenuOpen:      false
14:     property bool calendarOpen:      false
15:     property bool mediaOpen:         false
16:     property bool idleInhibitorOpen: false
17:     property bool volumeOpen:        false
18:     property bool launcherOpen:      false
19:     property bool clipboardOpen:     false
20:     property bool networkOpen:       false
21:     property int  networkTab:        0
22: 
23:     // Note: Tray context menu is managed internally by TrayContextMenu.
24:     // No open bool needed here; TrayContextMenu owns its own state.
25: 
26:     // ── Aggregate State ───────────────────────────────────────────────────────
27:     readonly property bool anyOpen:
28:         notificationsOpen ||
29:         systemOpen        ||
30:         archMenuOpen      ||
31:         calendarOpen      ||
32:         mediaOpen         ||
33:         idleInhibitorOpen ||
34:         volumeOpen        ||
35:         clipboardOpen     ||
36:         launcherOpen      ||
37:         networkOpen
38: 
39:     // ── Methods ───────────────────────────────────────────────────────────────
40:     function closeAll() {
41:         notificationsOpen = false
42:         systemOpen        = false
43:         archMenuOpen      = false
44:         calendarOpen      = false
45:         mediaOpen         = false
46:         idleInhibitorOpen = false
47:         volumeOpen        = false
48:         networkOpen       = false
49:         clipboardOpen     = false
50:         launcherOpen      = false
51:     }
52: }</file><file path="shell.qml"> 1: //@ pragma UseQApplication
 2: import QtQuick
 3: import Quickshell
 4: import Quickshell.Hyprland
 5: import Quickshell.Wayland
 6: import qs.src.windows
 7: import qs.src.popups
 8: import qs.src.state
 9: 
10: ShellRoot {
11:     // ── Per-screen scope ──────────────────────────────────────────────────────
12:     Variants {
13:         model: Quickshell.screens
14: 
15:         delegate: Component {
16:             Scope {
17:                 required property var modelData
18: 
19:                 // ── Bar ───────────────────────────────────────────────────────
20:                 TopBar { screen: modelData }
21: 
22:                 // ── Popup dismiss overlay ─────────────────────────────────────
23:                 PopupDismiss { screen: modelData }
24: 
25:                 // ── Toasts ────────────────────────────────────────────────────
26:                 NotificationToast { screen: modelData }
27: 
28:                 // ── Popups ────────────────────────────────────────────────────
29:                 // All popups are instantiated here and nowhere else.
30:                 // Add new popups to this list as they are built.
31: 
32:                 NotificationPanel   { screen: modelData }
33:                 SystemPopup         { screen: modelData }
34:                 VolumePopup         { screen: modelData }
35:                 NetworkPopup        { screen: modelData }
36:                 MediaPopup          { screen: modelData }
37:                 Launcher            { screen: modelData }
38:                 ClipboardPopup      { screen: modelData }
39:             }
40:         }
41:     }
42: 
43:     // ── Focus mode keybind (SUPER+Z) ──────────────────────────────────────────
44:     // Hyprland lua config bind:
45:     //   bind = SUPER, Z, global, quickshell:focusModeToggle
46:     GlobalShortcut {
47:         appid:       &quot;quickshell&quot;
48:         name:        &quot;focusModeToggle&quot;
49:         description: &quot;Toggle bar visibility in fullscreen&quot;
50:         onPressed:   ShellState.toggleManualOverride()
51:     }
52:     GlobalShortcut {
53:         appid:       &quot;quickshell&quot;
54:         name:        &quot;barHideToggle&quot;
55:         description: &quot;Toggle bar visibility anytime&quot;
56:         onPressed:   ShellState.toggleManualHide()
57:     }
58:     GlobalShortcut {
59:         appid:       &quot;quickshell&quot;
60:         name:        &quot;launcherToggle&quot;
61:         description: &quot;Toggle app launcher&quot;
62:         onPressed:   Popups.launcherOpen = !Popups.launcherOpen
63:     }
64:     GlobalShortcut {
65:         appid:       &quot;quickshell&quot;
66:         name:        &quot;clipboardToggle&quot;
67:         description: &quot;Toggle Clipboard Manager overlay&quot;
68:         onPressed:   Popups.clipboardOpen = !Popups.clipboardOpen
69:     }
70: }</file></files></repomix>