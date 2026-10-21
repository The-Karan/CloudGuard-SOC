# Power BI build guide

This is a complete build pack; no native PBIX file is included or claimed. Build and save the report in Power BI Desktop after running the R pipeline.

## Import, model and theme

1. Run Rscript R/run_all.R from the repository root.
2. Import SecurityEvents.csv, Incidents.csv, R_Analytics.csv, Users.csv, CloudAssets.csv and DateTable.csv from data/processed.
3. Apply transformations in powerbi/POWER_QUERY_GUIDE.md.
4. Create relationships in powerbi/DATA_MODEL.md and mark DateTable as a date table.
5. Apply powerbi/CloudGuard_Dark_Theme.json under View > Themes > Browse for themes.
6. Add the measures from powerbi/DAX_Measures.dax. Format rate measures as percentages and duration measures as whole-number minutes.

Use the dark background #0B1220, panel #111827, border #263244, blue #60A5FA, red #EF4444, amber #F59E0B and green #22C55E. Add a footer: SIMULATED DATA · EDUCATIONAL DEMONSTRATION.

## Six report pages

| Page | Required visuals | Interactions |
|---|---|---|
| 1. Security Overview | Cards: Total Incidents, Critical + High, Open, Suspicious Events. Incident trend line, severity donut, category bar, latest incident table. | Date, Region, Severity slicers; category chart cross-filters the table; IncidentID drill-through. |
| 2. Incident Analysis | Incident-by-date stacked column, category bar, severity/status matrix, searchable incident register. | IncidentID drill-through field; conditional colour on RiskScore and Severity. |
| 3. Threat Detection & Anomalies | Suspicious events over time, RiskScore distribution, detection-category bar, repeated failure and suspicious source-IP bar, evidence table. | EventType/RiskBand/Region slicers; SourceIP tooltip. |
| 4. Identity & Access Security | Failed logins by UserName and SourceIP, privileged versus standard activity donut, denied/privileged evidence table. | User, Role, IsPrivileged slicers and UserID drill-through. |
| 5. Cloud Asset & Risk | Incidents by AssetName, average RiskScore by Region, criticality donut, service comparison, high-risk asset table. | Region/ServiceType/Criticality slicers and AssetID drill-through. |
| 6. Incident Response & R Analytics | Status counts, mean/median response/resolution cards, SLA cards, risk summaries, reasons, precision/recall cards. | Status/Severity filters; explicitly label evaluation as synthetic ground-truth. |

## Tooltips, drill-through and conditional formatting

Create an incident report-page tooltip with IncidentID, Severity, RiskScore, DetectionReason, EventCount, ResponseMinutes and SLAStatus. Add IncidentID as a drill-through field on page 2; show related SecurityEvents fields using the IncidentID relationship. Add an asset drill-through page or use page 5 with AssetID in the drill-through well.

Format RiskScore backgrounds: 75–100 red, 55–74 amber, 35–54 blue, below 35 slate. Format status: Open red, Investigating amber, Resolved green. Use font colour only when a background rule would make text hard to read.

## Slicer synchronization and reset

Synchronize DateTable[Date] and CloudAssets[Region] across all pages using View > Sync slicers. Keep Severity/Status scoped to relevant incident pages. Create a Reset filters bookmark with default slicer states and attach it to a clearly labeled button.

## Refresh

Run Rscript R/run_all.R, confirm validation passes, then select Refresh in Power BI. The web dashboard and this report read the same source contracts but are otherwise separate frontends.

