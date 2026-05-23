import QtQuick
import Quickshell.Io

QtObject {
    id: root

    signal loaded(var apps)

    property bool   loading: false
    property string _buf:    ""

    function reload() {
        _buf    = ""
        loading = true
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
            onRead: (line) => { root._buf += line }
        }

        onExited: {
            root.loading = false
            try {
                root.loaded(JSON.parse(root._buf))
            } catch(e) {
                root.loaded([])
            }
        }
    }
}
