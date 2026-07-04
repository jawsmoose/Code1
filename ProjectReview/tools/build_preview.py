#!/usr/bin/env python3
"""
Render an HTML preview of the Project Review report from the same data that
drives the PBIP — one 1280x720 board per report page. This is a visual
approximation for layout review / sharing; the real dashboard is the PBIP.

Run:  python3 tools/build_preview.py   ->  preview/preview.html
"""

import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_pbip import (  # noqa: E402
    FIELDS, KEY_ACTIONS, MILESTONE_DEFS, NAVY, PROJECTS, STATUS_COLORS,
    WORKSTREAMS, milestone_rows, TL_X, TL_W, TL_Y, TL_H, ROW_B_XS, ROW_BC_W,
    px_for_pos,
)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MILES = {}
for pid, ws, sort, label, name, pos, rowy, status in milestone_rows():
    MILES.setdefault(pid, []).append((ws, label, name, pos, rowy, status))

FIELD_BY_COL = {f[0]: f for f in FIELDS}


def esc(s):
    return html.escape(str(s))


def card(x, y, w, h, title, value, vsize=10):
    return ('<div class="card" style="left:%dpx;top:%dpx;width:%dpx;height:%dpx">'
            '<div class="ct">%s</div><div class="cv" style="font-size:%dpx">%s</div></div>'
            % (x, y, w, h, esc(title), vsize + 3, esc(value)))


def bar(x, y, w, text, h=20, fs=9):
    return ('<div class="bar" style="left:%dpx;top:%dpx;width:%dpx;height:%dpx;'
            'font-size:%dpx;line-height:%dpx">%s</div>' % (x, y, w, h, fs, h, esc(text)))


def project_board(proj):
    pid = proj["ProjectID"]
    v = lambda col: proj[col]
    out = ['<div class="board">']

    out.append(card(8, 8, 170, 40, "REVIEW DATE", v("ReviewDate")))
    out.append(card(8, 52, 300, 52, "PROJECT", v("ProjectName"), vsize=15))
    leads = [("INTERCONNECTION", "LeadInterconnection"), ("HV ENGINEERING", "LeadHVEngineering"),
             ("SCADA / TELECOM", "LeadSCADATelecom"), ("HV O&M", "LeadHVOM"),
             ("ASSET MGMT", "LeadAssetMgmt")]
    for i, (t, c) in enumerate(leads):
        out.append(card(320 + i * 136, 8, 130, 48, t, v(c)))
    out.append('<div class="card sld" style="left:1004px;top:8px;width:268px;height:96px">'
               '<div class="ct">POI SUBSTATION DESIGN</div>'
               '<div class="cv ph">[ insert image / SLD ]</div></div>')

    row_b = [("PROJECT STATE", "ProjectState"), ("TO / UTILITY", "TOUtility"),
             ("ISO / RTO", "ISORTO"), ("OTB / E&P AGREEMENT", "OTBEPAgreement"),
             ("POI VOLTAGE", "POIVoltage"), ("POI TYPE", "POIType")]
    for x, (t, c) in zip(ROW_B_XS, row_b):
        out.append(card(x, 110, ROW_BC_W, 44, t, v(c)))
    row_c = [("SOLAR (MW AC / DC)", "Solar"), ("STORAGE (MW / MWH)", "Storage"),
             ("PGIA / GIA", "PGIAGIA"), ("COD", "COD"), ("EPC / HV", "EPCHV"),
             ("O&M PROVIDER", "OMProvider")]
    for x, (t, c) in zip(ROW_B_XS, row_c):
        out.append(card(x, 158, ROW_BC_W, 44, t, v(c)))
    out.append(card(1004, 110, 268, 44, "TOP GATING ITEM", v("TopGatingItem")))
    out.append(card(1004, 158, 268, 44, "TRANSMISSION SYSTEM NUs", v("TransmissionNUs")))

    out.append(bar(8, 212, 300, "UTILITY PROGRESS"))
    out.append(bar(316, 212, 560, "ENGINEERING  /  KEY DESIGN DETAILS"))
    out.append(bar(884, 212, 388, "STRATEGIC  /  PROJECT ATTRIBUTES"))
    util = [("POI ISD", "POIISD"), ("POI ISD STATUS", "POIISDStatus"),
            ("EST. IX COST", "EstIXCost"), ("IX COST STATUS", "IXCostStatus")]
    for i, (t, c) in enumerate(util):
        out.append(card(8 + (i % 2) * 154, 236 + (i // 2) * 48, 146, 44, t, v(c)))
    eng = [("SOLAR INVERTERS", "SolarInverters"), ("MPT", "MPT"),
           ("STORAGE / PCS", "StoragePCS"), ("GEN-TIE LENGTH", "GenTieLength"),
           ("REACTIVE POWER COMP", "ReactivePowerComp"), ("POWER PLANT CTRL", "PowerPlantCtrl")]
    for i, (t, c) in enumerate(eng):
        out.append(card(316 + (i % 3) * 188, 236 + (i // 3) * 48, 180, 44, t, v(c)))
    strat = [("SAFE HARBOR", "SafeHarbor"), ("OTHER", "OtherAttributes"),
             ("FUTURE EXPANSION — NEW APPS", "FutureExpansion"),
             ("OTB / E&P (DATES)", "OTBEPAgreement")]
    for i, (t, c) in enumerate(strat):
        out.append(card(884 + (i % 2) * 196, 236 + (i // 2) * 48, 188, 44, t, v(c)))

    # timeline
    out.append('<div class="tlt" style="left:8px;top:336px">CROSS-WORKSTREAM MILESTONE TIMELINE</div>')
    leg = "".join('<span style="color:%s">●</span> %s&nbsp;&nbsp;' % (c, esc(s))
                  for s, c in STATUS_COLORS.items())
    out.append('<div class="leg" style="left:400px;top:336px">%s</div>' % leg)
    phases = [("APP", 4), ("DEVELOPMENT", 15), ("GIA", 29), ("EPC", 37),
              ("CONSTRUCTION", 50), ("CMX", 63), ("COD", 73), ("COMMERCIAL OPS", 87)]
    for label, pos in phases:
        out.append('<div class="phase" style="left:%dpx;top:358px;width:104px">%s</div>'
                   % (int(px_for_pos(pos)) - 52, esc(label)))
    for i, ws in enumerate(WORKSTREAMS):
        rowy = 5 - i
        cy = TL_Y + TL_H * (6 - rowy) / 6.0
        out.append(bar(8, int(cy) - 14, 88, ws.upper(), h=30, fs=7))
        out.append('<div class="rowline" style="left:%dpx;top:%dpx;width:%dpx"></div>'
                   % (TL_X, int(cy), TL_W))
    out.append('<div class="plot" style="left:%dpx;top:%dpx;width:%dpx;height:%dpx"></div>'
               % (TL_X, TL_Y, TL_W, TL_H))
    for ws, label, name, pos, rowy, status in MILES[pid]:
        cx = px_for_pos(pos)
        cy = TL_Y + TL_H * (6 - rowy) / 6.0
        out.append('<div class="dot" title="%s — %s" style="left:%dpx;top:%dpx;'
                   'background:%s">%s</div>'
                   % (esc(name + " · " + status), esc(ws), int(cx) - 9, int(cy) - 9,
                      STATUS_COLORS[status], esc(label)))

    # key actions
    out.append(bar(976, 336, 296, "KEY ACTION ITEMS  /  NEXT STEPS"))
    rows = "".join('<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td></tr>'
                   % (i, esc(a), esc(o), esc(d))
                   for i, (a, o, d) in enumerate(KEY_ACTIONS[pid], start=1))
    out.append('<div class="tbl" style="left:976px;top:360px;width:296px;height:262px">'
               '<table><tr><th>#</th><th>Action item / decision needed</th>'
               '<th>Owner</th><th>Due</th></tr>%s</table></div>' % rows)

    # bottom strip
    strip_xs = [8, 200, 392, 584, 776]
    for x, ws in zip(strip_xs, WORKSTREAMS):
        out.append(bar(x, 630, 186, ws.upper(), h=16, fs=7))
        rws = "".join(
            '<tr style="color:%s"><td>%s</td><td>%s</td><td>%s</td></tr>'
            % (STATUS_COLORS[st], esc(lb), esc(nm), esc(st))
            for w2, lb, nm, _p, _r, st in MILES[pid] if w2 == ws)
        out.append('<div class="tbl small" style="left:%dpx;top:648px;width:186px;height:66px">'
                   '<table><tr><th>#</th><th>Milestone</th><th>Status</th></tr>%s</table></div>'
                   % (x, rws))
    out.append('</div>')
    return "".join(out)


def summary_board():
    out = ['<div class="board">']
    out.append('<div class="tlt big" style="left:8px;top:10px">TRANSMISSION &amp; GRID — '
               'PORTFOLIO SUMMARY</div>')
    out.append('<div class="leg" style="left:8px;top:46px;font-style:italic">Review date '
               '07/01/2026 · 5 active projects · milestone statuses are tracked on each '
               'project page</div>')
    out.append(bar(8, 74, 1264, "FOUNDATIONAL PROJECT INFO"))
    cols = [("Project", "ProjectName"), ("State", "ProjectState"),
            ("TO / Utility", "TOUtility"), ("ISO / RTO", "ISORTO"),
            ("Solar (MW AC / DC)", "Solar"), ("Storage (MW / MWh)", "Storage"),
            ("POI Voltage", "POIVoltage"), ("COD", "COD")]
    hdr = "".join("<th>%s</th>" % esc(t) for t, _ in cols)
    rows = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % esc(p[c]) for _, c in cols)
                   for p in PROJECTS if p["ProjectID"] != "P00")
    out.append('<div class="tbl med" style="left:8px;top:98px;width:1264px;height:200px">'
               '<table><tr>%s</tr>%s</table></div>' % (hdr, rows))
    out.append(bar(8, 320, 1264, "TOP GATING ITEMS"))
    rows = "".join('<tr><td>%s</td><td>%s</td><td>%s</td></tr>'
                   % (esc(p["ProjectName"]), esc(p["TopGatingItem"]), esc(p["COD"]))
                   for p in PROJECTS if p["ProjectID"] != "P00")
    out.append('<div class="tbl med" style="left:8px;top:344px;width:1264px;height:190px">'
               '<table><tr><th>Project</th><th>Top gating item (placeholder — maintained in '
               'projects.csv)</th><th>COD</th></tr>%s</table></div>' % rows)
    out.append('</div>')
    return "".join(out)


CSS = """
body{font-family:'Segoe UI',system-ui,sans-serif;background:#E8EAED;margin:0;padding:16px}
h2{font-size:14px;margin:18px 0 6px;color:#1F3252}
.board{position:relative;width:1280px;height:720px;background:#fff;
  box-shadow:0 1px 4px rgba(0,0,0,.25);overflow:hidden}
.card{position:absolute;background:#fff;border:1px solid #C9CDD4;border-radius:3px;
  padding:3px 6px;box-sizing:border-box;overflow:hidden}
.ct{font-size:8px;font-weight:600;color:#5F6368;letter-spacing:.02em}
.cv{color:#252423;line-height:1.15}
.ph{color:#8A8F98;font-style:italic;text-align:center;margin-top:14px}
.bar{position:absolute;background:#1F3252;color:#fff;font-weight:700;
  padding:0 6px;box-sizing:border-box;overflow:hidden;white-space:nowrap}
.tlt{position:absolute;font-size:12px;font-weight:700;color:#1F3252}
.tlt.big{font-size:20px}
.leg{position:absolute;font-size:10px;color:#3B3F46}
.phase{position:absolute;font-size:9px;font-weight:700;color:#1F3252;text-align:center}
.plot{position:absolute;border:1px solid #EDEFF2;box-sizing:border-box}
.rowline{position:absolute;border-top:1px dashed #D8DBE0}
.dot{position:absolute;width:18px;height:18px;border-radius:50%;color:#fff;
  font-size:7px;font-weight:700;line-height:18px;text-align:center;z-index:3;
  box-shadow:0 0 0 2px #fff}
.tbl{position:absolute;background:#fff;border:1px solid #C9CDD4;border-radius:3px;
  overflow:auto;box-sizing:border-box}
.tbl table{border-collapse:collapse;width:100%;font-size:8px}
.tbl.small table{font-size:7px}
.tbl.med table{font-size:12px}
.tbl th{background:#EDEFF2;color:#3B3F46;text-align:left;padding:2px 4px;
  border-bottom:1px solid #E4E6EA}
.tbl td{padding:2px 4px;border-bottom:1px solid #E4E6EA;vertical-align:top}
"""


def main():
    parts = ["<meta charset='utf-8'><title>Project Review — preview</title>",
             "<style>%s</style>" % CSS]
    parts.append("<h2>Template (P00 — no project info)</h2>")
    parts.append(project_board(PROJECTS[0]))
    for p in PROJECTS[1:]:
        parts.append("<h2>%s · %s</h2>" % (p["ProjectID"], esc(p["ProjectName"])))
        parts.append(project_board(p))
    parts.append("<h2>Portfolio Summary</h2>")
    parts.append(summary_board())
    outdir = os.path.join(ROOT, "preview")
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(outdir, "preview.html")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    print("wrote", path)


if __name__ == "__main__":
    main()
