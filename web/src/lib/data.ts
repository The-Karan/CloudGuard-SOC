import type { CloudAsset, DashboardData, Filters, Incident, SecurityEvent, User } from "../types";

type CsvRow = Record<string, string>;

function parseCsv(text: string): CsvRow[] {
  const rows: string[][] = [];
  let row: string[] = [], cell = "", quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const c = text[i];
    if (c === '"') {
      if (quoted && text[i + 1] === '"') { cell += '"'; i += 1; }
      else quoted = !quoted;
    } else if (c === "," && !quoted) { row.push(cell); cell = ""; }
    else if ((c === "\n" || c === "\r") && !quoted) {
      if (c === "\r" && text[i + 1] === "\n") i += 1;
      row.push(cell); if (row.some(Boolean)) rows.push(row); row = []; cell = "";
    } else cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  const [header, ...body] = rows;
  if (!header) return [];
  return body.map(values => Object.fromEntries(header.map((key, index) => [key, values[index] ?? ""])));
}
const bool = (v: string) => v.toLowerCase() === "true";
const num = (v: string) => Number(v || 0);
const maybeNum = (v: string) => v === "" ? null : Number(v);
const get = (r: CsvRow, k: string) => r[k] ?? "";

function eventFrom(r: CsvRow): SecurityEvent {
  return { ...r, EventID: get(r, "EventID"), Timestamp: get(r, "Timestamp"), EventDate: get(r, "EventDate"), EventType: get(r, "EventType"), Action: get(r, "Action"), SourceIP: get(r, "SourceIP"), UserID: get(r, "UserID"), UserName: get(r, "UserName"), UserRole: get(r, "UserRole"), AssetID: get(r, "AssetID"), AssetName: get(r, "AssetName"), ServiceType: get(r, "ServiceType"), Region: get(r, "Region"), AssetCriticality: get(r, "AssetCriticality"), Result: get(r, "Result"), IncidentID: get(r, "IncidentID"), RiskScore: num(get(r, "RiskScore")), RiskBand: get(r, "RiskBand") as SecurityEvent["RiskBand"], IsAnomaly: bool(get(r, "IsAnomaly")), DetectionReason: get(r, "DetectionReason"), DetectionCategory: get(r, "DetectionCategory"), GroundTruthAttack: bool(get(r, "GroundTruthAttack")), ScenarioID: get(r, "ScenarioID"), FailedLoginsFromIPWindow: num(get(r, "FailedLoginsFromIPWindow")), FailedLoginsFromIPPerDay: num(get(r, "FailedLoginsFromIPPerDay")), BytesTransferred: num(get(r, "BytesTransferred")), AfterHours: bool(get(r, "AfterHours")), PrivilegedAction: bool(get(r, "PrivilegedAction")), LargeNetworkTransfer: bool(get(r, "LargeNetworkTransfer")), AccessDeniedBurst: bool(get(r, "AccessDeniedBurst")) };
}
function incidentFrom(r: CsvRow): Incident {
  return { ...r, IncidentID: get(r, "IncidentID"), RepresentativeEventID: get(r, "RepresentativeEventID"), CreatedAt: get(r, "CreatedAt"), FirstSeenAt: get(r, "FirstSeenAt"), LastSeenAt: get(r, "LastSeenAt"), IncidentDate: get(r, "IncidentDate"), Severity: get(r, "Severity") as Incident["Severity"], Status: get(r, "Status") as Incident["Status"], Category: get(r, "Category"), UserID: get(r, "UserID"), AssetID: get(r, "AssetID"), SourceIP: get(r, "SourceIP"), EventCount: num(get(r, "EventCount")), RiskScore: num(get(r, "RiskScore")), RiskBand: get(r, "RiskBand") as Incident["RiskBand"], DetectionReason: get(r, "DetectionReason"), GroundTruthAttack: bool(get(r, "GroundTruthAttack")), ScenarioIDs: get(r, "ScenarioIDs"), AcknowledgedAt: get(r, "AcknowledgedAt"), ResolvedAt: get(r, "ResolvedAt"), ResponseMinutes: maybeNum(get(r, "ResponseMinutes")), ResolutionMinutes: maybeNum(get(r, "ResolutionMinutes")), ResponseTargetMinutes: num(get(r, "ResponseTargetMinutes")), ResolutionTargetMinutes: num(get(r, "ResolutionTargetMinutes")), SLAStatus: get(r, "SLAStatus") };
}
function userFrom(r: CsvRow): User {
  return { UserID: get(r, "UserID"), Username: get(r, "Username"), Role: get(r, "Role"), Department: get(r, "Department"), IsPrivileged: bool(get(r, "IsPrivileged")), IsMFAEnabled: bool(get(r, "IsMFAEnabled")), HomeRegion: get(r, "HomeRegion"), AccountStatus: get(r, "AccountStatus") };
}
function assetFrom(r: CsvRow): CloudAsset {
  return { AssetID: get(r, "AssetID"), AssetName: get(r, "AssetName"), ServiceType: get(r, "ServiceType"), Region: get(r, "Region"), Criticality: get(r, "Criticality"), CloudAccount: get(r, "CloudAccount"), InternetExposed: bool(get(r, "InternetExposed")) };
}
async function loadCsv(name: string): Promise<CsvRow[]> {
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  const response = await fetch(base + "/data/" + name);
  if (!response.ok) throw new Error("Could not load " + name + " (" + response.status + "). Run the R pipeline and prepare dashboard data.");
  return parseCsv(await response.text());
}
export async function loadDashboardData(): Promise<DashboardData> {
  const [eventRows, incidentRows, userRows, assetRows, manifest] = await Promise.all([
    loadCsv("SecurityEvents.csv"), loadCsv("Incidents.csv"), loadCsv("Users.csv"), loadCsv("CloudAssets.csv"),
    fetch(import.meta.env.BASE_URL.replace(/\/$/, "") + "/data/manifest.json").then(r => r.ok ? r.json() as Promise<{ generatedAt?: string }> : null)
  ]);
  return { events: eventRows.map(eventFrom), incidents: incidentRows.map(incidentFrom), users: userRows.map(userFrom), assets: assetRows.map(assetFrom), generatedAt: manifest?.generatedAt ?? null };
}
export function filterEvents(events: SecurityEvent[], filters: Filters): SecurityEvent[] {
  return events.filter(e => (!filters.from || e.EventDate >= filters.from) && (!filters.to || e.EventDate <= filters.to) && (!filters.severity || e.RiskBand === filters.severity) && (!filters.region || e.Region === filters.region) && (!filters.service || e.ServiceType === filters.service) && (!filters.category || e.DetectionCategory === filters.category));
}
export function filterIncidents(incidents: Incident[], assets: CloudAsset[], filters: Filters): Incident[] {
  const byAsset = new Map(assets.map(a => [a.AssetID, a]));
  return incidents.filter(i => {
    const asset = byAsset.get(i.AssetID);
    return (!filters.from || i.IncidentDate >= filters.from) && (!filters.to || i.IncidentDate <= filters.to) && (!filters.severity || i.Severity === filters.severity) && (!filters.status || i.Status === filters.status) && (!filters.region || asset?.Region === filters.region) && (!filters.service || asset?.ServiceType === filters.service) && (!filters.category || i.Category === filters.category);
  });
}
export function countBy<T>(items: T[], value: (item: T) => string): { name: string; value: number }[] {
  const counts = new Map<string, number>();
  items.forEach(item => { const key = value(item) || "Unknown"; counts.set(key, (counts.get(key) ?? 0) + 1); });
  return [...counts].map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value);
}
export function average(values: Array<number | null | undefined>): number {
  const usable = values.filter((value): value is number => typeof value === "number" && Number.isFinite(value));
  return usable.length ? usable.reduce((total, value) => total + value, 0) / usable.length : 0;
}
export function dateSeries<T>(items: T[], date: (item: T) => string, predicate: (item: T) => boolean = () => true) {
  const all = new Map<string, { date: string; total: number; suspicious: number }>();
  items.forEach(item => { const key = date(item); const entry = all.get(key) ?? { date: key, total: 0, suspicious: 0 }; entry.total += 1; if (predicate(item)) entry.suspicious += 1; all.set(key, entry); });
  return [...all.values()].sort((a, b) => a.date.localeCompare(b.date));
}
export function displayDate(value: string): string { return value ? new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric", timeZone: "UTC" }).format(new Date(value + (value.length === 10 ? "T00:00:00Z" : "Z"))) : "—"; }
export function formatMinutes(value: number | null): string { return value === null ? "—" : value < 60 ? Math.round(value) + " min" : (value / 60).toFixed(1) + " hr"; }
export function exportCsv(filename: string, headers: string[], rows: Array<Array<string | number | null>>) {
  const escape = (value: string | number | null) => '"' + String(value ?? "").replace(/"/g, '""') + '"';
  const csv = [headers, ...rows].map(row => row.map(escape).join(",")).join("\n");
  const link = document.createElement("a"); link.href = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" })); link.download = filename; link.click(); URL.revokeObjectURL(link.href);
}

