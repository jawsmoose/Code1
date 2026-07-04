# Transmission & Grid — Project Review (Power BI)

A Power BI replica of the one-page "Project Review" dashboard (see the source
PDF layout). Everything on the report is **populated and maintained from
spreadsheet files** in [`data/`](data/) — no report editing needed for routine
updates.

| Deliverable | Where |
|---|---|
| Power BI project (open in Power BI Desktop) | [`Project Review.pbip`](Project%20Review.pbip) |
| Data spreadsheets (the single source of truth) | `data/projects.csv`, `data/milestones.csv`, `data/key_actions.csv` |
| Same data as one Excel workbook (convenience copy) | `data/ProjectData.xlsx` |
| Layout generator (rebuilds the PBIP deterministically) | `tools/build_pbip.py` |

## Report pages

1. **Template** — the project page with no project info (bound to placeholder
   row `P00`; every card shows its `[ … ]` placeholder and every circle is gray).
2. **P01–P05** — five populated individual project views:
   Sunport Ridge Solar + Storage (TX), Mesa Verde Solar (AZ), Prairie Sky
   Solar + Storage (IL), Cypress Bend Solar (GA), High Desert Hybrid (NV).
3. **Portfolio Summary** — all 5 projects, **no circle statuses**: a
   foundational-info table (8 attributes: Project, State, TO/Utility, ISO/RTO,
   Solar, Storage, POI Voltage, COD) plus a *Top Gating Items* placeholder
   table.

## Quick start

1. Open `Project Review.pbip` in **Power BI Desktop** (any 2024+ release).
2. When prompted (or via *Transform data → Edit parameters*), set the
   **`DataFolder`** parameter to the full path of this repo's `data` folder,
   **with a trailing slash/backslash**, e.g. `C:\repos\Code1\ProjectReview\data\`.
3. **Refresh**. All 7 pages populate from the CSVs.

## How the page is driven by the spreadsheet

### Top half — project attributes (`data/projects.csv`)

One row per project (`P00` is the template placeholder row). Each column feeds
one labeled card: review date, project name, the five responsible-team leads,
state / TO / ISO / OTB / POI voltage / POI type, solar & storage capacity,
PGIA/GIA, COD, EPC and O&M provider, utility progress (POI ISD + status, IX
cost + status), engineering details (inverters, MPT, PCS, gen-tie, reactive
power, plant controller) and strategic attributes (safe harbor, future
expansion, NUs). Edit a cell → refresh → the card updates.

### Bottom half — milestone circles (`data/milestones.csv`)

One row per circle (32 milestones × each project). Two columns control the
graphic, exactly as requested:

* **`TimelinePos` (0–100) — moves the circle** left/right along the lifecycle:

  | Phase | APP | DEVELOPMENT | GIA | EPC | CONSTRUCTION | CMX | COD | COMMERCIAL OPS |
  |---|---|---|---|---|---|---|---|---|
  | Position | 0–8 | 8–26 | 26–33 | 33–41 | 41–60 | 60–68 | 68–78 | 78–100 |

* **`Status` — recolors the circle** from the responsible team's input. Exact
  values (case-sensitive): `On Track` (green ●), `At Risk` (orange ●),
  `Delayed` (red ●), `Not Started` (gray ●). The palette is color-blind
  validated, and status is never color-alone: each circle carries its
  milestone label, the tooltip shows the status text, and the tables under
  the timeline list every milestone with its status.

`Workstream`, `Label`, `MilestoneName`, `RowY` (timeline row: 5 = Commercial
Analytics … 1 = HV O&M) and `SortOrder` define the circle itself. Note:
Commercial Analytics milestones are labeled `C1–C6` and Interconnection
`I1–I6` (the source page reuses 1–6 for both rows; labels must be unique).

### Key actions (`data/key_actions.csv`)

Five "action item / decision needed" rows per project (item, owner, due),
shown in the panel on the right of each project page.

`ProjectData.xlsx` mirrors the three CSVs as tabs for anyone who prefers
maintaining the data in Excel — copy the tabs back over the CSVs (or repoint
the three Power Query sources at the workbook) to use it as the source.

## Adding a sixth project

1. Add a row to `projects.csv` (e.g. `P06`), 32 milestone rows to
   `milestones.csv`, and 5 rows to `key_actions.csv`.
2. In Power BI Desktop, right-click any project page → *Duplicate page*, then
   change the page-level filter from e.g. `ProjectID is P01` to `P06`.

## Regenerating the report layout

The PBIP (report layout + semantic model) and the CSVs are emitted by one
deterministic script — layout changes belong there, data changes in the CSVs:

```bash
cd ProjectReview && python3 tools/build_pbip.py
```
