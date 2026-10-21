# CloudGuard SOC Power BI data model

Import the six CSV files in data/processed. Set all identifiers to Text. The web dashboard and Power BI are separate frontends over these same CSV contracts.

## Relationships

Use single-direction filters from dimensions to facts.

| From (one) | To (many) | Active | Purpose |
|---|---|---:|---|
| DateTable[Date] | SecurityEvents[EventDate] | Yes | Event trends |
| DateTable[Date] | Incidents[IncidentDate] | Yes | Incident trends |
| Users[UserID] | SecurityEvents[UserID] | Yes | Identity filtering |
| Users[UserID] | Incidents[UserID] | Yes | Incident ownership context |
| CloudAssets[AssetID] | SecurityEvents[AssetID] | Yes | Asset, region and service filtering |
| CloudAssets[AssetID] | Incidents[AssetID] | Yes | Incident asset context |
| Incidents[IncidentID] | SecurityEvents[IncidentID] | Yes, one-to-many | Incident-to-evidence drill-through |
| SecurityEvents[EventID] | R_Analytics[EventID] | Yes, one-to-one | Optional analytics extensions |

If Power BI considers EventID ambiguous because of the IncidentID relationship, leave R_Analytics disconnected and use it only for event-level detail visuals. Its columns are intentionally duplicated in SecurityEvents for a simple report model.

## Model notes

- SecurityEvents is the primary event fact table.
- Incidents is a deduplicated incident fact table. It represents category/source-IP/asset activity in a six-hour UTC window, not one arbitrary event.
- Blank IncidentID means an event did not meet the anomaly threshold.
- Mark DateTable as a date table using DateTable[Date]. Do not enable bidirectional relationships.
- GroundTruthAttack is an evaluation label for deliberately injected synthetic scenarios only.

