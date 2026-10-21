import { useEffect, useMemo, useState } from "react";
import { Menu, RefreshCw, UserRound } from "lucide-react";
import { FilterBar } from "./components/FilterBar";
import { Sidebar } from "./components/Sidebar";
import { filterEvents, filterIncidents, loadDashboardData } from "./lib/data";
import { AssetPage, IdentityPage, IncidentPage, OverviewPage, ResponsePage, ThreatPage, pageTitles } from "./pages/DashboardPages";
import { emptyFilters, type DashboardData, type Filters, type Incident, type PageId } from "./types";

function LoadingState() {
  return <main className="state-page"><span className="spinner" /><h1>Loading CloudGuard telemetry</h1><p>Reading validated dashboard contracts from the local public data directory.</p></main>;
}
function ErrorState({ message, retry }: { message: string; retry: () => void }) {
  return <main className="state-page"><h1>Dashboard data is unavailable</h1><p>{message}</p><p>Run <code>Rscript R/run_all.R</code> from the project root, then start the dashboard again.</p><button className="primary-button" onClick={retry}><RefreshCw size={16} /> Retry data load</button></main>;
}
function EmptyState() {
  return <main className="state-page"><h1>No records match these filters</h1><p>Reset filters to return to the full synthetic telemetry dataset.</p></main>;
}

export default function App() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reload, setReload] = useState(0);
  const [page, setPage] = useState<PageId>("overview");
  const [filters, setFilters] = useState<Filters>(emptyFilters);
  const [incidentSearch, setIncidentSearch] = useState("");
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    let active = true;
    setError(null); setData(null);
    loadDashboardData().then(result => { if (active) setData(result); }).catch(reason => { if (active) setError(reason instanceof Error ? reason.message : "Unknown data load error."); });
    return () => { active = false; };
  }, [reload]);

  const visibleEvents = useMemo(() => data ? filterEvents(data.events, filters) : [], [data, filters]);
  const visibleIncidents = useMemo(() => data ? filterIncidents(data.incidents, data.assets, filters) : [], [data, filters]);
  const selectPage = (target: PageId) => { setPage(target); setMobileOpen(false); };
  const toggleNavigation = () => {
    if (window.matchMedia("(max-width: 760px)").matches) setMobileOpen(current => !current);
    else setCollapsed(current => !current);
  };
  const drill = (incident: Incident) => { setPage("incidents"); setIncidentSearch(incident.IncidentID); };

  if (error) return <ErrorState message={error} retry={() => setReload(x => x + 1)} />;
  if (!data) return <LoadingState />;

  const content = (() => {
    if (!visibleEvents.length && !visibleIncidents.length) return <EmptyState />;
    switch (page) {
      case "overview": return <OverviewPage data={data} events={visibleEvents} incidents={visibleIncidents} setCategory={category => setFilters(current => ({ ...current, category }))} drill={drill} />;
      case "incidents": return <IncidentPage data={data} incidents={visibleIncidents} search={incidentSearch} setSearch={setIncidentSearch} />;
      case "threats": return <ThreatPage events={visibleEvents} />;
      case "identity": return <IdentityPage data={data} events={visibleEvents} />;
      case "assets": return <AssetPage data={data} incidents={visibleIncidents} events={visibleEvents} filters={filters} />;
      case "response": return <ResponsePage incidents={visibleIncidents} events={visibleEvents} />;
    }
  })();

  return <div className="app-shell">
    <Sidebar active={page} collapsed={collapsed} mobileOpen={mobileOpen} onSelect={selectPage} onToggle={toggleNavigation} />
    {mobileOpen && <button className="backdrop" onClick={() => setMobileOpen(false)} aria-label="Close navigation" />}
    <div className="workspace">
      <header className="topbar">
        <button className="icon-button menu-button" onClick={toggleNavigation} aria-label={mobileOpen ? "Close navigation" : "Open navigation"} aria-expanded={mobileOpen}><Menu size={20} /></button>
        <div className="topbar-title"><span className="breadcrumb">CloudGuard SOC /</span> {pageTitles[page]}</div>
        <div className="topbar-actions">
          <div className="generated"><span className="simulation-dot" /> Synthetic telemetry | {data.generatedAt ? "Generated " + new Date(data.generatedAt).toLocaleString() : "Generation time unavailable"}</div>
          <div className="user-profile" aria-label="Signed in user: Karan, 26MCC10028"><span className="user-avatar"><UserRound size={15} /></span><span className="user-details"><b>Karan</b><small>26MCC10028</small></span></div>
        </div>
      </header>
      <FilterBar filters={filters} regions={[...new Set(data.assets.map(a => a.Region))].sort()} services={[...new Set(data.assets.map(a => a.ServiceType))].sort()} onChange={setFilters} onReset={() => { setFilters(emptyFilters); setIncidentSearch(""); }} onRefresh={() => setReload(x => x + 1)} />
      <main className="page-content">{content}</main>
      <footer>SIMULATED DATA | EDUCATIONAL DEMONSTRATION | RISK SCORES ARE HEURISTIC, NOT PROBABILITIES</footer>
    </div>
  </div>;
}

