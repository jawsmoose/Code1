# Solar & Storage Interconnection Tracker (Microsoft Access)

A complete Microsoft Access application for tracking **generator (solar / solar + storage / standalone storage) and load-only interconnection projects**. It combines:

- **Spreadsheet import** — 15 fields per project imported (and re-importable at any time) from a periodically updated Excel workbook, keyed on `ProjectCode` so updates never destroy your form-entered data.
- **Form-based data entry** — 12 additional fields per project entered through a modern flat-design form: free-form text, drop-down selections, a date picker, a checkbox, and a **multi-select technology list**.
- **Reports** — a landscape portfolio report grouped by ISO/RTO with subtotals and portfolio totals, plus a one-page pipeline summary by queue status.
- **One-click CSV / XLSX export** — a flat, Power BI-ready extract of everything (imported + form-entered + technologies).
- **Real example data** — 10 real utility-scale solar/storage projects and 4 real load-only interconnection applications (AI data centers), compiled from public sources (see [Data sources](#data-sources)).

> Access only runs on Windows, so this repo ships the application as **source + data + a one-click build script**. The build generates the entire `.accdb` — tables, relationships, queries, forms (with code-behind), reports, and data — in about 30 seconds.

## Repo layout

```
data/InterconnectionProjects.xlsx   The periodically updated import source (14 example projects)
src/modBuild_Main.bas               One-step build entry point: BuildSolarStorageApp
src/modTables.bas                   Tables, lookups, relationships, queries
src/modImport.bas                   Spreadsheet import / refresh (upsert on ProjectCode)
src/modSampleData.bas               Sample form-side records for the 14 projects
src/modForms.bas                    Dashboard + data-entry form (modern flat styling)
src/modReports.bas                  Portfolio + pipeline reports
src/modExport.bas                   CSV / XLSX export for Power BI
src/modUtil.bas                     Shared helpers and theme colors
scripts/Build-AccessApp.ps1         One-click automated build (requires Access on Windows)
```

## Quick start

### Option A — one-click build (recommended)

On a Windows machine with Microsoft Access (Microsoft 365 or 2016+):

```powershell
git clone <this repo>
cd Code1
powershell -ExecutionPolicy Bypass -File scripts\Build-AccessApp.ps1
```

This creates `SolarStorageTracker.accdb` at the repo root, imports all modules, builds every object, imports the spreadsheet, and loads the sample detail records. Open the database — the dashboard appears automatically.

> If Access shows a security bar when you first open the built database, click **Enable Content** (or add the folder as a Trusted Location under File > Options > Trust Center).

### Option B — manual build

1. Create a new blank database in Access (e.g. `SolarStorageTracker.accdb`) **in the repo root** (so it can find `data\InterconnectionProjects.xlsx`).
2. Press `Alt+F11` to open the VBA editor, then **File > Import File…** and import all eight `.bas` files from `src\`.
3. Press `Ctrl+G` (Immediate window), type `BuildSolarStorageApp` and press Enter.

## Using the application

**Dashboard** (`frmDashboard`, opens on startup):

| Button | What it does |
|---|---|
| Enter / Edit Project Details | Opens the data-entry form |
| Refresh Import from Spreadsheet | Re-imports the Excel workbook (updates existing projects, adds new ones) |
| Portfolio Report (by ISO/RTO) | Landscape report of the most critical fields with subtotals and totals |
| Pipeline Summary Report | One-page rollup of counts and MW/MWh by queue status |
| Export CSV (Power BI ready) | Writes a timestamped CSV to an `Exports\` folder beside the database |
| Export Excel (XLSX) | Same extract as a formatted-type XLSX |

**Data entry form** (`frmProjectDetails`) uses a modern stacked layout (caption-above-field, flat colored buttons, Segoe UI):

- **Free-form**: project manager, estimated capex, next milestone, notes (multi-line).
- **Drop-downs**: project (from the imported list), study phase, land control, permitting status, interconnection voltage, risk level.
- **Multi-select**: technologies list (single-axis trackers, LFP storage, grid-forming inverters, agrivoltaics, BYOG on-site generation, controllable load resource, …). Selections save instantly to a proper many-to-many junction table.
- A duplicate-project guard, date picker on milestone date, and record navigation buttons are built in.

**Updating the spreadsheet**: edit `InterconnectionProjects.xlsx` (sheet `Projects`) — add rows or revise capacity/status/COD — then click **Refresh Import**. Rows are matched on `ProjectCode`: existing projects are updated in place, new codes are appended, and all your form-entered details and technology selections are preserved. The chosen file path is remembered in `tblSettings`.

**Power BI**: point Power BI Desktop at either the exported CSV/XLSX (`Get Data > Text/CSV` or `Excel`) or directly at the `.accdb` (`Get Data > More > Access database`) and load `qryProjectMaster`.

## Data model

| Table | Populated by | Contents |
|---|---|---|
| `tblProjects` | Spreadsheet import (15 fields) | Code, name, developer, type, ISO/RTO, state, county, solar MWac, storage MW, storage MWh, load MW, queue number, queue status, COD, offtaker |
| `tblProjectDetails` | Form (12 fields) | PM, study phase, land control, permitting, voltage, risk, capex, next milestone + date, community-benefit flag, notes |
| `tblProjectTechnologies` | Form (multi-select) | Many-to-many project ↔ technology |
| `tblTechnologies`, `tlu*` | Build script | Drop-down / list choices |
| `qryProjectMaster` | — | Flat join of everything (report + export source) |
| `qryPipelineSummary` | — | Aggregates by queue status |

## Example projects included

Ten real generation projects — including Intersect Power's Darden Clean Energy (1,150 MW / 4,600 MWh, the largest permitted solar+storage in CAISO), Tehuacana Creek 1 (EIA's largest expected 2026 solar addition in ERCOT), Terra-Gen's Edwards & Sanborn, Gemini (NV), Eland 1 & 2, Bellefield 2, Sierra Estrella and Nova Power Bank standalone storage, Mammoth Solar, and Oak Run — plus four real **load-only** interconnection applications (Stargate Abilene, Meta Hyperion, xAI Colossus, and Vantage's Frontier campus in the ERCOT large-load queue).

**Important**: project names, developers, locations, and approximate capacities are real and compiled from the public sources below (retrieved July 2026). Queue numbers, PM names, capex figures, milestones, and risk ratings are **illustrative placeholders**. Verify everything against primary sources (EIA 860M, ISO queue extracts) before any business use.

### Data sources

- [EIA — New U.S. electric generating capacity expected to reach a record high in 2026](https://www.eia.gov/todayinenergy/detail.php?id=67205)
- [pv magazine USA — Solar and storage to lead record-breaking 86 GW of new U.S. capacity in 2026](https://pv-magazine-usa.com/2026/02/25/solar-and-storage-to-lead-record-breaking-86-gw-of-new-u-s-capacity-in-2026/)
- [ESS News — 24.3 GW of new battery storage to come online in 2026](https://www.ess-news.com/2026/02/26/new-us-battery-capacity-in-2026-24-3-gw-of-new-battery-storage-to-come-online/)
- [SEIA — Major Solar Projects List](https://seia.org/research-resources/major-solar-projects-list/)
- [LBNL — Utility-Scale Solar Data Update](https://emp.lbl.gov/utility-scale-solar)
- [ERCOT — Large Load Integration](https://www.ercot.com/services/rq/large-load-integration)
- [Latitude Media — ERCOT's large load queue has nearly quadrupled in a single year](https://www.latitudemedia.com/news/ercots-large-load-queue-has-nearly-quadrupled-in-a-single-year/)
- [Utility Dive — ERCOT's large load queue jumped almost 300% last year](https://www.utilitydive.com/news/ercots-large-load-queue-jumped-almost-300-last-year-official/808820/)

## Requirements

- Microsoft Access (Microsoft 365, 2019, or 2016) on Windows — for both the build and daily use.
- No third-party dependencies; the VBA uses only DAO and the Access object model.
