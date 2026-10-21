# Demonstration walkthrough

1. Run the pipeline, start the web app, and open the local URL shown by Vite (normally http://127.0.0.1:5173).
2. **Security Overview:** show the four live KPIs, click an incident category, then select a latest-incident row to drill into the incident register.
3. **Incident Analysis:** search a source IP or incident ID; sort a column; select a row to open lifecycle, evidence, SLA, identity and asset context.
4. **Threat Detection:** compare all telemetry with suspicious activity, inspect reason and source-IP charts, and export filtered event evidence.
5. **Identity & Access:** discuss repeated login failures, privileged actions, denied access, and MFA activity.
6. **Cloud Asset & Risk:** filter Region/Service, then select a high-risk asset to show its inventory detail.
7. **Response & R Analytics:** explain mean/median response and resolution, synthetic targets, and why precision/recall are valid only because injection labels exist.
8. Reset global filters and point out the simulated-data indicator and generation timestamp.

For Power BI, follow the six-page layout in POWER_BI_BUILD_GUIDE.md, then use synced Date/Region slicers and an IncidentID drill-through target.

