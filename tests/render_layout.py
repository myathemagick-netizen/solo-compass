"""Render the actual UI.lua widget layout with sample API data (not a WoW screenshot)."""
from pathlib import Path
import os
import sys
from lupa.lua51 import LuaRuntime
from PIL import Image, ImageDraw, ImageFont

os.chdir(Path(__file__).resolve().parents[1])
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(Path('tests/run.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
SoloCompassCharDB.minutes = 30
SoloCompassCharDB.interests = { quests=true, mounts=true, pets=true, toys=true, raids=true, delves=true }
SoloCompass.skipped = {}; SoloCompass.rotation = 0
C_PetJournal.GetPetInfoBySpeciesID = function(id)
    return "Mechanical Squirrel", "pet-icon", 1, 1, "Crafted by Engineers. Check the Auction House for a crafted pet.", "", false, true, true, false, true
end
SoloCompass:RefreshSuggestions()
for _, s in ipairs(SoloCompass.candidates) do
    if s.id == "mount:32458" then SoloCompass:SetGoal(s); break end
end
SoloCompass.UI:Show(); SoloCompass.UI.preferences:Hide()
''')
records = {}
for w in lua.globals().TEST_FRAMES.values():
    record = {k: w[k] for k in ('id', 'kind', 'name', 'shown', 'width', 'height', 'template', 'textValue', 'checked', 'texture')}
    record['parent'] = w.parent.id if w.parent else None
    for key in ('color', 'background', 'textColor'):
        record[key] = list(w[key].values()) if w[key] else None
    record['points'] = []
    for point in w.points.values():
        values = list(point.values())
        record['points'].append([v.id if lua.eval('type')(v) == 'table' else v for v in values])
    records[record['id']] = record
root = next(r for r in records.values() if r['name'] == 'SoloCompassFrame')
anchors = {'TOPLEFT': (0,0), 'TOP': (.5,0), 'TOPRIGHT': (1,0), 'LEFT': (0,.5),
           'CENTER': (.5,.5), 'RIGHT': (1,.5), 'BOTTOMLEFT': (0,1), 'BOTTOM': (.5,1), 'BOTTOMRIGHT': (1,1)}
positions = {root['id']: (30, 35)}
def position(r):
    if r['id'] in positions:
        return positions[r['id']]
    parent = records.get(r['parent'])
    if not parent:
        return (0,0)
    x, y = position(parent)
    if r['points']:
        p = r['points'][0]
        anchor = p[0]
        if len(p) == 3:
            target, relative, dx, dy = parent, anchor, p[1], p[2]
        elif len(p) == 5:
            target, relative, dx, dy = records[p[1]], p[2], p[3], p[4]
        else:
            target, relative, dx, dy = parent, anchor, 0, 0
        tx, ty = position(target)
        a, b = anchors[anchor], anchors[relative]
        x = tx + target['width'] * b[0] + dx - r['width'] * a[0]
        y = ty + target['height'] * b[1] - dy - r['height'] * a[1]
        if r['kind'] == 'FontString' and anchor == 'CENTER':
            r['width'] = parent['width']; x = tx
    positions[r['id']] = (x,y)
    return (x,y)
def visible(r):
    if r['shown'] is False:
        return False
    if r['id'] == root['id']:
        return True
    return bool(r['parent']) and visible(records[r['parent']])
def color(rgb, default):
    return tuple(int(c*255) for c in (rgb or default)[:3])
font_dir = Path('C:/Windows/Fonts')
def font(size, bold=False):
    return ImageFont.truetype(str(font_dir / ('segoeuib.ttf' if bold else 'segoeui.ttf')), size)
scale = 2
img = Image.new('RGB', (860*scale, 710*scale), '#111b23')
draw = ImageDraw.Draw(img)
draw.text((60,12), 'SOLO COMPASS / layout preview with sample data', font=font(21), fill='#9aaab7')
for r in records.values():
    if not visible(r):
        continue
    x,y = position(r); w,h = r['width'],r['height']
    box = (int(x*scale), int(y*scale), int((x+w)*scale), int((y+h)*scale))
    if r['background']:
        draw.rectangle(box, fill=color(r['background'], [0.08,.11,.14]), outline='#344852', width=2)
    elif r['kind'] == 'CheckButton':
        cx,cy = int((x+6)*scale),int((y+5)*scale)
        draw.rectangle((cx,cy,cx+16*scale,cy+16*scale), fill='#243a43', outline='#4a6470', width=2)
        if r['checked']:
            draw.line((cx+3*scale,cy+8*scale,cx+7*scale,cy+12*scale,cx+13*scale,cy+4*scale), fill='#dcc08a', width=3)
    elif r['kind'] == 'Texture' and r['texture']:
        draw.rectangle(box, fill='#254c52', outline='#567a7c', width=2)
        mx,my=int((x+w/2)*scale),int((y+h/2)*scale)
        draw.polygon([(mx,my-12*scale),(mx+7*scale,my),(mx,my+12*scale),(mx-7*scale,my)], outline='#e8bd69')
    elif r['kind'] == 'Texture' and r['color']:
        draw.rectangle(box, fill=color(r['color'], [0.3,.6,.6]))
    if r['kind'] != 'FontString' or not r['textValue']:
        continue
    text = str(r['textValue'])
    template = r['template'] or ''
    size = 20 if 'Large' in template else 11 if 'Small' in template else 13
    ft = font(size*scale, 'Large' in template or 'Normal' in template)
    fill = color(r['textColor'], [.92,.94,.95])
    centered = r['points'] and r['points'][0][0] == 'CENTER'
    lines = []
    for paragraph in text.split('\n'):
        line = ''
        for word in paragraph.split():
            candidate = (line + ' ' + word).strip()
            if draw.textlength(candidate, font=ft) > w*scale and line:
                lines.append(line); line=word
            else:
                line=candidate
        lines.append(line)
    if h <= 27 and len(lines) > max(1, int(h/(size+1))):
        lines=lines[:max(1,int(h/(size+1)))]; lines[-1]=lines[-1].rstrip(' .')+'…'
    for index,line in enumerate(lines):
        lx=x*scale + ((w*scale - draw.textlength(line,font=ft))/2 if centered else 0)
        draw.text((int(lx),int(y*scale+index*(size+3)*scale)),line,font=ft,fill=fill)
draw.text((60,1340), 'Constructed from UI.lua. Icons and fonts are approximations; verify in WoW before release.', font=font(20), fill='#9aaab7')
out = Path(sys.argv[1] if len(sys.argv)>1 else '../solo-compass-preview.png').resolve()
img.save(out)
print(out)
