import { FilterX, RefreshCw, SlidersHorizontal } from "lucide-react";
import type { Filters } from "../types";

const option = (value: string, label: string) => <option value={value}>{label}</option>;
export function FilterBar({ filters, regions, services, onChange, onReset, onRefresh }: { filters: Filters; regions: string[]; services: string[]; onChange: (next: Filters) => void; onReset: () => void; onRefresh: () => void }) {
  const set = (key: keyof Filters, value: string) => onChange({ ...filters, [key]: value });
  return <section className="filter-bar" aria-label="Global filters">
    <span className="filter-label"><SlidersHorizontal size={16} /> Filters</span>
    <label>From<input type="date" value={filters.from} onChange={e => set("from", e.target.value)} /></label>
    <label>To<input type="date" value={filters.to} onChange={e => set("to", e.target.value)} /></label>
    <label>Severity<select value={filters.severity} onChange={e => set("severity", e.target.value)}>{option("", "All severities")}{option("Critical", "Critical")}{option("High", "High")}{option("Medium", "Medium")}{option("Low", "Low")}</select></label>
    <label>Status<select value={filters.status} onChange={e => set("status", e.target.value)}>{option("", "All statuses")}{option("Open", "Open")}{option("Investigating", "Investigating")}{option("Resolved", "Resolved")}</select></label>
    <label>Region<select value={filters.region} onChange={e => set("region", e.target.value)}>{option("", "All regions")}{regions.map(v => option(v, v))}</select></label>
    <label>Service<select value={filters.service} onChange={e => set("service", e.target.value)}>{option("", "All services")}{services.map(v => option(v, v))}</select></label>
    <button className="text-button" onClick={onReset}><FilterX size={15} /> Reset</button>
    <button className="icon-button refresh" onClick={onRefresh} aria-label="Refresh data"><RefreshCw size={16} /></button>
  </section>;
}

