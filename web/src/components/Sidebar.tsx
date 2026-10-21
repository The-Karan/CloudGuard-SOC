import { ChevronLeft, X } from "lucide-react";
import type { PageId } from "../types";
import { navigationPages } from "../lib/navigation";

export function Sidebar({ active, collapsed, mobileOpen, onSelect, onToggle }: { active: PageId; collapsed: boolean; mobileOpen: boolean; onSelect: (id: PageId) => void; onToggle: () => void }) {
  return <aside className={"sidebar " + (collapsed ? "collapsed " : "") + (mobileOpen ? "mobile-open" : "")} aria-label="Primary navigation">
    <div className="brand"><img className="brand-logo" src="/cloudguard-soc-logo.svg" alt="CloudGuard SOC" /><button className="icon-button mobile-close" onClick={onToggle} aria-label="Close navigation"><X size={18} /></button></div>
    <nav aria-label="Dashboard pages">{navigationPages.map(item => { const Icon = item.icon; return <button key={item.id} className={active === item.id ? "nav-item active" : "nav-item"} onClick={() => onSelect(item.id)} title={collapsed ? item.label : undefined}><Icon size={19} /><span>{item.label}</span></button>; })}</nav>
    <div className="sidebar-bottom"><span className="simulation-dot" /><span className="sidebar-status">Synthetic telemetry</span><button className="icon-button collapse-button" onClick={onToggle} aria-label={collapsed ? "Expand navigation" : "Collapse navigation"} aria-expanded={!collapsed}><ChevronLeft size={18} /></button></div>
  </aside>;
}

