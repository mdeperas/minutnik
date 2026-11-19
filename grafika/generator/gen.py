import re, json, os
TU = os.path.dirname(os.path.abspath(__file__))
K = os.path.join(TU, '..', 'ryciny')
SRC = os.path.join(TU, 'zrodla')

D = '#17181c'
def paths(f):
    s = open(f'{SRC}/{f}.svg').read()
    return re.findall(r'<path[^>]*/>', s)
def dof(p): return re.search(r' d="([^"]*)"', p).group(1)
def bbox(d):
    pts = [(int(a), int(b)) for a, b in re.findall(r'(-?\d+),(-?\d+)', d)]
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)

def hl(d, stan, sw):
    if stan == 'n':
        return f'<path class="wyroznienie" fill="currentColor" stroke="{D}" stroke-width="{sw}" stroke-linejoin="round" d="{d}"/>'
    return f'<path class="wyroznienie" fill="currentColor" fill-opacity="0.5" stroke="{D}" stroke-width="{sw}" stroke-linejoin="round" d="{d}"/>'

def g(content, stroke=10, op=1):
    return f'<g class="wyroznienie" fill="none" stroke="currentColor" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round" opacity="{op}">{content}</g>'

def napiecie_kreski(x, y, strona, dl=60, w=12):
    s = -1 if strona == 'l' else 1
    return g(f'<path d="M{x},{y-50}l{s*dl},{-dl*0.6}M{x+s*10},{y}l{s*dl},0M{x},{y+50}l{s*dl},{dl*0.6}"/>', w)

def falka(x, y, w=12, n=3, a=22):
    seg = ''.join(f'q{a},{-a} {a*2},0 ' if i % 2 == 0 else f'q{a},{a} {a*2},0 ' for i in range(n))
    return g(f'<path d="M{x},{y}{seg}"/>', w, 0.9)

def strzalka(x, y, dl=110, w=12, w_gore=False):
    if w_gore:
        return g(f'<path d="M{x},{y}l0,{-dl}m-30,32l30,-32l30,32"/>', w)
    return g(f'<path d="M{x},{y}l0,{dl}m-30,-32l30,32l30,-32"/>', w, 0.9)

def svg(vb, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" overflow="hidden" width="100" height="100">{body}</svg>'

def wstawka(x, y, s, content):
    return f'<g transform="translate({x},{y}) scale({s})">{content}</g>'

TLO_WST = '#24262c'
def ramka(): return f'<rect x="0" y="0" width="300" height="300" rx="46" fill="{TLO_WST}"/>'

def piesc():
    return (ramka() + f'<rect x="72" y="70" width="156" height="128" rx="38" fill="currentColor" class="wyroznienie"/>'
            f'<path d="M111,76v58M150,74v62M189,76v58" stroke="{D}" stroke-width="9" stroke-linecap="round"/>'
            f'<path d="M84,168Q150,146 214,166" stroke="{D}" stroke-width="9" fill="none" stroke-linecap="round"/>'
            f'<rect x="104" y="190" width="92" height="80" rx="14" fill="currentColor" class="wyroznienie"/>'
            + g('<path d="M58,92l-36,-22M54,134h-40M58,176l-36,22M242,92l36,-22M246,134h40M242,176l36,22"/>', 11))

def dlon():
    palce = [((116,160),(94,62)), ((138,150),(130,42)), ((162,150),(170,44)), ((184,160),(206,70))]
    p = ''.join(f'M{a[0]},{a[1]}L{b[0]},{b[1]}' for a, b in palce) + 'M102,198L50,160'
    return (ramka() + g(f'<path d="{p}" stroke-width="30"/>', 30, 0.55)
            + f'<ellipse class="wyroznienie" cx="150" cy="196" rx="58" ry="54" fill="currentColor" opacity="0.55"/>'
            + f'<rect class="wyroznienie" x="118" y="236" width="64" height="50" fill="currentColor" opacity="0.55"/>'
            + falka(214, 262, 10, 2, 16))

def ramie_zgiete():
    return (ramka() + g('<path d="M36,236H170" stroke-width="58"/><path d="M186,238L208,104" stroke-width="48"/>', 48)
            + '<circle class="wyroznienie" cx="214" cy="78" r="40" fill="currentColor"/>'
            + f'<path d="M200,62v32M222,60v34" stroke="{D}" stroke-width="7" stroke-linecap="round"/>'
            + '<ellipse class="wyroznienie" cx="112" cy="198" rx="62" ry="46" fill="currentColor"/>'
            + f'<path d="M60,232Q112,214 166,230" stroke="{D}" stroke-width="7" fill="none"/>'
            + g('<path d="M78,132l-12,-34M114,124v-38M150,132l14,-34"/>', 11))

def ramie_opuszczone():
    return (ramka() + g('<path d="M118,26L122,210" stroke-width="52"/>', 52, 0.55)
            + g('<path d="M108,228L102,280M122,232L122,286M136,228L144,280"/>', 16, 0.55)
            + strzalka(222, 90, 120, 11))

def barki(stan):
    if stan == 'n':
        sh = 'M26,286Q30,150 108,150L192,150Q270,150 274,286Z'
        ex = g('<path d="M44,124v-70m-24,24l24,-24l24,24M256,124v-70m-24,24l24,-24l24,24"/>', 11)
        op = 1
    else:
        sh = 'M16,296Q22,206 104,200L196,200Q278,206 284,296Z'
        ex = strzalka(40, 70, 90, 10) + strzalka(260, 70, 90, 10)
        op = 0.55
    return (ramka() + f'<rect x="128" y="120" width="44" height="60" fill="#4a4e58"/><circle cx="150" cy="92" r="52" fill="#4a4e58"/>'
            + f'<path class="wyroznienie" d="{sh}" fill="currentColor" opacity="{op}"/>' + ex)

def tulow(nazwa, stan):
    p = paths(nazwa)
    base, h = p[0], dof(p[-1])
    x0, y0, x1, y1 = bbox(h)
    cy = (y0 + y1) // 2
    out = base + hl(h, stan, 7)
    W = {'przedramiona': (piesc, dlon), 'gorne-ramiona': (ramie_zgiete, ramie_opuszczone),
         'ramiona': (ramie_zgiete, ramie_opuszczone)}
    if nazwa in W:
        out += wstawka(690, 10, 1.0, W[nazwa][0 if stan == 'n' else 1]())
    elif nazwa == 'barki':
        out += wstawka(690, 10, 1.0, barki(stan))
    if stan == 'n':
        if nazwa == 'barki':
            out += g(f'<path d="M{x0+20},{y0-20}v-90m-26,30l26,-30l26,30"/>', 13)
        elif nazwa == 'brzuch':
            out += g(f'<path d="M{x0-130},{cy}h90m-32,-30l32,30l-32,30M{x1+130},{cy}h-90m32,-30l-32,30l32,30"/>', 13)
        elif nazwa == 'klatka-piersiowa':
            out += g(f'<path d="M{x0-30},{cy}h-110m32,-30l-32,30l32,30M{x1+30},{cy}h110m-32,-30l32,30l-32,30"/>', 13)
        else:
            out += napiecie_kreski(x0 - 25, cy, 'l') + napiecie_kreski(x1 + 25, cy, 'p')
    else:
        if nazwa == 'barki':
            out += strzalka(x0 + 10, y0 - 130, 90)
        else:
            out += falka(x0 - 150, cy - 20, 12, 2, 24) + falka(x1 + 50, cy - 20, 12, 2, 24)
    return svg('0 0 1000 1000', out)

def stopa(cx, top, strona, stan):
    return f'<g transform="translate({cx} {top}) scale({2.1 if stan == "n" else 1.6}) translate({-cx} {-top})">' + _stopa(cx, top, strona, stan) + '</g>'
def _stopa(cx, top, strona, stan):
    s = -1 if strona == 'l' else 1
    if stan == 'n':
        d = (f'M{cx-30},{top}L{cx+30},{top}L{cx+s*8+34},{top+56}'
             f'Q{cx+s*8},{top+30} {cx+s*8-34},{top+56}Z')
        palce = ''.join(f'<ellipse cx="{cx+s*8+dx}" cy="{top+36}" rx="9" ry="16" fill="#5a5f6b" stroke="{D}" stroke-width="5"/>' for dx in (-24,-8,8,24))
        return f'<path d="{d}" fill="#4a4e58" stroke="{D}" stroke-width="7" stroke-linejoin="round"/>' + palce
    rot = s * 22
    d = (f'M{cx-28},{top}L{cx+28},{top}Q{cx+44},{top+70} {cx+40},{top+100}'
         f'Q{cx},{top+118} {cx-40},{top+100}Q{cx-44},{top+70} {cx-28},{top}Z')
    palce = ''.join(f'<ellipse cx="{cx+dx}" cy="{top+108}" rx="10" ry="13" fill="#4a4e58" stroke="{D}" stroke-width="5"/>' for dx in (-30,-12,6,22,36))
    return f'<g transform="rotate({rot} {cx} {top})"><path d="{d}" fill="#4a4e58" stroke="{D}" stroke-width="7" stroke-linejoin="round"/>{palce}</g>'

def nogi(nazwa, stan):
    p = paths(nazwa)
    base, h = p[0], dof(p[-1])
    x0, y0, x1, y1 = bbox(h)
    cy = (y0 + y1) // 2
    out = stopa(398, 940, 'l', stan) + stopa(602, 940, 'p', stan) + base + hl(h, stan, 7)
    if stan == 'n':
        out += napiecie_kreski(x0 - 25, cy, 'l') + napiecie_kreski(x1 + 25, cy, 'p')
        if nazwa in ('podudzia', 'nogi'):
            out += g('<path d="M300,1050v-80m-26,30l26,-30l26,30M700,1050v-80m-26,30l26,-30l26,30"/>', 13)
    else:
        out += falka(x0 - 150, cy - 20, 12, 2, 24) + falka(x1 + 50, cy - 20, 12, 2, 24)
    return svg('-80 0 1160 1160', out)

def glowa(nazwa, stan):
    p = paths(nazwa)
    base, h = p[0], dof(p[-1])
    bd = dof(base)
    i = bd.find('ZM728,349Q')
    wlosy = bd[i+1:].split('Z')[0] + 'Z' if i >= 0 else ''
    sw = 10
    cien = (f'<path d="{wlosy}" fill="#363942"/>'
            '<path d="M330,520Q340,600 400,650Q360,580 350,510Z" fill="#3e414a"/>'
            '<path d="M670,520Q660,600 600,650Q640,580 650,510Z" fill="#3e414a"/>'
            '<path d="M500,462Q478,520 476,548Q490,560 500,558Z" fill="#3e414a"/>'
            '<path d="M300,380Q285,430 305,470M700,380Q715,430 695,470" fill="none" stroke="#3a3d45" stroke-width="10" stroke-linecap="round"/>')
    F = '#25272d'
    def l(d, w=14, c=F): return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
    oczy_otw = f'<path fill="{F}" d="M384,486Q424,462 464,486Q424,506 384,486ZM536,486Q576,462 616,486Q576,506 536,486Z"/>'
    oczy_zam = l('M386,484Q424,504 462,484M538,484Q576,504 614,484', 11)
    brwi = l('M384,430Q424,410 464,430M536,430Q576,410 616,430')
    brwi_luzne = l('M382,436Q424,420 466,434M534,434Q576,420 618,436', 12)
    nos = l('M500,462L500,542Q484,554 500,558', 12) + l('M470,556Q485,566 500,560Q515,566 530,556', 10)
    usta = l('M446,624Q500,640 554,624', 13) + l('M470,650Q500,660 530,650', 8, '#3e414a')
    usta_luz = l('M450,626Q500,644 550,626', 12)
    feat = oczy_zam + brwi_luzne + nos + usta_luz
    extra = ''
    hlp = hl(h, stan, sw)
    T = stan == 'n'
    if nazwa in ('czolo', 'gorne-czolo'):
        if T:
            feat = oczy_otw + l('M380,410Q424,370 468,404M532,404Q576,370 620,410', 16) + nos + usta
            extra = l('M380,300Q440,284 500,300T620,300M392,340Q446,324 500,340T608,340M410,262Q456,248 500,262T590,262', 12, D)
            if nazwa == 'czolo':
                extra += l('M486,350L492,400M514,350L508,400', 10, D)
    elif nazwa == 'dolne-czolo':
        if T:
            feat = (l('M372,420L470,456M628,420L530,456', 18) + l('M392,486Q424,476 456,486M544,486Q576,476 608,486', 12)
                    + nos + l('M478,500L470,520M522,500L530,520', 8) + usta)
            extra = l('M488,360L494,412M512,360L506,412', 11, D)
    elif nazwa == 'oczy':
        if T:
            feat = (l('M380,448Q424,464 466,456M534,456Q576,464 620,448', 16)
                    + l('M380,480L462,490L384,500M620,480L538,490L616,500', 13) + nos + usta)
            extra = (l('M300,470l38,8M296,496l40,0M300,522l38,-8M700,470l-38,8M704,496l-40,0M700,522l-38,-8', 11, '#3a3d45'))
            extra += napiecie_kreski(265, 490, 'l', 45, 11) + napiecie_kreski(735, 490, 'p', 45, 11)
        else:
            feat = oczy_zam + brwi_luzne + nos + usta_luz
            extra = falka(420, 200, 10, 4, 20)
    elif nazwa == 'usta-i-szczeka':
        if T:
            zeby = (f'<rect x="430" y="602" width="140" height="44" rx="14" fill="#d7dae0" stroke="{F}" stroke-width="9"/>'
                    + l('M430,624H570M465,604V644M500,604V644M535,604V644', 5, '#8a8e98'))
            feat = oczy_otw + brwi + nos + zeby
            extra = napiecie_kreski(300, 600, 'l', 50, 11) + napiecie_kreski(700, 600, 'p', 50, 11)
        else:
            feat = oczy_zam + brwi_luzne + nos + f'<ellipse cx="500" cy="634" rx="34" ry="18" fill="{F}"/>'
            extra = strzalka(500, 740, 90, 12)
    elif nazwa == 'szyja':
        if T:
            feat = l('M386,500Q424,486 462,500M538,500Q576,486 614,500', 11) + brwi + nos + usta
            extra = napiecie_kreski(330, 800, 'l', 50, 11) + napiecie_kreski(670, 800, 'p', 50, 11) + strzalka(800, 620, 110, 12)
    if not T and not extra:
        extra = falka(420, 170 if 'czolo' in nazwa else 900, 10, 4, 20)
    if not T and nazwa != 'szyja':
        pass
    return svg('0 0 1000 1000' if nazwa == 'szyja' else '120 50 760 760', base + cien + hlp + feat + extra)

TUL = ['przedramiona', 'gorne-ramiona', 'ramiona', 'brzuch', 'klatka-piersiowa', 'barki']
NOG = ['podudzia', 'uda', 'nogi']
GL = ['czolo', 'dolne-czolo', 'gorne-czolo', 'oczy', 'usta-i-szczeka', 'szyja']
for n in TUL + NOG + GL:
    for stan, suf in (('n', 'napiecie'), ('r', 'rozluznienie')):
        f = tulow if n in TUL else nogi if n in NOG else glowa
        open(f'{K}/{n}-{suf}.svg', 'w').write(f(n, stan))

mapa = json.load(open(f'{K}/mapa.json'))
nowa = {k: {'napiecie': v.replace('.svg', '-napiecie.svg'), 'rozluznienie': v.replace('.svg', '-rozluznienie.svg')} if isinstance(v, str) else v for k, v in mapa.items()}
json.dump(nowa, open(f'{K}/mapa.json', 'w'), ensure_ascii=False, indent=2)

h = ['<html><meta charset=utf-8><body style="background:#17181c;color:#ddd;font:14px -apple-system,sans-serif;margin:16px">',
     '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px">']
for k, v in nowa.items():
    h.append(f'<div style="background:#1f2126;border-radius:16px;padding:10px"><div style="margin-bottom:4px">{k}</div><div style="display:flex;gap:10px">')
    for stan, kol, pod in (('napiecie', 'hsl(190,80%,64%)', 'Napięcie'), ('rozluznienie', '#8fbfa3', 'Rozluźnienie')):
        s = open(f'{K}/{v[stan]}').read().replace('width="100" height="100"', 'width="170" height="170"')
        h.append(f'<div style="color:{kol};text-align:center">{s}<div style="font-size:12px;opacity:.7">{pod}</div></div>')
    h.append('</div></div>')
h.append('</div></body></html>')
open('/tmp/minutnik-ryciny.html', 'w').write(''.join(h))
