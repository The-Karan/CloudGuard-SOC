import type { ReactNode } from "react";

export function ChartPanel({ title, subtitle, action, children, className = "" }: { title: string; subtitle?: string; action?: ReactNode; children: ReactNode; className?: string }) {
  return <section className={"panel chart-panel " + className}>
    <header className="panel-header"><div><h2>{title}</h2>{subtitle && <p>{subtitle}</p>}</div>{action}</header>
    <div className="chart-content">{children}</div>
  </section>;
}

