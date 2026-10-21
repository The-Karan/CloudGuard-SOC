# Power Query import and transformation guide

1. In Power BI Desktop choose Get data > Text/CSV and import all six files from data/processed.
2. Set ID columns, SourceIP, and ScenarioIDs to Text.
3. Set SecurityEvents[Timestamp] and Incidents[CreatedAt], [FirstSeenAt], [LastSeenAt], [AcknowledgedAt], [ResolvedAt] to Date/Time.
4. Set EventDate, IncidentDate, and DateTable[Date] to Date.
5. Set RiskScore, counts, bytes and duration columns to Whole Number or Decimal Number. Set IsAnomaly, GroundTruthAttack, and rule indicators to True/False.
6. Keep blank acknowledgement/resolution timestamps as null. They are meaningful for open work.
7. Sort DateTable[Month] by MonthNumber; use YearMonth for chronological monthly visuals.
8. Close & Apply, then create the relationships in DATA_MODEL.md.

For a refresh, run Rscript R/run_all.R, then select Refresh in Power BI. Confirm that CSV paths did not change. All transformed data remains synthetic.

